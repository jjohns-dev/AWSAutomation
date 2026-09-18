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
    ImportExcel                         = '7.8.9'
    'AWS.Tools.Common'                  = '5.0.132'
    'AWS.Tools.CloudFormation'          = '5.0.132'
    'AWS.Tools.CloudWatch'              = '5.0.132'
    'AWS.Tools.EC2'                     = '5.0.132'
    'AWS.Tools.ElasticLoadBalancingV2'  = '5.0.132'
    'AWS.Tools.IdentityManagement'      = '5.0.132'
    'AWS.Tools.KeyManagementService'    = '5.0.132'
    'AWS.Tools.RDS'                     = '5.0.132'
    'AWS.Tools.Route53'                 = '5.0.132'
    'AWS.Tools.S3'                      = '5.0.132'
    'AWS.Tools.SimpleSystemsManagement' = '5.0.132'
    'AWS.Tools.SecurityToken'           = '5.0.132'
    'AWS.Tools.SSO'                     = '5.0.132'
    'AWS.Tools.SSOOIDC'                 = '5.0.132'
}
