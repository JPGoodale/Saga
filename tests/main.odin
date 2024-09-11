package saga_tests
import "core:fmt"
import "core:math"
import rt "../runtime"


main :: proc() {
    x: f32 = 9
    y := math.exp(x)
    fmt.println(y)
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


softmax :: proc(x: [$N]f32) -> (y: [N]f32) {
	numerator: [N]f32
	denominator: f32
	for value, idx in x {
		numerator[idx] = math.exp(x[idx])
		denominator += math.exp(x[idx])
	}
	for value, idx in numerator {
		y[idx] = numerator[idx] / denominator
	}		
	return
}
