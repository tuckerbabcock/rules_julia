using Test

include("mathlib.jl")
using .MathLib: fibonacci, factorial

@testset "MathLib Tests" begin
    @testset "Fibonacci" begin
        @test fibonacci(0) == 0
        @test fibonacci(1) == 1
        @test fibonacci(10) == 55
        @test fibonacci(20) == 6765
        @test_throws ArgumentError fibonacci(-1)
    end
    
    @testset "Factorial" begin
        @test factorial(0) == 1
        @test factorial(1) == 1
        @test factorial(5) == 120
        @test factorial(10) == 3628800
        @test_throws ArgumentError factorial(-1)
    end
end

