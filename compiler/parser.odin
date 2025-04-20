package saga_compiler
import "core:fmt"
import "core:os"

Parsing_Error :: enum {
    Syntax_Error,
}

Parser :: struct {
    tokens:             []Token,
    curr_token_index:   int,
    curr_token:         Token,
    prev_token:         Token,
    curr_proc:          ^Ast_Node,
    error_count:        int,
    expr_level:         int,
    allow_type:         bool,
}


parser_init :: proc(tokens: []Token) -> Parser {
    return Parser{
        tokens = tokens,
        curr_token = tokens[0],
    }
}


next_token :: proc(p: ^Parser) -> bool {
    if p.curr_token_index + 1 < len(p.tokens) {
        p.curr_token = p.tokens[p.curr_token_index + 1]
        p.curr_token_index += 1
        return true
    }
    syntax_error(p, "Unexpected end of file")
    return false
}


advance_token :: proc(p: ^Parser) -> Token {
    prev := p.curr_token
    p.prev_token = prev
    next_token(p)
    return prev
}


peek_token :: proc(p: ^Parser) -> Token {
    if p.curr_token_index + 1 >= len(p.tokens) {
        return Token{kind = .EOF}
    }
    return p.tokens[p.curr_token_index + 1]
}


expect_token :: proc(p: ^Parser, kind: Token_Kind) -> (prev: Token, err: Parsing_Error) {
    prev = p.curr_token
    if prev.kind != kind {
        err = syntax_error(p, fmt.tprintf("Expected '%v', got '%v'", kind, prev.kind))
        return
    }
    advance_token(p)
    return
}


allow_token :: proc(p: ^Parser, kind: Token_Kind) -> bool {
    prev := p.curr_token
    if prev.kind == kind {
        advance_token(p)
        return true
    }
    return false
}


is_literal_type :: proc(node: ^Ast_Node) -> bool {
    #partial switch node.kind {
    case .Bad_Expr, .Selector_Expr, .Call_Expr,
        .Identifier, .Array_Type, .Dynamic_Array_Type, 
        .Vector_Type, .Matrix_Type, .Tensor_Type:
        return true
    }
    return false
}


// syntax_error :: proc(p: ^Parser, msg: string) -> Parsing_Error {
//     p.error_count += 1
//     fmt.eprintf("%v: error: %s\n", p.curr_token.pos, msg)
//     return .Syntax_Error
// }

syntax_error :: proc(p: ^Parser, msg: string) -> Parsing_Error {
    p.error_count += 1
    fmt.eprintf("(%v:%v): error: %s\n",
        p.curr_token.pos.line, 
        p.curr_token.pos.column, msg)
    
    if p.error_count > 50 {
        os.exit(1)
    }
    
    for p.curr_token.kind != .EOF {
        #partial switch p.curr_token.kind {
        case .Semicolon, .Close_Brace:
            advance_token(p)
            return .Syntax_Error
        }
        advance_token(p)
    }
    
    return .Syntax_Error
}


// No polymorphism for now
parse_identifier :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    token := p.curr_token
    if token.kind == .Identifier {
        advance_token(p)
    } else {
        token.value = "_"
        expect_token(p, .Identifier) or_return
    }
    node = ast_identifier(token)
    return
}


parse_value :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    if p.curr_token.kind == .Open_Brace {
        return parse_compound_literal(p, nil)
    }
    return parse_expr(p, false)
}


parse_compound_literal :: proc(p: ^Parser, type: ^Ast_Node) -> (node: ^Ast_Node, err: Parsing_Error) {
    elems: [dynamic]^Ast_Node
    open := expect_token(p, .Open_Brace) or_return
    expr_level := p.expr_level
    p.expr_level = 0
    if p.curr_token.kind != .Close_Brace {
        elems = parse_element_list(p) or_return
    }
    p.expr_level = expr_level
    close := expect_token(p, .Close_Brace) or_return
    node = ast_compound_literal(type, elems[:], open, close);
    return
}


