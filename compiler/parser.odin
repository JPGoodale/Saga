package saga_compiler
import "core:log"
import "core:fmt"
import "core:strings"
import "core:strconv"


Parsing_Error :: enum {
    Type_Error,
    Syntax_Error,
    Unimplemented_Error
}


Parser :: struct {
    token_stream:           [dynamic]Token,
    current_token_number:   int,
    variables:              map[string]Type
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


parser_infer_variable_type :: proc(p: ^Parser, name: string) -> (type: Type, value_type: string, err: Parsing_Error) {
    found: bool
    type, found = parser_get_variable_type(p, name)
    if !found {
        err = .Syntax_Error
        log.errorf("Variable %s used before declaration", name)
        return
    }
    switch t in type {
    case Array_Type:
        value_type = t.element_type
    case Scalar_Type:
        value_type = t.variant
    }
    return
}


parser_peek :: proc(p: ^Parser) -> (current_token: Token) {
    if p.current_token_number >= len(p.token_stream) {
        current_token = Token{.EOF, ""}
        return
    }
    current_token = p.token_stream[p.current_token_number]
    return
}


parser_advance :: proc(p: ^Parser) -> (current_token: Token) {
    current_token = parser_peek(p)
    p.current_token_number += 1
    return
}


parser_scan :: proc(p: ^Parser) -> (current_token: Token) {
    for parser_peek(p).type == .Newline {
        p.current_token_number += 1
    }
    current_token = parser_advance(p)
    return
}


expect_token_type :: proc(t: Token, expected: Token_Type, error_message: string = "") -> (err: Parsing_Error) {
    if t.type != expected {
        log.errorf("expected token type: %v got: %v", expected, t.type) 
        log.error(error_message)
        err = .Syntax_Error
        return
    }
    return
}


parse_module_header :: proc(p: ^Parser) -> (node: Module, err: Parsing_Error) {
    keyword_token := parser_scan(p)
    expect_token_type(keyword_token, .Module_Keyword, "All Saga files must begin with the module keyword") or_return

    name_token := parser_advance(p)
    expect_token_type(name_token, .Identifier, "Module must have a name") or_return

    node = Module{name_token.value} 
    return
}


parse_layout :: proc(p: ^Parser, is_grid: bool = false) -> (node: Layout, err: Parsing_Error) {
    op_token := parser_advance(p)
    expect_token_type(op_token, .Constant_Assignment_Operator, "Layouts must be declared as constants") or_return

    delimter_token := parser_advance(p)
    expect_token_type(delimter_token, .Open_Bracket, "Layouts must be arrays") or_return
    
    // x
    value_token := parser_advance(p)
    expect_token_type(value_token, .Integer_Literal, "Layout values must be unsigned integers") or_return

    if value_token.value == "0" { 
        log.errorf("Layout values must be greater than or equal to 1")
        err = .Syntax_Error
        return
    }
    if err != nil do return

    node.x = value_token.value

    delimter_token = parser_advance(p)
    expect_token_type(delimter_token, .Comma, "Layout must contain both x, y and z values. Perhaps you forgot a comma?") or_return
    
    // y
    value_token = parser_advance(p)
    expect_token_type(value_token, .Integer_Literal, "Layout values must be unsigned integers") or_return

    if value_token.value == "0" { 
        log.errorf("Layout values must be greater than or equal to 1")
        err = .Syntax_Error
        return
    }
    if err != nil do return

    node.y = value_token.value

    delimter_token = parser_advance(p)
    expect_token_type(delimter_token, .Comma, "Layout must contain both x, y and z values. Perhaps you forgot a comma?") or_return
    
    // z
    value_token = parser_advance(p)
    expect_token_type(value_token, .Integer_Literal, "Layout values must be unsigned integers") or_return

    if value_token.value == "0" { 
        log.errorf("Layout values must be greater than or equal to 1")
        err = .Syntax_Error
        return
    }
    if err != nil do return

    node.z = value_token.value

    delimter_token = parser_advance(p)
    expect_token_type(delimter_token, .Close_Bracket, "Perhaps you forgot a closing bracket") or_return

    node.is_grid = is_grid
    return
}


// NOTE: We could consider allowing the values of file scope constants to be expressions if we include 
// a constant folding pass, however, I prefer the contents of a Saga file to be restricted what will 
// actually be ran on the device...
parse_initial_identifier :: proc(p: ^Parser, name_token: Token) -> (node: AST_Node, err: Parsing_Error) {
    op_token := parser_scan(p)
    expect_token_type(op_token, .Constant_Assignment_Operator, "Only constant, kernel and procedure declarations are allowed at file scope") or_return

    value_token := parser_advance(p)

    #partial switch value_token.type {
    case .Float_Literal, .Integer_Literal, .Boolean_Literal:
        node = Constant_Assignment {name_token.value, value_token.value}
        return
    case .Kernel_Keyword:
        delimiter_token := parser_advance(p)
        expect_token_type(delimiter_token, .Open_Parenthese, "Missing parenthese after kernel keyword") or_return

        args, err := parse_kernel_args(p)
        node = Kernel_Signature{name_token.value, args}
        return
    case .Procedure_Keyword:
        log.errorf("Coming soon to a compiler near you!")
        err = .Unimplemented_Error
        return
    case:
        log.errorf("Program must begin with either constant, kernel or procedure declarations")
        err = .Syntax_Error
        return
    }
}


