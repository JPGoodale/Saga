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
        id := graph.curr_scope[leaf_node.value]
        if id == -1 {
            // Not yet defined in current scope
            return make_ir_node(graph, .Load, nil)
        }
        return graph.nodes[id]

    case .Basic_Literal:
        leaf_node := leaf.derived.(Basic_Literal)
        // Create constant node with the literal value
        return make_ir_node(graph, .Load, nil)

    case .Compound_Literal:
        leaf_node := leaf.derived.(Compound_Literal)
        // Convert type
        type_node := convert_leaf(graph, leaf_node.type)
        
        // Convert each element
        elem_nodes := make([dynamic]^IR_Node)
        for elem in leaf_node.elems {
            if node := convert_leaf(graph, elem); node != nil {
                append(&elem_nodes, node.(^IR_Node))
            }
        }
        
        // Create constructor node
        node := make_ir_node(graph, .New, type_node.(^Type))
        for elem_node in elem_nodes {
            add_edge(elem_node, node)
        }
        return node

    case .Procedure_Literal:
        leaf_node := leaf.derived.(Procedure_Literal)
        push_scope(graph)
        
        // Convert type and body
        type_node := convert_leaf(graph, leaf_node.type)
        proc_node := make_ir_node(graph, .Region, type_node.(^Type))
        
        old_node := graph.curr_node
        graph.curr_node = proc_node
        
        body_node := convert_leaf(graph, leaf_node.body)
        if body_node != nil {
            add_edge(proc_node, body_node.(^IR_Node))
        }
        
        pop_scope(graph)
        graph.curr_node = old_node
        return proc_node

    case .Field:
        leaf_node := leaf.derived.(Field)
        type_node := convert_leaf(graph, leaf_node.type)
        
        field_nodes := make([dynamic]^IR_Node)
        for name in leaf_node.names {
            if id, ok := name.derived.(Identifier); ok {
                field := make_ir_node(graph, .Field, type_node.(^Type))
                graph.curr_scope[id.value] = field.id
                append(&field_nodes, field)
            }
        }
        
        if len(field_nodes) == 1 {
            return field_nodes[0]
        }
        return nil

    case .Field_List:
        leaf_node := leaf.derived.(Field_List)
        for node in leaf_node.nodes {
            convert_leaf(graph, node)
        }
        return nil

    case .Field_Value:
        leaf_node := leaf.derived.(Field_Value)
        field := convert_leaf(graph, leaf_node.field)
        value := convert_leaf(graph, leaf_node.value)
        
        if field != nil && value != nil {
            store := make_ir_node(graph, .Store, nil)
            add_edge(field.(^IR_Node), store)
            add_edge(value.(^IR_Node), store)
            return store
        }
        return nil

    // Expression nodes
    case .Bad_Expr:
        return nil

    case .Unary_Expr:
        leaf_node := leaf.derived.(Unary_Expr)
        expr := convert_leaf(graph, leaf_node.expr)
        if expr == nil do return nil

        ir_op := IR_Kind.Not // Default
        switch leaf_node.op.kind {
        case .Not: ir_op = .Not
        case .Sub: ir_op = .Neg
        case .Xor: ir_op = .Not
        }
        
        node := make_ir_node(graph, ir_op, nil)
        add_edge(expr.(^IR_Node), node)
        return node

    case .Binary_Expr:
        leaf_node := leaf.derived.(Binary_Expr)
        left := convert_leaf(graph, leaf_node.left)
        right := convert_leaf(graph, leaf_node.right)
        
        ir_op := IR_Kind.Add // Default
        switch leaf_node.op.kind {
        case .Add: ir_op = .Add
        case .Sub: ir_op = .Sub
        case .Mul: ir_op = .Mul
        case .Div: ir_op = .Div
        case .Mod: ir_op = .Mod
        case .Lt: ir_op = .Lt
        case .Gt: ir_op = .Gt
        case .Lt_Eq: ir_op = .Lt_Eq
        case .Gt_Eq: ir_op = .Gt_Eq
        case .Eq_Eq: ir_op = .Eq
        case .Not_Eq: ir_op = .Not_Eq
        case .And: ir_op = .And
        case .Or: ir_op = .Or
        case .Xor: ir_op = .Xor
        }
        
        node := make_ir_node(graph, ir_op, nil)
        if left != nil do add_edge(left.(^IR_Node), node)
        if right != nil do add_edge(right.(^IR_Node), node)
        return node

    case .Selector_Expr:
        leaf_node := leaf.derived.(Selector_Expr)
        expr := convert_leaf(graph, leaf_node.expr)
        selector := convert_leaf(graph, leaf_node.selector)
        
        if expr != nil && selector != nil {
            // Handle swizzle operations if present
            if leaf_node.swizzle_count > 0 {
                // Create vector swizzle operation
                node := make_ir_node(graph, .Shfl, nil)
                add_edge(expr.(^IR_Node), node)
                return node
            } else {
                // Regular field access
                node := make_ir_node(graph, .Field, nil)
                add_edge(expr.(^IR_Node), node)
                add_edge(selector.(^IR_Node), node)
                return node
            }
        }
        return nil

    case .Slice_Expr, .Index_Expr, .Matrix_Index_Expr, .Tensor_Index_Expr:
        leaf_node := leaf.derived.(Index_Expr)
        expr := convert_leaf(graph, leaf_node.expr)
        index := convert_leaf(graph, leaf_node.index)
        
        if expr != nil && index != nil {
            node := make_ir_node(graph, .Load, nil)
            add_edge(expr.(^IR_Node), node)
            add_edge(index.(^IR_Node), node)
            return node
        }
        return nil

    case .Deref_Expr:
        leaf_node := leaf.derived.(Deref_Expr)
        expr := convert_leaf(graph, leaf_node.expr)
        
        if expr != nil {
            node := make_ir_node(graph, .Load, nil)
            add_edge(expr.(^IR_Node), node)
            return node
        }
        return nil

    case .Call_Expr:
        leaf_node := leaf.derived.(Call_Expr)
        func := convert_leaf(graph, leaf_node.expr)
        
        // Convert arguments
        arg_nodes := make([dynamic]^IR_Node)
        for arg in leaf_node.args {
            if node := convert_leaf(graph, arg); node != nil {
                append(&arg_nodes, node.(^IR_Node))
            }
        }
        
        // Create call node
        call := make_ir_node(graph, .Call, nil)
        if func != nil do add_edge(func.(^IR_Node), call)
        for arg in arg_nodes {
            add_edge(arg, call)
        }
        return call

    case .Cast_Expr:
        leaf_node := leaf.derived.(Cast_Expr)
        type_node := convert_leaf(graph, leaf_node.type)
        expr := convert_leaf(graph, leaf_node.expr)
        
        if type_node != nil && expr != nil {
            node := make_ir_node(graph, .Move, type_node.(^Type))
            add_edge(expr.(^IR_Node), node)
            return node
        }
        return nil

    case .Paren_Expr:
        leaf_node := leaf.derived.(Paren_Expr)
        return convert_leaf(graph, leaf_node.expr)

    case .Ternary_If_Expr:
        leaf_node := leaf.derived.(Ternary_If_Expr)
        cond := convert_leaf(graph, leaf_node.cond)
        x := convert_leaf(graph, leaf_node.x)
        y := convert_leaf(graph, leaf_node.y)
        
        branch := make_ir_node(graph, .Branch, nil)
        if cond != nil do add_edge(cond.(^IR_Node), branch)
        
        phi := make_ir_node(graph, .Phi, nil)
        if x != nil do add_edge(x.(^IR_Node), phi)
        if y != nil do add_edge(y.(^IR_Node), phi)
        add_edge(branch, phi)
        
        return phi

    // Statement nodes
    case .Bad_Stmt:
        return nil

    case .Assign_Stmt:
        leaf_node := leaf.derived.(Assign_Stmt)
        
        // Convert RHS expressions first
        rhs_nodes := make([dynamic]^IR_Node)
        for rhs in leaf_node.rhs {
            if node := convert_leaf(graph, rhs); node != nil {
                append(&rhs_nodes, node.(^IR_Node))
            }
        }
        
        // Handle different assignment types
        store_nodes := make([dynamic]^IR_Node)
        
        for i := 0; i < len(leaf_node.lhs); i += 1 {
            lhs := leaf_node.lhs[i]
            rhs := rhs_nodes[min(i, len(rhs_nodes)-1)]
            
            // Create store node
            store := make_ir_node(graph, .Store, nil)
            add_edge(rhs, store)
            
            // Update symbol table for direct assignments
            if id, ok := lhs.derived.(Identifier); ok {
                graph.curr_scope[id.value] = store.id
            }
            
            append(&store_nodes, store)
        }
        
        // Return last store node
        if len(store_nodes) > 0 {
            graph.curr_node = store_nodes[len(store_nodes)-1]
            return store_nodes[len(store_nodes)-1]
        }
        return nil

    case .Block_Stmt:
        push_scope(graph)
        leaf_node := leaf.derived.(Block_Stmt)
        block_node := make_ir_node(graph, .Region, nil)
        add_edge(graph.curr_node, block_node)
        graph.curr_node = block_node
        
        for stmt in leaf_node.stmts {
            node := convert_leaf(graph, stmt)
            if node != nil {
                if n, ok := node.(^IR_Node); ok {
                    add_edge(graph.curr_node, n)
                    graph.curr_node = n
                }
            }
        }
        
        pop_scope(graph)
        return block_node

    case .If_Stmt:
        leaf_node := leaf.derived.(If_Stmt)
        cond := convert_leaf(graph, leaf_node.cond)
        
        branch := make_ir_node(graph, .Branch, nil)
        if cond != nil do add_edge(cond.(^IR_Node), branch)
        add_edge(graph.curr_node, branch)
        
        then_node := convert_leaf(graph, leaf_node.body)
        if then_node != nil do add_edge(branch, then_node.(^IR_Node))
        
        if leaf_node.else_stmt != nil {
            else_node := convert_leaf(graph, leaf_node.else_stmt)
            if else_node != nil do add_edge(branch, else_node.(^IR_Node))
        }
        
        merge := make_ir_node(graph, .Phi, nil)
        add_edge(branch, merge)
        graph.curr_node = merge
        return merge

    case .For_Stmt:
        leaf_node := leaf.derived.(For_Stmt)
        
        // Create loop header
        header := make_ir_node(graph, .Region, nil)
        add_edge(graph.curr_node, header)
        
        // Initialize loop variable if present
        if leaf_node.init != nil {
            init := convert_leaf(graph, leaf_node.init)
            if init != nil do add_edge(header, init.(^IR_Node))
        }
        
        // Create loop condition
        if leaf_node.cond != nil {
            cond := convert_leaf(graph, leaf_node.cond)
            if cond != nil do add_edge(header, cond.(^IR_Node))
        }
        
        // Convert loop body
        body := convert_leaf(graph, leaf_node.body)
        if body != nil do add_edge(header, body.(^IR_Node))
        
        // Handle post iteration statement
        if leaf_node.post != nil {
            post := convert_leaf(graph, leaf_node.post)
            if post != nil do add_edge(body.(^IR_Node), post.(^IR_Node))
        }
        
        // Create loop back edge
        add_edge(body.(^IR_Node), header)
        
        graph.curr_node = header
        return header

    case .Range_Stmt:
        leaf_node := leaf.derived.(Range_Stmt)
        
        // Convert range expression
        range_expr := convert_leaf(graph, leaf_node.expr)
        
        // Create loop header
        header := make_ir_node(graph, .Region, nil)
        add_edge(graph.curr_node, header)
        
        if range_expr != nil {
            add_edge(range_expr.(^IR_Node), header)
        }
        
        // Convert loop body
        body := convert_leaf(graph, leaf_node.body)
        if body != nil {
            add_edge(header, body.(^IR_Node))
            add_edge(body.(^IR_Node), header)  // Loop back edge
        }
        
        graph.curr_node = header
        return header

    case .Return_Stmt:
        leaf_node := leaf.derived.(Return_Stmt)
        
        // Convert return values
        ret_nodes := make([dynamic]^IR_Node)
        for result in leaf_node.results {
            if node := convert_leaf(graph, result); node != nil {
                append(&ret_nodes, node.(^IR_Node))
            }
        }
        
        // Create return node
        ret := make_ir_node(graph, .Return, nil)
        for node in ret_nodes {
            add_edge(node, ret)
        }
        add_edge(graph.curr_node, ret)
        add_edge(ret, graph.end)
        
        graph.curr_node = ret
        return ret

    case .Defer_Stmt:
        leaf_node := leaf.derived.(Defer_Stmt)
        stmt := convert_leaf(graph, leaf_node.stmt)
        
        // Create defer node that will be executed at function exit
        if stmt != nil {
            node := make_ir_node(graph, .Call, nil)  // Using Call for deferred execution
            add_edge(stmt.(^IR_Node), node)
            add_edge(node, graph.end)  // Connect to end to ensure execution
            return node
        }
        return nil

    case .Bad_Decl:
        return nil

    case .Module_Decl:
        leaf_node := leaf.derived.(Module_Decl)
        // Create a new scope for the module
        push_scope(graph)
        
        // Create module node
        module := make_ir_node(graph, .Region, nil)
        add_edge(graph.curr_node, module)
        graph.curr_node = module
        
        return module

    case .Value_Decl:
        leaf_node := leaf.derived.(Value_Decl)
        
        // Convert type if present
        type_node : ^Type = nil
        if leaf_node.type != nil {
            if type_entity := convert_leaf(graph, leaf_node.type); type_entity != nil {
                type_node = type_entity.(^Type)
            }
        }
        
        // Convert values
        value_nodes := make([dynamic]^IR_Node)
        for value in leaf_node.values {
            if node := convert_leaf(graph, value); node != nil {
                append(&value_nodes, node.(^IR_Node))
            }
        }
        
        // Create storage nodes for each name
        decl_nodes := make([dynamic]^IR_Node)
        for i := 0; i < len(leaf_node.names); i += 1 {
            name := leaf_node.names[i]
            
            if id, ok := name.derived.(Identifier); ok {
                // Create allocation node
                alloc := make_ir_node(graph, .Alloca, type_node)
                
                // If we have a value, create a store
                if i < len(value_nodes) {
                    store := make_ir_node(graph, .Store, type_node)
                    add_edge(value_nodes[i], store)
                    add_edge(alloc, store)
                }
                
                // Update symbol table
                graph.curr_scope[id.value] = alloc.id
                append(&decl_nodes, alloc)
            }
        }
        
        if len(decl_nodes) > 0 {
            return decl_nodes[len(decl_nodes)-1]
        }
        return nil

    // Type nodes
    case .Procedure_Type:
        leaf_node := leaf.derived.(Procedure_Type)
        
        // Convert parameter and result types
        params_node := convert_leaf(graph, leaf_node.params)
        results_node := convert_leaf(graph, leaf_node.results)
        
        // Create function type
        type_node := make_procedure_type(leaf_node.varient, params_node.(^Type), results_node.(^Type))
        return type_node

    case .Basic_Type:
        leaf_node := leaf.derived.(Basic_Type)
        return make_basic(BASIC_TYPE_MAP[leaf_node.value], leaf_node)

    case .Pointer_Type:
        leaf_node := leaf.derived.(Pointer_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        return make_pointer(elem_type.(^Type), leaf_node)

    case .Multi_Pointer_Type:
        leaf_node := leaf.derived.(Multi_Pointer_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        return make_pointer(elem_type.(^Type), leaf_node)

    case .Array_Type, .Vector_Type:
        leaf_node := leaf.derived.(Array_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        
        size_expr := convert_leaf(graph, leaf_node.size)
        shape := []^IR_Node{size_expr.(^IR_Node)} if size_expr != nil else nil
        
        return make_tensor(elem_type.(^Type), shape, leaf_node)

    case .Dynamic_Array_Type:
        leaf_node := leaf.derived.(Dynamic_Array_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        return make_tensor(elem_type.(^Type), nil, leaf_node)

    case .Matrix_Type:
        leaf_node := leaf.derived.(Matrix_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        
        rows_expr := convert_leaf(graph, leaf_node.rows)
        cols_expr := convert_leaf(graph, leaf_node.cols)
        shape := make([dynamic]^IR_Node)
        if rows_expr != nil do append(&shape, rows_expr.(^IR_Node))
        if cols_expr != nil do append(&shape, cols_expr.(^IR_Node))
        
        return make_tensor(elem_type.(^Type), shape[:], leaf_node)

    case .Dynamic_Matrix_Type:
        leaf_node := leaf.derived.(Dynamic_Matrix_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        return make_tensor(elem_type.(^Type), nil, leaf_node)

    case .Tensor_Type:
        leaf_node := leaf.derived.(Tensor_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        
        // Convert shape expressions
        shape := make([dynamic]^IR_Node)
        for dim in leaf_node.shape {
            if dim_expr := convert_leaf(graph, dim); dim_expr != nil {
                append(&shape, dim_expr.(^IR_Node))
            }
        }
        
        return make_tensor(elem_type.(^Type), shape[:], leaf_node)

    case .Dynamic_Tensor_Type:
        leaf_node := leaf.derived.(Dynamic_Tensor_Type)
        elem_type := convert_leaf(graph, leaf_node.elem_type)
        return make_tensor(elem_type.(^Type), nil, leaf_node)

    // Marker cases
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
    
    return nil
}
