package saga_compiler
import "core:os"
import "core:io"
import "core:fmt"
import "core:bufio"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"


Token_Type :: enum {
    Identifier,
    Type_Identifier,
    Literal,
    Builtin_Variable,
    Function_Call,

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
    Kernel_Keyword,
    Layout_Keyword,
    Conditional_Keyword,
    For_Keyword,

    // Operators
    Constant_Assignment_Operator,
    Variable_Assignment_Operator,
    Addition_Operator,
    Subtraction_Operator,
    Multiplication_Operator,
    Division_Operator,
}


Token :: struct {
    type: Token_Type,
    value: string
}


is_space :: unicode.is_space
is_alpha :: unicode.is_alpha
is_digit :: unicode.is_digit


is_operator :: proc(r: rune) -> bool {
    switch r {
    case '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~', ':':
        return true 
    }
    return false
}


is_delimiter :: proc(r: rune) -> bool {
    switch r {
    case '(', ')', '[', ']', '{', '}', ',', ';':
        return true
    }
    return false
}


is_type :: proc(s: string) -> bool {
    if len(s) > 0 && s[0] == '[' {
        parts := strings.split(s[1:], "]")
        if len(parts) == 2 {
            return is_type(parts[1])
        }
    }
    switch s {
    case "u8", "u16", "u32", "u64", "u128", "i8", "i16", "i32", "i64", "i128", "f16", "f32", "f64", "bool":
        return true
    }
    return false
}


is_builtin_variable :: proc(s: string) -> bool {
    switch s {
    case "tid.x", "tid.y", "tid.z", "ctaid.x", "ctaid.y", "ctaid.z", "ntid.x", "ntid.y", "ntid.z":
        return true
    }
    return false
}


is_builtin_function :: proc(s: string) -> bool {
    switch s {
    case "sin", "cos", "tanh", "exp", "log", "dot", "max", "min", "sqrt", "swizzle": 
        return true
    }
    return false
}


split_tokens :: proc(data: []byte, at_eof: bool) -> (advance: int, token: []byte, err: bufio.Scanner_Error, final_token: bool) {
    start := 0
    for width := 0; start < len(data); start += width {
        r: rune
        r, width = utf8.decode_rune(data[start:])
        if !is_space(r) || r == '\n' {
            break
        }
    }

    r, width := utf8.decode_rune(data[start:])

    if r == '\n' {
        advance = start + width
        token = data[start : start+width]
        return
    }

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
                    if is_type(string(data[type_start:end])) {
                        advance = end
                        token = data[start:end]
                        return
                    }
                    break
                }
            }
        }
    }

    if is_delimiter(r) {
        advance = start + width
        token = data[start : start+width]
        return
    }

    if is_operator(r) {
        end := start + width
        for end < len(data) {
            r, width := utf8.decode_rune(data[end:])
            if !is_operator(r) do break
            end += width
        }
        advance = end
        token = data[start:end]
        return
    }

    for width, i := 0, start; i < len(data); i += width {
        r, width = utf8.decode_rune(data[i:])
        if is_space(r) || is_operator(r) || is_delimiter(r) {
            if r == '(' && i > start {
                potential_func := string(data[start:i])
                if is_builtin_function(potential_func) {
                    paren_count := 1
                    for j := i + width; j < len(data); j += width {
                        r, width = utf8.decode_rune(data[j:])
                        if r == '(' {
                            paren_count += 1
                        } else if r == ')' {
                            paren_count -= 1
                            if paren_count == 0 {
                                advance = j + width
                                token = data[start:j+width]
                                return
                            }
                        }
                    }
                }
            }
            advance = i
            token = data[start:i]
            return
        }
    }

    if at_eof && len(data) > start {
        advance = len(data)
        token = data[start:]
        return
    }

    advance = start
    return
}


lex :: proc(reader_stream: io.Reader) -> [dynamic]Token {
    scanner : bufio.Scanner 
    bufio.scanner_init(&scanner, reader_stream)
    scanner.split = split_tokens
    tokens := make([dynamic]Token)

    for bufio.scanner_scan(&scanner) {
        token_str := bufio.scanner_text(&scanner)
        token_start := rune(token_str[0])
        token: Token 

        switch {
        // Keywords
        case token_str == "module":
            token = Token {.Module_Keyword, token_str} 
        case token_str == "layout":
            token = Token {.Layout_Keyword, token_str} 
        case token_str == "kernel":
            token = Token {.Kernel_Keyword, token_str} 
        case token_str == "if", token_str == "else":
            token = Token {.Conditional_Keyword, token_str} 
        case token_str == "for": 
            token = Token {.For_Keyword, token_str} 

        // Operators
        case token_str == "::":
            token = Token {.Constant_Assignment_Operator, token_str} 
        case token_str == "=":
            token = Token {.Variable_Assignment_Operator, token_str} 
        case token_str == "+":
            token = Token {.Addition_Operator, token_str}
        case token_str == "-":
            token = Token {.Subtraction_Operator, token_str}
        case token_str == "*":
            token = Token {.Multiplication_Operator, token_str}
        case token_str == "/":
            token = Token {.Division_Operator, token_str}

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

        case is_builtin_variable(token_str):
            token = Token {.Builtin_Variable, token_str} 

        case is_builtin_function(strings.split(token_str, "(")[0]): 
            token = Token{.Function_Call, token_str}

        case is_type(token_str):
            token = Token {.Type_Identifier, token_str} 

        case is_alpha(token_start):
            token = Token {.Identifier, token_str}

        case is_digit(token_start):
            token = Token {.Literal, token_str} 

        case:
            fmt.printf("Unknown token: %s\n", token_str)
            continue
        }

        append(&tokens, token)
    }

    return tokens
}


print_tokens :: proc(token_stream: [dynamic]Token) {
    for token in token_stream {
        fmt.printf("%v '%v'\n", token.type, token.value)
    }
    fmt.printf("\n\n")
}

