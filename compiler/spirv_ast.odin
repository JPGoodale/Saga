package saga_compiler

// NOTE: We are using the C UpperCamelCase conventions and keeping the redundent 'Op' prefix
// for all Instruction nodes in order to distingush them from identically named non-Instruction 
// types (usually enums), i.e. OpCapability / Capability. Could we simply have written them like:
// 'Op_Entry_Point' ? Yes.. but I find this hideous and since they directly correlate to foreign
// language (SPIR-V) structures, I find it nicer to keep them in the same format as the orginal,
// just like is is done with the vendor libraies wrapping C code.


// ----------------------------------------------------------------------------------------------------
// Types

Id                  :: distinct string // Maybe change to runes
Result_Id           :: distinct string // Maybe change to runes

Unsigned_Integer    :: union {u8, u16, u32, u64, u128, uint}
Signed_Integer      :: union {u8, u16, u32, u64, u128, int}
Integer             :: union {u8, u16, u32, u64, u128, uint, i8, i16, i32, i64, i128, int}
Numeric_Type        :: union {u8, u16, u32, u64, u128, uint, i8, i16, i32, i64, i128, int, f16, f32, f64}


// ----------------------------------------------------------------------------------------------------
// Enums

// NOTE: Some of the enums below have many more varients for various graphics tasks but these are 
// the only ones relevent to us for now.

Capability :: enum {
    Matrix,
    Shader,
    Addresses,
    Linkage,
    Kernel,
    Vector16,
    Float16Buffer,
    Float16,
    Float64,
    Int64,
    Int64Atomics,
    Pipes,
    Groups,
    DeviceEnqueue,
    LiteralSampler,
    AtomicStorage,
    Int16,
    GroupNonUniform,
    StorageBuffer16BitAccess,
    SubgroupVoteKHR,
    SubgroupDispatch,
    // TODO: Add more
}


Addressing_Model :: enum {
    Logical,
    Physical32,
    Physical64,
    PhysicalStorageBuffer64,
    PhysicalStorageBuffer64EXT,
}


Memory_Model :: enum {
    GLSL450,
    OpenCL,
    Vulkan,
    VulkanKHR,
}


Execution_Model :: enum {
    GLCompute,
    Kernel,
}


Execution_Mode :: enum {
    LocalSize, 
    LocalSizeHint, 
    VecTypeHint,
    ContractionOff,
    Initializer,
    Finalizer,
    SubgroupSize,
    SubgroupsPerWorkgroup,
    SubgroupsPerWorkgroupId,
    LocalSizeId,
    LocalSizeHintId,
    // TODO: Add more
}


Decoration :: enum {
    RelaxedPrecision,
    SpecId,
    Block,
    BufferBlock,
    RowMajor,
    ColMajor,
    ArrayStride,
    MatrixStride,
    GLSLShared,
    GLSLPacked,
    CPacked,
    BuiltIn,
    NoPerspective,
    Flat,
    Invariant,
    Restrict,
    Aliased,
    Volatile,
    Constant,
    Coherent,
    NonWritable,
    NonReadable,
    Uniform,
    UniformId,
    SaturatedConversion,
    Location,
    Component,
    Index,
    Binding,
    DescriptorSet,
    Offset,
    FuncParamAttr,
    FPRoundingMode,
    FPFastMathMode,
    LinkageAttributes,
    NoContraction,
    Alignment,
    MaxByteOffset,
    AlignmentId,
    MaxByteOffsetID,
    NoSignedWrap,
    NoUnSignedWrap,
    // TODO: Add more
}


Builtin :: enum {
    NumWorkgroups,
    WorkgroupSize,
    WorkgroupId,
    LocalInvocationId,
    GlobalInvocationId,
    LocalInvocationIndex,
    WorkDim,
    GlobalSize,
    EnqueuedWorkgroupSize,
    GlobalOffset,
    GlobalLinearId,
    SubgroupSize,
    SubgroupMaxSize,
    NumSubgroups,
    NumEnqueuedSubgroups,
    SubgroupId,
    SubgroupLocalInvocationId,
    // TODO: Add more
}


Storage_Class :: enum {
    UniformConstant,
    Input,
    Uniform,
    Output,
    Workgroup,
    CrossWorkgroup,
    Private,
    Function,
    Generic,
    PushConstant,
    AtomicCounter,
    StorageBuffer,
    // TODO: Add more
}


Memory_Operand :: enum {
    None,
    Volatile,
    Aligned,
    Nontemporal,
    MakePointerAvailable,
    MakePointerAvailableKHR,
    MakePointerVisible,
    MakePointerVisibleKHR,
    NonPrivatePointer,
    NonPrivatePointerKHR,
    // Left out the INTEL ones
}


Function_Control :: enum {
    None,
    Inline,
    DontInline,
    Pure,
    Const,
    // Left out the INTEL one (once again)
}


// ----------------------------------------------------------------------------------------------------
// Instructions

// This set of all instructions and the other unions for each Op family do not exist 
// in the SPIR-V spec but are a handy abstraction for our AST
OpAny :: union {
    // Mode-Setting
    OpModeSetting,
    OpCapability,
    OpMemoryModel,
    OpExecutionMode,
    OpEntryPoint,
    // Annotation
    OpAnnotation,
    OpDecorate,
    OpMemberDecorate,
    // Type-Declaration
    OpType,
    OpTypeVoid,
    OpTypeBool,
    OpTypeInt,
    OpTypeFloat,
    OpTypeVector,
    OpTypeMatrix,
    OpTypeArray,
    OpTypeRuntimeArray,
    OpTypeStruct,
    OpTypePointer,
    OpTypeFunction,
    // Constant-Creation
    OpConstant,
    // Memory
    OpMemory,
    OpVariable,
    OpLoad,
    OpStore,
    OpAccessChain,
    // Function
    OpFunctions,
    OpFunction,
    OpFunctionParameter,
    OpFunctionCall,
    OpFunctionEnd,
    // Composite
    OpComposite,
    OpCompositeExtract,
    // Arithmetic
    OpBinaryExpr,
    OpIAdd,
    OpISub,
    OpIMul,
    OpSDiv,
    OpUDiv,
    OpFAdd,
    OpFSub,
    OpFMul,
    OpFDiv,
    // Whatever family this is
    OpLabel,
    OpReturn,
}


