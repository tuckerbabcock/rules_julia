#!/usr/bin/env julia

include("mathlib.jl")
using .MathLib: fibonacci, factorial

println("MathLib Calculator Demo")
println("=" ^ 40)

# Fibonacci
println("\nFibonacci numbers:")
for i in 0:10
    println("  F($i) = $(fibonacci(i))")
end

# Factorials
println("\nFactorials:")
for i in 0:10
    println("  $(i)! = $(factorial(i))")
end

