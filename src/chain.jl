abstract type AbstractChainLink end

struct ChainLink{F}<:AbstractChainLink f::F end
(f::ChainLink)(it) = f.f(it)
(f::ChainLink)(it::AbstractChainLink) = f.f ∘ it
(f::ChainLink)(args...) = f.f(args)
(f::ChainLink)(; kwargs...) = f.f(kwargs) # do we want this? 🤔
Base.show(io::IO, f::ChainLink) = show(io, f.f)

struct ComposedChainLink{F}<:AbstractChainLink f::F end
ComposedChainLink(f, g::AbstractChainLink) = ComposedChainLink(ComposedFunction(f, g))
Base.:∘(f, g::AbstractChainLink) = ComposedChainLink(f, g)
(f::ComposedChainLink)(it) = f.f(it)
(f::ComposedChainLink)(it::AbstractChainLink) = f.f ∘ it
(f::ComposedChainLink)(args...) = f.f(args)
(f::ComposedChainLink)(; kwargs...) = f.f(kwargs)
Base.show(io::IO, f::ComposedChainLink) = show(io, f.f)

# notes:
# underscore splatting functions properly only on args, not kwargs

# chain and chainlink macros
macro chain(x, fns, broadcast=false) # normal chain
    fns isa Symbol && return esc(:($fns($x)))
    if fns isa Expr && fns.head ≠ :block
        fns = :(($fns;))
    end
    out = :(let it=$x; end)
    for ex ∈ _subchain(fns.args, broadcast)
        push!(out.args[2].args, ex)
    end
    esc(out)
end

macro chainlink(fns, broadcast=false) # headless chainlink
    fns isa Symbol && return esc(:(ChainLink($fns)))
    if fns isa Expr && fns.head ≠ :block
        fns = :(($fns;))
    end
    out = :(it -> ())
    for ex ∈ _subchain(fns.args, broadcast) 
        push!(out.args[2].args, ex)
    end
    out = esc(:(ChainLink($out)))
end

function _subchain(fns, broadcast=false) # construct array of :(it=xyz) expressions
    out = [];
    for ex ∈ fns
        ex isa LineNumberNode && continue
        if _has_it(ex) # an expression of "it" (that isn't contained in a nested chainlink)
            push!(out, broadcast ? :((it -> $ex).(it)) : ex)
        elseif ex isa Symbol # a named function that takes one argument
            push!(out, broadcast ? :($ex.(it)) : :($ex(it)))
        elseif ex.head == :call && (:(_...) ∈ ex.args[2:end] || count(==(:_), ex.args[2:end]) ≥ 2) # splatting PAS
            unfixed = filter(x->x==:_ || x==:(_...), ex.args)
            @assert findfirst(==(:(_...)), unfixed) == findlast(==(:(_...)), unfixed) "dafuk only one _... splat pls kthxbye"
            splatindex = findfirst(==(:(_...)), unfixed)
            if isnothing(splatindex) splatindex = length(unfixed) + 1 end
            remainder = length(unfixed) - splatindex

            newex = Expr(:call, ex.args[1])
            iunfix = 1

            for arg ∈ ex.args[2:end]
                if arg == :(_...)
                    push!(newex.args, :(it[begin+$(iunfix-1):end-$remainder]...))
                    iunfix += 1
                elseif arg == :_
                    iunfix < splatindex && push!(newex.args, :(it[begin+$(iunfix-1)]))
                    iunfix > splatindex && push!(newex.args, :(it[end-$(length(unfixed)-iunfix)]))
                    iunfix += 1
                else
                    push!(newex.args, arg)
                end
            end
            push!(out, broadcast ? Expr(:., newex.args[1], Expr(:tuple, newex.args[2:end]...)) : newex)
        elseif ex.head == :call && :_ ∈ ex.args[2:end] # non-splatting PES
            newex = Expr(:call, ex.args[1], replace(ex.args[2:end], :_ => :it)...)
            push!(out, broadcast ? Expr(:., newex.args[1], Expr(:tuple, newex.args[2:end]...)) : newex)
        elseif _is_broadcast(ex) && :_ ∈ ex.args[2].args # non-splatting broadcasted PES ...NOTE I DON'T IMPLEMENT SPLATTING BROADCASTED PES FOR NOW
            newex = Expr(:., ex.args[1], Expr(:tuple, replace(ex.args[2].args, :_ => :it)...))
            push!(out, newex)
        else # otherwise just call the darn thing and see what happens
            push!(out, broadcast ? Expr(:., ex, Expr(:tuple, :it)) : Expr(:call, ex, :it))
        end
    end
    (:(it=$ex) for ex ∈ out)
end

function _is_broadcast(ex)
    ex.head == :. && ex.args[2] isa Expr && ex.args[2].head == :tuple
end

function _has_it(ex) # true if ex is an expression of "it", and it isn't contained in a nested chainlink
    ex == :it && return true
    ex isa Expr || return false
    # omit local scopes
    ex.args[1] ≠ Symbol("@chain") && ex.args[1] ≠ Symbol("@chainlink") || ex.args[3]==:it || return false
    for arg ∈ ex.args
        arg == :it && return true
    end
    for arg ∈ ex.args
        arg isa Expr && _has_it(arg) && return true
    end
    false
end

"(Buggy) Code to implement @chain and @chainlink macros, which implement infix `--` and prefix `--` call chain syntax respectively."