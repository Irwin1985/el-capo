import ../token/token
import ast
import tables


method eval(n: Node): string {.base.} =
    raise newException(Exception, "Unknown Node type: " & repr(n))


proc print*(statements: seq[Stmt]): string =
    var output: seq[string] = newSeq[string]()    

    for s in statements:
        output.add(eval(s))

    for o in output:
        result = result & o


# ================================================ #
# Array Literal
# ================================================ #
method eval(e: Array): string =
    result = "["
    var i:int = 0
    for elem in e.elements:
        if i > 0:
            result &= ", " & eval(elem)
        else:
            result &= eval(elem)
        inc(i)

    result &= "]"


# ================================================ #
# Assign Expression (a = b)
# ================================================ #
method eval(s: Assign): string =
    return s.name.lexeme & " = " & eval(s.value)


# ================================================ #
# AssignCollection
# ================================================ #
method eval(e: AssignCollection): string =
    return eval(e.left) & "[" & eval(e.index) & "] = " & eval(e.value)

# ================================================ #
# Binary Expression
# ================================================ #
method eval(e: Binary): string =
    let lhs: string = eval(e.left)
    let rhs: string = eval(e.right)
    var ope: string = ""
    case e.operator.kind:
    of tkPlus: ope = "+"
    of tkMinus: ope = "-"
    of tkStar: ope = "*"
    of tkSlash: ope = "/"
    of tkPower: ope = "^"    
    of tkModulo: ope = "%"
    of tkEqual: ope = "="
    of tkEqualEqual: ope = "=="
    of tkBangEqual: ope = "!="
    of tkLess: ope = "<"
    of tkLessEqual: ope = "<="
    of tkGreater: ope = ">"
    of tkGreaterEqual: ope = ">="
    of tkIn: ope = "in"
    else:
        ope = "||"

    return "(" & lhs & " " & ope & " " & rhs & ")"


# ================================================ #
# Binary Incremental Expression
# ================================================ #
method eval(e: BinaryInc): string =
    let lhs: string = eval(e.left)
    let rhs: string = eval(e.right)
    var ope: string = ""
    case e.operator.kind:
    of tkPlusEqual: ope = "+="
    of tkMinusEqual: ope = "-="
    of tkStarEqual: ope = "*="
    of tkSlashEqual: ope = "/="
    else:
        ope = "||"

    return "(" & lhs & " " & ope & " " & rhs & ")"


# ================================================ #
# Boolean
# ================================================ #
method eval(e: Boolean): string =
    return if e.value : "true" else: "false"


# ================================================ #
# Call
# ================================================ #
method eval(e: Call): string =
    var arguments: string = ""
    var i: int = 0
    for arg in e.arguments:
        if i > 0:
            arguments &= ", " & eval(arg)
        else:
            arguments &= eval(arg)
        inc(i)
    return eval(e.callee) & "(" & arguments & ")"

# ================================================ #
# Dictionary Expression
# ================================================ #
method eval(e: Dictionary): string =
    var 
        output: string
        i: int = 0

    output.add("{")    
    for k,v in e.elements:
        if i > 0:
            output.add(",")
        output.add("\"" & $k & "\"" & ":" & $v)    
        inc(i)
    output.add("}")

    return output

# ================================================ #
# Enum expression
# ================================================ #
method eval(e: Enum): string =
    var
        output: string
        i: int = 0
    
    output.add("{")
    for k, v in e.elements:
        if i > 0:
            output.add(",")
        inc(i)
        output.add(k & "=" & $v)
    output.add("}")
    return output


# ================================================ #
# Float Literal
# ================================================ #
method eval(e: Float): string =
    return $e.value


# ================================================ #
# Get Expression
# ================================================ #
method eval(e: Get): string =
    return "(" & eval(e.owner) &  "." & e.name.lexeme & ")"


# ================================================ #
# Grouping expression
# ================================================ #
method eval(e: Grouping): string =
    return eval(e.expression)


# ================================================ #
# Index
# ================================================ #
method eval(e: Index): string =
    return eval(e.left) & "[" & eval(e.index) & "]"


# ================================================ #
# Integer Literal
# ================================================ #
method eval(e: Integer): string = 
    return $e.value


