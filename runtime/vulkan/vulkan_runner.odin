package vulkan_runtime
import "core:fmt"
import "core:log"
import "core:math"
import "core:dynlib"
import "base:runtime"
import c "core:c/libc"
import vk "vendor:vulkan"


ENABLE_VALIDATION_LAYERS    :: #config(ENABLE_VALIDATION_LAYERS, true)
VERBOSE_MODE                :: false
PROFILE                     :: true


vulkan_init :: proc() {
    vulkan_lib, loaded := dynlib.load_library("vulkan-1.dll")
    assert(loaded)

    vkGetInstanceProcAddr, found := dynlib.symbol_address(vulkan_lib, "vkGetInstanceProcAddr")
    assert(found)

    vk.load_proc_addresses_global(vkGetInstanceProcAddr)
}


vulkan_messenger_callback :: proc "system" (
	message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
	message_types:    vk.DebugUtilsMessageTypeFlagsEXT,
	callback_data:   ^vk.DebugUtilsMessengerCallbackDataEXT,
	user_data: rawptr,
) -> b32 {
    
        ctx: runtime.Context
	context = ctx

	level: log.Level
	if .ERROR in message_severity {
		level = .Error
	} else if .WARNING in message_severity {
		level = .Warning
	} else if .INFO in message_severity {
		level = .Info
	} else {
		level = .Debug
	}

	log.logf(level, "vulkan[%v]: %s", message_types, callback_data.pMessage)
	return false
}


vulkan_check :: proc(result: vk.Result, loc := #caller_location) {
    #partial switch result {
        case .SUCCESS:
        case .ERROR_OUT_OF_HOST_MEMORY:
        fmt.eprintln("ERROR: Out of host memory.")
        case .ERROR_OUT_OF_DEVICE_MEMORY:
        fmt.eprintln("ERROR: Out of device memory.")
        case .ERROR_INITIALIZATION_FAILED:
        fmt.eprintln("ERROR: Initialization failed.")
        case .ERROR_LAYER_NOT_PRESENT:
        fmt.eprintln("ERROR: Layer not present.")
        case .ERROR_EXTENSION_NOT_PRESENT:
        fmt.eprintln("ERROR: Extension not present.")        
        case .ERROR_INCOMPATIBLE_DRIVER:
        fmt.eprintln("ERROR: Incompatible driver.")
        case:
        fmt.eprintln("ERROR: Unknown error! Yike!")
    }
    if result != .SUCCESS {
        fmt.println("ERROR: vk procedure result was not .SUCCESS")
        fmt.println("Result was instead:", result)
        fmt.println("Error at:\n", loc)
        assert(false)
    }
}


Push_Constant :: struct {
    range:  vk.PushConstantRange,
    data:   rawptr
}


Compute_Context :: struct {
    instance:                       vk.Instance,
    physical_device:                vk.PhysicalDevice,
    device:                         vk.Device,
    compute_queue_family_index:     u32,
    memory_type_index:              u32,
}

compute_context_init :: proc(ctx: ^Compute_Context) {
    vulkan_init()
    ctx.compute_queue_family_index = 0
    ctx.memory_type_index = 5
}

compute_context_destroy :: proc(ctx: ^Compute_Context) {
    vk.DestroyDevice(ctx.device, nil)
    vk.DestroyInstance(ctx.instance, nil)
}


