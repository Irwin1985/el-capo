import ../common/types
import environment

proc bindFunction*(f: types.Function, i: types.Instance): types.Function =
    var env = newEnclosedEnv(f.closure)
    env.define("self", i)
    return types.Function(
        declaration: f.declaration,
        closure: env,
        isInitializer: f.isInitializer
    )