package saga_compiler
import "core:fmt"
import "core:log"
import "core:strings"
import "core:strconv"
import saga "../"


Ctx :: struct {
    grid_layout:            saga.Layout,
    module_name:            string,

    capability:             OpCapability,
    memory_model:           OpMemoryModel,
    execution_mode:         OpExecutionMode,
    entry_point:            OpEntryPoint,
    kernel_function:        OpFunction,
    kernel_body_label:      OpLabel,
    kernel_return:          OpReturn, // Here just for pedantic purposes
    kernel_function_end:    OpFunctionEnd, // ^ What he said..

    extensions:             [dynamic]OpExtInstImport,
    annotations:            [dynamic]OpAnnotation,
    scalar_types:           [dynamic]OpType,
    types:                  [dynamic]OpType,
    constants:              [dynamic]OpConstant,
    variables:              [dynamic]OpVariable,
    local_variables:        [dynamic]OpVariable,
    loads:                  [dynamic]OpLoad,
    stores:                 [dynamic]OpStore,
    composites:             [dynamic]OpComposite,
    access_chains:          [dynamic]OpAccessChain,
    operations:             [dynamic]Operation,
    arg_name_ids:           [dynamic]Id,
    storage_buffer_ids:     [dynamic]Id,
    workgroup_buffer_ids:   [dynamic]Id,

    constant_map:           map[string]Result_Id,
    variable_map:           map[string]Result_Id,

    arg_scalar_type_map:    map[Id]string, // Should probably just replace all these with the regular scalar type map

    access_chain_map:       map[Result_Id]bool, // ^ Same as above but for access chains
    load_map:               map[Result_Id]bool, // ^^^

    thread_id_map:          map[string]string,
    scalar_type_map:        map[string]string,
    storage_buf_ptr_map:    map[string]string,
    workgroup_buf_ptr_map:  map[string]string,
    push_constant_ptr_map:  map[string]string,
    runtime_array_map:      map[string]string,
    array_map:              map[string]string,

    zeroth_thread_id:       Id,
    max_thread_id:          Id,

    binary_op_counter:      int, // A strange and janky trick..
    unary_op_counter:       int, // Yet another strange and janky trick...
}


create_id :: proc(names: []string) -> (id: Id) {
    id = Id(strings.join(names, ""))
    return
}


create_result_id :: proc(names: []string) -> (result_id: Result_Id) {
    result_id = Result_Id(strings.join(names, ""))
    return
}


create_constant :: proc(ctx: ^Ctx, type_name: string, value: string) -> (id: Id) {
    value := value
    value_literal: Numeric_Type

    if !(value in ctx.constant_map) {
        if contains(value, ".") {
            value_literal = atof(value)
            value, _ = replace_all(value, ".", "_")
        }
        else {
            value_literal = atoi(value)
        }

        constant                : OpConstant
        constant.result         = create_result_id({"%", type_name, "_", value})
        constant.result_type    = create_id({"%", type_name})
        constant.value          = value_literal

        append(&ctx.constants, constant)
        ctx.constant_map[value] = constant.result
        id = auto_cast(constant.result)
        return
    }

    id = auto_cast(ctx.constant_map[value])
    return
}


create_local_variable :: proc(ctx: ^Ctx, name: string, type_id: Id, storage_class: Storage_Class, initializer: Id = "") -> (id: Id) {
    if !(name in ctx.variable_map) {
        variable                : OpVariable
        variable.result         = create_result_id({"%", name})
        variable.result_type    = type_id
        variable.storage_class  = storage_class
        variable.initializer    = initializer

        append(&ctx.local_variables, variable)
        ctx.variable_map[name] = variable.result
        id = auto_cast(variable.result)
        return
    }

    id = auto_cast(ctx.variable_map[name])
    return
}


create_storage_buffer :: proc(ctx: ^Ctx, node: saga.Array_Type, element_type_name: string) -> (storage_buffer_id: Id) {
    if !(element_type_name in ctx.storage_buf_ptr_map) {
        pointer                                     : OpTypePointer
        pointer.result                              = create_result_id({"%_ptr_StorageBuffer_", element_type_name})
        pointer.storage_class                       = .StorageBuffer
        pointer.type                                = create_id({"%", element_type_name})
        append(&ctx.types, pointer)
        ctx.storage_buf_ptr_map[element_type_name] = auto_cast(pointer.result)
    }

    switch node.n_elements {
    case "":
        if element_type_name in ctx.runtime_array_map {
            storage_buffer_id = create_id({"%_ptr_StorageBuffer_structured_rtarray_", element_type_name})
            return 
        }
        runtime_array                               : OpTypeRuntimeArray
        runtime_array.result                        = create_result_id({"%_rtarray_", element_type_name})
        runtime_array.element_type                  = create_id({"%", element_type_name})
        append(&ctx.types, runtime_array)
        ctx.runtime_array_map[element_type_name] = auto_cast(runtime_array.result)

        struct_buffer                               : OpTypeStruct
        struct_buffer.result                        = create_result_id({"%_structured_rtarray_", element_type_name})
        struct_buffer.members                       = {auto_cast(runtime_array.result)}
        append(&ctx.types, struct_buffer)

        struct_pointer                              : OpTypePointer
        struct_pointer.result                       = create_result_id({"%_ptr_StorageBuffer_structured_rtarray_", element_type_name})
        struct_pointer.storage_class                = .StorageBuffer
        struct_pointer.type                         = auto_cast(struct_buffer.result)
        append(&ctx.types, struct_pointer)

        rt_array_decorate                           : OpDecorate
        rt_array_decorate.target                    = create_id({"%_rtarray_", element_type_name})
        rt_array_decorate.decoration                = .ArrayStride
        rt_array_decorate.decoration_operands       = {4}
        append(&ctx.annotations, rt_array_decorate)

        struct_decorate                             : OpDecorate
        struct_decorate.target                      = auto_cast(struct_buffer.result)
        struct_decorate.decoration                  = .Block
        append(&ctx.annotations, struct_decorate)

        struct_member_decorate                      : OpMemberDecorate
        struct_member_decorate.structure_type       = auto_cast(struct_buffer.result)
        struct_member_decorate.member               = 0
        struct_member_decorate.decoration           = .Offset
        struct_member_decorate.decoration_operands  = {0}
        append(&ctx.annotations, struct_member_decorate)

        storage_buffer_id = auto_cast(struct_pointer.result)
        return

    case:
        if element_type_name in ctx.array_map {
            storage_buffer_id = create_id({"%_ptr_StorageBuffer_structured_array_", element_type_name})
            return 
        }
        constant_id := create_constant(ctx, "uint32", node.n_elements)

        array                                       : OpTypeArray
        array.result                                = create_result_id({"%_array_", element_type_name})
        array.element_type                          = create_id({"%", element_type_name})
        array.length                                = constant_id
        append(&ctx.types, array)
        ctx.array_map[element_type_name] = auto_cast(array.result)

        struct_buffer                               : OpTypeStruct
        struct_buffer.result                        = create_result_id({"%_structured_array_", element_type_name})
        struct_buffer.members                       = {auto_cast(array.result)}
        append(&ctx.types, struct_buffer)

        struct_pointer                              : OpTypePointer
        struct_pointer.result                       = create_result_id({"%_ptr_StorageBuffer_structured_array_", element_type_name})
        struct_pointer.storage_class                = .StorageBuffer
        struct_pointer.type                         = auto_cast(struct_buffer.result)
        append(&ctx.types, struct_pointer)

        array_decorate                              : OpDecorate
        array_decorate.target                       = create_id({"%_array_", element_type_name})
        array_decorate.decoration                   = .ArrayStride
        array_decorate.decoration_operands          = {4}
        append(&ctx.annotations, array_decorate)

        struct_decorate                             : OpDecorate
        struct_decorate.target                      = auto_cast(struct_buffer.result)
        struct_decorate.decoration                  = .Block
        append(&ctx.annotations, struct_decorate)

        struct_member_decorate                      : OpMemberDecorate
        struct_member_decorate.structure_type       = auto_cast(struct_buffer.result)
        struct_member_decorate.member               = 0
        struct_member_decorate.decoration           = .Offset
        struct_member_decorate.decoration_operands  = {0}
        append(&ctx.annotations, struct_member_decorate)

        storage_buffer_id = auto_cast(struct_pointer.result)
        return
    }
}


