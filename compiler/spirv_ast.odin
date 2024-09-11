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

GLSL_Instruction :: enum {
    Exp,
    // TODO: Add more
}


// ----------------------------------------------------------------------------------------------------
// Instructions

// This set of all instructions and the other unions for each Op family do not exist 
// in the SPIR-V spec but are a handy abstraction for our AST
Instruction :: union {
    Operation,
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
    // Extensions
    OpExtension,
    OpExtInstImport,
    OpExtInst,
    OpExtInstWithForwardRefsKHR,
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
    // Relational and Logical
    OpRelational,
    OpLogical,
    OpAny,
    OpAll,
    OpIsNan,
    OpIsInf,
    OpIsFinite,
    OpIsNormal,
    OpSignBitSet,
    OpOrdered,
    OpUnordered,
    OpLogicalEqual,
    OpLogicalNotEqual,
    OpLogicalOr,
    OpLogicalNot,
    OpSelect,
    OpIEqual,
    OpINotEqual,
    OpUGreaterThan,
    OpSGreaterThan,
    OpUGreaterThanEqual,
    OpSGreaterThanEqual,
    OpULessThan,
    OpSLessThan,
    OpULessThanEqual,
    OpSLessThanEqual,
    OpFOrdEqual,
    OpFUnordEqual,
    OpFOrdNotEqual,
    OpFUnordNotEqual,
    OpFOrdLessThan,
    OpFUnordLessThan,
    OpFOrdGreaterThan,
    OpFUnordGreaterThan,
    OpFOrdLessThanEqual,
    OpFUnordLessThanEqual,
    OpFOrdGreaterThanEqual,
    OpFUnordGreaterThanEqual
}


