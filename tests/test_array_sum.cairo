%lang starknet

from starkware.cairo.common.alloc import alloc
from src.array_sum import ArraySum

@external
func test_array_sum() -> ():
    # Allocation an array
    let (ptr) = alloc()

    # populating values in the array
    assert [ptr] = 9
    assert [ptr + 1] = 10
    assert [ptr + 2] = 11

    const size = 3
    let (sum) = ArraySum.array_sum(ptr, size)
    assert sum = 30
    return ()
end
