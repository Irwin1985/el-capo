# main source file

import os
import ../lexer/lexer
import ../token/token

var hadError: bool = false
var hadRuntimeError: bool = false

# ===============================================
# forward procedures
# ===============================================
proc main: void
proc runFile(path: string): void
proc runPrompt: void
proc run(source: string): void
proc error(line: int, message: string): void
proc error(line: int, message: string, exit: bool): void
proc error(tok: Token, message: string): void
proc report(line: int, where: string, message: string): void
proc printUsage: void

# ===============================================
# implementation
# ===============================================
proc main: void =
    if paramCount() > 1:
        printUsage()
        system.quit(system.QuitFailure)
    elif paramCount() == 1:
        runFile(paramStr(1))
    else:
        runPrompt()


proc runFile(path: string): void =
    if not os.fileExists(path):
        stderr.writeLine("error: file not found: ", path)
        printUsage()
        return
    # read all file
    let source = system.readFile(path)
    run(source & '\n') # '\n' is required for well formated source code.
    if hadError: system.quit(system.QuitFailure)
    


proc runPrompt: void =
    while true:
        stdout.write(">>> ")
        let line = stdin.readLine()
        if line.len == 0:
            break
        run(line & '\n')
        hadError = false # we don't care if there was an error in the last interpreted code.


proc run(source: string): void =       
    var l:Lexer = newLexer(source)
    # DEBUG LEXER
    let outputTokens: bool = true
    # DEBUG LEXER
    if outputTokens:
        var tok = l.nextToken()
        while tok.kind != TokenKind.tkEof:
            echo(tok.line, ":", tok.col, "<", tok.kind, ", '", tok.lexeme, "'>")
            tok = l.nextToken()
        echo(tok.line, ":", tok.col, "<", tok.kind, ", '", tok.lexeme, "'>")


proc error(line: int, message: string): void =
    report(line, "", message)


proc error(line: int, message: string, exit: bool): void =
    report(line, "", message)
    if exit:
        system.quit(system.QuitFailure)


proc error(tok: Token, message: string): void =
    if tok.kind == TokenKind.tkEof:
        report(tok.line, " at end", message)
    else:
        report(tok.line, " at '" & tok.lexeme & "'", message)


proc report(line: int, where: string, message: string): void =    
    stderr.writeLine("[line ", line, "] Error ", where, ": ", message)
    hadError = true


proc printUsage: void =
    stdout.writeLine("Usage: capo [script]")
    stdout.writeLine("use --help for a list of possible options")

when isMainModule:
    main()