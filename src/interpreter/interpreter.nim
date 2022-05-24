import typetraits
import std/tables
import ../token/token
import ../ast/ast
import ../utils/error
import ../common/types
import ../objects/environment
import ../objects/function
import ../objects/instance
import ../objects/class
import ../objects/callable
import ../objects/builtin


var i: Interpreter = nil

# =============================================== #
# Interpreter forwarded procedures
# =============================================== #
proc newInterpreter*(): Interpreter
proc registerBuiltins: void
proc interpret*(i: Interpreter, statements: seq[ast.Stmt]): void
proc executeBlock(i: Interpreter, statements: seq[ast.Stmt], env: Environment): void
proc resolve*(i: Interpreter, exp: ast.Expr, depth: int): void
proc applyFunction(f: types.Function, arguments: seq[Object]): Object
proc applyClass(c: types.Class, arguments: seq[Object]): Object

proc isEqual(a: Object, b: Object): bool
proc isTruthy(o: Object): bool
proc checkNumberOperands(operator: Token, left: Object, right: Object): void
proc checkNumberOperand(operator: Token, operand: Object): void
proc lookupVariable(name: Token, exp: ast.Expr): Object
proc doArithmeticWith(operator: Token, left: Object, right: Object): Object
proc nativeBoolToBooleanObject(value: bool): types.Boolean


method interpret*(n: ast.Node): Object {.base.}
method interpret*(e: ast.Array): Object
method interpret*(e: ast.Assign): Object
method interpret*(e: ast.AssignCollection): Object
method interpret*(e: ast.Binary): Object
method interpret*(e: ast.BinaryInc): Object
method interpret*(e: ast.Boolean): Object
method interpret*(e: ast.Call): Object
method interpret*(e: ast.Dictionary): Object
method interpret*(e: ast.Enum): Object
method interpret*(e: ast.Float): Object
method interpret*(e: ast.Get): Object
method interpret*(e: ast.Grouping): Object
method interpret*(e: ast.Index): Object
method interpret*(e: ast.Integer): Object
method interpret*(e: ast.Logical): Object
method interpret*(e: ast.Null): Object
method interpret*(e: ast.Self): Object
method interpret*(e: ast.Set): Object
method interpret*(e: ast.String): Object
method interpret*(e: ast.StringFormat): Object
method interpret*(e: ast.Super): Object
method interpret*(e: ast.Unary): Object
method interpret*(e: ast.Variable): Object
method interpret*(s: ast.Block): Object
method interpret*(s: ast.Break): Object
method interpret*(s: ast.Class): Object
method interpret*(s: ast.Continue): Object
method interpret*(s: ast.Defer): Object
method interpret*(s: ast.Expression): Object
method interpret*(s: ast.For): Object
method interpret*(s: ast.Function): Object
method interpret*(s: ast.If): Object
method interpret*(s: ast.Let): Object
method interpret*(s: ast.Return): Object
method interpret*(s: ast.While): Object

# =============================================== #
# implementation
# =============================================== #
proc newInterpreter*(): Interpreter =
    new result
    result.globals = newEnvironment()
    result.environment = result.globals
    result.locals = initTable[Expr, int]()
    i = result
    registerBuiltins()


proc registerBuiltins: void =
    i.globals.define("print", newBuiltin(BuiltinType.btPrint))
    i.globals.define("alltrim", newBuiltin(BuiltinType.btAlltrim))
    i.globals.define("len", newBuiltin(BuiltinType.btLen))


proc interpret*(i: Interpreter, statements: seq[ast.Stmt]): void =
    try:
        for statement in statements:
            discard interpret(statement)            
    except RuntimeError as e:
        error.runtimeError(e)


proc executeBlock(i: Interpreter, statements: seq[ast.Stmt], env: Environment): void =
    var previous = i.environment
    try:
        i.environment = env
        for statement in statements:
            discard interpret(statement)
    finally:
        i.environment = previous


proc resolve*(i: Interpreter, exp: Expr, depth: int): void =
    i.locals[exp] = depth


method interpret*(n: ast.Node): Object {.base.} =
    raise newException(Exception, "Unknown Node type: " & repr(n))


method interpret*(e: ast.Array): Object =
    discard


method interpret*(e: ast.Assign): Object =
    result = interpret(e.value)
    if i.locals.hasKey(e):
        let distance = i.locals[e]
        i.environment.assignAt(distance, e.name, result)
    else:
        i.globals.assign(e.name, result)


method interpret*(e: ast.AssignCollection): Object =
    discard


