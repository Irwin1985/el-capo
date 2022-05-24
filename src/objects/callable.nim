import ../common/types
import class

# ======================================================== #
# Callable forwarded proc.
# ======================================================== #
method arity*(o: Object): int {.base.}
method arity*(o: types.Function): int
method arity*(o: types.Class): int
method arity*(o: types.Builtin): int

method isVarArg*(o: Object): bool {.base.}
method isVarArg*(o: types.Function): bool
method isVarArg*(o: types.Class): bool
method isVarArg*(o: types.Builtin): bool


method toString*(o: Object): string {.base.}
method toString*(o: types.Function): string
method toString*(o: types.Class): string
method toString*(o: types.Builtin): string

# ============================================================ #
# arity method
# ============================================================ #
method arity*(o: Object): int {.base.} =
    discard # nothing


method arity*(o: types.Function): int =
    return o.declaration.params.len


method arity*(o: types.Class): int =
    var initializer:types.Function = o.findMethod("init")
    if initializer == nil:
        return 0
    return initializer.arity()

method arity*(o: types.Builtin): int =
    return o.paramSize


# ============================================================ #
# isVarArg method
# ============================================================ #
method isVarArg*(o: Object): bool {.base.} =
    discard


method isVarArg*(o: types.Function): bool =
    return o.declaration.varArgs


method isVarArg*(o: types.Class): bool =
    return false


method isVarArg*(o: types.Builtin): bool =
    return o.isVariadic


# ============================================================ #
# isVarArg method
# ============================================================ #
method toString*(o: Object): string {.base.} =
    discard


method toString*(o: types.Function): string =
    return "<fn " & o.declaration.name.lexeme & ">"


method toString*(o: types.Class): string =
    return o.name


method toString*(o: types.Builtin): string =
    return o.name