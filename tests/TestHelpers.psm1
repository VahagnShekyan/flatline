function Get-CurrentPowerShellPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $path = (Get-Process -Id $PID).Path
    if ($path) { return $path }
    if ($PSVersionTable.PSEdition -eq 'Desktop') { return 'powershell.exe' }
    return 'pwsh'
}

function Invoke-FlatlineFreshProcess {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Code
    )

    $exe = Get-CurrentPowerShellPath
    $scriptFile = [System.IO.Path]::GetTempFileName()
    $scriptPath = [System.IO.Path]::ChangeExtension($scriptFile, 'ps1')
    Move-Item -LiteralPath $scriptFile -Destination $scriptPath -Force
    $errorPath = [System.IO.Path]::GetTempFileName()

    try {
        Set-Content -LiteralPath $scriptPath -Value $Code -NoNewline -Encoding UTF8
        $output = & $exe -NoProfile -NonInteractive -File $scriptPath 2> $errorPath
        $exitCode = $LASTEXITCODE
        $stderr = Get-Content -LiteralPath $errorPath -Raw
        [pscustomobject]@{
            StdOut        = ($output | Out-String)
            StdErrWritten = -not [string]::IsNullOrWhiteSpace($stderr)
            ExitCode      = $exitCode
        }
    }
    finally {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $errorPath -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Get-CurrentPowerShellPath, Invoke-FlatlineFreshProcess
