macro demo_str(str)
    # very super-duper hacky: let's steal the :& operator!
    # unfortunately it doesn't give us the same precedence as :.
    # if it looks like this is my first time writing a macro ... it's because it is. This is super hard to debug and maintain.
    str = replace(str, "--"=>"&")
    ex = _insert_chain_macros!(Meta.parse(str))
    ex = :(@underscores $ex)
    esc(ex)
end

function _insert_chain_macros!(ex)
    if ex isa Expr
        map(_insert_chain_macros!, ex.args)
        if ex.head == :call && ex.args[1] == :& # & as infix operator
            pushfirst!(ex.args, Symbol("@chain"))
            ex.head = :macrocall
        elseif ex.head == :call && ex.args[1] == :.& # infix & broadcasting
            pushfirst!(ex.args, Symbol("@chain"))
            ex.head = :macrocall
            push!(ex.args, true)
        elseif ex.head == :& && ex.args[1] ≠ :_ # & as prefix operator
            pushfirst!(ex.args, :&)
            pushfirst!(ex.args, Symbol("@chainlink"))
            ex.head = :macrocall
        end # unfortunately prefix broadcasting doesn't work ... although, should I even want it?
    end
    ex
end

"""Very ugly dirty demo macro: inserts @chain and @chainlink macros for CCS, and invokes tight `_` currying for PAS
This would probably be better if I made the chain insertions a single global operation, perhaps after PAS evaluation."""