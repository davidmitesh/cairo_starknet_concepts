# References - It may be difficult to follow the progress of the ap register. So, to create a reference to that, we may use 'let' keyword in cairo
# References using let - It is defined uisng the let statement
# For example:
# let x = y * y * y
# You should think of x as an alias to the expression y * y * y,
# which means that the instruction let x = y * y * y by itself will not cause
# any computation to be performed. On the other hand, a later instruction
# such as assert x * x = 1 will turn into assert (y * y * y) * (y * y * y) = 1.

namespace References:
    func without_reference() -> (res : felt):
        # Set value of x.
        [ap] = 3; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++

        [ap] = [ap - 1] + [ap - 5]; ap++
        return (res=[ap - 1])
    end

    func with_reference() -> (res : felt):
        # Set value of x.
        let x = [ap]
        [ap] = 3; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++
        [ap] = [ap - 1] * [ap - 1]; ap++

        [ap] = [ap - 1] + x; ap++  # we can directly reference to x here instead of keeping tract of ap as [ap-5] which makes it easier to code
        return (res=[ap - 1])
    end
end