create_instance :: proc(ctx: ^Compute_Context) {
    app_info := vk.ApplicationInfo {
        sType              = .APPLICATION_INFO,
        pApplicationName   = "saga_vulkan_runner",
        applicationVersion = 1,
        engineVersion      = 0,
        apiVersion         = vk.API_VERSION_1_3
    }

    instance_create_info := vk.InstanceCreateInfo {
        sType               = .INSTANCE_CREATE_INFO,
        pApplicationInfo    = &app_info
    }

    extensions: [dynamic]cstring = {}

    when ENABLE_VALIDATION_LAYERS {
            instance_create_info.ppEnabledLayerNames = raw_data([]cstring{"VK_LAYER_KHRONOS_validation"})
            instance_create_info.enabledLayerCount = 1

            append(&extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)

            severity: vk.DebugUtilsMessageSeverityFlagsEXT
            if context.logger.lowest_level <= .Error {
                    severity |= {.ERROR}
            }
            if context.logger.lowest_level <= .Warning {
                    severity |= {.WARNING}
            }
            if context.logger.lowest_level <= .Info {
                    severity |= {.INFO}
            }
            if context.logger.lowest_level <= .Debug {
                    severity |= {.VERBOSE}
            }

            debug_create_info := vk.DebugUtilsMessengerCreateInfoEXT {
                    sType           = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
                    messageSeverity = severity,
                    messageType     = {.GENERAL, .VALIDATION, .PERFORMANCE, .DEVICE_ADDRESS_BINDING},
                    pfnUserCallback = vulkan_messenger_callback,
            }
            instance_create_info.pNext = &debug_create_info
    }

    vulkan_check(vk.CreateInstance(&instance_create_info, nil, &ctx.instance))
    vk.load_proc_addresses_instance(ctx.instance)
}


create_physical_device :: proc(ctx: ^Compute_Context) {
    device_count: u32
    vulkan_check(vk.EnumeratePhysicalDevices(ctx.instance, &device_count, nil))

    physical_devices := make([dynamic]vk.PhysicalDevice, device_count)
    vulkan_check(vk.EnumeratePhysicalDevices(ctx.instance, &device_count, raw_data(physical_devices)))

    when VERBOSE_MODE {
        for device in physical_devices {
            fmt.printf("\n")

            device_props: vk.PhysicalDeviceProperties
            vk.GetPhysicalDeviceProperties(device, &device_props)
            fmt.printf("%s\n", device_props.deviceName)

            device_limits: vk.PhysicalDeviceLimits
            device_limits = device_props.limits

            max_compute_shared_mem := device_limits.maxComputeSharedMemorySize
            fmt.printf("Max Compute Shared Memory Size %v KB\n", max_compute_shared_mem / 1024)

            max_workgroup_size  := device_limits.maxComputeWorkGroupSize
            fmt.printf("Max Compute WorkGroup Size %v\n", max_workgroup_size)

            max_workgroup_count := device_limits.maxComputeWorkGroupCount
            fmt.printf("Max Compute WorkGroup Count %v KB\n", max_workgroup_count)


            subgroup_properties := vk.PhysicalDeviceSubgroupProperties{
                sType = .PHYSICAL_DEVICE_SUBGROUP_PROPERTIES,
                pNext = nil,
            }

            properties2 := vk.PhysicalDeviceProperties2{
                sType = .PHYSICAL_DEVICE_PROPERTIES_2,
                pNext = &subgroup_properties,
            }

            vk.GetPhysicalDeviceProperties2(device, &properties2)

            fmt.printf("Subgroup Size: %d\n", subgroup_properties.subgroupSize)
            fmt.printf("Supported Stages: %v\n", subgroup_properties.supportedStages)
            fmt.printf("Supported Operations: %v\n", subgroup_properties.supportedOperations)
            fmt.printf("Quad Operations In All Stages: %v\n", subgroup_properties.quadOperationsInAllStages)
        }
    }

    ctx.physical_device = physical_devices[0]
}


get_physical_device_memory_properties :: proc(global_ctx: ^Compute_Context) {
    memory_properties: vk.PhysicalDeviceMemoryProperties
    vk.GetPhysicalDeviceMemoryProperties(global_ctx.physical_device, &memory_properties)

    for idx: u32 = 0; idx < memory_properties.memoryTypeCount; idx+=1 {
        fmt.printf("\n")
        fmt.printf("Memory Type %v:\n", idx)
        memory_type := memory_properties.memoryTypes[idx]
        fmt.printf("%v\n", memory_type)
        memory_heap_size := memory_properties.memoryHeaps[memory_type.heapIndex].size
        fmt.printf("%v GB\n", (memory_heap_size / 1024 / 1024 / 1024))
    }
}


