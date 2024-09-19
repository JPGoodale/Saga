package saga_runtime
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


Vulkan_Context :: struct {
    instance:                       vk.Instance,
    physical_device:                vk.PhysicalDevice,
    device:                         vk.Device,
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
    compute_queue_family_index:     u32,
    memory_type_index:              u32,
}

vulkan_context_init :: proc(ctx: ^Vulkan_Context) {
    vulkan_init()
    ctx.compute_queue_family_index = 0
    ctx.memory_type_index = 5
}

vulkan_context_destroy :: proc(ctx: ^Vulkan_Context) {
    flags: vk.CommandPoolResetFlags
    vk.ResetCommandPool(ctx.device, ctx.command_pool, flags)
    vk.DestroyFence(ctx.device, ctx.fence, nil)
    vk.DestroyDescriptorSetLayout(ctx.device, ctx.descriptor_set_layout, nil)
    vk.DestroyPipelineLayout(ctx.device, ctx.pipeline_layout, nil)
    vk.DestroyPipelineCache(ctx.device, ctx.pipeline_cache, nil)
    vk.DestroyShaderModule(ctx.device, ctx.shader_module, nil)
    vk.DestroyPipeline(ctx.device, ctx.compute_pipeline, nil)
    vk.DestroyDescriptorPool(ctx.device, ctx.descriptor_pool, nil)
    vk.DestroyCommandPool(ctx.device, ctx.command_pool, nil)
    vk.DestroyQueryPool(ctx.device, ctx.timestamp_query_pool, nil)
    for buffer, idx in ctx.buffers {
        vk.FreeMemory(ctx.device, ctx.device_memory[idx], nil)
        vk.DestroyBuffer(ctx.device, buffer, nil)
    }
    vk.DestroyDevice(ctx.device, nil)
    vk.DestroyInstance(ctx.instance, nil)
}


