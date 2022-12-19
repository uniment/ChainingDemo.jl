#module Underscores
#export @underscores

macro underscores(ex)
    esc(_underscore_pas!(ex))
end

function _underscore_pas!(ex, rhschainparent=false)
    if !(ex isa Expr)  return ex  end
    #for (i,child) ∈ enumerate(ex.args)
    #    isrhschain = (ex.args[1] == Symbol("@chain") && i > 3) || (ex.args[1] == Symbol("@chainlink")) ||
    #        rhschainparent && ex.head == :block # for any expression which CCS was going to syntax transform, let it handle it.
    #    _underscore_pas!(child, isrhschain)
    #end
    if ex.head == :call && (:_ ∈ ex.args[2:end] || :(_...) ∈ ex.args[2:end] || :(&_) == ex.args[end]) && !rhschainparent
        # let's turn this thing into a `Fix` object
        if :(&_) == ex.args[end] # zero-arg functor
            pop!(ex.args) # drop `&_` from argument list
            pushfirst!(ex.args, :(Fix{$((1:length(ex.args)-1)...,), $(length(ex.args)-1)}))
        else # Fix{fixinds,nargs}(f, fixvals...; fixkwargs...)
            @assert findfirst(==(:(_...)), ex.args) == findlast(==(:(_...)), ex.args) "dafuk only one splat _... pls kthxbye"
            params = if length(ex.args) > 2 && ex.args[2] isa Expr && ex.args[2].head == :parameters
                f=popfirst!(ex.args)
                p=popfirst!(ex.args)
                pushfirst!(ex.args, f)
                p
            else  nothing  end
            startargs = ex.args[2] isa Expr && ex.args[2].head == :parameters ? 3 : 2
            nargs = :(_...) ∈ ex.args ? -1 : length(ex.args)+1-startargs
            fixinds = Int[]
            arglen = length(ex.args[startargs:end])
            splatindex = findfirst(==(:(_...)), ex.args)
            if isnothing(splatindex)  splatindex = arglen + 1
            else  splatindex = splatindex - 1
            end

            for (i,arg) ∈ enumerate(ex.args[startargs:end])
                arg == :_ && continue
                i < splatindex && push!(fixinds, i)
                i > splatindex && push!(fixinds, -arglen + i - 1)
            end
            !isnothing(params) && pushfirst!(ex.args, params)
            pushfirst!(ex.args, :(Fix{$((fixinds)...,), $nargs}))
        end
        ex.args = filter(arg -> arg ≠ :_ && arg ≠ :(_...), ex.args)
    elseif ex.head == :. && ex.args[2] isa Expr && ex.args[2].head == :tuple && :_ ∈ ex.args[2].args && !rhschainparent # Broadcasting partial functions!
        newex = Expr(:call, ex.args[1], ex.args[2].args...)
        ex.head = :call
        ex.args = [:(Fix{(1,), 2}), :broadcast, _underscore_pas!(newex)]
    elseif ex.head == :. && ex.args[1] == :_ # _.prop
        newex = :(Fix2(getproperty, $(ex.args[2])))
        ex.head, ex.args = newex.head, newex.args
    elseif ex.head == :. && ex.args[2] == :(:_) # obj._
        newex = :(Fix1(getproperty, $(ex.args[1])))
        ex.head, ex.args = newex.head, newex.args
    elseif ex.head == :ref && ex.args[1] == :_ # _[ind]
        newex = :(Fix2(getindex, $(ex.args[2])))
        ex.head, ex.args = newex.head, newex.args
    elseif ex.head == :ref && ex.args[2] == :_ # d[_]
        newex = :(Fix1(getindex, $(ex.args[1])))
        ex.head, ex.args = newex.head, newex.args
    end
    ex isa Expr && map(_underscore_pas!, ex.args)
    ex
end

#end