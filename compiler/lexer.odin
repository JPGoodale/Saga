package saga_compiler
import "core:os"
import "core:io"
import "core:fmt"
import "core:log"
import "core:bufio"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import pp "../tools/pretty_printer"


Token_Type :: enum {
    Identifier,
    Array_Type,
    Scalar_Type,
    Integer_Literal,
    Float_Literal,
    Boolean_Literal,
    Builtin,
    Unary_Builtin_Function,
    Binary_Builtin_Function,

    // Delimters 
    Colon,
    Comma,
    Open_Parenthese,
    Close_Parenthese,
    Open_Brace,
    Close_Brace,
    Open_Bracket,
    Close_Bracket,
    Newline,
    EOF,

    // Keywords
    Module_Keyword,
    Layout_Keyword,
    Kernel_Keyword,
    Procedure_Keyword,
    Conditional_Keyword,
    For_Keyword,
    In_Keyword,

    // Operators
    Constant_Assignment_Operator,
    Variable_Assignment_Operator,
    Addition_Operator,
    Subtraction_Operator,
    Multiplication_Operator,
    Division_Operator,
    Modulo_Operator,
    Remainder_Operator,

    Bitwise_Or_Operator,
    Bitwise_Xor_Operator,
    Bitwise_And_Operator,
    Bitwise_And_Not_Operator,
    Left_Shift_Operator,
    Right_Shift_Operator,

    Addition_Assignment_Operator,
    Subtraction_Assignment_Operator,
    Multiplication_Assignment_Operator,
    Division_Assignment_Operator,
    Modulo_Assignment_Operator,
    Remainder_Assignment_Operator,

    Bitwise_Or_Assignment_Operator,
    Bitwise_Xor_Assignment_Operator,
    Bitwise_And_Assignment_Operator,
    Bitwise_And_Not_Assignment_Operator,
    Left_Shift_Assignment_Operator,
    Right_Shift_Assignment_Operator,

    Less_Than_Operator,
    Less_Than_Or_Equal_To_Operator,
    Greater_Than_Operator,
    Greater_Than_Or_Equal_To_Operator,
    Equals_Operator,
    Not_Equal_Operator,

    Not_Operator,
    And_Operator,
    Or_Operator,

    And_Assignment_Operator,
    Or_Assignment_Operator,

    Range_Operator,

    // Comments
    Single_Line_Comment,
    Multi_Line_Comment,
}


Token :: struct {
    type:       Token_Type,
    value:      string,
}


is_bool :: proc(r: string) -> bool {
    switch r {
    case "true", "false":
        return true 
    }
    return false
}


is_operator :: proc(r: rune) -> bool {
    switch r {
    case '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', ':', '~':
        return true 
    }
    return false
}


is_delimiter :: proc(r: rune) -> bool {
    switch r {
    case '(', ')', '[', ']', '{', '}', ',':
        return true
    }
    return false
}


is_scalar_type :: proc(s: string) -> bool {
    switch s {
    case "u8", "u16", "u32", "u64", "u128", "i8", "i16", "i32", "i64", "i128", "f16", "f32", "f64", "bool":
        return true
    }
    return false
}


is_integer :: proc(s: string) -> bool {
    switch s {
    case "u8", "u16", "u32", "u64", "u128", "i8", "i16", "i32", "i64", "i128":
        return true
    }
    return false
}


is_float :: proc(s: string) -> bool {
    switch s {
    case "f16", "f32", "f64":
        return true
    }
    return false
}


is_array_type :: proc(s: string) -> bool {
    if len(s) > 0 && s[0] == '[' {
        parts := strings.split(s[1:], "]")
        if len(parts) == 2 {
            return is_scalar_type(parts[1])
        }
    }
    return false
}


is_builtin :: proc(s: string) -> bool {
    switch s {
    case "thread_idx.x", "thread_idx.y", "thread_idx.z", "thread.x", "thread.y", "thread.z", 
        "block_idx.x", "block_idx.y", "block_idx.z", "block.x", "block.y", "block.z",
        "block_dim.x", "block_dim.y", "block_dim.z":
        return true
    }
    return false
}