parse_element_list :: proc(p: ^Parser) -> (elems: [dynamic]^Ast_Node, err: Parsing_Error) {
    for p.curr_token.kind != .Close_Brace && p.curr_token.kind != .EOF {
        elem := parse_value(p) or_return
        if p.curr_token.kind == .Eq {
            eq := expect_token(p, .Eq) or_return
            value := parse_value(p) or_return
            elem = ast_field_value(elem, value, eq)
        }
        append(&elems, elem)
        if p.curr_token.kind != .Comma do break
        advance_token(p)
    }
    return
}


parse_field_list :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) { 
    start_token := p.curr_token
    params: [dynamic]^Ast_Node
    
    for p.curr_token.kind != .Close_Paren && p.curr_token.kind != .EOF {
        names: [dynamic]^Ast_Node
        
        first_name_token := expect_token(p, .Identifier) or_return
        first_name := ast_identifier(first_name_token)
        append(&names, first_name)
        
        for p.curr_token.kind == .Comma {
            advance_token(p)
            if p.curr_token.kind == .Colon do break
            next_name_token := expect_token(p, .Identifier) or_return
            next_name := ast_identifier(next_name_token)
            append(&names, next_name)
        }

        expect_token(p, .Colon) or_return
        type := parse_type(p) or_return
        
        param := ast_field(names[:], type, first_name_token)
        append(&params, param)

        if p.curr_token.kind != .Comma do break
        advance_token(p)
    }
    expect_token(p, .Close_Paren) or_return
    node = ast_field_list(params[:], start_token)
    return
}


parse_type_or_ident :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) { 
    prev_allow_type := p.allow_type
    prev_expr_level := p.expr_level

    defer p.allow_type = prev_allow_type
    defer p.expr_level = prev_expr_level

    p.allow_type = true
    p.expr_level = -1

    lhs := true
    operand := parse_operand(p, lhs) or_return
    return parse_atom_expr(p, operand, lhs)
}


parse_type :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) { 
   node = parse_type_or_ident(p) or_return
   if node == nil {
       prev_token := p.curr_token
       token: Token
       if p.curr_token.kind == .Open_Brace {
           token = p.curr_token
       } else {
           token = advance_token(p)
       }
        err = syntax_error(p, "Expected a type")
        node = ast_bad_expr(token, p.curr_token)
        return 
   } 
   return
}


parse_proc_type :: proc(p: ^Parser, varient: Proc_Varient, token: Token) -> (node: ^Ast_Node, err: Parsing_Error) { 
    expect_token(p, .Open_Paren) or_return
    p.expr_level += 1
    params := parse_field_list(p) or_return
    p.expr_level -= 1
    results: ^Ast_Node
    if p.curr_token.kind != .Right_Arrow {
        results = nil
    } else {
        advance_token(p)
        results = parse_results(p) or_return
    }
    node = ast_procedure_type(params, results, varient, token)
    return 
}


parse_results :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) { 
    prev_level := p.expr_level
    defer p.expr_level = prev_level

    if p.curr_token.kind != .Open_Paren {
        begin_token := p.curr_token
        empty_names: []^Ast_Node
        list: [dynamic]^Ast_Node
        type := parse_type(p) or_return
        append(&list, ast_field(empty_names, type, begin_token))
        node = ast_field_list(list[:], begin_token)
        return
    }
    expect_token(p, .Open_Paren) or_return
    return parse_field_list(p) 
}


parse_body :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) { 
    prev_expr_level := p.expr_level
    defer p.expr_level = prev_expr_level
    p.expr_level = 0
    open := expect_token(p, .Open_Brace) or_return
    stmts := parse_stmt_list(p) or_return
    close := expect_token(p, .Close_Brace) or_return
    node = ast_block_stmt(stmts[:], open, close)
    return
}


