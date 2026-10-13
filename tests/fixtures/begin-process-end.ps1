function Test-It {
    begin { $acc = 0 }
    process { $acc += 1 }
    end { $acc }
}
1..3 | Test-It