is_unary_builtin_function :: proc(s: string) -> bool {
    switch s {
    case "sin", "cos", "tanh", "exp", "log", "exp2", "log2", "sqrt", "rsqrt", "rcp":
        return true
    }
    return false
}


is_binary_builtin_function :: proc(s: string) -> bool {
    switch s {
    case "min", "max": 
        return true
    }
    return false
}


is_hex_digit :: proc(r: rune) -> bool {
    return is_digit(r) || (r >= 'a' && r <= 'f') || (r >= 'A' && r <= 'F')
}


handle_newline :: proc(data: []byte, start: int) -> (int, []byte) {
    r, width := utf8.decode_rune(data[start:])
    if r == '\n' {
        return start + width, data[start : start+width]
    }
    return 0, nil
}


handle_whitespace :: proc(data: []byte, start: int) -> (int, []byte) {
    end := start
    for end < len(data) && is_space(rune(data[end])) && data[end] != '\n' {
        end += 1
    }
    if end > start {
        return end, data[start:end]
    }
    return 0, nil
}


handle_comment :: proc(data: []byte, start: int) -> (int, []byte) {
    if start + 1 >= len(data) {
        return 0, nil
    }
    
    if data[start] == '/' && data[start + 1] == '/' {
        end := start + 2
        for end < len(data) && data[end] != '\n' {
            end += 1
        }
        return end, data[start:end]
    }
    
    if data[start] == '/' && data[start + 1] == '*' {
        end := start + 2
        for end + 1 < len(data) {
            if data[end] == '*' && data[end + 1] == '/' {
                end += 2
                return end, data[start:end]
            }
            end += 1
        }
    }
    
    return 0, nil
}


handle_array_type :: proc(data: []byte, start: int) -> (int, []byte) {
    r, width := utf8.decode_rune(data[start:])
    if r == '[' {
        end := start + width
        bracket_count := 1
        for end < len(data) {
            r, w := utf8.decode_rune(data[end:])
            end += w
            if r == '[' do bracket_count += 1 
            else if r == ']' {
                bracket_count -= 1
                if bracket_count == 0 {
                    type_start := end
                    for end < len(data) {
                        r, w = utf8.decode_rune(data[end:])
                        if is_space(r) || is_operator(r) || is_delimiter(r) do break
                        end += w
                    }
                    if is_scalar_type(string(data[type_start:end])) {
                        return end, data[start:end]
                    }
                    break
                }
            }
        }
    }
    return 0, nil
}


handle_delimiter :: proc(data: []byte, start: int) -> (int, []byte) {
    r, width := utf8.decode_rune(data[start:])
    if is_delimiter(r) {
        return start + width, data[start : start+width]
    }
    return 0, nil
}


handle_range_operator :: proc(data: []byte, start: int) -> (int, []byte) {
    if start + 1 < len(data) && data[start] == '.' && data[start+1] == '.' {
        return start + 2, data[start : start+2]
    }
    return 0, nil
}


handle_operator :: proc(data: []byte, start: int) -> (int, []byte) {
    r, width := utf8.decode_rune(data[start:])
    if is_operator(r) {
        end := start + width
        for end < len(data) {
            r, width := utf8.decode_rune(data[end:])
            if !is_operator(r) do break
            end += width
        }
        return end, data[start:end]
    }
    return 0, nil
}


handle_identifier :: proc(data: []byte, start: int) -> (int, []byte) {
    r, width := utf8.decode_rune(data[start:])
    if is_alpha(r) || r == '_' {
        end := start + width
        has_dot := false
        for end < len(data) {
            r, w := utf8.decode_rune(data[end:])
            if !is_alpha(r) && !is_digit(r) && r != '_' {
                if r == '.' && !has_dot {
                    // Check for range operator
                    if end + 1 < len(data) && data[end + 1] == '.' {
                        break  // Stop at the range operator
                    }
                    // Check for .x, .y, .z
                    if end + 1 < len(data) {
                        next_char := data[end + 1]
                        if next_char == 'x' || next_char == 'y' || next_char == 'z' {
                            if end + 2 >= len(data) || (!is_alpha(rune(data[end+2])) && !is_digit(rune(data[end+2])) && data[end+2] != '_') {
                                end += 2  // Include .x, .y, or .z
                                break
                            }
                        }
                    }
                    has_dot = true
                    end += w
                    continue
                }
                break
            }
            end += w
        }
        return end, data[start:end]
    }
    return 0, nil
}


