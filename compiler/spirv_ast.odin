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

Selection_Control :: enum {
    None, 
    Flatten,
    DontFlatten,
}


Loop_Control :: enum {
    None,
    Unroll,
    DontUnroll,
    DependencyInfinte,
    DependencyLength,
    MinIterations,
    MaxIterations,
    IterationMultiple,
    PeelCount,
    PartialCount,
}


// ----------------------------------------------------------------------------------------------------
// Instructions

// This set of all instructions and the other unions for each Op family do not exist 
// in the SPIR-V spec but is a handy abstraction for our AST
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
    OpFUnordGreaterThanEqual,
    // Control-Flow
    OpControlFlow,
    OpPhi,
    OpLoopMerge,
    OpSelectionMerge,
    OpLabel,
    OpBranch,
    OpBranchConditional,
    OpSwitch,
    OpKill,
    OpReturn,
    OpReturnValue,
    OpUnreachable,
    OpLifetimeStart,
    OpLifetimeStop,
    OpTerminateInvocation,
    OpDemoteToHelperInvocation
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
    OpSMod,
    OpUMod,
    OpSRem,
    OpFAdd,
    OpFSub,
    OpFMul,
    OpFDiv,
    OpFMod,
    OpFRem,
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
    OpFUnordGreaterThanEqual,
    OpSelectionMerge,
    OpLoopMerge,
    OpBranchConditional,
    OpBranch,
    OpLabel,
    OpLoad,
    OpStore,
    OpAccessChain,
    OpVariable, // Here only for those of the Function Storage Class
}


// --------------------------------------------------
// Mode-Setting

OpModeSetting :: union {
    OpCapability,
    OpMemoryModel,
    OpEntryPoint,
    OpExecutionMode,
}


/*
OpMemoryModel

Set addressing model and memory model for the entire module.

Addressing Model selects the module’s Addressing Model.

Memory Model selects the module’s memory model, see Memory Model.
*/
OpMemoryModel :: struct {
    addressing_model:   Addressing_Model,
    memory_model:       Memory_Model
}


/*
OpEntryPoint

Declare an entry point, its execution model, and its interface.

Execution Model is the execution model for the entry point and its static call tree. See Execution Model.

Entry Point must be the Result <id> of an OpFunction instruction.

Name is a name string for the entry point. A module must not have two OpEntryPoint instructions with the same Execution Model and the same Name string.

Interface is a list of <id> of global OpVariable instructions. These declare the set of global variables from a module that form the interface of this entry point. The set of Interface <id> must be equal to or a superset of the global OpVariable Result <id> referenced by the entry point’s static call tree, within the interface’s storage classes. Before version 1.4, the interface’s storage classes are limited to the Input and Output storage classes. Starting with version 1.4, the interface’s storage classes are all storage classes used in declaring all global variables referenced by the entry point’s call tree.

Interface <id> are forward references. Before version 1.4, duplication of these <id> is tolerated. Starting with version 1.4, an <id> must not appear more than once.
*/
OpEntryPoint :: struct {
    execution_model:    Execution_Model,
    entry_point:        Id,
    name:               string,
    interfaces:         [dynamic]Id // These IDs must be the result of OpVariables
}


/*
OpExecutionMode

Declare an execution mode for an entry point.

Entry Point must be the Entry Point <id> operand of an OpEntryPoint instruction.

Mode is the execution mode. See Execution Mode.

This instruction is only valid if the Mode operand is an execution mode that takes no Extra Operands, or takes Extra Operands that are not <id> operands.
*/
OpExecutionMode :: struct {
    entry_point:    Id,
    mode:           Execution_Mode,
    mode_operands:  [dynamic]string
}


