%lang starknet
%builtins range_check
from src.puzzle import Puzzle
@external
func test_15_puzzle{range_check_ptr}() -> ():
    Puzzle.main()
    return ()
end
