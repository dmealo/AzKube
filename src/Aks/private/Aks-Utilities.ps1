

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
function Get-KubectlCredentialsForAksClusters($aksClusters, $ProxyUrl, $SkipProxyAll, $SetupAllWithDefaults) {
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
        $useProxyAll = ($answer = (Read-Host "Use proxy ($ProxyUrl) for all clusters? (Y/n/none)").ToLower()) ? $answer : $useProxyAll
    }

    # Get kubeconfig for each AKS cluster using Azure CLI
    $aksClusters | ForEach-Object {
        # Set subscription context to that of the AKS cluster
        az account set --subscription $_.subscriptionId --output none

        # Get kubeconfig for the AKS cluster and add it to the local kubeconfig file
        az aks get-credentials --name $_.name --resource-group $_.resourceGroup --admin --overwrite-existing --output none

        # Set proxy for added cluster if user chose to use proxy for all clusters
        if ($useProxyAll -eq "y") {
            kubectl config set-cluster $_.name --proxy-url=$ProxyUrl
        }
        else {
            # Ask user if proxy should be used
            if ($SkipProxyAll -or $useProxyAll -eq "none") {
                # Do not set proxy for added cluster
                Write-Host "Not setting proxy for cluster $($_.name)"
            }
            else {
                $useProxy = Read-Host "Use proxy ($ProxyUrl) for cluster $($_.name)? (y/n)"
                if ($useProxy -eq "y") {
                    # Set proxy for added cluster
                    kubectl config set-cluster $_.name --proxy-url=$ProxyUrl
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

# Function to test connections to an array of AKS clusters
function Test-ConnectionsToAksClusters($aksClusters) {
    
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