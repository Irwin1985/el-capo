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
        i += 1

    result &= "]"

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
        i += 1
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
        i += 1
    output.add("}")

    return output


# ================================================ #
# Grouping expression
# ================================================ #
method eval(e: Grouping): string =
    return eval(e.expression)


# ================================================ #
# Identifier
# ================================================ #
method eval(e: Variable): string =
    return e.name.lexeme


# ================================================ #
# Integer Literal
# ================================================ #
method eval(e: Integer): string = 
    return $e.value


# ================================================ #
# Float Literal
# ================================================ #
method eval(e: Float): string =
    return $e.value


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
# Block
# ================================================ #
method eval(b: Block): string =
    return "block"


# ================================================ #
# Expression
# ================================================ #
method eval(e: Expression): string =
    return eval(e.expression)

# ================================================ #
# Get Expression
# ================================================ #
method eval(e: Get): string =
    return "(" & eval(e.owner) &  "." & e.name.lexeme & ")"

# ================================================ #
# Assign Expression (a = b)
# ================================================ #
method eval(e: Assign): string =
    return e.name.lexeme & " = " & eval(e.value)

# ================================================ #
# Set Expression
# ================================================ #
method eval(e: Set): string =
    return eval(e.owner) & "." & e.name.lexeme & " = " & eval(e.value)


# ================================================ #
# Unary Expression
# ================================================ #
method eval(e: Unary): string =
    let right = eval(e.right)
    case e.operator.kind:
    of tkMinus: return "(-" & right & ")"
    of tkBang: return "(!" & right & ")"
    else: return ""


# ======================================================================================= #
# Statements
# ======================================================================================= #

# ================================================ #
# Let Statement
# ================================================ #
method eval(s: Let): string =
    if s.initializer != nil:
        return "let " & s.name.lexeme & " = " & eval(s.initializer)
    return "let " & s.name.lexeme