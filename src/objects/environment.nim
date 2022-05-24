import tables
import ../common/types
import ../token/token

# ======================================================== #
# Environment forwarded proc.
# ======================================================== #
proc newEnvironment*: Environment
proc newEnclosedEnv*(enclosing: Environment): Environment
proc get*(e: Environment, name: token.Token): Object
proc define*(e: Environment, name: string, value: Object): void
proc getAt*(e: Environment, distance: int, name: string): Object
proc ancestor*(e: Environment, distance: int): Environment
proc assignAt*(e: Environment, distance: int, name: Token, value: Object): void
proc assign*(e: Environment, name: Token, value: Object): void

# ======================================================== #
# Environment procedures implementation
# ======================================================== #
proc newEnvironment*: Environment =
    new result


proc newEnclosedEnv*(enclosing: Environment): Environment =
    new result
    result.enclosing = enclosing


proc get*(e: Environment, name: token.Token): Object =
    # we look first into the local store.
    if e.values.hasKey(name.lexeme):
        return e.values[name.lexeme]
    if e.enclosing != nil: return e.enclosing.get(name)

    raise RuntimeError(
        token: name, 
        message: "Undefined variable `" & name.lexeme & "`"
    )


proc define*(e: Environment, name: string, value: Object): void =
    e.values[name] = value


proc getAt*(e: Environment, distance: int, name: string): Object =
    var ancestorEnv = e.ancestor(distance)
    return ancestorEnv.values[name]


proc ancestor*(e: Environment, distance: int): Environment =
    result = e
    var i = 0
    while i < distance:
        result = result.enclosing
        inc(i)


proc assignAt*(e: Environment, distance: int, name: Token, value: Object): void =
    var ancestorEnv = e.ancestor(distance)
    ancestorEnv.values[name.lexeme] = value


proc assign*(e: Environment, name: Token, value: Object): void =
    if e.values.hasKey(name.lexeme):
        e.values[name.lexeme] = value
        return
    if e.enclosing != nil:
        e.enclosing.assign(name, value)
        return
    
    raise RuntimeError(
        token: name,
        message: "Undefined variable `" & name.lexeme & "`."
    )