using Test

include("dep_a.jl")
include("dep_b.jl")
using .DepB: func_b

@testset "Transitive Dependencies" begin
    @test func_b(5) == 11  # (5 * 2) + 1
    @test func_b(0) == 1   # (0 * 2) + 1
end

