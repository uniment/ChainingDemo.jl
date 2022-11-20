# Run through these demo examples! (just hit SHIFT+ENTER in VSCode)

# DO NOT USE THE "&" OPERATOR!!! I HIJACKED IT FOR THE DEMO.

# partial application demo
f(args...) = args
g(a...;kw...) = ((a...,),(;kw...))
demo"_>2".(1:5)
demo"f(_,2,_)"
demo"f(_,2,_)(1,3)"
demo"f(_,:start,_...,:finish)"(1,2,3,4)
h = demo"g(:a, _, :b; k=:k)"
h(2, j=:j)
demo"f(1, 2, &_)"()
demo"f(1, 2, &_)--typeof"
demo"_^2 isa Fix2"
demo"1+_ isa Fix1"
demo"map(_^2, 1:5)"

# call chain demo
q(x) = x^2; r(x) = x+1; s(x) = Complex(x)
γ(x) = (a=x, b=x^2); 
x = 2
demo"x--q"
demo"x--q(_)"
demo"x--q(it)"
demo"x--(q)"
demo"x--begin q end"
demo"x--(q;r;s)"
demo"x--q--r--s"
demo"x--begin q; r; s end"
demo"x--(γ; it.a+it.b; q)"
demo"x--(γ; f(_,_))"
demo"(1,3)--f(_,2,_)" # splat!
demo"1--(_^2; (println(it); it); _+1)"
macro aside(ex) :($ex; it) end
demo"1--(_^2; (@aside println(it)); _+1)"
demo""" "1"--parse(Int,_) == 1"""
demo" (1-1im)--(it--real, it--imag) "
demo" (1, 2, 10)--[(it--first : it--last)...] "
demo""" "Hello, world!"--(replace(_, "o"=>"e"); split(_, ","); join(_, ":"); uppercase) """
demo"""
[1, 2, 3] -- begin
    filter(isodd, _)
    map(_^2, _)
    sum(it)
    sqrt(_)
end"""
demo""" "1 2, 3; hehe4"--eachmatch(r"(\d+)", _).--(first; parse(Int, _))--join(_, ", ") """
chain = demo""" --(split(_, r",\s*"); map(--(parse(Int, it)^2), _); join(_, ", ")) """
demo""" "1, 2, 3, 4"--chain """
funcs = demo"(_+i for i=1:10)"
chain = demo"--(funcs...,)" # ok so this one doesn't work
demo"0--chain" # 🥺
demo"(_^2, [1,2,3])--mapreduce(_, +, _)"
demo"(:a,:b)--(reverse(it); f(_,_))"

run = demo"""println("Hello", "world!", &_)"""
run()

appEND = demo"f(_..., :END)"
appEND(:a, :b, :c)
appEND isa FixLast

using DataFrames
df = DataFrame(id=1:100, group=rand(1:3, 100), age=rand(1:30, 100))
demo"""
df--begin
    dropmissing
    filter(:id => >(50), _)
    groupby(_, :group)
    combine(_, :age => sum)
end"""

demo"""
"a=1 b=2 c=3"--begin
    split
    map(--(split(_, "="); Symbol(it[1]) => parse(Int, it[2])), _)
    NamedTuple
end"""

using Transducers
somethinging = demo"--(Filter(>(50)); Map(2_))"
xs = collect(1:100);
demo"xs--somethinging--sum"

# partial function composition demo
demo" (1,2,3)--abs2.(_) "
demo" (_+2+3) "
demo" (_-2-3) "
demo" 1--(_+2+3) "
demo" 1--(_-2-3) "
demo" tan(sin(cos(_)))--acos(asin(atan(_))) "
demo" tan(sin(cos(_)))--acos(asin(atan(_))) "(1)
demo" cos(_)--sin--tan--atan--asin--acos "
demo" cos(_)--sin--tan--atan--asin--acos "(1)
demo" --(cos; sin; tan; atan; asin; acos) "
demo" --(cos; sin; tan; atan; asin; acos) "(1)
demo" --cos--sin--tan--atan--asin--acos "
demo" --cos--sin--tan--atan--asin--acos "(1)
# cos--sin--tan--atan--asin--acos doesn't work,
# because sin(::Function) is not defined.
# Should it be though? 🤔 When a method for f(x::T) isn't found,
# if T is a callable type, should f∘x be returned?
demo" (a=1,)--(_.a+1; it+it^2) "
demo" ((1,2),(2,3),(3,4)).--(_[1]^2 + 1) "
demo" 1--((1,2,3)[_+1]) "
demo" (0:10)--filter(isodd, _)--map(_/2+1, _) "
demo" [(a=i,) for i=0:10]--filter(_.a%3==0, _) "
demo"""
"a=1 b=2 c=3"--begin
    split
    it.--(split(_,"="); (it[1]--Symbol => parse(Int,it[2])))
    NamedTuple
end
"""
using DataFrames
df = DataFrame(id=1:100, group=rand(1:5, 100), age=rand(1:30, 100));
demo"""
df--begin
    dropmissing
    filter(:id => (_%5==0), _)
    groupby(_, :group)
    combine(_, :age => sum)
end
"""
demo" (0:0.25:1).--atan(cos(π*_)) "
demo" [1,2,3]--((l=length(it); it); sum(it)/l) "
demo" 1--(it+1, it-2) "
demo" 1--[it+1, it-2] "
demo" 1--Dict(:a=>it+1, :b=>it-2) "
demo" 1--Set((it+1, it-2)) "
demo" (1,2,3)--[i^2 for i ∈ it] "
demo" (1,2,3)--[(i*_)^2 for i ∈ it] "