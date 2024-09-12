package saga_compiler
import "core:log"
import "core:fmt"


Parsing_Error :: enum {
    Token_Type_Error,
    Type_Error,
    Syntax_Error,
    Unimplemented_Error
}


Parser :: struct {
    token_stream: [dynamic]Token,
    current_token_number: int,
    variables: map[string]Type
}


parser_init :: proc(token_stream: [dynamic]Token) -> Parser {
    return Parser{token_stream, 0, make(map[string]Type)}
}


parser_capture_variable :: proc(p: ^Parser, name: string, type: Type) {
    p.variables[name] = type
}


parser_get_variable_type :: proc(p: ^Parser, name: string) -> (Type, bool) {
    return p.variables[name]
}


parser_infer_variable_type :: proc(p: ^Parser, token: Token) -> (type: Type, err: Parsing_Error) {
    found: bool
    type, found = parser_get_variable_type(p, token.value)
    if !found {
        err = .Syntax_Error
        log.errorf("Variable %s used before declaration", token.value)
        return
    }
    return
}


parser_peek :: proc(p: ^Parser) -> Token {
    if p.current_token_number >= len(p.token_stream) {
        return Token{type = .EOF, value = ""}
    }
    return p.token_stream[p.current_token_number]
}


parser_advance :: proc(p: ^Parser) -> (token: Token) {
    if p.current_token_number >= len(p.token_stream) {
        token = Token{type = .EOF, value = ""}
        return
    }
    token = p.token_stream[p.current_token_number]
    p.current_token_number += 1
    return
}


parser_scan :: proc(p: ^Parser) -> (token: Token) {
    for parser_peek(p).type == .Newline {
        parser_advance(p)
    }
    token = parser_advance(p)
    return
}


expect_token_type :: proc(t: Token, expected: Token_Type) -> (err: Parsing_Error) {
    if t.type != expected {
        log.errorf("expected token type: %v got: %v", expected, t.type) 
        err = .Token_Type_Error
        return
    }
    return
}


parse_module_header :: proc(p: ^Parser) -> (node: Module, err: Parsing_Error) {
    keyword_token := parser_scan(p)
    err = expect_token_type(keyword_token, .Module_Keyword)
    if err != nil do return

    name_token := parser_advance(p)
    err = expect_token_type(name_token, .Identifier)
    if err != nil do return

    node = Module{name_token.value} 
    return
}

// TODO: roll up this loop + assert that literal is numeric
parse_layout :: proc(p: ^Parser, is_grid: bool = false) -> (node: Layout, err: Parsing_Error) {
    next_token := parser_advance(p)
    expect_token_type(next_token, .Constant_Assignment_Operator)
    if err != nil do return

    next_token = parser_advance(p)
    expect_token_type(next_token, .Open_Bracket)
    if err != nil do return

    next_token = parser_advance(p)
    expect_token_type(next_token, .Literal)
    if err != nil do return
    if next_token.value == "0" { 
        log.errorf("Layout values must be at least 1")
        err = .Syntax_Error // ??
        return
    }
    if err != nil do return

    node.x = next_token.value

    next_token = parser_advance(p)
    expect_token_type(next_token, .Comma)
    if err != nil do return
    
    next_token = parser_advance(p)
    expect_token_type(next_token, .Literal)
    if err != nil do return
    if next_token.value == "0" { 
        log.errorf("Layout values must be at least 1")
        err = .Syntax_Error // ??
        return
    }
    if err != nil do return

    node.y = next_token.value

    next_token = parser_advance(p)
    expect_token_type(next_token, .Comma)
    if err != nil do return

    next_token = parser_advance(p)
    expect_token_type(next_token, .Literal)
    if err != nil do return
    if next_token.value == "0" { 
        log.errorf("Layout values must be at least 1")
        err = .Syntax_Error // ??
        return
    }
    if err != nil do return

    node.z = next_token.value

    next_token = parser_advance(p)
    expect_token_type(next_token, .Close_Bracket)
    if err != nil do return

    node.is_grid = is_grid
    return
}


