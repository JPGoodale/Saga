package saga_compiler
import "core:fmt"

Ast_Kind :: enum u8 {
    Identifier,
    Basic_Literal,
    Compound_Literal,
    Procedure_Literal,
    Field,
    Field_List,
    Field_Value,
    
    Expressions__Begin,
        Bad_Expr,
        Unary_Expr,
        Binary_Expr,
        Selector_Expr,
        Slice_Expr,
        Index_Expr,
        Matrix_Index_Expr,
        Tensor_Index_Expr,
        Deref_Expr,
        Call_Expr,
        Cast_Expr,
        Paren_Expr,
        Ternary_If_Expr,
    Expressions__End,
    
    Statements__Begin,
        Bad_Stmt,
        Assign_Stmt,
        Block_Stmt,
        If_Stmt,
        For_Stmt,
        Range_Stmt,
        Return_Stmt,
        Defer_Stmt,
    Statements__End,
    
    Declarations__Begin,
        Bad_Decl,
        Module_Decl,
        Value_Decl,
    Declarations__End,
    
    Types__Begin,
        Procedure_Type,
        Pointer_Type,
        Multi_Pointer_Type,
        Array_Type,
        Dynamic_Array_Type,
        Vector_Type,
        Matrix_Type,
        Dynamic_Matrix_Type,
        Tensor_Type,
        Dynamic_Tensor_Type,
    Types__End,
}

is_expr :: proc(kind: Ast_Kind) -> bool {
    return Ast_Kind.Expressions__Begin < kind && kind < Ast_Kind.Expressions__End
}

is_stmt :: proc(kind: Ast_Kind) -> bool {
    return Ast_Kind.Statements__Begin < kind && kind < Ast_Kind.Statements__End
}

is_decl :: proc(kind: Ast_Kind) -> bool {
    return Ast_Kind.Declarations__Begin < kind && kind < Ast_Kind.Declarations__End
}

is_type :: proc(kind: Ast_Kind) -> bool {
    return Ast_Kind.Types__Begin < kind && kind < Ast_Kind.Types__End
}


Ast_Node :: struct {
    kind: Ast_Kind,
    derived: union {
        Identifier,
        Basic_Literal,
        Compound_Literal,
        Procedure_Literal,
        Field,
        Field_List,
        Field_Value,
        Bad_Expr,
        Unary_Expr,
        Binary_Expr,
        Selector_Expr,
        Slice_Expr,
        Index_Expr,
        Matrix_Index_Expr,
        Tensor_Index_Expr,
        Deref_Expr,
        Call_Expr,
        Cast_Expr,
        Paren_Expr,
        Ternary_If_Expr,
        Bad_Stmt,
        Assign_Stmt,
        Block_Stmt,
        If_Stmt,
        For_Stmt,
        Range_Stmt,
        Return_Stmt,
        Defer_Stmt,
        Bad_Decl,
        Module_Decl,
        Value_Decl,
        Procedure_Type,
        Pointer_Type,
        Multi_Pointer_Type,
        Array_Type,
        Dynamic_Array_Type,
        Vector_Type,
        Matrix_Type,
        Dynamic_Matrix_Type,
        Tensor_Type,
        Dynamic_Tensor_Type,
    },
}


Identifier :: struct {
    token:  Token,
    value:  string
}


Basic_Literal :: struct {
    token: Token,
}


Compound_Literal :: struct {
    type:           ^Ast_Node,
    elems:          []^Ast_Node,
    open, close:    Token,
}


Procedure_Literal :: struct {
    type:   ^Ast_Node,
    body:   ^Ast_Node,
    token:  Token,
}


Field :: struct {
    names:  []^Ast_Node,
    type:   ^Ast_Node,
    token:  Token,
}


Field_List :: struct {
    nodes:  []^Ast_Node,
    token:  Token,
}


Field_Value :: struct {
    field:  ^Ast_Node,
    value:  ^Ast_Node,
    eq:     Token,
}


// Expression Nodes
Bad_Expr :: struct {
    begin, end: Token,
}


Unary_Expr :: struct {
    expr:   ^Ast_Node,
    op:     Token,
}


Binary_Expr :: struct {
    left, right:    ^Ast_Node,
    op:             Token,
}


Selector_Expr :: struct {
    expr:               ^Ast_Node,
    selector:           ^Ast_Node,
    swizzle_count:      u8,
    swizzle_indices:    u8,
    token:              Token,
}


Slice_Expr :: struct {
    expr:           ^Ast_Node,
    low, high:      ^Ast_Node,
    interval:       Token,
    open, close:    Token,
}


Index_Expr :: struct {
    expr:           ^Ast_Node,
    index:          ^Ast_Node,
    open, close:    Token,
}


Matrix_Index_Expr :: struct {
    expr:           ^Ast_Node,
    row_index:      ^Ast_Node,
    col_index:      ^Ast_Node,
    open, close:    Token,
}


Tensor_Index_Expr :: struct {
    expr:           ^Ast_Node,
    indices:        []^Ast_Node,
    open, close:    Token,
}


Deref_Expr :: struct {
    expr:   ^Ast_Node,
    op:     Token
}


