. "$PSScriptRoot\Aks-Utilities.ps1"

# Function to display a simple menu for selection
function Show-ClusterMenu {
    param (
        [object[]]$Clusters,
        [switch]$SelectAll,
        [switch]$HideSummary,
        [string]$Title = "Select AKS cluster(s):",
        [switch]$MultiSelect
    )
    Write-Host
    Write-Host $Title -ForegroundColor Cyan
    Write-Host
    # Display AKS clusters as a simple menu for selection
    $clusterIndexes = $($Clusters | ForEach-Object { [int]$Clusters.IndexOf($_) })
    $selectedClusters = Show-Menu -MenuItems $Clusters -MultiSelect:$MultiSelect -InitialSelection ($SelectAll ? $clusterIndexes : @())

    if ($HideSummary -eq $false -and $selectedClusters.Count -gt 0) {
        Write-Host 
        Write-Host "Selected AKS cluster(s): $($selectedClusters | ForEach-Object { "`n" + $_.ToString() } )" -ForegroundColor Cyan
    }
    return $selectedClusters
}

function Show-AksCluster-Actions {  
    param (
        [ManagementAction[]]$Actions,
        [string]$Title = "Select action to perform on AKS cluster(s):"
    )
    Write-Host
    Write-Host $Title -ForegroundColor Cyan
    Write-Host
    # Convert ManagementAction objects to strings
    $menuItems = $Actions | ForEach-Object { $_.ToString() }
    # Display management actions as a simple menu for selection
    $selectedAction = Show-Menu -MenuItems $menuItems -InitialSelection 0
    Write-Host
    Write-Host "Selected action: $selectedAction"
    # Find the selected ManagementAction object
    [ManagementAction]$selectedManagementAction = $Actions | Where-Object { $_.ToString() -eq $selectedAction }
    # Check that a valid action was selected
    if ($null -eq $selectedManagementAction) {
        Write-Host "No valid action selected."
        return $null
    }
    # Return the selected ManagementAction object
    return $selectedManagementAction
}

function Show-Tenants {
    param (
        [Tenant[]]$Tenants,
        [string]$Title = "Select tenant or hit Esc to exit:"
    )
    # Clear-Host
    Write-Host
    Write-Host $Title -ForegroundColor Cyan
    Write-Host
    # Convert Tenant objects to strings
    Write-Debug "Tenants: $($this.Tenants.Count)"
    $menuItems = $this.Tenants | ForEach-Object { $_.ToString() }
    # Display tenants as a simple menu for selection
    $selectedTenant = Show-Menu -MenuItems $menuItems -InitialSelection 0
    # Find the selected Tenant object
    $selectedTenantObject = $this.Tenants | Where-Object { $_.ToString() -eq $selectedTenant }
    # Check that a valid tenant was selected
    if ($null -eq $selectedTenantObject) {
        Write-Host
        Write-Host "No valid tenant selected. Exiting." -ForegroundColor Yellow
        return $null
    }
    Write-Host
    Write-Host "Selected tenant: $selectedTenant"
    # Return the selected Tenant object
    return $selectedTenantObject
}