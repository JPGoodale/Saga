package saga_compiler 


Register_Id :: distinct string


State_Space :: enum {
	Param,
	Global,
	Local,
}


Mul_Mode :: enum {
	Hi,
	Lo,
	Wide,
}


Unary :: enum {
	Dst,
	Src
}


Binary :: enum {
	Dst,
	Lhs,
	Rhs
}


Trinary :: enum {
	Dst,
	A,
	B,
	C
}


Entry :: struct {
	name:		string,
	visible:	bool,
}


_Param :: struct {
	name: string,
	type: string
}


Kernel_Registers_Declaration :: struct {
	type: string,
	n_instances: int
}


Load :: struct {
	state_space: State_Space,
	type: string,
	registers: [Unary]Register_Id,
}


Store :: struct {
	state_space: State_Space,
	type: string,
	registers: [Unary]Register_Id,
}


Move :: struct {
	type: string,
	registers: [Unary]Register_Id,
}


Branch :: struct {
	name: string,
	register: Register
}


Convert :: struct {
	state_space:	_State_Space,
	type:			string,
	registers:		[Unary]Register_Id,
}


Add :: struct {
	type: string,
	registers: [Unary]Register_Id,
}


Mul :: struct {
	mode: Mode,
	type: string,
	register_a: Register,
	register_b: Register,
	register_c: Register,
}


Mad :: struct {
	mode: Mode,
	type: string,
	register_a: Register,
	register_b: Register,
	register_c: Register,
	register_d: Register,
}