create_logical_device :: proc(ctx: ^Compute_Context) {
    when VERBOSE_MODE {
        queue_count: u32    
        vk.GetPhysicalDeviceQueueFamilyProperties(ctx.physical_device, &queue_count, nil)
        queue_family_properties := make([dynamic]vk.QueueFamilyProperties, queue_count)
        vk.GetPhysicalDeviceQueueFamilyProperties(ctx.physical_device, &queue_count, raw_data(queue_family_properties))

        for queue_fam, idx in queue_family_properties {
            fmt.printf("\n")
            fmt.printf("Queue %v:\n", idx)
            fmt.printf("Flags: %v\n", queue_fam.queueFlags)
            fmt.printf("Count: %v\n", queue_fam.queueCount)
        }
    }
 
    queue_priority: f32 = 1
    device_queue_create_info := vk.DeviceQueueCreateInfo {
        sType              = .DEVICE_QUEUE_CREATE_INFO,
        queueFamilyIndex   = ctx.compute_queue_family_index,
        queueCount         = 1,
        pQueuePriorities   = &queue_priority
    }

    device_create_info := vk.DeviceCreateInfo {
        sType                   = .DEVICE_CREATE_INFO,
        queueCreateInfoCount    = 1,
        pQueueCreateInfos       = &device_queue_create_info,
        ppEnabledExtensionNames = raw_data([]cstring{"VK_KHR_shader_subgroup_arithmetic"})
    }

    vulkan_check(vk.CreateDevice(ctx.physical_device, &device_create_info, nil, &ctx.device))
    vk.load_proc_addresses_device(ctx.device)
}


//---------------------------------------------------------------------------------------------------------------------

Kernel_Context :: struct {
    shader_module:                  vk.ShaderModule,
    descriptor_set_layout:          vk.DescriptorSetLayout,
    pipeline_layout:                vk.PipelineLayout,
    pipeline_cache:                 vk.PipelineCache,
    compute_pipeline:               vk.Pipeline,
    descriptor_pool:                vk.DescriptorPool,
    descriptor_set:                 vk.DescriptorSet,
    command_pool:                   vk.CommandPool,
    timestamp_query_pool:           vk.QueryPool,
    command_buffer:                 vk.CommandBuffer,
    queue:                          vk.Queue,
    fence:                          vk.Fence,
    device_memory:                  [dynamic]vk.DeviceMemory,
    buffers:                        [dynamic]vk.Buffer,
    buffer_sizes:                   [dynamic]vk.DeviceSize,
    buffer_offsets:                 [dynamic]vk.DeviceSize,
    push_constant_ranges:           [dynamic]vk.PushConstantRange,
    push_constants:                 [dynamic]Push_Constant,
}

kernel_context_destroy :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    flags: vk.CommandPoolResetFlags
    vk.ResetCommandPool(global_ctx.device, kernel_ctx.command_pool, flags)
    vk.DestroyFence(global_ctx.device, kernel_ctx.fence, nil)
    vk.DestroyDescriptorSetLayout(global_ctx.device, kernel_ctx.descriptor_set_layout, nil)
    vk.DestroyPipelineLayout(global_ctx.device, kernel_ctx.pipeline_layout, nil)
    vk.DestroyPipelineCache(global_ctx.device, kernel_ctx.pipeline_cache, nil)
    vk.DestroyShaderModule(global_ctx.device, kernel_ctx.shader_module, nil)
    vk.DestroyPipeline(global_ctx.device, kernel_ctx.compute_pipeline, nil)
    vk.DestroyDescriptorPool(global_ctx.device, kernel_ctx.descriptor_pool, nil)
    vk.DestroyCommandPool(global_ctx.device, kernel_ctx.command_pool, nil)
    vk.DestroyQueryPool(global_ctx.device, kernel_ctx.timestamp_query_pool, nil)
    for buffer, idx in kernel_ctx.buffers {
        vk.FreeMemory(global_ctx.device, kernel_ctx.device_memory[idx], nil)
        vk.DestroyBuffer(global_ctx.device, buffer, nil)
    }
}


