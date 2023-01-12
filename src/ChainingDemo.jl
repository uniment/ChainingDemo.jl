module ChainingDemo

include("fix.jl")
using .FixedFunctions
include("underscore.jl")
#using .Underscores
include("demo.jl")
include("chain.jl")
#include("whitelist.jl") # sorry, I no longer believe in a composition fallback. Taking this out.


export @demo_str, @underscores, @chain, @chainlink
export AbstractPartialFunction, ComposedPartialFunction, Fix, Fix1_2, Fix2_2, FixFirst, FixLast, ChainLink



end 
