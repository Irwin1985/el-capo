let letters* = {'a'..'z', 'A'..'Z', '_'}
let digits* = {'0'..'9'}
let spaces* = {' ', '\r', '\t'}


proc isSpace*(c: char): bool =
    return c in spaces

proc isDigit*(c: char): bool =
    return c in digits


proc isLetter*(c: char): bool =
    return c in letters


proc isIdentifier*(c: char): bool =
    return c in letters or c in digits


template dowhile*(a, b: untyped): untyped =
    while true:
        b
        if not a:
            break