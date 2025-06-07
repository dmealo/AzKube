# Set-Aks-Clusters.ps1
# Description: This script enables management of optional or all AKS clusters in all subscriptions.
# Prerequisites: WinGet (install in Store for auto-updating, else static version via: `Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.appxbundle ; Add-AppxPackage -Path winget.appxbundle`)

function Set-AksClusters {
    <#
    .SYNOPSIS
    Enables interactive management of Azure Kubernetes Service (AKS) clusters across all subscriptions.

    .DESCRIPTION
    Set-AksClusters provides an interactive interface for managing AKS clusters across all subscriptions 
    in your Azure tenant. It allows you to select clusters and perform various management actions such as 
    getting kubectl credentials, testing connections, and updating cluster resources.

    .PARAMETER ProxyUrl
    Specifies the proxy URL to be used for all AKS clusters. If not provided, the function will use 
    the default proxy URL from environment variables or prompt for configuration.

    .PARAMETER SkipProxyAll
    When specified, skips setting proxy configuration on any AKS cluster during operations.

    .PARAMETER SkipTestConnections
    When specified, skips testing connections to the AKS clusters after performing management actions.

    .PARAMETER SetupAllWithDefaults
    When specified, processes all AKS clusters found across all subscriptions using default settings 
    without prompting for user input. This is useful for automated scenarios.

    .PARAMETER SelectAll
    When specified, initially selects all AKS clusters in the interactive menu, allowing for quick 
    bulk operations.

    .PARAMETER SkipTestActions
    When specified, skips testing actions after performing management operations on clusters.

    .EXAMPLE
    Set-AksClusters
    
    Launches the interactive AKS cluster management interface, allowing you to select clusters 
    and management actions from menus.

    .EXAMPLE
    Set-AksClusters -SetupAllWithDefaults
    
    Processes all AKS clusters with default settings without user interaction, useful for 
    automated deployment scenarios.

    .EXAMPLE
    Set-AksClusters -ProxyUrl "http://proxy.company.com:8080" -SelectAll
    
    Launches the interface with a specific proxy URL and pre-selects all clusters for 
    bulk operations.

    .EXAMPLE
    Set-AksClusters -SkipProxyAll -SkipTestConnections
    
    Launches the interface without proxy configuration and skips connection testing.

    .INPUTS
    None. This function does not accept pipeline input.

    .OUTPUTS
    None. This function performs management operations and displays results to the console.

    .NOTES
    Prerequisites:
    - Azure CLI must be installed and configured
    - kubectl must be installed for cluster operations
    - PowerShell module PSMenu is required for interactive menus
    - User must have appropriate permissions to access AKS clusters

    This function requires interactive input unless used with -SetupAllWithDefaults parameter.

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
        $SelectAll,

        # Skip testing connections to the AKS clusters
        [Parameter()]
        [switch]
        $SkipTestActions
    )

    Clear-Host

    $appTitle = "AzKube"
    $Title = " | Starting..."

    . "$PSScriptRoot\..\private\Aks-Utilities.ps1"
    . "$PSScriptRoot\..\private\Aks-Ui-Utilities.ps1"

    $ProxyUrl = Get-DefaultProxyUrl -ProxyUrl $ProxyUrl

    Write-Host
    Write-Host $appTitle -ForegroundColor Blue -NoNewline
    Write-Host $Title -ForegroundColor Cyan

    Install-AzureCli
    Install-PsMenu

    $tenant = [TenantList]::New()

    do {
        # Create and use a new TenantList object to get all tenants
        Clear-Host
        if ($global:SelectedTenant) {
            # Use the saved tenant to initialize your tenant list
            $tenant.SelectedTenant = $global:SelectedTenant
        }
        else {
            # Load save tenant from user environment variable if it exists
            $tenant.SelectedTenant = $env:AzKubeSelectedTenant
            if ($null -ne $tenant.SelectedTenant) {
                $global:SelectedTenant = $tenant.SelectedTenant
            }
        }

        # Display or select tenant if not already set
        $tenant.DisplaySelectedTenant()
       
        if ($null -eq $tenant) {
            exit 0
        }
    
        if ($null -eq $tenant.SelectedTenant) {
            return
        }

        # Get all AKS clusters into a variable using Azure Resource Graph
        $aksClusters = Get-AksClusters
        if ($null -eq $aksClusters) {
            exit 0
        }
        # Show AKS clusters as a simple menu for selection
        $aksClusters = & Show-ClusterMenu -Clusters $aksClusters -SelectAll:$SelectAll -HideSummary:$false -Title "Select AKS cluster(s) to manage or ESC to quit:"  -MultiSelect:$true

        if ($aksClusters.Count -gt 0) {
            # Show actions menu
            [ManagementAction]$action = Show-AksCluster-Actions -Actions $(Get-ManagementActions)

            # Perform the selected action on the selected AKS clusters
            if ($null -ne $action) {
                Invoke-ClusterAction -Action $action -AksClusters $aksClusters -ProxyUrl $ProxyUrl -SkipProxyAll:$SkipProxyAll -SkipTestConnections:$SkipTestConnections
            }
        } 
    } while ($aksClusters.Count -gt 0 -and $null -ne $action -and $null -ne $tenant.SelectedTenant)


    Write-Host
    Write-Host $("$([System.Text.Encoding]::UTF8.GetString([byte[]](240, 159, 143, 131))) Exiting. Thanks for stopping by!") -ForegroundColor Yellow
    Write-Host
}