Call_Expr :: struct {
    expr:           ^Ast_Node,
    args:           []^Ast_Node,
    open, close:    Token,
}


Cast_Expr :: struct {
    type:   ^Ast_Node,
    expr:   ^Ast_Node,
    token:  Token,
}


Paren_Expr :: struct {
    expr:           ^Ast_Node,
    open, close:    Token,
}


Ternary_If_Expr :: struct {
    x, cond, y: ^Ast_Node,
}


// Statement Nodes
Bad_Stmt :: struct {
    begin, end: Token,
}


Assign_Stmt :: struct {
    lhs, rhs:   []^Ast_Node,
    op:         Token,
}


Block_Stmt :: struct {
    stmts:          []^Ast_Node,
    open, close:    Token,
}


If_Stmt :: struct {
    cond:       ^Ast_Node,
    body:       ^Ast_Node,
    else_stmt:  ^Ast_Node,
    token:      Token,
}


For_Stmt :: struct {
    init:   ^Ast_Node,
    cond:   ^Ast_Node,
    post:   ^Ast_Node,
    body:   ^Ast_Node,
    token:  Token,
}


Range_Stmt :: struct {
    values:     []^Ast_Node,
    expr:       ^Ast_Node,
    body:       ^Ast_Node,
    in_token:   Token,
    token:      Token,
}


Return_Stmt :: struct {
    results:    []^Ast_Node,
    token:      Token,
}


Defer_Stmt :: struct {
    stmt:   ^Ast_Node,
    token:  Token,
}


// Declaration Nodes
Bad_Decl :: struct {
    begin, end: Token,
}


Module_Decl :: struct {
    name, token:  Token,
}


Value_Decl :: struct {
    names:      []^Ast_Node,
    type:       ^Ast_Node,
    values:     []^Ast_Node,
    is_mutable: bool,
}


// Type Nodes
Proc_Varient :: enum {
    Vertex_Shader,
    Fragment_Shader,
    Compute_Shader,
    Basic_Procedure,
}


Procedure_Type :: struct {
    params:     ^Ast_Node,
    results:    ^Ast_Node,
    varient:    Proc_Varient,
    token:      Token,
}


Basic_Type :: struct {
    value: string,
    token: Token,
}


Pointer_Type :: struct {
    elem_type: ^Ast_Node,
    token:      Token,
}


Multi_Pointer_Type :: struct {
    elem_type: ^Ast_Node,
    token:      Token,
}


Array_Type :: struct {
    size:       ^Ast_Node,
    elem_type:  ^Ast_Node,
    token:      Token,
}


Dynamic_Array_Type :: struct {
    elem_type: ^Ast_Node,
    token:      Token,
}


Vector_Type :: struct {
    count:      ^Ast_Node,
    elem_type:  ^Ast_Node,
    token:      Token,
}


Matrix_Type :: struct {
    rows, cols: ^Ast_Node,
    elem_type:  ^Ast_Node,
    row_major:  bool,
    token:      Token,
}


Dynamic_Matrix_Type :: struct {
    elem_type: ^Ast_Node,
    token:      Token,
}


Tensor_Type :: struct {
    shape:      []^Ast_Node,
    strides:    []^Ast_Node,
    elem_type:  ^Ast_Node,
    token:      Token,
}


Dynamic_Tensor_Type :: struct {
    elem_type: ^Ast_Node,
    token:      Token,
}

// Makers
ast_identifier :: proc(token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Identifier
   node.derived = Identifier{token, token.value.(string)}
   return
}

ast_basic_literal :: proc(token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Basic_Literal
   node.derived = Basic_Literal{token}
   return
}

ast_compound_literal :: proc(type: ^Ast_Node, elems: []^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Compound_Literal
   node.derived = Compound_Literal{type, elems, open, close}
   return
}

ast_procedure_literal :: proc(type: ^Ast_Node, body: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Procedure_Literal
   node.derived = Procedure_Literal{type, body, token}
   return
}

ast_field :: proc(names: []^Ast_Node, type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Field
   node.derived = Field{names, type, token}
   return
}

ast_field_list :: proc(nodes: []^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Field_List
   node.derived = Field_List{nodes, token}
   return
}

ast_field_value :: proc(field, value: ^Ast_Node, eq: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Field_Value
   node.derived = Field_Value{field, value, eq}
   return
}

ast_bad_expr :: proc(begin, end: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Bad_Expr
   node.derived = Bad_Expr{begin, end}
   return
}

ast_unary_expr :: proc(expr: ^Ast_Node, op: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Unary_Expr
   node.derived = Unary_Expr{expr, op}
   return
}

ast_binary_expr :: proc(left, right: ^Ast_Node, op: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Binary_Expr
   node.derived = Binary_Expr{left, right, op}
   return
}

ast_selector_expr :: proc(expr, selector: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Selector_Expr
   node.derived = Selector_Expr{expr, selector, 0, 0, token}
   return
}

ast_slice_expr :: proc(expr, low, high: ^Ast_Node, interval, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Slice_Expr
   node.derived = Slice_Expr{expr, low, high, interval, open, close}
   return
}

