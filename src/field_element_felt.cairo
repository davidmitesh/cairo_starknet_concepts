%lang starknet

namespace FieldElement:
    func test_felt():
        alloc_locals
        local x = 7 / 3
        local y = 6 / 3
        %{
            assert ids.y == int(2)
            print(ids.x)
            # The value of x = 1206167596222043737899107594365023368541035738443865566657697352045290673496

            #Let's us explain why this happened, instead of something like 2.33
            # Because felt type is integer except that is in range -P/2 to P/2 where P is very large prime number
            # So if the result goes out of that range, it is done modulo P

            #So in this case, it satisfies the case x * 3 = 7
            #Because if x*3 goes out of the range, it will be done modulo P and the result will be 7.

            # assert ids.x * 3 == 7 # This will fail, because modulo P will not happen inside the hint as it is python compiler.
        %}
        assert x * 3 = 7  # Modulo will happen here
        return ()
    end
end