parse_operand :: proc(p: ^Parser, lhs: bool) -> (node: ^Ast_Node, err: Parsing_Error) { 
    node = nil
    #partial switch p.curr_token.kind {
    case .Identifier:
        return parse_identifier(p)

    case .Integer, .Float, .Imaginary:
        node = ast_basic_literal(advance_token(p))
        return

    case .Open_Brace:
        if !lhs do return parse_compound_literal(p, nil)

    case .Open_Paren:
        prev_expr_level: int
        open, close: Token

        open = expect_token(p, .Open_Paren) or_return
        if (p.prev_token.kind == .Close_Paren) {
            close = expect_token(p, .Close_Paren) or_return
            err = syntax_error(p, "Invalid parentheses expression with no inside expression");
            node = ast_bad_expr(open, close)
            return
        }

        prev_expr_level = p.expr_level
        p.expr_level = max(p.expr_level, 0) + 1
        operand := parse_expr(p, false) or_return
        p.expr_level = prev_expr_level

        close = expect_token(p, .Close_Paren) or_return
        node = ast_paren_expr(operand, open, close)
        return
    
    case .Kernel:
        token := expect_token(p, .Kernel) or_return
        type := parse_proc_type(p, .Compute_Shader, token) or_return
        curr_proc := p.curr_proc
        p.curr_proc = type
        body := parse_body(p) or_return
        p.curr_proc = curr_proc;
        node = ast_procedure_literal(type, body, token);
        return 

    // TODO: Differentiate between vertex and fragment shader types
    case .Shader:
        token := expect_token(p, .Shader) or_return
        type := parse_proc_type(p, .Fragment_Shader, token) or_return
        curr_proc := p.curr_proc
        p.curr_proc = type
        body := parse_body(p) or_return
        p.curr_proc = curr_proc;
        node = ast_procedure_literal(type, body, token);
        return

    case .Proc:
        token := expect_token(p, .Proc) or_return
        type := parse_proc_type(p, .Basic_Procedure, token) or_return
        curr_proc := p.curr_proc
        p.curr_proc = type
        body := parse_body(p) or_return
        p.curr_proc = curr_proc
        node = ast_procedure_literal(type, body, token)
        return

    case .Pointer:
        token := expect_token(p, .Pointer) or_return
        elem := parse_type(p) or_return
        node = ast_pointer_type(elem, token)
        return
        
    case .Open_Bracket:
        token := expect_token(p, .Open_Bracket) or_return
        size_expr: ^Ast_Node
        if p.curr_token.kind == .Pointer {
            expect_token(p, .Pointer) or_return
            expect_token(p, .Close_Bracket) or_return
            type := parse_type(p) or_return
            node = ast_multi_pointer_type(type, token)
            return
        }
        else if p.curr_token.kind == .Dynamic {
            expect_token(p, .Close_Bracket) or_return
            type := parse_type(p) or_return
            node = ast_dynamic_array_type(type, token)
            return
        }
        else if p.curr_token.kind != .Close_Bracket {
            p.expr_level += 1
            size_expr = parse_expr(p, false) or_return
            p.expr_level -= 1
        }
        expect_token(p, .Close_Bracket) or_return
        type := parse_type(p) or_return
        node = ast_array_type(size_expr, type, token)
        return

    case .Vec:
        token := expect_token(p, .Vec) or_return
        node = ast_vector_type(token)
        return

    case .Matrix:
        token := expect_token(p, .Matrix) or_return
        open := expect_token(p, .Open_Bracket) or_return

        if p.curr_token.kind == .Dynamic {
            expect_token(p, .Dynamic) or_return
            expect_token(p, .Close_Bracket) or_return
            type := parse_type(p) or_return
            node = ast_dynamic_matrix_type(type, token)
            return
        }
        row_count := parse_expr(p, true) or_return
        expect_token(p, .Comma) or_return
        column_count := parse_expr(p, true) or_return
        expect_token(p, .Close_Bracket) or_return
        elem_type := parse_type(p) or_return
        node = ast_matrix_type(row_count, column_count, elem_type, true, token) // Assuming row-major for now
        return

    case .Tensor:
        token := expect_token(p, .Tensor) or_return
        open := expect_token(p, .Open_Bracket) or_return

        if p.curr_token.kind == .Dynamic {
            expect_token(p, .Dynamic) or_return
            expect_token(p, .Close_Bracket) or_return
            type := parse_type(p) or_return
            node = ast_dynamic_tensor_type(type, token)
            return
        }

        dims: [dynamic]^Ast_Node
        for p.curr_token.kind != .Close_Bracket {
            expr := parse_expr(p, true) or_return
            append(&dims, expr)
            if p.curr_token.kind != .Comma do break
            advance_token(p)
        }
        expect_token(p, .Close_Bracket) or_return

        strides: [dynamic]^Ast_Node
        if p.curr_token.kind == .Open_Paren {
            open = expect_token(p, .Open_Paren) or_return
            for p.curr_token.kind != .Close_Paren {
                expr := parse_expr(p, true) or_return
                append(&strides, expr)
                if p.curr_token.kind != .Comma do break
                advance_token(p)
            }
            close := expect_token(p, .Close_Paren) or_return
            if len(strides) != len(dims) {
                err = syntax_error(p, "Number of strides must match number of tensor dimensions");
                node = ast_bad_expr(open, close)
                return
            }
        } else {
            for i in 0..<len(dims) {
                one_token := Token{.Integer, 1, token.pos}
                one_node := ast_basic_literal(one_token)
                append(&strides, one_node)
            }
        }
        elem_type := parse_type(p) or_return
        node = ast_tensor_type(dims[:], strides[:], elem_type, token)
        return
    }

    return
}


