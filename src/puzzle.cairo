#
# About
#

# The 15-puzzle is a well-known game in which you are given a frame of 4x4
# tiles where one of the tiles is missing, and the other are numbered 1-15.
# You have to slide tiles into the “hole” until you reach the “solved” configuration,
# in which the numbers are ordered.

#
# Goal
#

# write a Cairo program verifying a solution to the 15-puzzle
# (the initial state will be an input) thus allowing you to prove that you know
# the solution to that initial state (without necessarily revealing the solution
# to the person verifying the proof!

# The solution will be represented in form of two lists.
# First will the list of tile positions where the empty tile is fixed as we move states for our solution.
# second list will the number(1-15) that was actually moved.

# [(0, 2), (1, 2), (1, 3), (2, 3), (3, 3)]
#   [3, 7, 8, 12]

# %lang starknet
%builtins range_check
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.alloc import alloc
# namespace Puzzle:
struct Location:
    member row : felt
    member col : felt
end

#
# 1. The locations in the first list make sense – all the numbers are between 0 and 3, and each consecutive pair represent adjacent locations.

func verify_valid_location(loc : Location*):
    # Check that row is in the range 0-3.
    tempvar row = loc.row
    assert row * (row - 1) * (row - 2) * (row - 3) = 0

    # Check that col is in the range 0-3.
    tempvar col = loc.col
    assert col * (col - 1) * (col - 2) * (col - 3) = 0

    return ()
end

func verify_adjacent_locations(loc0 : Location*, loc1 : Location*):
    alloc_locals
    local row_diff = loc0.row - loc1.row
    local col_diff = loc0.col - loc1.col

    if row_diff == 0:
        # The row coordinate is the same. Make sure the difference
        # in col is 1 or -1.
        assert col_diff * col_diff = 1
        return ()
    else:
        # Verify the difference in row is 1 or -1.
        assert row_diff * row_diff = 1
        # Verify that the col coordinate is the same.
        assert col_diff = 0
        return ()
    end
end

# Verifying the list of locations

func verify_location_list(loc_list : Location*, n_steps):
    # Always verify that the location is valid, even if
    # n_steps = 0 (remember that there is always one more
    # location than steps).
    verify_valid_location(loc=loc_list)

    if n_steps == 0:
        return ()
    end

    verify_adjacent_locations(loc0=loc_list, loc1=loc_list + Location.SIZE)

    # Call verify_location_list recursively.
    verify_location_list(loc_list=loc_list + Location.SIZE, n_steps=n_steps - 1)
    return ()
end

# Building the dict to supply to squash_dict

func build_dict(loc_list : Location*, tile_list : felt*, n_steps, dict : DictAccess*) -> (
    dict : DictAccess*
):
    if n_steps == 0:
        return (dict=dict)
    end

    # Set the key of the dict to current tile being moved
    assert dict.key = [tile_list]

    # The previous location of current tile  would be the location
    # where the empty tile will move
    let next_loc : Location* = loc_list + Location.SIZE
    assert dict.prev_value = 4 * next_loc.row + next_loc.col

    # The next location should be the current location of the empty tile
    assert dict.new_value = 4 * loc_list.row + loc_list.col

    # calling the build_dict recursively
    return build_dict(
        loc_list=next_loc, tile_list=tile_list + 1, n_steps=n_steps - 1, dict=dict + DictAccess.SIZE
    )
end

# To make sure that the solution ends in the “solved” configuration,
# we will append 15 entries to the list of DictAccess entries created by
# build_dict().

func finalize_state(dict : DictAccess*, idx) -> (dict : DictAccess*):
    if idx == 0:
        return (dict=dict)
    end

    assert dict.key = idx
    assert dict.prev_value = idx - 1
    assert dict.new_value = idx - 1

    # call the finalize_state recursively
    return finalize_state(dict=dict + DictAccess.SIZE, idx=idx - 1)
end

