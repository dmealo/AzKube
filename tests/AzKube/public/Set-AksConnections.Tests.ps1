BeforeAll {
    # First load the dependencies with comprehensive mocking
    . "$PSScriptRoot/../../../src/AzKube/private/Aks-Utilities.ps1"
    . "$PSScriptRoot/../../../src/AzKube/private/Aks-Ui-Utilities.ps1"
    
    # Then load the function under test
    $testPath = "$($PSCommandPath.Replace('tests', 'src').Replace('.Tests.ps1','.ps1'))"
    . $testPath
    Write-Host "Running tests for $($testPath)"
    
    # Mock all external dependencies comprehensively
    Mock Write-Host { }
    Mock Install-AzureCli { }
    Mock Install-PSMenu { }
    Mock Install-AzModule { }
    Mock Get-DefaultProxyUrl { return "http://proxy:8080" }
    Mock Get-AzContext { return @{ Account = @{ Id = "test@test.com" }; Tenant = @{ Id = "test-tenant" } } }
    Mock Get-AzTenant { return @{ Name = "Test Tenant" } }
    Mock Connect-AzAccount { }
    Mock Invoke-AzureLoginReconciliation { }
    Mock Connect-AzureCli { }
    Mock Connect-Az { }
    Mock az { return '[]' }
    Mock exit { }
}

Describe "Set-AksConnections" {
    Context "When function is called with default parameters" {
        BeforeEach {
            # Mock all the dependencies
            Mock Get-AksClusters { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-ClusterMenu { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Get-KubectlCredentialsForAksClusters { }
            Mock Test-ConnectionsToAksClusters { }
        }

        It "Should not throw errors and complete execution" {
            # Act & Assert
            { Set-AksConnections } | Should -Not -Throw
        }

        It "Should call required initialization functions" {
            # Act
            Set-AksConnections

            # Assert
            Assert-MockCalled Install-AzureCli -Times 1
            Assert-MockCalled Install-PSMenu -Times 1
            Assert-MockCalled Get-DefaultProxyUrl -Times 1
        }

        It "Should get AKS clusters and process them" {
            # Act
            Set-AksConnections

            # Assert
            Assert-MockCalled Get-AksClusters -Times 1
            Assert-MockCalled Get-KubectlCredentialsForAksClusters -Times 1
            Assert-MockCalled Test-ConnectionsToAksClusters -Times 1
        }
    }

    Context "When called with SetupAllWithDefaults switch" {
        BeforeEach {
            Mock Get-AksClusters { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-ObjectArray { }
            Mock Get-KubectlCredentialsForAksClusters { }
            Mock Test-ConnectionsToAksClusters { }
        }

        It "Should skip menu and process all clusters with defaults" {
            # Act
            Set-AksConnections -SetupAllWithDefaults

            # Assert
            Assert-MockCalled Get-AksClusters -Times 1
            Assert-MockCalled Show-ObjectArray -Times 1
            Assert-MockCalled Get-KubectlCredentialsForAksClusters -Times 1
            Assert-MockCalled Test-ConnectionsToAksClusters -Times 1
        }
    }

    Context "When SkipTestConnections is specified" {
        BeforeEach {
            Mock Get-AksClusters { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-ClusterMenu { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Get-KubectlCredentialsForAksClusters { }
            Mock Test-ConnectionsToAksClusters { }
        }

        It "Should skip connection testing" {
            # Act
            Set-AksConnections -SkipTestConnections

            # Assert
            Assert-MockCalled Get-KubectlCredentialsForAksClusters -Times 1
            Assert-MockCalled Test-ConnectionsToAksClusters -Times 0
            Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Skipping testing connections*" } -Times 1
        }
    }

    Context "When no AKS clusters are found" {
        BeforeEach {
            Mock Get-AksClusters { return $null }
        }

        It "Should handle empty cluster list gracefully" {
            # Act & Assert
            { Set-AksConnections } | Should -Not -Throw
            
            # Verify it tries to get clusters but doesn't proceed further
            Assert-MockCalled Get-AksClusters -Times 1
        }
    }

    Context "When user cancels cluster selection" {
        BeforeEach {
            Mock Get-AksClusters { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-ClusterMenu { return $null }
            Mock Get-KubectlCredentialsForAksClusters { }
            Mock Test-ConnectionsToAksClusters { }
        }

        It "Should handle cancelled selection gracefully" {
            # Act & Assert
            { Set-AksConnections } | Should -Not -Throw
            
            # Should not proceed to credential setup
            Assert-MockCalled Get-KubectlCredentialsForAksClusters -Times 0
            Assert-MockCalled Test-ConnectionsToAksClusters -Times 0
        }
    }

    Context "Parameter validation" {
        BeforeEach {
            Mock Get-AksClusters { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-ClusterMenu { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Get-KubectlCredentialsForAksClusters { }
            Mock Test-ConnectionsToAksClusters { }
        }

        It "Should accept ProxyUrl parameter" {
            { Set-AksConnections -ProxyUrl "http://test-proxy:8080" } | Should -Not -Throw
        }

        It "Should accept all switch parameters" {
            { Set-AksConnections -SkipProxyAll -SkipTestConnections -SetupAllWithDefaults -SelectAll } | Should -Not -Throw
        }

        It "Should pass ProxyUrl to credential function" {
            # Act
            Set-AksConnections -ProxyUrl "http://custom-proxy:8080"

            # Assert
            Assert-MockCalled Get-KubectlCredentialsForAksClusters -ParameterFilter { 
                $args[1] -eq "http://custom-proxy:8080" 
            } -Times 1
        }

        It "Should pass SkipProxyAll flag correctly" {
            # Act
            Set-AksConnections -SkipProxyAll

            # Assert
            Assert-MockCalled Get-KubectlCredentialsForAksClusters -ParameterFilter { 
                $args[2] -eq $true 
            } -Times 1
        }
    }
}