enum Color {
    Red
    Green
    Blue
}
class Point {
    [int] $X
    [int] $Y
    [string] Show() {
        return "$($this.X),$($this.Y)"
    }
}
$p = [Point]::new()
$p.X = 3
$p.Y = 4
$p.Show()
[int][Color]::Green
