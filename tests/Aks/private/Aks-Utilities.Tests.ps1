BeforeAll {
    $testPath = "$($PSCommandPath.Replace('tests', 'src').Replace('.Tests.ps1','.ps1'))"
    . $testPath
    Write-Host "Running tests for $($testPath)"
}

Describe "Cluster Tests" {
    It "Should create a Cluster object with correct properties" {
        # Arrange
        $name = "MyCluster"
        $subscriptionId = "12345678-1234-1234-1234-1234567890ab"
        $resourceGroup = "MyResourceGroup"

        # Act
        $cluster = [Cluster]::new($name, $subscriptionId, $resourceGroup)

        # Assert
        $cluster.Name | Should -Be $name
        # Removed from testing since Pester does not seem to reset static variables
        # $cluster.Index | Should -Be 1
        $cluster.SubscriptionId | Should -Be $subscriptionId
        $cluster.ResourceGroup | Should -Be $resourceGroup
    }

    It "Should return the correct string representation of the Cluster object" {
        # Arrange
        $name = "MyCluster"
        $subscriptionId = "12345678-1234-1234-1234-1234567890ab"
        $resourceGroup = "MyResourceGroup"
        $expectedString = "$name (RG: $resourceGroup - SubId: $subscriptionId)"
        $cluster = [Cluster]::new($name, $subscriptionId, $resourceGroup)

        # Act
        $result = $cluster.ToString()

        # Assert
        $result | Should -Be $expectedString
    }
}

# Describe "Test-ConnectionsToAksClusters Tests" {
#     BeforeAll {
#         # Mock the 'az' and 'kubectl' commands
#         Mock az { }
#         Mock kubectl { }
#     }

#     Context "When testing connections to AKS clusters" {
#         It "Should test connection to each AKS cluster" {
#             # Arrange
#             $aksClusters = @(
#                 [PSCustomObject]@{
#                     name = "Cluster1"
#                     subscriptionId = "12345678-1234-1234-1234-1234567890ab"
#                 },
#                 [PSCustomObject]@{
#                     name = "Cluster2"
#                     subscriptionId = "98765432-4321-4321-4321-0987654321ba"
#                 }
#             )

#             # Act
#             Test-ConnectionsToAksClusters $aksClusters

#             # Assert
#             # Verify that 'az account set' is called with the correct subscriptionId
#             Assert-MockCalled az -ParameterFilter { $args[0] -eq "account set" -and $args[1] -eq "--subscription" -and $args[2] -eq "12345678-1234-1234-1234-1234567890ab" } -Times 1
#             Assert-MockCalled az -ParameterFilter { $args[0] -eq "account set" -and $args[1] -eq "--subscription" -and $args[2] -eq "98765432-4321-4321-4321-0987654321ba" } -Times 1

#             # Verify that 'kubectl version' is called with the correct context
#             Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "version" -and $args[1] -eq "--context" -and $args[2] -eq "Cluster1-admin" } -Times 1
#             Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "version" -and $args[1] -eq "--context" -and $args[2] -eq "Cluster2-admin" } -Times 1
#         }
#     }
# }

# Describe "Aks-Utilities Tests" {
#     BeforeAll {
#         $testPath = "$($PSCommandPath.Replace('tests', 'src').Replace('.Tests.ps1','.ps1'))"
#         . $testPath
#         Write-Host "Running tests for $($testPath)"
#     }

#     Describe "Get-KubectlCredentialsForAksClusters" {
#         Context "When logged into Azure CLI" {
#             BeforeAll {
#                 Mock az { }
#                 Mock kubectl { }
#             }

#             It "Should install kubectl if not already installed" {
#                 # Arrange
#                 Mock Get-Command { } -ParameterFilter { $args[0] -eq "kubectl" } -ErrorAction SilentlyContinue

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters

#                 # Assert
#                 Assert-MockCalled winget -ParameterFilter { $args[0] -eq "install" -and $args[1] -eq "--id" -and $args[2] -eq "Kubernetes.kubectl" -and $args[3] -eq "-e" } -Times 1
#             }

#             It "Should set subscription context for each AKS cluster" {
#                 # Arrange
#                 Mock az { }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters

#                 # Assert
#                 Assert-MockCalled az -ParameterFilter { $args[0] -eq "account set" -and $args[1] -eq "--subscription" -and $args[2] -eq "12345678-1234-1234-1234-1234567890ab" } -Times 1
#                 Assert-MockCalled az -ParameterFilter { $args[0] -eq "account set" -and $args[1] -eq "--subscription" -and $args[2] -eq "98765432-4321-4321-4321-0987654321ba" } -Times 1
#             }

