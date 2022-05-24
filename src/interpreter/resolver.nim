import std/tables
import ../ast/ast
import ../token/token
import ../utils/error
import typetraits
from ../common/types import Interpreter
import interpreter

const stackSize = 2048


type
    FunctionType = enum
        ftNone
        ftFunction
        ftInitializer
        ftMethod
    
    ClassType = enum
        ctNone
        ctClass
        ctSubclass
    
    Resolver = ref object of RootObj
        interpreter: Interpreter
        scopes: array[stackSize, Table[string, bool]]
        sp: int # stack pointer
        currentFunction: FunctionType
        currentClass: ClassType        


# ======================================================== #
# Resolver forwarded proc
# ======================================================== #
proc newResolver*(interpreter: Interpreter): Resolver
proc resolve*(statements: seq[Stmt]): void
method resolve(n: Node): void {.base.}
method resolve(e: Array): void
method resolve(e: Assign): void
method resolve(e: AssignCollection): void
method resolve(e: Binary): void
method resolve(e: BinaryInc): void
method resolve(e: Boolean): void
method resolve(e: Call): void
method resolve(e: Dictionary): void
method resolve(e: Enum): void
method resolve(e: Float): void
method resolve(e: Get): void
method resolve(e: Grouping): void
method resolve(e: Index): void
method resolve(e: Integer): void
method resolve(e: Logical): void
method resolve(e: Null): void
method resolve(e: Self): void
method resolve(e: Set): void
method resolve(e: String): void
method resolve(e: StringFormat): void
method resolve(e: Super): void
method resolve(e: Unary): void
method resolve(e: Variable): void
method resolve(s: Block): void
method resolve(s: Break): void
method resolve(s: Class): void
method resolve(s: Continue): void
method resolve(s: Defer): void
method resolve(s: Expression): void
method resolve(s: For): void
method resolve(s: Function): void
method resolve(s: If): void
method resolve(s: Let): void
method resolve(s: Return): void
method resolve(s: While): void

proc beginScope(r: Resolver): void
proc endScope(r: Resolver): void
proc declare(r: Resolver, name: Token): void
proc define(r: Resolver, name: Token): void
proc resolveLocal(r: Resolver, exp: Expr, name: Token): void
proc resolveFunction(r: Resolver, function: Function, tipe: FunctionType): void
proc push(r: Resolver, val: Table[string, bool]): void
proc pop(r: Resolver): void
proc peek(r: Resolver): Table[string, bool]
proc isEmpty(r: Resolver): bool



var r*: Resolver

# ======================================================== #
# Resolver implementation
# ======================================================== #
proc newResolver*(interpreter: Interpreter): Resolver =
    new result
    result.sp = -1
    result.interpreter = interpreter
    r = result


proc beginScope(r: Resolver, ): void =
    r.push(initTable[string, bool]())


proc endScope(r: Resolver, ): void =
    r.pop()


proc declare(r: Resolver, name: Token): void =
    if r.isEmpty():
        return

    var scope = r.peek()

    if scope.hasKey(name.lexeme):
        error.error(name, "This scope already has a variable defined with this name.")

    scope[name.lexeme] = false
    # parche
    r.scopes[r.sp] = scope
    # parche


proc define(r: Resolver, name: Token): void =
    if r.isEmpty(): return
    var scope = r.peek()
    scope[name.lexeme] = true
    # parche
    r.scopes[r.sp] = scope
    # parche    


proc resolveLocal(r: Resolver, exp: Expr, name: Token): void =        
    var i = r.sp
    while i >= 0:
        var scope = r.scopes[i]

        if scope.hasKey(name.lexeme):
            let depth = r.sp - i
            r.interpreter.resolve(exp, depth)
            return
        i -= 1


proc resolveFunction(r: Resolver, function: Function, tipe: FunctionType): void =
    let enclosingFunction = r.currentFunction
    r.currentFunction = tipe
    r.beginScope()

    for param in function.params:
        r.declare(param)
        r.define(param)
    
    resolve(function.body)
    r.endScope()

    r.currentFunction = enclosingFunction