# printing the initial state so that verifier of the proof may know it
func output_initial_values(squashed_dict : DictAccess*, n):
    if n == 0:
        return ()
    end

    %{ print(ids.squashed_dict.prev_value) %}

    # Call output_initial_values recursively.
    return output_initial_values(squashed_dict=squashed_dict + DictAccess.SIZE, n=n - 1)
end

# putting all the above functions together making a check_solution function
func check_solution{range_check_ptr}(loc_list : Location*, tile_list : felt*, n_steps):
    alloc_locals
    # first start by verifying if the location list is valid
    verify_location_list(loc_list=loc_list, n_steps=n_steps)

    # Now allocation memory for the dict and squashed dict
    let (local dict_start : DictAccess*) = alloc()  # first allocation the memory with reference to fp and then referencing it using let
    let (local squashed_dict : DictAccess*) = alloc()

    let (dict_end : DictAccess*) = build_dict(loc_list, tile_list, n_steps, dict_start)
    let (dict_end) = finalize_state(dict=dict_end, idx=15)  # this is rebinding of the reference

    let (squashed_dict_end : DictAccess*) = squash_dict(
        dict_accesses=dict_start, dict_accesses_end=dict_end, squashed_dict=squashed_dict
    )

    # Verify that the squashed dict has exactly 15 entries.
    # This will guarantee that all the values in the tile list
    # are in the range 1-15.
    assert squashed_dict_end - squashed_dict = 15 *
        DictAccess.SIZE
    return ()
end

# main function

# The way cairo differs from other conventional style programming, is the way inputs is passed and the
# prover and verifier see the program from their end

# Prover only discloses the initial state and the program, making the program complete and the verifier can check the soundness of the program.
# For this purpose, hints plays an important role in the cairo
# Instead of passing the hardcoded solution like the one below, we opt another the next one.

# func main{range_check_ptr}():
#     alloc_locals

# local loc_tuple : (
#         Location, Location, Location, Location, Location
#     ) = (
#         Location(row=0, col=2),
#         Location(row=1, col=2),
#         Location(row=1, col=3),
#         Location(row=2, col=3),
#         Location(row=3, col=3),
#         )

# local tiles : (felt, felt, felt, felt) = (3, 7, 8, 12)

# # Get the value of the frame pointer register (fp) so that
#     # we can use the address of loc_tuple(&loc_tuple)
#     let (__fp__, _) = get_fp_and_pc()
#     # Since the tuple elements are next to each other we can use the
#     # address of loc_tuple as a pointer to the 5 locations.

# # The casting is done because verify_location_list function expects loc_list
#     # to be Location* but is a tuple*, so we need casting for this. And same is the case for tile_list
#     check_solution(
#         loc_list=cast(&loc_tuple, Location*), tile_list=cast(&tiles, felt*), n_steps=4
#     )

# return ()
# end

func main{range_check_ptr}():
    alloc_locals
    # Declare two variables that will point to the two lists and
    # another variable that will contain the number of steps.

    # This is basically the solution that the prover will be passing in, but not known by the verifier, but still can check the soundness of the program
    local loc_list : Location*
    local tile_list : felt*
    local n_steps

    %{
            #The verifier doesnot care where those lists are allocated or what values they contain,
            #so, we use hint to populate them.

            # The verifier doesn't care where those lists are
        # allocated or what values they contain, so we use a hint
        # to populate them.
        locations = program_input['loc_list']
        tiles = program_input['tile_list']

        ids.loc_list = loc_list = segments.add()
        for i, val in enumerate(locations):
            memory[loc_list + i] = val

        ids.tile_list = tile_list = segments.add()
        for i, val in enumerate(tiles):
            memory[tile_list + i] = val

        ids.n_steps = len(tiles)

        # Sanity check (only the prover runs this check).
        assert len(locations) == 2 * (len(tiles) + 1)
    %}
    check_solution(loc_list=loc_list, tile_list=tile_list, n_steps=n_steps)
    return ()
end
# end