parse_atom_expr :: proc(p: ^Parser, operand: ^Ast_Node, lhs: bool) -> (node: ^Ast_Node, err: Parsing_Error) { 
    operand := operand
    lhs     := lhs
    if operand == nil {
        if p.allow_type do return nil, nil
        err = syntax_error(p, "Expected an operand")
        operand = ast_bad_expr(p.curr_token, p.curr_token)
    }
    loop := true
    for loop {
        #partial switch p.curr_token.kind {
        case .Open_Paren:
            operand = parse_call_expr(p, operand) or_return

        case .Period:
            token := advance_token(p)
            if p.curr_token.kind != .Identifier {
                err = syntax_error(p, "Expected a selector")
                return
            } else {
                id := parse_identifier(p) or_return
                operand = ast_selector_expr(operand, id, token)
            }

        case .Open_Bracket:
            indices: [dynamic]^Ast_Node
            interval: Token

            p.expr_level += 1
            open := p.prev_token
            expect_token(p, .Open_Bracket) or_return

            for p.curr_token.kind != .Close_Bracket && p.curr_token.kind != .EOF {
                expr := parse_expr(p, false) or_return
                append(&indices, expr)
                if p.curr_token.kind != .Close_Bracket{
                    interval = advance_token(p)
                }
            }

            p.expr_level -= 1
            close := expect_token(p, .Close_Bracket) or_return

            switch len(indices) {
            case 0:
                err = syntax_error(p, "Empty index expression")
                operand = ast_bad_expr(open, close)
                return operand, err
            case 1: 
                operand = ast_index_expr(operand, indices[0], open, close)
            case 2:
                #partial switch interval.kind {
                case .Comma:
                   operand = ast_matrix_index_expr(operand, indices[0], indices[1], open, close)
                case .Colon:
                   operand = ast_slice_expr(operand, indices[0], indices[1], interval, open, close)
                case:
                    err = syntax_error(p, "Invalid interval symbol for index expression")
                    operand = ast_bad_expr(open, close)
                    return operand, err
                }
            case:
                if interval.kind != .Comma {
                    err = syntax_error(p, "Invalid interval symbol for index expression")
                    operand = ast_bad_expr(open, close)
                    return operand, err
                }
                operand = ast_tensor_index_expr(operand, indices[:], open, close)
            }

        case .Pointer:
            token := expect_token(p, .Pointer) or_return
            operand = ast_deref_expr(operand, token)

        case .Open_Brace:
            if (!lhs && is_literal_type(operand) && p.expr_level >= 0) {
                operand = parse_compound_literal(p, operand) or_return
            } 
            else { loop = false}

        case:
            loop = false
        }

        lhs = false
    }

    node = operand
    return
}


