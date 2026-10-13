BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../src/Flatline/Flatline.psd1') -Force
}

AfterAll {
    Remove-Module Flatline -Force -ErrorAction SilentlyContinue
}

Describe 'ConvertTo-OneLiner modes and wrapping' {
    It 'defaults to bare Plain output with no wrapper' {
        ConvertTo-OneLiner -Script '$a = 1' | Should -BeExactly '$a = 1'
    }

    It 'accepts pipeline input' {
        ('$a = 1' | ConvertTo-OneLiner) | Should -BeExactly '$a = 1'
    }

    It 'reads from a file with -Path' {
        $temp = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), 'ps1')
        Set-Content -LiteralPath $temp -Value "'hello'" -NoNewline
        try {
            ConvertTo-OneLiner -Path $temp | Should -BeExactly "'hello'"
        }
        finally {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }

    It 'produces a decodable EncodedCommand' {
        $encoded = ConvertTo-OneLiner -Script 'Write-Output hi' -Mode Encoded
        $decoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($encoded))
        $decoded | Should -BeExactly 'Write-Output hi'
    }

    It 'wraps WindowsPowerShell with -NoProfile' {
        $out = ConvertTo-OneLiner -Script 'Get-Date' -Wrap WindowsPowerShell
        $out | Should -BeExactly 'powershell.exe -NoProfile -Command "Get-Date"'
    }

    It 'wraps pwsh with -NoProfile' {
        $out = ConvertTo-OneLiner -Script 'Get-Date' -Wrap Pwsh
        $out | Should -BeExactly 'pwsh -NoProfile -Command "Get-Date"'
    }
}

Describe 'Auto mode cmd-hazard rule' {
    It 'stays Plain when wrapped and the payload has no cmd hazard' {
        $out = ConvertTo-OneLiner -Script "Get-Process | Select-Object Name" -Wrap WindowsPowerShell -Mode Auto
        $out | Should -Match '^powershell\.exe -NoProfile -Command'
    }

    It 'chooses Encoded when wrapped and the payload contains a double quote' {
        $out = ConvertTo-OneLiner -Script 'Write-Output "hi there"' -Wrap WindowsPowerShell -Mode Auto
        $out | Should -Match '-EncodedCommand'
    }

    It 'chooses Encoded when wrapped and the payload contains a percent sign' {
        $out = ConvertTo-OneLiner -Script "Write-Output '100%'" -Wrap Pwsh -Mode Auto
        $out | Should -Match '-EncodedCommand'
    }

    It 'chooses Encoded when wrapped and the payload contains an exclamation mark' {
        $out = ConvertTo-OneLiner -Script "Write-Output 'go!'" -Wrap Pwsh -Mode Auto
        $out | Should -Match '-EncodedCommand'
    }

    It 'stays Plain with Wrap None regardless of hazard characters' {
        $out = ConvertTo-OneLiner -Script 'Write-Output "100% !"' -Wrap None -Mode Auto
        $out | Should -BeExactly 'Write-Output "100% !"'
    }
}

Describe 'MaxLength handling' {
    It 'throws and reports both Plain and Encoded lengths when over the limit' {
        $threw = $false
        try {
            ConvertTo-OneLiner -Script '$a = 1; $b = 2; $a + $b' -MaxLength 5
        }
        catch {
            $threw = $true
            $_.Exception.Message | Should -Match 'Plain form'
            $_.Exception.Message | Should -Match 'Encoded form'
            $_.Exception.Message | Should -Match '8191'
        }
        $threw | Should -BeTrue
    }

    It 'returns the result when within the limit' {
        ConvertTo-OneLiner -Script '$a = 1' -MaxLength 1000 | Should -BeExactly '$a = 1'
    }
}
