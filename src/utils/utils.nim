template dowhile*(a, b: untyped): untyped =
    while true:
        b
        if not a:
            break