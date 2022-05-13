import std/strutils
import ../token/token

type
    Lexer* = ref object of RootObj
        input: string
        cur_pos: int
        peek_pos: int
        line: int
        col: int
        begin_token_col: int
        c: char
        tokAnt: TokenKind

# helpers data types
let letters = {'a'..'z', 'A'..'Z', '_'}
let digits = {'0'..'9'}
let spaces = {' ', '\r', '\t'}
const EOF = '\x00'

# ==================================================== #    
# forward procedures
# ==================================================== #
proc newLexer*(input: string): Lexer
proc nextToken*(l: var Lexer): Token
proc readNumber(l: var Lexer): Token
proc readIdentifier(l: var Lexer): Token
proc readString(l: var Lexer, kind: TokenKind): Token
proc readRawString(l: var Lexer): Token
proc advance(l: var Lexer): void
proc peek(l: var Lexer): char
proc peekNext(l: var Lexer): char
proc skipWhitespace(l: var Lexer): void
proc isMultipleComment(l: var Lexer): bool
proc isSpace(c: char): bool
proc isDigit(c: char): bool
proc isLetter(c: char): bool
proc isIdentifier(c: char): bool
proc isString(c: char): bool
proc skipSingleComment(l: var Lexer): void
proc skipMultipleComment(l: var Lexer): void
proc skipBackSlash(l: var Lexer): void
proc newToken(l: var Lexer, kind: TokenKind): Token
proc newToken(l: var Lexer, kind: TokenKind, lexeme: string): Token

# ==================================================== #
# implementation
# ==================================================== #
proc newLexer*(input: string): Lexer =
    new result
    result.input = input
    result.line = 1
    result.tokAnt = TokenKind.tkEof
    result.advance()


proc nextToken*(l: var Lexer): Token =
    while l.c != EOF:
        l.begin_token_col = l.col
        if isSpace(l.c):
            l.skipWhitespace()
            continue
        if l.c == '#':
            l.skipSingleComment()
            continue
        if l.isMultipleComment():
            l.skipMultipleComment()
            continue
        if isDigit(l.c): return l.readNumber()
        # raw string (without escaping characters)
        if l.c == 'r' and isString(l.peek()):
            return l.readRawString()
        # format string
        if l.c == 'f' and isString(l.peek()):
            l.advance(); # eat the letter 'f'
            return l.readString(TokenKind.tkStringFormat)

        if isLetter(l.c): 
            return l.readIdentifier();

        if isString(l.c): 
            return l.readString(TokenKind.tkString)

        # single character
        if l.c == '(': 
            l.advance()
            return l.newToken(TokenKind.tkLeftParen)

        if l.c == ')': 
            l.advance()
            return l.newToken(TokenKind.tkRightParen)

        if l.c == '{':
            l.advance()
            return l.newToken(TokenKind.tkLeftBrace)

        if l.c == '}':
            l.advance()
            return l.newToken(TokenKind.tkRightBrace)

        if l.c == '[':
            l.advance()
            return l.newToken(TokenKind.tkLeftBracket)

        if l.c == ']':
            l.advance()
            return l.newToken(TokenKind.tkRightBracket)

        if l.c == ',':
            l.advance()
            return l.newToken(TokenKind.tkComma)

        if l.c == ';':
            l.advance()
            return l.newToken(TokenKind.tkSemicolon)

        # backslash for line continuation code.
        if l.c == '\\':
            l.advance()
            l.skipBackSlash()
            continue

        if l.c == ':':
            l.advance()
            return l.newToken(TokenKind.tkColon)

        if l.c == '.':
            if l.peek() == '.' and l.peekNext() == '.':
                l.advance(); l.advance(); l.advance()
                return l.newToken(TokenKind.tkEllipsis)
            l.advance()
            return l.newToken(TokenKind.tkDot)

        if l.c == '%':
            l.advance()
            return l.newToken(TokenKind.tkModulo)

        if l.c == '^':
            l.advance()
            return l.newToken(TokenKind.tkPower)

        # double characters
        if l.c == '+':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkPlusEqual)
            l.advance()
            return l.newToken(TokenKind.tkPlus)

        if l.c == '-':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkMinusEqual)
            l.advance()
            return l.newToken(TokenKind.tkMinus)

        if l.c == '*':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkStarEqual)
            l.advance()
            return l.newToken(TokenKind.tkStar)

        if l.c == '/':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkSlashEqual)
            l.advance()
            return l.newToken(TokenKind.tkSlash)

        if l.c == '=':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkEqualEqual)
            l.advance()
            return l.newToken(TokenKind.tkEqual)

        if l.c == '!':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkBangEqual)
            l.advance()
            return l.newToken(TokenKind.tkBang)

        if l.c == '<':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkLessEqual)
            l.advance()
            return l.newToken(TokenKind.tkLess)

        if l.c == '>':
            if l.peek() == '=':
                l.advance(); l.advance();
                return l.newToken(TokenKind.tkGreaterEqual)
            l.advance()
            return l.newToken(TokenKind.tkGreater)

        # check for new lines
        if l.c == '\n':
            l.advance()
            if l.tokAnt != TokenKind.tkEof and (l.tokAnt != TokenKind.tkSemicolon and l.tokAnt != TokenKind.tkColon):
                return l.newToken(TokenKind.tkSemicolon)
            else:
                continue
        
        # illegal character
        let tokIllegal = l.newToken(TokenKind.tkIllegal, $l.c)
        l.advance()
        return tokIllegal

    return l.newToken(TokenKind.tkEof)


