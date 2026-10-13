using namespace System.Text
param(
    [int] $N = 3
)
$sb = [StringBuilder]::new()
1..$N | ForEach-Object { [void]$sb.Append($_) }
$sb.ToString()
