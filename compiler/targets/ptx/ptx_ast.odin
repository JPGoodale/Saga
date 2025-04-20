package saga_compiler


// ----------------------------------------------------------------------------------------------------
// Types

Address_Type		:: union {u32, u64}
Unsigned_Integer    :: union {u8, u16, u32, u64, u128, uint}
Signed_Integer      :: union {u8, u16, u32, u64, u128, int}
Integer             :: union {u8, u16, u32, u64, u128, uint, i8, i16, i32, i64, i128, int}
Numeric_Type        :: union {u8, u16, u32, u64, u128, uint, i8, i16, i32, i64, i128, int, f16, f32, f64}


// ----------------------------------------------------------------------------------------------------
// Enums

Target :: enum {
	SM_90,
	SM_90a,
	SM_80,
	SM_86,
	SM_87,
	SM_89,
	SM_70,
	SM_72,
	SM_75,
	SM_60,
	SM_61,
	SM_62,
	SM_50,
	SM_52,
	SM_53,
	SM_30,
	SM_32,
	SM_35,
	SM_37,
	SM_20,
	SM_10,
	SM_11,
	SM_12,
	SM_13,
}


Texturing_Mode :: enum {
	Unified,
	Independent

}


Platform_Option :: enum {
	Debug,
	Map_F64_To_F32
}


Address_Size :: enum {
	B32,
	B64
}


// ----------------------------------------------------------------------------------------------------
// Directives

Directive :: union {
	Module_Directive,
	Kernel_Function_Directive,
	Control_Flow_Directive,
	Performance_Tuning_Directive,
	Debugging_Directive,
	Linking_Directive,
	Cluster_Dimension_Directive,
	Attribute_Directive,
}


// ----------------------------------------------------------------------------------------------------
// Module Directives

Module_Directive :: union {
	Version_Directive,
	Target_Directive,
	Address_Size,
}


Version_Directive :: struct {
	major: int,
	minor: int
}


Target_Directive :: struct {
	target:				Target,
	texturing_mode:		Texturing_Mode,
	platform_option:	Platform_Option,
}


Address_Size_Directive :: struct {
	size: Address_Size,
}



// ----------------------------------------------------------------------------------------------------
// Kernel and Function Directives 

Kernel_Function_Directive :: union {
	Entry_Directive,
	Function_Directive,
	Alias_Directive,
}


Entry_Directive :: struct {
	name:	string,
	params: [dynamic]Param,
	body:	Body,
}


Function_Directive :: struct {
	name: string,
	attribute: Attribute_Directive,
	params: []Param,
	body: Body,
	return_param: Param,
	no_return: bool,	
}


Alias_Directive :: struct {
	f_alias: string,
	f_aliasee: string
}


// ----------------------------------------------------------------------------------------------------
// Control Flow Directives 

Control_Flow_Directive :: struct {}


// ----------------------------------------------------------------------------------------------------
// Performance Tuning Directives 

Performance_Tuning_Directive :: struct {}


// ----------------------------------------------------------------------------------------------------
// Debugging Directives 

Debugging_Directive :: struct {}


// ----------------------------------------------------------------------------------------------------
// Linking Directives 

Linking_Directive :: struct {}


// ----------------------------------------------------------------------------------------------------
// Cluster Dimension Directives 

Cluster_Dimension_Directive :: struct {}


// ----------------------------------------------------------------------------------------------------

Attribute_Directive :: struct {
	managed: bool,
	unified: [2]int
}


// Kernel or Function Body

Body :: struct{
	instructions:	[dynamic]Instruction,
	registers:		[dynamic]Register,
}


// Registers and Params

Param :: struct {
	name:			string,
	type:			Address_Size,
	is_pointer:		bool,
	state_space:	State_Space,
	align:			int,
}


Register :: struct {
	name: string,
	dtype: Any,
	value: any,
}


Address_Register :: struct {
	name: string,
	dtype: Any,
	value: any,
}


// Instructions

_Instruction :: union {
	Integer_Arithmetic_Instruction,
	Extended_Precision_Integer_Arithmetic_Instruction,
	Floating_Point_Instruction,
	Half_Precision_Floating_Point_Instruction,
	Comparison_Instruction,
	Selection_Instruction,
	Half_Precision_Comparision_Instruction,
	Logic_Instruction,
	Shift_Instruction,
	Data_Movement_Instruction,
	Conversion_Instruction,
	Texture_Instruction,
	Surface_Instruction,
	Control_Flow_Instruction,
	Parallel_Synchronization_Instruction,
	Communication_Instruction,
	WMMA_Instruction,
	WGMMA_Instruction,
	Stack_Manipulation_Instruction,
	Video_Instruction,
	Misc_Instruction
}


