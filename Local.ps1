[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Package = $true, 

    [Parameter()]
    [Int16]
    $majorVersion = 0,

    [Parameter()]
    [Int16]
    $minorVersion = 1,

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

Begin {
    Write-Debug "DEBUG MODE ENABLED"
}

Process {

    # Ensure you have the NuGet module installed if not install it
    if (-not (Get-Module -Name NuGet -ListAvailable)) {
        Install-Module -Name NuGet -Force -SkipPublisherCheck
    }

    # Navigate to the src/AzKube directory
    Push-Location src/AzKube

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
        ### Set up project /NuGetRepo folder as a NuGet repository

        # Create the NuGet repository folder path (ensure it's correct)
        $repoPath = Join-Path (Get-Location) "NuGetRepo"
        if (-not (Test-Path $repoPath)) {
            Write-Debug "Creating NuGet repository directory at $repoPath"
            New-Item -Path $repoPath -ItemType Directory | Out-Null
        }

        # If the module is already installed, uninstall it
        Write-Debug "Checking for existing module installation"
        if (Get-Module -Name AzKube -ListAvailable) {
            Write-Debug "Uninstalling module"
            Uninstall-Module -Name AzKube -Force -AllVersions
        }
        
        # If the module is already in the NuGet repository, remove it
        Write-Debug "Checking for existing module in the NuGet repository"
        # Delete the module from the NuGet repository file system
        $modulePath = Join-Path $repoPath "AzKube.$moduleVersion.nupkg"
        if (Test-Path $modulePath) {
            Write-Debug "Removing existing module from the NuGet repository"
            Remove-Item -Path $modulePath -Force
        }

        # If the NuGet repository exists, remove it
        Write-Debug "Checking for existing NuGet repository"
        if (Get-PSRepository -Name AzKubeRepo -ErrorAction SilentlyContinue) {
            Write-Debug "Removing existing NuGet repository to recreate it"
            Unregister-PSRepository -Name AzKubeRepo -ErrorAction SilentlyContinue
        }

        # Register the NuGet repository with a proper name
        if (-not (Get-PSRepository -Name "AzKubeRepo" -ErrorAction SilentlyContinue)) {
            Write-Debug "Registering NuGet repository 'AzKubeRepo' with source location $repoPath"
            Register-PSRepository -Name "AzKubeRepo" -SourceLocation $repoPath -InstallationPolicy Trusted | Out-Null
        }

        # Package the module using the module manifest, Publish-Module
        Write-Debug "Packaging the module"
        Publish-Module -Path (Get-Location) -NuGetApiKey $NuGetApiKey -Repository AzKubeRepo -Force -Verbose

        # Install the module from the NuGet repository
        Write-Debug "Installing the module from the NuGet repository"
        Install-Module -Name AzKube -Repository AzKubeRepo -Force

        # If already imported, remove the module, then import it
        Write-Debug "Checking for existing module installation"
        if (Get-Module -Name AzKube) {
            Write-Debug "Removing existing module installation"
            Remove-Module -Name AzKube -Force

            # Verify the module is removed
            Write-Debug "Verifying the module is removed"
            Get-Module -Name AzKube
        }

        # Import the module
        Write-Debug "Importing the module"
        Import-Module AzKube -Force

        # Verify the module is imported
        Write-Debug "Verifying the module is imported"
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

    # Verify the module is imported
    Get-Module -Name AzKube

    # Navigate back to the root directory
    Pop-Location

    if ($Analyze) {
        # Ensure you have the PSScriptAnalyzer module installed if not install it
        if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
            Write-Host "Installing PSScriptAnalyzer module"
            Install-Module -Name PSScriptAnalyzer -Force
        }
        # Analyze the module
        $analysis = Invoke-ScriptAnalyzer -Path ./src/AzKube/AzKube.psm1 -Recurse -Severity Warning -Settings PSGallery
        $analysis
    }

    # # Run Pester tests
    # Invoke-Pester -Path ./tests/AzKube/private/Aks-Utilities.Tests.ps1

}

End {
}