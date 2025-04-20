package saga_compiler
import "core:fmt"

// NOTE: The AST can and should be totally replaced by the graph since we are using the SON approach but 
// I dont feel like refactoring the parser right now.. (Teehee!)

IR_Entity :: union {
    IR_Node,
    Type,
}

tree_to_graph :: proc(tree: []^Ast_Node) -> (graph: ^IR_Graph) {
    graph = make_ir_graph()
    for leaf in tree {
        convert_leaf(graph, leaf)
    }
    return
}

convert_leaf :: proc(graph: ^IR_Graph, leaf: ^Ast_Node) -> ^IR_Entity {
    if leaf == nil do return nil
    
    switch leaf.kind {
    // Basic nodes
    case .Identifier:
        leaf_node := leaf.derived.(Identifier)
        graph.curr_scope[leaf_node.value] = -1

    case .Basic_Literal:
        leaf_node := leaf.derived.(Basic_Literal)

    case .Compound_Literal:
        leaf_node := leaf.derived.(Compound_Literal)

    case .Procedure_Literal:
        leaf_node := leaf.derived.(Procedure_Literal)
        push_scope(graph)
        convert_leaf(graph, leaf_node.type)
        convert_leaf(graph, leaf_node.body)

    case .Field:
        leaf_node := leaf.derived.(Field)
        type := convert_leaf(graph, leaf_node.type)
        for subnode in leaf_node.names {
            convert_leaf(graph, subnode)
            make_ir_node(graph, .Field, type)
        }

    case .Field_List:
        leaf_node := leaf.derived.(Field_List)
        for subnode in leaf_node.nodes do convert_leaf(graph, subnode)

    case .Field_Value:
        leaf_node := leaf.derived.(Field_Value)

    // Expression nodes
    case .Bad_Expr:
    
    case .Unary_Expr:
        leaf_node := leaf.derived.(Unary_Expr)

    case .Binary_Expr:
        leaf_node := leaf.derived.(Binary_Expr)

    case .Selector_Expr:
        leaf_node := leaf.derived.(Selector_Expr)

    case .Slice_Expr:
        leaf_node := leaf.derived.(Slice_Expr)

    case .Index_Expr:
        leaf_node := leaf.derived.(Index_Expr)

    case .Matrix_Index_Expr:
        leaf_node := leaf.derived.(Matrix_Index_Expr)

    case .Tensor_Index_Expr:
        leaf_node := leaf.derived.(Tensor_Index_Expr)

    case .Deref_Expr:
        leaf_node := leaf.derived.(Deref_Expr)

    case .Call_Expr:
        leaf_node := leaf.derived.(Call_Expr)

    case .Cast_Expr:
        leaf_node := leaf.derived.(Cast_Expr)

    case .Paren_Expr:
        leaf_node := leaf.derived.(Paren_Expr)

    case .Ternary_If_Expr:
        leaf_node := leaf.derived.(Ternary_If_Expr)
        
    // Statement nodes
    case .Bad_Stmt:

    case .Assign_Stmt:
        leaf_node := leaf.derived.(Assign_Stmt)

    case .Block_Stmt:
        push_scope(graph)
        leaf_node := leaf.derived.(Block_Stmt)
        for subnode in leaf_node.stmts do convert_leaf(graph, subnode)

    case .If_Stmt:
        leaf_node := leaf.derived.(If_Stmt)

    case .For_Stmt:
        leaf_node := leaf.derived.(For_Stmt)

    case .Range_Stmt:
        leaf_node := leaf.derived.(Range_Stmt)

    case .Return_Stmt:
        leaf_node := leaf.derived.(Return_Stmt)

    case .Defer_Stmt:
        leaf_node := leaf.derived.(Defer_Stmt)
        
    // Declaration nodes
    case .Bad_Decl:

    case .Module_Decl:
        leaf_node := leaf.derived.(Module_Decl)

    case .Value_Decl:
        leaf_node := leaf.derived.(Value_Decl)
        
    // Type nodes
    case .Procedure_Type:
        leaf_node := leaf.derived.(Procedure_Type)
        convert_leaf(graph, leaf_node.params)
        convert_leaf(graph, leaf_node.results)

    case .Basic_Type:
        leaf_node := leaf.derived.(Basic_Type)
        kind := BASIC_TYPE_MAP[leaf_node.value]
        type = make_basic(kind, leaf_node)

    case .Pointer_Type:
        leaf_node := leaf.derived.(Pointer_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_pointer(type.kind, leaf)

    case .Multi_Pointer_Type:
        leaf_node := leaf.derived.(Multi_Pointer_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_pointer(type.kind, leaf)

    case .Array_Type:
        leaf_node := leaf.derived.(Array_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, {leaf_node.size}, leaf)

    case .Dynamic_Array_Type:
        leaf_node := leaf.derived.(Dynamic_Array_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, nil, leaf)

    case .Vector_Type:
        leaf_node := leaf.derived.(Vector_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, {leaf_node.size}, leaf)

    case .Matrix_Type:
        leaf_node := leaf.derived.(Matrix_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, {leaf_node.rows, leaf_node.cols}, leaf)

    case .Dynamic_Matrix_Type:
        leaf_node := leaf.derived.(Dynamic_Matrix_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, nil, leaf)

    case .Tensor_Type:
        leaf_node := leaf.derived.(Tensor_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, leaf)

    case .Dynamic_Tensor_Type:
        leaf_node := leaf.derived.(Dynamic_Tensor_Type)
        type := convert_leaf(leaf_node.elem_type)
        make_tensor(type.kind, nil, leaf)
        
    // Marker cases (shouldn't occur)
    case .Expressions__Begin,
         .Expressions__End,
         .Statements__Begin,
         .Statements__End,
         .Declarations__Begin,
         .Declarations__End,
         .Types__Begin,
         .Types__End:
        fmt.eprintln("ERROR: Found marker node type:", leaf.kind)
        return nil
    }
    
    return
}
