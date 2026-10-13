function ConvertTo-FlatlineTokenText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        $Token
    )

    $kind = $Token.Kind
    $isString = $kind -eq [System.Management.Automation.Language.TokenKind]::StringLiteral -or
    $kind -eq [System.Management.Automation.Language.TokenKind]::StringExpandable -or
    $kind -eq [System.Management.Automation.Language.TokenKind]::HereStringLiteral -or
    $kind -eq [System.Management.Automation.Language.TokenKind]::HereStringExpandable

    if (-not $isString) {
        return $Token.Text
    }

    $spansLines = $Token.Extent.StartLineNumber -ne $Token.Extent.EndLineNumber
    $isHere = $kind -eq [System.Management.Automation.Language.TokenKind]::HereStringLiteral -or
    $kind -eq [System.Management.Automation.Language.TokenKind]::HereStringExpandable

    if (-not $spansLines -and -not $isHere) {
        return $Token.Text
    }

    $isLiteral = $kind -eq [System.Management.Automation.Language.TokenKind]::StringLiteral -or
    $kind -eq [System.Management.Automation.Language.TokenKind]::HereStringLiteral

    if ($isLiteral) {
        return ConvertTo-FlatlineDoubleQuoteLiteral -Value $Token.Value
    }

    $inner = Get-FlatlineExpandableInner -Token $Token
    return ConvertTo-FlatlineDoubleQuoteExpandable -Inner $inner -StartLine $Token.Extent.StartLineNumber
}

function ConvertTo-FlatlineDoubleQuoteLiteral {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyString()]
        [string]
        $Value
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('"')
    foreach ($ch in $Value.ToCharArray()) {
        switch ($ch) {
            '`' { [void]$sb.Append('``') }
            '"' { [void]$sb.Append('`"') }
            '$' { [void]$sb.Append('`$') }
            "`r" { [void]$sb.Append('`r') }
            "`n" { [void]$sb.Append('`n') }
            "`0" { [void]$sb.Append('`0') }
            default { [void]$sb.Append($ch) }
        }
    }
    [void]$sb.Append('"')
    $sb.ToString()
}

function Get-FlatlineExpandableInner {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        $Token
    )

    $text = $Token.Text
    if ($Token.Kind -eq [System.Management.Automation.Language.TokenKind]::HereStringExpandable) {
        $firstNewline = $text.IndexOf("`n")
        $bodyStart = $firstNewline + 1
        $closeIndex = $text.LastIndexOf('"@')
        $bodyEnd = $closeIndex
        if ($bodyEnd -gt 0 -and $text[$bodyEnd - 1] -eq "`n") { $bodyEnd-- }
        if ($bodyEnd -gt 0 -and $text[$bodyEnd - 1] -eq "`r") { $bodyEnd-- }
        if ($bodyEnd -lt $bodyStart) { return '' }
        return $text.Substring($bodyStart, $bodyEnd - $bodyStart)
    }

    return $text.Substring(1, $text.Length - 2)
}

function ConvertTo-FlatlineDoubleQuoteExpandable {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyString()]
        [string]
        $Inner,

        [int]
        $StartLine
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('"')
    $i = 0
    $n = $Inner.Length
    while ($i -lt $n) {
        $c = $Inner[$i]
        if ($c -eq '`') {
            [void]$sb.Append('`')
            if ($i + 1 -lt $n) {
                [void]$sb.Append($Inner[$i + 1])
                $i += 2
            }
            else {
                $i += 1
            }
            continue
        }
        if ($c -eq '"') {
            [void]$sb.Append('`"')
            $i++
            continue
        }
        if ($c -eq "`r") {
            if ($i + 1 -lt $n -and $Inner[$i + 1] -eq "`n") {
                [void]$sb.Append('`r`n')
                $i += 2
            }
            else {
                [void]$sb.Append('`r')
                $i++
            }
            continue
        }
        if ($c -eq "`n") {
            [void]$sb.Append('`n')
            $i++
            continue
        }
        if ($c -eq '$' -and ($i + 1 -lt $n) -and $Inner[$i + 1] -eq '(') {
            [void]$sb.Append('$(')
            $i += 2
            $depth = 1
            while ($i -lt $n) {
                $d = $Inner[$i]
                if ($d -eq '"' -or $d -eq "'" -or $d -eq "`n" -or $d -eq "`r") {
                    throw ('Flatline cannot safely flatten an interpolated here-string with a multi-line or quote-bearing subexpression at line {0}. Rewrite that subexpression on one line first.' -f $StartLine)
                }
                if ($d -eq '(') { $depth++ }
                elseif ($d -eq ')') { $depth-- }
                [void]$sb.Append($d)
                $i++
                if ($depth -eq 0) { break }
            }
            continue
        }
        [void]$sb.Append($c)
        $i++
    }
    [void]$sb.Append('"')
    $sb.ToString()
}
