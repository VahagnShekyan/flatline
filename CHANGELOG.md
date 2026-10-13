# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-13

### Added
- `ConvertTo-OneLiner`: flattens a multi-line PowerShell script to a single line from the AST and token
  stream, never regular expressions. Inserts statement separators only between sibling statements, so
  `} else`, `} catch`, `} finally`, switch clauses and `begin`/`process`/`end` blocks are preserved.
  Rewrites here-strings and multi-line string literals as one-line double-quoted strings with embedded
  newlines preserved as backtick escapes. Wraps a top-level `param` block as `& { ... }`. Keeps `using`
  statements first. Warns on dropped `#requires` and comment-based help. Refuses, with a line number,
  input that does not parse or an interpolated here-string with a multi-line or quote-bearing
  subexpression.
- `ConvertTo-OneLiner` parameters: `-Path`/`-Script` (pipeline), `-Mode Auto|Plain|Encoded`,
  `-Wrap None|WindowsPowerShell|Pwsh`, `-MaxLength`, `-Clipboard`.
- Auto mode cmd-hazard rule: chooses Encoded only when wrapped and the payload contains `"`, `%` or `!`.
- `-MaxLength` error reports both Plain and Encoded lengths and the 8191-character cmd.exe limit.
- `Test-OneLiner`: parses both inputs, requires zero parse errors, walks both ASTs in order and compares
  node types and leaf values; compares strings by value; unwraps a `& { ... }` wrapper before comparing.
  Returns `Equivalent`, `ParseErrors` and `FirstDifference`.
- External help for both functions, generated from Markdown under `docs/`.
- 20 hazard fixtures with structural and behavioural tests on Windows PowerShell 5.1 and PowerShell 7
  (Windows and Linux).
- CI matrix and a PSScriptAnalyzer lint gate.

[0.1.0]: https://github.com/VahagnShekyan/flatline/releases/tag/v0.1.0