create_workgroup_buffer :: proc(ctx: ^Ctx, node: saga.Array_Type, element_type_name: string) -> (workgroup_buffer_id: Id) {
    if !(element_type_name in ctx.workgroup_buf_ptr_map) {
        pointer                                     : OpTypePointer
        pointer.result                              = create_result_id({"%_ptr_Workgroup_", element_type_name})
        pointer.storage_class                       = .Workgroup
        pointer.type                                = create_id({"%", element_type_name})
        append(&ctx.types, pointer)
        ctx.workgroup_buf_ptr_map[element_type_name] = auto_cast(pointer.result)
        workgroup_buffer_id = auto_cast(pointer.result)
        append(&ctx.workgroup_buffer_ids, workgroup_buffer_id)
        return
    }
    else {
        workgroup_buffer_id = auto_cast(ctx.workgroup_buf_ptr_map[element_type_name])
        append(&ctx.workgroup_buffer_ids, workgroup_buffer_id)
    }
    return
}


set_capability :: proc(ctx: ^Ctx) {
    capability              : OpCapability
    capability.capability   = .Shader
    ctx.capability = capability
}


set_extensions :: proc(ctx: ^Ctx) {
    glsl_entension          : OpExtInstImport
    glsl_entension.name     = "GLSL.std.450"
    glsl_entension.result   = auto_cast("%glsl")
    append(&ctx.extensions, glsl_entension)
}


set_memory_model :: proc(ctx: ^Ctx) {
    memory_model                    : OpMemoryModel
    memory_model.addressing_model   = .Logical
    memory_model.memory_model       = .GLSL450
    ctx.memory_model = memory_model
}


translate_module :: proc(ctx: ^Ctx, node: saga.Module) {
    set_capability(ctx)
    set_extensions(ctx)
    set_memory_model(ctx)
    ctx.module_name = node.name
}


translate_layout :: proc(ctx: ^Ctx, node: saga.Layout) {
    if node.is_grid {
        ctx.grid_layout = node
        return
    }

    execution_mode                  : OpExecutionMode
    execution_mode.mode             = .LocalSize
    execution_mode.mode_operands    = {node.x, node.y, node.z}
    ctx.execution_mode = execution_mode
    
    // We assume that the global_thread_id is being used, may add a pass which checks if it's not
    decorate                        : OpDecorate
    decorate.target                 = auto_cast("%gl_GlobalInvocationID")
    decorate.decoration             = .BuiltIn
    decorate.decoration_operands    = {Builtin.GlobalInvocationId}
    append(&ctx.annotations, decorate)

    uint                            : OpTypeInt
    uint.result                     = auto_cast("%uint32")
    uint.width                      = 32
    uint.signedness                 = 0
    append(&ctx.scalar_types, uint)
    ctx.scalar_type_map["u32"] = "%uint32"

    uint_vec3                       : OpTypeVector
    uint_vec3.result                = auto_cast("%v3uint32")
    uint_vec3.component_type        = auto_cast("%uint32")
    uint_vec3.component_count       = 3
    append(&ctx.types, uint_vec3)

    uint_vec3_ptr                   : OpTypePointer
    uint_vec3_ptr.result            = auto_cast("%_ptr_Input_v3uint32")
    uint_vec3_ptr.type              = auto_cast("%v3uint32")
    uint_vec3_ptr.storage_class     = .Input
    append(&ctx.types, uint_vec3_ptr)

    variable                        : OpVariable
    variable.result                 = auto_cast("%gl_GlobalInvocationID")
    variable.result_type            = auto_cast("%_ptr_Input_v3uint32")
    variable.storage_class          = .Input
    append(&ctx.variables, variable)

    load                            : OpLoad
    load.result                     = auto_cast("%layout_ptr")
    load.result_type                = auto_cast("%v3uint32")
    load.pointer                    = auto_cast("%gl_GlobalInvocationID")
    append(&ctx.loads, load)

    ctx.zeroth_thread_id = create_constant(ctx, "uint32", "0")
}


translate_kernel :: proc(ctx: ^Ctx, node: saga.Kernel) {
    translate_kernel_signature(ctx, node.signature)
    translate_kernel_body(ctx, node.body)
}


translate_kernel_signature :: proc(ctx: ^Ctx, node: saga.Kernel_Signature) {
    entry_point                         : OpEntryPoint
    entry_point.execution_model         = .GLCompute
    entry_point.entry_point             = create_id({"%", node.name})
    entry_point.name                    = node.name
    entry_point.interfaces              = {auto_cast("%gl_GlobalInvocationID")}
    ctx.entry_point = entry_point
    ctx.execution_mode.entry_point = entry_point.entry_point

    return_type                         : OpTypeVoid
    return_type.result                  = auto_cast("%void")
    append(&ctx.types, return_type)

    function_type                       : OpTypeFunction
    function_type.result                = auto_cast("%func_result")
    function_type.return_type           = auto_cast("%void")
    append(&ctx.types, function_type)

    function                            : OpFunction
    function.result                     = create_result_id({"%", node.name})
    function.result_type                = auto_cast("%void")
    function.function_control           = .None
    function.function_type              = auto_cast(function_type.result)
    ctx.kernel_function = function
    
    return_marker                       : OpReturn
    function_end                        : OpFunctionEnd
    ctx.kernel_return = return_marker
    ctx.kernel_function_end = function_end
    
    translate_kernel_args(ctx, node.args)
}