parse_kernel_args :: proc(p: ^Parser) -> (nodes: [dynamic]Argument, err: Parsing_Error) {
    nodes = make([dynamic]Argument)
    for {
        name_token := parser_scan(p)
        if name_token.type == .Close_Parenthese do break
        expect_token_type(name_token, .Identifier) or_return

        delimiter_token := parser_advance(p)
        expect_token_type(delimiter_token, .Colon) or_return

        type: Type
        type_token := parser_advance(p)
        #partial switch type_token.type {
        case .Array_Type:
            type = parse_array_type(type_token.value) or_return
        case .Scalar_Type:
            type = Scalar_Type{type_token.value}
        case:
            log.errorf("Expected token of either %v or %v, got %v", Token_Type.Array_Type, Token_Type.Scalar_Type, type_token.type)
            log.error("Kernel Arguments must be statically typed")
            err = .Syntax_Error
            return
        }

        node := Argument{name_token.value, type}
        append(&nodes, node)
        parser_capture_variable(p, node.name, type)

        delimiter_token = parser_advance(p)
        if delimiter_token.type == .Close_Parenthese do break
        expect_token_type(delimiter_token, .Comma) or_return
    }
    return
}


parse_array_type :: proc(type_string: string) -> (node: Array_Type, err: Parsing_Error) {
    end_index: int
    for rune, idx in type_string {
        if rune == ']' {
           end_index = idx 
        }
    } 
    // If array type has more than one dimension, i.e. [128x128]f32, we flatten it
    // Though we might want to refactor this for more dimension aware algorithms
    found, idx := contains_at(type_string, "x") 
    if found {
        n := atoi(type_string[1:idx]) * atoi(type_string[idx+1:end_index])
        node.n_elements = fmt.tprint(n)
    }
    else {
        node.n_elements = type_string[1:end_index]
    }
    node.element_type = type_string[end_index+1:]
    return
}


parse_thread_idx :: proc(p: ^Parser) -> (node: Thread_Idx, err: Parsing_Error) {
    value_token := parser_advance(p)
    thread := Thread{value_token.value}

    next_token := parser_advance(p)
    #partial switch next_token.type {
    case .Close_Bracket:
        node = thread
        return
    case .Addition_Operator, .Subtraction_Operator, 
         .Multiplication_Operator, .Division_Operator,
         .Modulo_Operator, .Remainder_Operator:

        operator := next_token.value

        lhs: Expression
        lhs = thread

        rhs: Expression
        rhs = parse_expression(p, "u32") or_return

        #partial switch expr in rhs {
        case Binary_Expression:
            if operator_precedence(expr.op) < operator_precedence(operator) {
                _lhs:  Expression = Binary_Expression{operator, new_clone(lhs), expr.lhs}
                _rhs: ^Expression = expr.rhs
                node = Binary_Expression{expr.op, new_clone(_lhs), _rhs}
                parser_advance(p)
                return
            }
        }

        node = Binary_Expression{operator, new_clone(lhs), new_clone(rhs)}
        parser_advance(p)
        return
    case:
        log.errorf("Invalid expression.") 
        err = .Syntax_Error
        return
    }
}


