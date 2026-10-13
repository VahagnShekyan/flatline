---
external help file: Flatline-help.xml
Module Name: Flatline
online version: https://github.com/VahagnShekyan/flatline/blob/main/docs/ConvertTo-OneLiner.md
schema: 2.0.0
---

<!-- platyPS fixes this layout: upper-case section headings, cmdlet and .NET type names as headings, and
"Example 1: Verb ..." titles. -->
<!-- vale Google.Headings = NO -->
<!-- vale Google.Colons = NO -->
<!-- vale Google.Spacing = NO -->

# ConvertTo-OneLiner

## SYNOPSIS

Turns a multi-line PowerShell script into a single line that behaves identically.

## SYNTAX

### Script (Default)

```
ConvertTo-OneLiner -Script <String> [-Mode <String>] [-Wrap <String>] [-MaxLength <Int32>] [-Clipboard]
 [<CommonParameters>]
```

### Path

```
ConvertTo-OneLiner -Path <String> [-Mode <String>] [-Wrap <String>] [-MaxLength <Int32>] [-Clipboard]
 [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-OneLiner parses the input with the PowerShell language parser. It then rewrites it from the
token stream, guided by the abstract syntax tree, into a single physical line. The result has no carriage
return or line feed. Statement separators are inserted only where two sibling statements meet. A stray
semicolon never breaks constructs such as `} else`, `} catch`, `switch` clauses, and
`begin`/`process`/`end` blocks. Here-strings and multi-line string literals are rewritten as one-line
double-quoted strings with their embedded newlines preserved as backtick escapes.

If the input does not parse, the function stops and reports the parse errors with their line numbers. It
never emits something that might behave differently. A top-level `param` block is wrapped as `& { ... }`
so arguments can still be appended. Dropped `#requires` statements and comment-based help raise warnings
on the warning stream.

Use Test-OneLiner to prove that the result is the same program as the input.

## EXAMPLES

### Example 1: Flatten a script with an if/else block

```powershell
PS > $script = @'
if (Test-Path C:\Temp) {
    'exists'
}
else {
    'missing'
}
'@
PS > ConvertTo-OneLiner -Script $script
if (Test-Path C:\Temp) { 'exists' } else { 'missing' }
```

### Example 2: Flatten a file and wrap it for a cmd box

```powershell
PS > ConvertTo-OneLiner -Path .\deploy.ps1 -Wrap WindowsPowerShell
```

The script is read from disk and wrapped as a full `powershell.exe -NoProfile` invocation. Because Wrap
is not None, Auto mode chooses the Encoded form when the one-liner contains a character cmd.exe would
reinterpret inside double quotes.

### Example 3: Copy an encoded command to the clipboard

```powershell
PS > ConvertTo-OneLiner -Path .\task.ps1 -Wrap Pwsh -Mode Encoded -Clipboard
```

## PARAMETERS

### -Path

Path to a `.ps1` file to read. The file is read as raw text, preserving its line endings.

```yaml
Type: String
Parameter Sets: Path
Aliases:
Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Script

The script text to flatten. Accepts pipeline input.

```yaml
Type: String
Parameter Sets: Script
Aliases:
Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Mode

Output form. Plain is readable PowerShell on one line. Encoded is the standard `-EncodedCommand` form
(Base64 of UTF-16LE). Auto chooses Encoded when Wrap is not None and the one-liner contains a character
that cmd.exe reinterprets inside double quotes. Those characters are a double quote, a percent sign, and
an exclamation mark. Otherwise Auto chooses Plain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Auto, Plain, Encoded
Required: False
Position: Named
Default value: Auto
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wrap

How to present the one-liner. None emits bare PowerShell for a PowerShell prompt. WindowsPowerShell and
Pwsh emit a full `powershell.exe` or `pwsh` invocation with `-NoProfile`, for boxes that run through cmd.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: None, WindowsPowerShell, Pwsh
Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLength

Maximum length of the result. If the result is longer, the function throws and reports both the Plain and
Encoded lengths. Encoded output is roughly 2.7 times longer and cannot rescue a length problem. The
cmd.exe command-line limit is 8191 characters.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:
Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Clipboard

Copies the result to the clipboard. Where Set-Clipboard is not available, a warning is written and the
result is not copied.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

A script passed to -Script, including from the pipeline.

## OUTPUTS

### System.String

A single line with no carriage return or line feed.

## NOTES

Flatline is not an obfuscator. Output stays readable for audit. Note that `-EncodedCommand` itself can
trigger endpoint-security alerts.

## RELATED LINKS

[Test-OneLiner](Test-OneLiner.md)