handle_numeric_literal :: proc(data: []byte, start: int) -> (int, []byte) {
    if start >= len(data) do return 0, nil

    end := start
    is_hex := false
    has_dot := false
    has_exponent := false

    // Check for hexadecimal prefix
    if end + 1 < len(data) && data[end] == '0' && (data[end+1] == 'x' || data[end+1] == 'X') {
        is_hex = true
        end += 2
    }

    for end < len(data) {
        r, width := utf8.decode_rune(data[end:])
        if is_hex {
            if !is_hex_digit(r) do break
        } else {
            if !is_digit(r) {
                if r == '.' && !has_dot && !has_exponent {
                    // Check for range operator
                    if end + 1 < len(data) && data[end + 1] == '.' {
                        return end, data[start:end]  // Stop at the first dot of range operator
                    }
                    has_dot = true
                } else if (r == 'e' || r == 'E') && !has_exponent {
                    has_exponent = true
                    if end + 1 < len(data) && (data[end+1] == '+' || data[end+1] == '-') {
                        end += width
                    }
                } else {
                    break
                }
            }
        }
        end += width
    }

    if end > start {
        return end, data[start:end]
    }
    return 0, nil
}


split_tokens :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: bufio.Scanner_Error, final_token: bool) {
    start := 0

    handlers: []proc([]byte, int) -> (int, []byte) = {
        handle_newline,
        handle_whitespace,
        handle_comment,
        handle_array_type,
        handle_delimiter,
        handle_range_operator,
        handle_operator,
        handle_identifier,
        handle_numeric_literal,
    }

    for handler in handlers {
        advance, token = handler(data, start)
        if advance > 0 {
            return
        }
    }

    if at_eof && len(data) > start {
        advance = len(data)
        token = data[start:]
        final_token = true
    }

    advance = start
    return
}


Location :: struct {
    line:   int,
    col:    int
}


Lexer_Error :: enum {
    Invalid_Token,
}


Lexer :: struct {
    token_stream:   [dynamic]Token,
    max_capacity:   int,
    location:       Location
}


lexer_init :: proc(lexer: ^Lexer, initial_capacity: int = 1024) {
    lexer.token_stream = make([dynamic]Token, 0, initial_capacity)
    lexer.max_capacity = initial_capacity
}


lexer_destroy :: proc(lexer: ^Lexer) {
    delete(lexer.token_stream)
}


