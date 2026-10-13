function Get-FlatlineSignature {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[psobject]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.Ast]
        $Ast
    )

    $list = [System.Collections.Generic.List[psobject]]::new()
    foreach ($node in $Ast.FindAll({ $true }, $true)) {
        $key = $node.GetType().Name
        if ($node -is [System.Management.Automation.Language.VariableExpressionAst]) {
            $key += '|v=' + $node.VariablePath.UserPath
        }
        elseif ($node -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $key += '|s=' + $node.Value
        }
        elseif ($node -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
            $key += '|e=' + $node.Value
        }
        elseif ($node -is [System.Management.Automation.Language.ConstantExpressionAst]) {
            $key += '|c=' + [string]$node.Value
        }
        elseif ($node -is [System.Management.Automation.Language.CommandParameterAst]) {
            $key += '|p=' + $node.ParameterName
        }
        elseif ($node -is [System.Management.Automation.Language.TypeConstraintAst]) {
            $key += '|t=' + $node.TypeName.FullName
        }
        elseif ($node -is [System.Management.Automation.Language.TypeExpressionAst]) {
            $key += '|t=' + $node.TypeName.FullName
        }
        elseif ($node -is [System.Management.Automation.Language.NamedBlockAst]) {
            $key += '|unnamed=' + $node.Unnamed
        }
        $list.Add([pscustomobject]@{
                Key  = $key
                Line = $node.Extent.StartLineNumber
                Text = $node.Extent.Text
            })
    }
    , $list
}

function Resolve-FlatlineUnwrapped {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]
        $Ast
    )

    if ($null -ne $Ast.ParamBlock -or $null -ne $Ast.BeginBlock -or
        $null -ne $Ast.ProcessBlock -or $null -ne $Ast.DynamicParamBlock) {
        return $Ast
    }
    $endBlock = $Ast.EndBlock
    if ($null -eq $endBlock -or $endBlock.Statements.Count -ne 1) { return $Ast }

    $pipeline = $endBlock.Statements[0]
    if ($pipeline -isnot [System.Management.Automation.Language.PipelineAst]) { return $Ast }
    if ($pipeline.PipelineElements.Count -ne 1) { return $Ast }

    $command = $pipeline.PipelineElements[0]
    if ($command -isnot [System.Management.Automation.Language.CommandAst]) { return $Ast }
    if ($command.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Ampersand) { return $Ast }
    if ($command.CommandElements.Count -ne 1) { return $Ast }

    $element = $command.CommandElements[0]
    if ($element -isnot [System.Management.Automation.Language.ScriptBlockExpressionAst]) { return $Ast }

    $innerText = $element.ScriptBlock.Extent.Text
    $innerText = $innerText.Substring(1, $innerText.Length - 2)

    $prefix = ''
    if ($Ast.UsingStatements -and $Ast.UsingStatements.Count -gt 0) {
        $prefix = (($Ast.UsingStatements | ForEach-Object { $_.Extent.Text }) -join [Environment]::NewLine) + [Environment]::NewLine
    }

    $errs = $null
    $reparsed = [System.Management.Automation.Language.Parser]::ParseInput($prefix + $innerText, [ref]$null, [ref]$errs)
    if ($errs -and $errs.Count -gt 0) { return $Ast }
    return $reparsed
}
