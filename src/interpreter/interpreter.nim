import typetraits
import hashes
import sequtils
import strutils
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
import stringify


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
proc raiseError(t: Token, m: string): void
proc raiseError(m: string): void
proc isNumber(o: types.Object): bool
proc isFloat(o: varargs[types.Object]): bool

proc isCollection(collection: Object): bool

proc executeForStmt(s: ast.For, collection: types.Array, env: Environment): void
proc executeForStmt(s: ast.For, collection: types.Integer, env: Environment): void
proc executeForStmt(s: ast.For, collection: types.String, env: Environment): void
proc executeForStmt(s: ast.For, collection: types.Dictionary, env: Environment): void
proc executeForStmt(s: ast.For, collection: types.Enum, env: Environment): void

# proc isEqual(a: Object, b: Object): bool
proc isTruthy(o: Object): bool
proc `==`(a: Object, b: Object): bool
proc checkNumberOperands(operator: Token, left: Object, right: Object): void
proc checkNumberOperand(operator: Token, operand: Object): void
proc lookupVariable(name: Token, exp: ast.Expr): Object
proc nativeBoolToBooleanObject(value: bool): types.Boolean


# expression evaluation methods
method evaluate(n: ast.Expr): Object {.base, warning[LockLevel]:off.}
# statement execution methods
method execute(n: ast.Stmt): void {.base, warning[LockLevel]:off.}

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
    i.globals.define("seconds", newBuiltin(BuiltinType.btSeconds))


proc interpret*(i: Interpreter, statements: seq[ast.Stmt]): void =
    try:
        for statement in statements:
            execute(statement)            
    except RuntimeError as e:
        error.runtimeError(e)


proc executeBlock(i: Interpreter, statements: seq[ast.Stmt], env: Environment): void =
    var previous = i.environment
    try:
        i.environment = env
        var deferBlock: ast.Defer = nil
        for statement in statements:
            if statement of ast.Defer:
                deferBlock = ast.Defer(statement)
            else:
                execute(statement)
        if deferBlock != nil:
            execute(deferBlock)
    finally:
        i.environment = previous


proc resolve*(i: Interpreter, exp: Expr, depth: int): void =
    i.locals[exp] = depth

# =================================================================== #
# Expression evaluation method implementation
# =================================================================== #
method evaluate(n: ast.Expr): Object {.base.} =
    raise newException(Exception, "Unknown Node type: " & repr(n))


method evaluate*(e: ast.Array): Object =
    var arrayObj = new types.Array
    arrayObj.elements = newSeq[Object]()
    for ae in e.elements:
        arrayObj.elements.add(evaluate(ae))
    
    return arrayObj


method evaluate*(e: ast.Assign): Object =
    result = evaluate(e.value)
    if i.locals.hasKey(e):
        let distance = i.locals[e]
        i.environment.assignAt(distance, e.name, result)
    else:
        i.globals.assign(e.name, result)


method evaluate*(e: ast.AssignCollection): Object =
    let owner = evaluate(e.left)
    if owner of types.Array or owner of types.Dictionary:
        let index = evaluate(e.index)
        if index == nil:
            raiseError(e.keyword, "The index must be an integer.")
        let value = evaluate(e.value)
        if owner of types.Array:
            if index of types.Integer:
                let j = types.Integer(index).value
                let arrayObj = types.Array(owner)
                if j < 0 or j >= arrayObj.elements.len:
                    raiseError(e.keyword, "Index out of bounds")
                arrayObj.elements[j] = value
                if i.locals.hasKey(e):
                    let distance = i.locals[e]
                    i.environment.assignAt(distance, e.left.name, arrayObj)
                else:
                    i.globals.assign(e.left.name, arrayObj)
            else:
                raiseError(e.keyword, "Array index must be an integer.")
        else: # Dictionary        
            var dictionary = types.Dictionary(owner)
            if dictionary.elements.hasKey(index.hash()):
                dictionary.elements[index.hash()] = types.HashPair(key: index, value: value)
                if i.locals.hasKey(e):
                    let distance = i.locals[e]
                    i.environment.assignAt(distance, e.left.name, dictionary)
                else:
                    i.globals.assign(e.left.name, dictionary)

        return value
    else:
        raiseError("Invalid object for item assignment.")


