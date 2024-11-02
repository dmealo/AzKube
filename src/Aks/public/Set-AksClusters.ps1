# Set-Aks-Clusters.ps1
# Description: This script enables management of optional or all AKS clusters in all subscriptions.
# Prerequisites: WinGet (install in Store for auto-updating, else static version via: `Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.appxbundle ; Add-AppxPackage -Path winget.appxbundle`)
function Set-AksClusters {
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

    . "$PSScriptRoot\..\private\Aks-Utilities.ps1"
    . "$PSScriptRoot\..\private\Aks-Ui-Utilities.ps1"

    $ProxyUrl = Get-DefaultProxyUrl -ProxyUrl $ProxyUrl

    Install-AzureCli
    Install-PsMenu

    do {
        # Create and use a new TenantList object to get all tenants
        Write-Host
        Write-Host "Loading interface..." -ForegroundColor Cyan
        $tenant = [TenantList]::New()
        $tenant.Select()
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
        $aksClusters = & Show-ClusterMenu -Clusters $aksClusters -SelectAll:$SelectAll -HideSummary:$false -Title "Select AKS cluster(s) to manage:"  -MultiSelect:$true

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