# Setup-Aks-Kubectl.ps1
# Description: This script gets kubectl credentials for all AKS clusters in all subscriptions and tests the connections to the clusters.
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

# Install Azure CLI using WinGet if not already installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.AzureCLI -e
}

# Install Azure Resource Graph if not already installed
if ((az extension list | ConvertFrom-Json | Where-Object { $_.name -eq 'resource-graph' }).Count -eq 0) {
    az extension add --name resource-graph
}

# Get all AKS clusters into a variable using Azure Resource Graph
$aksClusters = (az graph query -q "where type == 'microsoft.containerservice/managedclusters' | project name, subscriptionId, resourceGroup" | ConvertFrom-Json).data | ForEach-Object { [Cluster]::new($_.name, $_.subscriptionId, $_.resourceGroup) }

if ($aksClusters.Count -eq 0) {
    Write-Host "No AKS clusters found to get kubectl credentials for. Verify that you have logged into the correct Azure subscription(s) with permission to access AKS clusters and retry." -ForegroundColor Orange
    exit 0
}

# Install PSMenu if not already installed
if (-not (Get-Command Show-Menu -ErrorAction SilentlyContinue)) {
    Install-Module -Name PSMenu -Force
}

if ($SetupAllWithDefaults) {
    # Continue execution
    Write-Host "Setting up all AKS clusters with default settings:" -ForegroundColor Cyan
    Write-Host $($aksClusters | ForEach-Object { "`n" + $_.ToString() } ) -ForegroundColor Cyan
}
else {
    Write-Host
    Write-Host "Select AKS cluster(s) to get kubectl credentials for:"
    # Display AKS clusters as a simple menu for selection
    $clusterIndexes = $($aksClusters | ForEach-Object { [int]$aksClusters.IndexOf($_) })
    $selectedClusters = Show-Menu -MenuItems $aksClusters -MultiSelect -InitialSelection ($SelectAll ? $clusterIndexes : @())
    Write-Host 
    Write-Host "Selected AKS cluster(s): $($selectedClusters | ForEach-Object { "`n" + $_.ToString() } )" -ForegroundColor Cyan
    $aksClusters = $selectedClusters
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


