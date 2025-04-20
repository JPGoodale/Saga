package saga_compiler
import "core:fmt"

IR_Kind :: enum u8 {
    Control__Begin,
        Start,
        End,
        Region,
        Phi,
        Branch,
        Call,
        Return,
    Control__End,
    
    Memory__Begin,
        New,
        Move,
        Copy,
        Load,
        Store,
        Alloca,
    Memory__End,

    Data__Begin,
        Unary_Ops__Begin,
            Not,
            Exp2,
            Log2,
            Sqrt,
            Rsqrt,
            Abs,
            Neg,
            Ceil,
            Floor,
            Rcp,
            Sin,
            Cos,
            Tan,
            Asin,
            Acos,
            Atan,
            Sinh,
            Cosh,
            Tanh,
            Sigmoid,
            Softmax,
        Unary_Ops__End,

        Binary_Ops__Begin,
            And,
            Or,
            Xor,
            Shfl,
            Shfr,
            Dot,
            Madd,
            Add,
            Sub,
            Mul,
            Div,
            Mod,
            Rem,
            Exp,
            Log,
            Max,
            Min,
            Cdiv,
            Clamp,
            Eq,
            Not_Eq,
            Lt,
            Gt,
            Lt_Eq,
            Gt_Eq,
        Binary_Ops__End,
    Data__End,
    
    Communication__Begin,
        Barrier,
        Sync,
    Communication__End,

    Field,
    Scope,
    Thread_Idx,
}

is_control_flow :: proc(kind: IR_Kind) -> bool {
    return IR_Kind.Control__Begin < kind && kind < IR_Kind.Control__End
}

is_memory :: proc(kind: IR_Kind) -> bool {
    return IR_Kind.Memory__Begin < kind && kind < IR_Kind.Memory__End
}

is_data :: proc(kind: IR_Kind) -> bool {
    return IR_Kind.Data__Begin < kind && kind < IR_Kind.Data__End
}

is_unary_op :: proc(kind: IR_Kind) -> bool {
    return IR_Kind.Unary_Ops__Begin < kind && kind < IR_Kind.Unary_Ops__End
}

is_binary_op :: proc(kind: IR_Kind) -> bool {
    return IR_Kind.Binary_Ops__Begin < kind && kind < IR_Kind.Binary_Ops__End
}

is_communication :: proc(kind: IR_Kind) -> bool {
    return IR_Kind.Communication__Begin < kind && kind < IR_Kind.Communication__End
}

Symbol_Table :: distinct map[string]int

IR_Node :: struct {
    id:         int,
    kind:       IR_Kind,
    type:       ^Type,
    inputs:     [dynamic]^IR_Node,
    users:      [dynamic]^IR_Node,
}


IR_Graph :: struct {
    nodes:      map[int]^IR_Node,
    next_id:    int,
    start:      ^IR_Node,
    end:        ^IR_Node,
    curr_node:  ^IR_Node,
    scopes:     [dynamic]Symbol_Table,
    curr_scope: Symbol_Table
}


make_ir_node :: proc(graph: ^IR_Graph, kind: IR_Kind, type: ^Type) -> ^IR_Node {
    node                    := new(IR_Node)
    node.id                 = graph.next_id
    node.kind               = kind
    graph.next_id           += 1
    graph.nodes[node.id]    = node
    return node
}

make_ir_graph :: proc() -> ^IR_Graph {
    graph               := new(IR_Graph)
    graph.nodes         = make(map[int]^IR_Node) 
    graph.start         = make_ir_node(graph, .Start, nil)
    graph.end           = make_ir_node(graph, .End, nil)
    graph.curr_node     = graph.start
    graph.scopes        = make([dynamic]Symbol_Table)
    graph.curr_scope    = nil
    return graph
}

add_edge :: proc(from, to: ^IR_Node) {
    append(&from.users, to)
    append(&to.inputs, from)
}

push_scope :: proc(graph: ^IR_Graph) {
    scope: Symbol_Table
    append(&graph.scopes, scope)
    graph.curr_scope = scope
}

pop_scope :: proc(graph: ^IR_Graph) {
    pop(&graph.scopes)
    graph.curr_scope = graph.scopes[len(graph.scopes)]
}