allocate_kernel_memory :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context, kernel_operands: [$N]Kernel_Operand) {
    for operand in kernel_operands {
        switch {
        case operand.is_push_constant:
            range := vk.PushConstantRange {
                stageFlags  = {.COMPUTE}, 
                offset      = auto_cast(operand.offset),
                size        = auto_cast(operand.size)
            }
            constant := Push_Constant {range, operand.data}
            append(&kernel_ctx.push_constant_ranges, range)
            append(&kernel_ctx.push_constants, constant)
        case: 
            buffer_size     := vk.DeviceSize(operand.size)
            buffer_offset   := vk.DeviceSize(operand.offset) // Need to understand what to do with this

            buffer_create_info := vk.BufferCreateInfo {
                sType                    = .BUFFER_CREATE_INFO,
                size                     = buffer_size,
                usage                    = {.STORAGE_BUFFER},
                sharingMode              = .EXCLUSIVE,
                queueFamilyIndexCount    = 1,
                pQueueFamilyIndices      = &global_ctx.compute_queue_family_index,
            }

            buffer: vk.Buffer
            vulkan_check(vk.CreateBuffer(global_ctx.device, &buffer_create_info, nil, &buffer))

            // I think that we might be able to remove this due to its only use being to retrieve the allocation 
            // size, which we can already get from the Kernel_Operand object.. I think.. lol
            buffer_memory_requirements: vk.MemoryRequirements
            vk.GetBufferMemoryRequirements(global_ctx.device, buffer, &buffer_memory_requirements)

            memory_allocate_info := vk.MemoryAllocateInfo {
                sType           = .MEMORY_ALLOCATE_INFO,
                allocationSize  = buffer_memory_requirements.size,
                memoryTypeIndex = global_ctx.memory_type_index
            }

            device_memory: vk.DeviceMemory
            vulkan_check(vk.AllocateMemory(global_ctx.device, &memory_allocate_info, nil, &device_memory))
            
            if !operand.is_output {
                host_memory: rawptr
                vulkan_check(vk.MapMemory(global_ctx.device, device_memory, buffer_offset, buffer_size, nil, &host_memory))
                c.memcpy(host_memory, operand.data, operand.size)
                vk.UnmapMemory(global_ctx.device, device_memory)
            }

            vk.BindBufferMemory(global_ctx.device, buffer, device_memory, buffer_offset)

            append(&kernel_ctx.device_memory, device_memory)
            append(&kernel_ctx.buffers, buffer)
            append(&kernel_ctx.buffer_offsets, buffer_offset)
            append(&kernel_ctx.buffer_sizes, buffer_size)
        }
    }
}


create_shader_module :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context, spirv_bytecode: []byte) {
    create_info := vk.ShaderModuleCreateInfo {
        sType     = .SHADER_MODULE_CREATE_INFO,
        codeSize  = len(spirv_bytecode),
        pCode     = cast(^u32)raw_data(spirv_bytecode)
    }

    vulkan_check(vk.CreateShaderModule(global_ctx.device, &create_info, nil, &kernel_ctx.shader_module))
}


create_descriptor_set_layout :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    bindings: [dynamic]vk.DescriptorSetLayoutBinding

    for buffer, idx in kernel_ctx.buffers {
        binding := vk.DescriptorSetLayoutBinding {
            binding          = u32(idx),
            descriptorType   = .STORAGE_BUFFER,
            descriptorCount  = 1,
            stageFlags       = {.COMPUTE}
        }
        append(&bindings, binding)
    }

    create_info := vk.DescriptorSetLayoutCreateInfo {
        sType         = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        pBindings     = raw_data(bindings),
        bindingCount  = u32(len(bindings))
    }

    vulkan_check(vk.CreateDescriptorSetLayout(global_ctx.device, &create_info, nil, &kernel_ctx.descriptor_set_layout))
}


