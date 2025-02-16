# AzKube 🚀

## Overview 📖
AzKube is a PowerShell module designed to simplify the management and automation of Azure Kubernetes Service (AKS) clusters. It provides a set of cmdlets to manage AKS clusters, connections, and utilities to streamline your workflow.

## Features ✨
- Manage AKS clusters
    - Set up AKS connections for `kubectl` and `kubectl`-based tools (like OpenLens, Lens, k9s, etc.)
    - Test AKS connections for `kubectl` et al
    - Get resource IDs for AKS clusters
    - Run `az resource update` on AKS clusters to restart AKS Planned Maintenance (Cluster Upgrades, Node Image Upgrades, Weekly Updates)
- Set up AKS connections standalone command
    - Set up AKS connections for `kubectl` and `kubectl`-based tools (like OpenLens, Lens, k9s, etc.)
    - Test AKS connections for `kubectl` et al

## Usage 🛠️
To use the AzKube module, import it into your PowerShell session and use the available cmdlets. Below are some examples:

### Import the Module 📥
```powershell
Import-Module -Name AzKube
```

### Set AKS Clusters 🌐
```powershell
Set-AksClusters -ProxyUrl "http://proxy.example.com" -SkipProxyAll -SkipTestConnections -SetupAllWithDefaults -SelectAll -SkipTestActions
```
- `-ProxyUrl`: Proxy URL to be used for all AKS clusters.
- `-SkipProxyAll`: Skip setting proxy on any AKS cluster.
- `-SkipTestConnections`: Skip testing connections to the AKS clusters.
- `-SetupAllWithDefaults`: Simple mode to get kubectl credentials for all AKS clusters found on all subscriptions in logged in tenant without asking for user input using default proxy.
- `-SelectAll`: Initially select all AKS clusters for taking the action selected in the menu.
- `-SkipTestActions`: Skip testing connections to the AKS clusters.

### Set AKS Connections 🔗
```powershell
Set-AksConnections -ProxyUrl "http://proxy.example.com" -SkipProxyAll -SkipTestConnections -SetupAllWithDefaults -SelectAll
```
- `-ProxyUrl`: Proxy URL to be used for all AKS clusters.
- `-SkipProxyAll`: Skip setting proxy on any AKS cluster.
- `-SkipTestConnections`: Skip testing connections to the AKS clusters.
- `-SetupAllWithDefaults`: Simple mode to get kubectl credentials for all AKS clusters found on all subscriptions in logged in tenant without asking for user input using default proxy.
- `-SelectAll`: Initially select all AKS clusters for getting kubectl credentials.

## Reporting Issues 🐛
If you encounter any issues, please report them by creating an issue in the [ISSUES.md](ISSUES.md) file.

## Contributing 🤝
We welcome contributions from the community. Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines on how to contribute to the project.

## Thanks 🙏
Thank you for your interest in AzKube. We appreciate your help in reporting issues and contributing to the project.
