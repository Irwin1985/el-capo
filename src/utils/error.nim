import ../token/token
import std/strformat
from ../common/types import RuntimeError

var
    hadError*: bool
    fileName*: string

# ==================================================== #
# public API for error handling.
# ==================================================== #
proc error*(line: int, col: int, message: string): void
proc error*(line: int, col: int, message: string, exit: bool): void
proc error*(tok: Token, message: string): void
proc report(tok: Token, message: string): void
proc report(line: int, col: int, message: string): void
proc runtimeError*(e: RuntimeError): void


# ==================================================== #
# API implementation
# ==================================================== #
proc error*(line: int, col: int, message: string): void =
    report(line, col, message)


proc error*(line: int, col: int, message: string, exit: bool): void =
    report(line, col, message)
    if exit:
        system.quit(system.QuitFailure)


proc error*(tok: Token, message: string): void =
    report(tok, message)


proc report(tok: Token, message: string): void =    
    var strerr: string    
    if fileName.len > 0:
        strerr.add(fmt"{fileName}:{tok.line}:{tok.col} ") # prefix the filename
    strerr.add(fmt"error: {message}")
    
    stderr.writeLine(strerr)
    hadError = true



proc report(line: int, col: int, message: string): void =    
    var strerr: string
    if fileName.len > 0:
        strerr.add(fmt"{fileName}:")
    strerr.add(fmt"{line}:{col}: ")
    strerr.add(fmt"error: {message}")
    
    stderr.writeLine(strerr)
    hadError = true


proc runtimeError*(e: RuntimeError): void =
    if e.token != nil:
        report(e.token, e.message)
    else:
        report(0, 0, e.message)