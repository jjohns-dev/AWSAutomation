function Get-S3Url {
    <#
    .SYNOPSIS
        Get S3 object URL
    .DESCRIPTION
        Get S3 object URL
    .PARAMETER BucketName
        S3 Bucket name
    .PARAMETER Key
        S3 Object key
    .PARAMETER Region
        AWS Region
    .INPUTS
        None.
    .OUTPUTS
        System.String.
    .EXAMPLE
        PS C:\> Get-S3Url -BucketName myBucket -Key Files/Test/readme.txt
        Returns the URL "https://myBucket.s3.us-east-1.amazonaws.com/Files/Test/readme.txt"
    .NOTES
        Status: Stable
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $BucketName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidatePattern('^[\w\./-]+$')]
        [System.String] $Key,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateScript({ (Get-AWSRegion).Region -contains $_ })]
        [System.String] $Region
    )
    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    Process {
        # CHECK FOR REGION
        if ($PSBoundParameters.ContainsKey('Region')) {
            # RETURN URL
            'https://{0}.s3.{1}.amazonaws.com/{2}' -f $BucketName, $Region, $Key
        }
        else {
            # RETURN URL WITHOUT REGION
            'https://{0}.s3.amazonaws.com/{1}' -f $BucketName, $Key
        }
    }
}