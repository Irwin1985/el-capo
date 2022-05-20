import ../ast/ast
import ../token/token

type
    FunctionType = enum
        ftNone
        ftFunction
        ftInitializer
        ftMethod
    
    ClassType = enum
        ctNone
        ctClass
        ctSubclass
    
    Resolver = ref object of RootObj
        currentFunction: FunctionType
        currentClass: ClassType

# ======================================================== #
# Resolver forwarded proc
# ======================================================== #
proc resolve*(r: var Resolver, statements: seq[Stmt]): void
proc resolve*(r: var Resolver, stmt: Stmt): void
proc resolve*(r: var Resolver, expr: Expr): void
proc beginScope(r: var Resolver, ): void
proc endScope(r: var Resolver, ): void
proc declare(r: var Resolver, name: Token): void
proc define(r: var Resolver, name: Token): void
proc resolveLocal(r: var Resolver, expr: Expr, name: Token): void
proc resolveFunction(r: var Resolver, function: Function, tipe: FunctionType): void
# ======================================================== #
# Visitor forwarded proc
# ======================================================== #
proc visitBlockStmt(stmt: Block): void
proc visitClassStmt(stmt: Class): void
proc visitLetStmt(stmt: Let): void
proc visitVariableExpr(expr: Variable): void
proc visitAssignExpr(expr: Assign): void
proc visitFunctionStmt(stmt: Function): void
proc visitExpressonStmt(stmt: Expression): void
proc visitIfStmt(stmt: If): void
proc visitReturnStmt(stmt: Return): void
proc visitWhileStmt(stmt: While): void
proc visitBinaryExpr(expr: Binary): void
proc visitCallExpr(expr: Call): void
proc visitGetExpr(expr: Get): void
proc visitGroupingExpr(expr: Grouping): void
proc visitIntegerLiteral(expr: Integer): void
proc visitFloatLiteral(expr: Float): void
proc visitLogicalExpr(expr: Logical): void
proc visitUnaryExpr(expr: Unary): void
proc visitSetExpr(expr: Set): void
proc visitSuperExpr(expr: Super): void
proc visitSelfExpr(expr: Self): void
proc visitArrayExpr(expr: ArrayLiteral): void
proc visitIndexExpr(expr: Index): void
proc visitDictionaryExpr(expr: Dictionary): void
proc visitEnumExpr(expr: Enum): void
proc visitAssignCollectionExpr(expr: AssignCollection): void
proc visitForStmt(stmt: For): void
proc visitBreakStmt(stmt: Break): void
proc visitContinueStmt(stmt: Continue): void
proc visitBinaryInc(expr: BinaryInc): void
proc visitDeferStmt(stmt: Defer): void
proc visitStringFormat(expr: StringFormat): void


# ======================================================== #
# Resolver implementation
# ======================================================== #
proc resolve*(r: var Resolver, statements: seq[Stmt]): void =
    discard


proc resolve*(r: var Resolver, stmt: Stmt): void =
    discard


proc resolve*(r: var Resolver, expr: Expr): void =
    discard


proc beginScope(r: var Resolver, ): void =
    discard


proc endScope(r: var Resolver, ): void =
    discard


proc declare(r: var Resolver, name: Token): void =
    discard


proc define(r: var Resolver, name: Token): void =
    discard


proc resolveLocal(r: var Resolver, expr: Expr, name: Token): void =
    discard


proc resolveFunction(r: var Resolver, function: Function, tipe: FunctionType): void =
    discard


# ======================================================== #
# Visitor implementation
# ======================================================== #
proc visitBlockStmt(stmt: Block): void =
    discard


proc visitClassStmt(stmt: Class): void =
    discard


proc visitLetStmt(stmt: Let): void =
    discard


proc visitVariableExpr(expr: Variable): void =
    discard


proc visitAssignExpr(expr: Assign): void =
    discard


proc visitFunctionStmt(stmt: Function): void =
    discard


proc visitExpressonStmt(stmt: Expression): void =
    discard


proc visitIfStmt(stmt: If): void =
    discard


proc visitReturnStmt(stmt: Return): void =
    discard


proc visitWhileStmt(stmt: While): void =
    discard


proc visitBinaryExpr(expr: Binary): void =
    discard


proc visitCallExpr(expr: Call): void =
    discard


proc visitGetExpr(expr: Get): void =
    discard


proc visitGroupingExpr(expr: Grouping): void =
    discard


proc visitIntegerLiteral(expr: Integer): void =
    discard


proc visitFloatLiteral(expr: Float): void =
    discard


proc visitLogicalExpr(expr: Logical): void =
    discard


proc visitUnaryExpr(expr: Unary): void =
    discard


proc visitSetExpr(expr: Set): void =
    discard


proc visitSuperExpr(expr: Super): void =
    discard


proc visitSelfExpr(expr: Self): void =
    discard


proc visitArrayExpr(expr: ArrayLiteral): void =
    discard


proc visitIndexExpr(expr: Index): void =
    discard


proc visitDictionaryExpr(expr: Dictionary): void =
    discard


proc visitEnumExpr(expr: Enum): void =
    discard


proc visitAssignCollectionExpr(expr: AssignCollection): void =
    discard


proc visitForStmt(stmt: For): void =
    discard


proc visitBreakStmt(stmt: Break): void =
    discard


proc visitContinueStmt(stmt: Continue): void =
    discard


proc visitBinaryInc(expr: BinaryInc): void =
    discard


proc visitDeferStmt(stmt: Defer): void =
    discard


proc visitStringFormat(expr: StringFormat): void =
    discard

