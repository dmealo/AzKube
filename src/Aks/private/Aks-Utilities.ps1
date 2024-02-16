

# Create a class with ToString method to display AKS clusters
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

# Create a class with ToString method to display management actions
class ManagementAction {
    [string]$Name
    [int]$Index
    [string]$Description
    [scriptblock]$Script
    static [int]$LastId = 0

    ManagementAction([string]$name, [string]$description, [scriptblock]$script) {
        $this.Name = $name
        $this.Index = [ManagementAction]::LastId + 1
        [ManagementAction]::LastId = $this.Index
        $this.Description = $description
        $this.Script = $script
    }

    [string] ToString() {
        return "$($this.Name) - $($this.Description) > $($this.Script)"
    }
}

# Install Azure CLI using WinGet if not already installed
function Install-AzureCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Azure CLI using WinGet..."
        winget install --id Microsoft.AzureCLI -e
    }
}

# Install PSMenu if not already installed
function Install-PSMenu {
    if (-not (Get-Command Show-Menu -ErrorAction SilentlyContinue)) {
        Install-Module -Name PSMenu -Force
    }
}

# Function to install kubectl using WinGet if not already installed
function Install-Kubectl {
    # Install kubectl using WinGet if not already installed
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        winget install --id Kubernetes.kubectl -e
    }
}

# Function to connect to Azure CLI (login if not already logged in)
function Connect-AzureCli {

    # Check if already logged into Azure CLI
    $azAccount = az account show --output json
    if ($null -eq $azAccount) {
        # Log into Azure with minimal output
        az login --output none
    }
}

# Function to set Azure CLI subscription context
function Set-AzCliSubscription ($subscriptionId) {
    # Set subscription context to that of the AKS cluster
    az account set --subscription $subscriptionId --output none
}

# Function to display an array of objects
function Show-ObjectArray($objects, $color) {
    $objects | ForEach-Object { Write-Host $_.ToString() -ForegroundColor $color }
}

# Get all AKS clusters into a variable using Azure Resource Graph
function Get-AksClusters {
    # Get all AKS clusters into a variable using Azure Resource Graph
    [Cluster[]] $aksClusters = (az graph query -q "where type == 'microsoft.containerservice/managedclusters' | project name, subscriptionId, resourceGroup" | ConvertFrom-Json).data | ForEach-Object { [Cluster]::new($_.name, $_.subscriptionId, $_.resourceGroup) }

    if ($aksClusters.Count -eq 0) {
        Write-Host "No AKS clusters found to get kubectl credentials for. Verify that you have logged into the correct Azure subscription(s) with permission to access AKS clusters and retry." -ForegroundColor Orange
        return $null
    }

    return $aksClusters
}

# Function to get kubectl credentials for an AKS cluster
function Get-Kubectl-Credentials($ResourceGroup, $Name) {
    # Get kubeconfig for the AKS cluster and add it to the local kubeconfig file
    az aks get-credentials --resource-group $ResourceGroup --name $Name --admin --overwrite-existing --output none
}

# Function to set proxy for a cluster in kubeconfig
function Set-Kubectl-Cluster-Proxy($Name, $ProxyUrl) {
    # Set proxy for cluster in kubeconfig
    kubectl config set-cluster $Name --proxy-url=$ProxyUrl
}

# Function to test connection to a Kubernetes cluster
function Test-Kubectl-ServerVersion($Name) {
    # Test connection to the AKS cluster
    return (kubectl version --context "$($Name)-admin" -o json | ConvertFrom-Json).serverVersion
}

# Function to get a string with a green checkmark
function Get-SuccessShortString () {
    return "`e[32m√`e[0m"
}

# Function to get a string with a red cross
function Get-FailureShortString () {
    return "`e[31mX`e[0m"
}