parse_initial_identifier :: proc(p: ^Parser, name_token: Token) -> (node: AST_Node, err: Parsing_Error) {
    next_token := parser_scan(p)
    expect_token_type(next_token, .Constant_Assignment_Operator)
    if err != nil do return

    value_token := parser_scan(p)
    #partial switch value_token.type {
    case .Literal:
        node = Constant_Assignment {name_token.value, value_token.value}
        return
    case .Kernel_Keyword:
        delimiter_token := parser_scan(p)
        err = expect_token_type(delimiter_token, .Open_Parenthese)
        if err != nil do return
        args, err := parse_kernel_args(p)
        node = Kernel_Signature{name_token.value, args}
        return
    case:
        log.errorf("Program must begin with either constant declarations or kernel definition.")
        err = .Syntax_Error
        return
    }
}

// TODO: Replace this barbaric dogshit with a lexer refactor 
parse_type :: proc(p: ^Parser, type_token: Token) -> (type: Type, err: Parsing_Error) {
    if type_token.value[0] == '[' {
        end_index: int
        for rune, idx in type_token.value {
            if rune == ']' {
               end_index = idx 
            }
        } 
        n_elements      := type_token.value[1:end_index]
        element_type    := type_token.value[end_index+1:]
        type = Array_Type {n_elements, element_type}
        return
    }
    else {
        element_type := type_token.value[:]
        type = Scalar_Type {element_type}
        return
    }
}


parse_kernel_args :: proc(p: ^Parser) -> (args: [dynamic]Argument, err: Parsing_Error) {
    args = make([dynamic]Argument)
    for {
        arg_name_token := parser_scan(p)
        if arg_name_token.type == .Close_Parenthese do break
        err = expect_token_type(arg_name_token, .Identifier)
        if err != nil do return

        delimiter_token := parser_scan(p)
        err = expect_token_type(delimiter_token, .Colon)
        if err != nil do return

        arg_type_token := parser_scan(p)
        err = expect_token_type(arg_type_token, .Type_Identifier)
        if err != nil do return
        arg_type, err := parse_type(p, arg_type_token)
        if err != nil do return
        
        #partial switch type in arg_type {
        case Array_Type:
            arg_node := Array_Argument{arg_name_token.value, type}
            append(&args, arg_node)
            parser_capture_variable(p, arg_node.name, arg_type)
        case Scalar_Type:
            arg_node := Scalar_Argument{arg_name_token.value, type}
            append(&args, arg_node)
            parser_capture_variable(p, arg_node.name, arg_type)
        }

        delimiter_token = parser_scan(p)
        if delimiter_token.type == .Close_Parenthese do break
        err = expect_token_type(delimiter_token, .Comma)
        if err != nil do return
    }
    return
}


parse_array_index :: proc(p: ^Parser) -> (index: string, err: Parsing_Error) {
    // parser_advance(p)
    index = parser_advance(p).value
    next_token := parser_advance(p)
    err = expect_token_type(next_token, .Close_Bracket) // Need to handle cases like tid.x + 16
    return
}


parse_value :: proc(p: ^Parser, token: Token) -> (node: Value, err: Parsing_Error) {
    #partial switch token.type {
    // TODO: Add Literal type parsing
    case .Literal:
        node = Value{token.value, "", nil}
        return
    case .Builtin_Variable:
        node = Value{token.value, "", nil}
        return
    case .Identifier:
        thread_index: string
        if parser_peek(p).type == .Open_Bracket {
            parser_advance(p)
            thread_index, err = parse_array_index(p)
            if err != nil do return
        }
        else { thread_index =  "" }
        type, err := parser_infer_variable_type(p, token)
        if err != nil do return
        node = Value{token.value, thread_index, type}
        return
    case:
        log.errorf("Unexpected token: %v", token)
        err = .Syntax_Error
        return
    }
}


