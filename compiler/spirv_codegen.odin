package saga_compiler
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:c/libc"
import "core:path/filepath"
import rt "../runtime"

// For better readability
split               :: strings.split
split_n             :: strings.split_n
count               :: strings.count
join                :: strings.join
remove_all          :: strings.remove_all
contains            :: strings.contains
clone_to_cstring    :: strings.clone_to_cstring
atoi                :: strconv.atoi


Generic_Spirv_Node :: struct {
    instruction:    string,
    result:         string,
    operands:       [dynamic]string
}


contains_at :: proc(s, substr: string) -> (res: bool, idx: int) {
    idx = strings.index(s, substr)
    res = idx >= 0
    return
}


write_to_file :: proc(file_handle: os.Handle, content: string) {
    contents            := fmt.tprintf("%s\n", content)
    bytes_written, err  := os.write(file_handle, transmute([]byte)contents)
    if err != 0 do fmt.println("Error writing to file:", err)
}


generate_spirv_instruction:: proc(file_handle: os.Handle, ast_node: Instruction) {
    generic_node: Generic_Spirv_Node
    #partial switch n in ast_node {
    case OpReturn, OpFunctionEnd:
        s:  string = fmt.aprintln(n)
        ss: []string = strings.split(s, "{")
        s = ss[0]
        write_to_file(file_handle, s)
    case: 
        s:  string = fmt.aprintln(n)
        ss: []string = strings.split(s, "}")

        s   = ss[0]
        ss  = split(s, "{")
        generic_node.instruction = ss[0]
        s   = ss[1]

        found, idx := contains_at(s, "[")
        if found {
            s, _ = remove_all(s, "[")
            s, _ = remove_all(s, "]")
            comma_count := count(s[:idx], ",")
            ss = split_n(s, ",", comma_count+1)
        }
        else { ss  = split(s, ",") }
        
        if contains(ss[0], "result") {
            result_string := split(ss[0], "result = ")[1]
            generic_node.result = split(result_string, "\"")[1]
            ss = ss[1:]
        }
        for s in ss { 
            _ss := split(s, "= ")
            op_string: string 
            if contains(_ss[1], "\"") {
                if contains(_ss[0], "name") {
                    op_string = _ss[1]
                }
                else {
                    op_string, _ = remove_all(_ss[1], "\"")
                }
                op_string, _ = remove_all(op_string, ",")
            }
            else {
                op_string = _ss[1]
                op_string, _ = remove_all(op_string, ",")
            }
            append(&generic_node.operands, op_string)
        }

        instruction_line: [dynamic]string
        if generic_node.result != "" {
            result_expr, err := join({generic_node.result, "="}, " ")
            append(&instruction_line, result_expr)
        }
        append(&instruction_line, generic_node.instruction)
        for op in generic_node.operands {
            append(&instruction_line, op)
        }
        final_instruction_line := join(instruction_line[:], " ")
        write_to_file(file_handle, final_instruction_line)
    }
}


generate_spirv :: proc(ast: [dynamic]AST_Node, output_dir: string) -> (binary_file: string, grid_layout: rt.Grid_Layout) {
    ctx: Ctx
    for node in ast do parse_node(&ctx, node)
    grid_layout = rt.Grid_Layout {
        u32(atoi(ctx.grid_layout.x)), 
        u32(atoi(ctx.grid_layout.y)), 
        u32(atoi(ctx.grid_layout.z))
    }

    asm_file := filepath.join([]string{output_dir, fmt.tprintf("%s.spvasm", ctx.module_name)})
    o, err := os.open(asm_file, os.O_WRONLY|os.O_CREATE, 0o644)
    if err != 0 {
        fmt.printf("Error opening output file: %v\n", err)
        return
    }
    defer os.close(o)

    os.truncate(asm_file, 0)
    os.seek(o, 0, os.SEEK_END)
    generate_spirv_instruction(o, ctx.capability)
    for extension in ctx.extensions do generate_spirv_instruction(o, extension)
    generate_spirv_instruction(o, ctx.memory_model)
    generate_spirv_instruction(o, ctx.entry_point)
    generate_spirv_instruction(o, ctx.execution_mode)
    for annotaton in ctx.annotations do generate_spirv_instruction(o, annotaton)
    for type in ctx.scalar_types do generate_spirv_instruction(o, type)
    for const in ctx.constants do generate_spirv_instruction(o, const)
    for type in ctx.types do generate_spirv_instruction(o, type)
    for var in ctx.variables do generate_spirv_instruction(o, var)
    generate_spirv_instruction(o, ctx.kernel_function)
    generate_spirv_instruction(o, ctx.kernel_body_label)
    for var in ctx.local_variables do generate_spirv_instruction(o, var)
    generate_spirv_instruction(o, ctx.loads[0])
    for comp in ctx.composites do generate_spirv_instruction(o, comp)
    for chain in ctx.access_chains do generate_spirv_instruction(o, chain)
    for op in ctx.operations do generate_spirv_instruction(o, op)
    generate_spirv_instruction(o, ctx.kernel_return)
    generate_spirv_instruction(o, ctx.kernel_function_end)
    assemble_script := filepath.join({output_dir, "assemble.bat"}) // Need to add a bash script for posix systems
    cmd := strings.clone_to_cstring(fmt.tprintf("%s %s", assemble_script, asm_file))
    libc.system(cmd)
    binary_file = filepath.join({output_dir, fmt.tprintf("%s.spv", ctx.module_name)})
    return
}

