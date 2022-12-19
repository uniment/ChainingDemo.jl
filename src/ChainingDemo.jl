module ChainingDemo

include("demo.jl")
include("chain.jl")
include("fix.jl")
using .FixedFunctions
include("underscore.jl")
include("whitelist.jl")


export @demo_str, @underscores, @chain, @chainlink
export AbstractFunction, AbstractPartialFunction, ComposedPartialFunction, Fix, Fix1_2, Fix2_2, FixFirst, FixLast, ChainLink, ∨, ∧, ¬



end # module ChainingDemo
