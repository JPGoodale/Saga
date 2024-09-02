package saga
import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import "core:c/libc"
import sagac "./compiler"
import rt "./runtime"


main :: proc() {
    context.logger = log.create_console_logger()
    spirv_file := compile()
    run(spirv_file)
    // run()
}


compile :: proc() -> (spirv_file: string) {
    file_stream     := os.stream_from_handle(os.stdin) 
    token_stream    := sagac.lex(file_stream)
    // sagac.print_tokens(token_stream)
    ast, err        := sagac.parse(token_stream)
    // sagac.print_ast(ast)
    // sagac.walk_ast(ast)
    spirv_file      = sagac.generate_spirv(ast)
    return
}


run :: proc(spirv_file: string = "./glsl_examples/rms_norm.spv") {
    spirv_bytecode, ok := os.read_entire_file(spirv_file)

    input_data  := rt.fill_f32(1024, 9)
    weight_data := rt.fill_f32(1024, 5)
    pc_data: [1]u32 = {1024}

    input   := rt.create_kernel_input(&input_data) 
    weight  := rt.create_kernel_input(&weight_data) 
    output  := rt.create_kernel_output(&input_data)
    n_elem  := rt.create_push_constant(&pc_data)

    // kernel_operands: [3]rt.Kernel_Operand = {output, input, weight}
    kernel_operands: [4]rt.Kernel_Operand = {output, input, weight, n_elem}
    rt.vulkan_launch_kernel(kernel_operands, spirv_bytecode)
}

