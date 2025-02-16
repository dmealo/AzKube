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

    # Describe "Install-AzureCli" {
    #     Context "When Azure CLI is not installed" {
    #         BeforeEach {
    #             # Add a dummy winget function if not present to avoid CommandNotFoundException
    #             if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    #                 function winget { param($args) return }
    #             }
    #             Mock Get-Command { }
    #             Mock winget { }
    #         }

    #         It "Should install Azure CLI using WinGet" {
    #             # Act
    #             Install-AzureCli

    #             # Assert
    #             Assert-MockCalled winget -ParameterFilter { $args[0] -eq "install" -and $args[1] -eq "--id" -and $args[2] -eq "Microsoft.AzureCLI" -and $args[3] -eq "-e" } -Times 1
    #         }
    #     }

    #     Context "When Azure CLI is already installed" {
    #         BeforeEach {
    #             Mock Get-Command { az }
    #             # Ensure winget is stubbed too
    #             if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    #                 function winget { param($args) return }
    #             }
    #             Mock winget { }
    #         }

    #         It "Should not install Azure CLI" {
    #             # Act
    #             Install-AzureCli

    #             # Assert
    #             Assert-MockCalled winget -Times 0
    #         }
    #     }
    # }

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

    # Describe "Install-Kubectl" {
    #     Context "When kubectl is not installed" {
    #         BeforeEach {
    #             Mock Get-Command { }
    #             Mock winget { }
    #         }

    #         It "Should install kubectl using WinGet" {
    #             # Act
    #             Install-Kubectl

    #             # Assert
    #             Assert-MockCalled winget -ParameterFilter { $args[0] -eq "install" -and $args[1] -eq "--id" -and $args[2] -eq "Kubernetes.kubectl" -and $args[3] -eq "-e" } -Times 1
    #         }
    #     }

    #     Context "When kubectl is already installed" {
    #         BeforeEach {
    #             Mock Get-Command { kubectl }
    #             Mock winget { }
    #         }

    #         It "Should not install kubectl" {
    #             # Act
    #             Install-Kubectl

    #             # Assert
    #             Assert-MockCalled winget -Times 0
    #         }
    #     }
    # }

    Describe "Connect-AzureCli" {
        # Context "When not already logged into Azure CLI" {
        #     BeforeEach {
        #         Mock az { $null }
        #     }

        #     It "Should log into Azure CLI" {
        #         # Act
        #         Connect-AzureCli

        #         # Assert
        #         Assert-MockCalled az -ParameterFilter { $args[0] -eq "login" -and $args[1] -eq "--output" -and $args[2] -eq "none" } -Times 1
        #     }
        # }

        Context "When already logged into Azure CLI" {
            BeforeEach {
                Mock az { [PSCustomObject]@{ name = "TestAccount" } }
            }

            It "Should not log into Azure CLI" {
                # Act
                Connect-AzureCli

                # Assert
                Assert-MockCalled az -Times 1
            }
        }
    }

    Describe "Set-AzCliSubscription" {
        BeforeEach {
            Mock az { }
        }

        It "Should set the Azure CLI subscription context" {
            # Arrange
            $subscriptionId = "12345678-1234-1234-1234-1234567890ab"

            # Act
            Set-AzCliSubscription $subscriptionId

            # Assert
            Assert-MockCalled az -ParameterFilter { $args[0] -eq "account" -and $args[1] -eq "set" -and $args[2] -eq "--subscription" -and $args[3] -eq $subscriptionId -and $args[4] -eq "--output" -and $args[5] -eq "none" } -Times 1
        }
    }

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

    # Describe "Get-Kubectl-Credentials" {
    #     It "Should get kubeconfig for the AKS cluster and add it to the local kubeconfig file" {
    #         # Arrange
    #         $resourceGroup = "MyResourceGroup"
    #         $name = "MyCluster"

    #         # Act
    #         Get-Kubectl-Credentials -ResourceGroup $resourceGroup -Name $name

    #         # Assert
    #         # Add your assertions here
    #     }
    # }

    # Describe "Set-Kubectl-Cluster-Proxy" {
    #     It "Should set proxy for cluster in kubeconfig" {
    #         # Arrange
    #         Mock kubectl {  }
    #         $name = "MyCluster"
    #         $proxyUrl = "http://proxy.example.com"

    #         # Act
    #         Set-Kubectl-Cluster-Proxy -Name $name -ProxyUrl $proxyUrl

    #         # Assert
            
    #     }
    # }

    # Describe "Test-Kubectl-ServerVersion" {
    #     It "Should test connection to the AKS cluster and return the server version" {
    #         # Arrange
    #         Mock kubectl { [PSCustomObject]@{ serverVersion = "1.21.2" } }
    #         $name = "MyCluster"

    #         # Act
    #         $result = Test-Kubectl-ServerVersion -Name $name

    #         # Assert
    #         $result | Should -Be "1.21.2"
    #     }
    # }

    Describe "Get-SuccessShortString" {
        It "Should return a string with a green checkmark" {
            # Act
            $result = Get-SuccessShortString

            # Assert
            $result | Should -Be "`e[32m√`e[0m Success"
        }
    }

    Describe "Get-FailureShortString" {
        It "Should return a string with a red cross" {
            # Act
            $result = Get-FailureShortString

            # Assert
            $result | Should -Be "`e[31mX`e[0m Failure"
        }
    }

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