/*
OpCapability

Declare a capability used by this module.

Capability is the capability declared by this instruction. There are no restrictions on the order in which capabilities are declared.

See the capabilities section for more detail.
*/
OpCapability :: struct {
    capability: Capability
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


/*
OpTypeVoid

Declare the void type.
*/
OpTypeVoid :: struct {
    result: Result_Id,
}


/*
OpTypeBool

Declare the Boolean type. Values of this type can only be either true or false. There is no physical size or bit pattern defined for these values. If they are stored (in conjunction with OpVariable), they must only be used with logical addressing operations, not physical, and only with non-externally visible shader storage classes: UniformConstant, Workgroup, CrossWorkgroup, Private, Function, Input, and Output.
*/
OpTypeBool :: struct {
    result: Result_Id,
}


/*
OpTypeInt

Declare a new integer type.

Width specifies how many bits wide the type is. Width is an unsigned 32-bit integer. The bit pattern of a signed integer value is two’s complement.

Signedness specifies whether there are signed semantics to preserve or validate.
0 indicates unsigned, or no signedness semantics
1 indicates signed semantics.
In all cases, the type of operation of an instruction comes from the instruction’s opcode, not the signedness of the operands.
*/
OpTypeInt :: struct {
    result:     Result_Id,
    width:      u32,
    signedness: u32
}


/*
OpTypeFloat

Declare a new floating-point type.

Width specifies how many bits wide the type is. Width is an unsigned 32-bit integer.

Floating Point Encoding specifies the bit pattern of values.

Unless Floating Point Encoding is present, the bit pattern of a floating-point value is the binary format described by the IEEE 754 encoding for the specified Width.
*/
OpTypeFloat :: struct {
    result:         Result_Id,
    width:          u32,
    fp_encoding:    string // ??
}


/*
OpTypeVector

Declare a new vector type.

Component Type is the type of each component in the resulting type. It must be a scalar type.

Component Count is the number of components in the resulting type. Component Count is an unsigned 32-bit integer. It must be at least 2.

Components are numbered consecutively, starting with 0.
*/
OpTypeVector :: struct {
    result:             Result_Id,
    component_type:     Id,
    component_count:    u32
}


/*
OpTypeMatrix

Declare a new matrix type.

Column Type is the type of each column in the matrix. It must be vector type.

Column Count is the number of columns in the new matrix type. Column Count is an unsigned 32-bit integer. It must be at least 2.

Matrix columns are numbered consecutively, starting with 0. This is true independently of any Decorations describing the memory layout of a matrix (e.g., RowMajor or MatrixStride).
*/
OpTypeMatrix :: struct {
    result:         Result_Id,
    column_type:    Id,
    column_count:   u32
}


/*
OpTypeArray

Declare a new array type.

Element Type is the type of each element in the array.

Length is the number of elements in the array. It must be at least 1. Length must come from a constant instruction of an integer-type scalar whose value is at least 1.

Array elements are numbered consecutively, starting with 0.
*/
OpTypeArray :: struct {
    result:         Result_Id,
    element_type:   Id,
    length:         Id
}


/*
OpTypeRuntimeArray

Declare a new run-time array type. Its length is not known at compile time.

Element Type is the type of each element in the array.

See OpArrayLength for getting the Length of an array of this type.
*/
OpTypeRuntimeArray :: struct {
    result:         Result_Id,
    element_type:   Id,
}


/*
OpTypeStruct

Declare a new structure type.

Member N type is the type of member N of the structure. The first member is member 0, the next is member 1, …​ It is valid for the structure to have no members.

If an operand is not yet defined, it must be defined by an OpTypePointer, where the type pointed to is an OpTypeStruct.
*/
OpTypeStruct :: struct {
    result:     Result_Id,
    members:    [dynamic]Id
}


/*
OpTypePointer

Declare a new pointer type.

Storage Class is the Storage Class of the memory holding the object pointed to. If there was a forward reference to this type from an OpTypeForwardPointer, the Storage Class of that instruction must equal the Storage Class of this instruction.

Type is the type of the object pointed to.
*/
OpTypePointer :: struct {
    result:         Result_Id,
    storage_class:  Storage_Class,
    type:           Id
}


/*
OpTypeFunction

Declare a new function type.

OpFunction uses this to declare the return type and parameter types of a function.

Return Type is the type of the return value of functions of this type. It must be a concrete or abstract type, or a pointer to such a type. If the function has no return value, Return Type must be OpTypeVoid.

Parameter N Type is the type <id> of the type of parameter N. It must not be OpTypeVoid
*/
OpTypeFunction :: struct {
    result:         Result_Id,
    return_type:    Id,
    parameters:     [dynamic]Id
}


// --------------------------------------------------
// Constant-Creation

/*
OpConstant

Declare a new integer-type or floating-point-type scalar constant.

Result Type must be a scalar integer type or floating-point type.

Value is the bit pattern for the constant. Types 32 bits wide or smaller take one word. Larger types take multiple words, with low-order words appearing first.
*/
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


/*
OpVariable

Allocate an object in memory, resulting in a pointer to it, which can be used with OpLoad and OpStore.

Result Type must be an OpTypePointer. Its Type operand is the type of object in memory.

Storage Class is the Storage Class of the memory holding the object. It must not be Generic. It must be the same as the Storage Class operand of the Result Type. If Storage Class is Function, the memory is allocated on execution of the instruction for the current invocation for each dynamic instance of the function. The current invocation’s memory is deallocated when it executes any function termination instruction of the dynamic instance of the function it was allocated by.

Initializer is optional. If Initializer is present, it will be the initial value of the variable’s memory content. Initializer must be an <id> from a constant instruction or a global (module scope) OpVariable instruction. Initializer must have the same type as the type pointed to by Result Type.
*/
OpVariable :: struct {
    result:         Result_Id,
    result_type:    Id,
    storage_class:  Storage_Class,
    initializer:    Id
}


/*
OpLoad

Load through a pointer.

Result Type is the type of the loaded object. It must be a type with fixed size; i.e., it must not be, nor include, any OpTypeRuntimeArray types.

Pointer is the pointer to load through. Its type must be an OpTypePointer whose Type operand is the same as Result Type.

If present, any Memory Operands must begin with a memory operand literal. If not present, it is the same as specifying the memory operand None.
*/
OpLoad :: struct {
    result:             Result_Id,
    result_type:        Id,
    pointer:            Id,
    memory_operands:    [dynamic]Memory_Operand
}


/*
OpStore

Store through a pointer.

Pointer is the pointer to store through. Its type must be an OpTypePointer whose Type operand is the same as the type of Object.

Object is the object to store.

If present, any Memory Operands must begin with a memory operand literal. If not present, it is the same as specifying the memory operand None.
*/
OpStore :: struct {
    pointer:            Id,
    object:             Id,
    memory_operands:    [dynamic]Memory_Operand
}


/*
OpAccessChain

Create a pointer into a composite object.

Result Type must be an OpTypePointer. Its Type operand must be the type reached by walking the Base’s type hierarchy down to the last provided index in Indexes, and its Storage Class operand must be the same as the Storage Class of Base.

Base must be a pointer, pointing to the base of a composite object.

Indexes walk the type hierarchy to the desired depth, potentially down to scalar granularity. The first index in Indexes selects the top-level member/element/component/element of the base composite. All composite constituents use zero-based numbering, as described by their OpType…​ instruction. The second index applies similarly to that result, and so on. Once any non-composite type is reached, there must be no remaining (unused) indexes.

Each index in Indexes
- must have a scalar integer type
- is treated as signed
- if indexing into a structure, must be an OpConstant whose value is in bounds for selecting a member
- if indexing into a vector, array, or matrix, with the result type being a logical pointer type, causes undefined behavior if not in bounds.
*/
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


/*
OpFunction

Add a function. This instruction must be immediately followed by one OpFunctionParameter instruction per each formal parameter of this function. This function’s body or declaration terminates with the next OpFunctionEnd instruction.

Result Type must be the same as the Return Type declared in Function Type.

Function Type is the result of an OpTypeFunction, which declares the types of the return value and parameters of the function.
*/
OpFunction :: struct {
    result:             Result_Id,
    result_type:        Id,
    function_control:   Function_Control,
    function_type:      Id
}


/*
OpFunctionParameter

Declare a formal parameter of the current function.

Result Type is the type of the parameter.

This instruction must immediately follow an OpFunction or OpFunctionParameter instruction. The order of contiguous OpFunctionParameter instructions is the same order arguments are listed in an OpFunctionCall instruction to this function. It is also the same order in which Parameter Type operands are listed in the OpTypeFunction of the Function Type operand for this function’s OpFunction instruction.
*/
OpFunctionParameter :: struct {
    result:             Result_Id,
    result_type:        Id,
}


/*
OpFunctionCall

Call a function.

Result Type is the type of the return value of the function. It must be the same as the Return Type operand of the Function Type operand of the Function operand.

Function is an OpFunction instruction. This could be a forward reference.

Argument N is the object to copy to parameter N of Function.

Note: A forward call is possible because there is no missing type information: Result Type must match the Return Type of the function, and the calling argument types must match the formal parameter types.
*/
OpFunctionCall :: struct {
    result:         Result_Id,
    result_type:    Id,
    function:       Id,
    arguements:     [dynamic]Id
}


/*
OpFunctionEnd

Last instruction of a function.
*/
OpFunctionEnd :: struct {}


// --------------------------------------------------
// Composite

OpComposite :: union {
    OpCompositeExtract,
}


/*
OpCompositeExtract

Extract a part of a composite object.

Result Type must be the type of object selected by the last provided index. The instruction result is the extracted object.

Composite is the composite to extract from.

Indexes walk the type hierarchy, potentially down to component granularity, to select the part to extract. All indexes must be in bounds. All composite constituents use zero-based numbering, as described by their OpType…​ instruction. Each index is an unsigned 32-bit integer.
*/
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


/*
OpIAdd

Integer addition of Operand 1 and Operand 2.

Result Type must be a scalar or vector of integer type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same number of components as Result Type. They must have the same component width as Result Type.

The resulting value equals the low-order N bits of the correct result R, where N is the component width and R is computed with enough precision to avoid overflow and underflow.

Results are computed per component.
*/
OpIAdd :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFAdd

Floating-point addition of Operand 1 and Operand 2.

Result Type must be a scalar or vector of floating-point type.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component.
*/
OpFAdd :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpISub

Integer subtraction of Operand 2 from Operand 1.

Result Type must be a scalar or vector of integer type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same number of components as Result Type. They must have the same component width as Result Type.

The resulting value equals the low-order N bits of the correct result R, where N is the component width and R is computed with enough precision to avoid overflow and underflow.

Results are computed per component.
*/
OpISub :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFSub

Floating-point subtraction of Operand 2 from Operand 1.

Result Type must be a scalar or vector of floating-point type.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component.
*/
OpFSub :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpIMul

Integer multiplication of Operand 1 and Operand 2.

Result Type must be a scalar or vector of integer type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same number of components as Result Type. They must have the same component width as Result Type.

The resulting value equals the low-order N bits of the correct result R, where N is the component width and R is computed with enough precision to avoid overflow and underflow.

Results are computed per component.
*/
OpIMul :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFMul

Floating-point multiplication of Operand 1 and Operand 2.

Result Type must be a scalar or vector of floating-point type.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component.
*/
OpFMul :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpUDiv

Unsigned-integer division of Operand 1 divided by Operand 2.

Result Type must be a scalar or vector of integer type, whose Signedness operand is 0.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component. Behavior is undefined if Operand 2 is 0.
*/
OpUDiv :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSDiv

Signed-integer division of Operand 1 divided by Operand 2.

Result Type must be a scalar or vector of integer type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same number of components as Result Type. They must have the same component width as Result Type.

Results are computed per component. Behavior is undefined if Operand 2 is 0. Behavior is undefined if Operand 2 is -1 and Operand 1 is the minimum representable value for the operands' type, causing signed overflow.
*/
OpSDiv :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFDiv

Floating-point division of Operand 1 divided by Operand 2.

Result Type must be a scalar or vector of floating-point type.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component.
*/
OpFDiv :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpUMod

Unsigned modulo operation of Operand 1 modulo Operand 2.

Result Type must be a scalar or vector of integer type, whose Signedness operand is 0.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component. Behavior is undefined if Operand 2 is 0.
*/
OpUMod :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSMod

Signed remainder operation for the remainder whose sign matches the sign of Operand 2.

Result Type must be a scalar or vector of integer type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same number of components as Result Type. They must have the same component width as Result Type.

Results are computed per component. Behavior is undefined if Operand 2 is 0. Behavior is undefined if Operand 2 is -1 and Operand 1 is the minimum representable value for the operands' type, causing signed overflow. Otherwise, the result is the remainder r of Operand 1 divided by Operand 2 where if r ≠ 0, the sign of r is the same as the sign of Operand 2.
*/
OpSMod :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFMod

The floating-point remainder whose sign matches the sign of Operand 2.

Result Type must be a scalar or vector of floating-point type.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component. The resulting value is undefined if Operand 2 is 0. Otherwise, the result is the remainder r of Operand 1 divided by Operand 2 where if r ≠ 0, the sign of r is the same as the sign of Operand 2.
*/
OpFMod :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSRem

Signed remainder operation for the remainder whose sign matches the sign of Operand 1.

Result Type must be a scalar or vector of integer type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same number of components as Result Type. They must have the same component width as Result Type.

Results are computed per component. Behavior is undefined if Operand 2 is 0. Behavior is undefined if Operand 2 is -1 and Operand 1 is the minimum representable value for the operands' type, causing signed overflow. Otherwise, the result is the remainder r of Operand 1 divided by Operand 2 where if r ≠ 0, the sign of r is the same as the sign of Operand 1.
*/
OpSRem :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFRem

The floating-point remainder whose sign matches the sign of Operand 1.

Result Type must be a scalar or vector of floating-point type.

The types of Operand 1 and Operand 2 both must be the same as Result Type.

Results are computed per component. The resulting value is undefined if Operand 2 is 0. Otherwise, the result is the remainder r of Operand 1 divided by Operand 2 where if r ≠ 0, the sign of r is the same as the sign of Operand 1.
*/
OpFRem :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


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


/*
OpAny

Result is true if any component of Vector is true, otherwise result is false.

Result Type must be a Boolean type scalar.

Vector must be a vector of Boolean type.
*/
OpAny :: struct {
    result:         Result_Id,
    result_type:    Id,
    vector:         Id,
}


/*
OpAll

Result is true if all components of Vector are true, otherwise result is false.

Result Type must be a Boolean type scalar.

Vector must be a vector of Boolean type.
*/
OpAll :: struct {
    result:         Result_Id,
    result_type:    Id,
    vector:         Id,
}


/*
OpIsNan

Result is true if x is a NaN for the floating-point encoding used by the type of x, otherwise result is false.

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

Results are computed per component.
*/
OpIsNan :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


/*
OpIsInf

Result is true if x is an Inf for the floating-point encoding used by the type of x, otherwise result is false

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

Results are computed per component.
*/
OpIsInf :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


/*
OpIsFinite

Result is true if x is a finite number for the floating-point encoding used by the type of x, otherwise result is false.

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

Results are computed per component.
*/
OpIsFinite :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


/*
OpIsNormal

Result is true if x is a normal number for the floating-point encoding used by the type of x, otherwise result is false.

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

Results are computed per component.
*/
OpIsNormal :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


/*
OpSignBitSet

Result is true if x has its sign bit set, otherwise result is false.

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

Results are computed per component.
*/
OpSignBitSet :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
}


