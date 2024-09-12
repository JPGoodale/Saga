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
    spirv_file, grid_layout := compile()
    run(spirv_file, grid_layout)
    // run()
}


compile :: proc() -> (spirv_file: string, grid_layout: rt.Grid_Layout) {
    file_stream     := os.stream_from_handle(os.stdin) 
    token_stream    := sagac.lex(file_stream)
    // sagac.print_tokens(token_stream)
    ast, err        := sagac.parse(token_stream)
    sagac.print_ast(ast)
    // sagac.walk_ast(ast)
    spirv_file, grid_layout = sagac.generate_spirv(ast)
    return
}


run :: proc(spirv_file: string = "./spirv_files/softmax.spv", grid_layout: rt.Grid_Layout = rt.Grid_Layout{1, 1, 1}) {
    spirv_bytecode, ok := os.read_entire_file(spirv_file)

    input_data  := rt.fill_f32(128, 0)
    weight_data := rt.fill_f32(128, 5)
    // n_elements: [1]u32 = {128}

    input   := rt.create_kernel_input(&input_data) 
    weight  := rt.create_kernel_input(&weight_data) 
    output  := rt.create_kernel_output(&input_data) // Would be nice to write the output directly to this empty buffer
    // n       := rt.create_push_constant(&n_elements)

    kernel_operands: [3]rt.Kernel_Operand = {output, input, weight}
    out := rt.vulkan_launch_kernel(kernel_operands, grid_layout, spirv_bytecode)
    rt.print_results_f32(128, out)
}

