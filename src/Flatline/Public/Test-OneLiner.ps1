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
        throw [System.NotImplementedException]::new('Test-OneLiner is not implemented yet.')
    }
}
