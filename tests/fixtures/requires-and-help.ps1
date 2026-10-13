#requires -Version 5.1

<#
.SYNOPSIS
    Adds two numbers.
.DESCRIPTION
    A longer description that is comment-based help.
.EXAMPLE
    Use it.
#>

function Add-Two {
    param([int] $A, [int] $B)
    $A + $B
}
Add-Two -A 2 -B 3
