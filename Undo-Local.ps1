# Description: This script will remove the AzKube module from the local repository and unregister the NuGet repository.
#
# .\Undo-Local.ps1
#

# Remove the module from the local repository
if (Get-Module -Name AzKube) {
    Remove-Module -Name AzKube -Force

    # Verify the module is removed
    Get-Module -Name AzKube
}

# Uninstall the module
if (Get-Module -Name AzKube -ListAvailable) {
    Uninstall-Module -Name AzKube -Force -AllVersions
}

# Unregister the NuGet repository
Unregister-PSRepository -Name AzKubeRepo -ErrorAction SilentlyContinue

# Remove the NuGet repository
Remove-Item -Path ./src/AzKube/NuGetRepo -Force -Recurse

# Remove the module from the PSModulePath
$path = (Resolve-Path '.').Path
if ($env:PSModulePath -like "*$path*") {
    $env:PSModulePath = $env:PSModulePath -replace ";$path", ""
}