# ChainingDemo

This is some (buggy!) demo code to showcase my ideas [expressed in this thread](https://discourse.julialang.org/t/fixing-the-piping-chaining-partial-application-issue-rev-2/90408/31) for partial application syntax (PAS) and call chain syntax (CCS).

To use,

```
] add https://github.com/uniment/ChainingDemo.jl
```

and 

```
using ChainingDemo
```

You will now have the `@demo_str` macro loaded, which can be invoked like `demo"(1,2)--(it[1]+it[2]^2)"`.

To see a bunch of examples, browse to the file `ChainingDemo/src/demo_code_runthese.jl` and hit `SHIFT+ENTER` one each line of code!