# Function to get kubectl credentials for an array of AKS clusters
function Get-KubectlCredentialsForAksClusters($aksClusters, $ProxyUrl, $SkipProxyAll, $SetupAllWithDefaults) {
    Write-Host
    Write-Host "Getting kubectl credentials for these AKS Clusters:"
    $aksClusters | ForEach-Object { Write-Host $_.Name }

    Connect-AzureCli

    Install-Kubectl

    # Ask user if proxy should be used for all clusters
    Write-Host
    $useProxyAll = "y"
    if (!$SkipProxyAll -and !$SetupAllWithDefaults) {
        $useProxyAll = ($answer = (Read-Host "Use proxy ($ProxyUrl) for all clusters? (Y/n/none)").ToLower()) ? $answer : $useProxyAll
    }

    # Get kubeconfig for each AKS cluster using Azure CLI
    $aksClusters | ForEach-Object {
        Set-AzCliSubscription $_.subscriptionId

        # Get kubeconfig for the AKS cluster
        Get-Kubectl-Credentials -ResourceGroup $_.ResourceGroup -Name $_.Name

        # Set proxy for added cluster if user chose to use proxy for all clusters
        if ($useProxyAll -eq "y") {
            Set-Kubectl-Cluster-Proxy -Name $_.Name -ProxyUrl $ProxyUrl
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
                    Set-Kubectl-Cluster-Proxy -Name $_.Name -ProxyUrl $ProxyUrl
                }
                else {
                    # Specify alternative Proxy URL or ENTER for no proxy
                    $proxyUrlAlt = Read-Host "Specify alternative Proxy URL for cluster $($_.name) or ENTER for no proxy"
                    if ($proxyUrlAlt -ne "") {
                        # Set proxy for added cluster
                        Set-Kubectl-Cluster-Proxy -Name $_.Name -ProxyUrl $proxyUrlAlt
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
        # Test connection to the AKS cluster and display success or failure
        $serverVersionTest = Test-Kubectl-ServerVersion -Name $_.Name
        if ($null -ne $serverVersionTest) {
            #  Print green checkmark and name of the AKS cluster
            Write-Host "Get-SuccessShortString $($_.name)"
        }
        else {
            # Print red cross and name of the AKS cluster
            Write-Host "Get-FailureShortString $($_.name)"
        }
    }
}

# Function to get the resource ID of an AKS cluster
function Get-ClusterResourceIds($aksClusters) {
    Write-Host
    Write-Host "Resource ID of the selected AKS cluster(s):"
    $aksClusters | ForEach-Object {
        # Set subscription context to that of the AKS cluster
        Set-AzCliSubscription $_.subscriptionId

        # Get resource ID of the AKS cluster
        $resourceId = az aks show --name $_.name --resource-group $_.resourceGroup --query id --output tsv
        Write-Host "$($_.name): $resourceId"
    }
}

# Function to update the AKS cluster resource(s) by ID(s)
function Update-ClusterResources($aksClusters) {
    Write-Host
    $ignoreWarning = Read-Host "`e[31m!!`e[0m This action will update the selected AKS cluster(s) and may cause disruption depending on PDBs/HPAs/resources/activity. Continue? (y/n)"
    if ($ignoreWarning -eq "y") {
        Write-Host "Updating the selected AKS cluster(s):"
        $aksClusters | ForEach-Object {
            # Set subscription context to that of the AKS cluster
            Set-AzCliSubscription $_.subscriptionId

            # Update the AKS cluster
            az resource update --ids $_.resourceId
        }
    }
    else {
        Write-Host "Action cancelled."
    }
}

# Function to populate catalog of management actions
function Get-ManagementActions {
    [ManagementAction[]] $managementActions = @()
    $managementActions += [ManagementAction]::new("Get-KubectlCredentialsForAksClusters", "Get kubectl credentials for the selected AKS cluster(s)", { Get-KubectlCredentialsForAksClusters $aksClusters $ProxyUrl -SkipProxyAll:$SkipProxyAll -SetupAllWithDefaults:$SetupAllWithDefaults })
    $managementActions += [ManagementAction]::new("Test-ConnectionsToAksClusters", "Test connection(s) to the selected AKS cluster(s) using kubectl version command", { Test-ConnectionsToAksClusters $aksClusters })
    $managementActions += [ManagementAction]::new("Get-ClusterResourceIds", "Get the resource ID(s) of the selected AKS cluster(s)", { Get-ClusterResourceIds $aksClusters })
    $managementActions += [ManagementAction]::new("`e[31m!!`e[0m Update-ClusterResources", "Update the selected AKS cluster resource(s) by ID(s)", { Update-ClusterResources $aksClusters })
    return $managementActions
}

# Function to invoke a management action on an array of AKS clusters
function Invoke-ClusterAction {
    param (
        [ManagementAction]$Action,
        [Cluster[]]$AksClusters,
        [string]$ProxyUrl,
        [switch]$SkipProxyAll,
        [switch]$SetupAllWithDefaults
    )

    Write-Host
    Write-Host "Executing action: $($Action.Name) - $($Action.Description) on the selected AKS cluster(s):"
    $AksClusters | ForEach-Object {
        # Set subscription context to that of the AKS cluster
        Set-AzCliSubscription $_.SubscriptionId

        # Execute the selected action on the AKS cluster
        Invoke-Command $Action.Script
    }
}