translate_kernel_args :: proc(ctx: ^Ctx, nodes: [dynamic]saga.Argument) {
    for node, idx in nodes {
        switch t in node.type {
        case Array_Type:
            arg_name_id := create_id({"%", node.name})
            append(&ctx.arg_name_ids, arg_name_id)

            element_type_name := translate_scalar_type(ctx, t.element_type)
            ctx.arg_scalar_type_map[arg_name_id] = element_type_name

            storage_buffer_id := create_storage_buffer(ctx, t, element_type_name)
            append(&ctx.storage_buffer_ids, storage_buffer_id)

            decorate                        : OpDecorate
            decorate.target                 = create_id({"%", node.name})
            decorate.decoration             = .DescriptorSet
            decorate.decoration_operands    = {0}
            append(&ctx.annotations, decorate)

            decorate.target                 = create_id({"%", node.name})
            decorate.decoration             = .Binding
            decorate.decoration_operands    = {idx}
            append(&ctx.annotations, decorate)

            variable                        : OpVariable
            variable.result                 = create_result_id({"%", node.name})
            variable.result_type            = storage_buffer_id
            variable.storage_class          = .StorageBuffer
            append(&ctx.variables, variable)
        
        case Scalar_Type:
            arg_name_id := create_id({"%", node.name})
            append(&ctx.arg_name_ids, arg_name_id)

            type_name := translate_scalar_type(ctx, t.variant)
            ctx.arg_scalar_type_map[arg_name_id] = type_name

            member_decorate                     : OpMemberDecorate
            member_decorate.structure_type      = auto_cast("%push_constant")
            member_decorate.member              = 0
            member_decorate.decoration          = .Offset
            member_decorate.decoration_operands = {0}
            append(&ctx.annotations, member_decorate)

            decorate                            : OpDecorate
            decorate.target                     = auto_cast("%push_constant")
            decorate.decoration                 = .Block
            append(&ctx.annotations, decorate)

            structure                           : OpTypeStruct
            structure.result                    = auto_cast("%push_constant")
            structure.members                   = {create_id({"%", type_name})}
            append(&ctx.types, structure)
            
            pointer                             : OpTypePointer
            pointer.result                      = auto_cast("%_ptr_push_constant")
            pointer.storage_class               = .PushConstant
            pointer.type                        = auto_cast("%push_constant")
            append(&ctx.types, pointer)

            variable                            : OpVariable
            variable.result                     = auto_cast(arg_name_id)
            variable.result_type                = auto_cast("%_ptr_push_constant")
            variable.storage_class              = .PushConstant
            append(&ctx.variables, variable)

            pointer.result                      = create_result_id({"%_ptr_push_constant_", type_name})
            pointer.storage_class               = .PushConstant
            pointer.type                        = create_id({"%", type_name})
            append(&ctx.types, pointer)
            ctx.push_constant_ptr_map[type_name] = auto_cast(pointer.result)
        } 
    }
}


translate_kernel_body :: proc(ctx: ^Ctx, nodes: [dynamic]saga.Expression) {
    block_label             : OpLabel
    block_label.result      = auto_cast("%body")
    ctx.kernel_body_label   = block_label
    translate_block(ctx, nodes)
}


translate_block :: proc(ctx: ^Ctx, nodes: [dynamic]saga.Expression) {
    for node, idx in nodes {
        #partial switch n in node {
        case Variable_Declaration:
            translate_variable_declaration(ctx, n)
        case Variable_Expression:
            #partial switch e in n.value {
            case Binary_Expression:
                translate_binary_expression(ctx, n, e) 
            // case Unary_Call_Expression:
            //     translate_call_expression(ctx, n, e)
            case Literal:
                translate_value_assignment(ctx, n, e)
            case Identifier:
                translate_value_assignment(ctx, n, e)
            case:
                fmt.println(n)
                log.error("I'm afraid that this expression is not supported at this time.. a pity, tisn't it?")
            }
        case Conditional_Expression:
            translate_conditional_expression(ctx, n)
        // case Loop_Expression:
        //     translate_loop_expression(ctx, n)
        case:
            fmt.println(n)
            log.error("I'm afraid that this expression is not supported at this time.. a pity, tisn't it?")
        }
    }
}


// This and the proc below could probably be consolidated..
translate_variable_declaration :: proc(ctx: ^Ctx, node: saga.Variable_Declaration) {
    switch t in node.type {
    case Array_Type:
        element_type_name   := translate_scalar_type(ctx, t.element_type)
        workgroup_buffer_id := create_workgroup_buffer(ctx, t, element_type_name)
        variable_id         := create_local_variable(ctx, node.name, workgroup_buffer_id, .Workgroup)

    case Scalar_Type:
        type_name := translate_scalar_type(ctx, t.variant)

        pointer                         : OpTypePointer
        pointer.result                  = create_result_id({"%_ptr_Function_", type_name})
        pointer.storage_class           = .Function
        pointer.type                    = create_id({"%", type_name})
        append(&ctx.types, pointer)

        variable_id := create_local_variable(ctx, node.name, auto_cast(pointer.result), .Function)
    } 
}


// This and the proc above could probably be consolidated..
translate_value_assignment :: proc(ctx: ^Ctx, root_node: saga.Variable_Expression, node: saga.Expression) {
    #partial switch n in node {
    case Literal:
        type_name := translate_scalar_type(ctx, n.type)

        pointer                         : OpTypePointer
        pointer.result                  = create_result_id({"%_ptr_Function_", type_name})
        pointer.storage_class           = .Function
        pointer.type                    = create_id({"%", type_name})
        append(&ctx.types, pointer)

        constant_id := create_constant(ctx, type_name, n.value)
        variable_id := create_local_variable(ctx, root_node.name, auto_cast(pointer.result), .Function, constant_id)

    case Identifier:
        type_name: string
        switch t in n.type {
        case Array_Type:
            type_name = translate_scalar_type(ctx, t.n_elements) 
        case Scalar_Type:
            type_name = translate_scalar_type(ctx, t.variant) 
        }

        load                            : OpLoad
        load.result                     = create_result_id({"%another_", n.name, "_register"}) // No need to comment..
        load.result_type                = create_id({"%", type_name})
        load.pointer                    = create_id({"%", n.name})
        append(&ctx.operations, load)
        
        result_name_id                  := create_id({"%", root_node.name})
        result_max_thread_id            := translate_thread_id(ctx, root_node.thread_idx)
        result_element_type             := ctx.arg_scalar_type_map[result_name_id]
        result_pointer_id               : Id

        if result_name_id in ctx.arg_scalar_type_map {
            result_access_chain             : OpAccessChain
            result_access_chain.result      = create_result_id({string(result_name_id), "_access_chain"})
            result_access_chain.result_type = auto_cast(ctx.storage_buf_ptr_map[result_element_type])
            result_access_chain.base        = result_name_id
            result_access_chain.indexes     = {ctx.zeroth_thread_id, result_max_thread_id}

            if !(result_access_chain.result in ctx.access_chain_map) {
            append(&ctx.operations, result_access_chain)
                ctx.access_chain_map[result_access_chain.result] = true
            }

            result_pointer_id = auto_cast(result_access_chain.result)
        }
        else {
            result_pointer_id = auto_cast(ctx.variable_map[root_node.name])
        }

        store                           : OpStore
        store.pointer                   = auto_cast(result_pointer_id)
        store.object                    = auto_cast(load.result)
        append(&ctx.operations, store)
    } 
}


