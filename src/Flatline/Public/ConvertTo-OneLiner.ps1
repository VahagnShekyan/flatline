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

        [int]
        $MaxLength,

        [switch]
        $Clipboard
    )

    process {
        throw [System.NotImplementedException]::new('ConvertTo-OneLiner is not implemented yet.')
    }
}
