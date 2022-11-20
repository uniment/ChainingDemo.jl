macro underscores(ex)
    esc(_underscore_pas!(ex))
end

function _underscore_pas!(ex, rhschainparent=false)
    if ex isa Expr
        for (i,child) ∈ enumerate(ex.args)
            isrhschain = ex.args[1] ∈ Symbol.(("@chain","@chainlink")) && i > 3 ||
                rhschainparent && ex.head == :tuple # for any expression which CCS was going to syntax transform, let it handle it.
            _underscore_pas!(child, isrhschain)
        end
        if ex.head == :call && (:_ ∈ ex.args[2:end] || :(_...) ∈ ex.args[2:end] || :(&_) == ex.args[end]) && !rhschainparent
            # let's turn this thing into a `Fix` object
            if :(&_) == ex.args[end] # zero-arg functor
                pop!(ex.args)
                pushfirst!(ex.args, :(Fix{$((1:length(ex.args)-1)...,), $(length(ex.args)-1)}))
            else # Fix{fixinds,nargs}(f, fixvals...; fixkwargs...)
                @assert findfirst(==(:(_...)), ex.args) == findlast(==(:(_...)), ex.args) "dafuk only one splat _... pls kthxbye"
                startargs = ex.args[2] isa Expr && ex.args[2].head == :parameters ? 3 : 2
                nargs = :(_...) ∈ ex.args ? 0 : length(ex.args)+1-startargs
                fixinds = Int[]
                arglen = length(ex.args[startargs:end])
                splatindex = findfirst(==(:(_...)), ex.args)
                if isnothing(splatindex)
                    splatindex = arglen + 1
                else
                    splatindex = splatindex - 1
                end
                remainder = arglen - splatindex

                for (i,arg) ∈ enumerate(ex.args[startargs:end])
                    arg == :_ && continue
                    i < splatindex && push!(fixinds, i)
                    i > splatindex && push!(fixinds, -arglen + i - 1)
                end
                pushfirst!(ex.args, :(Fix{$((fixinds)...,), $nargs}))
            end
            ex.args = filter(arg -> arg ≠ :_ && arg ≠ :(_...), ex.args)
            if length(ex.args) > 2 && ex.args[3] isa Expr && ex.args[3].head == :parameters # if there were keyword args, put them back where they belong
                ex.args[2:3] = ex.args[3:-1:2]
            end
        elseif _is_broadcast(ex) && :_ ∈ ex.args[2].args && !rhschainparent # REALLY REALLY HACKY, NON-SPLATTING BROADCASTED FUNCTIONS ONLY BECAUSE I'M LAZY
            fixinds = ((i for (i,v) ∈ enumerate(ex.args[2].args) if v ≠ :_)...,)
            arglen = length(ex.args[2].args)
            fixargs = ((ex.args[2].args[i] for i ∈ fixinds)...,)
            newex = :(Fix{(1,), 2}(broadcast, Fix{($(fixinds...),), $arglen}($(ex.args[1]), $(fixargs...))))
            ex.head = newex.head
            ex.args = newex.args
        elseif ex.head == :. && ex.args[1] == :_
            newex = :(Fix2(getproperty, $(ex.args[2])))
            ex.head, ex.args = newex.head, newex.args
        elseif ex.head == :. && ex.args[2] == :(:_)
            newex = :(Fix1(getproperty, $(ex.args[1])))
            ex.head, ex.args = newex.head, newex.args
        elseif ex.head == :ref && ex.args[1] == :_
            newex = :(Fix2(getindex, $(ex.args[2])))
            ex.head, ex.args = newex.head, newex.args
        elseif ex.head == :ref && ex.args[2] == :_
            newex = :(Fix1(getindex, $(ex.args[1])))
            ex.head, ex.args = newex.head, newex.args
        end
    end
    ex
end

"(Buggy) Code to turn PAS expressions into `Fix` functor objects"