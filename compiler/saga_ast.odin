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
    Value,
    Literal,
    Type,
    Scalar_Type,
    Array_Type
}


Module :: struct {
    name: string,
}


Layout :: struct {
    x:          string,
    y:          string,
    z:          string,
    is_grid:    bool
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
    Variable_Declaration,
    Binary_Expression,
    Conditional_Expression,
    Loop_Expression,
    Call_Expression,
    Value,
    Literal,
    Thread_Idx
}


Variable_Declaration :: struct {
    name:       string,
    type:       Type,
}


Variable_Expression :: struct {
    name:       string,
    thread_id:  Thread_Idx,
    type:       Type,
    value:      ^Expression,
}


Binary_Expression :: struct {
    op:  string,
    lhs: ^Expression,
    rhs: ^Expression,
}


Conditional_Expression :: struct {
    condition:  ^Expression,
    body:       [dynamic]Expression
}


// Need to adjust this so that the start and stop can be variables as well
Loop_Expression :: struct {
    start:  ^Literal,
    end:    ^Literal,
    body:   [dynamic]Expression

}


Call_Expression :: struct {
    callee: string,
    args:   [dynamic]Value,
}


Value :: struct {
    value:          string,
    thread_id:      Thread_Idx,
    type:           Type,
}


// Only scalar literals are supported atm
Literal :: struct {
    value:          string,
    type:           string,
}


Thread_Idx :: union {
    Thread,
    Binary_Expression
}


Thread :: struct {
    value: string
}


print_node :: proc(node: AST_Node, indent: int = 0) {
    indent_str := strings.repeat(" ", indent)
    
    #partial switch n in node {
    case Module:
        fmt.printf("%sModule: %s\n", indent_str, n.name)
    case Layout:
        fmt.printf("%sLayout: (%s, %s, %s)\n", indent_str, n.x, n.y, n.z)
    case Constant_Assignment:
        fmt.printf("%sConstant: %s = %s\n", indent_str, n.name, n.value)
    case Kernel:
        fmt.printf("%sKernel:\n", indent_str)
        print_node(n.signature, indent + 2)
        fmt.printf("%sKernel Body:\n", indent_str)
        for expr in n.body {
            print_node(expr, indent + 2)
        }
    case Kernel_Signature:
        fmt.printf("%sKernel Signature: %s\n", indent_str, n.name)
        if len(n.args) > 0 {
            fmt.printf("%s  Arguments (%d):\n", indent_str, len(n.args))
            for arg in n.args {
                print_node(arg, indent + 4)
            }
        } else {
            fmt.printf("%s  WARNING: No arguments in kernel signature\n", indent_str)
        }
    case Array_Argument:
        fmt.printf("%sArray Arg: %s %v\n", indent_str, n.name, n.type)
    case Scalar_Argument:
        fmt.printf("%sScalar Arg: %s %v\n", indent_str, n.name, n.type)
    case Expression:
        switch e in n {
        case Variable_Declaration:
            fmt.printf("%sVariable: %v, %v\n", indent_str, e.name, e.type)
        case Variable_Expression:
            fmt.printf("%sVariable: %s, %v, %v\n", indent_str, e.name, e.thread_id, e.type)
            if e.value != nil {
                fmt.printf("%s  Value:\n", indent_str)
                print_node(e.value^, indent + 4)
            }
        case Binary_Expression:
            fmt.printf("%sBinary Op: %s\n", indent_str, e.op)
            fmt.printf("%s  Left:\n", indent_str)
            print_node(e.lhs^, indent + 4)
            fmt.printf("%s  Right:\n", indent_str)
            print_node(e.rhs^, indent + 4)
        case Conditional_Expression:
            fmt.printf("%sConditional:\n", indent_str)
            fmt.printf("%s  Condition:\n", indent_str)
            print_node(e.condition^, indent + 4)
            fmt.printf("%s  Body:\n", indent_str)
            for expr in e.body {
                print_node(expr, indent + 4)
            }
        case Loop_Expression:
            fmt.printf("%sLoop:\n", indent_str)
            fmt.printf("%s  Start:\n", indent_str)
            print_node(e.start^, indent + 4)
            fmt.printf("%s  End:\n", indent_str)
            print_node(e.end^, indent + 4)
            fmt.printf("%s  Body:\n", indent_str)
            for expr in e.body {
                print_node(expr, indent + 4)
            }
        case Call_Expression:
            fmt.printf("%sFunction Call: %s\n", indent_str, e.callee)
            fmt.printf("%s  Arguments:\n", indent_str)
            for arg in e.args {
                print_node(arg, indent + 4)
            }
        case Value:
            fmt.printf("%sValue: %s, %v, %v\n", indent_str, e.value, e.thread_id, e.type)
        case Literal:
            fmt.printf("%sValue: %v, %v\n", indent_str, e.value, e.type)
        case Thread_Idx:
            switch t in e {
            case Thread:
                fmt.printf("%sValue: %v\n", indent_str, t)
            case Binary_Expression:
                fmt.printf("%sBinary Op: %s\n", indent_str, t.op)
                fmt.printf("%s  Left:\n", indent_str)
                print_node(t.lhs^, indent + 4)
                fmt.printf("%s  Right:\n", indent_str)
                print_node(t.rhs^, indent + 4)
            }
        }
    case Type:
        switch t in n {
        case Scalar_Type:
            fmt.printf("%sScalar Type: %s\n", indent_str, t.variant)
        case Array_Type:
            fmt.printf("%sArray Type: %s[%s]\n", indent_str, t.element_type, t.n_elements)
        }
    case:
        fmt.printf("%sUnknown node type: %v\n", indent_str, n)
    }
}


print_ast :: proc(ast: [dynamic]AST_Node) {
    for node in ast {
        print_node(node)
        fmt.println() 
    }
}

