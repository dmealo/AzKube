BeforeAll {
    # Load the function under test
    $testPath = "$($PSCommandPath.Replace('tests', 'src').Replace('.Tests.ps1','.ps1'))"
    . $testPath
    Write-Host "Running tests for $($testPath)"
}

Describe "Set-AksClusters" {
    Context "Function definition and parameters" {
        It "Should have CmdletBinding attribute" {
            $function = Get-Command Set-AksClusters
            $function.CmdletBinding | Should -Be $true
        }

        It "Should have correct parameter definitions" {
            $function = Get-Command Set-AksClusters
            $function.Parameters.Keys | Should -Contain "ProxyUrl"
            $function.Parameters.Keys | Should -Contain "SkipProxyAll"
            $function.Parameters.Keys | Should -Contain "SkipTestConnections"
            $function.Parameters.Keys | Should -Contain "SetupAllWithDefaults"
            $function.Parameters.Keys | Should -Contain "SelectAll"
            $function.Parameters.Keys | Should -Contain "SkipTestActions"
        }

        It "Should have ProxyUrl parameter as string type" {
            $function = Get-Command Set-AksClusters
            $function.Parameters.ProxyUrl.ParameterType | Should -Be ([string])
        }

        It "Should have switch parameters as SwitchParameter type" {
            $function = Get-Command Set-AksClusters
            $function.Parameters.SkipProxyAll.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $function.Parameters.SkipTestConnections.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $function.Parameters.SetupAllWithDefaults.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $function.Parameters.SelectAll.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $function.Parameters.SkipTestActions.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }
    }

    Context "Function availability" {
        It "Should be available as a command" {
            Get-Command Set-AksClusters | Should -Not -BeNullOrEmpty
        }

        It "Should be defined as a function" {
            $function = Get-Command Set-AksClusters
            $function.CommandType | Should -Be "Function"
        }
    }
}