method evaluate*(e: ast.Binary): Object =
    let left = evaluate(e.left)
    let right = evaluate(e.right)

    case e.operator.kind:
    of tkBangEqual:
        if left == right: return oFalse else: return oTrue # negated '!='
    of tkEqualEqual:
        if left == right: return oTrue else: return oFalse
    of tkGreater:        
        checkNumberOperands(e.operator, left, right)
        if isFloat(left, right):
            if types.Float(left).value > types.Float(right).value: return oTrue else: return oFalse
        else:
            if types.Integer(left).value > types.Integer(right).value: return oTrue else: return oFalse
    of tkGreaterEqual:
        checkNumberOperands(e.operator, left, right)
        if isFloat(left, right):
            if types.Float(left).value >= types.Float(right).value: return oTrue else: return oFalse
        else:
            if types.Integer(left).value >= types.Integer(right).value: return oTrue else: return oFalse
    of tkLess:
        checkNumberOperands(e.operator, left, right)
        if isFloat(left, right):
            if types.Float(left).value < types.Float(right).value: return oTrue else: return oFalse
        else:
            if types.Integer(left).value < types.Integer(right).value: return oTrue else: return oFalse
    of tkLessEqual:
        checkNumberOperands(e.operator, left, right)
        if isFloat(left, right):
            if types.Float(left).value <= types.Float(right).value: return oTrue else: return oFalse
        else:
            if types.Integer(left).value <= types.Integer(right).value: return oTrue else: return oFalse
    of tkMinus:
        checkNumberOperands(e.operator, left, right)
        if isFloat(left, right):
            return types.Float(value: types.Float(left).value - types.Float(right).value)
        else:
            return types.Integer(value: types.Integer(left).value - types.Integer(right).value)
    of tkPlus:
        if isNumber(left) and isNumber(right):
            if isFloat(left, right):
                return types.Float(value: types.Float(left).value + types.Float(right).value)
            else:
                return types.Integer(value: types.Integer(left).value + types.Integer(right).value)
        elif left of types.String and right of types.String:
            return types.String(value: types.String(left).value & types.String(right).value)
        else:
            raiseError(e.operator, "Operands must be two numbers of two strings.")
    of tkSlash:
        checkNumberOperands(e.operator, left, right)        
        if types.Float(right).value == 0:
            raiseError(e.operator, "Division by zero.")
        return types.Float(value: types.Float(left).value / types.Float(right).value)
    of tkStar:
        checkNumberOperands(e.operator, left, right)
        if isFloat(left, right):
            return types.Float(value: types.Float(left).value * types.Float(right).value)
        else:
            return types.Integer(value: types.Integer(left).value * types.Integer(right).value)
    else:
        return oNull


method evaluate*(e: ast.BinaryInc): Object =
    if e.left of ast.Variable:
        let rightValue = evaluate(e.right)
        let variableNode = ast.Variable(e.left)
        let ownerValue = evaluate(variableNode)
        let operator = e.operator.kind

        if ownerValue of types.String:
            if rightValue of types.String:
                if operator == tkPlusEqual:
                    let newVal = types.String(ownerValue).value & types.String(rightValue).value
                    result = types.String(value: newVal)
                    i.environment.assign(variableNode.name, result)
                else:
                    raiseError(e.operator, "unsupported operand for string types.")
            else:
                raiseError(e.operator, "can only concatenate strings to strings types.")
        elif rightValue of types.Float: # when Float it doesn't matter the rightValue type
            if isNumber(rightValue):
                let newVal = types.Float(ownerValue).value + types.Float(rightValue).value
                result = types.Float(value: newVal)
                i.environment.assign(variableNode.name, result)
            else:
                raiseError(e.operator, "unsupported operand for float types.")
        elif rightValue of types.Integer: # if rightValue is float then the source type
            if isNumber(rightValue):
                if rightValue of types.Float:
                    let newVal = types.Float(ownerValue).value + types.Float(rightValue).value
                    result = types.Float(value: newVal)
                else:
                    let newVal = types.Integer(ownerValue).value + types.Integer(rightValue).value
                    result = types.Integer(value: newVal)

                i.environment.assign(variableNode.name, result)
            else:
                raiseError(e.operator, "unsupported operand for integer types.")
        else:
            raiseError(e.operator, "")
    else:
        raiseError(e.operator, "Illegal expression for augmented assignment")


method evaluate*(e: ast.Boolean): Object =
    return types.Boolean(value: e.value)


