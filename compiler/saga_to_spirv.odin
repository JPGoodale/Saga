package saga_compiler
import "core:fmt"
import "core:log"
import "core:strings"
import "core:strconv"


Ctx :: struct {
    module_name:            string,
    capability:             OpCapability,
    memory_model:           OpMemoryModel,
    execution_mode:         OpExecutionMode,
    entry_point:            OpEntryPoint,
    kernel_function:        OpFunction,
    kernel_body_label:      OpLabel,
    kernel_return:          OpReturn, // Here just for pedantic purposes
    kernel_function_end:    OpFunctionEnd, // ^ What he said..
    annotations:            [dynamic]OpAnnotation,
    scalar_types:           [dynamic]OpType,
    types:                  [dynamic]OpType,
    constants:              [dynamic]OpConstant,
    variables:              [dynamic]OpVariable,
    loads:                  [dynamic]OpLoad,
    stores:                 [dynamic]OpStore,
    composites:             [dynamic]OpComposite,
    access_chains:          [dynamic]OpAccessChain,
    binary_ops:             [dynamic]OpBinaryExpr,
    arg_name_ids:           [dynamic]Id,
    storage_buffer_ids:     [dynamic]Id,
    arg_scalar_type_map:   map[Id]string,
    thread_id_map:          map[string]string,
    scalar_type_map:        map[string]string,
    register_ptr_map:       map[string]string,
    runtime_array_map:      map[string]string,
    array_map:              map[string]string,
    zeroth_thread_id:       Id,
    max_thread_id:          Id,
}


create_id :: proc(names: []string) -> (id: Id) {
    id = Id(strings.join(names, ""))
    return
}


create_result_id :: proc(names: []string) -> (result_id: Result_Id) {
    result_id = Result_Id(strings.join(names, ""))
    return
}


set_capability :: proc(ctx: ^Ctx) {
    capability              : OpCapability
    capability.capability   = .Shader
    ctx.capability = capability
}


set_memory_model :: proc(ctx: ^Ctx) {
    memory_model                    : OpMemoryModel
    memory_model.addressing_model   = .Logical
    memory_model.memory_model       = .GLSL450
    ctx.memory_model = memory_model
}


translate_module :: proc(ctx: ^Ctx, node: Module) {
    set_capability(ctx)
    set_memory_model(ctx)
    ctx.module_name = node.name
}


translate_layout :: proc(ctx: ^Ctx, node: Layout) {
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
    uint.result                     = auto_cast("%uint")
    uint.width                      = 32
    uint.signedness                 = 0
    append(&ctx.scalar_types, uint)
    ctx.scalar_type_map["u32"] = "%uint"

    uint_vec3                       : OpTypeVector
    uint_vec3.result                = auto_cast("%v3uint")
    uint_vec3.component_type        = auto_cast("%uint")
    uint_vec3.component_count       = 3
    append(&ctx.types, uint_vec3)

    uint_vec3_ptr                   : OpTypePointer
    uint_vec3_ptr.result            = auto_cast("%_ptr_Input_v3uint")
    uint_vec3_ptr.type              = auto_cast("%v3uint")
    uint_vec3_ptr.storage_class     = .Input
    append(&ctx.types, uint_vec3_ptr)

    variable                        : OpVariable
    variable.result                 = auto_cast("%gl_GlobalInvocationID")
    variable.result_type            = auto_cast("%_ptr_Input_v3uint")
    variable.storage_class          = .Input
    append(&ctx.variables, variable)

    constant                        : OpConstant
    constant.result                 = auto_cast("%zeroth_thread_id")
    constant.result_type            = auto_cast("%uint")
    constant.value                  = u64(0)
    append(&ctx.constants, constant)
    ctx.zeroth_thread_id = auto_cast(constant.result)

    load                            : OpLoad
    load.result                     = auto_cast("%layout_ptr")
    load.result_type                = auto_cast("%v3uint")
    load.pointer                    = auto_cast("%gl_GlobalInvocationID")
    append(&ctx.loads, load)
}


