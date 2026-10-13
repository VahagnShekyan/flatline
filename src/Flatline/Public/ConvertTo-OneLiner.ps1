function ConvertTo-OneLiner {
    [CmdletBinding(DefaultParameterSetName = 'Script')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string]
        $Path,

        [Parameter(Mandatory, ParameterSetName = 'Script', ValueFromPipeline)]
        [string]
        $Script,

        [ValidateSet('Auto', 'Plain', 'Encoded')]
        [string]
        $Mode = 'Auto',

        [ValidateSet('None', 'WindowsPowerShell', 'Pwsh')]
        [string]
        $Wrap = 'None',

        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $MaxLength,

        [switch]
        $Clipboard
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
            $sourceText = [System.IO.File]::ReadAllText($resolved.ProviderPath)
        }
        else {
            $sourceText = $Script
        }

        $transform = ConvertTo-FlatlineLine -Text $sourceText
        foreach ($warning in $transform.Warnings) {
            Write-Warning $warning
        }
        $payload = $transform.Line

        $resolvedMode = $Mode
        if ($Mode -eq 'Auto') {
            if ($Wrap -ne 'None' -and (Test-FlatlineCmdHazard -Payload $payload)) {
                $resolvedMode = 'Encoded'
            }
            else {
                $resolvedMode = 'Plain'
            }
        }

        $result = Format-FlatlineWrap -Payload $payload -Wrap $Wrap -Mode $resolvedMode

        if ($PSBoundParameters.ContainsKey('MaxLength') -and $result.Length -gt $MaxLength) {
            $plainLength = (Format-FlatlineWrap -Payload $payload -Wrap $Wrap -Mode 'Plain').Length
            $encodedLength = (Format-FlatlineWrap -Payload $payload -Wrap $Wrap -Mode 'Encoded').Length
            throw ('The one-liner is {0} characters, over the -MaxLength of {1}. Plain form: {2} characters; Encoded form: {3} characters. Encoded output is roughly 2.7 times longer and cannot rescue a length limit. The cmd.exe command-line limit is 8191 characters.' -f $result.Length, $MaxLength, $plainLength, $encodedLength)
        }

        if ($Clipboard) {
            $setClipboard = Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue
            if ($setClipboard) {
                Set-Clipboard -Value $result
            }
            else {
                Write-Warning 'Set-Clipboard is not available on this platform; the result was not copied.'
            }
        }

        $result
    }
}
