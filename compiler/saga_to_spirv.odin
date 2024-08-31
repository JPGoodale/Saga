package saga_compiler
import "core:fmt"
import "core:log"
import "core:strings"


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
    types:                  [dynamic]OpType,
    constants:              [dynamic]OpConstant,
    variables:              [dynamic]OpVariable,
    loads:                  [dynamic]OpLoad,
    stores:                 [dynamic]OpStore,
    composites:             [dynamic]OpComposite,
    access_chains:          [dynamic]OpAccessChain,
    binary_ops:             [dynamic]OpBinaryExpr,
    arg_name_ids:           [dynamic]Id,
    access_chain_map:       map[Id]Id,
    buffer_scalar_type_id:  Id,       
    buffer_ptr_type_id:     Id,
    buffer_storage_class:   Storage_Class,
    register_ptr_id:        Id,
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
    execution_mode.entry_point      = auto_cast("%main")
    execution_mode.mode             = .LocalSize
    execution_mode.mode_operands    = {node.x, node.y, node.z}
    ctx.execution_mode = execution_mode

    decorate                        : OpDecorate
    decorate.target                 = auto_cast("%gl_GlobalInvocationID")
    decorate.decoration             = .BuiltIn
    decorate.decoration_operands    = {Builtin.GlobalInvocationId}
    append(&ctx.annotations, decorate)

    // decorate                        : OpDecorate
    // decorate.target                 = auto_cast("%gl_LocalInvocationID")
    // decorate.decoration             = .BuiltIn
    // decorate.decoration_operands    = {Builtin.LocalInvocationId}
    // append(&ctx.annotations, decorate)

    uint                            : OpTypeInt
    uint.result                     = auto_cast("%uint")
    uint.width                      = 32
    uint.signedness                 = 0
    append(&ctx.types, uint)

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

    load                            : OpLoad
    load.result                     = auto_cast("%layout_ptr")
    load.result_type                = uint_vec3_ptr.type
    load.pointer                    = auto_cast(variable.result)
    append(&ctx.loads, load)

    composite_extract               : OpCompositeExtract
    composite_extract.result        = auto_cast("%max_thread_id")
    composite_extract.result_type   = uint_vec3.component_type
    composite_extract.composite     = auto_cast(load.result)
    composite_extract.indexes       = {0}
    append(&ctx.composites, composite_extract)
    ctx.max_thread_id = auto_cast(composite_extract.result)
}


translate_kernel :: proc(ctx: ^Ctx, node: Kernel) {
    translate_kernel_signature(ctx, node.signature)
    translate_kernel_body(ctx, node.body)
}