/*
OpOrdered

Result is true if both x == x and y == y are true, where OpFOrdEqual is used as comparison, otherwise result is false.

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

y must have the same type as x.

Results are computed per component.
*/
OpOrdered :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
    y:              Id,
}


/*
OpUnordered

Result is true if either x or y is an NaN for the floating-point encoding used by the type of x and y, otherwise result is false.

Result Type must be a scalar or vector of Boolean type.

x must be a scalar or vector of floating-point type. It must have the same number of components as Result Type.

y must have the same type as x.

Results are computed per component.
*/
OpUnordered :: struct {
    result:         Result_Id,
    result_type:    Id,
    x:              Id,
    y:              Id,
}


/*
OpLogicalEqual

Result is true if Operand 1 and Operand 2 have the same value. Result is false if Operand 1 and Operand 2 have different values.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 must be the same as Result Type.

The type of Operand 2 must be the same as Result Type.

Results are computed per component.
*/
OpLogicalEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpLogicalNotEqual

Result is true if Operand 1 and Operand 2 have different values. Result is false if Operand 1 and Operand 2 have the same value.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 must be the same as Result Type.

The type of Operand 2 must be the same as Result Type.

Results are computed per component.
*/
OpLogicalNotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpLogicalOr

Result is true if either Operand 1 or Operand 2 is true. Result is false if both Operand 1 and Operand 2 are false.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 must be the same as Result Type.

