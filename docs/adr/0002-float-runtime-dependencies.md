# ADR 2: Float runtime dependencies to latest, pin build tooling

## Status

Accepted — 2026-10-28

## Context

- `AWSAutomation.psd1` lists 14 `AWS.Tools.*` modules and `ImportExcel` in `RequiredModules` with no version constraint, so a fresh install of this module resolves whatever is current.
- `Build/depend.psd1` pinned CI to `AWS.Tools` 5.0.132 (published 2026-01-12) and `ImportExcel` 7.8.9 (published 2024-05-18). By 2026-10-28 the gallery had 192 later `AWS.Tools.Common` 5.x releases, roughly one every 1.5 days. CI was testing a combination a fresh install would not get.
- Unit tests mock AWS.Tools cmdlets, and Pester binds a mock against the real command's parameter metadata. A change in that metadata breaks tests in this repo and calls in consumers alike; an exact pin only delays when CI sees it. `Set-AwsSsoCredential.tests.ps1`'s `-RemoveParameterType` workaround shows the coupling.
- The pinned versions were still available: `AWS.Tools.Common` lists 1,371 versions back to 3.3.563.0 (checked 2026-10-28). The concern is staleness, not availability.
- `Pester`, `psake`, `PSScriptAnalyzer` and `PlatyPS` change test and analysis outcomes, not the module's runtime behaviour. Consumers never install them.
- A bounded NuGet range does not yield the newest member under PSResourceGet 1.2.0 (measured 2026-10-28, recorded in #100). `Find-PSResource` returns range results in a non-semantic order and the installer takes the first: `[5.0.0,6.0.0)` on `AWS.Tools.Common` resolved to 5.0.300 against an in-range latest of 5.0.324, and `[7.0.0,8.0.0)` on `ImportExcel` resolved to 7.8.9 against 7.8.10. Omitting `-Version` resolved to the latest of both.
- PSResourceGet also installs a module's dependencies, so `AWS.Tools.Common` can be installed by another `AWS.Tools.*` module before the loop reaches its own entry (#98's run warned it was already installed).
- Per #100, no other module repo in the fleet depends on `AWS.Tools`, so this is not fleet-wide policy.

## Decision

- We will set every `RequiredModules` dependency in `Build/depend.psd1`, the 14 `AWS.Tools.*` modules and `ImportExcel`, to the sentinel `'latest'`, and `Build/build.ps1` will omit `-Version` for it.
- We will keep `Pester`, `psake`, `PSScriptAnalyzer` and `PlatyPS` exactly pinned.
- We will not use a version range to bound the floated modules.
- We will log every installed version of every dependency after resolution, because the CI log becomes the only record of what a build ran against.

## Consequences

- CI tests the same dependency versions a consumer installing today gets, so an upstream breaking change turns this repo red before a consumer reports it.
- Builds are no longer reproducible from the repository alone. Reproducing a past build means reading its resolved versions out of that run's CI log, which expires with the run's log retention.
- An upstream release can turn CI red on a day nothing in this repo changed, and that failure blocks unrelated PRs until it is fixed or worked around.
- There is no upper major bound. An eventual `AWS.Tools` 6.0 will be picked up unannounced and may break CI; that red build is the intended signal, preferred over silently staying on an end-of-support major.
- A dependency-driven install and the explicit install can land on different versions of the same module during one run, for example if AWS publishes mid-run. The resolution log makes that visible; nothing prevents it.
- CI runs on `ubuntu-latest` only, so floated versions are never validated on Windows here.
- `depend.psd1` now mixes two policies; adding a dependency means deciding which policy it belongs to.
