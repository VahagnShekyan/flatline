$h = @{
    Name = 'Flat'
    Age  = 3
    Nested = @{
        A = 1
        B = 2
    }
}
$h.Name
$h.Nested.B
