package saga_compiler
import "core:os"
import "core:fmt"
import "core:strings"
import pp "../tools/pretty_printer"


print_tokens :: proc(tokens: []Token) {
    for token in tokens {
        color: pp.Color
        #partial switch token.kind {
        case .Identifier:
            color = .White
            
        case .Integer, .Float, .Bool, .Imaginary:
            color = .Green
            
        case .Comment:
            color = .Reset
            
        case .Open_Paren, .Close_Paren,
             .Open_Brace, .Close_Brace,
             .Open_Bracket, .Close_Bracket,
             .Colon, .Comma, .Period, .Ellipsis:
            color = .Yellow
            
        case .Module, .Kernel, .Shader, .Proc,
             .Vec, .Matrix, .Tensor,
             .If, .Else, .For, .In, 
             .Defer, .Return, .Cast:
            color = .Blue
            
        case .Add, .Sub, .Mul, .Div, .Mod, .Rem,
             .And, .Or, .Xor, .And_Not, .Shl, .Shr,
             .Add_Eq, .Sub_Eq, .Mul_Eq, .Div_Eq,
             .Mod_Eq, .Rem_Eq, .And_Eq, .Or_Eq,
             .Xor_Eq, .And_Not_Eq, .Shl_Eq, .Shr_Eq,
             .Cmp_And, .Cmp_Or, .Cmp_And_Eq, .Cmp_Or_Eq,
             .Cmp_Eq, .Not_Eq, .Lt, .Gt, .Lt_Eq, .Gt_Eq:
            color = .Red
            
        case .Newline, .EOF:
            color = .Reset
            
        case:
            color = .Reset
        }
        
        pp.printf("%-35v", token.kind, color = color)
        if token.kind == .Newline {
            pp.printf(" \\n\n", color = .Reset)
        } else if token.kind == .EOF {
            pp.printf(" EOF\n", color = .Reset)
        } else {
            pp.printf(" %v\n", token.value, color = .Reset)
        }
    }
    pp.println("\n")
}


