BeforeAll {
    $script:ModuleRoot = Join-Path $PSScriptRoot '..' 'src' 'Flatline'
    $script:ManifestPath = Join-Path $script:ModuleRoot 'Flatline.psd1'
    Import-Module $script:ManifestPath -Force
}

AfterAll {
    Remove-Module Flatline -Force -ErrorAction SilentlyContinue
}

Describe 'Flatline module' {
    It 'has a valid manifest' {
        $manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
        $manifest.Version | Should -Be '0.1.0'
        $manifest.PowerShellVersion | Should -Be '5.1'
    }

    It 'exports exactly the two public functions' {
        $exported = (Get-Command -Module Flatline).Name | Sort-Object
        $exported | Should -Be @('ConvertTo-OneLiner', 'Test-OneLiner')
    }

    It 'is compatible with Desktop and Core editions' {
        $manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
        $manifest.CompatiblePSEditions | Should -Contain 'Desktop'
        $manifest.CompatiblePSEditions | Should -Contain 'Core'
    }
}