parse_expression :: proc(p: ^Parser, context_type: string) -> (node: Expression, err: Parsing_Error) {
    lhs: Expression
    value_token := parser_advance(p)

    #partial switch value_token.type {
    case .Unary_Builtin_Function:
        lhs = parse_unary_builtin_function(p, value_token.value) or_return
    case .Binary_Builtin_Function:
        lhs = parse_binary_builtin_function(p, value_token.value) or_return
    case .Builtin:
        lhs = Thread{value_token.value}
    case .Float_Literal, .Integer_Literal:
        lhs = Literal{value_token.value, context_type}
    case .Identifier:
        type, value_type := parser_infer_variable_type(p, value_token.value) or_return
        thread_idx: Thread_Idx = nil
        if parser_peek(p).type == .Open_Bracket {
            parser_advance(p) 
            thread_idx = parse_thread_idx(p) or_return
        }
        lhs = Identifier{value_token.value, type, thread_idx}
    }

    op_token := parser_peek(p)
    #partial switch op_token.type {
    case .Addition_Operator, .Subtraction_Operator, 
         .Multiplication_Operator, .Division_Operator,
         .Modulo_Operator, .Remainder_Operator,
         .Less_Than_Operator, .Less_Than_Or_Equal_To_Operator,
         .Greater_Than_Operator, .Greater_Than_Or_Equal_To_Operator,
         .Equals_Operator, .Not_Equal_Operator,
         .Left_Shift_Operator, .Right_Shift_Operator,
         .And_Operator, .Or_Operator, 
         .Bitwise_Or_Operator, .Bitwise_Xor_Operator,
         .Bitwise_And_Operator, .Bitwise_And_Not_Operator:

        operator := op_token.value
        parser_advance(p)

        rhs: Expression
        rhs = parse_expression(p, context_type) or_return

        #partial switch expr in rhs {
        case Binary_Expression:
            if operator_precedence(expr.op) < operator_precedence(operator) {
                _lhs:  Expression = Binary_Expression{operator, new_clone(lhs), expr.lhs}
                _rhs: ^Expression = expr.rhs
                node = Binary_Expression{expr.op, new_clone(_lhs), _rhs}
                return
            }
        }

        node = Binary_Expression{operator, new_clone(lhs), new_clone(rhs)}
        return
    case .Newline, .Open_Brace, .Close_Bracket:
        node = lhs
        return
    case:
        log.errorf("Invalid expression.") 
        err = .Syntax_Error
        return
    }
}


operator_precedence :: proc(op: string) -> int {
    switch op {
    case "||":
        return 1
    case "&&":
        return 2
    case "==", "!=", "<", "<=", ">", ">=":
        return 3
    case "|":
        return 4
    case "~":
        return 5
    case "&":
        return 6
    case "<<", ">>":
        return 7
    case "+", "-":
        return 8
    case "*", "/", "%", "%%":
        return 9
    case "&~":
        return 10
    case "!":
        return 11
    case:
        return 0
    }
}


