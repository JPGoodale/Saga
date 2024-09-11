package saga_runtime


Grid_Layout :: struct {
    x: u32,
    y: u32,
    z: u32
}


Kernel_Operand :: struct {
    data:               rawptr,
    size:               uint,
    offset:             uint,
    n_elem:             uint,
    elem_type:          typeid,
    is_output:          bool,
    is_push_constant:   bool
}


create_kernel_input :: proc(data: ^[$N]$T, offset: uint = 0) -> (operand: Kernel_Operand) {
    operand = Kernel_Operand {
        data                = rawptr(data), 
        size                = N * size_of(T), 
        offset              = offset, 
        n_elem              = N, 
        elem_type           = T, 
        is_output           = false, 
        is_push_constant    = false
    } 
    return
}


create_kernel_output :: proc(data: ^[$N]$T, offset: uint = 0) -> (operand: Kernel_Operand) {
    operand = Kernel_Operand {
        data                = nil, 
        size                = N * size_of(T), 
        offset              = offset, 
        n_elem              = N, 
        elem_type           = T, 
        is_output           = true, 
        is_push_constant    = false
    } 
    return
}

// For now only used for scalar values
create_push_constant :: proc(data: ^[1]$T, offset: uint = 0) -> (operand: Kernel_Operand) {
    operand = Kernel_Operand {
        data                = rawptr(data), 
        size                = size_of(T), 
        offset              = offset, 
        n_elem              = 1, 
        elem_type           = T, 
        is_output           = false, 
        is_push_constant    = true, 
    } 
    return
}

