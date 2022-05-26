import std/tables

type 
    # TokenType for the Token object.
    TokenKind* = enum
        # Operators
        tkPlus           # +
        tkPlusEqual      # +=
        tkMinus          # -
        tkMinusEqual     # -=
        tkStar           # *
        tkStarEqual      # *=
        tkSlash          # /
        tkSlashEqual     # /=
        tkModulo         # %
        tkPower          # ^
        tkBang           # !
        tkBangEqual      # !=
        tkEqual          # =
        tkEqualEqual     # ==
        tkGreater        # >
        tkGreaterEqual   # >=
        tkLess           # <
        tkLessEqual      # <=

        # Symbols
        tkLeftParen      # (
        tkRightParen     # )
        tkLeftBrace      # {
        tkRightBrace     # }
        tkLeftBracket    # [
        tkRightBracket   # ]
        tkComma          # ,
        tkColon          # :
        tkDot            # .
        tkEllipsis       # ...
        tkSemicolon      # ;

        # Keywords
        tkAs
        tkAnd
        tkBreak
        tkContinue
        tkClass
        tkElse
        tkEnum        
        tkFalse
        tkDef
        tkDefer
        tkFor
        tkFormat
        tkFrom
        tkIf
        tkImport
        tkIn
        tkNull
        tkOr
        tkPass
        tkReturn
        tkSuper
        tkSelf
        tkTrue
        tkLet
        tkWhile

        # Identifiers and literals
        tkIdentifier
        tkString
        tkStringFormat
        tkInteger
        tkFloat
        
        # Others
        tkIllegal
        tkEof


# Token object
    Token* = ref object of RootObj
        lexeme*: string
        line*: int
        col*: int
        case kind*: TokenKind
        of tkString, tkStringFormat, tkIdentifier:
            strValue*: string
        of tkInteger:
            intValue*: int
        of tkFloat:
            floatValue*: float
        of tkTrue, tkFalse:
            boolValue*: bool
        else:
            discard


# Keyword dictionary
var keywords = {
        "as":       tkAs,
        "and":      tkAnd,
        "break":    tkBreak,
        "continue": tkContinue,
        "class":    tkClass,
        "def":      tkDef,
        "defer":    tkDefer,
        "else":     tkElse,
        "enum":     tkEnum,
        "false":    tkFalse,
        "for":      tkFor,
        "format":   tkFormat,
        "from":     tkFrom,
        "if":       tkIf,
        "import":   tkImport,
        "in":       tkIn,
        "let":      tkLet,
        "null":     tkNull,
        "or":       tkOr,
        "pass":     tkPass,
        "return":   tkReturn,
        "super":    tkSuper,
        "self":     tkSelf,
        "true":     tkTrue,
        "while":    tkWhile
    }.newTable

proc lookupIdent*(ident: string): TokenKind =
    if keywords.hasKey(ident):
        return keywords[ident]
    return tkIdentifier
