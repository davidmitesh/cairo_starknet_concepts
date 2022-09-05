%lang starknet
# Beautiful use case of recursion
# Computes the sum of the memory elements at addresses:
#   arr + 0, arr + 1, ..., arr + (size - 1).
%builtins range_check
from starkware.cairo.common.math import unsigned_div_rem
namespace ArrayFelt:
    func array_sum(arr : felt*, size : felt) -> (sum : felt):
        if size == 0:
            return (sum=0)
        end

        let (sum_rest) = array_sum(arr + 1, size - 1)
        return (sum=[arr] + sum_rest)
    end

    func array_even_product{range_check_ptr}(arr : felt*, size : felt) -> (even_product : felt):
        alloc_locals
        if size == 0:
            return (even_product=1)
        end
        let (q, r) = unsigned_div_rem(value=size, div=2)  # q and r refers to the quotient and remainder here
        local element
        if r == 0:
            assert element = [arr]
        else:
            assert element = 1
        end
        let (res) = array_even_product(arr + 1, size - 1)
        return (even_product=element * res)
    end
end