// Integer Arithmetic Instructions

Integer_Arithmetic_Instruction :: union {
	Unary_Integer_Arithmetic_Instruction,
	Binary_Integer_Arithmetic_Instruction,
	Ternary_Integer_Arithmetic_Instruction,
	Quaternary_Integer_Arithmetic_Instruction
}


Unary_Integer_Arithmetic_Instruction :: struct {
	name: string "abs, neg, popc, clz, bfind, brev",
	dtype: Bits_And_Ints,
	operand: Register,
	destination: Register,
}


Binary_Integer_Arithmetic_Instruction :: struct {
	name: string "add, sub, mul, mul24, div, rem, min, max, bmsk, szext", 
	dtype: Bits_And_Ints,
	lhs: Register,
	rhs: Register,
	destination: Register,
	saturation_mod: Saturation_Modifier,
	mode: Mode,
}


Ternary_Integer_Arithmetic_Instruction :: struct {
	name: string "mad, mad24, sad, fns, bfe, dp4a, dp2a",
	dtype: Bits_And_Ints,
	a: Register,
	b: Register,
	c: Register,
	destination: Register,
	saturation_mod: Saturation_Modifier,
	mode: Mode,
}


Quaternary_Integer_Arithmetic_Instruction :: struct {
	name: string "bfi",
	dtype: Bits,
	a: Register,
	b: Register,
	c: Register,
	d: Register,
	destinaton: Register,
}


// Extended Integer Arithmetic Instructions

Extended_Precision_Integer_Arithmetic_Instruction :: union {
	Binary_Extended_Precision_Integer_Arithmetic_Instruction,
	Ternary_Extended_Precision_Integer_Arithmetic_Instruction,
}


Binary_Extended_Precision_Integer_Arithmetic_Instruction :: struct {
	name: string "add.cc, addc, sub.cc, subc",
	dtype: Integer,
	lhs: Register,
	rhs: Register,
	destination: Register,
	cc: bool,
}


Ternary_Extended_Precision_Integer_Arithmetic_Instruction :: struct {
	name: string "mad.cc, madc",
	dtype: Integer,
	a: Register,
	b: Register,
	c: Register,
	destination: Register,
	mode: Mode,
	cc: bool,
}


// Floating Point Instructions

Floating_Point_Instruction :: union {
	Unary_Floating_Point_Instruction,
	Binary_Floating_Point_Instruction,
	Ternary_Floating_Point_Instruction,
}


Unary_Floating_Point_Instruction :: struct {
	name: string "testp, abs, neg, rcp, rcp.approx.ftz.f64, sqrt, rsqrt, rsqrt.approx.ftz.f64, sin, cos, lg2, ex2, tanh",
	dtype: Float,
	operand: Register,
	destination: Register,
	rounding_mod: Rounding_Modifier,
	testp_op: Testp_Op,
	ftz_mod: bool,
}


Binary_Floating_Point_Instruction :: struct {
	name: string "copysign, add, sub, mul, div, min, max", 
	dtype: Float,
	lhs: Register,
	rhs: Register,
	destination: Register,
	rounding_mod: Rounding_Modifier,
	magnitude_mod: Magnitude_Modifier,
	ftz_mod: bool,
}


Ternary_Floating_Point_Instruction :: struct {
	name: string "fma, mad",
	dtype: Float,
	a: Register,
	b: Register,
	c: Register,
	destination: Register,
	rounding_mod: Rounding_Modifier,
	ftz_mod: bool,
}


// Half Precision Floating Point Instructions

Half_Precision_Floating_Point_Instruction :: union {
	Unary_Half_Precision_Floating_Point_Instruction,
	Binary_Half_Precision_Floating_Point_Instruction,
	Ternary_Half_Precision_Floating_Point_Instruction,
}


Unary_Half_Precision_Floating_Point_Instruction :: struct {
	name: string "neg, abs, tanh, ex2",
	dtype: Half,
	operand: Register,
	destination: Register,
	rounding_mod: Rounding_Modifier,
	ftz_mod: bool,
}


Binary_Half_Precision_Floating_Point_Instruction :: struct {
	name: string "add, sub, mul, min, max", 
	dtype: Half,
	lhs: Register,
	rhs: Register,
	destination: Register,
	rounding_mod: bool,
	saturation_mod: bool,
	ftz_mod: bool,
	magnitude_mod: Magnitude_Modifier,
}


Ternary_Half_Precision_Floating_Point_Instruction :: struct {
	name: string "fma",
	dtype: Half,
	a: Register,
	b: Register,
	c: Register,
	destination: Register,
	rounding_mod: bool,
	ftz_mod: bool,
	ooo_mod: bool,
	saturation_mod: Saturation_Modifier,
}


