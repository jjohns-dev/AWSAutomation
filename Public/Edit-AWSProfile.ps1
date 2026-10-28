function Edit-AWSProfile {
    <#
    .SYNOPSIS
        Manage AWS Credential Profiles
    .DESCRIPTION
        Allows for managemnt of AWS Profile Credentials by prompting the user
        for the necessary information to perform an initialization task.
        Profiles can be created, updated, set as default, or removed.
    .PARAMETER List
        List profiles
    .PARAMETER Create
        Create new profile
    .PARAMETER Update
        Update existing profile
    .PARAMETER Delete
        Remove existing profile
    .PARAMETER Default
        Set profile as default
    .PARAMETER Region
        Set AWS Region
    .PARAMETER ProfileName
        Profile name
    .INPUTS
        System.String.
    .OUTPUTS
        System.String.
    .EXAMPLE
        PS C:\> Edit-AWSProfile -List
        Display all existing profiles
    .EXAMPLE
        PS C:\> Edit-AWSProfile -Create -ProfileName MyProfile
        Create new profile named MyProfile
    .EXAMPLE
        PS C:\> Edit-AWSProfile -Update -ProfileName Profile1
        Update existing profile Profile1
    .LINK
        https://docs.aws.amazon.com/powershell/latest/userguide/specifying-your-aws-credentials.html#pstools-cred-provider-chain
    .NOTES
        Status: Stable
        Comments:
        Using -AsSecureString prevents copy/paste when running the script.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory, ParameterSetName = '_list', HelpMessage = 'List profiles')]
        [System.Management.Automation.SwitchParameter] $List,

        [Parameter(Mandatory, ParameterSetName = '_create', HelpMessage = 'Create new profile')]
        [Parameter(Mandatory, ParameterSetName = '_create_default', HelpMessage = 'Create new profile')]
        [System.Management.Automation.SwitchParameter] $Create,

        [Parameter(Mandatory, ParameterSetName = '_update', HelpMessage = 'Update existing profile')]
        [Parameter(Mandatory, ParameterSetName = '_update_default', HelpMessage = 'Update existing profile')]
        [System.Management.Automation.SwitchParameter] $Update,

        [Parameter(Mandatory, ParameterSetName = '_delete', HelpMessage = 'Remove existing profile')]
        [System.Management.Automation.SwitchParameter] $Delete,

        [Parameter(Mandatory, ParameterSetName = '_create_default', HelpMessage = 'Set profile as default')]
        [Parameter(Mandatory, ParameterSetName = '_update_default', HelpMessage = 'Set profile as default')]
        [System.Management.Automation.SwitchParameter] $Default,

        [Parameter(Mandatory, ParameterSetName = '_create_default', HelpMessage = 'Set AWS Region')]
        [Parameter(Mandatory, ParameterSetName = '_update_default', HelpMessage = 'Set AWS Region')]
        [ValidateScript( { (Get-AWSRegion).Region -contains $_ })]
        [System.String] $Region,

        [Parameter(Mandatory, ParameterSetName = '_create', HelpMessage = 'Profile name')]
        [Parameter(Mandatory, ParameterSetName = '_create_default', HelpMessage = 'Profile name')]
        [Parameter(Mandatory, ParameterSetName = '_delete', HelpMessage = 'Profile name')]
        [Parameter(Mandatory, ParameterSetName = '_update', HelpMessage = 'Profile name')]
        [Parameter(Mandatory, ParameterSetName = '_update_default', HelpMessage = 'Profile name')]
        [System.String] $ProfileName
    )
    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

        # OPERATIONAL PARAMETERS
        $OpParams = @('Default', 'Region', 'ProfileName')

        # HELPER FUNCTION
        function Confirm-Profile ([System.String] $ProfileName) {
            <# $ProfileExists = (Get-AWSCredential -ListProfileDetail).ProfileName -contains $ProfileName
            Return $ProfileExists #>

            if ((Get-AWSCredential -ListProfileDetail).ProfileName -contains $ProfileName) { $true } else { $false }
        }
    }
    Process {
        # SWITCH ON PARAMETER ARGUMENTS
        $Result = switch ($PSBoundParameters.Keys | Where-Object {$_ -notin $OpParams}) {
            List {
                # RETURN ARRAY OF AWS CREDENTIAL PROFILES
                Get-AWSCredential -ListProfileDetail | Sort-Object ProfileName | Out-String
            }
            Create {
                # VALIDATE PROFILE HAS UNIQUE NAME
                if ($PSBoundParameters.ContainsKey('ProfileName')) {
                    if (Confirm-Profile -ProfileName $ProfileName) {
                        Write-Error -Message ('Profile [{0}] already exists. Please enter a unique name.' -f $ProfileName) -ErrorAction Stop
                    }
                }
                else {
                    $ProfileName = Read-Host -Prompt 'Profile name'
                    if (Confirm-Profile -ProfileName $ProfileName) {
                        Write-Error -Message ('Profile [{0}] already exists. Please enter a unique name.' -f $ProfileName) -ErrorAction Stop
                    }
                }

                # PROMPT FOR KEYS
                Write-Output -InputObject `n
                $AccessKey = Read-Host -Prompt 'Access Key'
                $SecretKey = Read-Host -Prompt 'Secret Key' -MaskInput

                # CREATE NEW CREDENTIAL PROFILE
                Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs $ProfileName

                # SET NEW PROFILE AS DEFAULT IF SWITCH PARAMETER DETECTED
                if ($PSBoundParameters.ContainsKey('Default')) {
                    Initialize-AWSDefaultConfiguration -ProfileName $ProfileName -Region $Region
                }

                # RETURN TEXT RESULT
                'Profile [{0}] created.' -f $ProfileName
            }
            Update {
                # VALIDATE EXISTENCE OF SPECIFIED PROFILE
                if (-Not (Confirm-Profile -ProfileName $ProfileName)) {
                    Write-Error -Message ('Profile [{0}] not found' -f $ProfileName) -ErrorAction Stop
                }

                # PROMPT FOR KEYS
                Write-Output -InputObject `n
                $AccessKey = Read-Host -Prompt 'Access Key'
                $SecretKey = Read-Host -Prompt 'Secret Key' -MaskInput

                # UPDATE CREDENTIAL PROFILE WITH NEW KEYS
                Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs $ProfileName

                # SET AS DEFAULT PROFILE
                if ($PSBoundParameters.ContainsKey('Default')) {
                    Initialize-AWSDefaultConfiguration -ProfileName $ProfileName -Region $Region
                }

                # RETURN TEXT RESULT
                'Profile [{0}] updated.' -f $ProfileName
            }
            Delete {
                # VALIDATE EXISTENCE OF SPECIFIED PROFILE
                if (-Not (Confirm-Profile -ProfileName $ProfileName)) {
                    Write-Error -Message ('Profile [{0}] not found' -f $ProfileName) -ErrorAction Stop
                }

                # REMOVE CREDENTIAL PROFILE
                Remove-AWSCredentialProfile -ProfileName $ProfileName

                # RETURN TEXT RESULT
                'Profile [{0}] removed.' -f $ProfileName
            }
        }
    }
    End {
        # RETURN RESULTS
        if ($PSBoundParameters.ContainsKey('List')) {
            Write-Output -InputObject $Result
        }
        else {
            Write-Output -InputObject $Result, `n
        }
    }
}