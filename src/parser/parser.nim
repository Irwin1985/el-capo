import strutils
import std/strformat
import std/tables
import std/hashes
import ../token/token
import ../lexer/lexer
import ../ast/ast
import ../utils/utils
import ../utils/error

const
    lowest      = 1
    assignment  = 2
    logic_or    = 3
    logic_and   = 4
    equality    = 5
    comparison  = 6
    term        = 7
    factor      = 8
    power       = 9
    unary       = 10
    call        = 11
    index       = 12


var precedence = {
    TokenKind.tkEqual: assignment,
    TokenKind.tkOr: logic_or,
    TokenKind.tkAnd: logic_and,
    TokenKind.tkEqualEqual: equality,
    TokenKind.tkBangEqual: equality,
    TokenKind.tkLess: comparison,
    TokenKind.tkLessEqual: comparison,
    TokenKind.tkGreater: comparison,
    TokenKind.tkGreaterEqual: comparison,
    TokenKind.tkIn: comparison,
    TokenKind.tkPlus: term,
    TokenKind.tkPlusEqual: term,
    TokenKind.tkMinus: term,
    TokenKind.tkMinusEqual: term,
    TokenKind.tkStar: factor,
    TokenKind.tkStarEqual: factor,
    TokenKind.tkSlash: factor,
    TokenKind.tkSlashEqual: factor,
    TokenKind.tkModulo: factor,
    TokenKind.tkPower: power,
    TokenKind.tkLeftParen: call,
    TokenKind.tkLeftBracket: index,
    TokenKind.tkDot: index
}.toTable

type
    ParseError* = object of Exception
    Parser* = ref object of RootObj
        l: Lexer
        curToken: Token
        peekToken: Token
        prevToken: Token

    PrefixParseFn = proc(p: Parser): ast.Expr
    InfixParseFn = proc(p: Parser, left: ast.Expr): ast.Expr    

var 
    prefixParseFns = initTable[TokenKind, PrefixParseFn]()
    infixParseFns = initTable[TokenKind, InfixParseFn]()

# ================================================== #
# Parser forwarded proc
# ================================================== #
proc newParser*(l: Lexer): Parser
proc parse*(p: Parser): ast.Program
# proc parseModules(p: Parser): seq[ast.Module]
# ================================================== #
# Parsing Declarations procedures
# ================================================== #
proc parseDeclaration(p: Parser): ast.Stmt
proc parseLetDeclaration(p: Parser): ast.Let
proc parseFunctionDeclaration(p: Parser, kind: string): ast.Function
proc parseClassDeclaration(p: Parser): ast.Class
# ================================================== #
# Parsing Statements procedures
# ================================================== #
proc parseStatement(p: Parser): ast.Stmt
proc parseIfStatement(p: Parser): ast.Stmt
proc parserReturnStatement(p: Parser): ast.Stmt
proc parseBlockStatement(p: Parser): seq[ast.Stmt]
proc parseForStatement(p: Parser): ast.Stmt
proc parseWhileStatement(p: Parser): ast.Stmt
proc parseBreakStatement(p: Parser): ast.Stmt
proc parseContinueStatement(p: Parser): ast.Stmt
proc parseDeferStatement(p: Parser): ast.Stmt
proc parseExpressionStatement(p: Parser): ast.Stmt
# ================================================== #
# Parsing Expressions procedures
# ================================================== #
proc parseExpression(p: Parser, precedence: int): ast.Expr
proc parseArrayLiteral(p: Parser): ast.Expr
proc parseAssignment(p: Parser, left: ast.Expr): ast.Expr
proc parseBinaryExpression(p: Parser, left: ast.Expr): ast.Expr
proc parseBooleanLiteral(p: Parser): ast.Expr
proc parseCallExpression(p: Parser, left: ast.Expr): ast.Expr
proc parseDictionary(p: Parser): ast.Expr
proc parseFloatLiteral(p: Parser): ast.Expr
proc parseGetExpression(p: Parser, left: ast.Expr): ast.Expr
proc parseGroupedExpression(p: Parser): ast.Expr
proc parseIndexExpression(p: Parser, left: ast.Expr): ast.Expr
proc parseIntegerLiteral(p: Parser): ast.Expr
proc parseLogicalExpression(p: Parser, left: ast.Expr): ast.Expr
proc parseNullLiteral(p: Parser): ast.Expr
proc parseSelfExpression(p: Parser): ast.Expr
proc parseStringFormat(p: Parser): ast.Expr
proc parseStringLiteral(p: Parser): ast.Expr
proc parseSuperExpression(p: Parser): ast.Expr
proc parseUnaryExpression(p: Parser): ast.Expr
proc parseVariableExpression(p: Parser): ast.Expr
# ================================================== #
# Parser helper procedures
# ================================================== #
proc match(p: Parser, types: varargs[TokenKind]): bool
proc consume(p: Parser, kind: TokenKind, message: string): Token
proc check(p: Parser, kind: TokenKind): bool
proc advance(p: Parser): Token
proc isAtEnd(p: Parser): bool
proc previous(p: Parser): Token
proc error(p: Parser, message: string)
proc error(p: Parser, t: Token, message: string)
proc synchronize(p: Parser): void
proc curPrecedence(p: Parser): int
proc getInfixTokens(): string

