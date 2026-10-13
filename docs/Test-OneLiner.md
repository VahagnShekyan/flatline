---
external help file: Flatline-help.xml
Module Name: Flatline
online version: https://github.com/VahagnShekyan/flatline/blob/main/docs/Test-OneLiner.md
schema: 2.0.0
---

# Test-OneLiner

## SYNOPSIS

Checks whether a one-liner is the same program as the original script.

## SYNTAX

```
Test-OneLiner [-Original] <String> [-OneLiner] <String> [<CommonParameters>]
```

## DESCRIPTION

Test-OneLiner parses both inputs with the PowerShell language parser and requires zero parse errors from
each. It then walks both abstract syntax trees in order and compares node types and leaf values: constant
values, variable names, command names, member names and parameter names. String nodes are compared by
value, so a here-string and its flattened double-quoted form are treated as equivalent. A top-level
`& { ... }` wrapper is unwrapped before comparison, so a flattened `param` script still compares equal to
its source.

The result reports whether the two are Equivalent, any ParseErrors found, and the FirstDifference when
they diverge.

## EXAMPLES

### Example 1: Verify a conversion

```powershell
PS > $one = ConvertTo-OneLiner -Script $script
PS > Test-OneLiner -Original $script -OneLiner $one

Equivalent ParseErrors FirstDifference
---------- ----------- ---------------
      True {}
```

### Example 2: Catch a difference

```powershell
PS > (Test-OneLiner -Original '1 + 2' -OneLiner '1 + 3').Equivalent
False
```

## PARAMETERS

### -Original

The original, usually multi-line, script.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OneLiner

The one-liner to compare against the original.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSCustomObject

An object with Equivalent, ParseErrors and FirstDifference.

## NOTES

Equivalence is structural, not textual. Whitespace, comments and the physical form of strings do not
affect the result; a changed constant, name or node type does.

## RELATED LINKS

[ConvertTo-OneLiner](ConvertTo-OneLiner.md)
