#!/usr/bin/env julia

include("testlib.jl")
using .TestLib: greet, add

println(greet("Bazel"))
println("2 + 3 = ", add(2, 3))