operator_precedence :: proc(op: string) -> int {
    switch op {
    case "+", "-":
        return 1
    case "*", "/":
        return 2
    case:
        return 0
    }
}


parse_expression :: proc(p: ^Parser, prev_expr: Expression = nil, prev_op_token: Token = Token{}) -> (node: Expression, err: Parsing_Error) {
    lhs: Expression
    next_token := parser_advance(p)

    if next_token.type == .Function_Call {
        _next_token := parser_advance(p)
        err = expect_token_type(_next_token, .Open_Parenthese)
        if err != nil do return
        function_args: [dynamic]Value
        for {
            _next_token = parser_advance(p)
            if _next_token.type == .Close_Parenthese do break
            arg, err := parse_value(p, _next_token)
            append(&function_args, arg)
        }
        another_token := parser_peek(p)
        if is_unary_builtin_function(next_token.value) && another_token.type == .Open_Bracket {
            parser_advance(p)
            function_args[0].thread_id, err = parse_array_index(p)
        }
        lhs = Call_Expression{next_token.value, function_args}
    }
    else {
        lhs, err = parse_value(p, next_token)
        if err != nil do return
    }

    op_token := parser_peek(p)
    #partial switch op_token.type {
    case .Addition_Operator, .Subtraction_Operator, .Multiplication_Operator, .Division_Operator:
        parser_advance(p)
        rhs: Expression
        rhs, err = parse_expression(p)
        if err != nil do return
        #partial switch expr in rhs {
        case Binary_Expression:
            if operator_precedence(expr.op) < operator_precedence(op_token.value) {
                lhs : Expression = Binary_Expression{op_token.value, new_clone(lhs), expr.lhs}
                rhs := expr.rhs
                node = Binary_Expression{expr.op, new_clone(lhs), rhs}
                return
            }
        }
        node = Binary_Expression{op_token.value, new_clone(lhs), new_clone(rhs)}
        return
    // TODO: Add Literal type parsing
    case .Literal, .Newline:
        node = lhs
        return
    case:
        log.errorf("Invalid expression.") 
        err = .Syntax_Error
        return
    }
}



parse_variable_expression :: proc(p: ^Parser, name_token: Token) -> (node: Expression, err: Parsing_Error) {
    next_token := parser_advance(p)
    #partial switch next_token.type {
    case .Open_Bracket:
        thread_index, err := parse_array_index(p)
        if err != nil do return

        next_token = parser_advance(p)
        err = expect_token_type(next_token, .Variable_Assignment_Operator)
        if err != nil do return

        type: Type
        type, err = parser_infer_variable_type(p, name_token)
        if err != nil do return

        value: Expression
        value, err = parse_expression(p)
        if err != nil do return

        node = Variable_Expression{name_token.value, thread_index, type, new_clone(value)}
        return
    case .Colon:
        type_token := parser_advance(p)
        err = expect_token_type(type_token, .Type_Identifier)
        if err != nil do return
        type, err := parse_type(p, type_token)
        if err != nil do return

        next_token := parser_advance(p)
        err = expect_token_type(next_token, .Variable_Assignment_Operator)
        if err != nil do return

        value: Expression
        value, err = parse_expression(p)
        if err != nil do return

        node = Variable_Expression{name_token.value, "", type, new_clone(value)}
        parser_capture_variable(p, name_token.value, type)
        return
    case .Variable_Assignment_Operator:
        type: Type
        type, err = parser_infer_variable_type(p, name_token)
        if err != nil do return

        value: Expression
        value, err = parse_expression(p)
        if err != nil do return

        node = Variable_Expression{name_token.value, "", type, new_clone(value)}
        return
    case .Constant_Assignment_Operator:
        log.errorf("All constants must be declared outside of kernel.") 
        err = .Syntax_Error
        return
    case:
        log.errorf("Invalid expression.") 
        err = .Syntax_Error
        return
    }
}


