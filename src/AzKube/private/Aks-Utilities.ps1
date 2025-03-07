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
        return "$($this.Name -eq '' ? "(No name)" : $this.Name) - $($this.Id)"
    }
}

# Class to allow use of Azure Tenant objects
class TenantList {
    [Tenant[]]$Tenants
    [Tenant]$SelectedTenant

    TenantList() {
        Invoke-AzureLoginReconciliation
        az account list --only-show-errors | ConvertFrom-Json | Select-Object -ExpandProperty tenantId -Unique | ForEach-Object { $this.Tenants += [Tenant]::new($_, $(Get-AzTenant -TenantId $_).Name) }
        Write-Debug "Tenants found: $($this.Tenants.Count)"
    }
    
    Select() {
        Write-Debug "Tenants: $($this.Tenants.Count)"
        $this.SelectedTenant = Show-Tenants -MenuItems $this.Tenants
        $global:SelectedTenant = $this.SelectedTenant
        # Set the selected tenant as the default tenant in Azure CLI and Azure PowerShell module
        Connect-AzureCli -tenantId $this.SelectedTenant.Id
        Connect-Az -tenantId $this.SelectedTenant.Id
    }

    DisplaySelectedTenant() {
        if ($null -eq $this.SelectedTenant) {
            $this.Select()
        }
        else {
            $switchTenant = Display-SelectedTenant -SelectedTenant $this.SelectedTenant
            if ($switchTenant) {
                $this.Select()
            }
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
        Write-Host "Installing Az module..."
        Install-Module -Name Az -Force
    }
}

# Install PSMenu if not already installed
function Install-PSMenu {
    if (-not (Get-Command Show-Menu -ErrorAction SilentlyContinue)) {
        Write-Host "Installing PSMenu module..."
        Install-Module -Name PSMenu -Force
    }
}

# Function to install kubectl using WinGet if not already installed
function Install-Kubectl {
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Host "Installing kubectl using WinGet..."
        winget install --id Kubernetes.kubectl -e
    }
}

# Function to connect to Azure CLI (login if not already logged in)
function Connect-AzureCli ($forceReconnect = $false, $tenantId = $null) {

    # Check if already logged into Azure CLI
    $azAccount = az account show 2>$null --output json
    if (($null -eq $azAccount) -or $forceReconnect) {
        if ($null -ne $tenantId) {
            # Log into Azure with minimal output with the specified tenant ID if provided
            Write-Host "Logging into Azure from Azure CLI with tenant ID: $tenantId"
            Connect-Azure-Simplified -tenantId $tenantId
        }
        else {
            # Log into Azure with minimal output
            Write-Host "Logging into Azure from Azure CLI..."
            Connect-Azure-Simplified
        }
    }
    elseif ($null -ne $tenantId) {
        # Log into Azure with minimal output with the specified tenant ID if provided
        $tenantMatches = az account list --only-show-errors | ConvertFrom-Json | Where-Object { $_.tenantId -eq $tenantId }
        if (($null -eq $tenantMatches -or $tenantMatches.Count -eq 0) -or $forceReconnect) {
            Write-Host "Logging into Azure from Azure CLI with tenant ID: $tenantId"
            Connect-Azure-Simplified -tenantId $tenantId
        }
    }
}

# Function to connect to Azure using Azure PowerShell module (login if not already logged in)
function Connect-Az ($forceReconnect = $false, $tenantId = $null) {
    $azAccount = Get-AzContext
    if ($null -eq $azAccount -or $forceReconnect -or ($null -ne $tenantId -and $azAccount.Tenant.Id -ne $tenantId)) {
        if ($null -ne $tenantId) {
            Write-Host "Logging into Azure from Azure PowerShell with tenant ID: $tenantId`nChoose any subscription if prompted. We will change it later if needed."
            Connect-AzAccount -Tenant $tenantId -WarningAction Ignore
        }
        else {
            Write-Host "Logging into Azure from Azure PowerShell...`nChoose any subscription if prompted. We will change it later if needed."
            Connect-AzAccount -WarningAction Ignore
        }
    }
}

