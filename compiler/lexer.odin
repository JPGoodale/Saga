package saga_compiler
import "core:fmt"
import "core:strings"
import "core:strconv"
import scanner "core:text/scanner"

Token_Kind :: enum u8 {
    Invalid,
    EOF,
    Comment,
    
    Literals__Begin,
        Identifier,
        Integer,
        Float,
        Imaginary,
    Literals__End,
    
    Delimiters__Begin,
        Open_Paren,
        Close_Paren,
        Open_Brace,
        Close_Brace,
        Open_Bracket,
        Close_Bracket,
        Colon,
        Semicolon,
        Comma,
        Period,
        Ellipsis,
        Newline,
    Delimiters__End,
    
    Operators__Begin,
        Eq,
        Not,
        Hash,
        At,
        Dollar,
        Pointer,
        Question,
        Add,
        Sub,
        Mul,
        Div,
        Mod,
        Rem,
        And,
        Or,
        Xor,
        And_Not,
        Shl,
        Shr,
        Cmp_And,
        Cmp_Or,
        
        Assignment_Operators__Begin,
            Add_Eq,
            Sub_Eq,
            Mul_Eq,
            Div_Eq,
            Mod_Eq,
            Rem_Eq,
            And_Eq,
            Or_Eq,
            Xor_Eq,
            And_Not_Eq,
            Shl_Eq,
            Shr_Eq,
            Cmp_And_Eq,
            Cmp_Or_Eq,
        Assignment_Operators__End,
        
        Increment,
        Decrement,
        Right_Arrow,
        
        Comparison_Operators__Begin,
            Cmp_Eq,
            Not_Eq,
            Lt,
            Gt,
            Lt_Eq,
            Gt_Eq,
        Comparison_Operators__End,
    Operators__End,
    
    Keywords__Begin,
        Module,
        Kernel,
        Shader,
        Proc,
        Vec,
        Matrix,
        Tensor,
        If,
        Else,
        For,
        In,
        Defer,
        Return,
        Cast,
        Bool,
        Dynamic,
    Keywords__End,
}

is_literal :: proc(t: Token_Kind) -> bool {
    return t > .Literals__Begin && t < .Literals__End
}

is_delimiter :: proc(t: Token_Kind) -> bool {
    return t > .Delimiters__Begin && t < .Delimiters__End
}

is_operator :: proc(t: Token_Kind) -> bool {
    return t > .Operators__Begin && t < .Operators__End
}

is_assignment_operator :: proc(t: Token_Kind) -> bool {
    return t > .Assignment_Operators__Begin && t < .Assignment_Operators__End
}

is_comparison_operator :: proc(t: Token_Kind) -> bool {
    return t > .Comparison_Operators__Begin && t < .Comparison_Operators__End
}

is_keyword :: proc(t: Token_Kind) -> bool {
    return t > .Keywords__Begin && t < .Keywords__End
}


@(private)
keyword_lookup :: proc(text: string) -> (Token_Kind, bool) {
    switch text {
    case "module":              return .Module, true
    case "kernel":              return .Kernel, true
    case "proc":                return .Proc, true
    case "shader":              return .Shader, true
    case "matrix":              return .Matrix, true
    case "tensor":              return .Tensor, true
    case "if":                  return .If, true
    case "else":                return .Else, true
    case "for":                 return .For, true
    case "in":                  return .In, true
    case "defer":               return .Defer, true
    case "return":              return .Return, true
    case "cast":                return .Cast, true
    case "true", "false":       return .Bool, true
    case "dynamic":             return .Dynamic, true
    case "hvec2",
         "hvec3",
         "hvec4",
         "vec2",
         "vec3",
         "vec4",
         "dvec2",
         "dvec3",
         "dvec4",
         "ivec2",
         "ivec3",
         "ivec4",
         "uvec2",
         "uvec3",
         "uvec4",
         "bvec2",               
         "bvec3",    
         "bvec4",    
         "dim3":
        return .Vec, true
    }
    return .Invalid, false
}


Value :: union {
    int,
    f32,
    f64,
    bool,
    string,
}