proc readNumber(l: var Lexer): Token =
    var lexeme = ""
    while isDigit(l.c) or l.c == '_':
        if l.c != '_': lexeme.add(l.c)
        l.advance()
    # check for '.' separator
    if l.c == '.':
        lexeme.add(l.c)
        l.advance()
        while isDigit(l.c):
            lexeme.add(l.c)
            l.advance()
    
    return l.newToken(TokenKind.tkNumber, lexeme)


proc readIdentifier(l: var Lexer): Token =
    let left = l.cur_pos
    while isIdentifier(l.c):
        l.advance()
    
    let right = l.cur_pos
    let lexeme = l.input[left..right-1]
    let kind = token.lookupIdent(lexeme)

    return l.newToken(kind, lexeme)


proc readString(l: var Lexer, kind: TokenKind): Token =
    let str_end = l.c
    var scanning_string_finished = false
    var lexeme: string = ""
    l.advance()

    while l.c != EOF:
        if l.c == '\\':
            l.advance()
            case l.c
            of '\\': lexeme.add('\\')
            of 't': lexeme.add('\t')
            of 'r': lexeme.add('\r')
            of '\'': lexeme.add('\'')
            of '"': lexeme.add('"')            
            else:
                # TODO: raise lexical error here.
                discard
            l.advance()
        else:
            if l.c == str_end:
                l.advance()
                scanning_string_finished = true
                break
            else:
                lexeme.add(l.c)
                l.advance()
    
    if not scanning_string_finished:
        # TODO: raise lexical error here.
        return

    return l.newToken(kind, lexeme)
        

proc readRawString(l: var Lexer): Token =
    l.advance() # eat the 'r' letter
    let str_end = l.c
    let start_pos = l.cur_pos
    l.advance()
    while l.c != str_end: l.advance()

    if l.c == EOF:
        # TODO: raise exception
        return
    
    let end_pos = l.cur_pos
    l.advance() # skip the closing string delimiter
    let lexeme: string = l.input[start_pos..end_pos]

    return l.newToken(TokenKind.tkString, lexeme)


proc advance(l: var Lexer): void =
    if l.c == '\n':
        l.line += 1
        l.col = 0

    if l.peek_pos >= len(l.input):
        l.c = EOF
    else:
        l.c = l.input[l.peek_pos]
        l.cur_pos = l.peek_pos
        l.col += 1
        l.peek_pos += 1


proc peek(l: var Lexer): char =
    if l.peek_pos >= len(l.input):
        return EOF
    return l.input[l.peek_pos]


proc peekNext(l: var Lexer): char =
    let pos = l.peek_pos + 1
    if pos >= len(l.input):
        return EOF
    return l.input[pos]


proc skipWhitespace(l: var Lexer): void =
    while l.c != EOF and isSpace(l.c):
        l.advance()


proc isMultipleComment(l: var Lexer): bool =
    return l.c == '"' and l.peek() == '"' and l.peekNext() == '"'


proc isSpace(c: char): bool =
    return c in spaces


proc isDigit(c: char): bool =
    return c in digits


proc isLetter(c: char): bool =
    return c in letters


proc isIdentifier(c: char): bool =
    return c in letters or c in digits


proc isString(c: char): bool =
    return c == '\'' or c == '"'


proc skipSingleComment(l: var Lexer): void =
    while l.c != EOF and l.c != '\n':
        l.advance()


proc skipMultipleComment(l: var Lexer): void =
    l.advance(); l.advance(); l.advance() # skip begin '"""'
    while (l.c != EOF and not l.isMultipleComment()):
        l.advance()
    
    if not l.isMultipleComment():
        # TODO: raise error
        return    
    l.advance(); l.advance(); l.advance() # skip final '"""'


proc skipBackSlash(l: var Lexer): void =
    l.skipWhitespace()
    if l.c != '\n':
        # TODO: raise exception
        return
    l.advance()


proc newToken(l: var Lexer, kind: TokenKind): Token =
    l.tokAnt = kind
    return token.Token(kind: kind, line: l.line, col: l.begin_token_col)


proc newToken(l: var Lexer, kind: TokenKind, lexeme: string): Token =
    l.tokAnt = kind
    # convert from string to Double (NUMBER token type)
    case kind:
    of tkNumber:
        return token.Token(kind: kind, floatValue: strutils.parseFloat(lexeme), line: l.line, col: l.begin_token_col)
    of tkString, tkStringFormat, tkIdentifier:
        return token.Token(kind: kind, strValue: lexeme, lexeme: lexeme, line: l.line, col: l.begin_token_col)
    of tkTrue, tkFalse:
        return token.Token(kind: kind, boolValue: (lexeme == "true"), line: l.line, col: l.begin_token_col)
    else:
        return token.Token(kind: kind, lexeme: lexeme, line: l.line, col: l.begin_token_col)