# ================================================ #
# Binary logical expression
# ================================================ #
method eval(e: Logical): string =
    let lhs: string = eval(e.left)
    let rhs: string = eval(e.right)
    var ope: string
    if e.operator.kind == tkAnd:
        ope = "and"
    else:
        ope = "or"
    
    return "(" & lhs & " " & ope & " " & rhs & ")"


# ================================================ #
# Null
# ================================================ #
method eval(e: Null): string =
    return "null"


# ================================================ #
# Self Expression
# ================================================ #
method eval(e: Self): string =
    return e.keyword.lexeme


# ================================================ #
# Set Expression
# ================================================ #
method eval(e: Set): string =
    return eval(e.owner) & "." & e.name.lexeme & " = " & eval(e.value)


# ================================================ #
# String Literal
# ================================================ #
method eval(e: String): string =
    return "\"" & e.value & "\""


# ================================================ #
# StringFormat Literal
# ================================================ #
method eval(e: StringFormat): string =
    return e.source


# ================================================ #
# Super
# ================================================ #
method eval(e: Super): string =
    return e.keyword.lexeme & "." & e.methodName.lexeme


# ================================================ #
# Unary Expression
# ================================================ #
method eval(e: Unary): string =
    let right = eval(e.right)
    case e.operator.kind:
    of tkMinus: return "(-" & right & ")"
    of tkBang: return "(!" & right & ")"
    else: return ""


# ================================================ #
# Identifier
# ================================================ #
method eval(e: Variable): string =
    return e.name.lexeme


# ======================================================================================= #
# Statements
# ======================================================================================= #

# ================================================ #
# Block
# ================================================ #
method eval(s: Block): string =
    var output: string
    output.add("{\n")
    for statement in s.statements:
        output.add(eval(statement))
        output.add("\n")

    output.add("}\n")

    return output

# ================================================ #
# Break
# ================================================ #
method eval(s: Break): string =
    return "break"

# ================================================ #
# Class
# ================================================ #
method eval(s: Class): string =
    var output: string
    output.add("class " & s.name.lexeme)
    if s.superclass != nil:
        output.add("(" & eval(s.superclass) & ")")
    output.add(":\n")
    # methods
    for m in s.methods:
        output.add(eval(m) & "\n")

    return output


# ================================================ #
# Continue
# ================================================ #
method eval(s: Continue): string =
    return "continue"


# ================================================ #
# Defer
# ================================================ #
method eval(s: Defer): string =
    return "defer"

# ================================================ #
# Expression
# ================================================ #
method eval(s: Expression): string =
    return eval(s.expression)


# ================================================ #
# For Statement
# ================================================ #
method eval(s: For): string =
    var output: string
    output.add("for ")
    output.add(s.indexOrKey.lexeme)

    if s.value != nil:
        output.add("," & s.value.lexeme)

    output.add(" in " & eval(s.collection) & ":\n")    

    for st in s.body:
        output.add(eval(st) & "\n")
    
    return output


# ================================================ #
# Function Statement
# ================================================ #
method eval(s: Function): string =
    var output: string
    output.add("def " & s.name.lexeme)
    output.add("(")
    # parameters (if it does have)
    var i = 0
    for p in s.params:
        if i > 0:
            output.add(", ")
        inc(i)
        output.add(p.lexeme)
    if s.varArgs:
        output.add("...")
    output.add("):\n")
    # body
    for b in s.body:
        output.add(eval(b) & "\n")
    
    return output

# ================================================ #
# If Statement
# ================================================ #
method eval(s: If): string =
    var output: string
    output.add("if (" & eval(s.condition) & "):\n")
    output.add(eval(s.thenBranch))
    if s.elseBranch != nil:
        output.add("\nelse:\n")
        output.add(eval(s.elseBranch))

    return output
 
# ================================================ #
# Let Statement
# ================================================ #
method eval(s: Let): string =
    if s.initializer != nil:
        return "let " & s.name.lexeme & " = " & eval(s.initializer)
    return "let " & s.name.lexeme

# ================================================ #
# Return Statement
# ================================================ #
method eval(s: Return): string =
    var output: string
    output.add("return ")
    if s.value != nil:
        output.add(eval(s.value))
    
    return output

# ================================================ #
# While Statement
# ================================================ #
method eval(s: While): string =
    var output: string
    output.add("while (" & eval(s.condition) & "):\n")
    output.add(eval(s.body))

    return output
