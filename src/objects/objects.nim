import std/tables
import ../ast/ast
import ../token/token

type
    # Basic object of ElCapo
    Object* = ref object of RootObj

    BreakObj* = ref object of CatchableError
        # dummy
    
    Callable* = ref object of Object
        # dummy
    
    Class* = ref object of Callable
        name*: string
        superclass*: Class
        methods*: Table[string, ast.Function]

    Continue* = ref object of CatchableError
        # dummy

    Enum* = ref object of Object
        elements*: Table[string, int]

    Environment* = ref object of RootObj
        values: Table[string, Object]
        enclosing: Environment
    
    Function* = ref object of Callable
        declaration: ast.Function
        closure: Environment
        isInitializer: bool

    HashPair* = ref object of Object
        key*: Object
        value*: Object

    Instance* = ref object of Object
        class*: Class
        fields*: Table[string, Object]
    
    Return* = ref object of CatchableError
        value*: Object
    
    RuntimeError* = ref object of CatchableError
        # dummy

    
# ======================================================== #
# Object commons forwarded proc.
# ======================================================== #
proc toString*(o: Object): string

# ======================================================== #
# Callable forwarded proc.
# ======================================================== #
proc arity*(c: Callable): int
proc isVarArg*(c: Callable): bool
proc call*(interpreter: RootObj, arguments: seq[Object]): Object
# TODO: cambiar el tipo de interpreter por el objeto real.

# ======================================================== #
# Class forwarded proc.
# ======================================================== #
proc findMethod*(c: Class, name: string): ast.Function

# ======================================================== #
# Enum forwarded proc.
# ======================================================== #

# ======================================================== #
# Environment forwarded proc.
# ======================================================== #
proc get*(name: token.Token): Object
proc define*(name: string, value: Object): void
proc getAt*(distance: int, name: string): Object
proc ancestor*(distance: int): Environment
proc assignAt*(distance: int, name: Token, value: Object): void
proc assign*(name: Token, value: Object): void


# ======================================================== #
# Object commons forwarded proc.
# ======================================================== #
proc toString*(o: Object): string =
    discard

# ======================================================== #
# Callable forwarded proc.
# ======================================================== #
proc arity*(c: Callable): int =
    discard


proc isVarArg*(c: Callable): bool =
    discard


proc call*(interpreter: RootObj, arguments: seq[Object]): Object =
    discard

# TODO: cambiar el tipo de interpreter por el objeto real.

# ======================================================== #
# Class forwarded proc.
# ======================================================== #
proc findMethod*(c: Class, name: string): ast.Function =
    discard

# ======================================================== #
# Enum forwarded proc.
# ======================================================== #

# ======================================================== #
# Environment forwarded proc.
# ======================================================== #
proc get*(name: token.Token): Object =
    discard


proc define*(name: string, value: Object): void =
    discard


proc getAt*(distance: int, name: string): Object =
    discard


proc ancestor*(distance: int): Environment =
    discard


proc assignAt*(distance: int, name: Token, value: Object): void =
    discard


proc assign*(name: Token, value: Object): void =
    discard