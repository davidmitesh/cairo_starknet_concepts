%lang starknet
# Beautiful use case of recursion
# Computes the sum of the memory elements at addresses:
#   arr + 0, arr + 1, ..., arr + (size - 1).

namespace ArraySum:
    func array_sum(arr : felt*, size : felt) -> (sum : felt):
        if size == 0:
            return (sum=0)
        end

        let (sum_rest) = array_sum(arr + 1, size - 1)
        return (sum=[arr] + sum_rest)
    end
end
