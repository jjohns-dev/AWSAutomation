#Requires -Modules @{ ModuleName = "AWS.Tools.SSO"; ModuleVersion = "4.1.269" }
#Requires -Modules @{ ModuleName = "AWS.Tools.SSOOIDC"; ModuleVersion = "4.1.269" }
#Requires -Modules @{ ModuleName = "AWS.Tools.Common"; ModuleVersion = "4.1.269" }

function Set-AwsSsoCredential {
    <#
    .SYNOPSIS
        Set or update AWS Credential Profiles
    .DESCRIPTION
        Use AWS named profiles and AWS Tools for PowerShell to store and refresh credentials for multiple accounts from a single IAM Identity Center.
        Stores IAM Identity Center session data in memory for refreshing credentials without logging into IAM Identity Center again.
        Stores account credentials in the default location (~/.aws/credentials) which are picked up by AWS Tools for PowerShell
    .PARAMETER Region
        Identity Center Region
    .PARAMETER StartUrl
        Identity Center URL
    .PARAMETER Force
        Force add new accounts
    .PARAMETER Account
        Array of account info
    .INPUTS
        None.
    .OUTPUTS
        None.
    .EXAMPLE
        PS C:\> Set-AwsSsoCredential -StartUrl 'https://example.awsapps.com/start/' -Account $accounts
        Performs the AWS IAM Identity Center device-authorization flow against the
        supplied Start URL and writes refreshed access keys for every account in
        $accounts to ~/.aws/credentials.
    .NOTES
        Status: Stable
        Comments:
        https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/update-aws-cli-credentials-from-aws-iam-identity-center-by-using-powershell.html

        Token cache: this function stores the IAM Identity Center access
        token, its expiration, and the per-account credential state in
        three Global-scope variables so subsequent invocations in the
        same PowerShell session can refresh account credentials without
        re-authenticating in the browser:

            $Global:<IdentityCenterName>_identity_center_token
            $Global:<IdentityCenterName>_identity_center_token_expiration
            $Global:<IdentityCenterName>_identity_center_accounts

        where <IdentityCenterName> is the leading host label of -StartUrl
        (for example 'mcssec' for https://mcssec.awsapps.com/start/).
        The variables persist until the PowerShell session ends. To
        clear them manually:

            Remove-Variable -Scope Global -Name '<IdentityCenterName>_identity_center_*'

        Default Start URL: -StartUrl is mandatory and has no built-in
        default. To avoid supplying it on every call, set a per-user
        default in your PowerShell profile. $PSDefaultParameterValues is
        applied during parameter binding, before the mandatory-parameter
        check runs, so no prompt occurs:

            $PSDefaultParameterValues['Set-AwsSsoCredential:StartUrl'] = 'https://example.awsapps.com/start/'
    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidGlobalVars',
        '',
        Justification = 'Token and per-account state are cached in Global-scope variables to avoid re-authenticating each invocation. See .NOTES.'
    )]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = 'Identity Center region')]
        [System.String] $Region = 'us-east-1',

        [Parameter(Mandatory, HelpMessage = 'Identity Center url')]
        [ValidateNotNullOrEmpty()]
        [System.Uri] $StartUrl,

        [Parameter(Mandatory = $false, HelpMessage = 'Force add new accounts')]
        [System.Management.Automation.SwitchParameter] $Force,

        [Parameter(Mandatory = $true, HelpMessage = 'Array of account info')]
        [System.Object[]] $Account
    )
    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

        # SET ERROR PREFERENCe
        $ErrorActionPreference = 'Stop'
    }
    Process {
        try {
            # EXTRACT IDENTITY CENTER INSTANCE NAME
            $IdentityCenterName = $StartUrl.Host.Split('.')[0]

            # PSEUDO CREDS, DO NOT EDIT! NOT ACTUALLY USED FOR SECURITY PURPOSES BUT REQUIRED FOR AUTH PROCESS TO WORK
            $PsuedoCreds = @{AccessKey = 'AKAEXAMPLE123ACCESS'; SecretKey = 'PsuedoS3cret4cceSSKey123PsuedoS3cretKey' }

            # CREATE EMPTY AWS CREDENTIALS FILE IF IT DOES NOT ALREADY EXIST
            if (-not (Test-Path ~/.aws/credentials)) { New-Item -Path ~/.aws/credentials -ItemType 'File' -Force }
            $credentialFile = Resolve-Path ~/.aws/credentials

            # LOOK FOR SESSION VARIABLES THAT INDICATE EXISTING IDENTITY CENTER SESSION. IF NOT FOUND, INITIALIZE THEM TO $FALSE
            try { $IdentityCenterTokenExpiration = (Get-Variable -Scope Global -Name "$($IdentityCenterName)_identity_center_token_expiration" -ErrorAction 'SilentlyContinue').Value } catch { $IdentityCenterTokenExpiration = $False }
            try { $IdentityCenterToken = (Get-Variable -Scope Global -Name "$($IdentityCenterName)_identity_center_token" -ErrorAction 'SilentlyContinue').Value } catch { $IdentityCenterToken = $False }

            # IF TOKEN FROM SESSION VARIABLE IS EXPIRED, GENERATE A NEW ONE
            if ( $IdentityCenterTokenExpiration -lt (Get-Date) ) {
                $IdentityCenterToken = $Null

                # CREATE/REGISTER CLIENT
                $Client = Register-SSOOIDCClient -ClientName 'cli-sso-client' -ClientType 'public' -Region $Region @PsuedoCreds

                # START DEVICE AUTH
                $Device = $Client | Start-SSOOIDCDeviceAuthorization -StartUrl $StartUrl -Region $Region @PsuedoCreds
                Write-Output -InputObject 'A browser window should open.'
                Write-Output -InputObject 'Please login there and verify this code matches the one displayed in your browser.'
                Write-Output -InputObject 'Then click "Confirm and continue".'
                Write-Output -InputObject "Verification Code: $($Device.UserCode)"

                # OPEN DEFAULT BROWSER WITH URL POINTING TO IDENTITY CENTER WITH VERIFICATION CODE ALREADY SUPPLIED
                Start-Process $Device.VerificationUriComplete

                # GET IDENTITY CENTER ACCESS TOKEN. THE TOKEN ISSUED IS USED TO FETCH SHORT-TERM CREDS LATER
                while (-Not $IdentityCenterToken) {
                    try {
                        $IdentityCenterToken = $Client | New-SSOOIDCToken -DeviceCode $Device.DeviceCode -GrantType 'urn:ietf:params:oauth:grant-type:device_code' -Region $Region @PsuedoCreds
                    }
                    catch { If ($_.Exception.Message -notlike '*AuthorizationPendingException*') { Write-Error $_.Exception }; Start-Sleep 1 }
                }
                $IdentityCenterTokenExpiration = (Get-Date).AddSeconds($IdentityCenterToken.ExpiresIn)

                # SET SESSION VARIABLES FOR FUTURE RUNS
                Set-Variable -Name "$($IdentityCenterName)_identity_center_token" -Value $IdentityCenterToken -Scope Global
                Set-Variable -Name "$($IdentityCenterName)_identity_center_token_expiration" -Value $IdentityCenterTokenExpiration -Scope Global
            }

            # LOOK FOR VARIABLE IN CURRENT SESSION TO INDICATE IF INDIVIDUAL ACCOUNT ACCESS IS ALREADY DEFINED, IF NOT FOUND, INITIALIZE IT TO $FALSE
            try { $IdentityCenterAccounts = (Get-Variable -Name "$($IdentityCenterName)_identity_center_accounts" -Scope 'Global' -ErrorAction 'SilentlyContinue').Value.Clone() } catch { $IdentityCenterAccounts = $False }
            if ((-not $IdentityCenterAccounts) -or ($Force)) { $IdentityCenterAccounts = $Account }

            for ($i = 0; $i -lt $IdentityCenterAccounts.Count; $i++) {

                # IF EXISTING ACCOUNT LEVEL CREDS ARE EXPIRED, RENEW THEM OR SKIP IF ALREADY SETUP
                if (([DateTimeOffset]::FromUnixTimeSeconds($IdentityCenterAccounts[$i].CredsExpiration / 1000)).DateTime -lt (Get-Date).ToUniversalTime()) {
                    Write-Output -InputObject "Registering profile: $($IdentityCenterAccounts[$i].Profile)"

                    # GET NEW SHORT LIVED ACCOUNT CREDS USING TOKEN FROM IDENTITY CENTER
                    $TempCreds = $IdentityCenterToken | Get-SSORoleCredential -AccountId $IdentityCenterAccounts[$i].AccountId -RoleName $IdentityCenterAccounts[$i].RoleName -Region $Region @PsuedoCreds

                    # STORE SHORT LIVED ACCESS/SECRET KEY IN CREDENTIAL FILE
                    $awsCredParams = @{
                        AccessKey    = $TempCreds.AccessKeyId
                        SecretKey    = $TempCreds.SecretAccessKey
                        SessionToken = $TempCreds.SessionToken
                        StoreAs      = $IdentityCenterAccounts[$i].Profile
                    }
                    if (-Not $IsWindows) { $awsCredParams['ProfileLocation'] = $credentialFile }
                    Set-AWSCredential @awsCredParams
                    $IdentityCenterAccounts[$i].CredsExpiration = $TempCreds.Expiration
                }
            }

            $CredsTime = $IdentityCenterTokenExpiration - (Get-Date)
            Set-Variable -Name "$($IdentityCenterName)_identity_center_accounts" -Value $IdentityCenterAccounts.Clone() -Scope Global

            Write-Output -InputObject "`r$($IdentityCenterAccounts.Count) Profiles registered, $(('{0:D2}:{1:D2}:{2:D2} left on Identity Center token' -f $CredsTime.Hours, $CredsTime.Minutes, $CredsTime.Seconds).TrimStart('0 :'))"
        }
        catch {
            $msg = "Ran into an issue: Line {0} returned '{1}'" -f $PSItem.InvocationInfo.ScriptLineNumber, $PSItem.Exception.Message
            Write-Error -Message $msg -ErrorAction Stop
        }
    }
}