translate_conditional_expression :: proc(ctx: ^Ctx, node: saga.Conditional_Expression) {
    #partial switch condition in node.condition {
    case Literal, Identifier:
        log.error("Not handled yet")
    case Binary_Expression:
        _condition, _ := translate_binary_expression(ctx, node, condition, true)

        selection_merge                     : OpSelectionMerge
        selection_merge.merge_block         = auto_cast("%block_end")
        selection_merge.selection_control   = .None
        append(&ctx.operations, selection_merge)

        branch_conditional                  : OpBranchConditional
        branch_conditional.condition        = _condition
        branch_conditional.true_label       = auto_cast("%block_start")
        branch_conditional.false_label      = auto_cast("%block_end")
        append(&ctx.operations, branch_conditional)

        block_start_label                   : OpLabel
        block_start_label.result            = auto_cast("%block_start")
        append(&ctx.operations, block_start_label)
    }

    translate_block(ctx, node.body)

    branch                          : OpBranch
    branch.target                   = auto_cast("%block_end")          
    append(&ctx.operations, branch)

    block_stop_label                : OpLabel
    block_stop_label.result         = auto_cast("%block_end")
    append(&ctx.operations, block_stop_label)
}


// Need to add counter for unique ids
// translate_loop_expression :: proc(ctx: ^Ctx, node: Loop_Expression) {
//     pointer                             : OpTypePointer
//     pointer.result                      = auto_cast("%_ptr_Function_uint32")
//     pointer.storage_class               = .Function
//     pointer.type                        = auto_cast("%uint32")
//     append(&ctx.types, pointer)
//
//     start                               : OpVariable
//     start.result                        = auto_cast("%i")
//     start.result_type                   = auto_cast(pointer.result)
//     start.storage_class                 = .Function
//     start.initializer                   = auto_cast("%zeroth_thread_id")
//     append(&ctx.local_variables, start)
//     ctx.variable_map[start.result] = start
//
//     end                                 : OpConstant
//     end.result                          = create_result_id({"%uint32_", node.end.value})
//     end.result_type                     = auto_cast("%uint32")
//     end.value                           = atoi(node.end.value)
//     if !(end.result in ctx.constant_map) {
//         append(&ctx.constants, end)
//         ctx.constant_map[end.result] = true
//     }
//
//     loop_header_branch                  : OpBranch
//     loop_header_branch.target           = auto_cast("%loop_header")
//     append(&ctx.operations, loop_header_branch)
//
//     loop_header_label                   : OpLabel
//     loop_header_label.result            = auto_cast("%loop_header")
//     append(&ctx.operations, loop_header_label)
//
//     i_load                              : OpLoad
//     i_load.result                       = auto_cast("%an_i_register")
//     i_load.result_type                  = auto_cast("%uint32")
//     i_load.pointer                      = auto_cast(start.result)
//     append(&ctx.operations, i_load)
//
//     condition                           : OpSLessThan
//     condition.result                    = auto_cast("%loop_condition")
//     condition.result_type               = auto_cast("%bool")
//     condition.operand_1                 = auto_cast(i_load.result)
//     condition.operand_2                 = auto_cast(end.result)
//     translate_scalar_type(ctx, "bool") // I think that this is to check if it already exists??
//     append(&ctx.operations, condition)
//
//     loop_merge                          : OpLoopMerge
//     loop_merge.merge_block              = auto_cast("%loop_merge")
//     loop_merge.continue_target          = auto_cast("%loop_continue")
//     loop_merge.loop_control             = .None // Might want to inqure deeper into this..
//     append(&ctx.operations, loop_merge)
//
//     branch_conditional                  : OpBranchConditional
//     branch_conditional.condition        = auto_cast("%loop_condition")
//     branch_conditional.true_label       = auto_cast("%loop_body")
//     branch_conditional.false_label      = auto_cast("%loop_merge")
//     append(&ctx.operations, branch_conditional)
//
//     loop_body_label                     : OpLabel
//     loop_body_label.result              = auto_cast("%loop_body")
//     append(&ctx.operations, loop_body_label)
//
//     translate_block(ctx, node.body)
//
//     loop_continue_branch                : OpBranch
//     loop_continue_branch.target         = auto_cast("%loop_continue")          
//     append(&ctx.operations, loop_continue_branch)
//
//     loop_continue_label                 : OpLabel
//     loop_continue_label.result          = auto_cast("%loop_continue")
//     append(&ctx.operations, loop_continue_label)
//
//     next_i_load                         : OpLoad
//     next_i_load.result                  = auto_cast("%next_i_register")
//     next_i_load.result_type             = auto_cast("%uint32")
//     next_i_load.pointer                 = auto_cast(start.result)
//     append(&ctx.operations, next_i_load)
//
//     one                                 : OpConstant
//     one.result                          = auto_cast("%uint32_1")
//     one.result_type                     = auto_cast("%uint32")
//     one.value                           = u32(1)
//     if !(one.result in ctx.constant_map) {
//         append(&ctx.constants, one)
//         ctx.constant_map[one.result] = true
//     }
//
//     incrementer                         : OpIAdd
//     incrementer.result                  = auto_cast("%i_incrementer")
//     incrementer.result_type             = auto_cast("%uint32")
//     incrementer.operand_1               = auto_cast(next_i_load.result)
//     incrementer.operand_2               = auto_cast(one.result)
//     append(&ctx.operations, incrementer)
//
//     i_store                             : OpStore
//     i_store.pointer                     = auto_cast(start.result)
//     i_store.object                      = auto_cast(incrementer.result)
//     append(&ctx.operations, i_store)
//
//     _loop_header_branch                  : OpBranch
//     _loop_header_branch.target           = auto_cast("%loop_header")
//     append(&ctx.operations, _loop_header_branch)
//
//     loop_merge_label                    : OpLabel
//     loop_merge_label.result             = auto_cast("%loop_merge")
//     append(&ctx.operations, loop_merge_label)
// }


