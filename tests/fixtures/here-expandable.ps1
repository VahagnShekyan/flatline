$x = 42
$s = @"
value is $x
quote " here
sum $(1 + 2)
backtick `t stays
"@
$s
