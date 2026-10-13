# Flatline

Turn any multi-line PowerShell script into a single line that behaves identically. Flatline is
parser-based, keeps its output readable for audit, and ships with a built-in equivalence check so you
can prove the one-liner is the same program as the script you started with.

It exists for the fields that only accept one line: RMM consoles, remote shells, scheduled-task
command boxes. Flattening those by hand breaks on here-strings, nested quotes and `} else` blocks.
Flatline does it from the PowerShell abstract syntax tree, not regular expressions, so the result is
the same program or it is a clear error with a line number — never something that quietly behaves
differently.

## Before and after

Given this script:

```powershell
param(
    [string] $Service = 'Spooler'
)
$svc = Get-Service -Name $Service
if ($svc.Status -eq 'Running') {
    '{0} is up' -f $svc.DisplayName
}
else {
    Start-Service -Name $Service
}
```

`ConvertTo-OneLiner` produces:

```powershell
& { param( [string] $Service = 'Spooler' ) $svc = Get-Service -Name $Service;if ($svc.Status -eq 'Running') { '{0} is up' -f $svc.DisplayName } else { Start-Service -Name $Service } }
```

The `} else` keeps its space instead of gaining a semicolon that would break the script, and the
top-level `param` block is wrapped in `& { ... }` so you can still append arguments. `Test-OneLiner`
confirms the two are the same program:

```powershell
Test-OneLiner -Original $script -OneLiner $oneLiner | Select-Object Equivalent
# Equivalent
# ----------
#       True
```

## Install

From the PowerShell Gallery (once published):

```powershell
Install-Module Flatline -Scope CurrentUser
```

Or clone and import directly:

```powershell
git clone https://github.com/VahagnShekyan/flatline.git
Import-Module ./flatline/src/Flatline/Flatline.psd1
```

Flatline targets Windows PowerShell 5.1 and PowerShell 7 (Desktop and Core editions) and has no runtime
dependencies.

## Usage

```powershell
# From a string
ConvertTo-OneLiner -Script $script

# From a file, straight off the pipeline
Get-Content .\deploy.ps1 -Raw | ConvertTo-OneLiner

# Wrapped for a cmd box, copied to the clipboard
ConvertTo-OneLiner -Path .\deploy.ps1 -Wrap WindowsPowerShell -Clipboard

# Fail if it will not fit a length limit
ConvertTo-OneLiner -Path .\deploy.ps1 -MaxLength 8191
```

`Get-Help ConvertTo-OneLiner -Full` and `Get-Help Test-OneLiner -Full` document every parameter.

## Modes and wrapping

`-Mode` chooses the output form:

- **Plain** — readable PowerShell on one line.
- **Encoded** — the standard `-EncodedCommand` form (Base64 of UTF-16LE).
- **Auto** (default) — Plain unless the Auto rule below forces Encoded.

`-Wrap` chooses how it is presented:

- **None** (default) — bare PowerShell, for a PowerShell prompt.
- **WindowsPowerShell** — a full `powershell.exe -NoProfile ...` invocation, for boxes that run through cmd.
- **Pwsh** — a full `pwsh -NoProfile ...` invocation.

### The Auto rule

Quoting through cmd.exe is where hand-made one-liners fail most. Flatline's Auto mode is deliberate
about it:

> **Auto chooses Encoded when, and only when, `-Wrap` is not `None` and the one-line script contains a
> character that cmd.exe reinterprets inside a double-quoted argument: a double quote `"`, a percent
> sign `%`, or an exclamation mark `!`. In every other case Auto chooses Plain.**

With `-Wrap None` there is no cmd layer, so Auto is always Plain. Inside a cmd double-quoted argument the
characters `| & < > ( ) ^` are literal and safe; `"`, `%` and `!` are not, so their presence is what
tips Auto to the Encoded form. Encoded output is roughly 2.7 times longer than Plain and cannot rescue a
length problem, so Flatline reaches for it only when correctness through cmd requires it.

## Length limits

`-MaxLength` errors if the result is longer than the limit, and reports both the Plain and Encoded
lengths so you can see that Encoded will not help:

```
The one-liner is 9004 characters, over the -MaxLength of 8191. Plain form: 9004 characters;
Encoded form: 24344 characters. Encoded output is roughly 2.7 times longer and cannot rescue a
length limit. The cmd.exe command-line limit is 8191 characters.
```

The cmd.exe command-line limit is **8191** characters.

## What Flatline is not

Flatline is **not an obfuscator**. It does no renaming, no string splitting, no compression, and no
`Invoke-Expression` bootstrap. The output stays readable so it can be audited, and so it does not look
like the living-off-the-land patterns that endpoint-security tools flag.

Note that the `-EncodedCommand` form itself can trigger endpoint-security alerts, because attacker
tooling uses it to hide payloads. Prefer Plain output where cmd quoting allows it, and expect Encoded
one-liners to be noticed by EDR.

## Limitations and unsupported constructs

Flatline fails with a clear error rather than emit a one-liner that might behave differently.

| Construct | What happens |
| --- | --- |
| Input with parse errors | Throws `Flatline cannot convert a script with parse errors:` followed by each error with its line number. |
| An interpolated here-string whose `$( ... )` subexpression spans lines or contains a quote | Throws `Flatline cannot safely flatten an interpolated here-string with a multi-line or quote-bearing subexpression at line N. Rewrite that subexpression on one line first.` |
| `#requires` statements | Dropped (they have no effect on one line); a warning is written. Satisfy the requirement yourself. |
| Comment-based help | Dropped; a warning is written. |

Out of scope for v1, and untested: DSC configurations, workflows, a GUI, and a web playground.

`-Clipboard` is a no-op with a warning on platforms where `Set-Clipboard` is unavailable.

## Verification

`Test-OneLiner` parses both the original and the one-liner, requires zero parse errors from each, then
walks both ASTs in order and compares node types and leaf values — constants, variable names, command
names, member names and parameter names. String nodes are compared by value, so a here-string and its
flattened double-quoted form are treated as equal. A top-level `& { ... }` wrapper is unwrapped first,
so a flattened `param` script still compares equal to its source.

Every fixture in the test suite is also run as a fresh child process in both its original and flattened
form, and the two are required to produce the same standard output, the same exit code, and the same
answer to whether anything was written to standard error — on Windows PowerShell 5.1 and PowerShell 7 on
Windows, and PowerShell 7 on Linux.

## Developing

```powershell
Install-Module Pester -MinimumVersion 5.5 -Scope CurrentUser
Install-Module PSScriptAnalyzer -Scope CurrentUser

Invoke-ScriptAnalyzer -Path ./src -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
Invoke-Pester -Path ./tests
```

The external help file is generated from the Markdown under `docs/` with
[platyPS](https://github.com/PowerShell/platyPS):

```powershell
Install-Module platyPS -Scope CurrentUser
New-ExternalHelp -Path ./docs -OutputPath ./src/Flatline/en-US -Force
```

## License

[MIT](LICENSE)