#             It "Should get kubeconfig for each AKS cluster" {
#                 # Arrange
#                 Mock az { }
#                 Mock kubectl { }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters

#                 # Assert
#                 Assert-MockCalled az -ParameterFilter { $args[0] -eq "aks get-credentials" -and $args[1] -eq "--name" -and $args[2] -eq "Cluster1" -and $args[3] -eq "--resource-group" -and $args[4] -eq "MyResourceGroup" -and $args[5] -eq "--admin" -and $args[6] -eq "--overwrite-existing" } -Times 1
#                 Assert-MockCalled az -ParameterFilter { $args[0] -eq "aks get-credentials" -and $args[1] -eq "--name" -and $args[2] -eq "Cluster2" -and $args[3] -eq "--resource-group" -and $args[4] -eq "MyResourceGroup" -and $args[5] -eq "--admin" -and $args[6] -eq "--overwrite-existing" } -Times 1
#             }

#             It "Should set proxy for all clusters if chosen" {
#                 # Arrange
#                 Mock az { }
#                 Mock kubectl { }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters -ProxyUrl "http://proxy.example.com" -SkipProxyAll:$false -SetupAllWithDefaults:$false

#                 # Assert
#                 Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "config set-cluster" -and $args[1] -eq "Cluster1" -and $args[2] -eq "--proxy-url=http://proxy.example.com" } -Times 1
#                 Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "config set-cluster" -and $args[1] -eq "Cluster2" -and $args[2] -eq "--proxy-url=http://proxy.example.com" } -Times 1
#             }

#             It "Should not set proxy for any cluster if chosen" {
#                 # Arrange
#                 Mock az { }
#                 Mock kubectl { }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters -SkipProxyAll:$true

#                 # Assert
#                 Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "config set-cluster" } -Times 0
#             }

#             It "Should ask user for proxy usage per cluster" {
#                 # Arrange
#                 Mock az { }
#                 Mock kubectl { }
#                 Mock Read-Host { "y" }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters -ProxyUrl "http://proxy.example.com" -SkipProxyAll:$false -SetupAllWithDefaults:$false

#                 # Assert
#                 Assert-MockCalled Read-Host -ParameterFilter { $args[0] -eq "Use proxy (http://proxy.example.com) for cluster Cluster1? (y/n)" } -Times 1
#                 Assert-MockCalled Read-Host -ParameterFilter { $args[0] -eq "Use proxy (http://proxy.example.com) for cluster Cluster2? (y/n)" } -Times 1
#                 Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "config set-cluster" -and $args[1] -eq "Cluster1" -and $args[2] -eq "--proxy-url=http://proxy.example.com" } -Times 1
#                 Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "config set-cluster" -and $args[1] -eq "Cluster2" -and $args[2] -eq "--proxy-url=http://proxy.example.com" } -Times 1
#             }

#             It "Should ask user for alternative proxy URL per cluster" {
#                 # Arrange
#                 Mock az { }
#                 Mock kubectl { }
#                 Mock Read-Host { "http://altproxy.example.com" }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters -ProxyUrl "http://proxy.example.com" -SkipProxyAll:$false -SetupAllWithDefaults:$false

#                 # Assert
#                 Assert-MockCalled Read-Host -ParameterFilter { $args[0] -eq "Use proxy (http://proxy.example.com) for cluster Cluster1? (y/n)" } -Times 1
#                 Assert-MockCalled Read-Host -ParameterFilter { $args[0] -eq "Specify alternative Proxy URL for cluster Cluster1 or ENTER for no proxy" } -Times 1
#                 Assert-MockCalled kubectl -ParameterFilter { $args[0] -eq "config set-cluster" -and $args[1] -eq "Cluster1" -and $args[2] -eq "--proxy-url=http://altproxy.example.com" } -Times 1
#             }
#         }

#         Context "When not logged into Azure CLI" {
#             BeforeAll {
#                 Mock az { $null }
#                 Mock kubectl { }
#             }

#             It "Should log into Azure CLI" {
#                 # Arrange
#                 Mock az { }

#                 # Act
#                 Get-KubectlCredentialsForAksClusters @aksClusters

#                 # Assert
#                 Assert-MockCalled az -ParameterFilter { $args[0] -eq "login" -and $args[1] -eq "--output" -and $args[2] -eq "none" } -Times 1
#             }
#         }
#     }
# }