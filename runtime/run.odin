package saga_runtime 
import "core:os"
import "core:fmt"
import "./vulkan"
import "./cuda"


vulkan_run :: proc(spirv_file: string, grid_layout: vulkan.Grid_Layout) {
    global_context: vulkan.Compute_Context
    vulkan.initialize_global_context(&global_context)
    defer vulkan.compute_context_destroy(&global_context)

    spirv_bytecode, ok := os.read_entire_file(spirv_file)

    input_data  := fill_f32(1024, 3)
    weight_data := fill_f32(1024, 5)
    n_elements: [1]u32 = 1024

    output  := vulkan.create_kernel_output(&input_data) // Would be nice to write the output data directly to this empty buffer
    input   := vulkan.create_kernel_input(&input_data) 
    weight  := vulkan.create_kernel_input(&weight_data) 
    n       := vulkan.create_push_constant(&n_elements)

    operands: [4]vulkan.Kernel_Operand = {output, input, weight, n}

    kernel_context: vulkan.Kernel_Context
    vulkan.initialize_kernel(&global_context, &kernel_context, operands, spirv_bytecode)
    defer vulkan.kernel_context_destroy(&global_context, &kernel_context)
    
    vulkan.launch_kernel(&global_context, &kernel_context, grid_layout, profile=true)

    result := vulkan.write_results(&global_context, &kernel_context, operands[0].n_elem)
    print_results_f32(1024, result)
}


cuda_run :: proc() {
    N: uint = 1024
    d_out, d_input, d_weight: cuda.deviceptr
    bytes := size_of(f32) * N

    cuda.check(cuda.Init(0))

    device:     cuda.device
    ctx:        cuda.ctx
    module:     cuda.module
    vec_mul:    cuda.function

    cuda.check(cuda.DeviceGet(&device, 0))
    cuda.check(cuda.CtxCreate(&ctx, 0, device))
    defer cuda.CtxDestroy(ctx)

    cuda.check(cuda.ModuleLoad(&module, "C:\\Users\\zoeve\\saga\\runtime\\cuda\\vec_mul.ptx"))
    cuda.check(cuda.ModuleGetFunction(&vec_mul, module, "_Z10vector_mulPfS_S_i"))
    defer cuda.ModuleUnload(module)

    cuda.check(cuda.MemAlloc(&d_out, bytes))
    cuda.check(cuda.MemAlloc(&d_input, bytes))
    cuda.check(cuda.MemAlloc(&d_weight, bytes))
    defer cuda.MemFree(d_out)
    defer cuda.MemFree(d_input)
    defer cuda.MemFree(d_weight)

    h_out       := make([]f32, N)
    h_input     := fill_f32(1024, 3)
    h_weight    := fill_f32(1024, 3)

    defer delete(h_out)

    cuda.check(cuda.MemcpyHtoD(d_input, raw_data(&h_input), bytes))
    cuda.check(cuda.MemcpyHtoD(d_weight, raw_data(&h_weight), bytes))

    args := [?]rawptr{&d_out, &d_input, &d_weight, &N}

    start, stop: cuda.event
    cuda.check(cuda.EventCreate(&start, 0))
    cuda.check(cuda.EventCreate(&stop, 0))
    
    cuda.check(cuda.EventRecord(start, nil))

    cuda.check(cuda.LaunchKernel(vec_mul, 1, 1, 1, 1024, 1, 1, 0, nil, raw_data(&args), nil));

    cuda.check(cuda.EventRecord(stop, nil))
    cuda.check(cuda.EventSynchronize(stop))

    milliseconds: f32 = 0
    cuda.check(cuda.EventElapsedTime(&milliseconds, start, stop))

    fmt.printf("Time: %v ms\n", milliseconds);
    gflops: f64 = (f64(N) / 1e9) / (f64(milliseconds) / 1000.0);
    fmt.printf("GFLOPS: %v\n", gflops);

    cuda.check(cuda.MemcpyDtoH(raw_data(h_out), d_out, bytes));
    _print_results_f32(1024, h_out[:])
}
