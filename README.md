# NOTE

This demo is now officially dead; my ideas for chaining and underscores have moved into separate packages.

To see my latest ideas on chaining, check out [MethodChains.jl](https://github.com/uniment/MethodChains.jl).

To see my latest ideas on underscore partial application syntax, check out [PartialFuns.jl](https://github.com/uniment/PartialFuns.jl).

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