proc push(r: Resolver, val: Table[string, bool]): void =
    r.sp += 1 # first increase the stack pointer.
    if r.sp >= stackSize:
        stdout.writeLine("Stack overflow")
        return
    r.scopes[r.sp] = val


proc pop(r: Resolver): void =
    r.sp -= 1


proc peek(r: Resolver): Table[string, bool] =
    if r.scopes[r.sp].len > 0:
        return r.scopes[r.sp]


proc isEmpty(r: Resolver): bool =
    return r.sp < 0

# ======================================================== #
# Visitor forwarded proc
# ======================================================== #
method resolve(n: Node): void {.base.} =
    raise newException(Exception, "Unknown Node type: " & repr(n))


proc resolve*(statements: seq[Stmt]): void =
    for statement in statements:
        resolve(statement)


# ================================================ #
# Array Literal
# ================================================ #
method resolve(e: Array): void =
    for elem in e.elements:
        resolve(elem)


# ================================================ #
# Assign Expression (a = b)
# ================================================ #
method resolve(e: Assign): void =
    resolve(e.value)
    r.resolveLocal(e, e.name)


# ================================================ #
# AssignCollection
# ================================================ #
method resolve(e: AssignCollection): void =
    resolve(e.index)
    resolve(e.value)


# ================================================ #
# Binary Expression
# ================================================ #
method resolve(e: Binary): void =
    resolve(e.left)
    resolve(e.right)


# ================================================ #
# Binary Incremental Expression
# ================================================ #
method resolve(e: BinaryInc): void =
    resolve(e.left)
    resolve(e.right)


# ================================================ #
# Boolean
# ================================================ #
method resolve(e: Boolean): void =
    discard


# ================================================ #
# Call
# ================================================ #
method resolve(e: Call): void =
    resolve(e.callee)

    for a in e.arguments:
        resolve(a)


# ================================================ #
# Dictionary Expression
# ================================================ #
method resolve(e: Dictionary): void =
    for k,v in e.elements:
        resolve(k)
        resolve(v)


# ================================================ #
# Enum expression
# ================================================ #
method resolve(e: Enum): void =
    discard


# ================================================ #
# Float Literal
# ================================================ #
method resolve(e: Float): void =
    discard


# ================================================ #
# Get Expression
# ================================================ #
method resolve(e: Get): void =
    resolve(e.owner)


# ================================================ #
# Grouping expression
# ================================================ #
method resolve(e: Grouping): void =
    resolve(e.expression)


# ================================================ #
# Index
# ================================================ #
method resolve(e: Index): void =
    resolve(e.index)
    resolve(e.left)


# ================================================ #
# Integer Literal
# ================================================ #
method resolve(e: Integer): void =
    discard


# ================================================ #
# Binary logical expression
# ================================================ #
method resolve(e: Logical): void =
    resolve(e.left)
    resolve(e.right)


# ================================================ #
# Null
# ================================================ #
method resolve(e: Null): void =
    discard


# ================================================ #
# Self Expression
# ================================================ #
method resolve(e: Self): void =
    if r.currentClass == ClassType.ctNone:
        error.error(e.keyword, "Can't use `self` outside of a class.")
        return
    r.resolveLocal(e, e.keyword)



# ================================================ #
# Set Expression
# ================================================ #
method resolve(e: Set): void =
    resolve(e.value)
    resolve(e.owner)


# ================================================ #
# String Literal
# ================================================ #
method resolve(e: String): void =
    discard


# ================================================ #
# StringFormat Literal
# ================================================ #
method resolve(e: StringFormat): void =
    for v in e.variables:
        resolve(v)


# ================================================ #
# Super
# ================================================ #
method resolve(e: Super): void =
    if r.currentClass == ClassType.ctNone:
        error.error(e.keyword, "Can't use `super` outside of a class.")
    elif r.currentClass != ClassType.ctSubclass:
        error.error(e.keyword, "Can't use `super` in a class with no superclass.")
    
    r.resolveLocal(e, e.keyword)    


