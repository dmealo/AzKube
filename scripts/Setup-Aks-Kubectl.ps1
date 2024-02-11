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

# Create a class with ToString method to display AKS clusters as a simple menu
class Cluster {
    [string]$Name
    [int]$Index
    [string]$SubscriptionId
    [string]$ResourceGroup
    static [int]$LastId = 0

    Cluster([string]$name, [string]$subscriptionId, [string]$resourceGroup) {
        $this.Name = $name
        $this.Index = [Cluster]::LastId + 1
        [Cluster]::LastId = $this.Index
        $this.SubscriptionId = $subscriptionId
        $this.ResourceGroup = $resourceGroup
    }

    [string] ToString() {
        return "$($this.Name) (RG: $($this.ResourceGroup) - SubId: $($this.SubscriptionId))"
    }
}

# Function to get kubectl credentials for an array of AKS clusters
function Get-KubectlCredentialsForAksClusters($aksClusters) {
    Write-Host
    Write-Host "Getting kubectl credentials for these AKS Clusters:"
    $aksClusters | ForEach-Object { Write-Host $_.Name }

    # Check if already logged into Azure CLI
    $azAccount = az account show --output json
    if ($null -eq $azAccount) {
        # Log into Azure with minimal output
        az login --output none
    }

    # Install kubectl using WinGet if not already installed
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        winget install --id Kubernetes.kubectl -e
    }

    # Ask user if proxy should be used for all clusters
    Write-Host
    $useProxyAll = "y"
    if (!$SkipProxyAll -and !$SetupAllWithDefaults) {
        $useProxyAll = ($answer = (Read-Host "Use proxy ($proxyUrl) for all clusters? (Y/n/none)").ToLower()) ? $answer : $useProxyAll
    }

    # Get kubeconfig for each AKS cluster using Azure CLI
    $aksClusters | ForEach-Object {
        # Set subscription context to that of the AKS cluster
        az account set --subscription $_.subscriptionId --output none

        # Get kubeconfig for the AKS cluster and add it to the local kubeconfig file
        az aks get-credentials --name $_.name --resource-group $_.resourceGroup --admin --overwrite-existing --output none

        # Set proxy for added cluster if user chose to use proxy for all clusters
        if ($useProxyAll -eq "y") {
            kubectl config set-cluster $_.name --proxy-url=$proxyUrl
        }
        else {
            # Ask user if proxy should be used
            if ($SkipProxyAll -or $useProxyAll -eq "none") {
                # Do not set proxy for added cluster
                Write-Host "Not setting proxy for cluster $($_.name)"
            }
            else {
                $useProxy = Read-Host "Use proxy ($proxyUrl) for cluster $($_.name)? (y/n)"
                if ($useProxy -eq "y") {
                    # Set proxy for added cluster
                    kubectl config set-cluster $_.name --proxy-url=$proxyUrl
                }
                else {
                    # Specify alternative Proxy URL or ENTER for no proxy
                    $proxyUrlAlt = Read-Host "Specify alternative Proxy URL for cluster $($_.name) or ENTER for no proxy"
                    if ($proxyUrlAlt -ne "") {
                        # Set proxy for added cluster
                        kubectl config set-cluster $_.name --proxy-url=$proxyUrlAlt
                    }
                }
            }
        }
    }
}    

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
Get-KubectlCredentialsForAksClusters $aksClusters

# Test connections to the AKS clusters using kubectl version command
if ($SkipTestConnections) {
    Write-Host "Skipping testing connections to the AKS clusters."
}
else {
    Write-Host
    Write-Host "Testing kubectl connections to the AKS clusters:"
    $aksClusters | ForEach-Object {
        # Write-Host "Testing connection to AKS cluster $($_.name):"

        # Set subscription context to that of the AKS cluster
        az account set --subscription $_.subscriptionId --output none

        # Test connection to the AKS cluster and display success or failure
        $serverVersion = (kubectl version --context "$($_.name)-admin" -o json | ConvertFrom-Json).serverVersion
        if ($null -ne $serverVersion) {
            #  Print green checkmark and name of the AKS cluster
            Write-Host "`e[32m√`e[0m $($_.name)"
        }
        else {
            # Print red cross and name of the AKS cluster
            Write-Host "`e[31mX`e[0m $($_.name)"
        }
    }
}
# # List all subscriptions into a variable
# $subs = az account list --output json

# # Prompt user to select a subscription from the list uaing a text-based menu
# $selectedSub = $subs | ConvertFrom-Json | Out-GridView -OutputMode Single -Title "Select a subscription" -PassThru
# Write-Host "Selected subscription: $($selectedSub.Name)"