create_pipeline_layout :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    create_info := vk.PipelineLayoutCreateInfo {
        sType                   = .PIPELINE_LAYOUT_CREATE_INFO,
        pSetLayouts             = &kernel_ctx.descriptor_set_layout,
        setLayoutCount          = 1,
        pushConstantRangeCount  = u32(len(kernel_ctx.push_constant_ranges)),
        pPushConstantRanges     = raw_data(kernel_ctx.push_constant_ranges)
    }

    vulkan_check(vk.CreatePipelineLayout(global_ctx.device, &create_info, nil, &kernel_ctx.pipeline_layout))
}


create_pipeline_cache :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    create_info := vk.PipelineCacheCreateInfo {
        sType = .PIPELINE_CACHE_CREATE_INFO
    }

    vk.CreatePipelineCache(global_ctx.device, &create_info, nil, &kernel_ctx.pipeline_cache)
}


create_compute_pipeline :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    shader_stage_create_info := vk.PipelineShaderStageCreateInfo {
        sType   = .PIPELINE_SHADER_STAGE_CREATE_INFO,
        stage   = {.COMPUTE},
        module  = kernel_ctx.shader_module,
        pName   = "main"
    }

    create_info := vk.ComputePipelineCreateInfo {
        sType  = .COMPUTE_PIPELINE_CREATE_INFO,
        stage  = shader_stage_create_info,
        layout = kernel_ctx.pipeline_layout
    }

    create_info_count: u32 = 1
    vulkan_check(vk.CreateComputePipelines(global_ctx.device, kernel_ctx.pipeline_cache, create_info_count, &create_info, nil, &kernel_ctx.compute_pipeline))
}


create_descriptor_pool :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    pool_size := vk.DescriptorPoolSize {
        type            = .STORAGE_BUFFER,
        descriptorCount = auto_cast(len(kernel_ctx.buffers))
    }
    create_info := vk.DescriptorPoolCreateInfo {
        sType       = .DESCRIPTOR_POOL_CREATE_INFO,
        maxSets     = 1,
        pPoolSizes  = &pool_size
    }

    vulkan_check(vk.CreateDescriptorPool(global_ctx.device, &create_info, nil, &kernel_ctx.descriptor_pool))
}


allocate_descriptor_set :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    allocate_info := vk.DescriptorSetAllocateInfo {
        sType                 = .DESCRIPTOR_SET_ALLOCATE_INFO,
        descriptorPool        = kernel_ctx.descriptor_pool,
        descriptorSetCount    = 1,
        pSetLayouts           = &kernel_ctx.descriptor_set_layout
    }

    vulkan_check(vk.AllocateDescriptorSets(global_ctx.device, &allocate_info, &kernel_ctx.descriptor_set))
}


update_desciptor_sets :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    buffer_infos:   [dynamic]vk.DescriptorBufferInfo
    write_sets:     [dynamic]vk.WriteDescriptorSet
    set_count:      u32

    for buffer, idx in kernel_ctx.buffers {
        buffer_info := vk.DescriptorBufferInfo {
            buffer  = buffer,
            offset  = kernel_ctx.buffer_offsets[idx],
            range   = kernel_ctx.buffer_sizes[idx]
        }
        append(&buffer_infos, buffer_info)
        write_set := vk.WriteDescriptorSet {
            sType            = .WRITE_DESCRIPTOR_SET,
            dstSet           = kernel_ctx.descriptor_set,
            dstBinding       = auto_cast(idx),
            dstArrayElement  = 0,
            descriptorCount  = 1,
            descriptorType   = .STORAGE_BUFFER,
            pImageInfo       = nil,
            pBufferInfo      = &buffer_infos[idx]
        }
        append(&write_sets, write_set)
        set_count += 1
    }

    copy_count: u32 // Not sure what this is for
    vk.UpdateDescriptorSets(global_ctx.device, set_count, raw_data(write_sets), copy_count, nil)
}


//--------------------------------------------------------------------------------------------------------

