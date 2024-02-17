# Manage-Aks-Clusters.ps1
# Description: This script enables management of optional or all AKS clusters in all subscriptions.
# Prerequisites: WinGet (install in Store for auto-updating, else static version via: `Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.appxbundle ; Add-AppxPackage -Path winget.appxbundle`)

[CmdletBinding()]
param (
    # Proxy URL to be used for all AKS clusters
    [Parameter()]
    [string]
    $ProxyUrl = "http://fpx-primary.valtech.com:8080",

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


Install-AzureCli

Install-PsMenu
do {
    # Create and use a new TenantList object to get all tenants
    ([TenantList]::New()).Select()

    # Get all AKS clusters into a variable using Azure Resource Graph
    $aksClusters = Get-AksClusters
    if ($null -eq $aksClusters) {
        exit 0
    }
    # Show AKS clusters as a simple menu for selection
    $aksClusters = & Show-ClusterMenu -Clusters $aksClusters -SelectAll:$SelectAll -HideSummary:$false -Title "Select AKS cluster(s) to get kubectl credentials for:"

    if ($aksClusters.Count -gt 0) {
        # Show actions menu
        $action = Show-AksCluster-Actions -Actions $(Get-ManagementActions)

        # Perform the selected action on the selected AKS clusters
        if ($null -ne $action) {
            Invoke-ClusterAction -Action $action
        }
    } 
} while ($aksClusters.Count -gt 0 -and $null -ne $action)

Write-Host
Write-Host "Exiting. Thanks for stopping by!" -ForegroundColor Blue
Write-Host