The type of Operand 2 must be the same as Result Type.

Results are computed per component.
*/
OpLogicalOr :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpLogicalAnd

Result is true if both Operand 1 and Operand 2 are true. Result is false if either Operand 1 or Operand 2 are false.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 must be the same as Result Type.

The type of Operand 2 must be the same as Result Type.

Results are computed per component.
*/
OpLogicalAnd :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpLogicalNot

Result is true if Operand is false. Result is false if Operand is true.

Result Type must be a scalar or vector of Boolean type.

The type of Operand must be the same as Result Type.

Results are computed per component.
*/
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


/*
OpIEqual

Integer comparison for equality.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpIEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpINotEqual

Integer comparison for inequality.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpINotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpUGreaterThan

Unsigned-integer comparison if Operand 1 is greater than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpUGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSGreaterThan

Signed-integer comparison if Operand 1 is greater than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpSGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpUGreaterThanEqual

Unsigned-integer comparison if Operand 1 is greater than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpUGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSGreaterThanEqual

Signed-integer comparison if Operand 1 is greater than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpSGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpULessThan

Unsigned-integer comparison if Operand 1 is less than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpULessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSLessThan

Signed-integer comparison if Operand 1 is less than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpSLessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpULessThanEqual

Unsigned-integer comparison if Operand 1 is less than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpULessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpSLessThanEqual

Signed-integer comparison if Operand 1 is less than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of integer type. They must have the same component width, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpSLessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFOrdEqual

Floating-point comparison for being ordered and equal.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFOrdEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFUnordEqual

Floating-point comparison for being unordered or equal.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFUnordEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFOrdNotEqual

Floating-point comparison for being ordered and not equal.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFOrdNotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFUnordNotEqual

Floating-point comparison for being unordered or not equal.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFUnordNotEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFOrdLessThan

Floating-point comparison if operands are ordered and Operand 1 is less than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFOrdLessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFUnordLessThan

Floating-point comparison if operands are unordered or Operand 1 is less than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFUnordLessThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFOrdGreaterThan

Floating-point comparison if operands are ordered and Operand 1 is greater than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFOrdGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFUnordGreaterThan

Floating-point comparison if operands are unordered or Operand 1 is greater than Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFUnordGreaterThan :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFOrdLessThanEqual

Floating-point comparison if operands are ordered and Operand 1 is less than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFOrdLessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFUnordLessThanEqual

Floating-point comparison if operands are unordered or Operand 1 is less than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFUnordLessThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFOrdGreaterThanEqual

Floating-point comparison if operands are ordered and Operand 1 is greater than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFOrdGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


/*
OpFUnordGreaterThanEqual

Floating-point comparison if operands are unordered or Operand 1 is greater than or equal to Operand 2.

Result Type must be a scalar or vector of Boolean type.

The type of Operand 1 and Operand 2 must be a scalar or vector of floating-point type. They must have the same type, and they must have the same number of components as Result Type.

Results are computed per component.
*/
OpFUnordGreaterThanEqual :: struct {
    result:         Result_Id,
    result_type:    Id,
    operand_1:      Id,
    operand_2:      Id,
}