// Comparison and Selection Instructions

Comparison_Instruction :: struct {
	name: string "set, setp",
	source_dtype: Any,
	destination_dtype: Any,
	bool_op: Boolean_Operator,
	comp_op: Comparison_Operator,
	lhs: Register,
	rhs: Register,
	predicate: Register,
	destination: Register,
	ftz_mod: bool,
}


Selection_Instruction :: struct {
	name: string "selp, slct",
	dtype: Any,
	lhs: Register,
	rhs: Register,
	predicate: Register,
	destination: Register,
}


// Half Precision Comparison Instructions

Half_Precision_Comparision_Instruction :: struct {
	name: string "set, setp",
	source_dtype: Any,
	destination_dtype: Any,
	bool_op: Boolean_Operator,
	comp_op: Comparison_Operator,
	lhs: Register,
	rhs: Register,
	predicate: Register,
	destination: Register,
	ftz_mod: bool,
}


// Logic and Shift Instructions

Logic_Instruction :: union {
	Unary_Logic_Instruction,
	Binary_Logic_Instruction,
	Ternary_Logic_Instruction,
}


Shift_Instruction :: union {
	Binary_Shift_Instruction,
	Ternary_Shift_Instruction,
}


Unary_Logic_Instruction :: struct {
	name: string "not, cnot",
	dtype: Any,
	operand: Register,
}


Binary_Logic_Instruction :: struct {
	name: string "and, or, xor",
	dtype: Any,
	lhs: Register,
	rhs: Register,
}


Binary_Shift_Instruction :: struct {
	name: string "shl, shr",
	dtype: Any,
	lhs: Register,
	rhs: Register,
}


Ternary_Logic_Instruction :: struct {
	name: string "lop3",
	dtype: Any,
	a: Register,
	b: Register,
	c: Register,
	bool_op: Boolean_Operator,
}
 

Ternary_Shift_Instruction :: struct {
	name: string "shf",
	dtype: Any,
	a: Register,
	b: Register,
	c: Register,
	mode: Mode,
	direction: Shift_Direction,
}


// Data Movement and Conversion Instructions

Data_Movement_Instruction :: struct {}


Conversion_Instruction :: struct {
	name: string,
	size: Any,
	state_space: State_Space,
}


Texture_Instruction :: struct {}


Surface_Instruction :: struct {}


Control_Flow_Instruction :: struct {}


Parallel_Synchronization_Instruction :: struct {}


Communication_Instruction :: struct {}


WMMA_Instruction :: struct {}


WGMMA_Instruction :: struct {}


Stack_Manipulation_Instruction :: struct {}


Video_Instruction :: struct {}


Misc_Instruction :: struct {}


Any :: union {
	Integer,
	Float,
	Half,
	Bits,
	Bool,
}


Float :: enum {
	F32,
	F64,
}


Half :: enum {
	F16,
	BF16,
	F16x2,
	BF16x2,
}


Bool :: enum {
	Pred,
}


Bits :: enum {
	B8,
	B16,
	B32,
	B64,
	B128,
}


Bits_And_Ints :: union {
	Integer,
	Bits,
}


Mode :: enum {
	Hi,
	Lo,
	Wide,
	Clamp,
	Wrap,
}


Saturation_Modifier :: enum {
	Sat,
	Relu,
}


Rounding_Modifier :: enum {
	Approx,
	Rn,
	Rz,
	Rm,
	Rp,
}


Magnitude_Modifier :: enum {
	NaN,
	XorsignAbs
}


Testp_Op :: enum {
	Finite,
	Infinite,
	Number,
	Notanumber,
	Normal,
	Subnormal,
}


Comparison_Operator :: enum {
	EQ,
	NE,
	LT,
	LE,
	GT,
	GE,
	LO,
	LS,
	HI,
	HS,
	EQU,
	NEU,
	LTU,
	LEU,
	GTU,
	GEU,
	NUM,
	NAN,
}


Boolean_Operator :: enum {
	AND,
	OR,
	XOR,
}

Shift_Direction :: enum {
	Left,
	Right,
}


Memory_Store_Cache_Operator :: enum {
	CA,
	CG,
	CS,
	LU,
	CV,
}


Memory_Load_Cache_Operator :: enum {
	WB,
	CG,
	CS,
	WT,
}


Cache_Eviction_Priority_Hints :: enum {
	Evict_Normal,
	Evict_First,
	Evict_Last,
	Evict_Unchanged,
	Evict_Allocate,
}


State_Space :: enum {
	Const,
	Global,
	Local,
	Shared,
}

