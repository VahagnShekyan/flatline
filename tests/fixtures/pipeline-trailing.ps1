1..5 |
    Where-Object { $_ -gt 2 } |
    ForEach-Object { $_ * 10 }