method evaluate*(e: ast.Call): Object =
    var callee = evaluate(e.callee)
    if callee of types.Callable: 
        var arguments = newSeq[Object]()
        for a in e.arguments:
            arguments.add(evaluate(a))

        var 
            isVarArg = callee.isVarArg()
            arity = callee.arity()

            # return prepareClass(types.Class(callee), arguments, e)
        if not isVarArg:
            # TODO: pass null for the rest of arguments
            if arguments.len != arity:
                raiseError(e.paren,"Expecter " & $arity & " arguments but got " & $arguments.len & ".")
        else:
            if arity > 0 and arguments.len == 0:
                raiseError(e.paren, "Too few arguments.")

        if callee of types.Function:
            result = applyFunction(types.Function(callee), arguments)        
        elif callee of types.Class:
            result = applyClass(types.Class(callee), arguments)
        elif callee of types.Builtin:
            result = types.Builtin(callee).applyFunction(arguments)
    else:
        raiseError(e.paren, "Can only call functions and classes.")


method evaluate*(e: ast.Dictionary): Object =
    # HashPair: contains the objects (key, value)
    # TODO: i think HashPair could be replaced for a Tuple.
    var dictionary = new types.Dictionary
    dictionary.elements = initTable[Hash, types.HashPair]()
    for k, v in e.elements:
        let key = evaluate(k)
        if key == nil or key of types.Null:
            raiseError("Invalid key for diccionary.")
        let value = evaluate(v)
        if key.hash() == 0:
            raiseError("Invalid key for dictionary.")
        dictionary.elements[key.hash()] = types.HashPair(key: key, value: value)

    return dictionary

method evaluate*(e: ast.Float): Object =
    return types.Float(value: e.value)


method evaluate*(e: ast.Get): Object =
    let owner = evaluate(e.owner)
    if owner of Instance:
        return Instance(owner).get(e.name)
    elif owner of types.Enum:
        var enumObj = types.Enum(owner)
        if enumObj.elements.hasKey(e.name.lexeme):
            return types.Integer(value: enumObj.elements[e.name.lexeme])
        else:
            return oNull
    # elif owner of types.Dictionary:
    #     var dictionary = types.Dictionary(owner)
    #     let key = types.String(value: e.name.lexeme)
    #     if dictionary.elements.hasKey(key.hash()):
    #         return dictionary.elements[key.hash()].key
    #     return oNull

    raiseError(e.name, "Cannot find the proper object for this property.")


method evaluate*(e: ast.Grouping): Object =
    return evaluate(e.expression)


method evaluate*(e: ast.Index): Object =
    # evaluate the index or accesor
    let index = evaluate(e.index)
    let owner = evaluate(e.left) # ownwe
    if index == nil or owner == nil:
        return oNull
    if owner of types.Array:
        if index of types.Integer:
            let i = types.Integer(index).value
            let arrayObj = types.Array(owner)
            if i < 0 or i >= arrayObj.elements.len:
                return oNull
            return arrayObj.elements[i]
        else:
            return oNull
    elif owner of types.Dictionary:
        var dictionary = types.Dictionary(owner)
        if dictionary.elements.hasKey(index.hash()):
            return dictionary.elements[index.hash()].value
        else:
            return oNull


method evaluate*(e: ast.Integer): Object =
    return types.Integer(value: e.value)


method evaluate*(e: ast.Logical): Object =
    let left = evaluate(e.left)

    if e.operator.kind == tkOr:
        if isTruthy(left): return left
    else:
        if not isTruthy(left): return left
    
    return evaluate(e.right)


method evaluate*(e: ast.Null): Object =
    return oNull


method evaluate*(e: ast.Self): Object =
    return lookupVariable(e.keyword, e)


method evaluate*(e: ast.Set): Object =
    let owner = evaluate(e.owner)
    let value = evaluate(e.value)
    if owner of Instance:
        Instance(owner).set(e.name, value)
        return value
    # elif owner of types.Dictionary:
    #     var dictionary = types.Dictionary(owner)
    #     let key = types.String(value: e.name.lexeme)
    #     if dictionary.elements.hasKey(key.hash()):
    #         dictionary.elements[key.hash()] = types.HashPair(key: key, value: value)
    #         # TODO: check if is it neccesary to update the environment.
    #         if i.locals.hasKey(e):
    #             let distance = i.locals[e]
    #             i.environment.assignAt(distance, e.owner, dictionary)
    #         else:
    #             i.globals.assign(e.owner, dictionary)
    #         return value

    raiseError(e.name, "Only instances have fields.")


method evaluate*(e: ast.String): Object =
    return types.String(value: e.value)


method evaluate*(e: ast.StringFormat): Object =
    # iterate words and variables at the same time with zip
    let varAndWord = zip(e.words, e.variables)
    var source = e.source
    for vw in varAndWord:
        let res = stringify(evaluate(vw[1]))        
        source = replace(source, vw[0], res)

    return types.String(value: source)


