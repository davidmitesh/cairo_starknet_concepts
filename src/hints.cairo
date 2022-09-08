# Hint - A hint is a block of Python code, that will be executed by the prover right before the next instruction.
# Cairo hints can be useful for delegating heavy computation.
# This pattern is at the very heart of Cairo: verification is much faster than computation.
# However, as hints are not part of the final Cairo bytecode, a malicious program may provide wrong results.
# You should always verify computations done inside hints.
from starkware.cairo.common.math import assert_nn_le
namespace Hints:
    func basic_format() -> ():
        [ap] = 25; ap++
        %{
            import math
            memory[ap] = int(math.sqrt(memory[ap-1]))
        %}
        # The hint above is attached to this instruction below and executed before each execution of the corresponding instruction.
        # The hint is not the separate instruction on its own
        [ap - 1] = [ap] * [ap]; ap++  # This way verifier can verify the computation is legit and in very short time
        ret
    end

    # EXERCISE 1 ---------------------------*****************************

    # Taking advantage of the non-determinism of cairo using hints
    # Our problem is to write a function get_value_by_key that accepts
    # a key and returns a value from the list of of N pairs(key,value)
    # combinations passed onto the function

    # If we are gonna approach this problem naively with only cairo
    # code then it will take O(N) operations using recursion

    # But we can utilize hints and the computation will be done there,
    # and that will not be included in the cairo code, so the time is
    # constant time.

    struct KeyValue:
        member key : felt
        member value : felt
    end

    func get_value_by_key{range_check_ptr}(list : KeyValue*, size, key) -> (value):
        alloc_locals
        local idx
        %{
            #Our goal is to populate idx using hint
            STRUCT_SIZE = ids.KeyValue.SIZE
            KEY_OFFSET = ids.KeyValue.key
            for i in range(ids.size):
                addr = ids.list.address_ + STRUCT_SIZE * i + KEY_OFFSET
                if memory[addr] == ids.key:
                    ids.idx = i
                    break
            else:
                raise Exception(f'key{ids.key} was not found in the list.')
        %}

        # Verify that the index calculated from the hint/ or from
        # verifier's point of view, the non-determinism of the ids.x
        # is indeed sound
        let item : KeyValue = list[idx]
        assert item.key = key

        # Verify that the index is in range (0 <= idx <= size - 1).
        assert_nn_le(a=idx, b=size - 1)  # This uses range_check_ptr internally, so we need to

        # Return the corresponding value.
        return (value=item.value)
    end
end
