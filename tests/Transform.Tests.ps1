BeforeDiscovery {
    $script:FixtureRoot = Join-Path $PSScriptRoot 'fixtures'
    $script:Fixtures = Get-ChildItem -Path $script:FixtureRoot -Filter '*.ps1' |
        Sort-Object Name |
        ForEach-Object { @{ Name = $_.BaseName; FullName = $_.FullName } }
}

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'Flatline' 'Flatline.psd1') -Force
    Import-Module (Join-Path $PSScriptRoot 'TestHelpers.psm1') -Force
}

AfterAll {
    Remove-Module Flatline -Force -ErrorAction SilentlyContinue
    Remove-Module TestHelpers -Force -ErrorAction SilentlyContinue
}

Describe 'ConvertTo-OneLiner transform' {
    Context 'fixture <Name>' -ForEach $Fixtures {
        BeforeAll {
            $script:Source = Get-Content -LiteralPath $FullName -Raw
            $script:OneLiner = ConvertTo-OneLiner -Script $script:Source -WarningAction SilentlyContinue
        }

        It 'emits a single line with no carriage return or line feed' {
            $script:OneLiner | Should -Not -Match "[`r`n]"
        }

        It 'is structurally equivalent to the original' {
            $result = Test-OneLiner -Original $script:Source -OneLiner $script:OneLiner
            $result.ParseErrors | Should -BeNullOrEmpty
            $result.Equivalent | Should -BeTrue
        }

        It 'behaves identically in a fresh process' {
            $original = Invoke-FlatlineFreshProcess -Code $script:Source
            $flat = Invoke-FlatlineFreshProcess -Code $script:OneLiner
            $flat.StdOut | Should -BeExactly $original.StdOut
            $flat.ExitCode | Should -Be $original.ExitCode
            $flat.StdErrWritten | Should -Be $original.StdErrWritten
        }
    }
}

Describe 'Dropped constructs raise warnings' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'src' 'Flatline' 'Flatline.psd1') -Force
        $script:Source = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures' 'requires-and-help.ps1') -Raw
    }

    It 'warns about a dropped #requires statement' {
        $warnings = @()
        ConvertTo-OneLiner -Script $script:Source -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        ($warnings -join "`n") | Should -Match '#requires'
    }

    It 'warns about dropped comment-based help' {
        $warnings = @()
        ConvertTo-OneLiner -Script $script:Source -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        ($warnings -join "`n") | Should -Match 'comment-based help'
    }
}

Describe 'Parse errors are reported, not mangled' {
    It 'throws with a line number when the input does not parse' {
        { ConvertTo-OneLiner -Script 'if ($true) {' } |
            Should -Throw -ExpectedMessage '*parse errors*'
    }
}

Describe 'Interpolated here-string with a complex subexpression is refused' {
    It 'throws rather than emit something that might differ' {
        $src = "@`"`nvalue `$(`nGet-Date`n)`n`"@"
        { ConvertTo-OneLiner -Script $src } | Should -Throw
    }
}
