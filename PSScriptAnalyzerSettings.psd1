# PSScriptAnalyzer settings for AzKube module
# See: https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Settings.md

@{
    # Enable all rules by default
    IncludeDefaultRules = $true
    
    # Severity levels to include
    Severity = @('Error', 'Warning', 'Information')
    
    # Rules to exclude (with justification)
    ExcludeRules = @(
        # Allow Write-Host for user interface output
        'PSAvoidUsingWriteHost'
    )
    
    # Rule-specific settings
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            IndentationSize = 4
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }
        
        PSUseCorrectCasing = @{
            Enable = $true
        }
        
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = 'before'
        }
        
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }
        
        PSAvoidUsingCmdletAliases = @{
            Whitelist = @('cd', 'dir', 'ls', 'cat')
        }
    }
}