# ================================================== #
# Register prefix parsing functions
# ================================================== #
prefixParseFns[TokenKind.tkIdentifier] = parseVariableExpression
prefixParseFns[TokenKind.tkInteger] = parseIntegerLiteral
prefixParseFns[TokenKind.tkFloat] = parseFloatLiteral
prefixParseFns[TokenKind.tkString] = parseStringLiteral
prefixParseFns[TokenKind.tkStringFormat] = parseStringFormat
prefixParseFns[TokenKind.tkBang] = parseUnaryExpression
prefixParseFns[TokenKind.tkMinus] = parseUnaryExpression
prefixParseFns[TokenKind.tkTrue] = parseBooleanLiteral
prefixParseFns[TokenKind.tkFalse] = parseBooleanLiteral
prefixParseFns[TokenKind.tkNull] = parseNullLiteral
prefixParseFns[TokenKind.tkLeftParen] = parseGroupedExpression
prefixParseFns[TokenKind.tkLeftBracket] = parseArrayLiteral
prefixParseFns[TokenKind.tkLeftBrace] = parseDictionary
prefixParseFns[TokenKind.tkSelf] = parseSelfExpression
prefixParseFns[TokenKind.tkSuper] = parseSuperExpression
# ================================================== #
# Register infix parsing functions
# ================================================== #
infixParseFns[TokenKind.tkPlus] = parseBinaryExpression
infixParseFns[TokenKind.tkPlusEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkMinus] = parseBinaryExpression
infixParseFns[TokenKind.tkMinusEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkStar] = parseBinaryExpression
infixParseFns[TokenKind.tkStarEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkSlash] = parseBinaryExpression
infixParseFns[TokenKind.tkSlashEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkModulo] = parseBinaryExpression
infixParseFns[TokenKind.tkPower] = parseBinaryExpression
infixParseFns[TokenKind.tkEqualEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkBangEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkLess] = parseBinaryExpression
infixParseFns[TokenKind.tkLessEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkGreater] = parseBinaryExpression
infixParseFns[TokenKind.tkGreaterEqual] = parseBinaryExpression
infixParseFns[TokenKind.tkIn] = parseBinaryExpression
infixParseFns[TokenKind.tkEqual] = parseAssignment
infixParseFns[TokenKind.tkLeftParen] = parseCallExpression
infixParseFns[TokenKind.tkLeftBracket] = parseIndexExpression
infixParseFns[TokenKind.tkDot] = parseGetExpression
infixParseFns[TokenKind.tkOr] = parseLogicalExpression
infixParseFns[TokenKind.tkAnd] = parseLogicalExpression

# ================================================== #
# Parser implementation
# ================================================== #
proc newParser*(l: Lexer): Parser =
    new result
    result.l = l
    discard result.advance()
    discard result.advance()


proc parse*(p: Parser): ast.Program =
    var statements: seq[Stmt] = newSeq[Stmt]()
    while not p.isAtEnd():
        statements.add(p.parseDeclaration())

    return Program(statements: statements)


# proc parseModules(p: Parser): seq[ast.Module] =
#     discard


proc parseDeclaration(p: Parser): ast.Stmt =
    try:
        if p.match(TokenKind.tkLet):
            return p.parseLetDeclaration()
        elif p.match(TokenKind.tkDef):
            return p.parseFunctionDeclaration("function")
        elif p.match(TokenKind.tkClass):
            return p.parseClassDeclaration()
        return p.parseStatement()
    except ParseError:
        p.synchronize()
        return nil