method evaluate*(e: ast.Super): Object =
    let distance = i.locals[e]
    let superclass = types.Class(i.environment.getAt(distance, "super"))
    let instance = types.Instance(i.environment.getAt(distance-1, "self"))
    let method2 = superclass.findMethod(e.methodName.lexeme)

    if method2 == nil:
        raiseError(e.methodName, "Undefined property '" & e.methodName.lexeme & "'")
    return method2.bindFunction(instance)


method evaluate*(e: ast.Unary): Object =
    let right = evaluate(e.right)
    case e.operator.kind:
    of tkBang:
        return nativeBoolToBooleanObject(not isTruthy(right))
    of tkMinus:
        checkNumberOperand(e.operator, right)
        if right of types.Integer:
            return types.Integer(value: -types.Integer(right).value)
        else:
            return types.Float(value: -types.Float(right).value)
    else:
        return oNull


method evaluate*(e: ast.Variable): Object =
    result = lookupVariable(e.name, e)


# ================================================================== #
# Statement execution methods implementation
# ================================================================== #
method execute(n: ast.Stmt): void {.base.} =
    raise newException(Exception, "Unknown Node type: " & repr(n))


method execute(s: ast.Block): void =
    i.executeBlock(s.statements, newEnclosedEnv(i.environment))


method execute(s: ast.Break): void =
    raise types.BreakObj()


method execute*(s: ast.Class): void =
    var superclass: Object = nil
    if s.superclass != nil:
        superclass = evaluate(s.superclass)
        if not (superclass of types.Class):
            raiseError(s.superclass.name, "Superclass must be a class.")
    
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


method execute*(s: ast.Continue): void =
    raise types.ContinueObj()


method execute*(s: ast.Defer): void =
    execute(s.body)


method execute*(s: ast.Enum): void =
    var enumTable: types.Enum = new types.Enum
    enumTable.elements = s.elements

    i.environment.define(s.name.lexeme, enumTable)


method execute*(s: ast.Expression): void =
    discard evaluate(s.expression)


method execute*(s: ast.For): void =
    let collection = evaluate(s.collection)
    if collection == nil:
        raiseError(s.keyword, "Invalid collection type.")
    
    if isCollection(collection):
        var forEnv = newEnclosedEnv(i.environment)
        if s.indexOrKey != nil:
            forEnv.define(s.indexOrKey.lexeme, oNull)
        
        forEnv.define(s.value.lexeme, oNull)
        # star the itaration process
        if collection of types.Array:
            executeForStmt(s, types.Array(collection), forEnv)
        elif collection of types.Integer:
            executeForStmt(s, types.Integer(collection), forEnv)
        elif collection of types.String:
            executeForStmt(s, types.String(collection), forEnv)
        elif collection of types.Dictionary:
            executeForStmt(s, types.Dictionary(collection), forEnv)
        elif collection of types.Enum:
            executeForStmt(s, types.Enum(collection), forEnv)


proc executeForStmt(s: ast.For, collection: types.Array, env: Environment): void =
    var index = 0
    var integerValue = types.Integer(value: index)
    for k in collection.elements:
        try:
            if s.indexOrKey != nil:             
                integerValue.value = index
                env.assign(s.indexOrKey, integerValue)

            env.assign(s.value, k)
            i.executeBlock(s.body, env)
            inc(index)
        except types.Return, BreakObj, ContinueObj:
            let ex = getCurrentException()
            if ex of BreakObj or ex of types.Return: break
            continue


proc executeForStmt(s: ast.For, collection: types.Integer, env: Environment): void =
    var size = collection.value
    var integerValue = types.Integer(value: 0)
    for j in 0..size:
        try:
            if s.indexOrkey != nil:
                integerValue.value = j
                env.assign(s.indexOrKey, integerValue)
            env.assign(s.value, types.Integer(value: j))
            i.executeBlock(s.body, env)
        except types.Return, BreakObj, ContinueObj:
            let ex = getCurrentException()
            if ex of BreakObj or ex of types.Return: break
            continue


proc executeForStmt(s: ast.For, collection: types.String, env: Environment): void =
    var index = 0
    var integerValue = types.Integer(value: index)
    for v in collection.value:
        try:
            if s.indexOrKey != nil:
                integerValue.value = index
                env.assign(s.indexOrKey, integerValue)
            env.assign(s.value, types.String(value: $v))
            i.executeBlock(s.body, env)            
            inc(index)
        except types.Return, BreakObj, ContinueObj:
            let ex = getCurrentException()
            if ex of BreakObj or ex of types.Return: break
            continue


