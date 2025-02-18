# Description: This script will remove the AzKube module from the local repository and unregister the NuGet repository.
#
# .\Undo-Local.ps1
#

$nugetRepoPath = "$PSScriptRoot\src\AzKube\NuGetRepo"

# Remove the module from the local repository
if (Get-Module -Name AzKube) {
    Remove-Module -Name AzKube -Force

    # Verify the module is removed
    if (!(Get-Module -Name AzKube -ErrorAction SilentlyContinue)) {
        Write-Host "The AzKube module has been removed"
    }
    else {
        Write-Host "The AzKube module has not been removed"
    }
}

# Uninstall the module
if (Get-Module -Name AzKube -ListAvailable) {
    Uninstall-Module -Name AzKube -Force -AllVersions
}

# Unregister the NuGet repository
Unregister-PSRepository -Name AzKubeRepo -ErrorAction SilentlyContinue

Push-Location $PSScriptRoot

# Remove the NuGet repository
if (Test-Path $nugetRepoPath) {
    Remove-Item -Path $nugetRepoPath -Force -Recurse
}

# Remove the module from the PSModulePath
$path = (Resolve-Path './src/AzKube').Path
Write-Debug $path
if ($env:PSModulePath -like "*$path*") {
    $escapedAzKubePath = $path -replace "\\", "\\\\\\\\"
    Write-Debug $escapedAzKubePath
    $escapedPSModulePath = $env:PSModulePath -replace "\\", "\\\\"
    $removedPath = $escapedPSModulePath -replace ";$escapedAzKubePath", ""
    Write-Debug $removedPath
    if ($removedPath -ne '') {
        $env:PSModulePath = $removedPath -replace "\\\\\\\\", "\"
    }
}
Pop-Location