translate_kernel_signature :: proc(ctx: ^Ctx, node: Kernel_Signature) {
    entry_point                         : OpEntryPoint
    entry_point.execution_model         = .GLCompute
    entry_point.entry_point             = create_id({"%", node.name}) // A bit inconsistant with us setting it to %main automatically above
    entry_point.name                    = node.name
    entry_point.interfaces              = {auto_cast("%gl_GlobalInvocationID")}
    ctx.entry_point = entry_point


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
    existing_array_types := make(map[Array_Type]bool)
    for node, idx in nodes {
        switch n in node {
        case Array_Argument:
            // This is... weird...
            if idx == 0 {
                translate_array_type(ctx, n.type)
                existing_array_types[n.type] = true
            }
            if idx > 0 && !(n.type in existing_array_types) {
                translate_array_type(ctx, n.type)
                existing_array_types[n.type] = true
            }

            arg_name_id := create_id({"%", n.name})
            append(&ctx.arg_name_ids, arg_name_id)

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
            variable.result_type            = ctx.buffer_ptr_type_id
            variable.storage_class          = ctx.buffer_storage_class
            append(&ctx.variables, variable)

            access_chain                    : OpAccessChain
            access_chain.result             = create_result_id({"%", n.name, "_access_chain"})
            access_chain.result_type        = ctx.register_ptr_id
            access_chain.base               = create_id({"%", n.name})
            access_chain.indexes            = {ctx.zeroth_thread_id, ctx.max_thread_id}
            append(&ctx.access_chains, access_chain)

            ctx.access_chain_map[arg_name_id] = auto_cast(access_chain.result)
        
        // This needs to be much more robust / it currently assumes that it's a uint
        case Scalar_Argument:
            arg_name_id := create_id({"%", n.name})
            append(&ctx.arg_name_ids, arg_name_id)

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
            structure.members                   = {auto_cast("%uint")} // This needs to be more dynamic
            append(&ctx.types, structure)
            
            pointer                             : OpTypePointer
            pointer.result                      = auto_cast("%_ptr_push_constant")
            pointer.storage_class               = .PushConstant
            pointer.type                        = auto_cast("%push_constant")
            append(&ctx.types, pointer)

            variable                            : OpVariable
            variable.result                     = create_result_id({"%", n.name})
            variable.result_type                = auto_cast("%_ptr_push_constant")
            variable.storage_class              = .PushConstant
            append(&ctx.variables, variable)

            // Hard coding uint for now
            pointer.result                      = auto_cast("%_ptr_uint_push_constant")
            pointer.storage_class               = .PushConstant
            pointer.type                        = auto_cast("%uint")
            append(&ctx.types, pointer)

            access_chain                        : OpAccessChain
            access_chain.result                 = create_result_id({"%", n.name, "_access_chain"})
            access_chain.result_type            = auto_cast("%_ptr_uint_push_constant")
            access_chain.base                   = create_id({"%", n.name})
            access_chain.indexes                = {ctx.zeroth_thread_id} // Not sure what to do here
            append(&ctx.access_chains, access_chain)

            ctx.access_chain_map[arg_name_id] = auto_cast(access_chain.result)
        } 
    }
}


// For now we are just using the runtimearray structured buffer uniform ptr (phew!) 
// conversion method, definitely feel like we are overfitting here...
// Also we need to handle the names smoother, this looks pretty yucky
translate_array_type :: proc(ctx: ^Ctx, node: Array_Type) {
    translate_scalar_type(ctx, node.element_type)
    scalar_type_name := string(ctx.buffer_scalar_type_id)[1:]

    constant                                    : OpConstant
    constant.result                             = auto_cast("%zeroth_thread_id")
    constant.result_type                        = auto_cast("%uint")
    constant.value                              = u32(0)
    append(&ctx.constants, constant)
    ctx.zeroth_thread_id = auto_cast(constant.result)

    pointer                                     : OpTypePointer
    pointer.result                              = create_result_id({"%_ptr_Uniform_", scalar_type_name})
    pointer.storage_class                       = .Uniform
    pointer.type                                = ctx.buffer_scalar_type_id
    append(&ctx.types, pointer)
    ctx.register_ptr_id = auto_cast(pointer.result)
    
    runtime_array                               : OpTypeRuntimeArray
    runtime_array.result                        = create_result_id({"%_runtimearray_", scalar_type_name})
    runtime_array.element_type                  = create_id({"%", scalar_type_name})
    append(&ctx.types, runtime_array)

    structured_buffer                           : OpTypeStruct
    structured_buffer.result                    = create_result_id({"%type_RWStructured_buffer_", scalar_type_name})
    structured_buffer.members                   = {create_id({"%_runtimearray_", scalar_type_name})}
    append(&ctx.types, structured_buffer)

    struct_pointer                              : OpTypePointer
    struct_pointer.result                       = create_result_id({"%_ptr_Uniform_type_RWStructuredBuffer_", scalar_type_name})
    struct_pointer.storage_class                = .Uniform
    struct_pointer.type                         = create_id({"%type_RWStructured_buffer_", scalar_type_name})
    append(&ctx.types, struct_pointer)
    ctx.buffer_ptr_type_id = auto_cast(struct_pointer.result)
    ctx.buffer_storage_class = struct_pointer.storage_class

    rt_array_decorate                           : OpDecorate
    rt_array_decorate.target                    = create_id({"%_runtimearray_", scalar_type_name})
    rt_array_decorate.decoration                = .ArrayStride
    rt_array_decorate.decoration_operands       = {4}
    append(&ctx.annotations, rt_array_decorate)

    struct_member_decorate                      : OpMemberDecorate
    struct_member_decorate.structure_type       = create_id({"%type_RWStructured_buffer_", scalar_type_name})
    struct_member_decorate.member               = 0
    struct_member_decorate.decoration           = .Offset
    struct_member_decorate.decoration_operands  = {0}
    append(&ctx.annotations, struct_member_decorate)

    struct_decorate                             : OpDecorate
    struct_decorate.target                      = create_id({"%type_RWStructured_buffer_", scalar_type_name})
    struct_decorate.decoration                  = .BufferBlock
    append(&ctx.annotations, struct_decorate)
}


