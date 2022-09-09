%builtins output pedersen range_check ecdsa
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.dict import DictAccess, dict_new, dict_update, dict_squash
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.small_merkle_tree import small_merkle_tree_update

# The identifier that represents what we're voting for.
# This will appear in the user's signature to distinguish
# between different polls.
const POLL_ID = 10018
struct VoteInfo:
    # The ID of the voter.
    member voter_id : felt
    # The voter's public key.
    member pub_key : felt
    # The vote (0 or 1).
    member vote : felt
    # The ECDSA signature (r and s).
    member r : felt
    member s : felt
end

# A function to verify if the signature is indeed signed by the public_key

func verify_vote_signature{pedersen_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*}(
    vote_info_ptr : VoteInfo*
):
    let (message) = hash2{hash_ptr=pedersen_ptr}(x=POLL_ID, y=vote_info_ptr.vote)  # even though the pedersen_ptr as implicit argument to the function
    # we still need to pass it explicitly to the hash2 function, because hash2 expects implicit_argument with name hash_ptr.

    # But in case of verify_ecdsa_signature, we dont need to pass explicitly the ecdsa_ptr, it also same argument name as implicit argument.
    verify_ecdsa_signature(
        message=message,
        public_key=vote_info_ptr.pub_key,
        signature_r=vote_info_ptr.r,
        signature_s=vote_info_ptr.s,
    )
    return ()
end

# Returns the list of VoteInfo Instances representing the claimed votes

func get_claimed_votes() -> (votes : VoteInfo*, n : felt):
    alloc_locals
    local n
    let (votes : VoteInfo*) = alloc()
    %{
        ids.n = len(program_input['votes'])
        public_keys = [
            int(pub_key,16) for pub_key in program_input['public_keys']
        ]
        for i,vote in enumerate(program_input['votes']):
            base_address = ids.votes.address_ + i* ids.VoteInfo.SIZE
            memory[base_address+ids.VoteInfo.voter_id] = vote['voter_id']
            memory[base_address+ids.VoteInfo.pub_key] = public_keys[vote['voter_id']]
            memory[base_address+ids.VoteInfo.vote] = vote['vote']
            memory[base_address+ids.VoteInfo.r] = int(vote['r'],16)
            memory[base_address+ids.VoteInfo.s] = int(vote['s'],16)
    %}
    return (votes=votes, n=n)
end

# An important feature of this voting contract will be that it allows splitting the voting process to batches, where each batch can be processed in a separate cairo run
# this way we can support large and ongoing polls.) This means we need to separate the voters who already casted their votes and who havenot, and what the
# results of the election been so far

# We will use a merkle tree to store the information about the public keys that are allowed to vote.
# Our Merkle tree will contain all the voters’ public keys (padded with zeros) that haven’t voted yet.
# When someone votes, we replace their public key with 0 in the Merkle tree. Thus we guarantee that no one can vote more than once

const LOG_N_VOTERS = 10  # maximum number of voters confined to 2^10 = 1024

struct VotingState:
    member number_yes_votes : felt
    member number_no_votes : felt
    member public_key_tree_start : DictAccess*
    member public_key_tree_end : DictAccess*
end

func init_voting_state() -> (state : VotingState):
    alloc_locals
    local state : VotingState
    assert state.number_yes_votes = 0
    assert state.number_no_votes = 0
    %{
        public_keys = [int(pub_key, 16) for pub_key in program_input['public_keys']]
        initial_dict = dict(enumerate(public_keys))
    %}
    # dict_new() expects to get a get a hint variable called initial_dict with the initial values of the dictionary
    let (dict : DictAccess*) = dict_new()
    assert state.public_key_tree_start = dict
    assert state.public_key_tree_end = dict
    return (state=state)
end
# The following function verifies that the vote is signed and removes the public key from the tree.
func process_vote{pedersen_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*, state : VotingState}(
    vote_info_ptr : VoteInfo*
):
    alloc_locals

    assert_not_zero(vote_info_ptr.pub_key)
    verify_vote_signature(vote_info_ptr=vote_info_ptr)

    # update the public key dict
    let public_key_tree_end = state.public_key_tree_end

    # notice that as public_key_tree_end is passed as the dic_ptr as implicit argument, so the updated one will be returned as well
    dict_update{dict_ptr=public_key_tree_end}(
        key=vote_info_ptr.voter_id, prev_value=vote_info_ptr.pub_key, new_value=0
    )

    # Generating new state
    local new_state : VotingState
    assert new_state.public_key_tree_end = public_key_tree_end
    assert new_state.public_key_tree_start = state.public_key_tree_start

    # Update the counters.
    tempvar vote = vote_info_ptr.vote
    if vote == 0:
        # Vote "No".
        assert new_state.number_yes_votes = state.number_yes_votes
        assert new_state.number_no_votes = state.number_no_votes + 1
    else:
        # Make sure that in this case vote=1.
        assert vote = 1

        # Vote "Yes".
        assert new_state.number_yes_votes = state.number_yes_votes + 1
        assert new_state.number_no_votes = state.number_no_votes
    end

    # updating the state
    let state = new_state
    return ()  # notice that it will automically return the new_state because we have rebinded state to new_state and state was passed as an implicit argument
end

func process_votes{pedersen_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*, state : VotingState}(
    votes : VoteInfo*, n_votes : felt
):
    alloc_locals
    if n_votes == 0:
        return ()
    end

    process_vote(vote_info_ptr=votes)
    local state : VotingState = state
    process_votes(votes=votes + VoteInfo.SIZE, n_votes=n_votes - 1)
    return ()
end

# As explained above, the program will output 4 values that summarize the batch: the number of “yes” and
# “no” votes and the Merkle root before and after processing the votes of that batch

struct BatchOutput:
    member n_yes_votes : felt
    member n_no_votes : felt
    member public_keys_root_before : felt
    member public_keys_root_after : felt
end

# Now the only part missing is the calculation of the roots of the public_keys.
# In order to do this, we first squash the dict and then call the standard library function small_merkle_tree_update()
# (a requirement of small_merkle_tree_update() is that we use the high-level function dict_squash() rather than squash_dict().
# dict_squash() passes hint information about all of the dict entries to the squashed dict, including entries that haven’t changed.

func main{
    output_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*
}():
    alloc_locals
    let output = cast(output_ptr, BatchOutput*)  # This cast is done to display the output in the form of the BatchOutput format
    let output_ptr = output_ptr + BatchOutput.SIZE  # This is done because the output_ptr is passed as the implicit argument which means it should be returned
    # so, the space allocation is done so the batch output can be printed and then it is returned

    let (votes, n_votes) = get_claimed_votes()
    let (state) = init_voting_state()
    process_votes{state=state}(votes=votes, n_votes=n_votes)

    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local ecdsa_ptr : SignatureBuiltin* = ecdsa_ptr

    # Write the "yes" and "no" counts to the output.
    assert output.n_yes_votes = state.number_yes_votes
    assert output.n_no_votes = state.number_no_votes

    # squash the dict

    let (squashed_dict_start, squashed_dict_end) = dict_squash(
        dict_accesses_start=state.public_key_tree_start, dict_accesses_end=state.public_key_tree_end
    )
    local range_check_ptr = range_check_ptr

    # computing the two merkle roots

    let (root_before, root_after) = small_merkle_tree_update{hash_ptr=pedersen_ptr}(
        squashed_dict_start=squashed_dict_start,
        squashed_dict_end=squashed_dict_end,
        height=LOG_N_VOTERS,
    )

    # Writing the merkle roots to the output
    assert output.public_keys_root_after = root_after
    assert output.public_keys_root_before = root_before

    return ()
end
