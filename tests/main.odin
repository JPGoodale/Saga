package saga_tests
import "core:fmt"
import "core:math"
import rt "../runtime"


main :: proc() {
    input := rt.fill_f32(256, 5)
    weight := rt.fill_f32(256, 5)
    out := rms_norm(input, weight)
    for i in 0..<256 do fmt.printf("%v\n", out[i])
}


rms_norm :: proc(input: [$N]f32, weight: [N]f32) -> (out: [N]f32,) {
    squared_sum: f32
    for i in 0..<N { 
        squared_sum += input[i] * input[i] 
    }
    squared_sum /= N 
    squared_sum += 1e-5
    squared_sum = 1 / math.sqrt(squared_sum)
    for i in 0..<N {
        out[i] = weight[i] * (squared_sum * input[i])
    }
    return
}

