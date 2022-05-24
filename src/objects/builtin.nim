import strutils
import ../common/types
import ../interpreter/stringify


type
    BuiltinType* = enum
        btPrint
        btAlltrim
        btLen


proc newBuiltin*(t: BuiltinType): Builtin =
    case t:
    of btPrint:
        result = BuiltinPrint(
            name: "print",
            paramSize: 1,
            isVariadic: false
        )
    of btAlltrim:
        result = BuiltinAlltrim(
            name: "alltrim",
            paramSize: 1,
            isVariadic: false
        )
    of btLen:
        result = BuiltinLen(
            name: "len",
            paramSize: 1,
            isVariadic: false
        )


method applyFunction*(f: types.Builtin, arguments: seq[Object]): Object {.base.} =
    discard


method applyFunction*(f: types.BuiltinPrint, arguments: seq[Object]): Object =
    for a in arguments:
        stdout.writeLine(stringify(a))
    return nil


method applyFunction*(f: types.BuiltinAlltrim, arguments: seq[Object]): Object =
    if arguments[0] of types.String: 
        let noSpaces = types.String(arguments[0]).value.strip()
        return types.String(value: noSpaces)
    raise RuntimeError(message: "Argument must be a string.")


method applyFunction*(f: types.BuiltinLen, arguments: seq[Object]): Object =
    let obj = arguments[0]
    if obj of String:
        return Integer(value: String(obj).value.len)
    
    return oNull