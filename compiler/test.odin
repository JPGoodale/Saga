package saga_compiler
import "core:fmt"
import "core:os"
import "core:strings"


main :: proc() {
    data, read_ok := os.read_entire_file("./demo.saga")
    if !read_ok { 
        fmt.println("Failed to read file!") 
        return
    }

    tokenizer := tokenizer_init(string(data))
    tokens, tokens_ok := tokenize(&tokenizer)
    if !tokens_ok { 
        fmt.println("Failed to tokenize file!") 
        return
    }
    // print_tokens(tokens)
    // fmt.println()
    
    // Parsing
    parser := parser_init(tokens)
    ast, err := parse_file(&parser)
    if err != nil {
        fmt.println("Failed to parse file!")
        return
    }
 
    fmt.println("AST Structure:")
    fmt.println("-------------")
    for node, i in ast {
        print_ast(node)
        if i < len(ast)-1 {
            fmt.println()
        }
    }
    fmt.println()
}
