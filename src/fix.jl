abstract type AbstractFix end
    
struct ComposedFix{T}<:AbstractFix f::T end
ComposedFix(f, g::AbstractFix) = ComposedFix(ComposedFunction(f, g))
Base.:∘(f, g::AbstractFix) = ComposedFix(f, g)
(f::ComposedFix)(args...; kwargs...) = f.f(args...; kwargs...)
Base.show(io::IO, f::ComposedFix) = show(io, f.f)

struct Fix{F,fixinds,nargs,V<:Tuple,KW<:NamedTuple}<:AbstractFix
    f::F
    fixvals::V
    fixkwargs::KW

    Fix{F,fixinds,nargs,V,KW}(f::F,fixvals,fixkwargs) where {F,fixinds,nargs,V,KW} = begin
        nargs > 0 && @assert all(map(>(0), fixinds)) "fixed number of arguments requires left-aligned arguments (positive indices)"
        nargs > 0 && length(fixinds) > 0 && @assert nargs ≥ max(fixinds...) "number of arguments must be at least largest argument index"
        @assert length(fixinds) == length(fixvals) "length of fixed args and fixed indices must match"
        orderok(a, b) = a < b || (a > 0 && b < 0)  # not a perfect test ... just want args ordered left to right
        length(fixinds) > 1 && @assert all(orderok(a,b) for (a,b) ∈ zip(fixinds, Iterators.drop(fixinds,1))) "argument indices must be in left-to-right order"
        new{F,map(Int,fixinds),Int(nargs),V,KW}(f,fixvals,fixkwargs)
    end
    # specializations for common simple cases: this doesn't improve speed, but it reduces compile-time memory usage
    Fix{F,(1,),2,V,KW}(f::F,fixvals::Tuple{<:Any},fixkwargs) where {F,V,KW} = new{F,(1,),2,V,KW}(f,fixvals,fixkwargs)
    Fix{F,(2,),2,V,KW}(f::F,fixvals::Tuple{<:Any},fixkwargs) where {F,V,KW} = new{F,(2,),2,V,KW}(f,fixvals,fixkwargs)
    Fix{F,(1,),0,V,KW}(f::F,fixvals::Tuple{<:Any},fixkwargs) where {F,V,KW} = new{F,(1,),0,V,KW}(f,fixvals,fixkwargs)
    Fix{F,(-1,),0,V,KW}(f::F,fixvals::Tuple{<:Any},fixkwargs) where {F,V,KW} = new{F,(-1,),0,V,KW}(f,fixvals,fixkwargs)
    Fix{F,(1,-1),0,V,KW}(f::F,fixvals::Tuple{<:Any,<:Any},fixkwargs) where {F,V,KW} = new{F,(1,-1),0,V,KW}(f,fixvals,fixkwargs)
end

Fix{fixinds,nargs}(f, fixvals...; fixkwargs...) where {fixinds,nargs} =
    Fix{typeof(f), fixinds, nargs, typeof(fixvals), typeof((; fixkwargs...))}(f, fixvals, (; fixkwargs...))
Fix{fixinds}(f, fixvals...; fixkwargs...) where {fixinds} = 
    Fix{typeof(f), fixinds,     0, typeof(fixvals), typeof((; fixkwargs...))}(f, fixvals, (; fixkwargs...))

@generated (f::Fix{F,fixinds,nargs,V,KW})(args...; kwargs...) where {F,fixinds,nargs,V,KW} = begin
    fixinds == () && return :(f.f(args...; f.fixkwargs..., kwargs...))
    if nargs > 0
        @assert nargs==length(fixinds) + length(args) "incorrect number of arguments"
    else
        nargs = length(fixinds) + length(args)
    end
    combined_args = Vector{Expr}(undef, nargs)
    args_i = fixed_args_i = 1
    for i ∈ eachindex(combined_args)
        if any(==(fixinds[fixed_args_i]), (i, i-length(combined_args)-1))
            combined_args[i] = :(f.fixvals[$fixed_args_i])
            fixed_args_i = clamp(fixed_args_i+1, eachindex(fixinds))
        else
            combined_args[i] = :(args[$args_i])
            args_i += 1
        end
    end

    # break out by kwargs cases to improve compile memory usage
    if f <: Fix{<:Any, <:Any, <:Any, <:Any, typeof((;))} # no fixed kwargs
        kwargs <: Tuple{} && return :(f.f($(combined_args...)))
        return :(f.f($(combined_args...); kwargs...))
    end
    kwargs <: Tuple{} && return :(f.f($(combined_args...); f.fixkwargs...))
    :(f.f($(combined_args...); f.fixkwargs..., kwargs...)) #zr
end

# specialized types, constructors, and functors for Fix1 and Fix2
const Fix1{F,X} = Fix{F,(1,),2,Tuple{X},NamedTuple{(),Tuple{}}}
const Fix2{F,Y} = Fix{F,(2,),2,Tuple{Y},NamedTuple{(),Tuple{}}}
Fix1(f,x) = Fix{(1,),2}(f,x)
Fix2(f,y) = Fix{(2,),2}(f,y)
(f::Fix1)(y) = f.f(f.fixvals[1], y)
(f::Fix2)(x) = f.f(x, f.fixvals[1])

# specialized types and constructors for FixFirst and FixLast
const FixFirst{F,X} = Fix{F,(1,),0,Tuple{X}}
const FixLast{F,X} = Fix{F,(-1,),0,Tuple{X}}
FixFirst(f,x...; kw...) = Fix{(1,),0}(f,x...; kw...)
FixLast(f,x...; kw...) = Fix{(-1,),0}(f,x...; kw...)

Base.show(io::IO, f::Fix{F,fixinds,nargs,V,KW}) where {F,fixinds,nargs,V,KW} = begin
    showval(i) = begin
        if i ∈ fixinds  "$(f.fixvals[findfirst(==(i), fixinds)])"
        else  "_"  end
    end
    
    args=String[]
    if nargs > 0
        for i=1:nargs  push!(args, showval(i))  end
    else
        for i=1:max(fixinds...)  push!(args, showval(i))  end
        push!(args, "_...")
        for i=min(fixinds...):-1  push!(args, showval(i))  end
    end
    if length(f.fixkwargs) > 0
        push!(args, "; " * join(("$k=$w" for (k,w) ∈ zip(keys(f.fixkwargs), values(f.fixkwargs))), ", "))
    end
    print(io, "$(f.f)(" * join(args, ", ") * ")")
end

"Implements `Fix` functor, which is created by PAS expressions"