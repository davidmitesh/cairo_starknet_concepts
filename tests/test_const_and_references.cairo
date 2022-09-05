%lang starknet
from src.const_and_references import References

@external
func test_without_reference() -> ():
    let (res) = References.without_reference()
    # 3^16 + 3
    assert res = 43046724
    return ()
end

@external
func test_with_reference() -> ():
    let (res) = References.with_reference()
    # 3^16 + 3
    assert res = 43046724
    return ()
end
