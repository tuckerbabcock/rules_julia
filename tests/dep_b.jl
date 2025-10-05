module DepB

using ..DepA

export func_b

func_b(x) = func_a(x) + 1

end

