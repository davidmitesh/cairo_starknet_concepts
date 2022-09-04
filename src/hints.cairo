# Hint - A hint is a block of Python code, that will be executed by the prover right before the next instruction.
# Cairo hints can be useful for delegating heavy computation.
# This pattern is at the very heart of Cairo: verification is much faster than computation.
# However, as hints are not part of the final Cairo bytecode, a malicious program may provide wrong results.
# You should always verify computations done inside hints.

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
end
