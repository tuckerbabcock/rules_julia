"""Simple math library for demonstration."""

module MathLib

export fibonacci, factorial

"""
    fibonacci(n::Integer) -> Integer

Calculate the nth Fibonacci number.
"""
function fibonacci(n::Integer)
    n < 0 && throw(ArgumentError("n must be non-negative"))
    n <= 1 && return n
    
    a, b = 0, 1
    for _ in 2:n
        a, b = b, a + b
    end
    return b
end

"""
    factorial(n::Integer) -> Integer

Calculate n factorial.
"""
function factorial(n::Integer)
    n < 0 && throw(ArgumentError("n must be non-negative"))
    n == 0 && return 1
    return n * factorial(n - 1)
end

end # module