parse_conditional_expression :: proc(p: ^Parser, keyword_token: Token) -> (node: Conditional_Expression, err: Parsing_Error) {
    condition_tokens: [dynamic]Token
    for {
        token := parser_advance(p)
        if token.type == .Open_Brace do break
        append(&condition_tokens, token)
    }
    switch len(condition_tokens) {
    case 1:
        condition_value, err := parse_value(p, condition_tokens[0])
        condition: Expression = condition_value
        node.condition = new_clone(condition)
    case 3:
        lhs: Expression
        rhs: Expression
        lhs, err = parse_value(p, condition_tokens[0])
        rhs, err = parse_value(p, condition_tokens[2])
        operator := condition_tokens[1].value
        condition: Expression = Binary_Expression{operator, new_clone(lhs), new_clone(rhs)}
        node.condition = new_clone(condition)
    case:
        log.errorf("Invalid conditional expression.. for now...") 
    }
    node.body, err = parse_block(p)
    return
}


parse_block :: proc(p: ^Parser) -> (body: [dynamic]Expression, err: Parsing_Error){
    for {
        next_token := parser_scan(p)
        if next_token.type == .Close_Brace do break
        #partial switch next_token.type {
        case .Identifier: 
            subnode: Expression
            subnode, err = parse_variable_expression(p, next_token)
            append(&body, subnode)
        case .Conditional_Keyword: 
            subnode: Expression
            subnode, err = parse_conditional_expression(p, next_token)
            append(&body, subnode)
        case .For_Keyword: 
            log.errorf("TODO: Implement parsing for %v", next_token.type)
            err = .Unimplemented_Error
            return
        case:
            log.errorf("Unexpected token: %v", next_token)
            err = .Syntax_Error
            return
        }
    }
    return
}


parse :: proc(token_stream: [dynamic]Token) -> (ast: [dynamic]AST_Node, err: Parsing_Error) {
    p := parser_init(token_stream)
    ast = make([dynamic]AST_Node)

    node: AST_Node
    next_token: Token
    
    node, err = parse_module_header(&p)
    if err != nil do return
    append(&ast, node)

    // Grid Layout
    next_token = parser_scan(&p)
    err = expect_token_type(next_token, .Layout_Keyword)
    node, err = parse_layout(&p, true)
    if err != nil do return
    append(&ast, node)

    // Block Layout
    next_token = parser_scan(&p)
    err = expect_token_type(next_token, .Layout_Keyword)
    node, err = parse_layout(&p)
    if err != nil do return
    append(&ast, node)

    next_token = parser_scan(&p)
    err = expect_token_type(next_token, .Identifier)
    if err != nil do return

    node, err = parse_initial_identifier(&p, next_token)
    if err != nil do return

    #partial switch n in node {
    case Constant_Assignment:
        append(&ast, node)

    case Kernel_Signature:
        sig := n
        body := make([dynamic]Expression)

        next_token = parser_scan(&p)
        err = expect_token_type(next_token, .Open_Brace)
        if err != nil do return

        for {
            next_token = parser_scan(&p)
            if next_token.type == .Close_Brace do break

            #partial switch next_token.type {
            case .Identifier: 
                subnode: Expression
                subnode, err = parse_variable_expression(&p, next_token)
                append(&body, subnode)
            case .Conditional_Keyword: 
                subnode: Expression
                subnode, err = parse_conditional_expression(&p, next_token)
                append(&body, subnode)
            case .For_Keyword: 
                log.errorf("TODO: Implement parsing for %v", next_token.type)
                err = .Unimplemented_Error
                return
            case:
                log.errorf("Unexpected token: %v", next_token)
                err = .Syntax_Error
                return
            }
        }
        parser_scan(&p)
        node = Kernel{sig, body}
        append(&ast, node)
    }
    return
}

