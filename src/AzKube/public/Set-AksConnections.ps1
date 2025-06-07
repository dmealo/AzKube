# Set-AksConnections.ps1
# Description: This script gets kubectl credentials for selected or all AKS clusters in all subscriptions and tests the connections to the clusters.
# Prerequisites: WinGet (install in Store for auto-updating, else static version via: `Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.appxbundle ; Add-AppxPackage -Path winget.appxbundle`)

function Set-AksConnections {
    <#
    .SYNOPSIS
    Configures kubectl credentials and connections for Azure Kubernetes Service (AKS) clusters.

    .DESCRIPTION
    Set-AksConnections retrieves kubectl credentials for selected or all AKS clusters across all 
    subscriptions in your Azure tenant. It configures local kubectl context and optionally tests 
    the connections to ensure they are working properly.

    .PARAMETER ProxyUrl
    Specifies the proxy URL to be used for all AKS clusters. If not provided, the function will use 
    the default proxy URL from environment variables or prompt for configuration.

    .PARAMETER SkipProxyAll
    When specified, skips setting proxy configuration on any AKS cluster during credential setup.

    .PARAMETER SkipTestConnections
    When specified, skips testing connections to the AKS clusters after setting up credentials.
    This can speed up the process when you only need to configure credentials.

    .PARAMETER SetupAllWithDefaults
    When specified, processes all AKS clusters found across all subscriptions using default settings 
    without prompting for user input. This is useful for automated credential setup scenarios.

    .PARAMETER SelectAll
    When specified, initially selects all AKS clusters in the interactive menu, allowing for quick 
    bulk credential setup.

    .EXAMPLE
    Set-AksConnections
    
    Launches the interactive interface to select AKS clusters and configure their kubectl credentials.

    .EXAMPLE
    Set-AksConnections -SetupAllWithDefaults
    
    Configures kubectl credentials for all AKS clusters with default settings without user interaction.

    .EXAMPLE
    Set-AksConnections -ProxyUrl "http://proxy.company.com:8080" -SelectAll
    
    Configures credentials for all clusters with a specific proxy URL.

    .EXAMPLE
    Set-AksConnections -SkipTestConnections
    
    Configures kubectl credentials but skips testing the connections, useful for faster setup.

    .EXAMPLE
    Set-AksConnections -SkipProxyAll -SetupAllWithDefaults
    
    Configures credentials for all clusters without proxy settings and without user interaction.

    .INPUTS
    None. This function does not accept pipeline input.

    .OUTPUTS
    None. This function configures kubectl credentials and displays connection test results to the console.

    .NOTES
    Prerequisites:
    - Azure CLI must be installed and configured
    - kubectl must be installed for cluster operations
    - PowerShell module PSMenu is required for interactive menus
    - User must have appropriate permissions to access AKS clusters

    This function modifies your local kubectl configuration (~/.kube/config) by adding contexts 
    for the selected AKS clusters.

    .LINK
    https://github.com/dmealo/AzKube
    #>
    [CmdletBinding()]
    param (
        # Proxy URL to be used for all AKS clusters
        [Parameter()]
        [string]
        $ProxyUrl = "",

        # Skip setting proxy on any AKS cluster
        [Parameter()]
        [switch]
        $SkipProxyAll,

        # Skip testing connections to the AKS clusters
        [Parameter()]
        [switch]
        $SkipTestConnections,

        # Simple mode to get kubectl credentials for all AKS clusters found on all subscriptions in logged in tenant without asking for user input using default proxy
        [Parameter()]
        [switch]
        $SetupAllWithDefaults,

        # Initially select all AKS clusters for getting kubectl credentials
        [Parameter()]
        [switch]
        $SelectAll
    )

    . "$PSScriptRoot\..\private\Aks-Utilities.ps1"
    . "$PSScriptRoot\..\private\Aks-Ui-Utilities.ps1"

    $ProxyUrl = Get-DefaultProxyUrl -ProxyUrl $ProxyUrl

    Install-AzureCli
    Install-PsMenu

    # Get all AKS clusters into a variable using Azure Resource Graph
    $aksClusters = Get-AksClusters
    if ($null -eq $aksClusters) {
        exit 0
    }

    # Show AKS clusters as a simple menu for selection
    if ($SetupAllWithDefaults) {
        # Continue execution
        Write-Host "Setting up all AKS clusters with default settings:" -ForegroundColor Cyan
        Show-ObjectArray $aksClusters Cyan
    }
    else {
        $aksClusters = Show-ClusterMenu -Clusters $aksClusters -SelectAll:$SelectAll -HideSummary:$false -Title "Select AKS cluster(s) to get kubectl credentials for or Esc to exit:" -MultiSelect:$true
        if ($null -eq $aksClusters) {
            exit 0
        }
    }

    # Get kubectl credentials for the selected AKS clusters
    Get-KubectlCredentialsForAksClusters $aksClusters $ProxyUrl $SkipProxyAll $SetupAllWithDefaults

    # Test connections to the AKS clusters using kubectl version command
    if ($SkipTestConnections) {
        Write-Host "Skipping testing connections to the AKS clusters."
    }
    else {
        Test-ConnectionsToAksClusters $aksClusters
    }

}
