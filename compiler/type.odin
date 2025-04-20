package saga_compiler

Basic_Kind :: enum {
    U8,
    U16,
    U32,
    U64,
    I8,
    I16,
    I32,
    I64,
    F8,
    F16,
    F32,
    F64,
    Bool,
    Rawptr,
}


Type_Kind :: enum {
    Basic,
    Pointer,
    Tensor,
}


Type :: struct {
    kind: Type_Kind,
    derived: union {
        Basic,
        Pointer,
        Tensor,
    }
} 


Basic :: struct{
    kind: Basic_Kind,
    src: ^Ast_Node,
}


Pointer :: struct{
    kind: Basic_Kind,
    src: ^Ast_Node,
}


Tensor :: struct{
    kind:       Basic_Kind,
    dims:       []int,
    strides:    []int,
    src:        ^Ast_Node,
}


make_basic :: proc(kind: Basic_Kind, src: ^Ast_Node) -> (type: ^Type) {
    type.kind = .Basic
    type.derived = Basic{kind, src}
    return
}

make_pointer :: proc(kind: Basic_Kind, src: ^Ast_Node) -> (type: ^Type) {
    type.kind = .Pointer
    type.derived = Pointer{kind, src}
    return
}

make_tensor :: proc(kind: Basic_Kind, dims, strides: []int, src: ^Ast_Node) -> (type: ^Type) {
    type.kind = .Tensor 
    type.derived = Tensor{kind, dims, strides, src}
    return
}

BASIC_TYPE_MAP := map[string]Basic_Kind{
    "u8"     = .U8,
    "u16"    = .U16,
    "u32"    = .U32,
    "u64"    = .U64,
    "i8"     = .I8,
    "i16"    = .I16,
    "i32"    = .I32,
    "i64"    = .I64,
    "f8"     = .F8,
    "f16"    = .F16,
    "f32"    = .F32,
    "f64"    = .F64,
    "bool"   = .Bool,
    "rawptr" = .Rawptr,
}
