BeforeAll {
    # First load the dependencies with comprehensive mocking
    . "$PSScriptRoot/../../../src/AzKube/private/Aks-Utilities.ps1"
    . "$PSScriptRoot/../../../src/AzKube/private/Aks-Ui-Utilities.ps1"
    
    # Then load the function under test
    $testPath = "$($PSCommandPath.Replace('tests', 'src').Replace('.Tests.ps1','.ps1'))"
    . $testPath
    Write-Host "Running tests for $($testPath)"
    
    # Mock all external dependencies comprehensively
    Mock Clear-Host { }
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

Describe "Set-AksClusters" {
    Context "When function is called with default parameters" {
        BeforeEach {
            # Mock all the dependencies
            Mock Get-AksClusters { return @() }
            Mock Show-ClusterMenu { return @() }
            Mock Show-AksCluster-Actions { return $null }
            Mock Invoke-ClusterAction { }
            
            # Mock the TenantList class functionality
            $mockTenant = [PSCustomObject]@{
                SelectedTenant = [PSCustomObject]@{ Id = "test-tenant"; Name = "Test Tenant" }
                DisplaySelectedTenant = { }
            }
            Mock New-Object { return $mockTenant } -ParameterFilter { $TypeName -eq 'TenantList' }
            
            # Mock environment variables
            $env:AzKubeSelectedTenant = $null
            $global:SelectedTenant = $null
        }

        It "Should not throw errors and complete execution" {
            # Act & Assert
            { Set-AksClusters } | Should -Not -Throw
        }

        It "Should call required initialization functions" {
            # Act
            Set-AksClusters

            # Assert
            Assert-MockCalled Install-AzureCli -Times 1
            Assert-MockCalled Install-PSMenu -Times 1
            Assert-MockCalled Get-DefaultProxyUrl -Times 1
        }
    }

    Context "When called with SetupAllWithDefaults switch" {
        BeforeEach {
            Mock Get-AksClusters { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-ClusterMenu { return @([Cluster]::new("TestCluster", "sub-123", "rg-test")) }
            Mock Show-AksCluster-Actions { 
                return [ManagementAction]::new("TestAction", "Test Description", { })
            }
            Mock Invoke-ClusterAction { }
            
            # Mock the TenantList class functionality
            $mockTenant = [PSCustomObject]@{
                SelectedTenant = [PSCustomObject]@{ Id = "test-tenant"; Name = "Test Tenant" }
                DisplaySelectedTenant = { }
            }
            Mock New-Object { return $mockTenant } -ParameterFilter { $TypeName -eq 'TenantList' }
        }

        It "Should process with default settings" {
            # Act
            { Set-AksClusters -SetupAllWithDefaults } | Should -Not -Throw

            # Assert
            Assert-MockCalled Get-AksClusters -Times 1
        }
    }

    Context "When no AKS clusters are found" {
        BeforeEach {
            Mock Get-AksClusters { return $null }
            
            # Mock the TenantList class functionality
            $mockTenant = [PSCustomObject]@{
                SelectedTenant = [PSCustomObject]@{ Id = "test-tenant"; Name = "Test Tenant" }
                DisplaySelectedTenant = { }
            }
            Mock New-Object { return $mockTenant } -ParameterFilter { $TypeName -eq 'TenantList' }
        }

        It "Should handle empty cluster list gracefully" {
            # Act & Assert
            { Set-AksClusters } | Should -Not -Throw
            
            # Verify it tries to get clusters
            Assert-MockCalled Get-AksClusters -Times 1
        }
    }

    Context "Parameter validation" {
        It "Should accept ProxyUrl parameter" {
            Mock Get-AksClusters { return $null }
            $mockTenant = [PSCustomObject]@{
                SelectedTenant = [PSCustomObject]@{ Id = "test-tenant"; Name = "Test Tenant" }
                DisplaySelectedTenant = { }
            }
            Mock New-Object { return $mockTenant } -ParameterFilter { $TypeName -eq 'TenantList' }
            
            { Set-AksClusters -ProxyUrl "http://test-proxy:8080" } | Should -Not -Throw
        }

        It "Should accept switch parameters" {
            Mock Get-AksClusters { return $null }
            $mockTenant = [PSCustomObject]@{
                SelectedTenant = [PSCustomObject]@{ Id = "test-tenant"; Name = "Test Tenant" }
                DisplaySelectedTenant = { }
            }
            Mock New-Object { return $mockTenant } -ParameterFilter { $TypeName -eq 'TenantList' }
            
            { Set-AksClusters -SkipProxyAll -SkipTestConnections -SetupAllWithDefaults -SelectAll -SkipTestActions } | Should -Not -Throw
        }
    }
}