proc executeForStmt(s: ast.For, collection: types.Dictionary, env: Environment): void =
    for k, v in collection.elements:
        try:
            if s.indexOrKey != nil:
                env.assign(s.indexOrKey, v.key)
            env.assign(s.value, v.value)
            i.executeBlock(s.body, env)
        except types.Return, BreakObj, ContinueObj:
            let ex = getCurrentException()
            if ex of BreakObj or ex of types.Return: break
            continue


proc executeForStmt(s: ast.For, collection: types.Enum, env: Environment): void =
    var stringValue = types.String(value: "")
    for k, v in collection.elements:
        try:
            if s.indexOrKey != nil:
                stringValue.value = k
                env.assign(s.indexOrKey, stringValue)
            env.assign(s.value, types.Integer(value: v))            
            i.executeBlock(s.body, env)
        except types.Return, BreakObj, ContinueObj:
            let ex = getCurrentException()
            if ex of BreakObj or ex of types.Return: break
            continue


proc isCollection(collection: Object): bool =
    return collection of types.Enum or
            collection of types.Integer or
            collection of types.String or
            collection of types.Array or
            collection of types.Dictionary

method execute*(s: ast.Function): void =
    let function = types.Function(
        declaration: s,
        closure: i.environment,
        isInitializer: false
    )
    i.environment.define(s.name.lexeme, function)


method execute*(s: ast.If): void =
    if isTruthy(evaluate(s.condition)):
        execute(s.thenBranch)
    elif s.elseBranch != nil:
        execute(s.elseBranch)


method execute*(s: ast.Let): void =
    var initializer: types.Object = nil
    if s.initializer != nil:
        initializer = evaluate(s.initializer)

    i.environment.define(s.name.lexeme, initializer)


method execute*(s: ast.Return): void =
    var value: types.Object = nil
    if s.value != nil:        
        value = evaluate(s.value)

    raise types.Return(
        value: value
    )


method execute*(s: ast.While): void =
    while isTruthy(evaluate(s.condition)):
        try:
            execute(s.body)
        except BreakObj, ContinueObj:
            let ex = getCurrentException()
            if ex of BreakObj: break


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
# proc isEqual(a: Object, b: Object): bool =
#     if a of types.Null and b of types.Null: return true
#     if a of types.Null: return false
#     if a of types.String and b of types.String:
#         return types.String(a).value == types.String(b).value
#     elif a of types.Integer and b of types.Integer:
#         return types.Integer(a).value == types.Integer(b).value
#     elif a of types.Float and b of types.Float:
#         return types.Float(a).value == types.Float(b).value
#     else:
#         return a == b


proc isTruthy(o: Object): bool =
    if o of types.Null: return false
    if o of types.Boolean: return types.Boolean(o).value
    return true


proc `==`(a: Object, b: Object): bool =
    if a of types.Null and b of types.Null: return true
    if a of types.String and b of types.String:
        return types.String(a).value == types.String(b).value
    elif a of types.Integer and b of types.Integer:
        return types.Integer(a).value == types.Integer(b).value
    elif a of types.Float and b of types.Float:
        return types.Float(a).value == types.Float(b).value
    elif a of types.Boolean and b of types.Boolean:
        return types.Boolean(a).value == types.Boolean(b).value
    else:
        return false


proc checkNumberOperands(operator: Token, left: Object, right: Object): void =
    if isNumber(left) and isNumber(right):
        return
    raiseError(operator, "Operands must be numbers.")


proc checkNumberOperand(operator: Token, operand: Object): void =
    if isNumber(operand):
        return
    raiseError(operator, "Operand must be number.")


proc lookupVariable(name: Token, exp: ast.Expr): Object =
    if i.locals.hasKey(exp):
        let distance = i.locals[exp]
        return i.environment.getAt(distance, name.lexeme)
    else:
        return i.globals.get(name)


proc nativeBoolToBooleanObject(value: bool): types.Boolean =
    if value:
        return oTrue
    else:
        return oFalse


proc raiseError(t: Token, m: string): void =
    raise RuntimeError(token: t, message: m)


proc raiseError(m: string): void =
    raise RuntimeError(message: m)


proc isNumber(o: types.Object): bool =
    return o of types.Integer or o of types.Float


proc isFloat(o: varargs[types.Object]): bool =
    for obj in o:
        if obj of types.Float: return true
    return false