# Function to log into Azure using Azure CLI with handling of WAM pop up and subscription selection prompt
function Connect-Azure-Simplified ($tenantId = $null) {
    Write-Host "Simplifying signin to Azure via Az CLI."
    # Save WAM pop up config to variable to restore after login
    $wamConfig = az config get core.enable_broker_on_windows | ConvertFrom-Json | Select-Object -ExpandProperty value
    # Save subscription selection prompt config to variable to restore after login
    $loginExperienceConfig = az config get core.login_experience_v2 | ConvertFrom-Json | Select-Object -ExpandProperty value

    # Disable WAM pop up default behavior on Windows
    az config set core.enable_broker_on_windows=false
    # Disable subscription selection prompt
    az config set core.login_experience_v2=off

    if ($null -ne $tenantId) {
        # Log into Azure with minimal output with the specified tenant ID if provided
        Write-Host "Logging into Azure from Azure CLI with tenant ID: $tenantId"
        az login --allow-no-subscriptions --output none --tenant $tenantId --only-show-errors
    }
    else {
        # Log into Azure with minimal output
        Write-Host "Logging into Azure from Azure CLI..."
        az login --allow-no-subscriptions --output none --only-show-errors
    }

    # Restore previous user settings
    if ($null -ne $wamConfig) {
        az config set core.enable_broker_on_windows=$wamConfig
    }
    else {
        az config unset core.enable_broker_on_windows
    }
    if ($null -ne $loginExperienceConfig) {
        az config set core.login_experience_v2=$loginExperienceConfig
    }
    else {
        az config unset core.login_experience_v2
    }
}

function GetRandomString {
    param (
        [int] $length = 22
    )
    $randomStr = ''
    $chars = (65..90) + (97..122) + (48..57) # ASCII ranges for A-Z, a-z, 0-9
    $randomStr = -join (Get-Random -InputObject $chars -Count $length | ForEach-Object { [char]$_ })
    Write-Debug "Length: $($randomStr.Length)"
    Write-Debug "Random string generated: $randomStr"
    return $randomStr
}

# Function to reconcile Azure CLI and Azure PowerShell module logins
function Invoke-AzureLoginReconciliation {
    Install-AzModule
    Install-AzureCli
    # Check if already logged into Azure PowerShell (Az module) and Azure CLI
    $azContext = Get-AzContext
    $azTenant = (Get-AzTenant 2>$null).Name
    $azAccount = az account show --output json 2>$null | ConvertFrom-Json
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
            Connect-Az -forceReconnect $true
        }
        else {
            # Log into Azure using Azure CLI
            Connect-AzureCli -forceReconnect $true
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

    # Prompt user to press spacebar to continue
    Write-Host
    Write-Host "Press spacebar to continue..." -ForegroundColor Yellow -NoNewline
    
    # Wait for spacebar key
    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } while ($key.VirtualKeyCode -ne 32)  # 32 is the virtual key code for spacebar
    
    Write-Host "`nContinuing..." -ForegroundColor Green
}

# Function to get the resource ID of an AKS cluster
function Get-ClusterResourceIds($aksClusters, $background) {
    if (!$background) {
        Write-Host
        Write-Host "Resource ID of the selected AKS cluster(s):"
    }
    $aksClusters | ForEach-Object {
        # Set subscription context to that of the AKS cluster
        Set-AzCliSubscription $_.subscriptionId

        # Get resource ID of the AKS cluster
        $resourceId = az aks show --name $_.name --resource-group $_.resourceGroup --query id --output tsv
        if (!$background) {
            Write-Host "$($_.name) resource ID: $resourceId"

            # Copy resource ID to clipboard
            Set-Clipboard -Value $resourceId
            Write-Host "Resource ID copied to clipboard"
        }

        if ($background) {
            return $resourceId
        }
    }
}