method interpret*(e: ast.Binary): Object =
    let left = interpret(e.left)
    let right = interpret(e.right)

    case e.operator.kind:
    of tkGreater:
        return nativeBoolToBooleanObject(types.Float(left) > types.Float(right))
    of tkGreaterEqual:
        return nativeBoolToBooleanObject(types.Float(left) >= types.Float(right))
    of tkLess:
        return nativeBoolToBooleanObject(types.Float(left) < types.Float(right))
    of tkLessEqual:
        return nativeBoolToBooleanObject(types.Float(left) <= types.Float(right))
    of tkMinus, tkPlus, tkSlash, tkStar:
        checkNumberOperands(e.operator, left, right)
        return doArithmeticWith(e.operator, left, right)
    of tkBangEqual:
        return nativeBoolToBooleanObject(not isEqual(left, right))
    of tkEqualEqual:
        return nativeBoolToBooleanObject(isEqual(left, right))
    else:
        return oNull


method interpret*(e: ast.BinaryInc): Object =
    discard


method interpret*(e: ast.Boolean): Object =
    return types.Boolean(value: e.value)


method interpret*(e: ast.Call): Object =
    var callee = interpret(e.callee)
    if callee of types.Callable: 
        var arguments = newSeq[Object]()
        for a in e.arguments:
            arguments.add(interpret(a))

        var 
            isVarArg = callee.isVarArg()
            arity = callee.arity()

            # return prepareClass(types.Class(callee), arguments, e)
        if not isVarArg:
            # TODO: pass null for the rest of arguments
            if arguments.len != arity:
                raise RuntimeError(
                    token: e.paren,
                    message: "Expecter " & $arity & " arguments but got " & $arguments.len & "."
                )
        else:
            if arity > 0 and arguments.len == 0:
                raise RuntimeError(
                    token: e.paren,
                    message: "Too few arguments."
                )

        if callee of types.Function:
            result = applyFunction(types.Function(callee), arguments)        
        elif callee of types.Class:
            result = applyClass(types.Class(callee), arguments)
        elif callee of types.Builtin:
            result = types.Builtin(callee).applyFunction(arguments)
    else:
        raise RuntimeError(
            token: e.paren,
            message: "Can only call functions and classes."
        )


method interpret*(e: ast.Dictionary): Object =
    discard


method interpret*(e: ast.Enum): Object =
    discard


method interpret*(e: ast.Float): Object =
    discard


method interpret*(e: ast.Get): Object =
    let owner = interpret(e.owner)
    if owner of Instance:
        return Instance(owner).get(e.name)

    raise RuntimeError(
        token: e.name,
        message: "Only instances have properties."
    )


method interpret*(e: ast.Grouping): Object =
    discard


method interpret*(e: ast.Index): Object =
    discard


method interpret*(e: ast.Integer): Object =
    return types.Integer(value: e.value)


method interpret*(e: ast.Logical): Object =
    discard


method interpret*(e: ast.Null): Object =
    return oNull


method interpret*(e: ast.Self): Object =
    return lookupVariable(e.keyword, e)


method interpret*(e: ast.Set): Object =
    let owner = interpret(e.owner)
    if owner of Instance:
        let value = interpret(e.value)
        Instance(owner).set(e.name, value)
        return value

    raise RuntimeError(
        token: e.name,
        message: "Only instances have fields."
    )


method interpret*(e: ast.String): Object =
    return types.String(value: e.value)


method interpret*(e: ast.StringFormat): Object =
    discard


method interpret*(e: ast.Super): Object =
    let distance = i.locals[e]
    let superclass = types.Class(i.environment.getAt(distance, "super"))
    let instance = types.Instance(i.environment.getAt(distance-1, "self"))
    let method2 = superclass.findMethod(e.methodName.lexeme)

    if method2 == nil:
        raise RuntimeError(token: e.methodName, message: "Undefined property '" & e.methodName.lexeme & "'")
    return method2.bindFunction(instance)


method interpret*(e: ast.Unary): Object =
    discard


method interpret*(e: ast.Variable): Object =
    result = lookupVariable(e.name, e)


# ================================================================== #
# STATEMENTS
# ================================================================== #
method interpret*(s: ast.Block): Object =
    discard


method interpret*(s: ast.Break): Object =
    discard


method interpret*(s: ast.Class): Object =
    var superclass: Object = nil
    if s.superclass != nil:
        superclass = interpret(s.superclass)
        if not (superclass of types.Class):
            raise RuntimeError(
                token: s.superclass.name,
                message: "Superclass must be a class."
            )
    
    i.environment.define(s.name.lexeme, oNull)

    if s.superclass != nil:
        i.environment = newEnclosedEnv(i.environment)
        i.environment.define("super", superclass)
    
    var methods = initTable[string, types.Function]()
    for m in s.methods:
        let function = types.Function(
                            declaration: m, 
                            closure: i.environment, 
                            isInitializer: m.name.lexeme == "init"
                        )
        methods[m.name.lexeme] = function
    
    let class = types.Class(
        name: s.name.lexeme,
        superclass: types.Class(superclass),
        methods: methods
    )

    if superclass != nil:
        i.environment = i.environment.enclosing
    
    i.environment.assign(s.name, class)

    return oNull


