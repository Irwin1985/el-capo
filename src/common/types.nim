import tables
import ../token/token
import ../ast/ast

type
    # Basic object of ElCapo
    Object* = ref object of RootObj

    Boolean* = ref object of Object
        value*: bool

    BreakObj* = ref object of CatchableError
        # dummy    
    Callable* = ref object of Object
        # dummy
    Builtin* = ref object of Callable
        name*: string
        paramSize*: int
        isVariadic*:  bool

    BuiltinPrint* = ref object of Builtin  
    BuiltinAlltrim* = ref object of Builtin
    BuiltinLen* = ref object of Builtin

    Class* = ref object of Callable
        name*: string
        superclass*: types.Class
        methods*: Table[string, types.Function]

    Continue* = ref object of CatchableError
        # dummy

    Enum* = ref object of Object
        elements*: Table[string, int]

    Environment* = ref object of RootObj
        values*: Table[string, Object]
        enclosing*: Environment
    
    Float* = ref object of Object
        value*: float

    Function* = ref object of Callable
        declaration*: ast.Function
        closure*: Environment
        isInitializer*: bool

    HashPair* = ref object of Object
        key*: Object
        value*: Object

    Instance* = ref object of Callable
        class*: Class
        fields*: Table[string, Object]
    
    Integer* = ref object of Object
        value*: int

    Null* = ref object of Object
    
    Return* = ref object of CatchableError
        value*: Object
    
    RuntimeError* = ref object of CatchableError
        token*: Token
        message*: string
    
    String* = ref object of Object
        value*: string
    
    VariadicArgs* = ref object of Object
        args*: seq[Object]

    Interpreter* = ref object of RootObj
        globals*: Environment
        environment*: Environment
        locals*: Table[Expr, int]


let
    oNull* = Null()
    oTrue* = Boolean(value: true)
    oFalse* = Boolean(value: false)