proc parseLetDeclaration(p: Parser): ast.Let =
    let letNode = new Let
    letNode.name = p.consume(TokenKind.tkIdentifier, "Expecting `identifier` (e.g. `let x`)")    
    if p.match(TokenKind.tkEqual):
        letNode.initializer = p.parseExpression(lowest)

    discard p.consume(TokenKind.tkSemicolon, "Expecting `newline` after variable declaration.")

    return letNode


proc parseFunctionDeclaration(p: Parser, kind: string): ast.Function =
    let funcNode = new Function

    funcNode.name = p.consume(TokenKind.tkIdentifier, "Expecting `" & kind & "` name.")    
    funcNode.params = newSeq[Token]()
    funcNode.varArgs = false

    if p.match(TokenKind.tkLeftParen):
        if not p.check(TokenKind.tkRightParen):
            dowhile p.match(TokenKind.tkComma):
                funcNode.params.add(p.consume(TokenKind.tkIdentifier, "Expecting parameter name."))
                if p.check(TokenKind.tkEllipsis) and p.peekToken.kind == TokenKind.tkComma:
                    p.error(p.curToken, "Variadic parameter must be at the end of parameter list.")
            funcNode.varArgs = p.match(TokenKind.tkEllipsis)
        discard p.consume(TokenKind.tkRightParen, "Expecting `)` after parameters (e.g. `(...)`)")

    discard p.consume(TokenKind.tkColon, "Expecting ':' before " & kind & " body.")
    funcNode.body = p.parseBlockStatement()

    return funcNode


proc parseClassDeclaration(p: Parser): ast.Class =
    let classNode = new Class

    classNode.name = p.consume(TokenKind.tkIdentifier, "Expecting class name.")
    classNode.properties = newSeq[Let]()
    classNode.methods = newSeq[Function]()

    # check for inheritance
    if p.match(TokenKind.tkLeftParen):
        discard p.consume(TokenKind.tkIdentifier, "Expecting `superclass` name (e.g. `class a(b)`)")
        let variableNode = new Variable
        variableNode.name = p.previous()
        classNode.superclass = variableNode
        discard p.consume(TokenKind.tkRightParen, "Expecting `)` after superclass name (e.g. `class a(b)`)")

    discard p.consume(TokenKind.tkColon, "Expecting ':' before class body.")

    if not p.match(TokenKind.tkPass):
        # get the first token indent
        let classIndent = p.curToken.col

        # classBody ::= varDeclaration* methodDeclaration*
        while not p.isAtEnd() and p.curToken.col == classIndent:
            # parsing class methods
            while p.curToken.col == classIndent and p.match(TokenKind.tkDef):
                classNode.methods.add(p.parseFunctionDeclaration("method"))

    return classNode


proc parseStatement(p: Parser): ast.Stmt =
    if p.match(TokenKind.tkIf): return p.parseIfStatement()
    if p.match(TokenKind.tkReturn): return p.parserReturnStatement()
    if p.match(TokenKind.tkColon): return ast.Block(statements: p.parseBlockStatement())
    if p.match(TokenKind.tkFor): return p.parseForStatement()
    if p.match(TokenKind.tkWhile): return p.parseWhileStatement()
    if p.match(TokenKind.tkBreak): return p.parseBreakStatement()
    if p.match(TokenKind.tkContinue): return p.parseContinueStatement()
    if p.match(TokenKind.tkDefer): return p.parseDeferStatement()
    return p.parseExpressionStatement()


proc parseIfStatement(p: Parser): ast.Stmt =
    let ifNode = new If
    ifNode.condition = p.parseExpression(lowest)
    ifNode.thenBranch = p.parseStatement()
    
    if p.match(TokenKind.tkElse):
        ifNode.elseBranch = p.parseStatement()
    
    return ifNode


proc parserReturnStatement(p: Parser): ast.Stmt =
    let returnNode = new Return
    returnNode.keyword = p.previous()

    if not p.check(TokenKind.tkSemicolon):
        returnNode.value = p.parseExpression(lowest)
    
    discard p.consume(TokenKind.tkSemicolon, "Expecting `newline` after return value.")

    return returnNode