parse_unary_expr :: proc(p: ^Parser, lhs: bool) -> (node: ^Ast_Node, err: Parsing_Error) { 
    #partial switch p.curr_token.kind {
    case .Cast:
        token := advance_token(p)
        expect_token(p, .Open_Paren) or_return
        type := parse_type(p) or_return
        expect_token(p, .Close_Paren) or_return
        expr := parse_unary_expr(p, lhs) or_return
        node = ast_cast_expr(type, expr, token)
        return

    case .Add, .Sub, .Xor, .And, .Not:
        token := advance_token(p)
        expr := parse_unary_expr(p, lhs) or_return
        node = ast_unary_expr(expr, token)
        return
    }

    expr := parse_operand(p, lhs) or_return
    node = parse_atom_expr(p, expr, lhs) or_return
    return
}


token_precedence :: proc(t: Token_Kind) -> int {
    #partial switch t {
    case .If:
        return 1
    case .Ellipsis:
        return 2
    case .Cmp_Or:
        return 3
    case .Cmp_And:
        return 4
    case .Cmp_Eq, .Not_Eq, .Lt, .Gt, .Lt_Eq, .Gt_Eq:
        return 5
    case .Add, .Sub, .Or, .Xor:
        return 6
    case .Mul, .Div, .Mod, .Rem, .And, .And_Not, .Shl, .Shr:
        return 7
    }
    return 0
}


parse_binary_expr :: proc(p: ^Parser, lhs: bool, prec_in: int) -> (node: ^Ast_Node, err: Parsing_Error) { 
    lhs := lhs
    expr := parse_unary_expr(p, lhs) or_return
    for {
        op := p.curr_token
        op_prec := token_precedence(op.kind)
        if op_prec < prec_in do break 

        prev := p.prev_token
        if op.kind == .If {
            if prev.pos.line < op.pos.line {
                node = expr
                return
            }
        }
        if !is_operator(op.kind) && op.kind != .If {
            err = syntax_error(p, "Expected an operator")
            return
        }
        advance_token(p)

        if op.kind == .If {
            x           := expr
            cond        := parse_expr(p, lhs) or_return
            else_token  := expect_token(p, .Else) or_return
            y           := parse_expr(p, lhs) or_return
            expr         = ast_ternary_if_expr(x, cond, y)
        } else {
            right := parse_binary_expr(p, false, op_prec + 1) or_return
            if right == nil {
                err = syntax_error(p, "Expected expression on the right-hand side of the binary operator")
                return
            }
            expr = ast_binary_expr(expr, right, op)
        }

        lhs = false
    }

    node = expr
    return
}


parse_expr :: proc(p: ^Parser, lhs: bool) -> (node: ^Ast_Node, err: Parsing_Error) {
    return parse_binary_expr(p, lhs, 1)
}


parse_expr_list :: proc(p: ^Parser, lhs: bool) -> (list: [dynamic]^Ast_Node, err: Parsing_Error) {
    for {
        expr := parse_expr(p, lhs) or_return
        append(&list, expr)
        if p.curr_token.kind != .Comma || p.curr_token.kind == .EOF do break
        advance_token(p)
    }
    return 
}


parse_lhs_expr_list :: proc(p: ^Parser) -> (node: [dynamic]^Ast_Node, err: Parsing_Error) {
    return parse_expr_list(p, true)
}


parse_rhs_expr_list :: proc(p: ^Parser) -> (node: [dynamic]^Ast_Node, err: Parsing_Error) {
    return parse_expr_list(p, false)
}