// I know.. I know...
Operation :: union {
    OpExtInst,
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


/*
OpDecorate

Add a Decoration to another <id>.

Target is the <id> to decorate. It can potentially be any <id> that is a forward reference. A set of decorations can be grouped together by having multiple decoration instructions targeting the same OpDecorationGroup instruction.

This instruction is only valid if the Decoration operand is a decoration that takes no Extra Operands, or takes Extra Operands that are not <id> operands.
*/
OpDecorate :: struct {
    target:                 Id,
    decoration:             Decoration,
    decoration_operands:    [dynamic]Decorate_Operand
}


/*
OpMemberDecorate

Add a Decoration to a member of a structure type.

Structure type is the <id> of a type from OpTypeStruct.

Member is the number of the member to decorate in the type. The first member is member 0, the next is member 1, …

Note: See OpDecorate for creating groups of decorations for consumption by OpGroupMemberDecorate
*/
OpMemberDecorate :: struct {
    structure_type:         Id,
    member:                 u32,
    decoration:             Decoration,
    decoration_operands:    [dynamic]Decorate_Operand
}


// --------------------------------------------------
// Extensions

/*
OpExtension

Declare use of an extension to SPIR-V. This allows validation of additional instructions, tokens, semantics, etc.

Name is the extension’s name string.
*/
OpExtension :: struct {
    name: string
}


/*
OpExtInstImport

Import an extended set of instructions. It can be later referenced by the Result <id>.

Name is the extended instruction-set’s name string. Before version 1.6, there must be an external specification defining the semantics for this extended instruction set. Starting with version 1.6, if Name starts with "NonSemantic.", including the period that separates the namespace "NonSemantic" from the rest of the name, it is encouraged for a specification to exist on the SPIR-V Registry, but it is not required.

Starting with version 1.6, an extended instruction-set name which is prefixed with "NonSemantic." is guaranteed to contain only non-semantic instructions, and all OpExtInst instructions referencing this set can be ignored. All instructions within such a set must have only <id> operands; no literals. When literals are needed, then the Result <id> from an OpConstant or OpString instruction is referenced as appropriate. Result <id>s from these non-semantic instruction-set instructions must be used only in other non-semantic instructions.

See Extended Instruction Sets for more information.
*/
OpExtInstImport :: struct {
    result: Result_Id,
    name:   string
}


/*
OpExtInst

Execute an instruction in an imported set of extended instructions.

Result Type is defined, per Instruction, in the external specification for Set.

Set is the result of an OpExtInstImport instruction.

Instruction is the enumerant of the instruction to execute within Set. It is an unsigned 32-bit integer. The semantics of the instruction are defined in the external specification for Set.

Operand 1, … are the operands to the extended instruction.
*/
OpExtInst :: struct {
    result:         Result_Id,
    result_type:    Id,
    Set:            Id,
    Instruction:    GLSL_Instruction,
    operands:       [dynamic]Id
}


/*
OpExtInstWithForwardRefsKHR

Reserved.
*/
OpExtInstWithForwardRefsKHR :: struct {
    result:         Result_Id,
    result_type:    Id,
    Set:            Id,
    Instruction:    string,
    operands:       [dynamic]Id
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


// --------------------------------------------------
// Relational and Logical

OpRelational :: union {
    OpAny,
    OpAll,
    OpIsNan,
    OpIsInf,
    OpIsFinite,
    OpIsNormal,
    OpSignBitSet,
    OpOrdered,
    OpUnordered,
    OpSelect,
    OpIEqual,
    OpINotEqual,
    OpUGreaterThan,
    OpSGreaterThan,
    OpUGreaterThanEqual,
    OpSGreaterThanEqual,
    OpULessThan,
    OpSLessThan,
    OpULessThanEqual,
    OpSLessThanEqual,
    OpFOrdEqual,
    OpFUnordEqual,
    OpFOrdNotEqual,
    OpFUnordNotEqual,
    OpFOrdLessThan,
    OpFUnordLessThan,
    OpFOrdGreaterThan,
    OpFUnordGreaterThan,
    OpFOrdLessThanEqual,
    OpFUnordLessThanEqual,
    OpFOrdGreaterThanEqual,
    OpFUnordGreaterThanEqual
}
    

OpLogical :: union {
    OpLogicalEqual,
    OpLogicalNotEqual,
    OpLogicalOr,
    OpLogicalNot,
}


OpAny :: struct {
    result:         Result_Id,
    result_type:    Id,
    vector:         Id,
}


OpAll :: struct {
    result:         Result_Id,
    result_type:    Id,
    vector:         Id,
}


OpIsNan :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


OpIsInf :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


OpIsFinite :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


OpIsNormal :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


OpSignBitSet :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


OpOrdered :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
    y:              Id,
}


OpUnordered :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
    y:              Id,
}


OpLogicalEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpLogicalNotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpLogicalOr :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpLogicalAnd :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpLogicalNot :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}

/*
OpSelect

Select between two objects. Before version 1.4, results are only computed per component.

Before version 1.4, Result Type must be a pointer, scalar, or vector. Starting with version 1.4, Result Type can additionally be a composite type other than a vector.

The types of Object 1 and Object 2 must be the same as Result Type.

Condition must be a scalar or vector of Boolean type.

If Condition is a scalar and true, the result is Object 1. If Condition is a scalar and false, the result is Object 2.

If Condition is a vector, Result Type must be a vector with the same number of components as Condition and the result is a mix of Object 1 and Object 2: If a component of Condition is true, the corresponding component in the result is taken from Object 1, otherwise it is taken from Object 2.
*/
OpSelect :: struct {
    result:         Result_Id,
    result_type:    Id,
    condition:      Id,
    object_1:       Id,
    object_2:       Id,
}


OpIEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpINotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpUGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpUGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpULessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSLessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpULessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpSLessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFOrdEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFUnordEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFOrdNotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFUnordNotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFOrdLessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFUnordLessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFOrdGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFUnordGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFOrdLessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFUnordLessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFOrdGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


OpFUnordGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}

