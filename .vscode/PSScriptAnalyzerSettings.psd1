@{
    # EDITOR ONLY. VS Code's PowerShell extension reads this file through
    # powershell.scriptAnalysis.settingsPath in .vscode/settings.json. The build, its
    # Analyze task and the Security-tab scan never read it: they use the shared
    # pwsh-module-ci analyzer settings plus PSScriptAnalyzerExcludeRules in
    # Build/harness.psd1.
    #
    # Keep ExcludeRules identical to Build/harness.psd1, which records why these two
    # rules are excluded module-wide. In short: nearly every public function takes an
    # [Amazon.Runtime.AWSCredentials[]] -Credential, so both rules fire on 25 of the 36
    # public functions (measured 2026-11-12, PSScriptAnalyzer 1.25.0). Suppressing them
    # in place would put the same SuppressMessageAttribute pair on each of those 25 with
    # no signal. Use in-place suppression for anything narrower.
    ExcludeRules = @(
        'PSUsePSCredentialType'
        'PSAvoidUsingPlainTextForPassword'
    )
}
