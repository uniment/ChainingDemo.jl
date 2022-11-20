
∧(a::Bool,b::Bool) = a && b # non-short-circuiting and (\wedge)
∨(a::Bool,b::Bool) = a || b # non-short-circuiting or (\vee)
¬(a::Bool) = !(a) # negation (\neg)

# because apparently (f::Function)(a, b) = begin ... end doesn't work lol who woulda guessed
function fixit(fun, arg, nargs)
    argnames = ((gensym() for i=1:nargs)...,)
    i=arg
    expr = :($fun($(argnames[1:i-1]...), ($(argnames[i])::Union{AbstractFix, AbstractChainLink}),$(argnames[i+1:nargs]...)) = Fix{($((1:i-1)...,(i+1:nargs)...)),$nargs}($fun, $(argnames[1:i-1]...),$(argnames[i+1:nargs]...)) ∘ $(argnames[i]) )
    eval(expr)
end
function fixitall(fun, nargs)
    for i = 1:nargs
        fixit(fun, i, nargs)
    end
end
whitelist = [ #func, nargs
    (:(Base.sin), 1),
    (:(Base.asin), 1),
    (:(Base.cos), 1),
    (:(Base.acos), 1),
    (:(Base.tan), 1),
    (:(Base.atan), 1),
    (:(Base.atan), 2),
    (:(Base.exp), 1),
    (:(Base.log), 1),
    (:(Base.log10), 1),
    (:(Base.sqrt), 1),
    (:(Base.abs), 1),
    (:(Base.abs2), 1),
    (:(Base.sum), 1),
    (:(∨), 2),
    (:(∧), 2),
    (:(¬), 1),
    (:(Base.:+), 2),
    (:(Base.:-), 2),
    (:(Base.:*), 2),
    (:(Base.:/), 2),
    (:(Base.://), 2),
    (:(Base.:\), 2),
    (:(Base.:^), 2),
    (:(Base.:%), 2),
    (:(Base.:>), 2),
    (:(Base.:<), 2),
    (:(Base.:≤), 2),
    (:(Base.:≥), 2),
    (:(Base.in), 2),
    (:(Base.iseven), 1),
    (:(Base.isodd), 1),
    (:(Base.ifelse), 3),
    (:(Base.:(==)), 2),
    (:(Base.:!), 1),
    (:(Base.getindex), 2)
]
for (name,nargs) ∈ whitelist
    fixitall(name, nargs)
end

"Makes a whitelist of functions compose with callable `Fix` and `ChainLink` types"