vulkan_create_instance :: proc(ctx: ^Vulkan_Context) {
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


vulkan_create_physical_device :: proc(ctx: ^Vulkan_Context) {
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


vulkan_create_logical_device :: proc(ctx: ^Vulkan_Context) {
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



vulkan_allocate_memory :: proc(ctx: ^Vulkan_Context, kernel_operands: [$N]Kernel_Operand) {
    when VERBOSE_MODE {
        memory_properties: vk.PhysicalDeviceMemoryProperties
        vk.GetPhysicalDeviceMemoryProperties(ctx.physical_device, &memory_properties)

        for idx: u32 = 0; idx < memory_properties.memoryTypeCount; idx+=1 {
            fmt.printf("\n")
            fmt.printf("Memory Type %v:\n", idx)
            memory_type := memory_properties.memoryTypes[idx]
            fmt.printf("%v\n", memory_type)
            memory_heap_size := memory_properties.memoryHeaps[memory_type.heapIndex].size
            fmt.printf("%v GB\n", (memory_heap_size / 1024 / 1024 / 1024))
        }
    }

    for operand in kernel_operands {
        switch {
        case operand.is_push_constant:
            range := vk.PushConstantRange {
                stageFlags  = {.COMPUTE}, 
                offset      = auto_cast(operand.offset), 
                size        = auto_cast(operand.size)
            }
            constant := Push_Constant {range, operand.data}
            append(&ctx.push_constant_ranges, range)
            append(&ctx.push_constants, constant)
        case: 
            buffer_size     := vk.DeviceSize(operand.size)
            buffer_offset   := vk.DeviceSize(operand.offset) // Need to understand what to do with this

            buffer_create_info := vk.BufferCreateInfo {
                sType                    = .BUFFER_CREATE_INFO,
                size                     = buffer_size,
                usage                    = {.STORAGE_BUFFER},
                sharingMode              = .EXCLUSIVE,
                queueFamilyIndexCount    = 1,
                pQueueFamilyIndices      = &ctx.compute_queue_family_index,
            }

            buffer: vk.Buffer
            vk.CreateBuffer(ctx.device, &buffer_create_info, nil, &buffer)

            buffer_memory_requirements: vk.MemoryRequirements
            vk.GetBufferMemoryRequirements(ctx.device, buffer, &buffer_memory_requirements)

            buffer_memory_allocate_info := vk.MemoryAllocateInfo {
                sType           = .MEMORY_ALLOCATE_INFO,
                allocationSize  = buffer_memory_requirements.size,
                memoryTypeIndex = ctx.memory_type_index
            }

            buffer_memory: vk.DeviceMemory
            vulkan_check(vk.AllocateMemory(ctx.device, &buffer_memory_allocate_info, nil, &buffer_memory))
            
            if !operand.is_output {
                buffer_ptr: rawptr
                vulkan_check(vk.MapMemory(ctx.device, buffer_memory, buffer_offset, buffer_size, nil, &buffer_ptr))
                c.memcpy(buffer_ptr, operand.data, operand.size)
                vk.UnmapMemory(ctx.device, buffer_memory)
            }

            vk.BindBufferMemory(ctx.device, buffer, buffer_memory, buffer_offset)

            append(&ctx.device_memory, buffer_memory)
            append(&ctx.buffers, buffer)
            append(&ctx.buffer_offsets, buffer_offset)
            append(&ctx.buffer_sizes, buffer_size)
        }
    }
}


vulkan_create_shader_module :: proc(ctx: ^Vulkan_Context, spirv_bytecode: []byte) {
    create_info := vk.ShaderModuleCreateInfo {
        sType     = .SHADER_MODULE_CREATE_INFO,
        codeSize  = len(spirv_bytecode),
        pCode     = cast(^u32)raw_data(spirv_bytecode)
    }

    vulkan_check(vk.CreateShaderModule(ctx.device, &create_info, nil, &ctx.shader_module))
}


vulkan_create_descriptor_set_layout :: proc(ctx: ^Vulkan_Context) {
    bindings: [dynamic]vk.DescriptorSetLayoutBinding

    for buffer, idx in ctx.buffers {
        binding := vk.DescriptorSetLayoutBinding {
            binding          = auto_cast(idx),
            descriptorType   = .STORAGE_BUFFER,
            descriptorCount  = 1,
            stageFlags       = {.COMPUTE}
        }
        append(&bindings, binding)
    }

    create_info := vk.DescriptorSetLayoutCreateInfo {
        sType         = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        pBindings     = raw_data(bindings),
        bindingCount  = auto_cast(len(bindings))
    }

    vulkan_check(vk.CreateDescriptorSetLayout(ctx.device, &create_info, nil, &ctx.descriptor_set_layout))
}


vulkan_create_pipeline_layout :: proc(ctx: ^Vulkan_Context) {
    create_info := vk.PipelineLayoutCreateInfo {
        sType                   = .PIPELINE_LAYOUT_CREATE_INFO,
        pSetLayouts             = &ctx.descriptor_set_layout,
        setLayoutCount          = 1,
        pushConstantRangeCount  = auto_cast(len(ctx.push_constant_ranges)),
        pPushConstantRanges     = raw_data(ctx.push_constant_ranges)
    }

    vulkan_check(vk.CreatePipelineLayout(ctx.device, &create_info, nil, &ctx.pipeline_layout))
}


vulkan_create_pipeline_cache :: proc(ctx: ^Vulkan_Context) {
    create_info := vk.PipelineCacheCreateInfo {
        sType = .PIPELINE_CACHE_CREATE_INFO
    }

    vk.CreatePipelineCache(ctx.device, &create_info, nil, &ctx.pipeline_cache)
}


vulkan_create_compute_pipeline :: proc(ctx: ^Vulkan_Context) {
    shader_stage_create_info := vk.PipelineShaderStageCreateInfo {
        sType   = .PIPELINE_SHADER_STAGE_CREATE_INFO,
        stage   = {.COMPUTE},
        module  = ctx.shader_module,
        pName   = "main"
    }

    create_info := vk.ComputePipelineCreateInfo {
        sType  = .COMPUTE_PIPELINE_CREATE_INFO,
        stage  = shader_stage_create_info,
        layout = ctx.pipeline_layout
    }

    create_info_count: u32 = 1
    vulkan_check(vk.CreateComputePipelines(ctx.device, ctx.pipeline_cache, create_info_count, &create_info, nil, &ctx.compute_pipeline))
}


vulkan_create_descriptor_pool :: proc(ctx: ^Vulkan_Context) {
    pool_size := vk.DescriptorPoolSize {
        type            = .STORAGE_BUFFER,
        descriptorCount = auto_cast(len(ctx.buffers))
    }
    create_info := vk.DescriptorPoolCreateInfo {
        sType       = .DESCRIPTOR_POOL_CREATE_INFO,
        maxSets     = 1,
        pPoolSizes  = &pool_size
    }

    vulkan_check(vk.CreateDescriptorPool(ctx.device, &create_info, nil, &ctx.descriptor_pool))
}


vulkan_allocate_descriptor_set :: proc(ctx: ^Vulkan_Context) {
    allocate_info := vk.DescriptorSetAllocateInfo {
        sType                 = .DESCRIPTOR_SET_ALLOCATE_INFO,
        descriptorPool        = ctx.descriptor_pool,
        descriptorSetCount    = 1,
        pSetLayouts           = &ctx.descriptor_set_layout
    }

    vulkan_check(vk.AllocateDescriptorSets(ctx.device, &allocate_info, &ctx.descriptor_set))
}


vulkan_update_desciptor_sets :: proc(ctx: ^Vulkan_Context) {
    buffer_infos:   [dynamic]vk.DescriptorBufferInfo
    write_sets:     [dynamic]vk.WriteDescriptorSet
    set_count:      u32

    for buffer, idx in ctx.buffers {
        buffer_info := vk.DescriptorBufferInfo {
            buffer  = buffer,
            offset  = ctx.buffer_offsets[idx],
            range   = ctx.buffer_sizes[idx]
        }
        append(&buffer_infos, buffer_info)
        write_set := vk.WriteDescriptorSet {
            sType            = .WRITE_DESCRIPTOR_SET,
            dstSet           = ctx.descriptor_set,
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
    vk.UpdateDescriptorSets(ctx.device, set_count, raw_data(write_sets), copy_count, nil)
}


vulkan_create_command_pool :: proc(ctx: ^Vulkan_Context) {
    create_info := vk.CommandPoolCreateInfo {
        sType              = .COMMAND_POOL_CREATE_INFO,
        queueFamilyIndex   = ctx.compute_queue_family_index
    }

    vulkan_check(vk.CreateCommandPool(ctx.device, &create_info, nil, &ctx.command_pool))
}


vulkan_create_timestamp_query_pool :: proc(ctx: ^Vulkan_Context) {
    create_info := vk.QueryPoolCreateInfo{
        sType       = .QUERY_POOL_CREATE_INFO,
        queryType   = .TIMESTAMP,
        queryCount  = 2,
    }
    
    vulkan_check(vk.CreateQueryPool(ctx.device, &create_info, nil, &ctx.timestamp_query_pool))
}


vulkan_allocate_command_buffer :: proc(ctx: ^Vulkan_Context) {
    allocate_info := vk.CommandBufferAllocateInfo {
        sType                 = .COMMAND_BUFFER_ALLOCATE_INFO,
        commandPool           = ctx.command_pool,
        level                 = .PRIMARY,
        commandBufferCount    = 1 // What determines this number exactly?
    }

    vulkan_check(vk.AllocateCommandBuffers(ctx.device, &allocate_info, &ctx.command_buffer))
}


vulkan_begin_command_buffer :: proc(ctx: ^Vulkan_Context) {
    begin_info := vk.CommandBufferBeginInfo {
        sType = .COMMAND_BUFFER_BEGIN_INFO,
        flags = {.ONE_TIME_SUBMIT}
    }

    vulkan_check(vk.BeginCommandBuffer(ctx.command_buffer, &begin_info))

    when PROFILE {
        vk.CmdResetQueryPool(ctx.command_buffer, ctx.timestamp_query_pool, 0, 2)
    }
}


vulkan_command_push_constants :: proc(ctx: ^Vulkan_Context) {
    for pc in ctx.push_constants {
        vk.CmdPushConstants(ctx.command_buffer, ctx.pipeline_layout, {.COMPUTE}, pc.range.offset, pc.range.size, pc.data)
    }
}


vulkan_bind_pipeline_to_cmd_buffer :: proc(ctx: ^Vulkan_Context, bind_point: vk.PipelineBindPoint = .COMPUTE) {
    vk.CmdBindPipeline(ctx.command_buffer, bind_point, ctx.compute_pipeline)
}


vulkan_bind_descriptor_sets_to_cmd_buffer :: proc(
    ctx: ^Vulkan_Context, 
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


vulkan_command_dispatch :: proc(ctx: ^Vulkan_Context, layout: Grid_Layout) {
    when PROFILE { 
        vk.CmdWriteTimestamp(ctx.command_buffer, {.TOP_OF_PIPE}, ctx.timestamp_query_pool, 0)
    }

    vk.CmdDispatch(ctx.command_buffer, layout.x, layout.y, layout.z)

    when PROFILE {
        vk.CmdWriteTimestamp(ctx.command_buffer, {.BOTTOM_OF_PIPE}, ctx.timestamp_query_pool, 1)
    }

    vk.EndCommandBuffer(ctx.command_buffer)
}


vulkan_get_queue :: proc(ctx: ^Vulkan_Context, queue_index: u32 = 0) {
    vk.GetDeviceQueue(ctx.device, ctx.compute_queue_family_index, queue_index, &ctx.queue)
}


vulkan_create_fence :: proc(ctx: ^Vulkan_Context) {
    create_info := vk.FenceCreateInfo {
        sType = .FENCE_CREATE_INFO
    }

    vk.CreateFence(ctx.device, &create_info, nil, &ctx.fence)
}


vulkan_submit_queue :: proc(ctx: ^Vulkan_Context) {
    queue_index: u32 = 0
    vk.GetDeviceQueue(ctx.device, ctx.compute_queue_family_index, queue_index, &ctx.queue)

    submit_info := vk.SubmitInfo {
        sType               = .SUBMIT_INFO,
        waitSemaphoreCount  = 0,
        pWaitSemaphores     = nil,
        pWaitDstStageMask   = nil,
        commandBufferCount  = 1,
        pCommandBuffers     = &ctx.command_buffer
    }

    submit_count: u32 = 1
    vulkan_check(vk.QueueSubmit(ctx.queue, submit_count, &submit_info, ctx.fence))
}


vulkan_wait_for_fences :: proc(ctx: ^Vulkan_Context, fence_count: u32 = 1, wait_all: b32 = true) {
    timeout := math.max(u64)
    vk.WaitForFences(ctx.device, fence_count, &ctx.fence, wait_all, timeout)
}


// Need to make this type generic
vulkan_write_results :: proc(ctx: ^Vulkan_Context, N: uint, idx: int = 0) -> (out_array: [dynamic]f32) {
    out_buffer_ptr: rawptr
    vulkan_check(vk.MapMemory(ctx.device, ctx.device_memory[idx], ctx.buffer_offsets[idx], ctx.buffer_sizes[idx], nil, &out_buffer_ptr))

    out_buffer_data := ([^]f32)(out_buffer_ptr)
    for i: uint = 0; i < N; i+=1 { 
        append(&out_array, out_buffer_data[i])
    }

    vk.UnmapMemory(ctx.device, ctx.device_memory[idx])
    return
}


vulkan_get_timestamp_results :: proc(ctx: ^Vulkan_Context) -> f32 {
    results: [2]u64
    vulkan_check(vk.GetQueryPoolResults(
        ctx.device,
        ctx.timestamp_query_pool,
        0,
        2,
        size_of(results),
        &results[0],
        size_of(u64),
        {.WAIT, ._64}
    ))

    device_properties: vk.PhysicalDeviceProperties
    vk.GetPhysicalDeviceProperties(ctx.physical_device, &device_properties)
    
    timestamp_period := f32(device_properties.limits.timestampPeriod)
    duration_ns := f32(results[1] - results[0]) * timestamp_period
    return duration_ns / 1e6
}


vulkan_launch_kernel :: proc(operands: [$N]Kernel_Operand, layout: Grid_Layout, spirv_bytecode: []byte) -> (output: [dynamic]f32) {
    ctx: Vulkan_Context
    vulkan_context_init(&ctx)
    vulkan_create_instance(&ctx)
    vulkan_create_physical_device(&ctx)
    vulkan_create_logical_device(&ctx)
    vulkan_allocate_memory(&ctx, operands)
    vulkan_create_shader_module(&ctx, spirv_bytecode)
    vulkan_create_descriptor_set_layout(&ctx)
    vulkan_create_pipeline_layout(&ctx)
    vulkan_create_pipeline_cache(&ctx)
    vulkan_create_compute_pipeline(&ctx)
    vulkan_create_descriptor_pool(&ctx)
    vulkan_allocate_descriptor_set(&ctx)
    vulkan_update_desciptor_sets(&ctx)
    vulkan_create_command_pool(&ctx)
    when PROFILE {vulkan_create_timestamp_query_pool(&ctx)}
    vulkan_allocate_command_buffer(&ctx)
    vulkan_begin_command_buffer(&ctx)
    vulkan_command_push_constants(&ctx)
    vulkan_bind_pipeline_to_cmd_buffer(&ctx)
    vulkan_bind_descriptor_sets_to_cmd_buffer(&ctx)
    vulkan_command_dispatch(&ctx, layout)
    vulkan_get_queue(&ctx)
    vulkan_create_fence(&ctx)
    vulkan_submit_queue(&ctx)
    vulkan_wait_for_fences(&ctx)
    output = vulkan_write_results(&ctx, operands[0].n_elem)
    when PROFILE {
        duration_ms := vulkan_get_timestamp_results(&ctx)
        fmt.printf("\n duration in milliseconds: %v \n", duration_ms)
    }
    vulkan_context_destroy(&ctx)
    return
}

