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

Describe "Aks-Utilities Tests" {
    BeforeAll {
        $testPath = "$($PSCommandPath.Replace('tests', 'src').Replace('.Tests.ps1','.ps1'))"
        . $testPath
        Write-Host "Running tests for $($testPath)"
    }

    Describe "Install-AzureCli" {
        Context "When Azure CLI is not installed" {
            BeforeEach {
                Mock Get-Command { }
                Mock winget { }
            }

            It "Should install Azure CLI using WinGet" {
                # Act
                Install-AzureCli

                # Assert
                Assert-MockCalled winget -ParameterFilter { $args[0] -eq "install" -and $args[1] -eq "--id" -and $args[2] -eq "Microsoft.AzureCLI" -and $args[3] -eq "-e" } -Times 1
            }
        }

        Context "When Azure CLI is already installed" {
            BeforeEach {
                Mock Get-Command { az }
                Mock winget { }
            }

            It "Should not install Azure CLI" {
                # Act
                Install-AzureCli

                # Assert
                Assert-MockCalled winget -Times 0
            }
        }
    }

    # Describe "Install-PSMenu" {
    #     Context "When PSMenu is not installed" {
    #         BeforeEach {
    #             Mock Get-Command { }
    #             Mock Install-Module { }
    #         }

    #         It "Should install PSMenu" {
    #             # Act
    #             Install-PSMenu

    #             # Assert
    #             Assert-MockCalled Install-Module -ParameterFilter { $args[0] -eq "PSMenu" -and $args[1] -eq "-Force" } -Times 1
    #         }
    #     }

    #     Context "When PSMenu is already installed" {
    #         BeforeEach {
    #             Mock Get-Command { Show-Menu }
    #         }

    #         It "Should not install PSMenu" {
    #             # Act
    #             Install-PSMenu

    #             # Assert
    #             Assert-MockCalled Install-Module -Times 0
    #         }
    #     }
    # }

    # Describe "Show-ObjectArray" {
    #     BeforeEach {
    #         Mock Write-Host { }
    #     }

    #     It "Should display objects in the specified color" {
    #         # Arrange
    #         $objects = @(
    #             [PSCustomObject]@{ Name = "Object1" },
    #             [PSCustomObject]@{ Name = "Object2" }
    #         )
    #         $color = "Green"

    #         # Act
    #         Show-ObjectArray $objects $color

    #         # Assert
    #         Assert-MockCalled Write-Host -ParameterFilter { $args[0] -eq "Object1" -and $args[1] -eq "-ForegroundColor" -and $args[2] -eq "Green" } -Times 1
    #         Assert-MockCalled Write-Host -ParameterFilter { $args[0] -eq "Object2" -and $args[1] -eq "-ForegroundColor" -and $args[2] -eq "Green" } -Times 1
    #     }
    # }

    # Describe "Get-AksClusters" {
    #     Context "When AKS clusters are found" {
    #         BeforeEach {
    #             Mock az { [PSCustomObject]@{ data = @(@{ name = "Cluster1"; subscriptionId = "12345678-1234-1234-1234-1234567890ab"; resourceGroup = "MyResourceGroup" }) } }
    #         }

    #         It "Should return an array of Cluster objects" {
    #             # Act
    #             $result = Get-AksClusters

    #             # Assert
    #             $result | Should -BeOfType [System.Array]
    #             $result.Length | Should -Be 1
    #             $result[0].Name | Should -Be "Cluster1"
    #             $result[0].SubscriptionId | Should -Be "12345678-1234-1234-1234-1234567890ab"
    #             $result[0].ResourceGroup | Should -Be "MyResourceGroup"
    #         }
    #     }

    #     Context "When no AKS clusters are found" {
    #         BeforeEach {
    #             Mock az { [PSCustomObject]@{ data = @() } }
    #         }

    #         It "Should display a message and return null" {
    #             # Act
    #             $result = Get-AksClusters

    #             # Assert
    #             $result | Should -BeNull
    #             Assert-MockCalled Write-Host -ParameterFilter { $args[0] -eq "No AKS clusters found to get kubectl credentials for. Verify that you have logged into the correct Azure subscription(s) with permission to access AKS clusters and retry." -and $args[1] -eq "-ForegroundColor" -and $args[2] -eq "Orange" } -Times 1
    #         }
    #     }
    # }
}