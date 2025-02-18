[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Package,

    [Parameter()]
    [switch]
    $Analyze,

    [Parameter()]
    [switch]
    $RunAfterBuild
)

Begin {
}

Process {
    # Build the module
    Push-Location $PSScriptRoot
    .\Build.ps1 -Local:$true -Package:$Package -Analyze:$Analyze
    Pop-Location

    if ($RunAfterBuild) {
        # Run the module
        Set-AksClusters
    }
}

End {
}