// --------------------------------------------------
// Control-Flow

OpControlFlow :: union {
    OpPhi,
    OpLoopMerge,
    OpSelectionMerge,
    OpLabel,
    OpBranch,
    OpBranchConditional,
    OpSwitch,
    OpKill,
    OpReturn,
    OpReturnValue,
    OpUnreachable,
    OpLifetimeStart,
    OpLifetimeStop,
    OpTerminateInvocation,
    OpDemoteToHelperInvocation
}


/*
OpPhi

The SSA phi function.

The result is selected based on control flow: If control reached the current block from Parent i, Result Id gets the value that Variable i had at the end of Parent i.

Result Type can be any type except OpTypeVoid.

Operands are a sequence of pairs: (Variable 1, Parent 1 block), (Variable 2, Parent 2 block), …​ Each Parent i block is the label of an immediate predecessor in the CFG of the current block. There must be exactly one Parent i for each parent block of the current block in the CFG. If Parent i is reachable in the CFG and Variable i is defined in a block, that defining block must dominate Parent i. All Variables must have a type matching Result Type.

Within a block, this instruction must appear before all non-OpPhi instructions (except for OpLine and OpNoLine, which can be mixed with OpPhi)
*/
OpPhi :: struct {}


/*
OpLoopMerge

Declare a structured loop.

This instruction must immediately precede either an OpBranch or OpBranchConditional instruction. That is, it must be the second-to-last instruction in its block.

Merge Block is the label of the merge block for this structured loop.

Continue Target is the label of a block targeted for processing a loop "continue".

Loop Control Parameters appear in Loop Control-table order for any Loop Control setting that requires such a parameter.

See Structured Control Flow for more detail.
*/
OpLoopMerge :: struct {
    merge_block:        Id,
    continue_target:    Id,
    loop_control:       Loop_Control,
    loop_control_params: [dynamic]u32 // ???
}


