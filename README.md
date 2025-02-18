# AzKube 🚀

## Overview 📖
AzKube is a PowerShell module designed to simplify the management and automation of Azure Kubernetes Service (AKS) clusters. It provides a set of cmdlets that streamline your AKS workflow by listing resource group details for and allowing management of AKS clusters including easy batch setup and testing of local `kubectl` connections (including setting/changing proxy URLs quickly), getting cluster resource IDs, `az resource update`-ing clusters.

If you find yourself setting up or updating kubectl connections for projects often or wanting to just test them all quickly or wanting to just change the proxy URL for all of them quickly (like when one is failing 😩), this tool could be for you.

## Features ✨
- Manage AKS clusters
  - List AKS clusters, their resource group and their subscription ID
  - Set up AKS connections for `kubectl` and `kubectl`-based tools (like OpenLens, Lens, k9s, etc.)
  - Test AKS connections for `kubectl` et al
  - Get resource IDs for AKS clusters
  - Run `az resource update` on AKS clusters to restart AKS Planned Maintenance (Cluster Upgrades, Node Image Upgrades, Weekly Updates)
- Set up AKS connections standalone command
    - Set up AKS connections for `kubectl` and `kubectl`-based tools (like OpenLens, Lens, k9s, etc.)
    - Test AKS connections for `kubectl` et al

## Installation 🤝
1. Install the Module from PowerShell Gallery 📦
    ```powershell
    Install-Module -Name AzKube
    ```

2. Import the Module (Optional) 📥
    ```powershell
    Import-Module -Name AzKube
    ```
## Usage 🛠️
To use the AzKube module, import it into your PowerShell session and use the available cmdlets. You can select and multiselect clusters using `Up`, `Down` to move through options and `Space` to toggle selection, and then `Enter` to list possible actions (see [Features](#Features)) you can move through and then execute with `Enter`. Or `Esc` from most menus to Exit the module.

CLI examples:

### Set AKS Clusters 🌐
```powershell
Set-AksClusters # run with defaults and/or saved settings
```
- `-ProxyUrl` [Default: '']: Proxy URL to be used for all AKS clusters. Will be saved to AzKubeProxyUrl user environment variable for default value.
- `-SkipProxyAll` [Default: $false]: Skip setting proxy on any AKS cluster.
- `-SkipTestConnections` [Default: $false]: Skip testing connections to the AKS clusters.
- `-SetupAllWithDefaults` [Default: $false]: Simple mode to get kubectl credentials for all AKS clusters found on all subscriptions in logged in tenant without asking for user input using default proxy.
- `-SelectAll` [Default: $false]: Initially select all AKS clusters for taking the action selected in the menu.
- `-SkipTestActions` [Default: $false]: Skip testing connections to the AKS clusters.

### Set AKS Connections 🔗
```powershell
Set-AksConnections # run with defaults and/or saved settings
```
- `-ProxyUrl` [Default: '']: Proxy URL to be used for all AKS clusters. Will be saved to AzKubeProxyUrl user environment variable for default value.
- `-SkipProxyAll` [Default: $false]: Skip setting proxy on any AKS cluster.
- `-SkipTestConnections` [Default: $false]: Skip testing connections to the AKS clusters.
- `-SetupAllWithDefaults` [Default: $false]: Simple mode to get kubectl credentials for all AKS clusters found on all subscriptions in logged in tenant without asking for user input using default proxy.
- `-SelectAll` [Default: $false]: Initially select all AKS clusters for getting kubectl credentials.

## Reporting Issues 🐛
If you encounter any issues, please report them by creating an issue. 
<!-- If you encounter any issues, please report them by creating an issue as described at [ISSUES.md](./docs/ISSUES.md). -->

## Contributing 🤝
We welcome contributions from the community! Reporting issues, requesting features, updating documentation, and/or implementing features (after concept discussion/approval so as not to waste effort) or fixes would all make this tool even more enjoyable. For example, suggesting or adding new commands that can be run against clusters could be relatively easy to implement, but add so much value. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Thanks 🙏
Thank you for your interest in AzKube! We appreciate your help in reporting issues and contributing to the project!