translate_kernel :: proc(ctx: ^Ctx, node: Kernel) {
    translate_kernel_signature(ctx, node.signature)
    translate_kernel_body(ctx, node.body)
}


translate_kernel_signature :: proc(ctx: ^Ctx, node: Kernel_Signature) {
    entry_point                         : OpEntryPoint
    entry_point.execution_model         = .GLCompute
    entry_point.entry_point             = create_id({"%", node.name})
    entry_point.name                    = node.name
    entry_point.interfaces              = {auto_cast("%gl_GlobalInvocationID")}
    ctx.entry_point = entry_point
    ctx.execution_mode.entry_point = ctx.entry_point.entry_point

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


translate_kernel_args :: proc(ctx: ^Ctx, nodes: [dynamic]Argument) {
    for node, idx in nodes {
        switch n in node {
        case Array_Argument:
            arg_name_id := create_id({"%", n.name})
            append(&ctx.arg_name_ids, arg_name_id)

            element_type_name := translate_scalar_type(ctx, n.type.element_type)
            ctx.arg_scalar_type_map[arg_name_id] = element_type_name

            storage_buffer_id := translate_array_type(ctx, n.type, element_type_name)
            append(&ctx.storage_buffer_ids, storage_buffer_id)

            decorate                        : OpDecorate
            decorate.target                 = create_id({"%", n.name})
            decorate.decoration             = .DescriptorSet
            decorate.decoration_operands    = {0}
            append(&ctx.annotations, decorate)

            decorate.target                 = create_id({"%", n.name})
            decorate.decoration             = .Binding
            decorate.decoration_operands    = {idx}
            append(&ctx.annotations, decorate)

            variable                        : OpVariable
            variable.result                 = create_result_id({"%", n.name})
            variable.result_type            = storage_buffer_id
            variable.storage_class          = .StorageBuffer
            append(&ctx.variables, variable)
        
        case Scalar_Argument:
            arg_name_id := create_id({"%", n.name})
            append(&ctx.arg_name_ids, arg_name_id)

            type_name := translate_scalar_type(ctx, n.type.variant)
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

            pointer.result                      = create_result_id({"%_ptr_", type_name, "_push_constant"})
            pointer.storage_class               = .PushConstant
            pointer.type                        = create_id({"%", type_name})
            append(&ctx.types, pointer)

            access_chain                        : OpAccessChain
            access_chain.result                 = create_result_id({"%", n.name, "_access_chain"})
            access_chain.result_type            = auto_cast(pointer.result)
            access_chain.base                   = arg_name_id
            access_chain.indexes                = {ctx.zeroth_thread_id} // Not sure what to do here
            append(&ctx.access_chains, access_chain)
        } 
    }
}


translate_array_type :: proc(ctx: ^Ctx, node: Array_Type, element_type_name: string) -> (storage_buffer_id: Id) {
    if !(element_type_name in ctx.register_ptr_map) {
        pointer                                     : OpTypePointer
        pointer.result                              = create_result_id({"%_ptr_StorageBuffer_", element_type_name})
        pointer.storage_class                       = .StorageBuffer
        pointer.type                                = create_id({"%", element_type_name})
        append(&ctx.types, pointer)
        ctx.register_ptr_map[element_type_name] = auto_cast(pointer.result)
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
        constant                                    : OpConstant
        constant.result                             = create_result_id({"%uint_", node.n_elements})
        constant.result_type                        = auto_cast("%uint")
        constant.value                              = strconv.atoi(node.n_elements)
        append(&ctx.constants, constant)

        array                                       : OpTypeArray
        array.result                                = create_result_id({"%_array_", element_type_name})
        array.element_type                          = create_id({"%", element_type_name})
        array.length                                = auto_cast(constant.result)
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
            type.result     = create_result_id({"%", "int"})
            type.width      = 8
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i16": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int"})
            type.width      = 16
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i32": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int"})
            type.width      = 32
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "i64": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "int"})
            type.width      = 64
            type.signedness = 1
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u8": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint"})
            type.width      = 8
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u16": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint"})
            type.width      = 16
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u32": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint"})
            type.width      = 32
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "u64": 
            type            : OpTypeInt
            type.result     = create_result_id({"%", "uint"})
            type.width      = 64
            type.signedness = 0
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        // Not handling FP Encoding for OpTypeFloat quite yet
        case "f16": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float"})
            type.width      = 16
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "f32": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float"})
            type.width      = 32
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "f64": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float"})
            type.width      = 64
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        case "f128": 
            type            : OpTypeFloat
            type.result     = create_result_id({"%", "float"})
            type.width      = 128
            type_name       = auto_cast(type.result[1:])
            ctx.scalar_type_map[t] = auto_cast(type.result)
            append(&ctx.scalar_types, type)
        }
        return
    }
}


