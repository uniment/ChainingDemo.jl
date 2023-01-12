# NOTE

I no longer promote the *chaining* ideas in this demo, because I have converged on the belief that chaining and partial application are best kept separate.

However, I still keep this demo alive for underscore partial application syntax and generalized `Fix` functors. If you want to see my latest ideas on chaining, check out [MethodChains.jl](https://github.com/uniment/MethodChains.jl).

To play with the `Fix` functors and underscore partial application syntax, try stuff like this:

```julia
julia> using ChainingDemo, REPL

julia> pushfirst!(Base.active_repl_backend.ast_transforms, ChainingDemo._underscore_pas!);

julia> [1, 2, 3] |> map(_^2, _)
3-element Vector{Int64}:
 1
 4
 9

julia> f(ar...; kw...) = (; ar, kw)
f (generic function with 1 method)

julia> g = f(:a, _, :c, _..., :end; kw1='a', kw2='b')
(::Fix{typeof(f), (1, 3, -1), -1, Tuple{Symbol, Symbol, Symbol}, NamedTuple{(:kw1, :kw2), Tuple{Char, Char}}}) (generic function with 1 method)

julia> g(2, 4, 5; kw3='c')
(ar = (:a, 2, :c, 4, 5, :end), kw = Base.Pairs(:kw1 => 'a', :kw2 => 'b', :kw3 => 'c'))

julia> Base.map(f) = FixFirst(map, f)

julia> ([:a, :b, :c], [1, 2, 3]) |> Base.splat(map((x,y) -> x=>y))
3-element Vector{Pair{Symbol, Int64}}:
 :a => 1
 :b => 2
 :c => 3
```

This was written as a demo, so I would be surprised if it doesn't have bugs; feel free to let me know when you find them. The `Fix` functor has been pretty carefully written to be performant and bug-free, but maybe it can be better; I'm open to ideas. Already its runtime is zero because it constant-propagates, but maybe its compile time can be improved.

I've disabled the "composition fallback" as I don't believe in that anymore.

I don't know what GitHub stars are, so don't bother.

Old readme below:

# ChainingDemo.jl

This is some (buggy!) demo code to showcase my ideas [expressed in this thread](https://discourse.julialang.org/t/fixing-the-piping-chaining-partial-application-issue-rev-2/90408/31) for partial application syntax (PAS) and call chain syntax (CCS).

To use,

```julia
] add https://github.com/uniment/ChainingDemo.jl
```

and 

```julia
using ChainingDemo
```

You will now have the `@demo_str` macro loaded, which can be invoked like `demo"(1,2)--(it[1]+it[2]^2)"`.

To see a bunch of examples, browse to the file `ChainingDemo/src/demo_code_runthese.jl` and hit `SHIFT+ENTER` on each line of code!

To see what the macro is doing (and hopefully you don't catch one of my many bugs):
```julia
julia> @macroexpand demo" (1,2,3)--(filter(isodd, _); map(_^2+2, _)) "
:(let it = (1, 2, 3)
      it = filter(isodd, it)
      it = map(Fix{(2,), 2}(^, 2) + 2, it)
  end)

julia> demo" (1,2,3)--(filter(isodd, _); map(_^2+2, _)) "
(3, 11)
```