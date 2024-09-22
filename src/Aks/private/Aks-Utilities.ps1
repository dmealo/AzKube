

# Class with ToString method to display AKS clusters
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

# Class with ToString method to display management actions
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

# Class to define Azure Tenant objects
class Tenant {
    [string]$Id
    [string]$Name
    [int]$Index
    static [int]$LastId = 0

    Tenant([string]$id, [string]$name) {
        $this.Id = $id
        $this.Name = $name
        $this.Index = [Tenant]::LastId + 1
        [Tenant]::LastId = $this.Index
    }

    [string] ToString() {
        return "$($this.Name) - $($this.Id)"
    }
}

# Class to allow use of Azure Tenant objects
class TenantList {
    [Tenant[]]$Tenants

    TenantList() {
        Invoke-AzureLoginReconciliation
        az account list | ConvertFrom-Json | Select-Object -ExpandProperty tenantId -Unique | ForEach-Object { $this.Tenants += [Tenant]::new($_, $(Get-AzTenant -TenantId $_).Name) }
        Write-Debug "Tenants found: $($this.Tenants.Count)"
    }
    
    Select() {
        Write-Debug "Tenants: $($this.Tenants.Count)"
        $selectedTenant = Show-Tenants -MenuItems $this.Tenants
        # Set the selected tenant as the default tenant in Azure CLI and Azure PowerShell module
        if ($null -ne $selectedTenant) {
            Connect-AzureCli -tenantId $selectedTenant.Id
            Connect-Az -tenantId $selectedTenant.Id
        }
    }
}


# Install Azure CLI using WinGet if not already installed
function Install-AzureCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Azure CLI using WinGet..."
        winget install --id Microsoft.AzureCLI -e
    }
}

# Install Azure Powershell module if not already installed
function Install-AzModule {
    if (-not (Get-Command Connect-AzAccount -ErrorAction SilentlyContinue)) {
        Install-Module -Name Az -Force
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
function Connect-AzureCli ($forceReconnect = $false, $tenantId = $null) {

    # Check if already logged into Azure CLI
    $azAccount = az account show --output json
    if (($null -eq $azAccount) -or $forceReconnect) {
        if ($null -ne $tenantId) {
            # Log into Azure with minimal output with the specified tenant ID if provided
            Write-Host "Logging into Azure from Azure CLI with tenant ID: $tenantId"
            az login --allow-no-subscriptions --output none --tenant $tenantId
        }
        else {
            # Log into Azure with minimal output
            Write-Host "Logging into Azure from Azure CLI..."
            az login --allow-no-subscriptions --output none
        }
    }
    elseif ($null -ne $tenantId) {
        # Log into Azure with minimal output with the specified tenant ID if provided
        $tenantMatches = az account list | ConvertFrom-Json | Where-Object { $_.tenantId -eq $tenantId }
        if (($null -eq $tenantMatches -or $tenantMatches.Count -eq 0) -or $forceReconnect) {
            Write-Host "Logging into Azure from Azure CLI with tenant ID: $tenantId"
            az login --allow-no-subscriptions --output none --tenant $tenantId
        }
    }
}

# Function to connect to Azure using Azure PowerShell module (login if not already logged in)
function Connect-Az ($forceReconnect = $false, $tenantId = $null) {
    $azAccount = Get-AzContext
    if ($null -eq $azAccount -or $forceReconnect -or ($null -ne $tenantId -and $azAccount.Tenant.Id -ne $tenantId)) {
        if ($null -ne $tenantId) {
            Write-Host "Logging into Azure from Azure PowerShell with tenant ID: $tenantId"
            Connect-AzAccount -Tenant $tenantId
        }
        else {
            Write-Host "Logging into from Azure PowerShell..."
            Connect-AzAccount
        }
    }
}

# Function to reconcile Azure CLI and Azure PowerShell module logins
function Invoke-AzureLoginReconciliation {
    Install-AzModule
    # Check if already logged into Azure PowerShell (Az module) and Azure CLI
    $azContext = Get-AzContext
    $azTenant = (Get-AzTenant).Name
    $azAccount = az account show --output json | ConvertFrom-Json
    if ($null -eq $azContext -or $null -eq $azAccount -or $null -eq $azTenant -or $null -eq $azTenant[0] ) {
        Connect-AzureCli -forceReconnect $true
        Connect-Az -forceReconnect $true
    }
    elseif ($null -ne $azAccount -and $null -ne $azContext -and $azAccount.user.name -ne $azContext.Account.id) {
        # Prompt user to choose which login to keep by name
        $azAccountName = $azAccount.user.name
        $azContextName = $azContext.Account.id
        $accountToKeep = Read-Host "Which login do you want to keep? (1) $azAccountName or (2) $azContextName"
        if ($accountToKeep -eq "1") {
            # Log into Azure using Azure PowerShell module
            Connect-Az -forceReconnect
        }
        else {
            # Log into Azure using Azure CLI
            Connect-AzureCli -forceReconnect
        }
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
    Connect-AzureCli
    
    # Get all AKS clusters into a variable using Azure Resource Graph
    [Cluster[]] $aksClusters = (az graph query -q "where type == 'microsoft.containerservice/managedclusters' | project name, subscriptionId, resourceGroup" | ConvertFrom-Json).data | ForEach-Object { [Cluster]::new($_.name, $_.subscriptionId, $_.resourceGroup) }

    if ($aksClusters.Count -eq 0) {
        Write-Host "No AKS clusters found to get kubectl credentials for. Verify that you have logged into the correct Azure subscription(s) with permission to access AKS clusters and retry." -ForegroundColor DarkYellow
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
    return "`e[32m√`e[0m Success"
}

# Function to get a string with a red cross
function Get-FailureShortString () {
    return "`e[31mX`e[0m Failure"
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
            Write-Host "$(Get-SuccessShortString $($_.name)): $($_.Name)"
        }
        else {
            # Print red cross and name of the AKS cluster
            Write-Host "$(Get-FailureShortString $($_.name)): $($_.Name)"
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
    $managementActions += [ManagementAction]::new("Get-KubectlCredentialsForAksClusters", "Get kubectl credentials for the selected AKS cluster(s)", { param ($aksClusters, $ProxyUrl, $SkipProxyAll, $SetupAllWithDefaults) Get-KubectlCredentialsForAksClusters $aksClusters $ProxyUrl -SkipProxyAll:$SkipProxyAll -SetupAllWithDefaults:$SetupAllWithDefaults })
    $managementActions += [ManagementAction]::new("Test-ConnectionsToAksClusters", "Test connection(s) to the selected AKS cluster(s) using kubectl version command", { param ($aksClusters) Test-ConnectionsToAksClusters $aksClusters })
    $managementActions += [ManagementAction]::new("Get-ClusterResourceIds", "Get the resource ID(s) of the selected AKS cluster(s)", { param ($aksClusters) Get-ClusterResourceIds $aksClusters })
    $managementActions += [ManagementAction]::new("`e[31m!!`e[0m Update-ClusterResources", "Update the selected AKS cluster resource(s) by ID(s)", { param ($aksClusters) Update-ClusterResources $aksClusters })
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
    # Execute the selected action on the AKS cluster
    Invoke-Command $Action.Script -ArgumentList $AksClusters, $ProxyUrl, $SkipProxyAll, $SetupAllWithDefaults
}