proc parseBlockStatement(p: Parser): seq[ast.Stmt] =
    var statements = newSeq[Stmt]()

    var blockColumn = p.curToken.col

    while p.curToken.col == blockColumn and not p.isAtEnd():
        statements.add(p.parseDeclaration())

    return statements


proc parseForStatement(p: Parser): ast.Stmt =
    let forNode = new For

    forNode.keyword = p.previous()

    if p.peekToken.kind == TokenKind.tkComma:
        forNode.indexOrKey = p.consume(TokenKind.tkIdentifier, "Expecting index or key (e.g `for x, y in ...`)")
        discard p.advance() # ',' already checked

    forNode.value = p.consume(TokenKind.tkIdentifier, "Expecting value target (e.g `for x, y in ...`)")
    discard p.consume(TokenKind.tkIn, "Expecting the `in` keyword.")
    forNode.collection = p.parseExpression(lowest)
    forNode.body = p.parseBlockStatement()

    return forNode


proc parseWhileStatement(p: Parser): ast.Stmt =
    let whileNode = new While

    if p.match(TokenKind.tkLeftParen):
        whileNode.condition = p.parseExpression(lowest)
        discard p.consume(TokenKind.tkRightParen, "Expecting `)` after while condition.")
    else:
        whileNode.condition = p.parseExpression(lowest)

    whileNode.body = p.parseStatement()

    return whileNode


proc parseBreakStatement(p: Parser): ast.Stmt =
    let breakNode = new Break
    discard p.consume(TokenKind.tkSemicolon, "Expecting `newline` after break.")

    return breakNode


proc parseContinueStatement(p: Parser): ast.Stmt =
    let continueNode = new Continue
    discard p.consume(TokenKind.tkSemicolon, "Expecting `newline` after continue.")
    return continueNode


proc parseDeferStatement(p: Parser): ast.Stmt =
    let deferNode = new Defer
    deferNode.body = p.parseStatement()

    return deferNode


proc parseExpressionStatement(p: Parser): ast.Stmt =
    var expStmtNode = new Expression
    expStmtNode.expression = p.parseExpression(lowest)
    discard p.consume(TokenKind.tkSemicolon, "Expecting `newline` after expression.")    

    return expStmtNode

# ================================================== #
# Parsing Expressions procedures
# ================================================== #
proc parseExpression(p: Parser, precedence: int): ast.Expr =
    var 
        prefix: PrefixParseFn = nil
        leftExp: ast.Expr = nil

    if prefixParseFns.hasKey(p.curToken.kind):
        prefix = prefixParseFns[p.curToken.kind]        
    else:
        p.error("Invalid expression: unexpected token `" & p.curToken.lexeme & "`")
        return nil
        
    leftExp = p.prefix()
    
    while not p.check(TokenKind.tkSemicolon) and precedence < p.curPrecedence():
        if infixParseFns.hasKey(p.curToken.kind):
            var infix = infixParseFns[p.curToken.kind]
            leftExp = p.infix(leftExp)
        else:
            return leftExp

    return leftExp


proc parseArrayLiteral(p: Parser): ast.Expr =
    let arrayNode = new Array
    arrayNode.keyword = p.advance()
    arrayNode.elements = newSeq[Expr]()

    if not p.check(TokenKind.tkRightBracket):
        dowhile p.match(TokenKind.tkComma):
            arrayNode.elements.add(p.parseExpression(lowest))
    
    discard p.consume(TokenKind.tkRightBracket, "Expecting `]` after array elements.")

    return arrayNode


#[
    assignment = identifier '=' expression
    identifier '=' expression                   <- Assignment
    identifier ('.' identifier)? '=' expression <- Set
]#
proc parseAssignment(p: Parser, left: ast.Expr): ast.Expr =
    let equals: Token = p.advance() # the '=' token
    let value: Expr = p.parseExpression(lowest)
    if left of Variable:
        let assignNode = new Assign
        assignNode.name = Variable(left).name
        assignNode.value = value
        return assignNode
    elif left of Get:
        let setNode = new Set
        let get: Get = Get(left) # cast left into Get
        setNode.owner = get.owner
        setNode.name = get.name
        setNode.value = value

        return setNode

    p.error(equals, "Invalid assignment target.")


