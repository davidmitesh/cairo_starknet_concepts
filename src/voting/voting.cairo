%lang starknet
from starkware.cairo.common.alloc import alloc
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
