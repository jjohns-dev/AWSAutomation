# Contributing Guide

- For minor fixes such as a typo, a simple pull request is all that's needed. For more involved changes, please follow the process laid out below.
- :heavy_exclamation_mark: Focus on updating a single function/cmdlet in a Pull Request to make the review processes simpler for the core team.
- [AGENTS.md](AGENTS.md) covers repo layout, test conventions, analyzer policy, versioning, and merge requirements. This guide covers the contribution process and function style.

To propose changes to the existing functions or the creation of a new one, the process is as follows:

1. Create a new [issue](https://github.com/jjohns-dev/AWSAutomation/issues/new) describing the change, whether it is a new function or a modification to an existing one.
2. Once the issue has been discussed and approved:
    1. Clone this repository.
    2. Create a new branch.
    3. Either:
        - Create a new function under `Public/`, following the structure in the [Style Guide](#style-guide) below.
        - Modify the target function in case of an update or refactor.
    4. Add or update the matching test file under `Tests/Unit/`.
    5. Submit your [Pull Request](https://help.github.com/articles/creating-a-pull-request/).

## Style Guide

### Content

The intended purpose of the functions in this module are internal functionality within the secure boundaries, specfically within virtual machines. There should be no dependency on outside libraries.

### Structure

- Start with this general structure

```pwsh
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief one-line description.
    .DESCRIPTION
        Detailed explanation of what the function does.
    .PARAMETER ParameterName
        Description of the parameter.
    .INPUTS
        None.
    .OUTPUTS
        System.Object.
    .EXAMPLE
        PS C:\> Verb-Noun -ParameterName $value
        Description of what this example does.
    .NOTES
        Status: <Stable|Beta|Experimental|Deprecated>
        Comments:
        https://link-to-api-documentation
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param(
        [Parameter(Mandatory, HelpMessage = 'Description of the parameter')]
        [ValidateNotNullOrEmpty()]
        [System.String] $ParameterName
    )
    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    Process {
        # FUNCTION LOGIC
    }
}
```

- Only use approved verbs when naming functions
- Function must include properly defined help
- Use full .NET type names (`[System.String]`, `[System.Int32]`) — never type accelerators
- Use `Write-Error -Message '...' -ErrorAction Stop` instead of `Throw` for terminating errors
- `.NOTES` must start with a `Status:` line; do not include name, author, version, or last-edit date (git history owns that)

## How to get started contributing

Follow these steps:

1. Install [Visual Studio Code (VSCode)](https://code.visualstudio.com/).
2. Open the repository folder in VSCode.
3. You should be prompted to reopen the folder in a dev container. If you are not prompted, open the Command Palette and search for "Dev Containers: Rebuild and Reopen in Container". When complete, you should be connected to the development container as if it was your local machine.
4. You are ready to contribute :+1:

>:alarm_clock: What to verify before pushing the updates?

1. Ensure your changes are passing PSScriptAnalyzer and Pester tests.

    ```pwsh
    ./Build/build.ps1 -ResolveDependency -TaskList Test # run pester
    ./Build/build.ps1 -ResolveDependency -TaskList Analyze # run psscriptanalyzer
    ```

2. Both tasks generate `Staging/` and `Artifacts/` directories in the root of the project. They are gitignored, but delete them when testing is complete.

    ```pwsh
    ./Build/build.ps1 -TaskList Cleanup
    ```

## Release

This project also includes the necessary tools to automate the release of the module via GitHub Actions. The file [release.yml](.github/workflows/release.yml) handles this task.

To create a new release of the module, first update the module manifest with the necessary version number and commit that to the main branch. Then, create a new tag with the same version number and push it to GitHub. This will start the build process and publish a new version of the module to the repo.
