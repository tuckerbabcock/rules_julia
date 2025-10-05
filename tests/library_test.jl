using Test

include("testlib.jl")
using .TestLib: greet, add

@testset "TestLib Tests" begin
    @test greet("World") == "Hello, World!"
    @test add(5, 7) == 12
    @test add(-3, 3) == 0
end