lex :: proc(lexer: ^Lexer, reader_stream: io.Reader) -> (tokens: [dynamic]Token, err: Lexer_Error) {
    clear(&lexer.token_stream)
    lexer.location.line = 1
    lexer.location.col = 1

    scanner: bufio.Scanner 
    bufio.scanner_init(&scanner, reader_stream)
    scanner.split = split_tokens

    for bufio.scanner_scan(&scanner) {
        token: Token 
        token_str := bufio.scanner_text(&scanner)
        token_start := rune(token_str[0])
        token_start_col := lexer.location.col

        switch {
        // Keywords
        case token_str == "module":
            token = Token {.Module_Keyword, token_str} 
        case token_str == "BLOCKS", token_str == "THREADS":
            token = Token {.Layout_Keyword, token_str} 
        case token_str == "kernel":
            token = Token {.Kernel_Keyword, token_str} 
        case token_str == "proc":
            token = Token {.Procedure_Keyword, token_str} 
        case token_str == "if", token_str == "else":
            token = Token {.Conditional_Keyword, token_str} 
        case token_str == "for": 
            token = Token {.For_Keyword, token_str} 
        case token_str == "in": 
            token = Token {.In_Keyword, token_str} 

        // Operators
        case token_str == "::":
            token = Token {.Constant_Assignment_Operator, token_str} 
        case token_str == "=", token_str == ":=":
            token = Token {.Variable_Assignment_Operator, token_str} 
        case token_str == "+":
            token = Token {.Addition_Operator, token_str}
        case token_str == "-":
            token = Token {.Subtraction_Operator, token_str}
        case token_str == "*":
            token = Token {.Multiplication_Operator, token_str}
        case token_str == "/":
            token = Token {.Division_Operator, token_str}
        case token_str == "%":
            token = Token {.Modulo_Operator, token_str}
        case token_str == "%%":
            token = Token {.Remainder_Operator, token_str}

        case token_str == "|":
            token = Token {.Bitwise_Or_Operator, token_str}
        case token_str == "~":
            token = Token {.Bitwise_Xor_Operator, token_str}
        case token_str == "&":
            token = Token {.Bitwise_And_Operator, token_str}
        case token_str == "&~":
            token = Token {.Bitwise_And_Not_Operator, token_str}
        case token_str == "<<":
            token = Token {.Left_Shift_Operator, token_str}
        case token_str == ">>":
            token = Token {.Right_Shift_Operator, token_str}

        case token_str == "+=":
            token = Token {.Addition_Assignment_Operator, token_str}
        case token_str == "-=":
            token = Token {.Subtraction_Assignment_Operator, token_str}
        case token_str == "*=":
            token = Token {.Multiplication_Assignment_Operator, token_str}
        case token_str == "/=":
            token = Token {.Division_Assignment_Operator, token_str}
        case token_str == "%=":
            token = Token {.Modulo_Assignment_Operator, token_str}
        case token_str == "%%=":
            token = Token {.Remainder_Assignment_Operator, token_str}

        case token_str == "|=":
            token = Token {.Bitwise_Or_Assignment_Operator, token_str}
        case token_str == "~=":
            token = Token {.Bitwise_Xor_Assignment_Operator, token_str}
        case token_str == "&=":
            token = Token {.Bitwise_And_Assignment_Operator, token_str}
        case token_str == "&~=":
            token = Token {.Bitwise_And_Not_Assignment_Operator, token_str}
        case token_str == "<<=":
            token = Token {.Left_Shift_Assignment_Operator, token_str}
        case token_str == ">>=":
            token = Token {.Right_Shift_Assignment_Operator, token_str}

        case token_str == "<":
            token = Token {.Less_Than_Operator, token_str}
        case token_str == "<=":
            token = Token {.Less_Than_Or_Equal_To_Operator, token_str}
        case token_str == ">":
            token = Token {.Greater_Than_Operator, token_str}
        case token_str == ">=":
            token = Token {.Less_Than_Or_Equal_To_Operator, token_str}
        case token_str == "==":
            token = Token {.Equals_Operator, token_str}
        case token_str == "!=":
            token = Token {.Not_Equal_Operator, token_str}

        case token_str == "&&":
            token = Token {.And_Operator, token_str}
        case token_str == "||":
            token = Token {.Or_Operator, token_str}
        case token_str == "!":
            token = Token {.Not_Operator, token_str}

        case token_str == "&&=":
            token = Token {.And_Assignment_Operator, token_str}
        case token_str == "||=":
            token = Token {.Or_Assignment_Operator, token_str}

        case token_str == "..":
            token = Token {.Range_Operator, token_str}

        // Delimiters 
        case token_str == "(":
            token = Token{.Open_Parenthese, token_str} 
        case token_str == ")":
            token = Token{.Close_Parenthese, token_str} 
        case token_str == "{":
            token = Token{.Open_Brace, token_str} 
        case token_str == "}":
            token = Token{.Close_Brace, token_str} 
        case token_str == "[":
            token = Token{.Open_Bracket, token_str} 
        case token_str == "]":
            token = Token{.Close_Bracket, token_str} 
        case token_str == ":":
            token = Token{.Colon, token_str}
        case token_str == ",":
            token = Token{.Comma, token_str}
        case token_str == "\n":
            token = Token{.Newline, token_str} 
            lexer.location.line += 1
            lexer.location.col = 1

        // Comments
        case has_prefix(token_str, "//"):
            token = Token{.Single_Line_Comment, token_str}
        case has_prefix(token_str, "/*"):
            token = Token{.Multi_Line_Comment, token_str}

        // Builtin Functions
        case is_unary_builtin_function(token_str): 
            token = Token{.Unary_Builtin_Function, token_str}
        case is_binary_builtin_function(token_str): 
            token = Token{.Binary_Builtin_Function, token_str}

        case is_builtin(token_str):
            token = Token {.Builtin, token_str} 

        case is_scalar_type(token_str):
            token = Token {.Scalar_Type, token_str} 

        case is_array_type(token_str):
            token = Token {.Array_Type, token_str} 

        case is_bool(token_str):
            token = Token {.Boolean_Literal, token_str} 

        case is_alpha(token_start):
            token = Token {.Identifier, token_str}

        case is_digit(token_start) && contains_any(token_str, ".e"):
            token = Token {.Float_Literal, token_str} 

        case is_digit(token_start):
            token = Token {.Integer_Literal, token_str} 

        case is_space(token_start):
            lexer.location.col += len(token_str)
            continue

        case:
            log.errorf("Invalid token: %s at line: %v, col: %v \n", token_str, lexer.location.line, lexer.location.col)
            err = .Invalid_Token
            return
        }

        if !is_space(token_start) do lexer.location.col = token_start_col + len(token_str)
        append(&lexer.token_stream, token)
    }

    if cap(lexer.token_stream) > lexer.max_capacity {
        lexer.max_capacity = cap(lexer.token_stream)
    }

    tokens = lexer.token_stream
    return
}


