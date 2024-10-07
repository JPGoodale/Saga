package saga
import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import "core:c/libc"
import "core:path/filepath"
import sagac "./compiler"
import rt "./runtime"


compile_spirv_module :: proc(file_path: string, output_dir: string) -> (spirv_file: string, grid_layout: rt.Grid_Layout) {
    using sagac

    file_handle, err := os.open(file_path, os.O_RDONLY, 0)
    if err != 0 {
        log.errorf("Error opening file: %v\n", err)
        return
    }
    defer os.close(file_handle)
    file_stream := os.stream_from_handle(file_handle)

    lexer: Lexer
    lexer_init(&lexer)
    token_stream, lexing_err := lex(&lexer, file_stream)
    print_tokens(token_stream)

    ast, parse_err  := parse(token_stream)
    print_ast(ast)

    if parse_err != nil {
        log.errorf("Error parsing file: %v\n", parse_err)
        return
    }

    spirv_file, grid_layout = generate_spirv(ast, output_dir)
    return
}


main :: proc() {
    context.logger = log.create_console_logger()
    spirv_file, grid_layout := compile_spirv_module("./vec_mul.saga", "./spirv_gen/")

    global_context: rt.Compute_Context
    rt.initialize_global_context(&global_context)
    defer rt.compute_context_destroy(&global_context)

    spirv_bytecode, ok := os.read_entire_file(spirv_file)

    input_data  := rt.fill_f32(1024, 3)
    weight_data := rt.fill_f32(1024, 5)
    n_elements: [1]u32 = 1024

    output  := rt.create_kernel_output(&input_data)
    input   := rt.create_kernel_input(&input_data) 
    weight  := rt.create_kernel_input(&weight_data) 
    n       := rt.create_push_constant(&n_elements)

    operands: [4]rt.Kernel_Operand = {output, input, weight, n}

    kernel_context: rt.Kernel_Context
    rt.initialize_kernel(&global_context, &kernel_context, operands, spirv_bytecode)
    defer rt.kernel_context_destroy(&global_context, &kernel_context)
    
    rt.launch_kernel(&global_context, &kernel_context, grid_layout, profile=true)

    result := rt.write_results(&global_context, &kernel_context, operands[0].n_elem)
    rt.print_results_f32(1024, result)
}

