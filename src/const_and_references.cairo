# References - It may be difficult to follow the progress of the ap register. So, to create a reference to that, we may use 'let' keyword in cairo

# For example:

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
