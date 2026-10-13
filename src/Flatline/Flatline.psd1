@{
    RootModule           = 'Flatline.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'b3e2c9a4-5d7f-4e1a-9c8b-2f6a1d0e4c33'
    Author               = 'Vahagn Shekyan'
    Copyright            = '(c) 2026 Vahagn Shekyan. All rights reserved.'
    Description          = 'Turn any multi-line PowerShell script into a single line that behaves identically. Parser-based, readable output, with built-in equivalence checks.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport    = @('ConvertTo-OneLiner', 'Test-OneLiner')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('PowerShell', 'OneLiner', 'RMM', 'AST', 'Automation')
            LicenseUri   = 'https://github.com/VahagnShekyan/flatline/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/VahagnShekyan/flatline'
            ReleaseNotes = 'https://github.com/VahagnShekyan/flatline/blob/main/CHANGELOG.md'
        }
    }
}