method interpret*(s: ast.Continue): Object =
    discard


method interpret*(s: ast.Defer): Object =
    discard


method interpret*(s: ast.Expression): Object =
    return interpret(s.expression)


method interpret*(s: ast.For): Object =
    discard


method interpret*(s: ast.Function): Object =
    let function = types.Function(
        declaration: s,
        closure: i.environment,
        isInitializer: false
    )
    i.environment.define(s.name.lexeme, function)

    return oNull


method interpret*(s: ast.If): Object =
    discard


method interpret*(s: ast.Let): Object =
    new result
    if s.initializer != nil:
        result = interpret(s.initializer)

    i.environment.define(s.name.lexeme, result)
    return oNull


method interpret*(s: ast.Return): Object =
    var value: Object = nil
    if s.value != nil:        
        value = interpret(s.value)

    raise types.Return(
        value: value
    )


method interpret*(s: ast.While): Object =
    discard


proc applyFunction(f: types.Function, arguments: seq[Object]): Object =
    var env = newEnclosedEnv(f.closure)
    if not f.declaration.varArgs:
        var i = 0
        while i < f.declaration.params.len:            
            env.define(f.declaration.params[i].lexeme, arguments[i])
            inc(i)
    else:
        var i = 0
        while i < f.declaration.params.len-1:
            env.define(f.declaration.params[i].lexeme, arguments[i])
            inc(i)
        # Fill the array or arguments
        var varArguments = newSeq[Object]()
        while i < arguments.len:
            varArguments.add(arguments[i])
            inc(i)

        env.define(f.declaration.params[i].lexeme, VariadicArgs(args: varArguments))    

    try:
        i.executeBlock(f.declaration.body, env)
    except types.Return as r:        
        if f.isInitializer: return f.closure.getAt(0, "self")
        result = r.value


proc applyClass(c: types.Class, arguments: seq[Object]): Object =
    var instance = types.Instance(
        class: c,
        fields: initTable[string, Object]()
    )
    let initializer = c.findMethod("init")
    if initializer != nil:
        let function = initializer.bindFunction(instance)
        discard applyFunction(function, arguments)
        
    return instance


# ===================================================================== #
# HELPER FUNCTIONS
# ===================================================================== #
proc isEqual(a: Object, b: Object): bool =
    if a of types.Null and b of types.Null: return true
    if a of types.Null: return false
    return a == b


proc isTruthy(o: Object): bool =
    if o of types.Null: return false
    if o of types.Boolean: return types.Boolean(o).value
    return true


proc checkNumberOperands(operator: Token, left: Object, right: Object): void =
    if (left of types.Integer or left of types.Float) and (right of types.Integer or right of types.Float):
        return
    raise RuntimeError(token: operator, message: "Operands must be numbers.")


proc checkNumberOperand(operator: Token, operand: Object): void =
    if operand of types.Integer or operand of types.Float:
        return
    raise RuntimeError(token: operator, message: "Operand must be number.")

proc lookupVariable(name: Token, exp: ast.Expr): Object =
    if i.locals.hasKey(exp):
        let distance = i.locals[exp]
        return i.environment.getAt(distance, name.lexeme)
    else:
        return i.globals.get(name)


proc doArithmeticWith(operator: Token, left: Object, right: Object): Object =
    if operator.kind == tkSlash:
        if types.Integer(right).value == 0:
            raise RuntimeError(token: operator, message: "Division by zero.")
        return types.Float(value: types.Integer(left).value / types.Integer(right).value)

    if left of types.Float or right of types.Float:
        case operator.kind:
        of tkPlus:
            return types.Float(value: types.Float(left).value + types.Float(right).value)
        of tkMinus:
            return types.Float(value: types.Float(left).value - types.Float(right).value)
        of tkStar:
            return types.Float(value: types.Float(left).value * types.Float(right).value)
        else:
            return oNull
    else:
        case operator.kind:
        of tkPlus:
            return types.Integer(value: types.Integer(left).value + types.Integer(right).value)
        of tkMinus:
            return types.Integer(value: types.Integer(left).value - types.Integer(right).value)
        of tkStar:
            return types.Integer(value: types.Integer(left).value * types.Integer(right).value)
        else:
            return oNull


proc nativeBoolToBooleanObject(value: bool): types.Boolean =
    if value:
        return oTrue
    else:
        return oFalse
