@{
    # PSUsePSCredentialType and PSAvoidUsingPlainTextForPassword are excluded
    # module-wide: this module wraps the AWS Tools for PowerShell, which uses
    # Amazon.Runtime.AWSCredentials objects and named profiles rather than
    # PSCredential. Adopting PSCredential would require a translation shim on
    # every public function for no benefit. Both rules fire on the -Credential
    # parameter that nearly every public function exposes, so suppressing them
    # in place would mean a SuppressMessageAttribute on each one carrying no
    # signal a reader does not already get from this comment.
    #
    # PSAvoidGlobalVars and PSAvoidUsingConvertToSecureStringWithPlainText are
    # NOT excluded here. Their single legitimate occurrence each is suppressed
    # in place via SuppressMessageAttribute on Set-AwsSsoCredential and
    # Export-SECSecret respectively, so any new violation elsewhere will fire.
    ExcludeRules = @(
        'PSUsePSCredentialType'
        'PSAvoidUsingPlainTextForPassword'
    )
    Severity     = @(
        'Warning',
        'Error'
    )
    Rules        = @{}
}
