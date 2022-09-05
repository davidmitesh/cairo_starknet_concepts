%lang starknet
from src.field_element_felt import FieldElement

@external
func test_felt():
    FieldElement.test_felt()
    return ()
end
