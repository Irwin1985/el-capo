import tables
import hashes
import ../token/token

type
    Node* = ref object of RootObj
    Expr* = ref object of Node
    Stmt* = ref object of Node
    # ===================================================== #
    # Expression Nodes
    # ===================================================== #
    Array* = ref object of Expr
        keyword*: Token
        elements*: seq[Expr]
    
    Assign* = ref object of Expr
        name*: Token
        value*: Expr
    
    AssignCollection* = ref object of Expr
        keyword*: Token
        left*: Variable
        index*: Expr
        value*: Expr
    
    Binary* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr
    
    BinaryInc* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr
    
    Boolean* = ref object of Expr
        value*: bool

    Call* = ref object of Expr
        callee*: Expr
        paren*: Token
        arguments*: seq[Expr]
    
    Dictionary* = ref object of Expr
        keyword*: Token
        elements*: Table[Expr, Expr]
    
    Enum* = ref object of Expr
        keyword*: Token
        elements*: Table[string, int]
    
    Float* = ref object of Expr
        value*: float

    Get* = ref object of Expr
        owner*: Expr
        name*: Token
    
    Grouping* = ref object of Expr
        expression*: Expr
    
    Index* = ref object of Expr
        keyword*: Token
        left*: Expr
        index*: Expr    

    Integer* = ref object of Expr
        value*: int
    
    Logical* = ref object of Expr
        left*: Expr
        operator*: Token
        right*: Expr

    Null* = ref object of Expr
        # nothing
    
    Self* = ref object of Expr
        keyword*: Token

    Set* = ref object of Expr
        owner*: Expr
        name*: Token
        value*: Expr        

    String* = ref object of Expr
        value*: string
    
    StringFormat* = ref object of Expr
        variables*: seq[Expr]
        words*: seq[string]
        source*: string
    
    Super* = ref object of Expr
        keyword*: Token
        methodName*: Token
    
    Unary* = ref object of Expr
        operator*: Token
        right*: Expr
    
    Variable* = ref object of Expr
        name*: Token

    # ===================================================== #
    # Statement Nodes
    # ===================================================== #
    Block* = ref object of Stmt
        statements*: seq[Stmt]
    
    Break* = ref object of Stmt
        doomyProp: bool
    
    Class* = ref object of Stmt
        name*: Token
        superclass*: Variable
        properties*: seq[Let]
        methods*: seq[Function]
    
    Continue* = ref object of Stmt
        dommyProp: bool
    
    Defer* = ref object of Stmt
        body*: Stmt
    
    Expression* = ref object of Stmt
        expression*: Expr
    
    For* = ref object of Stmt
        keyword*: Token
        indexOrKey*: Token
        value*: Token
        collection*: Expr
        body*: seq[Stmt]
    
    Function* = ref object of Stmt
        name*: Token
        varArgs*: bool
        params*: seq[Token]
        body*: seq[Stmt]
    
    If* = ref object of Stmt
        condition*: Expr
        thenBranch*: Stmt
        elseBranch*: Stmt
    
    Let* = ref object of Stmt
        name*: Token
        initializer*: Expr
    
    Module* = ref object of Stmt
        names*: seq[Token]
        alias*: Token
        identifiers*: seq[Token]
    
    Program* = ref object of Stmt
        statements*: seq[Stmt]
        modules*: seq[Module]
    
    Return* = ref object of Stmt
        keyword*: Token
        value*: Expr
    
    While* = ref object of Stmt
        condition*: Expr
        body*: Stmt

# ===================================================== #
# hash procedure for hashable nodes.
# ===================================================== #
proc hash*(n: Expr): Hash =
    var h: Hash = 0
    if n of Integer:
        h = h !& Integer(n).value.hash        
    elif n of Float:
        h = h !& Float(n).value.hash        
    elif n of String:
        h = h !& String(n).value.hash        
    elif n of StringFormat:
        h = h !& StringFormat(n).source.hash        
    elif n of Boolean:
        let value: int = if Boolean(n).value: 1 else : 0
        h = h !& value.hash        
    return h

# ============================================================ #
# ATTENTION: this procedure is just for debugging porpuses.
# ============================================================ #
proc `$`*(n: Expr): string =
    if n of Integer:
        return $Integer(n).value
    elif n of Float:
        return $Float(n).value    
    elif n of String:
        return String(n).value
    elif n of StringFormat:
        return StringFormat(n).source
    elif n of Boolean:
        if Boolean(n).value: return "true" else: return "false"

proc isHashable*(n: Expr): bool =
    if n of Integer: return true
    if n of Float: return true
    if n of Boolean: return true
    if n of String: return true
    if n of StringFormat: return true    

    return false
    