create_command_pool :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    create_info := vk.CommandPoolCreateInfo {
        sType              = .COMMAND_POOL_CREATE_INFO,
        queueFamilyIndex   = global_ctx.compute_queue_family_index
    }

    vulkan_check(vk.CreateCommandPool(global_ctx.device, &create_info, nil, &kernel_ctx.command_pool))
}


create_timestamp_query_pool :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    create_info := vk.QueryPoolCreateInfo{
        sType       = .QUERY_POOL_CREATE_INFO,
        queryType   = .TIMESTAMP,
        queryCount  = 2,
    }
    
    vulkan_check(vk.CreateQueryPool(global_ctx.device, &create_info, nil, &kernel_ctx.timestamp_query_pool))
}


allocate_command_buffer :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    allocate_info := vk.CommandBufferAllocateInfo {
        sType                 = .COMMAND_BUFFER_ALLOCATE_INFO,
        commandPool           = kernel_ctx.command_pool,
        level                 = .PRIMARY,
        commandBufferCount    = 1 // What determines this number exactly?
    }

    vulkan_check(vk.AllocateCommandBuffers(global_ctx.device, &allocate_info, &kernel_ctx.command_buffer))
}


begin_command_buffer :: proc(ctx: ^Kernel_Context) {
    begin_info := vk.CommandBufferBeginInfo {
        sType = .COMMAND_BUFFER_BEGIN_INFO,
        flags = {.ONE_TIME_SUBMIT}
    }

    vulkan_check(vk.BeginCommandBuffer(ctx.command_buffer, &begin_info))

    when PROFILE {
        vk.CmdResetQueryPool(ctx.command_buffer, ctx.timestamp_query_pool, 0, 2)
    }
}


command_push_constants :: proc(ctx: ^Kernel_Context) {
    for pc in ctx.push_constants {
        vk.CmdPushConstants(ctx.command_buffer, ctx.pipeline_layout, {.COMPUTE}, pc.range.offset, pc.range.size, pc.data)
    }
}


bind_pipeline_to_cmd_buffer :: proc(ctx: ^Kernel_Context, bind_point: vk.PipelineBindPoint = .COMPUTE) {
    vk.CmdBindPipeline(ctx.command_buffer, bind_point, ctx.compute_pipeline)
}


bind_descriptor_sets_to_cmd_buffer :: proc(
    ctx: ^Kernel_Context, 
    bind_point: vk.PipelineBindPoint = .COMPUTE, 
    first_set: u32 = 0, 
    set_count: u32 = 1,
    offset_count: u32 = 0,
) {
    vk.CmdBindDescriptorSets(
        ctx.command_buffer, 
        bind_point, 
        ctx.pipeline_layout, 
        first_set, 
        set_count, 
        &ctx.descriptor_set, 
        offset_count, 
        nil
    )
}


command_dispatch :: proc(ctx: ^Kernel_Context, layout: Grid_Layout) {
    when PROFILE { 
        vk.CmdWriteTimestamp(ctx.command_buffer, {.TOP_OF_PIPE}, ctx.timestamp_query_pool, 0)
    }

    vk.CmdDispatch(ctx.command_buffer, layout.x, layout.y, layout.z)

    when PROFILE {
        vk.CmdWriteTimestamp(ctx.command_buffer, {.BOTTOM_OF_PIPE}, ctx.timestamp_query_pool, 1)
    }

    vk.EndCommandBuffer(ctx.command_buffer)
}


get_queue :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context, queue_index: u32 = 0) {
    vk.GetDeviceQueue(global_ctx.device, global_ctx.compute_queue_family_index, queue_index, &kernel_ctx.queue)
}


create_fence :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    create_info := vk.FenceCreateInfo {
        sType = .FENCE_CREATE_INFO
    }

    vk.CreateFence(global_ctx.device, &create_info, nil, &kernel_ctx.fence)
}