ast_index_expr :: proc(expr, index: ^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Index_Expr
   node.derived = Index_Expr{expr, index, open, close}
   return
}

ast_matrix_index_expr :: proc(expr, row_index, col_index: ^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Matrix_Index_Expr
   node.derived = Matrix_Index_Expr{expr, row_index, col_index, open, close}
   return
}

ast_tensor_index_expr :: proc(expr: ^Ast_Node, indices: []^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Tensor_Index_Expr
   node.derived = Tensor_Index_Expr{expr, indices, open, close}
   return
}

ast_deref_expr:: proc(expr: ^Ast_Node, op: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Deref_Expr
   node.derived = Deref_Expr{expr, op}
   return
}

ast_call_expr :: proc(expr: ^Ast_Node, args: []^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Call_Expr
   node.derived = Call_Expr{expr, args, open, close}
   return
}

ast_cast_expr :: proc(type, expr: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Cast_Expr
   node.derived = Cast_Expr{type, expr, token}
   return
}

ast_paren_expr :: proc(expr: ^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Paren_Expr
   node.derived = Paren_Expr{expr, open, close}
   return
}

ast_ternary_if_expr :: proc(x, cond, y: ^Ast_Node) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Ternary_If_Expr
   node.derived = Ternary_If_Expr{x, cond, y}
   return
}

ast_bad_stmt :: proc(begin, end: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Bad_Stmt
   node.derived = Bad_Stmt{begin, end}
   return
}

ast_assign_stmt :: proc(lhs, rhs: []^Ast_Node, op: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Assign_Stmt
   node.derived = Assign_Stmt{lhs, rhs, op}
   return
}

ast_block_stmt :: proc(stmts: []^Ast_Node, open, close: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Block_Stmt
   node.derived = Block_Stmt{stmts, open, close}
   return
}

ast_if_stmt :: proc(cond, body, else_stmt: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .If_Stmt
   node.derived = If_Stmt{cond, body, else_stmt, token}
   return
}

ast_for_stmt :: proc(init, cond, post, body: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .For_Stmt
   node.derived = For_Stmt{init, cond, post, body, token}
   return
}

ast_range_stmt :: proc(values: []^Ast_Node, expr, body: ^Ast_Node, in_token, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Range_Stmt
   node.derived = Range_Stmt{values, expr, body, in_token, token}
   return
}

ast_return_stmt :: proc(results: []^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Return_Stmt
   node.derived = Return_Stmt{results, token}
   return
}

ast_defer_stmt :: proc(stmt: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Defer_Stmt
   node.derived = Defer_Stmt{stmt, token}
   return
}

ast_bad_decl :: proc(begin, end: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Bad_Stmt
   node.derived = Bad_Decl{begin, end}
   return
}

ast_module_decl :: proc(name, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Module_Decl
   node.derived = Module_Decl{name, token}
   return
}

ast_value_decl :: proc(names: []^Ast_Node, type: ^Ast_Node, values: []^Ast_Node, is_mutable: bool) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Value_Decl
   node.derived = Value_Decl{names, type, values, is_mutable}
   return
}

ast_procedure_type :: proc(params, results: ^Ast_Node, varient: Proc_Varient, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Procedure_Type
   node.derived = Procedure_Type{params, results, varient, token}
   return
}

ast_pointer_type :: proc(elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Pointer_Type
   node.derived = Pointer_Type{elem_type, token}
   return
}

ast_multi_pointer_type :: proc(elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Multi_Pointer_Type
   node.derived = Multi_Pointer_Type{elem_type, token}
   return
}

ast_array_type :: proc(size, elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Array_Type
   node.derived = Array_Type{size, elem_type, token}
   return
}

ast_dynamic_array_type :: proc(elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Dynamic_Array_Type
   node.derived = Dynamic_Array_Type{elem_type, token}
   return
}

ast_vector_type :: proc(token: Token) -> (node: ^Ast_Node) {
   info         := VEC_INFO_MAP[token.value.(string)]
   count        := ast_identifier(make_token(.Identifier, info.count, token.pos))
   elem_type    := ast_identifier(make_token(.Identifier, info.elem_type, token.pos))
   node = new(Ast_Node)
   node.kind = .Vector_Type
   node.derived = Vector_Type{count, elem_type, token}
   return
}

ast_matrix_type :: proc(rows, cols, elem_type: ^Ast_Node, row_major: bool, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Matrix_Type
   node.derived = Matrix_Type{rows, cols, elem_type, row_major, token}
   return
}

ast_dynamic_matrix_type :: proc(elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Dynamic_Matrix_Type
   node.derived = Dynamic_Matrix_Type{elem_type, token}
   return
}

ast_tensor_type :: proc(shape, strides: []^Ast_Node, elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Tensor_Type
   node.derived = Tensor_Type{shape, strides, elem_type, token}
   return
}

ast_dynamic_tensor_type :: proc(elem_type: ^Ast_Node, token: Token) -> (node: ^Ast_Node) {
   node = new(Ast_Node)
   node.kind = .Dynamic_Tensor_Type
   node.derived = Dynamic_Tensor_Type{elem_type, token}
   return
}
