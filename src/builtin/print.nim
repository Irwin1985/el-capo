import ../common/types

proc applyFunction(f: types.Builtin, arguments: seq[Object]): Object =
    discard