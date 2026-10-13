BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'Flatline' 'Flatline.psd1') -Force
}

AfterAll {
    Remove-Module Flatline -Force -ErrorAction SilentlyContinue
}

Describe 'Test-OneLiner' {
    It 'reports equivalence for an identical program on one line' {
        $result = Test-OneLiner -Original "$('$a = 1')`n`$a + 2" -OneLiner '$a = 1;$a + 2'
        $result.Equivalent | Should -BeTrue
    }

    It 'treats a here-string and its double-quoted form as equivalent by value' {
        $original = "@`"`nhello `$name`n`"@"
        $oneLiner = '"hello `$name"' -replace '`\$', '$'
        $result = Test-OneLiner -Original $original -OneLiner '"hello $name"'
        $result.Equivalent | Should -BeTrue
    }

    It 'unwraps an & { } param wrapper before comparing' {
        $original = "param(`$x)`n`$x + 1"
        $oneLiner = '& { param($x) $x + 1 }'
        $result = Test-OneLiner -Original $original -OneLiner $oneLiner
        $result.Equivalent | Should -BeTrue
    }

    It 'detects a changed constant' {
        $result = Test-OneLiner -Original '1 + 2' -OneLiner '1 + 3'
        $result.Equivalent | Should -BeFalse
        $result.FirstDifference | Should -Not -BeNullOrEmpty
    }

    It 'detects a changed variable name' {
        $result = Test-OneLiner -Original '$a = 1' -OneLiner '$b = 1'
        $result.Equivalent | Should -BeFalse
    }

    It 'detects a changed command name' {
        $result = Test-OneLiner -Original 'Get-Thing' -OneLiner 'Get-Other'
        $result.Equivalent | Should -BeFalse
    }

    It 'reports parse errors and is not equivalent' {
        $result = Test-OneLiner -Original 'if ($true) {' -OneLiner '$a = 1'
        $result.Equivalent | Should -BeFalse
        $result.ParseErrors | Should -Not -BeNullOrEmpty
    }
}
