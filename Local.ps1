[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Package
)

# Ensure you have the NuGet module installed if not install it
if (-not (Get-Module -Name NuGet -ListAvailable)) {
    Install-Module -Name NuGet -Force -SkipPublisherCheck
}

# Navigate to the src/Aks directory
Push-Location src/Aks

# Increment the module version to the format yymmdd.hhmm.sss
$moduleVersion = (Get-Date).ToString('yyMMdd.HHmm.ss')
Write-Host "Incrementing module version to $moduleVersion"


# Create the module manifest
Update-ModuleManifest -Path ./AzKube.psd1 -RootModule ./AzKube.psm1 `
    -Author 'David Mealo' `
    -Copyright '(c) David Mealo. All rights reserved.' `
    -CompanyName 'Undecided' `
    -Description 'Module for managing AKS clusters' `
    -ModuleVersion $moduleVersion `

if ($Package) {
    # Package the module
    New-NuGetPackage -Path ./AzKube.psd1 -OutputDirectory ../../

    # Install the module from the local path
    Install-Module -Name AzKube -Scope CurrentUser -Repository PSGallery -Force -SkipPublisherCheck -SourceLocation "../../"

    # If already imported, remove the module, then import it
    if (Get-Module -Name AzKube) {
        Remove-Module -Name AzKube -Force
    }
    Import-Module AzKube
}
else {
    $path = (Resolve-Path '../../').Path
    if ($env:PSModulePath -notlike "*$path*") {
        $env:PSModulePath += ";$path"
    }

    Import-Module '../../AzKube' -Force
}

# Navigate back to the root directory
Pop-Location

# Verify the module is imported
Get-Module -Name AzKube

# # Run Pester tests
# Invoke-Pester -Path ./tests/Aks/private/Aks-Utilities.Tests.ps1