Vec_Info :: struct {
    count:      int,
    elem_type:  string,
}


VEC_INFO_MAP := map[string]Vec_Info {
    "hvec2" = Vec_Info{2, "f16"},
    "hvec3" = Vec_Info{3, "f16"},
    "hvec4" = Vec_Info{4, "f16"},

    "vec2"  = Vec_Info{2, "f32"},
    "vec3"  = Vec_Info{3, "f32"},
    "vec4"  = Vec_Info{4, "f32"},

    "dvec2" = Vec_Info{2, "f64"},
    "dvec3" = Vec_Info{3, "f64"},
    "dvec4" = Vec_Info{4, "f64"},
    
    "ivec2" = Vec_Info{2, "i32"},
    "ivec3" = Vec_Info{3, "i32"},
    "ivec4" = Vec_Info{4, "i32"},
    
    "uvec2" = Vec_Info{2, "u32"},
    "uvec3" = Vec_Info{3, "u32"},
    "uvec4" = Vec_Info{4, "u32"},
    
    "bvec2" = Vec_Info{2, "bool"},
    "bvec3" = Vec_Info{3, "bool"},
    "bvec4" = Vec_Info{4, "bool"},
    
    "dim3"  = Vec_Info{3, "u32"},
}


TOKEN_BYTES_RATIO :: 8
MINIMUM_TOKEN_CAPACITY :: 256


@(private)
estimate_token_capacity :: proc(source_len: int) -> int {
    capacity := source_len / TOKEN_BYTES_RATIO
    return max(capacity, MINIMUM_TOKEN_CAPACITY)
}


Token :: struct {
    kind:   Token_Kind,
    value:  Value,
    pos:    Position,
}


make_token :: proc(kind: Token_Kind, value: Value, pos: Position) -> (tok: Token) {
    tok = Token{kind, value, pos}
    return
}


Tokenizer :: struct {
    scanner:      Scanner,
    tokens:       [dynamic]Token,
    source:       string,
    error_count:  int,
}


tokenizer_init :: proc(source: string, filename := "") -> (t: Tokenizer) {
    t.source = source
    scanner.init(&t.scanner, source, filename)
    
    // Pre-allocate token buffer based on source size
    estimated_capacity := estimate_token_capacity(len(source))
    t.tokens = make([dynamic]Token, 0, estimated_capacity)
    return
}


tokenizer_destroy :: proc(t: ^Tokenizer) {
    delete(t.tokens)
}


@(private)
tokenizer_error :: proc(t: ^Tokenizer, pos: Position, msg: string) {
    t.error_count += 1
    fmt.eprintf("%v: error: %s\n", pos, msg)
}