translate_scalar_type :: proc(ctx: ^Ctx, t: string) {
    switch t {
    case "bool": 
        type            : OpTypeBool
        type.result     = create_result_id({"%", "bool"})
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "i8": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "int"})
        type.width      = 8
        type.signedness = 1
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "i16": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "int"})
        type.width      = 16
        type.signedness = 1
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "i32": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "int"})
        type.width      = 32
        type.signedness = 1
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "i64": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "int"})
        type.width      = 64
        type.signedness = 1
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "u8": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "uint"})
        type.width      = 8
        type.signedness = 0
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "u16": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "uint"})
        type.width      = 16
        type.signedness = 0
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "u32": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "uint"})
        type.width      = 32
        type.signedness = 0
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "u64": 
        type            : OpTypeInt
        type.result     = create_result_id({"%", "uint"})
        type.width      = 64
        type.signedness = 0
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    // Not handling FP Encoding for OpTypeFloat quite yet
    case "f16": 
        type            : OpTypeFloat
        type.result     = create_result_id({"%", "float"})
        type.width      = 16
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "f32": 
        type            : OpTypeFloat
        type.result     = create_result_id({"%", "float"})
        type.width      = 32
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "f64": 
        type            : OpTypeFloat
        type.result     = create_result_id({"%", "float"})
        type.width      = 64
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
    case "f128": 
        type            : OpTypeFloat
        type.result     = create_result_id({"%", "float"})
        type.width      = 128
        append(&ctx.types, type)
        ctx.buffer_scalar_type_id = auto_cast(type.result)
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
                translate_binary_op(ctx, e) 
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
translate_binary_op :: proc(ctx: ^Ctx, node: Binary_Expression) {
    // switch n in node.lhs {
    // case .Literal:
    // case .Variable_Expression:
    // case .Binary_Expression:
    // case .Call_Expression:
    // }


    // Need error handling here
    lhs_id := create_id({"%", node.lhs.value})
    rhs_id := create_id({"%", node.rhs.value})

    lhs_load                : OpLoad
    lhs_load.result         = auto_cast("%lhs_register")
    lhs_load.result_type    = ctx.buffer_scalar_type_id
    lhs_load.pointer        = ctx.access_chain_map[lhs_id]
    append(&ctx.loads, lhs_load)

    rhs_load                : OpLoad
    rhs_load.result         = auto_cast("%rhs_register")
    rhs_load.result_type    = ctx.buffer_scalar_type_id
    rhs_load.pointer        = ctx.access_chain_map[rhs_id]
    append(&ctx.loads, rhs_load)

    lhs_load_id: Id = auto_cast(lhs_load.result)
    rhs_load_id: Id = auto_cast(rhs_load.result)

    result: Result_Id
    type := string(ctx.buffer_scalar_type_id)
    switch type {
    case "%int":
        switch node.op {
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
        switch node.op {
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
        switch node.op {
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
    
    store: OpStore
    store.pointer = auto_cast(ctx.access_chain_map["%out"]) // Cheating a bit here
    store.object = auto_cast(result)
    append(&ctx.stores, store)
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