parse_unary_builtin_function :: proc(p: ^Parser, callee: string) -> (node: Unary_Call_Expression, err: Parsing_Error) {
    delimiter_token := parser_advance(p)
    expect_token_type(delimiter_token, .Open_Parenthese, "Function call must have parentheses") or_return

    operand: Expression
    value_token := parser_advance(p)
    #partial switch value_token.type {
    case .Integer_Literal, .Float_Literal:
        operand = Literal{value_token.value, "f32"}
    case .Identifier:
        type, value_type := parser_infer_variable_type(p, value_token.value) or_return

        if !is_float(value_type) {
            log.errorf("%v function requires a float operand, got type: %v", callee, value_type)
            err = .Type_Error
            return
        }

        thread_idx: Thread_Idx = nil
        if parser_peek(p).type == .Open_Bracket {
            parser_advance(p) 
            thread_idx = parse_thread_idx(p) or_return
        }

        operand = Identifier{value_token.value, type, thread_idx}

    case .Unary_Builtin_Function:
        log.errorf("Coming soon to a compiler near you!")
        err = .Unimplemented_Error
        return
    case .Binary_Builtin_Function:
        log.errorf("Coming soon to a compiler near you!")
        err = .Unimplemented_Error
        return
    case:
        log.errorf("Invalid expression.") 
        err = .Syntax_Error
        return
    }

    delimiter_token = parser_advance(p)
    expect_token_type(delimiter_token, .Close_Parenthese, "Function call must have parentheses") or_return

    node = Unary_Call_Expression{callee, new_clone(operand)}
    return
}


parse_binary_builtin_function :: proc(p: ^Parser, callee: string) -> (node: Binary_Call_Expression, err: Parsing_Error) {
    delimter_token := parser_advance(p)
    expect_token_type(delimter_token, .Open_Parenthese, "Function call must have parentheses") or_return

    operands: [2]^Expression
    for i in 0..<2 {
        value_token := parser_advance(p)

        #partial switch value_token.type {
        case .Float_Literal:
            operand: Expression = Literal{value_token.value, "f32"}
            operands[i] = new_clone(operand)
        case .Integer_Literal:
            operand: Expression = Literal{value_token.value, "i32"}
            operands[i] = new_clone(operand)
        case .Identifier:
            type, value_type := parser_infer_variable_type(p, value_token.value) or_return

            thread_idx: Thread_Idx = nil
            if parser_peek(p).type == .Open_Bracket {
                parser_advance(p) 
                thread_idx = parse_thread_idx(p) or_return
            }

            operand: Expression = Identifier{value_token.value, type, thread_idx}
            operands[i] = new_clone(operand)

        case .Unary_Builtin_Function:
            log.errorf("Coming soon to a compiler near you!")
            err = .Unimplemented_Error
            return
        case .Binary_Builtin_Function:
            log.errorf("Coming soon to a compiler near you!")
            err = .Unimplemented_Error
            return
        case:
            log.errorf("Invalid expression.") 
            err = .Syntax_Error
            return
        }

        delimiter_token := parser_advance(p)
        if i == 0 {
            expect_token_type(delimiter_token, .Comma, "Binary functions require two operands.. Perhaps you forgot a comma?") or_return
        } else {
            expect_token_type(delimiter_token, .Close_Parenthese, "Binary functions only have two operands.. Perhaps you forgot a closing parenthese?") or_return
        }
    }

    // TODO: Make sure operand types match

    node = Binary_Call_Expression{callee, operands}
    return
}


parse_variable_expression :: proc(p: ^Parser, name_token: Token) -> (node: Expression, err: Parsing_Error) {
    next_token := parser_advance(p)

    #partial switch next_token.type {
    case .Open_Bracket:
        thread_index := parse_thread_idx(p) or_return

        op_token := parser_advance(p)
        expect_token_type(op_token, .Variable_Assignment_Operator) or_return
        type, value_type := parser_infer_variable_type(p, name_token.value) or_return

        value := parse_expression(p, value_type) or_return
        node = Variable_Expression{name_token.value, thread_index, type, new_clone(value)}
        return
    case .Colon:
        type: Type
        value_type: string
        type_token := parser_advance(p)

        #partial switch type_token.type {
        case .Array_Type:
            array_type := parse_array_type(type_token.value) or_return
            type = array_type
            value_type = array_type.element_type
        case .Scalar_Type:
            type = Scalar_Type{type_token.value}
            value_type = type_token.value
        case:
            log.errorf("Invalid expression.") 
            err = .Syntax_Error
            return
        }

        if parser_peek(p).type == .Newline {
            node = Variable_Declaration{name_token.value, type}
            parser_capture_variable(p, name_token.value, type)
            return
        }

        op_token := parser_advance(p)
        expect_token_type(op_token, .Variable_Assignment_Operator) or_return

        value := parse_expression(p, value_type) or_return

        node = Variable_Expression{name_token.value, nil, type, new_clone(value)}
        parser_capture_variable(p, name_token.value, type)
        return
    case .Variable_Assignment_Operator:
        type, value_type := parser_infer_variable_type(p, name_token.value) or_return
        value := parse_expression(p, value_type) or_return
        node = Variable_Expression{name_token.value, nil, type, new_clone(value)}
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


