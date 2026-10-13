function ConvertTo-FlatlineEncoded {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Payload
    )

    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Payload)
    [System.Convert]::ToBase64String($bytes)
}

function Test-FlatlineCmdHazard {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Payload
    )

    return $Payload.IndexOf('"') -ge 0 -or
    $Payload.IndexOf('%') -ge 0 -or
    $Payload.IndexOf('!') -ge 0
}

function Format-FlatlineWrap {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Payload,

        [Parameter(Mandatory)]
        [ValidateSet('None', 'WindowsPowerShell', 'Pwsh')]
        [string]
        $Wrap,

        [Parameter(Mandatory)]
        [ValidateSet('Plain', 'Encoded')]
        [string]
        $Mode
    )

    if ($Wrap -eq 'None') {
        if ($Mode -eq 'Encoded') {
            return ConvertTo-FlatlineEncoded -Payload $Payload
        }
        return $Payload
    }

    $exe = if ($Wrap -eq 'WindowsPowerShell') { 'powershell.exe' } else { 'pwsh' }

    if ($Mode -eq 'Encoded') {
        $encoded = ConvertTo-FlatlineEncoded -Payload $Payload
        return '{0} -NoProfile -EncodedCommand {1}' -f $exe, $encoded
    }

    return '{0} -NoProfile -Command "{1}"' -f $exe, $Payload
}