parse_call_expr :: proc(p: ^Parser, operand: ^Ast_Node) -> (node: ^Ast_Node, err: Parsing_Error) {
    args: [dynamic]^Ast_Node
    defer delete(args)
    
    prev_expr_level := p.expr_level
    p.expr_level = 0
    open_paren := expect_token(p, .Open_Paren) or_return
    for p.curr_token.kind != .Close_Paren && p.curr_token.kind != .EOF {
        if p.curr_token.kind == .Comma {
            err = syntax_error(p, "Expected an expression not ,")
            return
        } else if p.curr_token.kind == .Eq {
            err = syntax_error(p, "Expected an expression not =")
            return
        }
        
        arg := parse_expr(p, false) or_return
        
        if p.curr_token.kind == .Eq {
            eq := expect_token(p, .Eq) or_return
            value := parse_value(p) or_return
            arg = ast_field_value(arg, value, eq)
        }

        append(&args, arg)
        if p.curr_token.kind != .Close_Paren do expect_token(p, .Comma) or_return
    }
    p.expr_level = prev_expr_level
    close_paren := expect_token(p, .Close_Paren) or_return
    node = ast_call_expr(operand, args[:], open_paren, close_paren)
    return
}


parse_value_decl :: proc(p: ^Parser, names: []^Ast_Node) -> (node: ^Ast_Node, err: Parsing_Error) {
    values: [dynamic]^Ast_Node
    is_mutable := true
    type := parse_type_or_ident(p) or_return
    
    if p.curr_token.kind == .Eq || p.curr_token.kind == .Colon {
        sep: Token
        if !is_mutable {
            sep = expect_token(p, .Colon) or_return
        } else {
            sep = advance_token(p)
            is_mutable = sep.kind != .Colon
        }
        
        values = parse_rhs_expr_list(p) or_return
        
        if len(values) > len(names) {
            err = syntax_error(p, "Too many values on the right hand side of the declaration")
            return
        } else if len(values) < len(names) && !is_mutable {
            err = syntax_error(p, "All constant declarations must be defined")
            return
        } else if len(values) == 0 {
            err = syntax_error(p, "Expected an expression for this declaration")
            return
        }
    }
    
    if is_mutable {
        if type == nil && len(values) == 0 {
            err = syntax_error(p, "Missing variable type or initialization")
            node = ast_bad_decl(p.curr_token, p.curr_token)
            return
        }
    } else {
        if type == nil && len(values) == 0 && len(names) > 0 {
            err = syntax_error(p, "Missing constant value")
            node = ast_bad_decl(p.curr_token, p.curr_token)
            return
        }
    }
    
    node = ast_value_decl(names, type, values[:], is_mutable)
    return
}


parse_block_stmt :: proc (p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    if p.curr_proc == nil {
        err = syntax_error(p, "You cannot use a block statement in the file scope");
        node = ast_bad_stmt(p.curr_token, p.curr_token)
        return
    }
    return parse_body(p)
}


parse_return_stmt :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    token := expect_token(p, .Return) or_return
    
    if p.curr_proc == nil {
        err = syntax_error(p, "You cannot use a return statement in the file scope")
        node = ast_bad_stmt(token, p.curr_token)
        return
    }
    
    if p.expr_level > 0 {
        err = syntax_error(p, "You cannot use a return statement within an expression")
        node = ast_bad_stmt(token, p.curr_token)
        return
    }
    
    results: [dynamic]^Ast_Node
    for p.curr_token.kind != .Close_Brace {
        arg := parse_expr(p, false) or_return
        append(&results, arg)
        
        if p.curr_token.kind != .Comma || p.curr_token.kind == .EOF {
            break
        }
        advance_token(p)
    }
    
    node = ast_return_stmt(results[:], token)
    return
}


