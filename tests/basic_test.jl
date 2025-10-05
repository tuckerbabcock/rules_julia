using Test

@testset "Basic Tests" begin
    @test 1 + 1 == 2
    @test 2 * 3 == 6
    @test "hello" * " world" == "hello world"
end

