package saga_compiler
import "core:os"
import "core:log"
import rt "../runtime"


compile :: proc(file_path: string, output_dir: string) -> (spirv_file: string, grid_layout: rt.Grid_Layout) {
    file_handle, err := os.open(file_path, os.O_RDONLY, 0)
    if err != 0 {
        log.errorf("Error opening file: %v\n", err)
        return
    }
    defer os.close(file_handle)
    
    file_stream     := os.stream_from_handle(file_handle)
    token_stream    := lex(file_stream)
    ast, parse_err  := parse(token_stream)

    if parse_err != nil {
        log.errorf("Error parsing file: %v\n", parse_err)
        return
    }
    
    spirv_file, grid_layout = generate_spirv(ast, output_dir)
    return
}
