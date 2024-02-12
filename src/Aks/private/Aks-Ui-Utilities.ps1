. "$PSScriptRoot\Aks-Utilities.ps1"

# Function to display a simple menu for selection
function Show-ClusterMenu {
    param (
        [object[]]$Clusters,
        [switch]$SelectAll,
        [switch]$HideSummary,
        [string]$Title = "Select AKS clusters:"
    )
    Write-Host
    Write-Host $Title
    Write-Host
    # Display AKS clusters as a simple menu for selection
    $clusterIndexes = $($Clusters | ForEach-Object { [int]$Clusters.IndexOf($_) })
    $selectedClusters = Show-Menu -MenuItems $Clusters -MultiSelect -InitialSelection ($SelectAll ? $clusterIndexes : @())

    if ($ShowSummary) {
        Write-Host 
        Write-Host "Selected AKS cluster(s): $($selectedClusters | ForEach-Object { "`n" + $_.ToString() } )" -ForegroundColor Cyan
        $Clusters = $selectedClusters
    }
    return $selectedClusters
}