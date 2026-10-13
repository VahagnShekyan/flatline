function Test-OneLiner {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Original,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $OneLiner
    )

    process {
        $originalErrors = $null
        $oneLinerErrors = $null
        $originalAst = [System.Management.Automation.Language.Parser]::ParseInput($Original, [ref]$null, [ref]$originalErrors)
        $oneLinerAst = [System.Management.Automation.Language.Parser]::ParseInput($OneLiner, [ref]$null, [ref]$oneLinerErrors)

        $parseErrors = [System.Collections.Generic.List[string]]::new()
        foreach ($e in @($originalErrors)) {
            if ($e) { $parseErrors.Add(('Original line {0}: {1}' -f $e.Extent.StartLineNumber, $e.Message)) }
        }
        foreach ($e in @($oneLinerErrors)) {
            if ($e) { $parseErrors.Add(('OneLiner line {0}: {1}' -f $e.Extent.StartLineNumber, $e.Message)) }
        }

        if ($parseErrors.Count -gt 0) {
            return [pscustomobject]@{
                Equivalent      = $false
                ParseErrors     = $parseErrors.ToArray()
                FirstDifference = $null
            }
        }

        $originalAst = Resolve-FlatlineUnwrapped -Ast $originalAst
        $oneLinerAst = Resolve-FlatlineUnwrapped -Ast $oneLinerAst

        $originalSignature = Get-FlatlineSignature -Ast $originalAst
        $oneLinerSignature = Get-FlatlineSignature -Ast $oneLinerAst

        $max = [Math]::Max($originalSignature.Count, $oneLinerSignature.Count)
        $firstDifference = $null
        for ($i = 0; $i -lt $max; $i++) {
            $left = if ($i -lt $originalSignature.Count) { $originalSignature[$i] } else { $null }
            $right = if ($i -lt $oneLinerSignature.Count) { $oneLinerSignature[$i] } else { $null }
            $leftKey = if ($left) { $left.Key } else { $null }
            $rightKey = if ($right) { $right.Key } else { $null }
            if ($leftKey -ne $rightKey) {
                $firstDifference = [pscustomobject]@{
                    OriginalNode = if ($left) { '{0} (line {1}): {2}' -f $left.Key, $left.Line, $left.Text } else { '(none)' }
                    OneLinerNode = if ($right) { '{0}: {1}' -f $right.Key, $right.Text } else { '(none)' }
                }
                break
            }
        }

        [pscustomobject]@{
            Equivalent      = $null -eq $firstDifference
            ParseErrors     = @()
            FirstDifference = $firstDifference
        }
    }
}