/*
OpSelectionMerge

Declare a structured selection.

This instruction must immediately precede either an OpBranchConditional or OpSwitch instruction. That is, it must be the second-to-last instruction in its block.

Merge Block is the label of the merge block for this structured selection.

See Structured Control Flow for more detail.
*/
OpSelectionMerge :: struct {
    merge_block:        Id,
    selection_control:  Selection_Control
}


/*
OpLabel

The label instruction of a block.

References to a block are through the Result <id> of its label.
*/
OpLabel :: struct {
    result: Result_Id
}


/*
OpBranch

Unconditional branch to Target Label.

Target Label must be the Result <id> of an OpLabel instruction in the current function.

This instruction must be the last instruction in a block.
*/
OpBranch :: struct {
    target: Result_Id
}


/*
OpBranchConditional

If Condition is true, branch to True Label, otherwise branch to False Label.

Condition must be a Boolean type scalar.

True Label must be an OpLabel in the current function.

False Label must be an OpLabel in the current function.

Starting with version 1.6, True Label and False Label must not be the same <id>.

Branch weights are unsigned 32-bit integer literals. There must be either no Branch Weights or exactly two branch weights. If present, the first is the weight for branching to True Label, and the second is the weight for branching to False Label. The implied probability that a branch is taken is its weight divided by the sum of the two Branch weights. At least one weight must be non-zero. A weight of zero does not imply a branch is dead or permit its removal; branch weights are only hints. The sum of the two weights must not overflow a 32-bit unsigned integer.

This instruction must be the last instruction in a block.
*/
OpBranchConditional :: struct {
    condition:      Id,
    true_label:     Id,
    false_label:    Id,
    branch_weights: [dynamic]i32
}


