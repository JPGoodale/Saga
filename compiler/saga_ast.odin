package saga_compiler
import "core:fmt"
import "core:strings"
import pp "../tools/pretty_printer"


AST_Node :: union {
    Module,
    Layout,
    Constant_Assignment,
    Kernel_Signature,
    Argument,
    Kernel,
    Expression,
    Variable_Expression,
    Value,
    Identifier,
    Literal,
    Type,
    Scalar_Type,
    Array_Type,
    Thread_Idx,
    Thread
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


Argument :: struct {
    name: string,
    type: Type
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
    Unary_Call_Expression,
    Binary_Call_Expression,
    Identifier,
    Literal,
    Thread_Idx,
    Thread
}


Variable_Declaration :: struct {
    name:       string,
    type:       Type,
}


Variable_Expression :: struct {
    name:           string,
    thread_idx:     Thread_Idx,
    type:           Type,
    value:          ^Expression,
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


Loop_Expression :: struct {
    start:  Value,
    end:    Value,
    body:   [dynamic]Expression

}


Unary_Call_Expression :: struct {
    callee:     string,
    operand:    ^Expression,
}


Binary_Call_Expression :: struct {
    callee:     string,
    operands:   [2]^Expression,
}


Value :: union {
    Identifier,
    Literal,
}


Identifier :: struct {
    name:       string,
    type:       Type,
    thread_idx: Thread_Idx
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
        pp.printf("%sModule: ", indent_str, color = .Yellow)
        pp.printf("%s\n", n.name, color = .White)
    case Layout:
        pp.printf("%sLayout: ", indent_str, color = .Yellow)
        pp.printf("[%s, %s, %s]\n", n.x, n.y, n.z, color = .White)
    case Constant_Assignment:
        pp.printf("%sConstant: ", indent_str, color = .Green)
        pp.printf("%s = %s\n", n.name, n.value, color = .White)
    case Kernel:
        pp.printf("%sKernel:\n", indent_str, color = .Yellow)
        print_node(n.signature, indent + 2)
        pp.printf("%s  Kernel Body:\n", indent_str, color = .Yellow)
        for expr in n.body {
            print_node(expr, indent + 4)
        }
    case Kernel_Signature:
        pp.printf("%sKernel Signature: ", indent_str, color = .Yellow)
        pp.printf("%s\n", n.name, color = .White)
        if len(n.args) > 0 {
            pp.printf("%s  Arguments (%d):\n", indent_str, len(n.args), color = .Green)
            for arg in n.args {
                print_node(arg, indent + 4)
            }
        } else {
            pp.printf("%s  WARNING: No arguments in kernel signature\n", indent_str, color = .Bright_Red)
        }
    case Argument:
        pp.printf("%sArg: ", indent_str, color = .Cyan)
        pp.printf("%s ", n.name, color = .White)
        print_node(n.type, 0)
        fmt.println()
    case Expression:
        #partial switch e in n {
        case Variable_Declaration:
            pp.printf("%sVariable: ", indent_str, color = .Green)
            pp.printf("%v, ", e.name, color = .White)
            print_node(e.type, 0)
        case Variable_Expression:
            pp.printf("%sVariable: ", indent_str, color = .Cyan)
            pp.printf("%s, ", e.name, color = .White)
            print_node(e.type, 0)
            print_node(e.thread_idx, 0)
            pp.printf("%s  Value: ", indent_str, color = .Green)
            fmt.println()
            print_node(e.value^, indent + 4)
        case Binary_Expression:
            pp.printf("%sBinary Op: ", indent_str, color = .Cyan)
            pp.printf("%s\n", e.op, color = .Bright_Red)
            pp.printf("%s  Left:\n", indent_str, color = .Green)
            print_node(e.lhs^, indent + 4)
            pp.printf("%s  Right:\n", indent_str, color = .Green)
            print_node(e.rhs^, indent + 4)
        case Conditional_Expression:
            pp.printf("%sConditional:\n", indent_str, color = .Cyan)
            pp.printf("%s  Condition:\n", indent_str, color = .Green)
            print_node(e.condition^, indent + 4)
            pp.printf("%s  Body:\n", indent_str, color = .Green)
            for expr in e.body {
                print_node(expr, indent + 4)
            }
        case Loop_Expression:
            pp.printf("%sLoop:\n", indent_str, color = .Cyan)
            pp.printf("%s  Start:\n", indent_str, color = .Green)
            print_node(e.start, indent + 4)
            pp.printf("%s  End:\n", indent_str, color = .Green)
            print_node(e.end, indent + 4)
            pp.printf("%s  Body:\n", indent_str, color = .Green)
            for expr in e.body {
                print_node(expr, indent + 4)
            }
        case Unary_Call_Expression:
            pp.printf("%sFunction Call: ", indent_str, color = .Cyan)
            pp.printf("%s\n", e.callee, color = .White)
            pp.printf("%s  Operand:\n", indent_str, color = .Green)
            print_node(e.operand^, indent + 4)
        case Binary_Call_Expression:
            pp.printf("%sFunction Call: ", indent_str, color = .Cyan)
            pp.printf("%s\n", e.callee, color = .White)
            pp.printf("%s  Operands:\n", indent_str, color = .Cyan)
            for operand in e.operands {
                print_node(operand^, indent + 4)
            }
        case Identifier:
            pp.printf("%sIdentifier: ", indent_str, color = .Cyan)
            pp.printf("%s, ", e.name, color = .White)
            print_node(e.type, 0)
            if e.thread_idx != nil {
                switch t in e.thread_idx {
                case Thread:
                    pp.printf("Thread_Idx: ", color = .Green)
                    pp.printf("%v", t.value, color = .Bright_Red)
                    fmt.println()
                case Binary_Expression:
                    fmt.println()
                    print_node(e.thread_idx, indent + 2)
                case:
                    fmt.println()
                    print_node(e.thread_idx, indent + 2)
                }
            }
        case Literal:
            pp.printf("%sLiteral: ", indent_str, color = .Cyan)
            pp.printf("%v, ", e.value, color = .White)
            pp.printf("Type: ", color = .Green)
            pp.printf("%v", e.type, color = .Bright_Red)
            fmt.println()
        case Thread:
            pp.printf("%sThread_Idx: ", indent_str, color = .Cyan)
            pp.printf("%v\n", e.value, color = .Bright_Red)
        }
    case Type:
        switch t in n {
        case Scalar_Type:
            pp.printf("%sType: ", indent_str, color = .Green)
            pp.printf("%s\n", t.variant, color = .Bright_Red)
        case Array_Type:
            pp.printf("%sType: ", indent_str, color = .Green)
            pp.printf("%v", t.element_type, color = .Bright_Red)
            pp.printf("[%s], ", t.n_elements, color = .Bright_Red)
        }
    case Thread_Idx:
        switch t in n {
        case Thread:
            pp.printf("%sThread_Idx: ", indent_str, color = .Green)
            pp.printf("%v\n", t.value, color = .Bright_Red)
        case Binary_Expression:
            pp.printf("%sThread_Idx:\n", indent_str, color = .Green)
            e: Expression = t
            print_node(e, indent + 4)
        }
    case Value:
        switch t in n {
        case Identifier:
            print_node(t, indent)
        case Literal:
            print_node(t, indent)
        }
    case Identifier:
        pp.printf("%sIdentifier: ", indent_str, color = .Cyan)
        pp.printf("%s, ", n.name, color = .White)
        print_node(n.type, 0)
        if n.thread_idx != nil {
            switch t in n.thread_idx {
            case Thread:
                pp.printf(", Thread_Idx: ", color = .Green)
                pp.printf("%v", t.value, color = .Bright_Red)
                fmt.println()
            case Binary_Expression:
                fmt.println()
                print_node(n.thread_idx, indent + 2)
            case:
                fmt.println()
                print_node(n.thread_idx, indent + 2)
            }
        }
    case Literal:
        pp.printf("%sLiteral: ", indent_str, color = .Cyan)
        pp.printf("%v, ", n.value, color = .White)
        pp.printf("Type: ", color = .Green)
        pp.printf("%v", n.type, color = .Bright_Red)
        fmt.println()
    case:
        pp.printf("%sUnknown node type: %v", indent_str, n, color = .Bright_Red)
        pp.printf("%v\n", n, color = .Bright_Red)
    }
}

print_ast :: proc(ast: [dynamic]AST_Node) {
    for node in ast {
        print_node(node)
        fmt.println() 
    }
}

print_ast_simple :: proc(ast: [dynamic]AST_Node) {
    for node in ast {
        fmt.println(node)
        fmt.println() 
    }
}
