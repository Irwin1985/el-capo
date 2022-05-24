import ../common/types
import tables

proc findMethod*(c: types.Class, name: string): types.Function =
    if c.methods.hasKey(name):
        return c.methods[name]
    if c.superclass != nil:
        return c.superclass.findMethod(name)

    return nil