translate_binary_expression :: proc(ctx: ^Ctx, root_node: saga.Expression, op_node: saga.Binary_Expression, is_subexpr: bool = false) -> (result_id: Id, type: string) {
    // -----------------------------------------------------------------------------------
    // Left-Hand-Side

    lhs_node:       Identifier
    lhs_load_id:    Id
    lhs_pointer_id: Id

    #partial switch node in op_node.lhs^ {
    case Thread_Idx:
        switch n in node {
        case Thread:
            lhs_value, _        := strings.replace_all(n.value, ".", "_")
            lhs_id              := create_id({"%", lhs_value})
            lhs_max_thread_id   := translate_thread_id(ctx, node)
            lhs_load_id         = auto_cast(lhs_max_thread_id)
        case Binary_Expression:
            log.error("Not yet!") // Do we even need to handle this??
        }
    case Thread:
        // We need some way of converting scientific notation literals to decimal
        lhs_value, _        := strings.replace_all(node.value, ".", "_")
        lhs_id              := create_id({"%", lhs_value})
        lhs_max_thread_id   := translate_thread_id(ctx, node)
        lhs_load_id         = auto_cast(lhs_max_thread_id)

    case Literal:
        type_name := translate_scalar_type(ctx, node.type)
        lhs_load_id = create_constant(ctx, type_name, node.value)

    case Identifier:
        lhs_node = node
        #partial switch t in node.type {
        case Array_Type:
            lhs_id                          := create_id({"%", lhs_node.name})
            lhs_max_thread_id               := translate_thread_id(ctx, lhs_node.thread_idx)
            lhs_element_type                := translate_scalar_type(ctx, t.element_type)

            if lhs_id in ctx.arg_scalar_type_map {
                lhs_access_chain                : OpAccessChain
                lhs_access_chain.result         = create_result_id({string(lhs_id), "_access_chain"})
                lhs_access_chain.result_type    = auto_cast(ctx.storage_buf_ptr_map[lhs_element_type])
                lhs_access_chain.base           = lhs_id
                lhs_access_chain.indexes        = {ctx.zeroth_thread_id, lhs_max_thread_id}

                if !(lhs_access_chain.result in ctx.access_chain_map) {
                append(&ctx.operations, lhs_access_chain)
                    ctx.access_chain_map[lhs_access_chain.result] = true
                }
                lhs_pointer_id = auto_cast(lhs_access_chain.result)
            }
            else {
                lhs_pointer_id = auto_cast(ctx.variable_map[lhs_node.name])
            }

            lhs_load                        : OpLoad
            lhs_load.result                 = create_result_id({string(lhs_id), "_register"})
            lhs_load.result_type            = create_id({"%", lhs_element_type})
            lhs_load.pointer                = lhs_pointer_id
            if !(lhs_load.result in ctx.load_map) {
                append(&ctx.operations, lhs_load)
                ctx.load_map[lhs_load.result] = true
            }

            lhs_load_id = auto_cast(lhs_load.result)

        case Scalar_Type:
            lhs_id                          := create_id({"%", lhs_node.name})
            lhs_max_thread_id               := translate_thread_id(ctx, lhs_node.thread_idx)
            lhs_element_type                := translate_scalar_type(ctx, t.variant)

            if lhs_id in ctx.arg_scalar_type_map {
                lhs_access_chain                : OpAccessChain
                lhs_access_chain.result         = create_result_id({string(lhs_id), "_access_chain"})
                lhs_access_chain.result_type    = auto_cast(ctx.push_constant_ptr_map[lhs_element_type])
                lhs_access_chain.base           = lhs_id
                lhs_access_chain.indexes        = {ctx.zeroth_thread_id} // Not sure what to do here

                if !(lhs_access_chain.result in ctx.access_chain_map) {
                append(&ctx.operations, lhs_access_chain)
                    ctx.access_chain_map[lhs_access_chain.result] = true
                }
                lhs_pointer_id = auto_cast(lhs_access_chain.result)
            }
            else {
                lhs_pointer_id = auto_cast(ctx.variable_map[lhs_node.name])
            }

            lhs_load                        : OpLoad
            lhs_load.result                 = create_result_id({string(lhs_id), "_register"})
            lhs_load.result_type            = create_id({"%", lhs_element_type})
            lhs_load.pointer                = lhs_pointer_id
            if !(lhs_load.result in ctx.load_map) {
                append(&ctx.operations, lhs_load)
                ctx.load_map[lhs_load.result] = true
            }

            // lhs_load_id = auto_cast(ctx.thread_id_map[string(lhs_node.value)]) // Not really sure why this was here
            lhs_load_id = auto_cast(lhs_load.result)
        }

    // case Unary_Call_Expression:
    //     lhs_node = node.operand^
    //
    //     lhs_id                          := create_id({"%", lhs_node.name})
    //     lhs_max_thread_id               := translate_thread_id(ctx, lhs_node.thread_idx)
    //     // We are assuming the operand to be an array here
    //     lhs_element_type                := translate_scalar_type(ctx, lhs_node.type.(Array_Type).element_type) 
    //
    //     if lhs_id in ctx.arg_scalar_type_map {
    //         lhs_access_chain                : OpAccessChain
    //         lhs_access_chain.result         = create_result_id({string(lhs_id), "_access_chain"})
    //         lhs_access_chain.result_type    = auto_cast(ctx.storage_buf_ptr_map[lhs_element_type])
    //         lhs_access_chain.base           = lhs_id
    //         lhs_access_chain.indexes        = {ctx.zeroth_thread_id, lhs_max_thread_id}
    //
    //         if !(lhs_access_chain.result in ctx.access_chain_map) {
    //         append(&ctx.operations, lhs_access_chain)
    //             ctx.access_chain_map[lhs_access_chain.result] = true
    //         }
    //         lhs_pointer_id = auto_cast(lhs_access_chain.result)
    //     }
    //     else {
    //         lhs_pointer_id = auto_cast(ctx.variable_map[auto_cast(lhs_id)].result)
    //     }
    //
    //     lhs_load                        : OpLoad
    //     lhs_load.result                 = create_result_id({string(lhs_id), "_register"})
    //     lhs_load.result_type            = create_id({"%", lhs_element_type})
    //     lhs_load.pointer                = lhs_pointer_id
    //     if !(lhs_load.result in ctx.load_map) {
    //         append(&ctx.operations, lhs_load)
    //         ctx.load_map[lhs_load.result] = true
    //     }
    //
    //     lhs_load_id = auto_cast(lhs_load.result)
    //     lhs_load_id = _translate_call_expression(ctx, node, lhs_element_type, lhs_load_id)

    case Binary_Expression:
        lhs_load_id, type = translate_binary_expression(ctx, root_node, node, true)

    case:
        log.error("I'm afraid this is not supported at this time.. a pity, tisn't it?")
    }

    // -----------------------------------------------------------------------------------
    // Right-Hand-Side

    rhs_node:       Identifier
    rhs_load_id:    Id
    rhs_pointer_id: Id
    // type:           string

    #partial switch node in op_node.rhs^ {
    case Thread_Idx:
        switch n in node {
        case Thread:
            rhs_value, _            := strings.replace_all(n.value, ".", "_")
            rhs_id                  := create_id({"%", rhs_value})
            rhs_max_thread_id       := translate_thread_id(ctx, node)
            rhs_load_id             = auto_cast(rhs_max_thread_id)
        case Binary_Expression:
            log.error("Not yet!") // Do we even need to handle this??
        }

    case Literal:
        type_name := translate_scalar_type(ctx, node.type)
        rhs_load_id = create_constant(ctx, type_name, node.value)
        // type = auto_cast(constant.result_type)

    case Identifier:
        rhs_node            = node
        rhs_id              := create_id({"%", rhs_node.name})
        rhs_max_thread_id   := translate_thread_id(ctx, rhs_node.thread_idx)

        #partial switch t in node.type {
        case Array_Type:
            rhs_element_type := translate_scalar_type(ctx, t.element_type)

            if rhs_id in ctx.arg_scalar_type_map {
                rhs_access_chain                : OpAccessChain
                rhs_access_chain.result         = create_result_id({string(rhs_id), "_access_chain"})
                rhs_access_chain.result_type    = auto_cast(ctx.storage_buf_ptr_map[rhs_element_type])
                rhs_access_chain.base           = rhs_id
                rhs_access_chain.indexes        = {ctx.zeroth_thread_id, rhs_max_thread_id}

                if !(rhs_access_chain.result in ctx.access_chain_map) {
                append(&ctx.operations, rhs_access_chain)
                    ctx.access_chain_map[rhs_access_chain.result] = true
                }
                rhs_pointer_id = auto_cast(rhs_access_chain.result)
            }
            else {
                rhs_pointer_id = auto_cast(ctx.variable_map[rhs_node.name])
            }

            rhs_load                        : OpLoad
            rhs_load.result                 = create_result_id({string(rhs_id), "_register"})
            rhs_load.result_type            = create_id({"%", rhs_element_type})
            rhs_load.pointer                = rhs_pointer_id
            if !(rhs_load.result in ctx.load_map) {
                append(&ctx.operations, rhs_load)
                ctx.load_map[rhs_load.result] = true
            }

            rhs_load_id = auto_cast(rhs_load.result)
            type = string(rhs_load.result_type)

        case Scalar_Type:
            rhs_element_type := translate_scalar_type(ctx, t.variant)

            if rhs_id in ctx.arg_scalar_type_map {
                rhs_access_chain                : OpAccessChain
                rhs_access_chain.result         = create_result_id({string(rhs_id), "_access_chain"})
                rhs_access_chain.result_type    = auto_cast(ctx.push_constant_ptr_map[rhs_element_type])
                rhs_access_chain.base           = rhs_id
                rhs_access_chain.indexes        = {ctx.zeroth_thread_id} // Not sure what to do here

                if !(rhs_access_chain.result in ctx.access_chain_map) {
                append(&ctx.operations, rhs_access_chain)
                    ctx.access_chain_map[rhs_access_chain.result] = true
                }
                rhs_pointer_id = auto_cast(rhs_access_chain.result)
            }
            else {
                rhs_pointer_id = auto_cast(ctx.variable_map[rhs_node.name])
            }

            rhs_load                        : OpLoad
            rhs_load.result                 = create_result_id({string(rhs_id), "_register"})
            rhs_load.result_type            = create_id({"%", rhs_element_type})
            rhs_load.pointer                = rhs_pointer_id
            if !(rhs_load.result in ctx.load_map) {
                append(&ctx.operations, rhs_load)
                ctx.load_map[rhs_load.result] = true
            }

            rhs_load_id = auto_cast(rhs_load.result)
            type = string(rhs_load.result_type)
        }

    // case Unary_Call_Expression:
    //     lhs_node = node.operand^
    //
    //     rhs_id                          := create_id({"%", rhs_node.name})
    //     rhs_max_thread_id               := translate_thread_id(ctx, rhs_node.thread_idx)
    //     // We are assuming the operand to be an array here
    //     rhs_element_type                := translate_scalar_type(ctx, rhs_node.type.(Array_Type).element_type) 
    //
    //     if rhs_id in ctx.arg_scalar_type_map {
    //         rhs_access_chain                : OpAccessChain
    //         rhs_access_chain.result         = create_result_id({string(rhs_id), "_access_chain"})
    //         rhs_access_chain.result_type    = auto_cast(ctx.storage_buf_ptr_map[rhs_element_type])
    //         rhs_access_chain.base           = rhs_id
    //         rhs_access_chain.indexes        = {ctx.zeroth_thread_id, rhs_max_thread_id}
    //
    //         if !(rhs_access_chain.result in ctx.access_chain_map) {
    //         append(&ctx.operations, rhs_access_chain)
    //             ctx.access_chain_map[rhs_access_chain.result] = true
    //         }
    //         rhs_pointer_id = auto_cast(rhs_access_chain.result)
    //     }
    //     else {
    //         rhs_pointer_id = auto_cast(ctx.variable_map[auto_cast(rhs_id)].result)
    //     }
    //
    //     rhs_load                        : OpLoad
    //     rhs_load.result                 = create_result_id({string(rhs_id), "_register"})
    //     rhs_load.result_type            = create_id({"%", rhs_element_type})
    //     rhs_load.pointer                = rhs_pointer_id
    //     if !(rhs_load.result in ctx.load_map) {
    //         append(&ctx.operations, rhs_load)
    //         ctx.load_map[rhs_load.result] = true
    //     }
    //
    //     rhs_load_id = auto_cast(rhs_load.result)
    //     rhs_load_id = _translate_call_expression(ctx, node, rhs_element_type, rhs_load_id)
    //     type = string(rhs_load.result_type)

    case Binary_Expression:
        rhs_load_id, type = translate_binary_expression(ctx, root_node, node, true)

    case:
        log.error("I'm afraid this is not supported at this time.. a pity, tisn't it?")
    }

    // -----------------------------------------------------------------------------------
    // Operation

    // Need to assert that the type of lhs and rhs is the same
    result  := translate_binary_op(ctx, op_node, type, lhs_load_id, rhs_load_id)

    // -----------------------------------------------------------------------------------
    // Result

    if !(is_subexpr) {
        #partial switch n in root_node {
        case Variable_Expression:

            result_name_id                  := create_id({"%", n.name})
            result_max_thread_id            := translate_thread_id(ctx, n.thread_idx)
            result_element_type             := ctx.arg_scalar_type_map[result_name_id]
            result_pointer_id               : Id

            if result_name_id in ctx.arg_scalar_type_map {
                result_access_chain             : OpAccessChain
                result_access_chain.result      = create_result_id({string(result_name_id), "_access_chain"})
                result_access_chain.result_type = auto_cast(ctx.storage_buf_ptr_map[result_element_type])
                result_access_chain.base        = result_name_id
                result_access_chain.indexes     = {ctx.zeroth_thread_id, result_max_thread_id}

                if !(result_access_chain.result in ctx.access_chain_map) {
                append(&ctx.operations, result_access_chain)
                    ctx.access_chain_map[result_access_chain.result] = true
                }

                result_pointer_id = auto_cast(result_access_chain.result)
            }
            else {
                result_pointer_id = auto_cast(ctx.variable_map[n.name])
            }

            store                           : OpStore
            store.pointer                   = result_pointer_id
            store.object                    = auto_cast(result)
            append(&ctx.operations, store)
        }
    }
    else {
       return auto_cast(result), type
    }
    return
}