# Function to update the AKS cluster resource(s) by ID(s)
function Update-ClusterResources($aksClusters) {
    Write-Host
    $ignoreWarning = Read-Host "`e[31m!!`e[0m This action will update the selected AKS cluster(s) and may cause disruption depending on PDBs/HPAs/resources/activity. Continue? (y/n)"
    if ($ignoreWarning -eq "y") {
        Write-Host
        Write-Host "Updating the selected AKS cluster(s)..."
        $aksClusters | ForEach-Object {
            # Set subscription context to that of the AKS cluster
            Set-AzCliSubscription $_.subscriptionId

            # Update the AKS cluster in a separate process
            Start-Process -NoNewWindow -FilePath "az" -ArgumentList "resource update --ids $(Get-ClusterResourceIds $_ $true)" -RedirectStandardOutput "NUL"

            # Display cluster provisioning state in a loop with a progress indicator
            $pollingStart = 30
            $provisioningState = az aks show --name $_.name --resource-group $_.resourceGroup --query provisioningState --output tsv
            Write-Host "Updating $($_.name). Waiting $pollingStart seconds before polling for provisioning state..."
            # Wait for update to begin before starting to poll for provisioning state
            Start-Sleep -Seconds $pollingStart         
            $provisioningState = az aks show --name $_.name --resource-group $_.resourceGroup --query provisioningState --output tsv
            Write-Host $provisioningState -NoNewline
            while ($provisioningState -eq "Updating") {
                Write-Host "." -NoNewline
                Start-Sleep -Seconds 5
                $provisioningState = az aks show --name $_.name --resource-group $_.resourceGroup --query provisioningState --output tsv
            }
            Write-Host
            Write-Host "Provisioning state result: $provisioningState" -ForegroundColor Yellow
            
            # Wait for user input to continue
            Write-Host
            Read-Host "Press ENTER to continue"
        }
    }
    else {
        Write-Host "Action cancelled."
    }
}

# Function to populate catalog of management actions
function Get-ManagementActions {
    [ManagementAction[]] $managementActions = @()
    $managementActions += [ManagementAction]::new("Get-KubectlCredentialsForAksClusters", "Get kubectl credentials for the selected AKS cluster(s)", { param ($aksClusters, $ProxyUrl, $SkipProxyAll, $SetupAllWithDefaults) Get-KubectlCredentialsForAksClusters $aksClusters $ProxyUrl -SkipProxyAll:$SkipProxyAll -SetupAllWithDefaults:$SetupAllWithDefaults -SkipTestConnections:$SkipTestConnections })
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
        [switch]$SetupAllWithDefaults,
        [switch]$SkipTestConnections
    )

    Write-Host
    Write-Host "Executing action: $($Action.Name) - $($Action.Description) on the selected AKS cluster(s):"
    $AksClusters | ForEach-Object { Write-Host $_.Name }
    # Execute the selected action on the AKS cluster
    Invoke-Command $Action.Script -ArgumentList $AksClusters, $ProxyUrl, $SkipProxyAll, $SetupAllWithDefaults
    if (!$SkipTestConnections -and $Action.Name -eq "Get-KubectlCredentialsForAksClusters") {
        Test-ConnectionsToAksClusters $AksClusters
    }
}

function Get-DefaultProxyUrl ($ProxyUrlFromArgs) {
    # Set up the storage of a default value for the proxy URL in the user's variables
    $ProxyUrl = $([Environment]::GetEnvironmentVariable('AzKubeDefaultProxyUrl', 'User'))
    # If the variable does not exist, prompt the user to set the default proxy URL
    if ($null -eq $ProxyUrl -or $ProxyUrl -eq "" -or ($ProxyUrlFromArgs -ne "" -and $ProxyUrlFromArgs -ne $ProxyUrl)) {
        if ($null -ne $ProxyUrlFromArgs -and $ProxyUrlFromArgs -ne "") {
            $ProxyUrl = $ProxyUrlFromArgs
        }
        else {
            $ProxyUrl = Read-Host "Enter the default proxy URL suggestion for AKS clusters (used without prompting w/ -SetupAllWithDefaults parameter)"
        }
        # Set permanent system environment variable for the default proxy URL
        [Environment]::SetEnvironmentVariable("AzKubeDefaultProxyUrl", $ProxyUrl, "User")
        # Set the variable in the current session
        $env:AzKubeDefaultProxyUrl = $ProxyUrl
    }
    return $ProxyUrl
}