submit_queue :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) {
    queue_index: u32 = 0
    vk.GetDeviceQueue(global_ctx.device, global_ctx.compute_queue_family_index, queue_index, &kernel_ctx.queue)

    submit_info := vk.SubmitInfo {
        sType               = .SUBMIT_INFO,
        waitSemaphoreCount  = 0,
        pWaitSemaphores     = nil,
        pWaitDstStageMask   = nil,
        commandBufferCount  = 1,
        pCommandBuffers     = &kernel_ctx.command_buffer
    }

    submit_count: u32 = 1
    vulkan_check(vk.QueueSubmit(kernel_ctx.queue, submit_count, &submit_info, kernel_ctx.fence))
}


wait_for_fences :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context, fence_count: u32 = 1, wait_all: b32 = true) {
    timeout := math.max(u64)
    vk.WaitForFences(global_ctx.device, fence_count, &kernel_ctx.fence, wait_all, timeout)
}


// Need to make this type generic
write_results :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context, N: uint, idx: int = 0) -> (out_array: [dynamic]f32) {
    out_buffer_ptr: rawptr
    vulkan_check(vk.MapMemory(global_ctx.device, kernel_ctx.device_memory[idx], kernel_ctx.buffer_offsets[idx], kernel_ctx.buffer_sizes[idx], nil, &out_buffer_ptr))

    out_buffer_data := ([^]f32)(out_buffer_ptr)
    for i: uint = 0; i < N; i+=1 { 
        append(&out_array, out_buffer_data[i])
    }

    vk.UnmapMemory(global_ctx.device, kernel_ctx.device_memory[idx])
    return
}


get_timestamp_results :: proc(global_ctx: ^Compute_Context, kernel_ctx: ^Kernel_Context) -> f32 {
    results: [2]u64
    vulkan_check(vk.GetQueryPoolResults(
        global_ctx.device,
        kernel_ctx.timestamp_query_pool,
        0,
        2,
        size_of(results),
        &results[0],
        size_of(u64),
        {.WAIT, ._64}
    ))

    device_properties: vk.PhysicalDeviceProperties
    vk.GetPhysicalDeviceProperties(global_ctx.physical_device, &device_properties)
    
    timestamp_period := f32(device_properties.limits.timestampPeriod)
    duration_ns := f32(results[1] - results[0]) * timestamp_period
    return duration_ns / 1e6
}


initialize_global_context :: proc(ctx: ^Compute_Context) {
    compute_context_init(ctx)
    create_instance(ctx)
    create_physical_device(ctx)
    create_logical_device(ctx)
}


initialize_kernel :: proc(global_ctx: ^Compute_Context, ctx: ^Kernel_Context,  operands: [$N]Kernel_Operand, spirv_bytecode: []byte) {
    allocate_kernel_memory(global_ctx, ctx, operands)
    create_shader_module(global_ctx, ctx, spirv_bytecode)
    create_descriptor_set_layout(global_ctx, ctx)
    create_pipeline_layout(global_ctx, ctx)
    create_pipeline_cache(global_ctx, ctx)
    create_compute_pipeline(global_ctx, ctx)
    create_descriptor_pool(global_ctx, ctx)
    allocate_descriptor_set(global_ctx, ctx)
    update_desciptor_sets(global_ctx, ctx)
}


launch_kernel :: proc(global_ctx: ^Compute_Context, ctx: ^Kernel_Context, layout: Grid_Layout, profile: bool = false) {
    create_command_pool(global_ctx, ctx)
    if profile do create_timestamp_query_pool(global_ctx, ctx)
    allocate_command_buffer(global_ctx, ctx)
    begin_command_buffer(ctx)
    command_push_constants(ctx)
    bind_pipeline_to_cmd_buffer(ctx)
    bind_descriptor_sets_to_cmd_buffer(ctx)
    command_dispatch(ctx, layout)
    get_queue(global_ctx, ctx)
    create_fence(global_ctx, ctx)
    submit_queue(global_ctx, ctx)
    wait_for_fences(global_ctx, ctx)
    if profile {
        duration_ms := get_timestamp_results(global_ctx, ctx)
        fmt.printf("\n duration in milliseconds: %v \n", duration_ms)
    }
}

