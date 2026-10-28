@{
    # Defaults for all dependencies
    PSDependOptions  = @{
        Target     = 'CurrentUser'
        Parameters = @{
            # Use a local repository for offline support
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }

    }

    # Dependency Management modules
    # PackageManagement = '1.2.2'
    # PowerShellGet     = '2.0.1'

    # Common modules
    Pester                              = '6.2.0'
    PlatyPS                             = '0.14.2'
    psake                               = '4.9.1'
    #PSDeploy         = '1.0.5'
    PSScriptAnalyzer                    = '1.24.0'
    # REQUIRED FOR THIS SPECIFIC MODULE
    ImportExcel                         = 'latest'
    'AWS.Tools.Common'                  = 'latest'
    'AWS.Tools.CloudFormation'          = 'latest'
    'AWS.Tools.CloudWatch'              = 'latest'
    'AWS.Tools.EC2'                     = 'latest'
    'AWS.Tools.ElasticLoadBalancingV2'  = 'latest'
    'AWS.Tools.IdentityManagement'      = 'latest'
    'AWS.Tools.KeyManagementService'    = 'latest'
    'AWS.Tools.RDS'                     = 'latest'
    'AWS.Tools.Route53'                 = 'latest'
    'AWS.Tools.S3'                      = 'latest'
    'AWS.Tools.SimpleSystemsManagement' = 'latest'
    'AWS.Tools.SecurityToken'           = 'latest'
    'AWS.Tools.SSO'                     = 'latest'
    'AWS.Tools.SSOOIDC'                 = 'latest'
}
