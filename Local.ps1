[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Package, 

    [Parameter()]
    [Int16]
    $majorVersion = 0,

    [Parameter()]
    [Int16]
    $minorVersion = 0,

    [Parameter()]
    [Int16]
    $patchVersion = 0,

    [Parameter()]
    [switch]
    $Analyze,

    [Parameter()]
    [string]
    $NuGetApiKey = "REPLACE_FOR_REAL_NUGET_PUBLISHING"
)

# Ensure you have the NuGet module installed if not install it
if (-not (Get-Module -Name NuGet -ListAvailable)) {
    Install-Module -Name NuGet -Force -SkipPublisherCheck
}

# Navigate to the src/Aks directory
Push-Location src/Aks

# Increment the module version to the format yymmdd.hhmm.ss
if ($Package) {
    $moduleVersion = $("$majorVersion.$minorVersion.$patchVersion")
}
else {
    $moduleVersion = $(Get-Date).ToString('yyMMdd.HHmm.ss')
}
# $moduleVersion = $("$majorVersion.$minorVersion.$patchVersion+$((Get-Date).ToString('yyMMdd.HHmm.ss'))")
Write-Host "Incrementing module version to $moduleVersion"


# Create the module manifest
Update-ModuleManifest -Path ./AzKube.psd1 -RootModule ./AzKube.psm1 `
    -Author 'David Mealo' `
    -Copyright '(c) David Mealo. All rights reserved.' `
    -CompanyName 'Undecided' `
    -Description 'Module for managing AKS clusters' `
    -ModuleVersion $moduleVersion `
    -RequiredModules @('Az', 'PSMenu')

# Test the module manifest
Test-ModuleManifest -Path ./AzKube.psd1

if ($Package) {
    # Set up project /NuGetRepo folder as a NuGet repository
    if (-not (Test-Path ./NuGetRepo)) {
        New-Item -Path ./NuGetRepo -ItemType Directory
    }
    $NuGetRepository = Resolve-Path('./NuGetRepo')

    # Format the NuGet repository path to file UNC for the Publish-Module command
    $NuGetRepositoryUri = [Uri]::new($NuGetRepository)
    
    # Register the NuGet repository
    Register-PSRepository -Name AzKubeRepo -ScriptSourceLocation $NuGetRepositoryUri -SourceLocation $NuGetRepositoryUri -PublishLocation $NuGetRepositoryUri -InstallationPolicy Trusted

    # Package the module using the module manifest, Publish-Module
    Publish-Module -Path ./AzKube.psd1 -NuGetApiKey $NuGetApiKey -Repository $NuGetRepositoryUri -Force -Verbose

    # Install the module from the NuGet repository
    Install-Module -Name AzKube -Repository AzKubeRepo -Force

    # If already imported, remove the module, then import it
    if (Get-Module -Name AzKube) {
        Remove-Module -Name AzKube -Force

        # Verify the module is removed
        Get-Module -Name AzKube
    }

    # Import the module
    Import-Module AzKube -Force

    # Verify the module is imported
    Get-Module -Name AzKube
}
else {
    $path = (Resolve-Path '.').Path
    if ($env:PSModulePath -notlike "*$path*") {
        $env:PSModulePath += ";$path"
    }
    Write-Host "Module path: $path"
    Import-Module "$path\AzKube.psm1" -Force
}    

# Navigate back to the root directory
Pop-Location

# Verify the module is imported
Get-Module -Name AzKube

if ($Analyze) {
    # Ensure you have the PSScriptAnalyzer module installed if not install it
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Host "Installing PSScriptAnalyzer module"
        Install-Module -Name PSScriptAnalyzer -Force
    }
    # Analyze the module
    $analysis = Invoke-ScriptAnalyzer -Path ./src/Aks/AzKube.psm1 -Recurse -Severity Warning -Settings PSGallery
    $analysis
}

# # Run Pester tests
# Invoke-Pester -Path ./tests/Aks/private/Aks-Utilities.Tests.ps1