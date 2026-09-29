# AGENTS.md

PowerShell module wrapping AWS Tools for PowerShell with reporting, inventory, and operational helpers. Read [CONTRIBUTING.md](CONTRIBUTING.md) for function structure, comment-based help layout, and style rules — this file covers what that guide does not.

## Layout

| Path | Contents |
| ---- | -------- |
| `Public/` | One exported function per file, named `Verb-Noun.ps1`. This is the module's API surface. |
| `Private/` | `.types.ps1xml` / `.format.ps1xml` extensions only — no private functions today. |
| `Tests/Unit/` | One file per public function, `Verb-Noun.tests.ps1`. |
| `Tests/Common/` | Help, manifest, and meta tests that run against **every** exported function automatically. |
| `Build/` | psake build (`build.psake.ps1`), entry point (`build.ps1`), analyzer settings. |

Adding a public function means: the `.ps1` in `Public/`, a matching `Tests/Unit/` file, and a `FunctionsToExport` entry in `AWSAutomation.psd1`.

## Commands

```pwsh
./Build/build.ps1 -TaskList Analyze   # PSScriptAnalyzer
./Build/build.ps1 -TaskList Test      # Pester
./Build/build.ps1 -TaskList Cleanup   # delete Staging/ and Artifacts/
```

Add `-ResolveDependency` on a clean checkout. `Analyze` and `Test` both generate `Staging/` and `Artifacts/`; **run `Cleanup` when you are done** — they are gitignored but should not be left behind.

Scanning with `Invoke-ScriptAnalyzer -Path . -Recurse` while `Staging/` exists double-counts every finding in `Public/`, because `Staging/` holds a copy. Clean up first, or read the counts with that in mind.

## Tests

Pester 5+. Never reach AWS — mock it.

- Import via the BuildHelpers env vars the `Init` task sets: `$env:BHProjectName`, `$env:BHPSModuleManifest`. Do not hard-code the module name.
- Mock anything the function calls with `-ModuleName $env:BHProjectName`, or the real cmdlet runs inside the module. This includes cmdlets invoked from `[ValidateScript]` blocks, which run at parameter-binding time.
- Test names read as sentences: `'returns ...'`, `'rejects ...'`, `'passes ... to ...'`.
- A mock that fails on *binding* rather than logic usually needs `-RemoveParameterType`. AWS.Tools cmdlets expose `-NetworkCredential` as `[PSCredential]` with `ValueFromPipeline`, and its transform throws on any piped object that is not a credential.
- CI runs `ubuntu-latest` only, by deliberate choice — Windows runners are slow and the `AWS.Tools.*` dependency install is slower. Do not propose adding them. A `.tests.windows.ps1` file would never execute, so force `$IsWindows` instead: it is `ReadOnly, AllScope`, so `Set-Variable -Name 'IsWindows' -Scope Global -Force` works and module functions observe it. Restore it in `AfterEach`. Code guarded on `[System.Environment]::OSVersion.Platform` cannot be faked this way.

## PSScriptAnalyzer

Two different scopes, and confusing them wastes time:

- `Build/build.ps1 -TaskList Analyze` (and CI's `validate` job) analyzes **`Staging/` only**, so no test or build file is ever covered.
- `.github/workflows/pssa-sarif.yml` scans the **whole repo** and feeds the Security tab. It honors `Build/PSScriptAnalyzerSettings.psd1` and `SuppressMessageAttribute`, and posts PR review comments that auto-resolve once an alert closes.

Policy: suppress **in place** with `SuppressMessageAttribute` plus a real `Justification`, so a new violation elsewhere still fires. `ExcludeRules` in the settings file is reserved for rules that fire on a uniform, settled API decision across the module — currently `PSUsePSCredentialType` and `PSAvoidUsingPlainTextForPassword`, both triggered by the `[Amazon.Runtime.AWSCredentials[]] $Credential` parameter nearly every public function exposes. Record the reasoning in the settings file header when adding one.

## Versioning and release

`ModuleVersion` in `AWSAutomation.psd1` follows the commit type: **`feat` → minor, `fix` → patch.** Consistent since 0.9.2; ignore older history. The granularity is the commit type, not "new function vs. new parameter" — a parameter-only change typed `feat` still takes a minor bump. If a bump would deviate, retype the commit instead.

Merging publishes nothing. `release.yml` is gated on a `v<x.y.z>` tag push, which is a separate deliberate step after the version bump lands on `main`.

## Merging

The `protect` ruleset covers `main` only:

- Commits must be **signed**.
- **Linear history** — squash or rebase merge, never a merge commit.
- No force-push, no deletion, PR required, status checks required.

Feature branches are unprotected.
