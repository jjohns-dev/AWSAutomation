[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseShouldProcessForStateChangingFunctions',
    '',
    Justification = 'New-FakeVpc is a test fixture factory that builds an in-memory object and changes no state; the rule fires on the verb alone.'
)]
Param()

BeforeDiscovery {
    if (-not (Get-Module -Name $env:BHProjectName)) {
        Import-Module -Name $env:BHPSModuleManifest -ErrorAction Stop -Force
    }
}

Describe -Name 'Find-NextSubnet' -Fixture {

    BeforeAll {
        # Satisfy the ProfileName [ValidateScript] without touching AWS.
        Mock -CommandName 'Get-AWSCredential' -ModuleName $env:BHProjectName -MockWith {
            [PSCustomObject] @{ ProfileName = 'fake-profile' }
        }

        # Satisfy the Region [ValidateScript] when callers pass -Region.
        Mock -CommandName 'Get-AWSRegion' -ModuleName $env:BHProjectName -MockWith {
            [PSCustomObject] @{ Region = 'us-east-1' }
        }

        function New-FakeVpc {
            param([System.String] $Cidr, [System.String] $Name)
            $vpc = [Amazon.EC2.Model.Vpc]::new()
            $vpc.CidrBlock = $Cidr
            $vpc.Tags = @([Amazon.EC2.Model.Tag]::new('Name', $Name))
            $vpc
        }
    }

    Context -Name 'when computing the next available second octet' -Fixture {

        It -Name 'returns max(second octet) + 1 from non-default VPCs' -Test {
            Mock -CommandName 'Get-EC2Vpc' -ModuleName $env:BHProjectName -MockWith {
                @(
                    (New-FakeVpc -Cidr '10.5.0.0/16'  -Name 'a')
                    (New-FakeVpc -Cidr '10.12.0.0/16' -Name 'b')
                    (New-FakeVpc -Cidr '10.7.0.0/16'  -Name 'c')
                )
            }
            Find-NextSubnet -ProfileName 'fake-profile' | Should -Be 13
        }

        It -Name 'excludes default VPCs in the 172.* range' -Test {
            Mock -CommandName 'Get-EC2Vpc' -ModuleName $env:BHProjectName -MockWith {
                @(
                    (New-FakeVpc -Cidr '10.3.0.0/16'   -Name 'a')
                    (New-FakeVpc -Cidr '172.31.0.0/16' -Name 'default')
                )
            }
            Find-NextSubnet -ProfileName 'fake-profile' | Should -Be 4
        }
    }

    Context -Name 'parameter sets' -Fixture {

        It -Name 'accepts -Credential as an alternative to -ProfileName' -Test {
            Mock -CommandName 'Get-EC2Vpc' -ModuleName $env:BHProjectName -MockWith {
                @((New-FakeVpc -Cidr '10.1.0.0/16' -Name 'a'))
            }
            $cred = [Amazon.Runtime.BasicAWSCredentials]::new('AK', 'SK')
            Find-NextSubnet -Credential $cred | Should -Be 2
        }
    }
}
