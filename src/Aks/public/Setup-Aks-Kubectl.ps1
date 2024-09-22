# Setup-Aks-Kubectl.ps1
# Description: This script gets kubectl credentials for selected or all AKS clusters in all subscriptions and tests the connections to the clusters.
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
    $SelectAll
)

. "$PSScriptRoot\..\private\Aks-Utilities.ps1"
. "$PSScriptRoot\..\private\Aks-Ui-Utilities.ps1"


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


