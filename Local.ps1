[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Package
)

# Ensure you have the NuGet module installed
Install-Module -Name NuGet -Force -SkipPublisherCheck

# Navigate to the src/Aks directory
Push-Location src/Aks

# Create the module manifest
Update-ModuleManifest -Path ./AzKube.psd1 -RootModule ./AzKube.psm1

if ($Package) {
    # Package the module
    New-NuGetPackage -Path ./AzKube.psd1 -OutputDirectory ../../

    # Install the module from the local path
    Install-Module -Name AzKube -Scope CurrentUser -Repository PSGallery -Force -SkipPublisherCheck -SourceLocation "../../"
}
else {
    $path = (Resolve-Path '../../').Path
    if ($env:PSModulePath -notlike "*$path*") {
        $env:PSModulePath += ";$path"
    }
}

# Navigate back to the root directory
Pop-Location

# Import the module
Import-Module AzKube

# Verify the module is imported
Get-Module -Name AzKube

# # Run Pester tests
# Invoke-Pester -Path ./tests/Aks/private/Aks-Utilities.Tests.ps1