print_tokens :: proc(token_stream: [dynamic]Token) {
    for token in token_stream {
        color: pp.Color
        switch token.type {
        case .Identifier:
            color = .White
        case .Scalar_Type, .Array_Type:
            color = .Magenta
        case .Integer_Literal, .Float_Literal, .Boolean_Literal:
            color = .Green
        case .Builtin:
            color = .Bright_Red
        case .Unary_Builtin_Function, .Binary_Builtin_Function:
            color = .Cyan
        case .Colon, .Comma, .Open_Parenthese, .Close_Parenthese, 
             .Open_Brace, .Close_Brace, .Open_Bracket, .Close_Bracket:
            color = .Yellow
        case .Newline, .EOF:
            color = .Reset
        case .Module_Keyword, .Kernel_Keyword, .Layout_Keyword, 
             .Procedure_Keyword, .Conditional_Keyword, .For_Keyword,
             .In_Keyword:
            color = .Blue
        case .Constant_Assignment_Operator, .Variable_Assignment_Operator,
             .Addition_Operator, .Subtraction_Operator,
             .Multiplication_Operator, .Division_Operator,
             .Less_Than_Operator, .Less_Than_Or_Equal_To_Operator,
             .Greater_Than_Operator, .Greater_Than_Or_Equal_To_Operator,
             .Equals_Operator, .Not_Equal_Operator, .Modulo_Operator, .Remainder_Operator,
             .Range_Operator, .Addition_Assignment_Operator, .Subtraction_Assignment_Operator,
             .Multiplication_Assignment_Operator, .Division_Assignment_Operator,
             .Remainder_Assignment_Operator, .Modulo_Assignment_Operator,
             .Not_Operator, .And_Operator, .Or_Operator, .Left_Shift_Operator, .Right_Shift_Operator,
             .Bitwise_Or_Operator, .Bitwise_Xor_Operator, .Bitwise_And_Operator, .Bitwise_And_Not_Operator,
             .Bitwise_Or_Assignment_Operator, .Bitwise_Xor_Assignment_Operator, .Bitwise_And_Assignment_Operator, 
             .Bitwise_And_Not_Assignment_Operator, .Left_Shift_Assignment_Operator, .Right_Shift_Assignment_Operator,
             .And_Assignment_Operator, .Or_Assignment_Operator:
            color = .Red
        case .Single_Line_Comment, .Multi_Line_Comment:
            color = .Reset
        case:
            color = .Reset
        }
        
        pp.printf("%-35v", token.type, color = color)
        if token.type == .Newline {
            pp.printf(" \\n\n", color = .Reset)
        } else if token.type == .EOF {
            pp.printf(" EOF\n", color = .Reset)
        } else {
            pp.printf(" %v\n", token.value, color = .Reset)
        }
    }
    pp.println("\n")
}
