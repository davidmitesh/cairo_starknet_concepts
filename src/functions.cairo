# The fp register
# When a function starts the frame pointer(fp) is initialized to the current value of ap.During the entire scope of the function(excluding the inner function calls)
# the value of fp remains constant. The idea behind this is that ap may change randomly when inner function is called which makes it impossible to call the
# local variables of the caller function. So, here fp serves as the anchor to access these values.
