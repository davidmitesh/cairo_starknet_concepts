%lang starknet
%builtins range_check
from src.hints import Hints
from starkware.cairo.common.registers import get_fp_and_pc
@external
func test_basic_format() -> ():
    Hints.basic_format()
    return ()
end

@external
func test_get_value_by_key_function{range_check_ptr}():
    alloc_locals
    local list : (
        Hints.KeyValue, Hints.KeyValue, Hints.KeyValue
    ) = (
        Hints.KeyValue(1, 10), Hints.KeyValue(2, 20), Hints.KeyValue(3, 30)
        )
    let (__fp__, _) = get_fp_and_pc()  # this is required because we have used &list in the below statement
    let (value) = Hints.get_value_by_key(list=cast(&list, Hints.KeyValue*), size=3, key=2)
    %{ print(ids.value) %}
    assert value = 20
    return ()
end