# ================================================ #
# Unary Expression
# ================================================ #
method resolve(e: Unary): void =
    resolve(e.right)


# ================================================ #
# Identifier
# ================================================ #
method resolve(e: Variable): void =
    if not r.isEmpty():
        var scope = r.peek()
        if scope.hasKey(e.name.lexeme):
            let value = scope[e.name.lexeme]
            if not value:
                error.error(e.name, "Can't read local variable in its own initializer")
    
    r.resolveLocal(e, e.name)


# ======================================================================================= #
# Statements
# ======================================================================================= #

# ================================================ #
# Block
# ================================================ #
method resolve(s: Block): void =
    r.beginScope()
    resolve(s.statements)
    r.endScope()


# ================================================ #
# Break
# ================================================ #
method resolve(s: Break): void =
    discard


# ================================================ #
# Class
# ================================================ #
method resolve(s: Class): void =
    let enclosingClass = r.currentClass
    r.currentClass = ClassType.ctClass

    r.declare(s.name)
    r.define(s.name)

    if s.superclass != nil and s.name.lexeme == s.superclass.name.lexeme:
        error.error(s.superclass.name, "A class can't inherit from itself")
    
    if s.superclass != nil:
        r.currentClass = ClassType.ctSubclass
        resolve(s.superclass)
    
    if s.superclass != nil:
        r.beginScope()
        var scope = r.peek()
        scope["super"] = true
        # parche
        r.scopes[r.sp] = scope
        # parche        
    
    r.beginScope()
    var scope = r.peek()
    scope["self"] = true
    # parche
    r.scopes[r.sp] = scope
    # parche    

    for m in s.methods:
        var declaration = FunctionType.ftMethod

        if m.name.lexeme == "init":
            declaration = FunctionType.ftInitializer
        
        r.resolveFunction(m, declaration)
    
    r.endScope()

    if s.superclass != nil:
        r.endScope()

    r.currentClass = enclosingClass


# ================================================ #
# Continue
# ================================================ #
method resolve(s: Continue): void =
    discard


# ================================================ #
# Defer
# ================================================ #
method resolve(s: Defer): void =
    resolve(s.body)


# ================================================ #
# Expression
# ================================================ #
method resolve(s: Expression): void =
    resolve(s.expression)


# ================================================ #
# For Statement
# ================================================ #
method resolve(s: For): void =
    r.beginScope()
    if s.indexOrKey != nil:
        r.declare(s.indexOrKey)
        r.define(s.indexOrKey)
    
    r.declare(s.value)
    r.define(s.value)

    resolve(s.collection)
    resolve(s.body)

    r.endScope()


# ================================================ #
# Function Statement
# ================================================ #
method resolve(s: Function): void =
    r.declare(s.name)
    r.define(s.name)

    r.resolveFunction(s, FunctionType.ftFunction)


# ================================================ #
# If Statement
# ================================================ #
method resolve(s: If): void =
    resolve(s.condition)
    resolve(s.thenBranch)
    if s.elseBranch != nil:
        resolve(s.elseBranch)


# ================================================ #
# Let Statement
# ================================================ #
method resolve(s: Let): void =
    r.declare(s.name)
    if s.initializer != nil:
        resolve(s.initializer)
    
    r.define(s.name)    


# ================================================ #
# Return Statement
# ================================================ #
method resolve(s: Return): void =
    if r.currentFunction == FunctionType.ftNone:
        error.error(s.keyword, "Can't return from top-level code.")
    
    if s.value != nil:
        if r.currentFunction == FunctionType.ftInitializer:
            error.error(s.keyword, "Can't return a value from an initializer.")
        
        resolve(s.value)


# ================================================ #
# While Statement
# ================================================ #
method resolve(s: While): void =
    resolve(s.condition)
    resolve(s.body)    

