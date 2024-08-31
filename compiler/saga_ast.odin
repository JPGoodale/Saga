package saga_compiler
import "core:fmt"
import "core:strings"


AST_Node :: union {
    Module,
    Layout,
    Constant_Assignment,
    Kernel_Signature,
    Argument,
    Array_Argument,
    Scalar_Argument,
    Kernel,
    Expression,
    Literal,
    Type,
    Scalar_Type,
    Array_Type
}


Module :: struct {
    name: string,
}


Layout :: struct {
    x: string,
    y: string,
    z: string,
}


Constant_Assignment :: struct {
    name:  string,
    value: string,
}


Kernel_Signature :: struct {
    name: string,
    args: [dynamic]Argument,
}


Argument :: union {
    Array_Argument,
    Scalar_Argument
}


Array_Argument :: struct {
    name: string,
    type: Array_Type,
}


Scalar_Argument :: struct {
    name: string,
    type: Scalar_Type,
}


Type :: union {
    Scalar_Type,
    Array_Type,
}


Scalar_Type :: struct {
    variant: string,
}


Array_Type :: struct {
    n_elements:     string,
    element_type:   string
}


Kernel :: struct {
    signature: Kernel_Signature,
    body:      [dynamic]Expression,
}


Expression :: union {
    Variable_Expression,
    Binary_Expression,
    Call_Expression,
    Literal,
}


Variable_Expression :: struct {
    name:  string,
    type:  Type,
    value: ^Expression,
}


Call_Expression :: struct {
    callee: string,
    args:   [dynamic]Expression,
}


Binary_Expression :: struct {
    op:  string,
    lhs: Literal,
    rhs: Literal,
}


Literal :: struct {
    value:         string,
    is_identifier: bool,
}


print_node :: proc(node: AST_Node) {
    #partial switch n in node {
    case Module:
        fmt.printf("%v\n", n)
    case Layout:
        fmt.printf("%v\n", n)
    case Constant_Assignment:
        fmt.printf("%v\n", n)
    case Kernel:
        print_node(n.signature)
        for expr in n.body {
            print_node(expr)
        }
    case Kernel_Signature:
        fmt.printf("%v\n", n.name)
        for arg in n.args {
            print_node(arg)
        }
    case Array_Argument, Scalar_Argument:
        fmt.printf("%v\n", n)
    case Expression:
        switch e in n {
        case Variable_Expression:
            fmt.printf("%v\n", e)
        case Binary_Expression:
            fmt.printf("%v\n", e)
        case Call_Expression:
            for arg in e.args {
                fmt.printf("%v\n", arg)
            }
        case Literal:
            fmt.printf("%v\n", e)
        }
    }
}


print_ast :: proc(ast: [dynamic]AST_Node) {
    for node in ast {
        print_node(node)
        fmt.println() 
    }
}