// translate_unary_call_expression :: proc(ctx: ^Ctx, root_node: Variable_Expression, expr_node: Unary_Call_Expression) {
//     // -----------------------------------------------------------------------------------
//     // Operand
//     operand_node                        := expr_node.operand
//     operand_id                          := create_id({"%", operand_node.name})
//     operand_max_thread_id               := translate_thread_id(ctx, operand_node.thread_idx)
//     operand_element_type                := ctx.scalar_type_map[operand_node.type.(Array_Type).element_type] // Assuming that the operand is an array
//     operand_pointer_id                  : Id
//     operand_load_id                     : Id
//
//     if operand_id in ctx.arg_scalar_type_map { // A bit of a hacky way to see if we need an access chain
//         operand_access_chain                : OpAccessChain
//         operand_access_chain.result         = create_result_id({string(operand_id), "_access_chain"})
//         operand_access_chain.result_type    = auto_cast(ctx.storage_buf_ptr_map[operand_element_type[1:]])
//         operand_access_chain.base           = operand_id
//         operand_access_chain.indexes        = {ctx.zeroth_thread_id, operand_max_thread_id}
//
//         if !(operand_access_chain.result in ctx.access_chain_map) {
//         append(&ctx.operations, operand_access_chain)
//             ctx.access_chain_map[operand_access_chain.result] = true
//         }
//         operand_pointer_id = auto_cast(operand_access_chain.result)
//     }
//     else {
//         operand_pointer_id = auto_cast(ctx.variable_map[auto_cast(operand_id)].result)
//     }
//
//     operand_load                        : OpLoad
//     operand_load.result                 = create_result_id({string(operand_id), "_register"})
//     operand_load.result_type            = auto_cast(operand_element_type)
//     operand_load.pointer                = operand_pointer_id
//     append(&ctx.operations, operand_load)
//
//     operand_load_id = auto_cast(operand_load.result)
//
//     // -----------------------------------------------------------------------------------
//     // Function
//     function                        : OpExtInst
//     function.result                 = create_result_id({expr_node.callee, "_of_", string(operand_load_id)[1:]})
//     function.result_type            = auto_cast(operand_element_type)
//     function.Instruction            = .Exp
//     function.Set                    = auto_cast(ctx.extensions[0].result) // GLSL will always be the first extension imported (for now lol)
//     function.operands               = {operand_load_id}
//     append(&ctx.operations, function)
//
//     // -----------------------------------------------------------------------------------
//     // Result
//     result_name_id                  := create_id({"%", root_node.name})
//     result_max_thread_id            := translate_thread_id(ctx, root_node.thread_idx)
//     result_element_type             := ctx.scalar_type_map[root_node.type.(Array_Type).element_type] // Assuming that the operand is an array
//     result_pointer_id               : Id
//
//     if result_name_id in ctx.arg_scalar_type_map { // A bit of a hacky way to see if we need an access chain
//         result_access_chain             : OpAccessChain
//         result_access_chain.result      = create_result_id({string(result_name_id), "_access_chain"})
//         result_access_chain.result_type = auto_cast(ctx.storage_buf_ptr_map[result_element_type[1:]])
//         result_access_chain.base        = result_name_id
//         result_access_chain.indexes     = {ctx.zeroth_thread_id, result_max_thread_id}
//
//         if !(result_access_chain.result in ctx.access_chain_map) {
//         append(&ctx.operations, result_access_chain)
//             ctx.access_chain_map[result_access_chain.result] = true
//         }
//
//         result_pointer_id = auto_cast(result_access_chain.result)
//     }
//     else {
//         result_pointer_id = auto_cast(ctx.variable_map[auto_cast(result_name_id)].result)
//     }
//     
//     store                           : OpStore
//     store.pointer                   = result_pointer_id
//     store.object                    = auto_cast(function.result)
//     append(&ctx.operations, store)
//         
// }
//
// // Need to update this (or better yet get rid of it!)
// _translate_unary_call_expression :: proc(ctx: ^Ctx, node: Unary_Call_Expression, operand_element_type: string, operand_load_id: Id) -> (result_id: Id) {
//     function: OpExtInst
//     function.result = auto_cast(node.callee)
//     function.result_type = create_id({"%", string(operand_element_type)})
//     function.Instruction = .Exp
//     function.Set = auto_cast(ctx.extensions[0].result)
//     function.operands = {operand_load_id}
//     append(&ctx.operations, function)
//     result_id = auto_cast(function.result)
//     return
// }