/*
OpSwitch

Multi-way branch to one of the operand label <id>.

Selector must have a type of OpTypeInt. Selector is compared for equality to the Target literals.

Default must be the <id> of a label. If Selector does not equal any of the Target literals, control flow branches to the Default label <id>.

Target must be alternating scalar integer literals and the <id> of a label. If Selector equals a literal, control flow branches to the following label <id>. It is invalid for any two literal to be equal to each other. If Selector does not equal any literal, control flow branches to the Default label <id>. Each literal is interpreted with the type of Selector: The bit width of Selector’s type is the width of each literal’s type. If this width is not a multiple of 32-bits and the OpTypeInt Signedness is set to 1, the literal values are interpreted as being sign extended.

This instruction must be the last instruction in a block.
*/
OpSwitch :: struct {}


/*
OpKill

Deprecated (use OpTerminateInvocation or OpDemoteToHelperInvocation).

Fragment-shader discard.

Ceases all further processing in any invocation that executes it: Only instructions these invocations executed before OpKill have observable side effects. If this instruction is executed in non-uniform control flow, all subsequent control flow is non-uniform (for invocations that continue to execute).

This instruction must be the last instruction in a block.

This instruction is only valid in the Fragment Execution Model.
*/
OpKill :: struct {}


/*
OpReturn

Return with no value from a function with void return type.

This instruction must be the last instruction in a block.
*/
OpReturn :: struct {}


