1..5
| Where-Object { $_ -gt 2 }
| Measure-Object -Sum
| ForEach-Object { $_.Sum }
