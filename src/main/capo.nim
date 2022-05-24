# ================================================================ #
# This is the 'El Capo' main file.
# Usage: form REPL you can hit: 'capo fileName'
# or simply hit any valid command.
# 
# created at: May 13 2022
# all credits: Irwin Rodríguez <rodriguez.irwin@gmail.com>
# ================================================================ #

import os
import ../token/token
import ../lexer/lexer
import ../parser/parser
import ../interpreter/resolver
import ../interpreter/interpreter
import ../utils/error
import ../common/types

# import ../ast/ast_printer

type
    Capo* = ref object of RootObj
        interpreter: Interpreter
        debug*: bool
        hadRuntimeError: bool

# ===============================================
# forward procedures
# ===============================================
proc newCapo: Capo
proc main: void
proc runFile(c: Capo, path: string): void
proc runPrompt(c: Capo): void
proc run(c: Capo, source: string): void
proc printUsage: void
proc printHeader: void

# ===============================================
# implementation
# ===============================================
proc newCapo: Capo =
    new result
    result.hadRuntimeError = false
    result.interpreter = newInterpreter()


proc main: void =
    let capo = newCapo()
    # debug
    capo.debug = true
    # debug
    if not capo.debug:
        if paramCount() > 1:
            printUsage()
            system.quit(system.QuitFailure)
        elif paramCount() == 1:
            capo.runFile(paramStr(1))
        else:
            capo.runPrompt()
    else:
        capo.runFile(r"C:\Users\irwin.SUBIFOR\el-capo\sample.capo")


proc runFile(c: Capo, path: string): void =
    if not os.fileExists(path):
        stderr.writeLine("error: file not found: ", path)
        printUsage()
        return
    # read all file
    let source = system.readFile(path)
    error.fileName = os.extractFilename(path)
    c.run(source & '\n') # '\n' is required for well formated source code.
    if error.hadError: system.quit(system.QuitFailure)
    


proc runPrompt(c: Capo): void =
    printHeader()
    while true:
        stdout.write(">>> ")
        let line = stdin.readLine()
        if line.len == 0:
            break
        c.run(line & '\n')
        error.hadError = false # we don't care if there was an error in the last interpreted code.


proc run(c: Capo, source: string): void =       
    let l:Lexer = newLexer(source)
    let p:Parser = newParser(l)

    # DEBUG LEXER
    let outputTokens: bool = false
    # DEBUG LEXER
    if outputTokens:
        var tok = l.nextToken()
        while tok.kind != TokenKind.tkEof:
            echo(tok.line, ":", tok.col, "<", tok.kind, ", '", tok.lexeme, "'>")
            tok = l.nextToken()
        echo(tok.line, ":", tok.col, "<", tok.kind, ", '", tok.lexeme, "'>")
    
    # Parse the tokens
    let program = p.parse()
    # if program.statements.len > 0 and program.statements[0] != nil:
    #     let output: string = ast_printer.print(program.statements)
    #     echo output
    
    if error.hadError: return
    
    # echo ast_printer.print(program.statements)

    discard newResolver(c.interpreter)
    resolve(program.statements)
    
    if error.hadError: return
    c.interpreter.interpret(program.statements)

proc printUsage: void =
    stdout.writeLine("Usage: capo [script]")
    stdout.writeLine("use --help for a list of possible options")


proc printHeader: void =
    let logo = """
  ______ _    _____                  
 |  ____| |  / ____|                   | Welcome to `El Capo` programming language REPL console.
 | |__  | | | |     __ _ _ __   ___    | here you can experiment with the language syntax. For best
 |  __| | | | |    / _` | '_ \ / _ \   | experience, use a text editor and save your program in a
 | |____| | | |___| (_| | |_) | (_) |  | `program.capo` file and then execute: capo run program.capo
 |______|_|  \_____\__,_| .__/ \___/   | Use Ctrl+C or `exit` to exit, or `help` for other commands.
                        | |          
                        |_|              
    """
    stdout.writeLine(logo)

when isMainModule:
    main()