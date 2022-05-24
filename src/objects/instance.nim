import ../common/types
import ../token/token
import function
import tables
import class


proc get*(i: Instance, name: Token): Object
proc set*(i: Instance, name: Token, value: Object): void
proc toString*(i: Instance): string


proc get*(i: Instance, name: Token): Object =
    if i.fields.hasKey(name.lexeme):
        return i.fields[name.lexeme]

    var methodo = i.class.findMethod(name.lexeme)

    if methodo != nil:
        return methodo.bindFunction(i)

    raise RuntimeError(
        token: name,
        message: "Undefined property `" & name.lexeme & "`."
    )


proc set*(i: Instance, name: Token, value: Object): void =
    i.fields[name.lexeme] = value


proc toString*(i: Instance): string =
    result = i.class.name & " instance"