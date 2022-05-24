import ../common/types


method stringify*(o: Object): string {.base.}
method stringify*(o: types.Null): string
method stringify*(o: types.Float): string
method stringify*(o: types.Integer): string
method stringify*(o: types.String): string

method stringify*(o: Object): string {.base.} =
    if o == nil:
        return "null"


method stringify*(o: types.Null): string =
    return "null"


method stringify*(o: types.Float): string =
    return $o.value


method stringify*(o: types.Integer): string =
    return $o.value


method stringify*(o: types.String): string =
    return o.value