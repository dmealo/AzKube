# src/AzKube/AzKube.psd1
@{
    ModuleVersion = '1.0.0'
    GUID = 'd3b3e1a1-5b5d-4b5d-8b5d-5b5d5b5d5b5d'
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Description = 'Module for managing AKS clusters'
    FunctionsToExport = @(
        'Set-AksClusters',
        'Set-AksKubectl'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('AKS', 'Kubernetes', 'Azure')
            # LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/your-repo'
        }
    }
}