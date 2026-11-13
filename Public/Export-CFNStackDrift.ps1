function Export-CFNStackDrift {
    <#
    .SYNOPSIS
        Explort CloudFormation drift results
    .DESCRIPTION
        Explort CloudFormation drift results including difference line numbers.
        The function will wait 5 seconds between initiation drift detection and
        gathering results.
    .PARAMETER Credential
        AWS Credential Object
    .PARAMETER ProfileName
        AWS Credential Profile name
    .PARAMETER Region
        AWS Region
    .PARAMETER StackName
        CloudFormation Stack Name
    .PARAMETER SheetName
        Excel Workbook Sheet name
    .PARAMETER Path
        Output path for report
    .INPUTS
        None.
    .OUTPUTS
        None.
    .EXAMPLE
        PS C:\> Export-CFNStackDrift -ProfileName myProfile -StackName Stack1 -SheetName Stack1 -Path "$HOME\Desktop\StackDrift.xlsx"
        Exports an Excel Spreadsheet containing the objects IN_SYNC and DRIFTED in separate tabs
    .NOTES
        Status: Stable
    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    Param(
        [Parameter(HelpMessage = 'AWS credentials object')]
        [ValidateNotNullOrEmpty()]
        [Amazon.Runtime.AWSCredentials] $Credential,

        [Parameter(HelpMessage = 'AWS credential profile name')]
        [ValidateScript({ (Get-AWSCredential -ListProfileDetail).ProfileName -contains $_ })]
        [System.String] $ProfileName,

        [Parameter(HelpMessage = 'AWS region')]
        [ValidateScript({ (Get-AWSRegion).Region -contains $_ })]
        [System.String] $Region,

        [Parameter(Mandatory, HelpMessage = 'CloudFormation Stack Name')]
        [ValidateNotNullOrEmpty()]
        [System.String] $StackName,

        [Parameter(Mandatory, HelpMessage = 'Excel Workbook Sheet name')]
        [ValidatePattern('[\w-]{3,30}')]
        [System.String] $SheetName,

        [Parameter(HelpMessage = 'Path to new or existing Excel spreadsheet file')]
        [ValidateScript({ Test-Path -Path ([System.IO.Path]::GetDirectoryName($_)) })]
        [ValidateScript({ [System.IO.Path]::GetExtension($_) -eq '.xlsx' })]
        [System.String] $Path
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

        # SET EXCEL PARAMS AND DESIRED PROPERTIES
        $excelParams = @{
            FreezeTopRow = $true
            MoveToEnd    = $true
            BoldTopRow   = $true
            Style        = (New-ExcelStyle -Bold -Range '1:1' -HorizontalAlignment Center)
        }

        if ( $PSBoundParameters.ContainsKey('Path') ) { $excelParams.Add("Path", $Path) }
        else { $excelParams['Path'] = Join-Path -Path (Join-Path -Path $HOME -ChildPath 'Desktop') -ChildPath ('CFNStackDrift_{0:yyyy-MM-dd}.xlsx' -f (Get-Date)) }

        $props = @("PhysicalResourceId", "StackResourceDriftStatus")

        $creds = @{ Region = $Region }
        if ( $PSBoundParameters.ContainsKey('Credential') ) { $creds.Add("Credential", $Credential) }
        if ( $PSBoundParameters.ContainsKey('ProfileName') ) { $creds['ProfileName'] = $ProfileName }
    }
    Process {
        # RUN DRIFT AND WAIT 5 SECONDS FOR RESULTS
        Start-CFNStackDriftDetection @creds -StackName $StackName | Out-Null
        Start-Sleep -Seconds 10

        # GET DRIFT RESULTS
        $driftResults = Get-CFNDetectedStackResourceDrift @creds -StackName $StackName
        $syncd = [System.Collections.Generic.List[System.Object]]::new()

        foreach ( $drift in $driftResults ) {
            # FIND ANY DRIFTS
            if ( $drift.StackResourceDriftStatus -ne 'IN_SYNC' ) {
                # CONVERT RESULTS TO ARRAY OF STRING
                $actual = ($drift.ActualProperties | ConvertFrom-Json | ConvertTo-Json -Depth 10).Split([Environment]::NewLine)
                $expect = ($drift.ExpectedProperties | ConvertFrom-Json | ConvertTo-Json -Depth 10).Split([Environment]::NewLine)

                # CREATE LIST
                $results = [System.Collections.Generic.List[System.Object]]::new()

                # OUTPUT RESULTS
                for ($i = 0; $i -le $actual.Count; $i++) {
                    if ( $actual[$i] -ne $expect[$i] ) {
                        $results.Add([PSCustomObject] @{
                                RESOURCE = $drift.LogicalResourceId
                                LINE     = $i + 1
                                ACTUAL   = $actual[$i]
                                EXPECTED = $expect[$i]
                            }
                        )
                    }
                }

                # WRITE TO EXCEL
                $results | Export-Excel @excelParams -WorksheetName ('{0}-DIFFS' -f $SheetName)
            }
            else {
                $syncd.Add(($drift | Select-Object -Property $props))
            }
        }

        $syncd | Export-Excel @excelParams -WorksheetName $SheetName -AutoSize
    }
}