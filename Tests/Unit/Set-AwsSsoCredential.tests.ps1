[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester assigns fixtures in BeforeDiscovery/BeforeAll/BeforeEach and consumes them in It blocks; PSScriptAnalyzer cannot follow that scope.'
)]
Param()

BeforeDiscovery {
    if (-not (Get-Module -Name $env:BHProjectName)) {
        Import-Module -Name $env:BHPSModuleManifest -ErrorAction 'Stop' -Force
    }
}

Describe -Name 'Set-AwsSsoCredential' -Fixture {
    BeforeAll {
        $startUrl = 'https://example.awsapps.com/start/'
        # $IsWindows IS ReadOnly + AllScope, SO A FORCED GLOBAL OVERRIDE IS THE ONLY WAY TO EXERCISE BOTH BRANCHES ON ONE HOST
        $realIsWindows = $IsWindows
        $fakeCredentialFile = Join-Path -Path $TestDrive -ChildPath 'credentials'
        # KEEP THE REAL ~/.aws/credentials OUT OF THE TEST ENTIRELY
        Mock -CommandName 'Test-Path' -ModuleName $env:BHProjectName -MockWith { $true }
        Mock -CommandName 'Resolve-Path' -ModuleName $env:BHProjectName -MockWith { $fakeCredentialFile }
        Mock -CommandName 'Set-AWSCredential' -ModuleName $env:BHProjectName -MockWith { }
        # -RemoveParameterType DROPS THE [PSCredential] TRANSFORM THAT OTHERWISE SWALLOWS THE PIPED TOKEN OBJECT
        Mock -CommandName 'Get-SSORoleCredential' -ModuleName $env:BHProjectName -RemoveParameterType 'NetworkCredential', 'Credential' -MockWith {
            [PSCustomObject] @{
                AccessKeyId     = 'AKIAFAKEFAKEFAKEFAKE'
                SecretAccessKey = 'fake-secret-key'
                SessionToken    = 'fake-session-token'
                Expiration      = 0
            }
        }
        # THE DEVICE-AUTHORIZATION FLOW OPENS A BROWSER; FAIL LOUDLY IF THE SEEDED TOKEN EVER STOPS SHORT-CIRCUITING IT
        Mock -CommandName 'Register-SSOOIDCClient' -ModuleName $env:BHProjectName -MockWith {
            throw 'device authorization flow should not run'
        }
    }
    BeforeEach {
        # SEED AN UNEXPIRED TOKEN SO THE FUNCTION SKIPS STRAIGHT TO THE PER-ACCOUNT CREDENTIAL REFRESH
        $token = [Amazon.SSOOIDC.Model.CreateTokenResponse]::new()
        $token.AccessToken = 'fake-token'
        $token.ExpiresIn = 3600
        Set-Variable -Name 'example_identity_center_token' -Value $token -Scope 'Global'
        Set-Variable -Name 'example_identity_center_token_expiration' -Value (Get-Date).AddHours(1) -Scope 'Global'
        Remove-Variable -Name 'example_identity_center_accounts' -Scope 'Global' -Force -ErrorAction 'SilentlyContinue'
        $account = @(
            [PSCustomObject] @{
                AccountId       = '111122223333'
                RoleName        = 'FakeRole'
                Profile         = 'fake-profile'
                CredsExpiration = 0
            }
        )
    }
    AfterEach {
        Set-Variable -Name 'IsWindows' -Value $realIsWindows -Scope 'Global' -Force
        Remove-Variable -Name 'example_identity_center_*' -Scope 'Global' -Force -ErrorAction 'SilentlyContinue'
    }
    Context -Name 'on Windows' -Fixture {
        It -Name 'omits ProfileLocation so credentials land in the encrypted SDK store' -Test {
            Set-Variable -Name 'IsWindows' -Value $true -Scope 'Global' -Force
            Set-AwsSsoCredential -Region 'us-east-1' -StartUrl $startUrl -Account $account | Out-Null
            Should -Invoke -CommandName 'Set-AWSCredential' -ModuleName $env:BHProjectName -Times 1 -Exactly -ParameterFilter {
                $null -eq $ProfileLocation
            }
        }
        It -Name 'passes ProfileLocation when -SharedCredentialFile is specified' -Test {
            Set-Variable -Name 'IsWindows' -Value $true -Scope 'Global' -Force
            Set-AwsSsoCredential -Region 'us-east-1' -StartUrl $startUrl -Account $account -SharedCredentialFile | Out-Null
            Should -Invoke -CommandName 'Set-AWSCredential' -ModuleName $env:BHProjectName -Times 1 -Exactly -ParameterFilter {
                $ProfileLocation -eq $fakeCredentialFile
            }
        }
    }
    Context -Name 'on Linux and macOS' -Fixture {
        It -Name 'passes ProfileLocation without -SharedCredentialFile' -Test {
            Set-Variable -Name 'IsWindows' -Value $false -Scope 'Global' -Force
            Set-AwsSsoCredential -Region 'us-east-1' -StartUrl $startUrl -Account $account | Out-Null
            Should -Invoke -CommandName 'Set-AWSCredential' -ModuleName $env:BHProjectName -Times 1 -Exactly -ParameterFilter {
                $ProfileLocation -eq $fakeCredentialFile
            }
        }
    }
}