parse_defer_stmt :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    if p.curr_proc == nil {
        err = syntax_error(p, "You cannot use a defer statement in the file scope")
        node = ast_bad_stmt(p.curr_token, p.curr_token)
        return
    }
    
    token := expect_token(p, .Defer) or_return
    stmt := parse_stmt(p) or_return
    
    #partial switch stmt.kind {
    case .Defer_Stmt:
        err = syntax_error(p, "You cannot defer a defer statement")
        return
    case .Return_Stmt:
        err = syntax_error(p, "You cannot defer a return statement")
        return
    }
    
    node = ast_defer_stmt(stmt, token)
    return
}


// parse_if_stmt :: proc(p: ^Parser) -> ^Ast_Node {
//     if p.curr_proc == nil {
//         syntax_error(p, "You cannot use an if statement in the file scope")
//         return ast_bad_stmt(p.curr_token, p.curr_token)
//     }
//     top_if_stmt, prev_if_stmt: ^Ast_Node
//     if_else_chain: for {
//         token := expect_token(p, .If)
//         cond, body, else_stmt: ^Ast_Node
//
//         prev_level := p.expr_level
//         p.expr_level = -1
//         cond = parse_expr(p, false)
//         p.expr_level = prev_level
//         if cond == nil do syntax_error(p, "Expected condition for if statement")
//
//         body = parse_block_stmt(p)
//         curr_if_stmt := ast_if_stmt(cond, body, nil, token)
//
//         if top_if_stmt == nil {
//             top_if_stmt = curr_if_stmt
//         }
//         if prev_if_stmt != nil {
//             prev_if_stmt.derived.(if_stmt).else_stmt = curr_if_stmt
//         }
//         if p.curr_token.kind == .Else {
//             else_token := expect_token(p, .Else)
//             #partial switch p.curr_token.kind {
//             case .If:
//                 prev_if_stmt = curr_if_stmt
//                 continue if_else_chain
//             case .Open_Brace:
//                 else_stmt = parse_block_stmt(p)
//             case:
//                 syntax_error(p, "Expected if statement or block statement")
//                 else_stmt = ast_bad_stmt(p.curr_token, p.tokens[p.curr_token_index+1])
//             }
//         }
//         curr_if_stmt.(If_Stmt).else_stmt = else_stmt
//         return top_if_stmt
//     }
// }


parse_if_stmt :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    if p.curr_proc == nil {
        err = syntax_error(p, "You cannot use an if statement in the file scope")
        node = ast_bad_stmt(p.curr_token, p.curr_token)
        return
    }
    token := expect_token(p, .If) or_return

    prev_level := p.expr_level 
    p.expr_level = -1
    cond := parse_expr(p, false) or_return
    p.expr_level = prev_level
   
    if cond == nil {
        err = syntax_error(p, "Expected condition for if statement")
        return
    }
    body := parse_block_stmt(p) or_return
    node = ast_if_stmt(cond, body, nil, token)
    return
}


parse_control_statement_semicolon_separator :: proc(p: ^Parser) -> bool {
    token := peek_token(p)
    if token.kind != .Open_Brace do return allow_token(p, .Semicolon)
    if p.curr_token.kind == .Semicolon do return allow_token(p, .Semicolon)
    return false
}


parse_for_stmt :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    if p.curr_proc == nil {
        err = syntax_error(p, "You cannot use a for statement in the file scope")
        node = ast_bad_stmt(p.curr_token, p.curr_token)
        return
    }
    token := expect_token(p, .For) or_return
    init, cond, post, body: ^Ast_Node
    is_range := false
    
    if p.curr_token.kind != .Open_Brace {
        prev_level := p.expr_level
        defer p.expr_level = prev_level
        p.expr_level = -1
        if p.curr_token.kind != .Semicolon {
            cond = parse_simple_stmt(p) or_return
            if cond.kind == .Assign_Stmt && cond.derived.(Assign_Stmt).op.kind == .In {
                is_range = true
            }
        }
        if !is_range && parse_control_statement_semicolon_separator(p) {
            init = cond
            cond = nil
            
            if p.curr_token.kind == .Open_Brace {
                err = syntax_error(p, "Expected ';', followed by a condition expression and post statement")
                return
            } else {
                if p.curr_token.kind != .Semicolon {
                    cond = parse_simple_stmt(p) or_return
                }
                expect_token(p, .Semicolon) or_return
                if p.curr_token.kind != .Open_Brace {
                    post = parse_simple_stmt(p) or_return
                }
            }
        }
    }
    body = parse_block_stmt(p) or_return
    if is_range {
        in_token := cond.derived.(Assign_Stmt).op
        vals := cond.derived.(Assign_Stmt).lhs
        rhs: ^Ast_Node
        if len(cond.derived.(Assign_Stmt).rhs) > 0 {
            rhs = cond.derived.(Assign_Stmt).rhs[0]
        }
        node = ast_range_stmt(vals, rhs, body, in_token, token)
        return
    }
    
    node = ast_for_stmt(init, cond, post, body, token)
    return
}