// --------------------------------------------------
// Mode-Setting

OpModeSetting :: union {
    OpCapability,
    OpMemoryModel,
    OpEntryPoint,
    OpExecutionMode,
}

OpCapability :: struct {
    capability: Capability
}


OpMemoryModel :: struct {
    addressing_model:   Addressing_Model,
    memory_model:       Memory_Model
}


OpEntryPoint :: struct {
    execution_model:    Execution_Model,
    entry_point:        Id,
    name:               string,
    interfaces:         [dynamic]Id // These IDs must be the result of OpVariables
}


OpExecutionMode :: struct {
    entry_point:    Id,
    mode:           Execution_Mode,
    mode_operands:  [dynamic]string
}


// --------------------------------------------------
// Annotation

// A necessary evil..
Decorate_Operand :: union {
    int,
    string,
    Builtin,
}

OpAnnotation :: union {
    OpDecorate,
    OpMemberDecorate,
}


OpDecorate :: struct {
    target:                 Id,
    decoration:             Decoration,
    decoration_operands:    [dynamic]Decorate_Operand
}


OpMemberDecorate :: struct {
    structure_type:         Id,
    member:                 u32,
    decoration:             Decoration,
    decoration_operands:    [dynamic]Decorate_Operand
}


// --------------------------------------------------
// Type-Declaration

OpType :: union {
    OpTypeVoid,
    OpTypeBool,
    OpTypeInt,
    OpTypeFloat,
    OpTypeVector,
    OpTypeMatrix,
    OpTypeArray,
    OpTypeRuntimeArray,
    OpTypeStruct,
    OpTypePointer,
    OpTypeFunction,
}


OpTypeVoid :: struct {
    result: Result_Id,
}


OpTypeBool :: struct {
    result: Result_Id,
}


OpTypeInt :: struct {
    result:     Result_Id,
    width:      u32,
    signedness: u32
}


OpTypeFloat :: struct {
    result:         Result_Id,
    width:          u32,
    fp_encoding:    string // ??
}


OpTypeVector :: struct {
    result:             Result_Id,
    component_type:     Id,
    component_count:    u32
}


OpTypeMatrix :: struct {
    result:         Result_Id,
    column_type:    Id,
    column_count:   u32
}


OpTypeArray :: struct {
    result:         Result_Id,
    element_type:   Id,
    length:         Id
}


OpTypeRuntimeArray :: struct {
    result:         Result_Id,
    element_type:   Id,
}


OpTypeStruct :: struct {
    result:     Result_Id,
    members:    [dynamic]Id
}


OpTypePointer :: struct {
    result:         Result_Id,
    storage_class:  Storage_Class,
    type:           Id
}


OpTypeFunction :: struct {
    result:         Result_Id,
    return_type:    Id,
    parameters:     [dynamic]Id
}


// --------------------------------------------------
// Constant-Creation

OpConstant :: struct {
    result:         Result_Id,
    result_type:    Id,
    value:          Numeric_Type
}


// --------------------------------------------------
// Memory

OpMemory :: union {
    OpVariable,
    OpLoad,
    OpStore,
    OpAccessChain,
}


OpVariable :: struct {
    result:         Result_Id,
    result_type:    Id,
    storage_class:  Storage_Class,
    initializer:    Id
}


OpLoad :: struct {
    result:             Result_Id,
    result_type:        Id,
    pointer:            Id,
    memory_operands:    [dynamic]Memory_Operand
}


OpStore :: struct {
    pointer:            Id,
    object:             Id,
    memory_operands:    [dynamic]Memory_Operand
}


OpAccessChain :: struct {
    result:         Result_Id,
    result_type:    Id,
    base:           Id,
    indexes:        [dynamic]Id
}


// --------------------------------------------------
// Function

OpFunctions :: union {
    OpFunction,
    OpFunctionParameter,
    OpFunctionCall,
    OpFunctionEnd
}


OpFunction :: struct {
    result:             Result_Id,
    result_type:        Id,
    function_control:   Function_Control,
    function_type:      Id
}


OpFunctionParameter :: struct {
    result:             Result_Id,
    result_type:        Id,
}


OpFunctionCall :: struct {
    result:         Result_Id,
    result_type:    Id,
    function:       Id,
    arguements:     [dynamic]Id
}


OpFunctionEnd :: struct {}


// --------------------------------------------------
// Composite

OpComposite :: union {
    OpCompositeExtract,
}


OpCompositeExtract :: struct {
    result:         Result_Id,
    result_type:    Id,
    composite:      Id,
    indexes:        [dynamic]u32
}


// --------------------------------------------------
// Arithmetic

OpBinaryExpr :: union {
    OpIAdd,
    OpISub,
    OpIMul,
    OpSDiv,
    OpUDiv,
    OpFAdd,
    OpFSub,
    OpFMul,
    OpFDiv
}


OpIAdd :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFAdd :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpISub :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFSub :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpIMul :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFMul :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpUDiv :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSDiv :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFDiv :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpUMod :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSMod :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFMod :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSRem :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFRem :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpLabel :: struct {
    result: Result_Id
}

OpReturn :: struct {}