parse_conditional_expression :: proc(p: ^Parser) -> (node: Conditional_Expression, err: Parsing_Error) {
    expr := parse_condition(p) or_return
    node.condition = new_clone(expr)

    delimter_token := parser_advance(p)
    expect_token_type(delimter_token, .Open_Brace) or_return

    node.body, err = parse_block(p)
    return
}

// NOTE: Can't give proper type errors here, might need a pass for that
parse_condition :: proc(p: ^Parser) -> (node: Expression, err: Parsing_Error) {
    lhs: Expression
    value_token := parser_advance(p)

    #partial switch value_token.type {
    case .Unary_Builtin_Function:
        lhs = parse_unary_builtin_function(p, value_token.value) or_return
    case .Binary_Builtin_Function:
        lhs = parse_binary_builtin_function(p, value_token.value) or_return
    case .Builtin:
        lhs = Thread{value_token.value}
    case .Float_Literal:
        lhs = Literal{value_token.value, "f32"}
    case .Integer_Literal:
        lhs = Literal{value_token.value, "i32"}
    case .Identifier:
        type, value_type := parser_infer_variable_type(p, value_token.value) or_return
        thread_idx: Thread_Idx = nil
        if parser_peek(p).type == .Open_Bracket {
            parser_advance(p) 
            thread_idx = parse_thread_idx(p) or_return
        }
        lhs = Identifier{value_token.value, type, thread_idx}
    }

    op_token := parser_peek(p)
    #partial switch op_token.type {
    case .Less_Than_Operator, .Less_Than_Or_Equal_To_Operator,
         .Greater_Than_Operator, .Greater_Than_Or_Equal_To_Operator,
         .Equals_Operator, .Not_Equal_Operator:

        operator := op_token.value
        parser_advance(p)

        rhs: Expression
        rhs = parse_expression(p, "u32") or_return

        #partial switch expr in rhs {
        case Binary_Expression:
            #partial switch t in expr.rhs {
            case Binary_Expression:
                // This is dumbest shit I have ever done.
                comparison_op_map := make(map[string]bool)
                comparison_op_map["<"]  = true
                comparison_op_map[">"]  = true
                comparison_op_map["<="] = true
                comparison_op_map[">="] = true
                comparison_op_map["=="] = true
                comparison_op_map["!="] = true
                if !(t.op in comparison_op_map) {
                    log.errorf("Invalid expression.") 
                    err = .Syntax_Error
                    return
                }
            case:
                // TODO: Make sure that rhs is a boolean value
            }

            if operator_precedence(expr.op) < operator_precedence(operator) {
                _lhs:  Expression = Binary_Expression{operator, new_clone(lhs), expr.lhs}
                _rhs: ^Expression = expr.rhs
                node = Binary_Expression{expr.op, new_clone(_lhs), _rhs}
                return
            }
        }

        node = Binary_Expression{operator, new_clone(lhs), new_clone(rhs)}
        return
    case .Open_Brace:
        #partial switch value_token.type {
        case .Boolean_Literal:
            node = Literal{value_token.value, "bool"}
            return
        case .Identifier:
            type, value_type := parser_infer_variable_type(p, value_token.value) or_return
            #partial switch t in type {
            case Scalar_Type:
                switch {
                case t.variant == "bool":
                    node = Identifier{value_token.value, t, nil}
                    return
                case:
                    log.errorf("Invalid expression.") 
                    err = .Syntax_Error
                    return
                }
            case:
                log.errorf("Invalid expression.") 
                err = .Syntax_Error
                return
            }
        case:
            log.errorf("Invalid expression.") 
            err = .Syntax_Error
            return
        }
    case:
        log.errorf("Invalid expression.") 
        err = .Syntax_Error
        return
    }
}


