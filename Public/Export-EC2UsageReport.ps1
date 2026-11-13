function Export-EC2UsageReport {
    <#
    .SYNOPSIS
        Generate reports for instances offline and running without reservation
    .DESCRIPTION
        This script iterates through all instances in a give AWS Region and creates
        a list of specific attributes. It then finds the last stop time, user who
        stopped the instance, and calculates the number of days the system has been
        stopped (if possible) and creates a data sheet (CSV). The data sheet is then
        imported into Excel and formatted.  This can be done for a single or
        multiple accounts based on AWS Credentail Profiles.
    .PARAMETER OutputDirectory
        Path to existing folder for report
    .PARAMETER ProfileName
        This is the name of the AWS Credential profile containing the Access Key and
        Secret Key.
    .PARAMETER Credential
        AWS Credential Object
    .PARAMETER Region
        This is the AWS region containing the desired resources to be processed
    .PARAMETER PassThru
        Return path to report file
    .INPUTS
        None.
    .OUTPUTS
        None.
    .EXAMPLE
        PS C:\> Export-EC2UsageReport -Region us-west-1 -ProfileName MyAccount
        Generate new EC2 report for all instances in MyAccount in the us-west-1
        region
    .NOTES
        Status: Stable
    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    Param(
        [Parameter(HelpMessage = 'Path to existing folder for report')]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Alias('DestinationPath')]
        [System.String] $OutputDirectory,

        [Parameter(HelpMessage = 'AWS credential profile name')]
        [ValidateScript({(Get-AWSCredential -ListProfileDetail).ProfileName -contains $_ })]
        [Alias('PN')]
        [System.String[]] $ProfileName,

        [Parameter(HelpMessage = 'AWS credentials object')]
        [ValidateNotNullOrEmpty()]
        [Amazon.Runtime.AWSCredentials[]] $Credential,

        [Parameter(HelpMessage = 'AWS region')]
        [ValidateScript( { (Get-AWSRegion).Region -contains $_ })]
        [System.String] $Region,

        [Parameter(HelpMessage = 'Return path to report file')]
        [System.Management.Automation.SwitchParameter] $PassThru
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

        function Get-AvailableEBS {
            [CmdletBinding(DefaultParameterSetName = '_profile')]
            [OutputType([System.Object[]])]
            Param(
                [Parameter(Mandatory, ParameterSetName = '_profile', HelpMessage = 'AWS credential profile name')]
                [ValidateScript( { (Get-AWSCredential -ListProfileDetail).ProfileName -contains $_ })]
                [System.String[]] $ProfileName,

                [Parameter(Mandatory, ParameterSetName = '_credential', HelpMessage = 'AWS credentials object')]
                [ValidateNotNullOrEmpty()]
                [Amazon.Runtime.AWSCredentials[]] $Credential,

                [Parameter(HelpMessage = 'Name of desired AWS Region.')]
                [ValidateScript( { (Get-AWSRegion).Region -contains $_ })]
                [System.String] $Region
            )

            $results = [System.Collections.Generic.List[System.Object]]::new()
            $awsParams = @{ Region = $Region; Filter = @{Name = "status"; Values = "available" } }

            if ( $PSCmdlet.ParameterSetName -eq '_profile' ) {
                foreach ( $name in $ProfileName ) {
                    foreach ( $volume in (Get-EC2Volume -ProfileName $name @awsParams) ) {
                        $volume | Add-Member -MemberType NoteProperty -Name Account -Value $name
                        $results.Add($volume)
                    }
                }
            }
            if ( $PSCmdlet.ParameterSetName -eq '_credential' ) {
                foreach ( $cred in $Credential ) {
                    $account = (Get-STSCallerIdentity -Credential $cred -Region $Region).Account
                    foreach ( $volume in (Get-EC2Volume -Credential $cred @awsParams) ) {
                        $volume | Add-Member -MemberType NoteProperty -Name Account -Value $account
                        $results.Add($volume)
                    }
                }
            }

            Write-Verbose -Message ('Number of volumes: [{0}]' -f $results.Count)
            $results
        }

        # SET OUTPUT REPORT PATH
        $reportName = 'EC2UsageReport'
        $date = Get-Date -Format "yyyy-MM"

        if ( $PSBoundParameters.ContainsKey('OutputDirectory') ) {
            $ReportPath = Join-Path -Path $OutputDirectory -ChildPath ('{0}_{1}.xlsx' -f $date, $reportName)
        }
        else {
            $ReportPath = Join-Path -Path (Join-Path -Path $HOME -ChildPath 'Desktop') -ChildPath ('{0}_{1}.xlsx' -f $date, $reportName)
        }

        # SET VAR FOR INSTANCES
        $ec2 = [System.Collections.Generic.List[System.Object]]::new()
        $90DayList = [System.Collections.Generic.List[System.Object]]::new()
        $60DayList = [System.Collections.Generic.List[System.Object]]::new()

        # CREATE PARAMETERS FOR EXCEL EXPORT
        $excelParams = @{
            Path         = $ReportPath
            AutoSize     = $true
            FreezeTopRow = $true
            MoveToEnd    = $true
            BoldTopRow   = $true
            AutoFilter   = $true
            Style        = (New-ExcelStyle -Bold -Range '1:1' -HorizontalAlignment Center)
        }

        # SET AUTHENTICATION
        if ( $PSBoundParameters.ContainsKey('ProfileName') ) {
            $ec2 = foreach ( $p in $ProfileName ) { (Get-EC2Instance -ProfileName $p -Region $Region).Instances }
            $allVolumes = Get-AvailableEBS -ProfileName $ProfileName -Region $Region | Group-Object -Property Account | Select-Object Name, Count
        }
        if ( $PSBoundParameters.ContainsKey('Credential') ) {
            $ec2 = foreach ( $c in $Credential ) { (Get-EC2Instance -Credential $c -Region $Region).Instances }
            $allVolumes = Get-AvailableEBS -Credential $Credential -Region $Region | Group-Object -Property Account | Select-Object Name, Count
        }
        Write-Verbose -Message ('EC2 instances: {0}' -f $ec2.Count)
        Write-Verbose -Message ('EBS volumes: {0}' -f $allVolumes.Count)
    }
    Process {
        # ADD DATA VALUES FOR COST INFO
        Get-CostInfo -Region $Region -Instance $ec2 | Out-Null

        foreach ( $i in $ec2 ) {
            if ( $i.Status -eq 'stopped' ) { $90DayList.Add($i) }
            if ( $i.Status -eq 'running' ) { $60DayList.Add($i) }
        }
        Write-Verbose -Message ('Stopped instances: {0}' -f $90DayList.Count)
        Write-Verbose -Message ('Running volumes: {0}' -f $60DayList.Count)

        # IF EXISTS EXPORT 60 DAY LIST
        if ( $60DayList.Count -ge 1 ) {
            # PROPERTIES ARE DEFINED IN EC2.types.ps1xml
            $60DayList | Select-Object -Property Running | Sort-Object LastStart | Export-Excel @excelParams -WorksheetName '60-Day Report'
        }

        # IF EXISTS EXPORT 90 DAY LIST
        if ( $90DayList.Count -gt 0 ) {
            # PROPERTIES ARE DEFINED IN EC2.types.ps1xml
            $90DayList | Select-Object -Property Stopped | Sort-Object DaysStopped | Export-Excel @excelParams -WorksheetName '90-Day Report'
        }

        # EXPORT VOLUMES LIST
        if ( $allVolumes ) {
            $allVolumes | Export-Excel @excelParams -WorksheetName 'Unattached EBS'
        }
    }
    End {
        # RETURN REPORT PATH
        if ( $PSBoundParameters.ContainsKey('PassThru') ) {
            Write-Output $ReportPath
        }
    }
}