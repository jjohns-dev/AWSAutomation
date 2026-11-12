@{
    # OPTIONAL. Copy this file to Build/harness.psd1 only if your module needs one of the
    # settings below. A module that needs none of them should not have the file at all.
    # Any key not listed here stops the build, so a misspelt setting cannot be silently ignored.

    # PSScriptAnalyzer rules to exclude for this module only. String array; default none.
    # Used by AWSAutomation: AWS.Tools.* authenticates with AWSCredentials, never PSCredential.
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
    PSScriptAnalyzerExcludeRules = @('PSUsePSCredentialType', 'PSAvoidUsingPlainTextForPassword')

    # Pester tags to exclude from the gating build. String array; default none.
    # Used by PS.SSL: tests tagged Network call a live third-party endpoint.
    # PesterExcludeTag = @('Network')

    # Run this module's tests under Set-StrictMode -Version Latest. Boolean; default $false.
    # Used by PS.DCU. Confirm your tests pass under strict mode before turning it on.
    # PesterStrictMode = $true
}
