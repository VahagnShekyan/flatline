function ConvertTo-FlatlineLine {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Text
    )

    $warnings = [System.Collections.Generic.List[string]]::new()

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$parseErrors)

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $detail = ($parseErrors | ForEach-Object {
                'Line {0}: {1}' -f $_.Extent.StartLineNumber, $_.Message
            }) -join [Environment]::NewLine
        throw ('Flatline cannot convert a script with parse errors:{0}{1}' -f [Environment]::NewLine, $detail)
    }

    $boundaryOffsets = [System.Collections.Generic.HashSet[int]]::new()
    $astNodes = $ast.FindAll({ $true }, $true)
    foreach ($node in $astNodes) {
        if ($node -is [System.Management.Automation.Language.NamedBlockAst] -or
            $node -is [System.Management.Automation.Language.StatementBlockAst]) {
            $statements = $node.Statements
            for ($i = 1; $i -lt $statements.Count; $i++) {
                [void]$boundaryOffsets.Add($statements[$i].Extent.StartOffset)
            }
        }
        elseif ($node -is [System.Management.Automation.Language.HashtableAst]) {
            $pairs = $node.KeyValuePairs
            for ($i = 1; $i -lt $pairs.Count; $i++) {
                [void]$boundaryOffsets.Add($pairs[$i].Item1.Extent.StartOffset)
            }
        }
        elseif ($node -is [System.Management.Automation.Language.TypeDefinitionAst]) {
            $members = $node.Members
            for ($i = 1; $i -lt $members.Count; $i++) {
                [void]$boundaryOffsets.Add($members[$i].Extent.StartOffset)
            }
        }
    }

    $usingStatements = $ast.UsingStatements
    $hasUsing = $usingStatements -and $usingStatements.Count -gt 0
    if ($hasUsing) {
        for ($i = 1; $i -lt $usingStatements.Count; $i++) {
            [void]$boundaryOffsets.Add($usingStatements[$i].Extent.StartOffset)
        }
    }

    $paramBlock = $ast.ParamBlock
    $hasParam = $null -ne $paramBlock

    $afterUsingOffset = -1
    if ($hasUsing) {
        $candidates = [System.Collections.Generic.List[int]]::new()
        foreach ($b in @($ast.ParamBlock, $ast.BeginBlock, $ast.ProcessBlock, $ast.EndBlock, $ast.DynamicParamBlock)) {
            if ($null -ne $b) { $candidates.Add($b.Extent.StartOffset) }
        }
        foreach ($blockNode in @($ast.BeginBlock, $ast.ProcessBlock, $ast.EndBlock, $ast.DynamicParamBlock)) {
            if ($null -ne $blockNode -and $blockNode.Statements.Count -gt 0) {
                $candidates.Add($blockNode.Statements[0].Extent.StartOffset)
            }
        }
        $future = $candidates | Where-Object { $_ -gt $usingStatements[$usingStatements.Count - 1].Extent.EndOffset }
        if ($future) { $afterUsingOffset = ($future | Measure-Object -Minimum).Minimum }
    }

    foreach ($token in $tokens) {
        if ($token.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment) {
            if ($token.Text -match '(?im)^\s*#requires\b') {
                $warnings.Add('Dropped a #requires statement; it has no effect on one line. Satisfy its requirement manually.') | Out-Null
            }
            if ($token.Text -match '(?im)\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)\b') {
                $warnings.Add('Dropped comment-based help. Document the one-liner elsewhere.') | Out-Null
            }
        }
    }
    $uniqueWarnings = [System.Collections.Generic.List[string]]::new()
    foreach ($w in ($warnings | Select-Object -Unique)) { $uniqueWarnings.Add($w) }
    $warnings = $uniqueWarnings

    $render = {
        param([int]$MinOffset, [int]$MaxOffset)

        $sb = [System.Text.StringBuilder]::new()
        $prevEnd = -1
        $lastChar = ''

        foreach ($token in $tokens) {
            $kind = $token.Kind
            if ($kind -eq [System.Management.Automation.Language.TokenKind]::Comment -or
                $kind -eq [System.Management.Automation.Language.TokenKind]::NewLine -or
                $kind -eq [System.Management.Automation.Language.TokenKind]::LineContinuation -or
                $kind -eq [System.Management.Automation.Language.TokenKind]::EndOfInput) {
                continue
            }

            $start = $token.Extent.StartOffset
            if ($start -lt $MinOffset -or $start -ge $MaxOffset) { continue }

            $isBoundary = $boundaryOffsets.Contains($start)
            $hadGap = ($prevEnd -ge 0 -and $start -gt $prevEnd)

            if ($sb.Length -gt 0) {
                if ($isBoundary) {
                    if ($lastChar -ne ';' -and $lastChar -ne '{') {
                        [void]$sb.Append(';')
                        $lastChar = ';'
                    }
                }
                elseif ($hadGap) {
                    [void]$sb.Append(' ')
                    $lastChar = ' '
                }
            }

            $piece = ConvertTo-FlatlineTokenText -Token $token
            [void]$sb.Append($piece)
            if ($piece.Length -gt 0) { $lastChar = $piece[$piece.Length - 1] }
            $prevEnd = $token.Extent.EndOffset
        }

        $sb.ToString()
    }

    if ($hasUsing -and $afterUsingOffset -ge 0) {
        $usingPart = & $render 0 $afterUsingOffset
        $bodyPart = & $render $afterUsingOffset ([int]::MaxValue)
        if ($hasParam) {
            $line = '{0};& {{ {1} }}' -f $usingPart, $bodyPart
        }
        else {
            $line = '{0};{1}' -f $usingPart, $bodyPart
        }
    }
    elseif ($hasParam) {
        $line = '& {{ {0} }}' -f (& $render 0 ([int]::MaxValue))
    }
    else {
        $line = & $render 0 ([int]::MaxValue)
    }

    [pscustomobject]@{
        Line     = $line
        Warnings = $warnings.ToArray()
        Wrapped  = [bool]$hasParam
    }
}
