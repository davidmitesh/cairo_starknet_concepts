%lang starknet

from starkware.cairo.common.alloc import alloc
from src.array_felt import ArrayFelt

@external
func test_array_sum() -> ():
    # Allocation an array
    let (ptr) = alloc()

    # populating values in the array
    assert [ptr] = 9
    assert [ptr + 1] = 10
    assert [ptr + 2] = 11

    const size = 3
    let (sum) = ArrayFelt.array_sum(ptr, size)
    assert sum = 30
    return ()
end

@external
func test_array_even_product{range_check_ptr}() -> ():
    # Allocation an array
    let (ptr) = alloc()

    # populating values in the array
    assert [ptr] = 1
    assert [ptr + 1] = 2
    assert [ptr + 2] = 3
    assert [ptr + 3] = 4
    assert [ptr + 4] = 5
    assert [ptr + 5] = 6

    const size = 6
    let (even_product) = ArrayFelt.array_even_product{range_check_ptr=range_check_ptr}(ptr, size)
    assert even_product = 15
    return ()
end