/*
OpReturnValue

Return a value from a function.

Value is the value returned, by copy, and must match the Return Type operand of the OpTypeFunction type of the OpFunction body this return instruction is in. Value must not have type OpTypeVoid.

This instruction must be the last instruction in a block.
*/
OpReturnValue :: struct {}


/*

OpUnreachable

Behavior is undefined if this instruction is executed.

This instruction must be the last instruction in a block.
*/
OpUnreachable :: struct {}


/*
OpLifetimeStart

Declare that an object was not defined before this instruction.

Pointer is a pointer to the object whose lifetime is starting. Its type must be an OpTypePointer with Storage Class Function.

Size is an unsigned 32-bit integer. Size must be 0 if Pointer is a pointer to a non-void type or the Addresses capability is not declared. If Size is non-zero, it is the number of bytes of memory whose lifetime is starting.
*/
OpLifetimeStart :: struct {}


/*
OpLifetimeStop

Declare that an object is dead after this instruction.

Pointer is a pointer to the object whose lifetime is ending. Its type must be an OpTypePointer with Storage Class Function.

Size is an unsigned 32-bit integer. Size must be 0 if Pointer is a pointer to a non-void type or the Addresses capability is not declared. If Size is non-zero, it is the number of bytes of memory whose lifetime is ending.
*/
OpLifetimeStop :: struct {}


/*
OpTerminateInvocation

Fragment-shader terminate.

Ceases all further processing in any invocation that executes it: Only instructions these invocations executed before OpTerminateInvocation will have observable side effects. If this instruction is executed in non-uniform control flow, all subsequent control flow is non-uniform (for invocations that continue to execute).

This instruction must be the last instruction in a block.

This instruction is only valid in the Fragment Execution Model.
*/
OpTerminateInvocation :: struct {}


/*
OpDemoteToHelperInvocation (OpDemoteToHelperInvocationEXT)

Demote this fragment shader invocation to a helper invocation. Any stores to memory after this instruction are suppressed and the fragment does not write outputs to the framebuffer.

Unlike the OpTerminateInvocation instruction, this does not necessarily terminate the invocation which might be needed for derivative calculations. It is not considered a flow control instruction (flow control does not become non-uniform) and does not terminate the block. The implementation may terminate helper invocations before the end of the shader as an optimization, but doing so must not affect derivative calculations and does not make control flow non-uniform.

After an invocation executes this instruction, any subsequent load of HelperInvocation within that invocation will load an undefined value unless the HelperInvocation built-in variable is decorated with Volatile or the load included Volatile in its Memory Operands

This instruction is only valid in the Fragment Execution Model.
*/
OpDemoteToHelperInvocation :: struct {}

