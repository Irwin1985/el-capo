import tables
import hashes
type
    Expr = ref object of RootObj
    Integer = ref object of Expr
        value: int
    String = ref object of Expr
        value: string
    Boolean = ref object of Expr
        value: bool
    Dictionary = ref object of Expr
        elements: Table[Expr, Expr]

proc hash*(n: Expr): Hash =
    var h: Hash = 0
    if n of Integer:
        h = h !& Integer(n).value.hash        
    elif n of String:
        h = h !& String(n).value.hash        
    elif n of Boolean:
        let value: int = if Boolean(n).value: 1 else : 0
        h = h !& value.hash        
    return h

    # if n of Integer:
    #     return !$Integer(n).value.hash
    # elif n of String:
    #     return !$String(n).value.hash
    # elif n of Boolean:
    #     if Boolean(n).value: return !$1.hash else: return !$0.hash


proc `$`*(n: Expr): string =
    if n of Integer:
        return $Integer(n).value
    elif n of String:
        return String(n).value
    elif n of Boolean:
        if Boolean(n).value: return "true" else: return "false"

let number = Integer(value: 10)
let boolean = Boolean(value: true)
let name = String(value: "Irwin")
let age = Integer(value: 36)

let data = new Dictionary
data.elements = Table[Expr, Expr]()

data.elements[number] = boolean
data.elements[name] = age

for k, v in data.elements:
    echo $k
    echo $v

