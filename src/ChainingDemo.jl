module ChainingDemo

include("demo.jl")
include("chain.jl")
include("fix.jl")
include("underscore.jl")
include("whitelist.jl")

export @demo_str, @underscores, @chain, @chainlink, Fix, Fix1, Fix2, FixFirst, FixLast, ChainLink



end # module ChainingDemo