parse_loop_expression :: proc(p: ^Parser) -> (node: Loop_Expression, err: Parsing_Error) {
    name_token := parser_scan(p)
    expect_token_type(name_token, .Identifier, "Expected an index identifier") or_return

    parser_capture_variable(p, name_token.value, Scalar_Type{"u32"})

    keyword_token := parser_scan(p)
    expect_token_type(keyword_token, .In_Keyword, "Missing an 'in' keyword for loop expression") or_return

    value_token := parser_scan(p)
    #partial switch value_token.type {
    case .Identifier:
        parser_infer_variable_type(p, value_token.value) or_return
        node.start = Identifier{value_token.value, Scalar_Type{"u32"}, nil}
    case .Integer_Literal, .Float_Literal:
        node.start = Literal{value_token.value, "u32"}
    case:
        log.errorf("Expected a scalar value for start index of loop but got: %v \n", value_token.value)
        err = .Syntax_Error
        return
    }

    op_token := parser_scan(p)
    expect_token_type(op_token, .Range_Operator, "Missing a range operator for loop expression") or_return

    value_token = parser_scan(p)
    #partial switch value_token.type {
    case .Identifier:
        parser_infer_variable_type(p, value_token.value) or_return
        node.end = Identifier{value_token.value, Scalar_Type{"u32"}, nil}
    case .Integer_Literal, .Float_Literal:
        node.end = Literal{value_token.value, "u32"}
    case:
        log.errorf("Expected a scalar value for end index of loop but got: %v \n", value_token.value)
        err = .Syntax_Error
        return
    }

    delimiter_token := parser_scan(p)
    expect_token_type(delimiter_token, .Open_Brace) or_return

    node.body, err = parse_block(p)
    return
}


parse_block :: proc(p: ^Parser) -> (body: [dynamic]Expression, err: Parsing_Error){
    for {
        subnode: Expression
        next_token := parser_scan(p)
        if next_token.type == .Close_Brace do break

        #partial switch next_token.type {
        case .Identifier: 
            subnode = parse_variable_expression(p, next_token) or_return
            append(&body, subnode)
        case .Conditional_Keyword: 
            subnode = parse_conditional_expression(p) or_return
            append(&body, subnode)
        case .For_Keyword: 
            subnode = parse_loop_expression(p) or_return
            append(&body, subnode)
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
    
    node = parse_module_header(&p) or_return
    append(&ast, node)

    // Grid Layout
    next_token = parser_scan(&p)
    expect_token_type(next_token, .Layout_Keyword, "Grid layout must be declared at the top of every Saga file") or_return

    node = parse_layout(&p, true) or_return
    append(&ast, node)

    // Block Layout
    next_token = parser_scan(&p)
    expect_token_type(next_token, .Layout_Keyword, "Block layout must be declared at the top of every Saga file") or_return

    node = parse_layout(&p) or_return
    append(&ast, node)

    next_token = parser_scan(&p)
    expect_token_type(next_token, .Identifier, "Only declarations are allowed at file scope") or_return

    node = parse_initial_identifier(&p, next_token) or_return

    #partial switch n in node {
    case Constant_Assignment:
        append(&ast, node)

    case Kernel_Signature:
        sig := n
        body := make([dynamic]Expression)

        next_token = parser_scan(&p)
        expect_token_type(next_token, .Open_Brace) or_return

        body = parse_block(&p) or_return

        parser_scan(&p)
        node = Kernel{sig, body}
        append(&ast, node)
    }
    return
}