parse_simple_stmt :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    token := p.curr_token
    lhs := parse_lhs_expr_list(p) or_return
    token = p.curr_token
    #partial switch token.kind {
    case .Eq, 
         .Add_Eq, 
         .Sub_Eq, 
         .Mul_Eq,
         .Div_Eq, 
         .Mod_Eq, 
         .Rem_Eq, 
         .And_Eq,
         .Or_Eq, 
         .Xor_Eq, 
         .Shl_Eq, 
         .Shr_Eq,
         .And_Not_Eq, 
         .Cmp_And_Eq, 
         .Cmp_Or_Eq:

        advance_token(p)
        rhs := parse_rhs_expr_list(p) or_return
        if len(rhs) == 0 {
            err = syntax_error(p, "No right-hand side in assignment statement.")
            node = ast_bad_stmt(token, p.curr_token)
            return
        }
	node = ast_assign_stmt(lhs[:], rhs[:], token)
        return

    case .Colon:
        advance_token(p)
        return parse_value_decl(p, lhs[:])
    }

    node = ast_bad_stmt(token, p.curr_token)
    return
}


parse_stmt :: proc(p: ^Parser) -> (node: ^Ast_Node, err: Parsing_Error) {
    token := p.curr_token
    #partial switch token.kind {
    case .Identifier, 
         .Kernel,  
         .Shader, 
         .Proc,  
         .Integer, 
         .Float, 
         .Imaginary, 
         .Open_Paren,
         .Pointer, 
         .Add, 
         .Sub, 
         .Xor, 
         .Not, 
         .And:
        return parse_simple_stmt(p)
    case .If:     
        return parse_if_stmt(p);
    case .For:    
        return parse_for_stmt(p);
    case .Return: 
        return parse_return_stmt(p);
    case .Defer:  
        return parse_defer_stmt(p);
    case .Open_Brace:
        return parse_block_stmt(p);
    }

    err = syntax_error(p, fmt.tprintf("Expected 'a statement', got '%v'", token.kind))
    node = ast_bad_stmt(token, token)
    if p.curr_token == token do advance_token(p)
    return
}


parse_stmt_list :: proc(p: ^Parser) -> (list: [dynamic]^Ast_Node, err: Parsing_Error) {
    for p.curr_token.kind != .Close_Brace && p.curr_token.kind != .EOF {
        stmt := parse_stmt(p) or_return
        append(&list, stmt)
    }
   return
}


parse_file :: proc(p: ^Parser) -> (nodes: [dynamic]^Ast_Node, err: Parsing_Error) {
    if len(p.tokens) == 0 || p.tokens[0].kind == .EOF {
        fmt.println("Empty File!")
        return
    }

    module_token    := expect_token(p, .Module) or_return
    name_token      := expect_token(p, .Identifier) or_return
    module_ast      := ast_module_decl(name_token, module_token)
    append(&nodes, module_ast)

    for p.curr_token.kind != .EOF {
        next_node := parse_stmt(p) or_return
        append(&nodes, next_node)
    }
    return nodes, nil
}