translate_kernel_body :: proc(ctx: ^Ctx, nodes: [dynamic]Expression) {
    block_label         : OpLabel
    block_label.result  = auto_cast("%body")
    ctx.kernel_body_label = block_label

    for node in nodes {
        #partial switch n in node {
        case Variable_Expression:
            #partial switch e in n.value {
            case Binary_Expression:
                translate_binary_op(ctx, n, e) 
            case:
                fmt.println(n)
                log.error("I'm afraid only binary expressions are supported at this time.. a pity, tisn't it?")
            }
        case:
            fmt.println(n)
            log.error("I'm afraid only variable expressions are supported at this time.. a pity, tisn't it?")
        }
    }
}

// Only works on kernel args as of now
translate_binary_op :: proc(ctx: ^Ctx, root_node: Variable_Expression, op_node: Binary_Expression) {
    lhs_id              := create_id({"%", op_node.lhs.value})
    rhs_id              := create_id({"%", op_node.rhs.value})

    lhs_max_thread_id   := translate_thread_id(ctx, op_node.lhs.thread_id)
    rhs_max_thread_id   := translate_thread_id(ctx, op_node.rhs.thread_id)

    lhs_element_type    := ctx.arg_scalar_type_map[lhs_id]
    rhs_element_type    := ctx.arg_scalar_type_map[rhs_id]
    assert(lhs_element_type == rhs_element_type)

    lhs_access_chain                : OpAccessChain
    lhs_access_chain.result         = create_result_id({string(lhs_id), "_access_chain"})
    lhs_access_chain.result_type    = auto_cast(ctx.register_ptr_map[lhs_element_type])
    lhs_access_chain.base           = lhs_id
    lhs_access_chain.indexes        = {ctx.zeroth_thread_id, lhs_max_thread_id}
    append(&ctx.access_chains, lhs_access_chain)

    rhs_access_chain                : OpAccessChain
    rhs_access_chain.result         = create_result_id({string(rhs_id), "_access_chain"})
    rhs_access_chain.result_type    = auto_cast(ctx.register_ptr_map[rhs_element_type])
    rhs_access_chain.base           = rhs_id
    rhs_access_chain.indexes        = {ctx.zeroth_thread_id, rhs_max_thread_id}
    append(&ctx.access_chains, rhs_access_chain)

    lhs_load                        : OpLoad
    lhs_load.result                 = auto_cast("%lhs_register")
    lhs_load.result_type            = create_id({"%", lhs_element_type})
    lhs_load.pointer                = auto_cast(lhs_access_chain.result)
    append(&ctx.loads, lhs_load)

    rhs_load                        : OpLoad
    rhs_load.result                 = auto_cast("%rhs_register")
    rhs_load.result_type            = create_id({"%", rhs_element_type})
    rhs_load.pointer                = auto_cast(rhs_access_chain.result)
    append(&ctx.loads, rhs_load)

    lhs_load_id: Id = auto_cast(lhs_load.result)
    rhs_load_id: Id = auto_cast(rhs_load.result)

    result: Result_Id
    type := string(lhs_load.result_type)
    switch type {
    case "%int":
        switch op_node.op {
        case "+":
            op: OpIAdd
            op.result = auto_cast("%sum")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "-":
            op: OpISub
            op.result = auto_cast("%difference")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "*":
            op: OpIMul
            op.result = auto_cast("%product")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "/":
            op: OpSDiv
            op.result = auto_cast("%quotient")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        }

    case "%uint":
        switch op_node.op {
        case "+":
            op: OpIAdd
            op.result = auto_cast("%sum")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "-":
            op: OpISub
            op.result = auto_cast("%difference")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "*":
            op: OpIMul
            op.result = auto_cast("%product")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "/":
            op: OpUDiv
            op.result = auto_cast("%quotient")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        }
    case "%float":
        switch op_node.op {
        case "+":
            op: OpFAdd
            op.result = auto_cast("%sum")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "-":
            op: OpFSub
            op.result = auto_cast("%difference")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "*":
            op: OpFMul
            op.result = auto_cast("%product")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        case "/":
            op: OpFDiv
            op.result = auto_cast("%quotient")
            op.result_type = auto_cast(type)
            op.operand_1 = lhs_load_id
            op.operand_2 = rhs_load_id
            append(&ctx.binary_ops, op)
            result = op.result
        }
    }

    result_name_id                  := create_id({"%", root_node.name})
    result_max_thread_id            := translate_thread_id(ctx, root_node.thread_id)
    result_element_type             := ctx.arg_scalar_type_map[result_name_id]

    result_access_chain             : OpAccessChain
    result_access_chain.result      = create_result_id({string(result_name_id), "_access_chain"})
    result_access_chain.result_type = auto_cast(ctx.register_ptr_map[result_element_type])
    result_access_chain.base        = result_name_id
    result_access_chain.indexes     = {ctx.zeroth_thread_id, result_max_thread_id}
    append(&ctx.access_chains, result_access_chain)
    
    store: OpStore
    store.pointer = auto_cast(result_access_chain.result)
    store.object = auto_cast(result)
    append(&ctx.stores, store)
}