proc parseBinaryExpression(p: Parser, left: ast.Expr): ast.Expr =
    let binaryNode = new Binary

    let operator: Token = p.curToken
    let precedence: int = p.curPrecedence()
    discard p.advance()
    let right: Expr = p.parseExpression(precedence)

    if operator.kind in [TokenKind.tkPlusEqual, TokenKind.tkMinusEqual, 
                         TokenKind.tkStarEqual, TokenKind.tkSlashEqual]:
        # it's an incrementer operator (+=, -=, *=, /=)
        let binaryIncNode = new BinaryInc
        binaryIncNode.left = left
        binaryIncNode.operator = operator
        binaryIncNode.right = right
        return binaryIncNode

    # return the BinaryNode
    binaryNode.left = left
    binaryNode.operator = operator
    binaryNode.right = right

    return binaryNode


proc parseBooleanLiteral(p: Parser): ast.Expr =
    let booleanNode = new Boolean
    booleanNode.value = (p.advance().kind == TokenKind.tkTrue)

    return booleanNode


proc parseCallExpression(p: Parser, left: ast.Expr): ast.Expr =
    let callNode = new Call
    callNode.callee = left

    discard p.advance()
    callNode.arguments = newSeq[Expr]()
    if not p.check(TokenKind.tkRightParen):
        dowhile p.match(TokenKind.tkComma):
            callNode.arguments.add(p.parseExpression(lowest))
    
    callNode.paren = p.consume(TokenKind.tkRightParen, "Expecting `)` after arguments.")
    return callNode


proc parseDictionary(p: Parser): ast.Expr =
    # check for Dictionary or Enum expression
    let keyword: Token = p.advance()
    if p.peekToken.kind == TokenKind.tkColon: # it's a Dictionary!        
        var dictionaryNode: Dictionary = new Dictionary
        dictionaryNode.keyword = keyword
        dictionaryNode.elements = initTable[Expr, Expr]()
        
        if not p.check(TokenKind.tkRightBrace):
            dowhile p.match(TokenKind.tkComma):
                var key = p.parseExpression(lowest)
                if not key.isHashable():
                    raise newException(ParseError, "Invalid type for dictionary key.")
                
                discard p.consume(TokenKind.tkColon, "Expecting `:` after key definition.")
                dictionaryNode.elements[key] = p.parseExpression(lowest)                

        discard p.consume(TokenKind.tkRightBrace, "Expecting `}` after dictionary elements.")
        return dictionaryNode
    elif p.peekToken.kind == TokenKind.tkComma: # it's an Enum!
        let enumNode: Enum = new Enum
        enumNode.elements = initTable[string, int]()
        var i:int = 0
        dowhile p.match(TokenKind.tkComma):
            discard p.consume(TokenKind.tkIdentifier, "Expecting IDENTIFIER as enumeration")
            enumNode.elements[p.previous().lexeme] = i
            i += 1
        discard p.consume(TokenKind.tkRightBrace, "Expecting `}` after enum elements.")
        return enumNode
    else:
        raise newException(ParseError, "Sintax error.")
    discard


proc parseFloatLiteral(p: Parser): ast.Expr =
    let floatNode = new Float
    floatNode.value = p.advance().floatValue
    return floatNode


proc parseGetExpression(p: Parser, left: ast.Expr): ast.Expr =
    let getNode = new Get
    getNode.owner = left
    discard p.advance() # the '.' token
    getNode.name = p.consume(TokenKind.tkIdentifier, "Expecting property name after `.` (e.g. `property.name`)")
    return getNode


proc parseGroupedExpression(p: Parser): ast.Expr =
    let groupingNode = new Grouping

    discard p.advance() # the '(' token
    groupingNode.expression = p.parseExpression(lowest)
    discard p.consume(TokenKind.tkRightParen, "Expecting `)` after expression.")

    return groupingNode


proc parseIndexExpression(p: Parser, left: ast.Expr): ast.Expr =
    let indexNode = new Index
    let keyword: Token = p.advance() # the '[' token
    let index: Expr = p.parseExpression(lowest)
    discard p.consume(TokenKind.tkRightBracket, "Expecting `]` after expression.")

    if p.match(TokenKind.tkEqual):
        if left of Variable:
            # now create the AssignCollection Node
            let assignCollectionNode = new AssignCollection
            assignCollectionNode.keyword = keyword
            assignCollectionNode.left = Variable(left)
            assignCollectionNode.index = index
            assignCollectionNode.value = p.parseExpression(lowest)

            return assignCollectionNode

        # if left hand side is not a Variable node then syntax error.
        p.error("Invalid expression for collection accesor.")

    # just return the indexNode
    indexNode.keyword = keyword
    indexNode.left = left
    indexNode.index = index
    return indexNode