print_ast :: proc(node: ^Ast_Node, indent: int = 0, is_last: bool = true) {
    if node == nil do return
    
    if indent > 0 {
        for i := 0; i < indent-1; i += 1 {
            fmt.print("|   ")
        }
        if is_last {
            fmt.print("'---")
        } else {
            fmt.print("|---")
        }
    }
    
    // Print basic node info with detailed fields
    print_node_details :: proc(node: ^Ast_Node) {
        fmt.printf("%v", node.kind)
        
        #partial switch v in node.derived {
        case Binary_Expr:
            fmt.printf(" [op: %v, left: %v, right: %v]", 
                v.op.kind, 
                v.left != nil ? v.left.kind : Ast_Kind.Bad_Expr,
                v.right != nil ? v.right.kind : Ast_Kind.Bad_Expr)
                
        case Unary_Expr:
            fmt.printf(" [op: %v, expr: %v]", 
                v.op.kind,
                v.expr != nil ? v.expr.kind : Ast_Kind.Bad_Expr)
                
        case Module_Decl:
            fmt.printf(" [name: %v]", v.name.value)
            
        case Procedure_Type:
            fmt.printf(" [variant: %v, params: %v, results: %v]", 
                v.varient, 
                v.params != nil ? v.params.kind : Ast_Kind.Bad_Expr,
                v.results != nil ? v.results.kind : Ast_Kind.Bad_Expr)
                
        case Array_Type:
            size_str := "dynamic"
            if v.size != nil {
                if lit, ok := v.size.derived.(Basic_Literal); ok {
                    size_str = fmt.tprintf("%v", lit.token.value)
                }
            }
            fmt.printf(" [size: %v, elem_type: %v]",
                size_str,
                v.elem_type != nil ? v.elem_type.kind : Ast_Kind.Bad_Expr)
                
        case Matrix_Type:
            fmt.printf(" [row_major: %v, rows: %v, cols: %v, elem_type: %v]",
                v.row_major,
                v.rows != nil ? v.rows.kind : Ast_Kind.Bad_Expr,
                v.cols != nil ? v.cols.kind : Ast_Kind.Bad_Expr,
                v.elem_type != nil ? v.elem_type.kind : Ast_Kind.Bad_Expr)
                
        case Value_Decl:
            fmt.printf(" [names: %d, type: %v, values: %d, mutable: %v]",
                len(v.names),
                v.type != nil ? v.type.kind : Ast_Kind.Bad_Expr,
                len(v.values),
                v.is_mutable)
                
        case Assign_Stmt:
            fmt.printf(" [op: %v, lhs: %d, rhs: %d]",
                v.op.kind,
                len(v.lhs),
                len(v.rhs))
                
        case Selector_Expr:
            fmt.printf(" [expr: %v, selector: %v, swizzle_count: %d, swizzle_indices: %d]",
                v.expr != nil ? v.expr.kind : Ast_Kind.Bad_Expr,
                v.selector != nil ? v.selector.kind : Ast_Kind.Bad_Expr,
                v.swizzle_count,
                v.swizzle_indices)
                
        case Block_Stmt:
            fmt.printf(" [statements: %d]", len(v.stmts))
            
        case If_Stmt:
            fmt.printf(" [cond: %v, body: %v, else: %v]",
                v.cond != nil ? v.cond.kind : Ast_Kind.Bad_Expr,
                v.body != nil ? v.body.kind : Ast_Kind.Bad_Expr,
                v.else_stmt != nil ? v.else_stmt.kind : Ast_Kind.Bad_Expr)
                
        case Field:
            fmt.printf(" [names: %d, type: %v]",
                len(v.names),
                v.type != nil ? v.type.kind : Ast_Kind.Bad_Expr)
                
        case Field_List:
            fmt.printf(" [fields: %d]", len(v.nodes))
            
        case Call_Expr:
            fmt.printf(" [expr: %v, args: %d]",
                v.expr != nil ? v.expr.kind : Ast_Kind.Bad_Expr,
                len(v.args))
                
        case Index_Expr:
            fmt.printf(" [expr: %v, index: %v]",
                v.expr != nil ? v.expr.kind : Ast_Kind.Bad_Expr,
                v.index != nil ? v.index.kind : Ast_Kind.Bad_Expr)
                
        case Basic_Literal:
            fmt.printf(" [value: %v]", v.token.value)
            
        case Identifier:
            fmt.printf(" [value: %v]", v.value)

        case Procedure_Literal:
            fmt.printf(" [type: %v, body: %v]",
                v.type != nil ? v.type.kind : Ast_Kind.Bad_Expr,
                v.body != nil ? v.body.kind : Ast_Kind.Bad_Expr)
    }
    fmt.println()
    }
    
    print_node_details(node)
    
    // Recursive traversal with existing structure
    #partial switch v in node.derived {
        case Binary_Expr:
            print_ast(v.left, indent + 1, false)
            print_ast(v.right, indent + 1, true)
            
        case Unary_Expr:
            print_ast(v.expr, indent + 1, true)
            
        case Call_Expr:
            print_ast(v.expr, indent + 1, false)
            for arg, i in v.args {
                print_ast(arg, indent + 1, i == len(v.args)-1)
            }
            
        case If_Stmt:
            print_ast(v.cond, indent + 1, false)
            print_ast(v.body, indent + 1, v.else_stmt == nil)
            if v.else_stmt != nil {
                print_ast(v.else_stmt, indent + 1, true)
            }
            
        case Block_Stmt:
            for s, i in v.stmts {
                print_ast(s, indent + 1, i == len(v.stmts)-1)
            }
            
        case Return_Stmt:
            for result, i in v.results {
                print_ast(result, indent + 1, i == len(v.results)-1)
            }
            
        case Assign_Stmt:
            for lhs, i in v.lhs {
                print_ast(lhs, indent + 1, false)
            }
            for rhs, i in v.rhs {
                print_ast(rhs, indent + 1, i == len(v.rhs)-1)
            }
            
        case Value_Decl:
            for name, i in v.names {
                print_ast(name, indent + 1, false)
            }
            if v.type != nil {
                print_ast(v.type, indent + 1, len(v.values) == 0)
            }
            for value, i in v.values {
                print_ast(value, indent + 1, i == len(v.values)-1)
            }
            
        case Field:
            for name, i in v.names {
                print_ast(name, indent + 1, false)
            }
            print_ast(v.type, indent + 1, true)
            
        case Field_List:
            for node, i in v.nodes {
                print_ast(node, indent + 1, i == len(v.nodes)-1)
            }
            
        case Selector_Expr:
            print_ast(v.expr, indent + 1, false)
            print_ast(v.selector, indent + 1, true)
            
        case Index_Expr:
            print_ast(v.expr, indent + 1, false)
            print_ast(v.index, indent + 1, true)
            
        case Procedure_Type:
            if v.params != nil {
                print_ast(v.params, indent + 1, v.results == nil)
            }
            if v.results != nil {
                print_ast(v.results, indent + 1, true)
            }
            
        case Array_Type:
            if v.size != nil {
                print_ast(v.size, indent + 1, false)
            }
            print_ast(v.elem_type, indent + 1, true)

        case Procedure_Literal:
            if v.type != nil {
                print_ast(v.type, indent + 1, v.body == nil)
            }
            if v.body != nil {
                print_ast(v.body, indent + 1, true)
            }
    }
}
