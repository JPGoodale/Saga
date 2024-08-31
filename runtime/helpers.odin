package saga_runtime


fill_f32 :: proc($N: int, value: f32) -> (array: [N]f32) {
    for i in 0..<N do array[i] = value 
    return
}