tokenize :: proc(t: ^Tokenizer) -> ([]Token, bool) {
    using scanner
    
    for {
        tok_kind := scan(&t.scanner)
        if tok_kind == EOF {
            append(&t.tokens, Token{.EOF, "", position(&t.scanner)})
            break
        }
        
        pos := position(&t.scanner)
        text := token_text(&t.scanner)
        token: Token
        
        switch tok_kind {
        case '\n':
            token = Token{.Newline, "\\n", pos}
            
        case Comment:
            token = Token{.Comment, text, pos}
            
        case Ident:
            if keyword_type, is_kw := keyword_lookup(text); is_kw {
                token = Token{keyword_type, text, pos}
            } else {
                token = Token{.Identifier, text, pos}
            }
            
        case Int:
            value := strconv.atoi(text)
            token = Token{.Integer, value, pos}
            
        case Float:
            value := f64(strconv.atoi(text))
            token = Token{.Float, value, pos}
            
        case '(':
            token = Token{.Open_Paren, text, pos}
        case ')':
            token = Token{.Close_Paren, text, pos}
        case '{':
            token = Token{.Open_Brace, text, pos}
        case '}':
            token = Token{.Close_Brace, text, pos}
        case '[':
            token = Token{.Open_Bracket, text, pos}
        case ']':
            token = Token{.Close_Bracket, text, pos}
        case ',':
            token = Token{.Comma, text, pos}
        case '^':
            token = Token{.Pointer, text, pos}
        case '.':
            if peek(&t.scanner) == '.' {
                next(&t.scanner)
                if peek(&t.scanner) == '.' {
                    next(&t.scanner)
                    token = Token{.Ellipsis, "...", pos}
                } else {
                    token = Token{.Period, ".", pos}
                }
            } else {
                token = Token{.Period, ".", pos}
            }
            
        case '+':
            switch peek(&t.scanner) {
            case '=':
                next(&t.scanner)
                token = Token{.Add_Eq, "+=", pos}
            case '+':
                next(&t.scanner)
                token = Token{.Increment, "++", pos}
            case:
                token = Token{.Add, "+", pos}
            }
            
        case '-':
            switch peek(&t.scanner) {
            case '=':
                next(&t.scanner)
                token = Token{.Sub_Eq, "-=", pos}
            case '-':
                next(&t.scanner)
                token = Token{.Decrement, "--", pos}
            case '>':
                next(&t.scanner)
                token = Token{.Right_Arrow, "->", pos}
            case:
                token = Token{.Sub, "-", pos}
            }
            
        case '*':
            if peek(&t.scanner) == '=' {
                next(&t.scanner)
                token = Token{.Mul_Eq, "*=", pos}
            } else {
                token = Token{.Mul, "*", pos}
            }
            
        case '/':
            if peek(&t.scanner) == '=' {
                next(&t.scanner)
                token = Token{.Div_Eq, "/=", pos}
            } else {
                token = Token{.Div, "/", pos}
            }
            
        case ':':
            token = Token{.Colon, ":", pos}

        case '=':
            if peek(&t.scanner) == '=' {
                next(&t.scanner)
                token = Token{.Cmp_Eq, "==", pos}
            } else {
                token = Token{.Eq, "=", pos}
            }
            
        case '!':
            if peek(&t.scanner) == '=' {
                next(&t.scanner)
                token = Token{.Not_Eq, "!=", pos}
            } else {
                token = Token{.Not, "!", pos}
            }
            
        case '<':
            switch peek(&t.scanner) {
            case '=':
                next(&t.scanner)
                token = Token{.Lt_Eq, "<=", pos}
            case '<':
                next(&t.scanner)
                if peek(&t.scanner) == '=' {
                    next(&t.scanner)
                    token = Token{.Shl_Eq, "<<=", pos}
                } else {
                    token = Token{.Shl, "<<", pos}
                }
            case:
                token = Token{.Lt, "<", pos}
            }
            
        case '>':
            switch peek(&t.scanner) {
            case '=':
                next(&t.scanner)
                token = Token{.Gt_Eq, ">=", pos}
            case '>':
                next(&t.scanner)
                if peek(&t.scanner) == '=' {
                    next(&t.scanner)
                    token = Token{.Shr_Eq, ">>=", pos}
                } else {
                    token = Token{.Shr, ">>", pos}
                }
            case:
                token = Token{.Gt, ">", pos}
            }
            
        case '&':
            switch peek(&t.scanner) {
            case '=':
                next(&t.scanner)
                token = Token{.And_Eq, "&=", pos}
            case '&':
                next(&t.scanner)
                if peek(&t.scanner) == '=' {
                    next(&t.scanner)
                    token = Token{.Cmp_And_Eq, "&&=", pos}
                } else {
                    token = Token{.Cmp_And, "&&", pos}
                }
            case:
                token = Token{.And, "&", pos}
            }
            
        case '|':
            switch peek(&t.scanner) {
            case '=':
                next(&t.scanner)
                token = Token{.Or_Eq, "|=", pos}
            case '|':
                next(&t.scanner)
                if peek(&t.scanner) == '=' {
                    next(&t.scanner)
                    token = Token{.Cmp_Or_Eq, "||=", pos}
                } else {
                    token = Token{.Cmp_Or, "||", pos}
                }
            case:
                token = Token{.Or, "|", pos}
            }
            
        case: 
            tokenizer_error(t, pos, fmt.tprintf("unexpected token: %v", tok_kind))
            continue
        }
        
        append(&t.tokens, token)
    }
    
    return t.tokens[:], t.error_count == 0
}