// TODO: Handle more cases
translate_thread_id :: proc(ctx: ^Ctx, thread_id: string) -> (max_thread_id: Id){
    if thread_id in ctx.thread_id_map {
        max_thread_id = auto_cast(ctx.thread_id_map[thread_id])
        return
    }
    switch thread_id {
    case "tid.x":
        composite_extract               : OpCompositeExtract
        composite_extract.result        = auto_cast("%max_thread_id_x")
        composite_extract.result_type   = auto_cast("%uint")
        composite_extract.composite     = auto_cast("%layout_ptr")
        composite_extract.indexes       = {0}
        max_thread_id = auto_cast(composite_extract.result)
        ctx.thread_id_map["tid.x"] = auto_cast(composite_extract.result)
        append(&ctx.composites, composite_extract)
    case "tid.y":
        composite_extract               : OpCompositeExtract
        composite_extract.result        = auto_cast("%max_thread_id_y")
        composite_extract.result_type   = auto_cast("%uint")
        composite_extract.composite     = auto_cast("%layout_ptr")
        composite_extract.indexes       = {1}
        max_thread_id = auto_cast(composite_extract.result)
        ctx.thread_id_map["tid.y"] = auto_cast(composite_extract.result)
        append(&ctx.composites, composite_extract)
    case "tid.z":
        composite_extract               : OpCompositeExtract
        composite_extract.result        = auto_cast("%max_thread_id_z")
        composite_extract.result_type   = auto_cast("%uint")
        composite_extract.composite     = auto_cast("%layout_ptr")
        composite_extract.indexes       = {2}
        max_thread_id = auto_cast(composite_extract.result)
        ctx.thread_id_map["tid.z"] = auto_cast(composite_extract.result)
        append(&ctx.composites, composite_extract)
    }
    return
}


parse_node :: proc(ctx: ^Ctx, node: AST_Node) {
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


walk_ast :: proc(ast: [dynamic]AST_Node) {
    ctx: Ctx
    for node in ast do parse_node(&ctx, node)
    fmt.println()
    fmt.printf("%v\n", ctx.capability)
    fmt.printf("%v\n", ctx.memory_model)
    fmt.printf("%v\n", ctx.entry_point)
    fmt.printf("%v\n", ctx.execution_mode)
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
    for op in ctx.binary_ops do fmt.printf("%v\n", op)
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

