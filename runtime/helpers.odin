package saga_runtime
import "core:fmt"


fill_f32 :: proc($N: int, value: f32) -> (array: [N]f32) {
    for i in 0..<N do array[i] = value 
    return
}


arrange_f32 :: proc($N: int, start, stop: int) -> (array: [N]f32) {
    for i in 0..<N do array[i] = f32(i)
    return
}


print_results_f32 :: proc(N: int, out: [dynamic]f32) {
    for i:=0; i < N; i+=1 do fmt.printf("%v ", out[i]) 
}