proc parseIntegerLiteral(p: Parser): ast.Expr =
    let integerNode = new Integer
    integerNode.value = p.advance().intValue
    
    return integerNode


proc parseLogicalExpression(p: Parser, left: ast.Expr): ast.Expr =
    let logicalNode = new Logical

    logicalNode.operator = p.advance()
    let precedence = p.curPrecedence()
    logicalNode.right = p.parseExpression(precedence)

    return logicalNode



proc parseNullLiteral(p: Parser): ast.Expr =
    let nullNode = new Null
    discard p.advance()
    return nullNode


proc parseSelfExpression(p: Parser): ast.Expr =
    let selfNode = new Self
    selfNode.keyword = p.advance()

    return selfNode


proc parseStringFormat(p: Parser): ast.Expr =
    let keyword = p.advance()
    let source = keyword.lexeme & " "
    var parsingString = false
    var builder: string
    var variables: seq[ast.Expr] = newSeq[ast.Expr]()
    var words: seq[string] = newSeq[string]()

    for c in source:
        if parsingString:
            if utils.isIdentifier(c) or c == '.':
                builder.add(c)
                continue
            else:
                parsingString = false
                if builder.len > 0:
                    let expression = builder
                    let l = newLexer(expression & '\n')
                    let tempParser = newParser(l)
                    let node = tempParser.parseExpression(lowest)
                    variables.add(node)
                    words.add("$" & expression)
        
        if c == '$':
            builder = ""
            parsingString = true        
    
    return StringFormat(
        variables: variables,
        words: words,
        source: source
    )


proc parseStringLiteral(p: Parser): ast.Expr =
    let stringLiteralNode = new String
    stringLiteralNode.value = p.advance().lexeme

    return stringLiteralNode


proc parseSuperExpression(p: Parser): ast.Expr =
    let superNode = new Super

    superNode.keyword = p.advance()
    discard p.consume(TokenKind.tkDot, "Expecting `.` after `super` (e.g `super.method()`)")
    superNode.methodName = p.consume(TokenKind.tkIdentifier, "Expecting superclass method name.")

    return superNode


proc parseUnaryExpression(p: Parser): ast.Expr =
    let unaryNode = new Unary
    unaryNode.operator = p.advance()
    unaryNode.right = p.parseExpression(unary)

    return unaryNode


proc parseVariableExpression(p: Parser): ast.Expr =
    let variableNode = new Variable
    variableNode.name = p.advance()
    return variableNode

# ================================================== #
# Parser helper procedures
# ================================================== #
proc match(p: Parser, types: varargs[TokenKind]): bool =
    for t in types:
        if p.check(t):
            discard p.advance()
            return true
    return false


proc consume(p: Parser, kind: TokenKind, message: string): Token =
    if p.check(kind): return p.advance()
    p.error(message)
    # raise ParseError.newException(message)


proc check(p: Parser, kind: TokenKind): bool =
    return p.curToken.kind == kind


proc advance(p: Parser): Token =
    p.prevToken = p.curToken
    p.curToken = p.peekToken
    p.peekToken = p.l.nextToken()

    return p.previous()


proc isAtEnd(p: Parser): bool =
    return p.curToken.kind == TokenKind.tkEof


proc previous(p: Parser): Token =
    return p.prevToken


proc error(p: Parser, message: string) =
    error.error(p.curToken, message)
    raise ParseError.newException(message)


proc error(p: Parser, t: Token, message: string) =
    error.error(t, message)
    raise ParseError.newException(message) 
    

proc synchronize(p: Parser): void =
    discard p.advance()
    while not p.isAtEnd():
        if p.previous().kind == TokenKind.tkSemicolon: return
        case p.curToken.kind:
        of tkClass, tkDef, tkLet, tkFor, tkIf, tkWhile, tkReturn: return
        else:
            discard
        discard p.advance()


proc curPrecedence(p: Parser): int =
    if precedence.hasKey(p.curToken.kind):
        return precedence[p.curToken.kind]
    return lowest

proc getInfixTokens: string =
    return fmt"`+`, `-`, `*`, `/`, etc"