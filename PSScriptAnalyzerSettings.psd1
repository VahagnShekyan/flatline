@{
    Severity = @('Error', 'Warning', 'Information')
    Rules    = @{
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSUseCompatibleSyntax     = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
    }
}