translate_binary_op :: proc(ctx: ^Ctx, node: saga.Binary_Expression, type: string, lhs_load_id, rhs_load_id: Id) -> (result: Result_Id) {
    ctx.binary_op_counter += 1
    switch type {
    case "%int8", "%int16", "%int32", "%int64":
        switch node.op {
        case "+":
            op: OpIAdd
            op.result = create_result_id({"%sum_of_", string(lhs_load_id[1:]), string(rhs_load_id[1:])}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "-":
            op: OpISub
            op.result = create_result_id({"%difference_", fmt.tprint(ctx.binary_op_counter)}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "*":
            op: OpIMul
            op.result = create_result_id({"%product_of_", string(lhs_load_id[1:]), string(rhs_load_id[1:])}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "/":
            op: OpSDiv
            op.result = create_result_id({"%quotient_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "%":
            op: OpSMod
            op.result = create_result_id({"%modulo_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "%%":
            op: OpSRem
            op.result = create_result_id({"%remainder_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "<":
            op: OpSLessThan
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "<=":
            op: OpSLessThanEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case ">":
            op: OpSGreaterThan
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case ">=":
            op: OpSGreaterThanEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "==":
            op: OpIEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "!=":
            op: OpINotEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        }

    case "%uint8", "%uint16", "%uint32", "%uint64":
        switch node.op {
        case "+":
            op: OpIAdd
            op.result = create_result_id({"%sum_", fmt.tprint(ctx.binary_op_counter)}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "-":
            op: OpISub
            op.result = create_result_id({"%difference_", fmt.tprint(ctx.binary_op_counter)}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "*":
            op: OpIMul
            op.result = create_result_id({"%product_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "/":
            op: OpUDiv
            op.result = create_result_id({"%quotient_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "%":
            op: OpUMod
            op.result = create_result_id({"%modulo_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "<":
            op: OpULessThan
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "<=":
            op: OpULessThanEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case ">":
            op: OpUGreaterThan
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case ">=":
            op: OpUGreaterThanEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "==":
            op: OpIEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "!=":
            op: OpINotEqual
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        }
    case "%float16", "%float32", "%float64", "float128":
        switch node.op {
        case "+":
            op: OpFAdd
            op.result = create_result_id({"%sum_", fmt.tprint(ctx.binary_op_counter)}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "-":
            op: OpFSub
            op.result = create_result_id({"%difference_", fmt.tprint(ctx.binary_op_counter)}) // lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "*":
            op: OpFMul
            op.result = create_result_id({"%product_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "/":
            op: OpFDiv
            op.result = create_result_id({"%quotient_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "%":
            op: OpFMod
            op.result = create_result_id({"%modulo_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "%%":
            op: OpFRem
            op.result = create_result_id({"%remainder_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.operations, op)
            result = op.result
        case "<":
            op: OpFOrdLessThan // Not handling ordered vs unordered atm
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "<=":
            op: OpFOrdLessThanEqual // Not handling ordered vs unordered atm
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case ">":
            op: OpFOrdGreaterThan // Not handling ordered vs unordered atm
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case ">=":
            op: OpFOrdGreaterThanEqual // Not handling ordered vs unordered atm
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "==":
            op: OpFOrdEqual // Not handling ordered vs unordered atm
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        case "!=":
            op: OpFOrdNotEqual // Not handling ordered vs unordered atm
            op.result = create_result_id({"%condition_", fmt.tprint(ctx.binary_op_counter)}) //lol
            op.result_type = auto_cast("%bool")
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            translate_scalar_type(ctx, "bool")
            append(&ctx.operations, op)
            result = op.result
        }
    case:
        log.error("Didn't work!")
    }
    return
}


translate_scalar_type :: proc(ctx: ^Ctx, t: string) -> (type_name: string) {
    if t in ctx.scalar_type_map { 
        type_name = ctx.scalar_type_map[t][1:] 
        return
    }
    else {
        switch t {
        case "bool": 
            type            : OpTypeBool
            type.result     = create_result_id({"%", "bool"})
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i8": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int8"})
            type.width      = 8
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i16": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int16"})
            type.width      = 16
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i32": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int32"})
            type.width      = 32
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i64": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int64"})
            type.width      = 64
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u8": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint8"})
            type.width      = 8
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u16": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint16"})
            type.width      = 16
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u32": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint32"})
            type.width      = 32
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u64": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint64"})
            type.width      = 64
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        // Not handling FP Encoding for OpTypeFloat quite yet
        case "f16": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float16"})
            type.width      = 16
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "f32": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float32"})
            type.width      = 32
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "f64": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float64"})
            type.width      = 64
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "f128": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float128"})
            type.width      = 128
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        }
        return
    }
}


translate_thread_id :: proc(ctx: ^Ctx, thread_id: saga.Thread_Idx) -> (max_thread_id: Id){
    switch t in thread_id {
    case Thread:
        if t.value in ctx.thread_id_map {
            max_thread_id = auto_cast(ctx.thread_id_map[t.value])
            return
        }
        switch t.value {
        case "thread_idx.x", "thread.x":
            composite_extract               : OpCompositeExtract
            composite_extract.result        = auto_cast("%max_thread_id_x")
            composite_extract.result_type   = auto_cast("%uint32")
            composite_extract.composite     = auto_cast("%layout_ptr")
            composite_extract.indexes       = {0}
            max_thread_id = auto_cast(composite_extract.result)
            ctx.thread_id_map["thread_idx.x"] = auto_cast(composite_extract.result)
            ctx.thread_id_map["thread.x"] = auto_cast(composite_extract.result) // Should probably just pick one
            append(&ctx.composites, composite_extract)
        case "thread_idx.y", "thread.y":
            composite_extract               : OpCompositeExtract
            composite_extract.result        = auto_cast("%max_thread_id_y")
            composite_extract.result_type   = auto_cast("%uint32")
            composite_extract.composite     = auto_cast("%layout_ptr")
            composite_extract.indexes       = {1}
            max_thread_id = auto_cast(composite_extract.result)
            ctx.thread_id_map["thread_idx.y"] = auto_cast(composite_extract.result)
            ctx.thread_id_map["thread.y"] = auto_cast(composite_extract.result)
            append(&ctx.composites, composite_extract)
        case "thread_idx.z", "thread.z":
            composite_extract               : OpCompositeExtract
            composite_extract.result        = auto_cast("%max_thread_id_z")
            composite_extract.result_type   = auto_cast("%uint32")
            composite_extract.composite     = auto_cast("%layout_ptr")
            composite_extract.indexes       = {2}
            max_thread_id = auto_cast(composite_extract.result)
            ctx.thread_id_map["thread_idx.z"] = auto_cast(composite_extract.result)
            ctx.thread_id_map["thread.y"] = auto_cast(composite_extract.result)
            append(&ctx.composites, composite_extract)
        case: // Should probably offload this to the parser
            if t.value in ctx.variable_map {
                max_thread_id = create_id({"%", t.value, "_register"}) // This may cause some problems...
            }
            else {log.error("Not found!")}
        }
    case Binary_Expression:
        max_thread_id, _ = translate_binary_expression(ctx, Expression{}, t, true) // Not actually a subexpr but life is hard
    }
    return
}


parse_node :: proc(ctx: ^Ctx, node: saga.AST_Node) {
    #partial switch n in node {
    case Module:
        translate_module(ctx, n)
    case Layout:
        translate_layout(ctx, n)
    case Kernel:
        translate_kernel(ctx, n)
    case:
        fmt.println()
    }
}

// Desparately out of date
walk_ast :: proc(ast: [dynamic]saga.AST_Node) {
    ctx: Ctx
    for node in ast do parse_node(&ctx, node)
    fmt.println()
    fmt.printf("%v\n", ctx.capability)
    fmt.printf("%v\n", ctx.memory_model)
    fmt.printf("%v\n", ctx.entry_point)
    fmt.printf("%v\n", ctx.execution_mode)
    fmt.println()
    for extension in ctx.extensions do fmt.printf("%v\n", extension)
    fmt.println()
    for annotaton in ctx.annotations do fmt.printf("%v\n", annotaton)
    fmt.println()
    for type in ctx.types do fmt.printf("%v\n", type)
    fmt.println()
    for const in ctx.constants do fmt.printf("%v\n", const)
    fmt.println()
    for var in ctx.variables do fmt.printf("%v\n", var)
    fmt.println()
    fmt.printf("%v\n", ctx.kernel_function)
    fmt.println()
    fmt.printf("%v\n", ctx.kernel_body_label)
    fmt.println()
    fmt.printf("%v\n", ctx.loads[0]) // Will always be the thread_id?
    fmt.println()
    for comp in ctx.composites do fmt.printf("%v\n", comp)
    fmt.println()
    for chain in ctx.access_chains do fmt.printf("%v\n", chain)
    fmt.println()
    for load in ctx.loads[1:] do fmt.printf("%v\n", load)
    fmt.println()
    for op in ctx.operations do fmt.printf("%v\n", op)
    fmt.println()
    for store in ctx.stores do fmt.printf("%v\n", store)
    fmt.println()
    fmt.printf("%v\n", ctx.kernel_return)
    fmt.printf("%v\n", ctx.kernel_function_end)
}

clean_context :: proc(ctx: ^Ctx) {
    for type in ctx.types {
        #partial switch t in type {
        case OpTypeVoid:
            if t.result == "%float" do fmt.printf("%v\n", type)
        }
    }
}

