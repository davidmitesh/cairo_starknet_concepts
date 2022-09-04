%lang starknet
from src.hints import Hints

@external
func test_basic_format() -> ():
    Hints.basic_format()
    return ()
end
