package cuda_runtime
import "core:c"


foreign import lib "lib/cuda.lib"


/**
 * Error codes
 */
Result :: enum {
    /**
     * The API call returned with no errors. In the case of query calls, this
     * also means that the operation being queried is complete (see
     * ::cuEventQuery() and ::cuStreamQuery()).
     */
    SUCCESS                              = 0,

    /**
     * This indicates that one or more of the parameters passed to the API call
     * is not within an acceptable range of values.
     */
    ERROR_INVALID_VALUE                  = 1,

    /**
     * The API call failed because it was unable to allocate enough memory to
     * perform the requested operation.
     */
    ERROR_OUT_OF_MEMORY                  = 2,

    /**
     * This indicates that the CUDA driver has not been initialized with
     * ::cuInit() or that initialization has failed.
     */
    ERROR_NOT_INITIALIZED                = 3,

    /**
     * This indicates that the CUDA driver is in the process of shutting down.
     */
    ERROR_DEINITIALIZED                  = 4,

    /**
     * This indicates profiler is not initialized for this run. This can
     * happen when the application is running with external profiling tools
     * like visual profiler.
     */
    ERROR_PROFILER_DISABLED              = 5,

    /**
     * \deprecated
     * This error return is deprecated as of CUDA 5.0. It is no longer an error
     * to attempt to enable/disable the profiling via ::cuProfilerStart or
     * ::cuProfilerStop without initialization.
     */
    ERROR_PROFILER_NOT_INITIALIZED       = 6,

    /**
     * \deprecated
     * This error return is deprecated as of CUDA 5.0. It is no longer an error
     * to call cuProfilerStart() when profiling is already enabled.
     */
    ERROR_PROFILER_ALREADY_STARTED       = 7,

    /**
     * \deprecated
     * This error return is deprecated as of CUDA 5.0. It is no longer an error
     * to call cuProfilerStop() when profiling is already disabled.
     */
    ERROR_PROFILER_ALREADY_STOPPED       = 8,

    /**
     * This indicates that the CUDA driver that the application has loaded is a
     * stub library. Applications that run with the stub rather than a real
     * driver loaded will result in CUDA API returning this error.
     */
    ERROR_STUB_LIBRARY                   = 34,

    /**  
     * This indicates that requested CUDA device is unavailable at the current
     * time. Devices are often unavailable due to use of
     * ::CU_COMPUTEMODE_EXCLUSIVE_PROCESS or ::CU_COMPUTEMODE_PROHIBITED.
     */
    ERROR_DEVICE_UNAVAILABLE            = 46,

    /**
     * This indicates that no CUDA-capable devices were detected by the installed
     * CUDA driver.
     */
    ERROR_NO_DEVICE                      = 100,

    /**
     * This indicates that the device ordinal supplied by the user does not
     * correspond to a valid CUDA device or that the action requested is
     * invalid for the specified device.
     */
    ERROR_INVALID_DEVICE                 = 101,

    /**
     * This error indicates that the Grid license is not applied.
     */
    ERROR_DEVICE_NOT_LICENSED            = 102,

    /**
     * This indicates that the device kernel image is invalid. This can also
     * indicate an invalid CUDA module.
     */
    ERROR_INVALID_IMAGE                  = 200,

    /**
     * This most frequently indicates that there is no context bound to the
     * current thread. This can also be returned if the context passed to an
     * API call is not a valid handle (such as a context that has had
     * ::cuCtxDestroy() invoked on it). This can also be returned if a user
     * mixes different API versions (i.e. 3010 context with 3020 API calls).
     * See ::cuCtxGetApiVersion() for more details.
     */
    ERROR_INVALID_CONTEXT                = 201,

    /**
     * This indicated that the context being supplied as a parameter to the
     * API call was already the active context.
     * \deprecated
     * This error return is deprecated as of CUDA 3.2. It is no longer an
     * error to attempt to push the active context via ::cuCtxPushCurrent().
     */
    ERROR_CONTEXT_ALREADY_CURRENT        = 202,

    /**
     * This indicates that a map or register operation has failed.
     */
    ERROR_MAP_FAILED                     = 205,

    /**
     * This indicates that an unmap or unregister operation has failed.
     */
    ERROR_UNMAP_FAILED                   = 206,

    /**
     * This indicates that the specified array is currently mapped and thus
     * cannot be destroyed.
     */
    ERROR_ARRAY_IS_MAPPED                = 207,

    /**
     * This indicates that the resource is already mapped.
     */
    ERROR_ALREADY_MAPPED                 = 208,

    /**
     * This indicates that there is no kernel image available that is suitable
     * for the device. This can occur when a user specifies code generation
     * options for a particular CUDA source file that do not include the
     * corresponding device configuration.
     */
    ERROR_NO_BINARY_FOR_GPU              = 209,

    /**
     * This indicates that a resource has already been acquired.
     */
    ERROR_ALREADY_ACQUIRED               = 210,

    /**
     * This indicates that a resource is not mapped.
     */
    ERROR_NOT_MAPPED                     = 211,

    /**
     * This indicates that a mapped resource is not available for access as an
     * array.
     */
    ERROR_NOT_MAPPED_AS_ARRAY            = 212,

    /**
     * This indicates that a mapped resource is not available for access as a
     * pointer.
     */
    ERROR_NOT_MAPPED_AS_POINTER          = 213,

    /**
     * This indicates that an uncorrectable ECC error was detected during
     * execution.
     */
    ERROR_ECC_UNCORRECTABLE              = 214,

    /**
     * This indicates that the ::CUlimit passed to the API call is not
     * supported by the active device.
     */
    ERROR_UNSUPPORTED_LIMIT              = 215,

    /**
     * This indicates that the ::CUcontext passed to the API call can
     * only be bound to a single CPU thread at a time but is already
     * bound to a CPU thread.
     */
    ERROR_CONTEXT_ALREADY_IN_USE         = 216,

    /**
     * This indicates that peer access is not supported across the given
     * devices.
     */
    ERROR_PEER_ACCESS_UNSUPPORTED        = 217,

    /**
     * This indicates that a PTX JIT compilation failed.
     */
    ERROR_INVALID_PTX                    = 218,

    /**
     * This indicates an error with OpenGL or DirectX context.
     */
    ERROR_INVALID_GRAPHICS_CONTEXT       = 219,

    /**
    * This indicates that an uncorrectable NVLink error was detected during the
    * execution.
    */
    ERROR_NVLINK_UNCORRECTABLE           = 220,

    /**
    * This indicates that the PTX JIT compiler library was not found.
    */
    ERROR_JIT_COMPILER_NOT_FOUND         = 221,

    /**
     * This indicates that the provided PTX was compiled with an unsupported toolchain.
     */

    ERROR_UNSUPPORTED_PTX_VERSION        = 222,

    /**
     * This indicates that the PTX JIT compilation was disabled.
     */
    ERROR_JIT_COMPILATION_DISABLED       = 223,

    /**
     * This indicates that the ::CUexecAffinityType passed to the API call is not
     * supported by the active device.
     */ 
    ERROR_UNSUPPORTED_EXEC_AFFINITY      = 224,

    /**
     * This indicates that the code to be compiled by the PTX JIT contains
     * unsupported call to cudaDeviceSynchronize.
     */
    ERROR_UNSUPPORTED_DEVSIDE_SYNC       = 225,

    /**
     * This indicates that the device kernel source is invalid. This includes
     * compilation/linker errors encountered in device code or user error.
     */
    ERROR_INVALID_SOURCE                 = 300,

    /**
     * This indicates that the file specified was not found.
     */
    ERROR_FILE_NOT_FOUND                 = 301,

    /**
     * This indicates that a link to a shared object failed to resolve.
     */
    ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND = 302,

    /**
     * This indicates that initialization of a shared object failed.
     */
    ERROR_SHARED_OBJECT_INIT_FAILED      = 303,

    /**
     * This indicates that an OS call failed.
     */
    ERROR_OPERATING_SYSTEM               = 304,

    /**
     * This indicates that a resource handle passed to the API call was not
     * valid. Resource handles are opaque types like ::CUstream and ::CUevent.
     */
    ERROR_INVALID_HANDLE                 = 400,

    /**
     * This indicates that a resource required by the API call is not in a
     * valid state to perform the requested operation.
     */
    ERROR_ILLEGAL_STATE                  = 401,

    /**
     * This indicates that a named symbol was not found. Examples of symbols
     * are global/constant variable names, driver function names, texture names,
     * and surface names.
     */
    ERROR_NOT_FOUND                      = 500,

    /**
     * This indicates that asynchronous operations issued previously have not
     * completed yet. This result is not actually an error, but must be indicated
     * differently than ::_SUCCESS (which indicates completion). Calls that
     * may return this value include ::cuEventQuery() and ::cuStreamQuery().
     */
    ERROR_NOT_READY                      = 600,

    /**
     * While executing a kernel, the device encountered a
     * load or store instruction on an invalid memory address.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_ILLEGAL_ADDRESS                = 700,

    /**
     * This indicates that a launch did not occur because it did not have
     * appropriate resources. This error usually indicates that the user has
     * attempted to pass too many arguments to the device kernel, or the
     * kernel launch specifies too many threads for the kernel's register
     * count. Passing arguments of the wrong size (i.e. a 64-bit pointer
     * when a 32-bit int is expected) is equivalent to passing too many
     * arguments and can also result in this error.
     */
    ERROR_LAUNCH_OUT_OF_RESOURCES        = 701,

    /**
     * This indicates that the device kernel took too long to execute. This can
     * only occur if timeouts are enabled - see the device attribute
     * ::CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT for more information.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_LAUNCH_TIMEOUT                 = 702,

    /**
     * This error indicates a kernel launch that uses an incompatible texturing
     * mode.
     */
    ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  = 703,

    /**
     * This error indicates that a call to ::cuCtxEnablePeerAccess() is
     * trying to re-enable peer access to a context which has already
     * had peer access to it enabled.
     */
    ERROR_PEER_ACCESS_ALREADY_ENABLED    = 704,

    /**
     * This error indicates that ::cuCtxDisablePeerAccess() is
     * trying to disable peer access which has not been enabled yet
     * via ::cuCtxEnablePeerAccess().
     */
    ERROR_PEER_ACCESS_NOT_ENABLED        = 705,

    /**
     * This error indicates that the primary context for the specified device
     * has already been initialized.
     */
    ERROR_PRIMARY_CONTEXT_ACTIVE         = 708,

    /**
     * This error indicates that the context current to the calling thread
     * has been destroyed using ::cuCtxDestroy, or is a primary context which
     * has not yet been initialized.
     */
    ERROR_CONTEXT_IS_DESTROYED           = 709,

    /**
     * A device-side assert triggered during kernel execution. The context
     * cannot be used anymore, and must be destroyed. All existing device
     * memory allocations from this context are invalid and must be
     * reconstructed if the program is to continue using CUDA.
     */
    ERROR_ASSERT                         = 710,

    /**
     * This error indicates that the hardware resources required to enable
     * peer access have been exhausted for one or more of the devices
     * passed to ::cuCtxEnablePeerAccess().
     */
    ERROR_TOO_MANY_PEERS                 = 711,

    /**
     * This error indicates that the memory range passed to ::cuMemHostRegister()
     * has already been registered.
     */
    ERROR_HOST_MEMORY_ALREADY_REGISTERED = 712,

    /**
     * This error indicates that the pointer passed to ::cuMemHostUnregister()
     * does not correspond to any currently registered memory region.
     */
    ERROR_HOST_MEMORY_NOT_REGISTERED     = 713,

    /**
     * While executing a kernel, the device encountered a stack error.
     * This can be due to stack corruption or exceeding the stack size limit.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_HARDWARE_STACKERROR           = 714,

    /**
     * While executing a kernel, the device encountered an illegal instruction.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_ILLEGAL_INSTRUCTION            = 715,

    /**
     * While executing a kernel, the device encountered a load or store instruction
     * on a memory address which is not aligned.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_MISALIGNED_ADDRESS             = 716,

    /**
     * While executing a kernel, the device encountered an instruction
     * which can only operate on memory locations in certain address spaces
     * (global, shared, or local), but was supplied a memory address not
     * belonging to an allowed address space.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_INVALID_ADDRESS_SPACE          = 717,

    /**
     * While executing a kernel, the device program counter wrapped its address space.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_INVALID_PC                     = 718,

    /**
     * An exception occurred on the device while executing a kernel. Common
     * causes include dereferencing an invalid device pointer and accessing
     * out of bounds shared memory. Less common cases can be system specific - more
     * information about these cases can be found in the system specific user guide.
     * This leaves the process in an inconsistent state and any further CUDA work
     * will return the same error. To continue using CUDA, the process must be terminated
     * and relaunched.
     */
    ERROR_LAUNCH_FAILED                  = 719,

    /**
     * This error indicates that the number of blocks launched per grid for a kernel that was
     * launched via either ::cuLaunchCooperativeKernel or ::cuLaunchCooperativeKernelMultiDevice
     * exceeds the maximum number of blocks as allowed by ::cuOccupancyMaxActiveBlocksPerMultiprocessor
     * or ::cuOccupancyMaxActiveBlocksPerMultiprocessorWithFlags times the number of multiprocessors
     * as specified by the device attribute ::CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT.
     */
    ERROR_COOPERATIVE_LAUNCH_TOO_LARGE   = 720,

    /**
     * This error indicates that the attempted operation is not permitted.
     */
    ERROR_NOT_PERMITTED                  = 800,

    /**
     * This error indicates that the attempted operation is not supported
     * on the current system or device.
     */
    ERROR_NOT_SUPPORTED                  = 801,

    /**
     * This error indicates that the system is not yet ready to start any CUDA
     * work.  To continue using CUDA, verify the system configuration is in a
     * valid state and all required driver daemons are actively running.
     * More information about this error can be found in the system specific
     * user guide.
     */
    ERROR_SYSTEM_NOT_READY               = 802,

    /**
     * This error indicates that there is a mismatch between the versions of
     * the display driver and the CUDA driver. Refer to the compatibility documentation
     * for supported versions.
     */
    ERROR_SYSTEM_DRIVER_MISMATCH         = 803,

    /**
     * This error indicates that the system was upgraded to run with forward compatibility
     * but the visible hardware detected by CUDA does not support this configuration.
     * Refer to the compatibility documentation for the supported hardware matrix or ensure
     * that only supported hardware is visible during initialization via the _VISIBLE_DEVICES
     * environment variable.
     */
    ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE = 804,

    /**
     * This error indicates that the MPS client failed to connect to the MPS control daemon or the MPS server.
     */
    ERROR_MPS_CONNECTION_FAILED          = 805,

    /**
     * This error indicates that the remote procedural call between the MPS server and the MPS client failed.
     */
    ERROR_MPS_RPC_FAILURE                = 806,

    /**
     * This error indicates that the MPS server is not ready to accept new MPS client requests.
     * This error can be returned when the MPS server is in the process of recovering from a fatal failure.
     */
    ERROR_MPS_SERVER_NOT_READY           = 807,

    /**
     * This error indicates that the hardware resources required to create MPS client have been exhausted.
     */
    ERROR_MPS_MAX_CLIENTS_REACHED        = 808,

    /**
     * This error indicates the the hardware resources required to support device connections have been exhausted.
     */
    ERROR_MPS_MAX_CONNECTIONS_REACHED    = 809,

    /**
     * This error indicates that the MPS client has been terminated by the server. To continue using CUDA, the process must be terminated and relaunched.
     */
    ERROR_MPS_CLIENT_TERMINATED          = 810,

    /**
     * This error indicates that the module is using CUDA Dynamic Parallelism, but the current configuration, like MPS, does not support it.
     */
    ERROR_CDP_NOT_SUPPORTED              = 811,

    /**
     * This error indicates that a module contains an unsupported interaction between different versions of CUDA Dynamic Parallelism.
     */
    ERROR_CDP_VERSION_MISMATCH           = 812,

    /**
     * This error indicates that the operation is not permitted when
     * the stream is capturing.
     */
    ERROR_STREAM_CAPTURE_UNSUPPORTED     = 900,

    /**
     * This error indicates that the current capture sequence on the stream
     * has been invalidated due to a previous error.
     */
    ERROR_STREAM_CAPTURE_INVALIDATED     = 901,

    /**
     * This error indicates that the operation would have resulted in a merge
     * of two independent capture sequences.
     */
    ERROR_STREAM_CAPTURE_MERGE           = 902,

    /**
     * This error indicates that the capture was not initiated in this stream.
     */
    ERROR_STREAM_CAPTURE_UNMATCHED       = 903,

    /**
     * This error indicates that the capture sequence contains a fork that was
     * not joined to the primary stream.
     */
    ERROR_STREAM_CAPTURE_UNJOINED        = 904,

    /**
     * This error indicates that a dependency would have been created which
     * crosses the capture sequence boundary. Only implicit in-stream ordering
     * dependencies are allowed to cross the boundary.
     */
    ERROR_STREAM_CAPTURE_ISOLATION       = 905,

    /**
     * This error indicates a disallowed implicit dependency on a current capture
     * sequence from cudaStreamLegacy.
     */
    ERROR_STREAM_CAPTURE_IMPLICIT        = 906,

    /**
     * This error indicates that the operation is not permitted on an event which
     * was last recorded in a capturing stream.
     */
    ERROR_CAPTURED_EVENT                 = 907,

    /**
     * A stream capture sequence not initiated with the ::CU_STREAM_CAPTURE_MODE_RELAXED
     * argument to ::cuStreamBeginCapture was passed to ::cuStreamEndCapture in a
     * different thread.
     */
    ERROR_STREAM_CAPTURE_WRONG_THREAD    = 908,

    /**
     * This error indicates that the timeout specified for the wait operation has lapsed.
     */
    ERROR_TIMEOUT                        = 909,

    /**
     * This error indicates that the graph update was not performed because it included 
     * changes which violated constraints specific to instantiated graph update.
     */
    ERROR_GRAPH_EXEC_UPDATE_FAILURE      = 910,

    /**
     * This indicates that an async error has occurred in a device outside of CUDA.
     * If CUDA was waiting for an external device's signal before consuming shared data,
     * the external device signaled an error indicating that the data is not valid for
     * consumption. This leaves the process in an inconsistent state and any further CUDA
     * work will return the same error. To continue using CUDA, the process must be
     * terminated and relaunched.
     */
    ERROR_EXTERNAL_DEVICE               = 911,

    /**
     * Indicates a kernel launch error due to cluster misconfiguration.
     */
    ERROR_INVALID_CLUSTER_SIZE           = 912,

    /**
     * This indicates that an unknown internal error has occurred.
     */
    ERROR_UNKNOWN                        = 999
}


ctx_st		    :: struct {}
mod_st		    :: struct {}
func_st		    :: struct {}
lib_st		    :: struct {}
kern_st		    :: struct {}
array_st	    :: struct {}
mipmappedArray_st   :: struct {}
texref_st	    :: struct {}
surfref_st	    :: struct {}
event_st	    :: struct {}
stream_st	    :: struct {}
graphicsResource_st :: struct {}
extMemory_st	    :: struct {}
extSemaphore_st	    :: struct {}
graph_st	    :: struct {}
graphNode_st	    :: struct {}
graphExec_st	    :: struct {}
memPoolHandle_st    :: struct {}
userObject_st	    :: struct {}


deviceptr	    :: distinct c.ulonglong		// CUDA device pointer
device		    :: distinct c.int			// CUDA device
ctx		    :: distinct ^ctx_st			// CUDA context
module		    :: distinct ^mod_st			// CUDA module
function	    :: distinct ^func_st		// CUDA function
library		    :: distinct ^lib_st			// CUDA library
kernel		    :: distinct ^kern_st		// CUDA kernel
array		    :: distinct ^array_st		// CUDA array
mipmappedArray	    :: distinct ^mipmappedArray_st	// CUDA mipmapped array
texref		    :: distinct ^texref_st		// CUDA texture reference
surfref		    :: distinct ^surfref_st		// CUDA surface reference
event		    :: distinct ^event_st		// CUDA event
stream		    :: distinct ^stream_st		// CUDA stream
graphicsResource    :: distinct ^graphicsResource_st	// CUDA graphics interop resource
externalMemory	    :: distinct ^extMemory_st           // CUDA external memory
externalSemaphore   :: distinct ^extSemaphore_st	// CUDA external semaphore
graph		    :: distinct ^graph_st               // CUDA graph
graphNode	    :: distinct ^graphNode_st           // CUDA graph node
graphExec	    :: distinct ^graphExec_st           // CUDA executable graph
memoryPool	    :: distinct ^memPoolHandle_st       // CUDA memory pool
userObject	    :: distinct ^userObject_st          // CUDA user object for graphs


@(default_calling_convention="c", link_prefix="cu")
foreign lib {

	/**
	 * \brief Initialize the CUDA driver API
	 * Initializes the driver API and must be called before any other function from
	 * the driver API in the current process. Currently, the \p Flags parameter must be 0. If ::cuInit()
	 * has not been called, any function from the driver API will return
	 * ::CUDA_ERROR_NOT_INITIALIZED.
	 *
	 * \param Flags - Initialization flag for CUDA.
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_INVALID_DEVICE,
	 * ::CUDA_ERROR_SYSTEM_DRIVER_MISMATCH,
	 * ::CUDA_ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE
	 * \notefnerr
	 */
	Init :: proc(Flags: c.uint) -> Result ---


	/**
	 * \brief Returns a handle to a compute device
	 *
	 * Returns in \p *device a device handle given an ordinal in the range <b>[0,
	 * ::cuDeviceGetCount()-1]</b>.
	 *
	 * \param device  - Returned device handle
	 * \param ordinal - Device number to get handle for
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_INVALID_DEVICE
	 * \notefnerr
	 *
	 * \sa
	 * ::cuDeviceGetAttribute,
	 * ::cuDeviceGetCount,
	 * ::cuDeviceGetName,
	 * ::cuDeviceGetUuid,
	 * ::cuDeviceGetLuid,
	 * ::cuDeviceTotalMem,
	 * ::cuDeviceGetExecAffinitySupport
	 */
	DeviceGet :: proc(device: ^device, ordinal: c.int) -> Result ---


	/**
	 * \brief Create a CUDA context
	 *
	 * \note In most cases it is recommended to use ::cuDevicePrimaryCtxRetain.
	 *
	 * Creates a new CUDA context and associates it with the calling thread. The
	 * \p flags parameter is described below. The context is created with a usage
	 * count of 1 and the caller of ::cuCtxCreate() must call ::cuCtxDestroy()
	 * when done using the context. If a context is already current to the thread,
	 * it is supplanted by the newly created context and may be restored by a subsequent
	 * call to ::cuCtxPopCurrent().
	 *
	 * The three LSBs of the \p flags parameter can be used to control how the OS
	 * thread, which owns the CUDA context at the time of an API call, interacts
	 * with the OS scheduler when waiting for results from the GPU. Only one of
	 * the scheduling flags can be set when creating a context.
	 *
	 * - ::CU_CTX_SCHED_SPIN: Instruct CUDA to actively spin when waiting for
	 * results from the GPU. This can decrease latency when waiting for the GPU,
	 * but may lower the performance of CPU threads if they are performing work in
	 * parallel with the CUDA thread.
	 *
	 * - ::CU_CTX_SCHED_YIELD: Instruct CUDA to yield its thread when waiting for
	 * results from the GPU. This can increase latency when waiting for the GPU,
	 * but can increase the performance of CPU threads performing work in parallel
	 * with the GPU.
	 *
	 * - ::CU_CTX_SCHED_BLOCKING_SYNC: Instruct CUDA to block the CPU thread on a
	 * synchronization primitive when waiting for the GPU to finish work.
	 *
	 * - ::CU_CTX_BLOCKING_SYNC: Instruct CUDA to block the CPU thread on a
	 * synchronization primitive when waiting for the GPU to finish work. <br>
	 * <b>Deprecated:</b> This flag was deprecated as of CUDA 4.0 and was
	 * replaced with ::CU_CTX_SCHED_BLOCKING_SYNC.
	 *
	 * - ::CU_CTX_SCHED_AUTO: The default value if the \p flags parameter is zero,
	 * uses a heuristic based on the number of active CUDA contexts in the
	 * process \e C and the number of logical processors in the system \e P. If
	 * \e C > \e P, then CUDA will yield to other OS threads when waiting for
	 * the GPU (::CU_CTX_SCHED_YIELD), otherwise CUDA will not yield while
	 * waiting for results and actively spin on the processor (::CU_CTX_SCHED_SPIN).
	 * Additionally, on Tegra devices, ::CU_CTX_SCHED_AUTO uses a heuristic based on
	 * the power profile of the platform and may choose ::CU_CTX_SCHED_BLOCKING_SYNC
	 * for low-powered devices.
	 *
	 * - ::CU_CTX_MAP_HOST: Instruct CUDA to support mapped pinned allocations.
	 * This flag must be set in order to allocate pinned host memory that is
	 * accessible to the GPU.
	 *
	 * - ::CU_CTX_LMEM_RESIZE_TO_MAX: Instruct CUDA to not reduce local memory
	 * after resizing local memory for a kernel. This can prevent thrashing by
	 * local memory allocations when launching many kernels with high local
	 * memory usage at the cost of potentially increased memory usage. <br>
	 * <b>Deprecated:</b> This flag is deprecated and the behavior enabled
	 * by this flag is now the default and cannot be disabled.
	 * Instead, the per-thread stack size can be controlled with ::cuCtxSetLimit().
	 *
	 * - ::CU_CTX_COREDUMP_ENABLE: If GPU coredumps have not been enabled globally
	 * with ::cuCoredumpSetAttributeGlobal or environment variables, this flag can
	 * be set during context creation to instruct CUDA to create a coredump if
	 * this context raises an exception during execution. These environment variables
	 * are described in the CUDA-GDB user guide under the "GPU core dump support"
	 * section.
	 * The initial attributes will be taken from the global attributes at the time of
	 * context creation. The other attributes that control coredump output can be 
	 * modified by calling ::cuCoredumpSetAttribute from the created context after
	 * it becomes current.
	 *
	 * - ::CU_CTX_USER_COREDUMP_ENABLE: If user-triggered GPU coredumps have not
	 * been enabled globally with ::cuCoredumpSetAttributeGlobal or environment 
	 * variables, this flag can be set during context creation to instruct CUDA to
	 * create a coredump if data is written to a certain pipe that is present in the
	 * OS space. These environment variables are described in the CUDA-GDB user
	 * guide under the "GPU core dump support" section.
	 * It is important to note that the pipe name *must* be set with
	 * ::cuCoredumpSetAttributeGlobal before creating the context if this flag is
	 * used. Setting this flag implies that ::CU_CTX_COREDUMP_ENABLE is set.
	 * The initial attributes will be taken from the global attributes at the time of
	 * context creation. The other attributes that control coredump output can be 
	 * modified by calling ::cuCoredumpSetAttribute from the created context after 
	 * it becomes current.
	 * Setting this flag on any context creation is equivalent to setting the 
	 * ::CU_COREDUMP_ENABLE_USER_TRIGGER attribute to \p true globally.
	 *
	 * Context creation will fail with ::CUDA_ERROR_UNKNOWN if the compute mode of
	 * the device is ::CU_COMPUTEMODE_PROHIBITED. The function ::cuDeviceGetAttribute()
	 * can be used with ::CU_DEVICE_ATTRIBUTE_COMPUTE_MODE to determine the
	 * compute mode of the device. The <i>nvidia-smi</i> tool can be used to set
	 * the compute mode for * devices.
	 * Documentation for <i>nvidia-smi</i> can be obtained by passing a
	 * -h option to it.
	 *
	 * \param pctx  - Returned context handle of the new context
	 * \param flags - Context creation flags
	 * \param dev   - Device to create context on
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_DEVICE,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_OUT_OF_MEMORY,
	 * ::CUDA_ERROR_UNKNOWN
	 * \notefnerr
	 *
	 * \sa ::cuCtxDestroy,
	 * ::cuCtxGetApiVersion,
	 * ::cuCtxGetCacheConfig,
	 * ::cuCtxGetDevice,
	 * ::cuCtxGetFlags,
	 * ::cuCtxGetLimit,
	 * ::cuCtxPopCurrent,
	 * ::cuCtxPushCurrent,
	 * ::cuCtxSetCacheConfig,
	 * ::cuCtxSetLimit,
	 * ::cuCoredumpSetAttributeGlobal,
	 * ::cuCoredumpSetAttribute,
	 * ::cuCtxSynchronize
	 */
	CtxCreate :: proc(pctx: ^ctx, flags: c.uint, dev: device) -> Result ---

	/**
	 * \brief Destroy a CUDA context
	 *
	 * Destroys the CUDA context specified by \p ctx.  The context \p ctx will be
	 * destroyed regardless of how many threads it is current to.
	 * It is the responsibility of the calling function to ensure that no API
	 * call issues using \p ctx while ::cuCtxDestroy() is executing.
	 *
	 * Destroys and cleans up all resources associated with the context.
	 * It is the caller's responsibility to ensure that the context or its resources
	 * are not accessed or passed in subsequent API calls and doing so will result in undefined behavior.
	 * These resources include CUDA types such as ::CUmodule, ::CUfunction, ::CUstream, ::CUevent,
	 * ::CUarray, ::CUmipmappedArray, ::CUtexObject, ::CUsurfObject, ::CUtexref, ::CUsurfref,
	 * ::CUgraphicsResource, ::CUlinkState, ::CUexternalMemory and ::CUexternalSemaphore.
	 *
	 * If \p ctx is current to the calling thread then \p ctx will also be
	 * popped from the current thread's context stack (as though ::cuCtxPopCurrent()
	 * were called).  If \p ctx is current to other threads, then \p ctx will
	 * remain current to those threads, and attempting to access \p ctx from
	 * those threads will result in the error ::CUDA_ERROR_CONTEXT_IS_DESTROYED.
	 *
	 * \param ctx - Context to destroy
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE
	 * \notefnerr
	 *
	 * \sa ::cuCtxCreate,
	 * ::cuCtxGetApiVersion,
	 * ::cuCtxGetCacheConfig,
	 * ::cuCtxGetDevice,
	 * ::cuCtxGetFlags,
	 * ::cuCtxGetLimit,
	 * ::cuCtxPopCurrent,
	 * ::cuCtxPushCurrent,
	 * ::cuCtxSetCacheConfig,
	 * ::cuCtxSetLimit,
	 * ::cuCtxSynchronize
	 */
	CtxDestroy :: proc(ctx: ctx) -> Result ---

	/**
	 * \brief Loads a compute module
	 *
	 * Takes a filename \p fname and loads the corresponding module \p module into
	 * the current context. The CUDA driver API does not attempt to lazily
	 * allocate the resources needed by a module; if the memory for functions and
	 * data (constant and global) needed by the module cannot be allocated,
	 * ::cuModuleLoad() fails. The file should be a \e cubin file as output by
	 * \b nvcc, or a \e PTX file either as output by \b nvcc or handwritten, or
	 * a \e fatbin file as output by \b nvcc from toolchain 4.0 or later.
	 *
	 * \param module - Returned module
	 * \param fname  - Filename of module to load
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_INVALID_PTX,
	 * ::CUDA_ERROR_UNSUPPORTED_PTX_VERSION,
	 * ::CUDA_ERROR_NOT_FOUND,
	 * ::CUDA_ERROR_OUT_OF_MEMORY,
	 * ::CUDA_ERROR_FILE_NOT_FOUND,
	 * ::CUDA_ERROR_NO_BINARY_FOR_GPU,
	 * ::CUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND,
	 * ::CUDA_ERROR_SHARED_OBJECT_INIT_FAILED,
	 * ::CUDA_ERROR_JIT_COMPILER_NOT_FOUND
	 * \notefnerr
	 *
	 * \sa ::cuModuleGetFunction,
	 * ::cuModuleGetGlobal,
	 * ::cuModuleGetTexRef,
	 * ::cuModuleLoadData,
	 * ::cuModuleLoadDataEx,
	 * ::cuModuleLoadFatBinary,
	 * ::cuModuleUnload
	 */
	ModuleLoad :: proc(module: ^module, fname: cstring) -> Result ---

	/**
	 * \brief Unloads a module
	 *
	 * Unloads a module \p hmod from the current context.
	 *
	 * \param hmod - Module to unload
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE
	 * \notefnerr
	 * \note_destroy_ub
	 *
	 * \sa ::cuModuleGetFunction,
	 * ::cuModuleGetGlobal,
	 * ::cuModuleGetTexRef,
	 * ::cuModuleLoad,
	 * ::cuModuleLoadData,
	 * ::cuModuleLoadDataEx,
	 * ::cuModuleLoadFatBinary
	 */
	ModuleUnload :: proc(hmod: module) -> Result ---

	/**
	 * \brief Returns a function handle
	 *
	 * Returns in \p *hfunc the handle of the function of name \p name located in
	 * module \p hmod. If no function of that name exists, ::cuModuleGetFunction()
	 * returns ::CUDA_ERROR_NOT_FOUND.
	 *
	 * \param hfunc - Returned function handle
	 * \param hmod  - Module to retrieve function from
	 * \param name  - Name of function to retrieve
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_NOT_FOUND
	 * \notefnerr
	 *
	 * \sa ::cuModuleGetGlobal,
	 * ::cuModuleGetTexRef,
	 * ::cuModuleLoad,
	 * ::cuModuleLoadData,
	 * ::cuModuleLoadDataEx,
	 * ::cuModuleLoadFatBinary,
	 * ::cuModuleUnload
	 */
	ModuleGetFunction :: proc(hfunc: ^function, hmod: module, name: cstring) -> Result ---


	/**
	 * \brief Allocates device memory
	 *
	 * Allocates \p bytesize bytes of linear memory on the device and returns in
	 * \p *dptr a pointer to the allocated memory. The allocated memory is suitably
	 * aligned for any kind of variable. The memory is not cleared. If \p bytesize
	 * is 0, ::cuMemAlloc() returns ::CUDA_ERROR_INVALID_VALUE.
	 *
	 * \param dptr     - Returned device pointer
	 * \param bytesize - Requested allocation size in bytes
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_OUT_OF_MEMORY
	 * \notefnerr
	 *
	 * \sa ::cuArray3DCreate, ::cuArray3DGetDescriptor, ::cuArrayCreate,
	 * ::cuArrayDestroy, ::cuArrayGetDescriptor, ::cuMemAllocHost,
	 * ::cuMemAllocPitch, ::cuMemcpy2D, ::cuMemcpy2DAsync, ::cuMemcpy2DUnaligned,
	 * ::cuMemcpy3D, ::cuMemcpy3DAsync, ::cuMemcpyAtoA, ::cuMemcpyAtoD,
	 * ::cuMemcpyAtoH, ::cuMemcpyAtoHAsync, ::cuMemcpyDtoA, ::cuMemcpyDtoD, ::cuMemcpyDtoDAsync,
	 * ::cuMemcpyDtoH, ::cuMemcpyDtoHAsync, ::cuMemcpyHtoA, ::cuMemcpyHtoAAsync,
	 * ::cuMemcpyHtoD, ::cuMemcpyHtoDAsync, ::cuMemFree, ::cuMemFreeHost,
	 * ::cuMemGetAddressRange, ::cuMemGetInfo, ::cuMemHostAlloc,
	 * ::cuMemHostGetDevicePointer, ::cuMemsetD2D8, ::cuMemsetD2D16,
	 * ::cuMemsetD2D32, ::cuMemsetD8, ::cuMemsetD16, ::cuMemsetD32,
	 * ::cudaMalloc
	 */
	MemAlloc :: proc(dptr: ^deviceptr, bytesize: c.size_t) -> Result ---

	/**
	 * \brief Frees device memory
	 *
	 * Frees the memory space pointed to by \p dptr, which must have been returned
	 * by a previous call to one of the following memory allocation APIs - ::cuMemAlloc(), 
	 * ::cuMemAllocPitch(), ::cuMemAllocManaged(), ::cuMemAllocAsync(), ::cuMemAllocFromPoolAsync()
	 *
	 * Note - This API will not perform any implict synchronization when the pointer was allocated with
	 * ::cuMemAllocAsync or ::cuMemAllocFromPoolAsync. Callers must ensure that all accesses to the
	 * pointer have completed before invoking ::cuMemFree. For best performance and memory reuse, users
	 * should use ::cuMemFreeAsync to free memory allocated via the stream ordered memory allocator.
	 * 
	 * \param dptr - Pointer to memory to free
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE
	 * \notefnerr
	 *
	 * \sa ::cuArray3DCreate, ::cuArray3DGetDescriptor, ::cuArrayCreate,
	 * ::cuArrayDestroy, ::cuArrayGetDescriptor, ::cuMemAlloc, ::cuMemAllocHost,
	 * ::cuMemAllocPitch, ::cuMemAllocManaged, ::cuMemAllocAsync, ::cuMemAllocFromPoolAsync, 
	 * ::cuMemcpy2D, ::cuMemcpy2DAsync, ::cuMemcpy2DUnaligned, ::cuMemcpy3D, ::cuMemcpy3DAsync,
	 * ::cuMemcpyAtoA, ::cuMemcpyAtoD, ::cuMemcpyAtoH, ::cuMemcpyAtoHAsync, ::cuMemcpyDtoA,
	 * ::cuMemcpyDtoD, ::cuMemcpyDtoDAsync, ::cuMemcpyDtoH, ::cuMemcpyDtoHAsync, ::cuMemcpyHtoA,
	 * ::cuMemcpyHtoAAsync, ::cuMemcpyHtoD, ::cuMemcpyHtoDAsync, ::cuMemFreeHost,
	 * ::cuMemGetAddressRange, ::cuMemGetInfo, ::cuMemHostAlloc, ::cuMemFreeAsync,
	 * ::cuMemHostGetDevicePointer, ::cuMemsetD2D8, ::cuMemsetD2D16,
	 * ::cuMemsetD2D32, ::cuMemsetD8, ::cuMemsetD16, ::cuMemsetD32,
	 * ::cudaFree
	 */
	MemFree :: proc(dptr: deviceptr) -> Result ---


	/**
	 * \brief Copies memory from Host to Device
	 *
	 * Copies from host memory to device memory. \p dstDevice and \p srcHost are
	 * the base addresses of the destination and source, respectively. \p ByteCount
	 * specifies the number of bytes to copy.
	 *
	 * \param dstDevice - Destination device pointer
	 * \param srcHost   - Source host pointer
	 * \param ByteCount - Size of memory copy in bytes
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE
	 * \notefnerr
	 * \note_sync
	 * \note_memcpy
	 *
	 * \sa ::cuArray3DCreate, ::cuArray3DGetDescriptor, ::cuArrayCreate,
	 * ::cuArrayDestroy, ::cuArrayGetDescriptor, ::cuMemAlloc, ::cuMemAllocHost,
	 * ::cuMemAllocPitch, ::cuMemcpy2D, ::cuMemcpy2DAsync, ::cuMemcpy2DUnaligned,
	 * ::cuMemcpy3D, ::cuMemcpy3DAsync, ::cuMemcpyAtoA, ::cuMemcpyAtoD,
	 * ::cuMemcpyAtoH, ::cuMemcpyAtoHAsync, ::cuMemcpyDtoA, ::cuMemcpyDtoD, ::cuMemcpyDtoDAsync,
	 * ::cuMemcpyDtoH, ::cuMemcpyDtoHAsync, ::cuMemcpyHtoA, ::cuMemcpyHtoAAsync,
	 * ::cuMemcpyHtoDAsync, ::cuMemFree, ::cuMemFreeHost,
	 * ::cuMemGetAddressRange, ::cuMemGetInfo, ::cuMemHostAlloc,
	 * ::cuMemHostGetDevicePointer, ::cuMemsetD2D8, ::cuMemsetD2D16,
	 * ::cuMemsetD2D32, ::cuMemsetD8, ::cuMemsetD16, ::cuMemsetD32,
	 * ::cudaMemcpy,
	 * ::cudaMemcpyToSymbol
	 */
	MemcpyHtoD :: proc(dstDevice: deviceptr, srcHost: rawptr, ByteCount: c.size_t) -> Result ---


	/**
	 * \brief Copies memory from Device to Host
	 *
	 * Copies from device to host memory. \p dstHost and \p srcDevice specify the
	 * base pointers of the destination and source, respectively. \p ByteCount
	 * specifies the number of bytes to copy.
	 *
	 * \param dstHost   - Destination host pointer
	 * \param srcDevice - Source device pointer
	 * \param ByteCount - Size of memory copy in bytes
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE
	 * \notefnerr
	 * \note_sync
	 * \note_memcpy
	 *
	 * \sa ::cuArray3DCreate, ::cuArray3DGetDescriptor, ::cuArrayCreate,
	 * ::cuArrayDestroy, ::cuArrayGetDescriptor, ::cuMemAlloc, ::cuMemAllocHost,
	 * ::cuMemAllocPitch, ::cuMemcpy2D, ::cuMemcpy2DAsync, ::cuMemcpy2DUnaligned,
	 * ::cuMemcpy3D, ::cuMemcpy3DAsync, ::cuMemcpyAtoA, ::cuMemcpyAtoD,
	 * ::cuMemcpyAtoH, ::cuMemcpyAtoHAsync, ::cuMemcpyDtoA, ::cuMemcpyDtoD, ::cuMemcpyDtoDAsync,
	 * ::cuMemcpyDtoHAsync, ::cuMemcpyHtoA, ::cuMemcpyHtoAAsync,
	 * ::cuMemcpyHtoD, ::cuMemcpyHtoDAsync, ::cuMemFree, ::cuMemFreeHost,
	 * ::cuMemGetAddressRange, ::cuMemGetInfo, ::cuMemHostAlloc,
	 * ::cuMemHostGetDevicePointer, ::cuMemsetD2D8, ::cuMemsetD2D16,
	 * ::cuMemsetD2D32, ::cuMemsetD8, ::cuMemsetD16, ::cuMemsetD32,
	 * ::cudaMemcpy,
	 * ::cudaMemcpyFromSymbol
	 */
	MemcpyDtoH :: proc(dstHost: rawptr, srcDevice: deviceptr, ByteCount: c.size_t) -> Result ---

	/**
	 * \brief Launches a CUDA function ::CUfunction or a CUDA kernel ::CUkernel
	 *
	 * Invokes the function ::CUfunction or the kernel ::CUkernel \p f
	 * on a \p gridDimX x \p gridDimY x \p gridDimZ grid of blocks.
	 * Each block contains \p blockDimX x \p blockDimY x
	 * \p blockDimZ threads.
	 *
	 * \p sharedMemBytes sets the amount of dynamic shared memory that will be
	 * available to each thread block.
	 *
	 * Kernel parameters to \p f can be specified in one of two ways:
	 *
	 * 1) Kernel parameters can be specified via \p kernelParams.  If \p f
	 * has N parameters, then \p kernelParams needs to be an array of N
	 * pointers.  Each of \p kernelParams[0] through \p kernelParams[N-1]
	 * must point to a region of memory from which the actual kernel
	 * parameter will be copied.  The number of kernel parameters and their
	 * offsets and sizes do not need to be specified as that information is
	 * retrieved directly from the kernel's image.
	 *
	 * 2) Kernel parameters can also be packaged by the application into
	 * a single buffer that is passed in via the \p extra parameter.
	 * This places the burden on the application of knowing each kernel
	 * parameter's size and alignment/padding within the buffer.  Here is
	 * an example of using the \p extra parameter in this manner:
	 * \code
		size_t argBufferSize;
		char argBuffer[256];

		// populate argBuffer and argBufferSize

		void *config[] = {
			CU_LAUNCH_PARAM_BUFFER_POINTER, argBuffer,
			CU_LAUNCH_PARAM_BUFFER_SIZE,    &argBufferSize,
			CU_LAUNCH_PARAM_END
		};
		status = cuLaunchKernel(f, gx, gy, gz, bx, by, bz, sh, s, NULL, config);
	 * \endcode
	 *
	 * The \p extra parameter exists to allow ::cuLaunchKernel to take
	 * additional less commonly used arguments.  \p extra specifies a list of
	 * names of extra settings and their corresponding values.  Each extra
	 * setting name is immediately followed by the corresponding value.  The
	 * list must be terminated with either NULL or ::CU_LAUNCH_PARAM_END.
	 *
	 * - ::CU_LAUNCH_PARAM_END, which indicates the end of the \p extra
	 *   array;
	 * - ::CU_LAUNCH_PARAM_BUFFER_POINTER, which specifies that the next
	 *   value in \p extra will be a pointer to a buffer containing all
	 *   the kernel parameters for launching kernel \p f;
	 * - ::CU_LAUNCH_PARAM_BUFFER_SIZE, which specifies that the next
	 *   value in \p extra will be a pointer to a size_t containing the
	 *   size of the buffer specified with ::CU_LAUNCH_PARAM_BUFFER_POINTER;
	 *
	 * The error ::CUDA_ERROR_INVALID_VALUE will be returned if kernel
	 * parameters are specified with both \p kernelParams and \p extra
	 * (i.e. both \p kernelParams and \p extra are non-NULL).
	 *
	 * Calling ::cuLaunchKernel() invalidates the persistent function state
	 * set through the following deprecated APIs:
	 *  ::cuFuncSetBlockShape(),
	 *  ::cuFuncSetSharedSize(),
	 *  ::cuParamSetSize(),
	 *  ::cuParamSeti(),
	 *  ::cuParamSetf(),
	 *  ::cuParamSetv().
	 *
	 * Note that to use ::cuLaunchKernel(), the kernel \p f must either have
	 * been compiled with toolchain version 3.2 or later so that it will
	 * contain kernel parameter information, or have no kernel parameters.
	 * If either of these conditions is not met, then ::cuLaunchKernel() will
	 * return ::CUDA_ERROR_INVALID_IMAGE.
	 *
	 * Note that the API can also be used to launch context-less kernel ::CUkernel
	 * by querying the handle using ::cuLibraryGetKernel() and then passing it
	 * to the API by casting to ::CUfunction. Here, the context to launch
	 * the kernel on will either be taken from the specified stream \p hStream
	 * or the current context in case of NULL stream.
	 *
	 * \param f              - Function ::CUfunction or Kernel ::CUkernel to launch
	 * \param gridDimX       - Width of grid in blocks
	 * \param gridDimY       - Height of grid in blocks
	 * \param gridDimZ       - Depth of grid in blocks
	 * \param blockDimX      - X dimension of each thread block
	 * \param blockDimY      - Y dimension of each thread block
	 * \param blockDimZ      - Z dimension of each thread block
	 * \param sharedMemBytes - Dynamic shared-memory size per thread block in bytes
	 * \param hStream        - Stream identifier
	 * \param kernelParams   - Array of pointers to kernel parameters
	 * \param extra          - Extra options
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_HANDLE,
	 * ::CUDA_ERROR_INVALID_IMAGE,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_LAUNCH_FAILED,
	 * ::CUDA_ERROR_LAUNCH_OUT_OF_RESOURCES,
	 * ::CUDA_ERROR_LAUNCH_TIMEOUT,
	 * ::CUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING,
	 * ::CUDA_ERROR_SHARED_OBJECT_INIT_FAILED,
	 * ::CUDA_ERROR_NOT_FOUND
	 * \note_null_stream
	 * \notefnerr
	 *
	 * \sa ::cuCtxGetCacheConfig,
	 * ::cuCtxSetCacheConfig,
	 * ::cuFuncSetCacheConfig,
	 * ::cuFuncGetAttribute,
	 * ::cudaLaunchKernel,
	 * ::cuLibraryGetKernel,
	 * ::cuKernelSetCacheConfig,
	 * ::cuKernelGetAttribute,
	 * ::cuKernelSetAttribute
	 */
	LaunchKernel :: proc(
		f: function,
		gridDimX: c.uint,
		gridDimY: c.uint,
		gridDimZ: c.uint,
		blockDimX: c.uint,
		blockDimY: c.uint,
		blockDimZ: c.uint,
		sharedMemBytes: c.uint,
		hStream: stream,
		kernelParams: ^rawptr,
		extra: ^rawptr
	) -> Result ---

	/**
	 * \brief Creates an event
	 *
	 * Creates an event *phEvent for the current context with the flags specified via
	 * \p Flags. Valid flags include:
	 * - ::CU_EVENT_DEFAULT: Default event creation flag.
	 * - ::CU_EVENT_BLOCKING_SYNC: Specifies that the created event should use blocking
	 *   synchronization.  A CPU thread that uses ::cuEventSynchronize() to wait on
	 *   an event created with this flag will block until the event has actually
	 *   been recorded.
	 * - ::CU_EVENT_DISABLE_TIMING: Specifies that the created event does not need
	 *   to record timing data.  Events created with this flag specified and
	 *   the ::CU_EVENT_BLOCKING_SYNC flag not specified will provide the best
	 *   performance when used with ::cuStreamWaitEvent() and ::cuEventQuery().
	 * - ::CU_EVENT_INTERPROCESS: Specifies that the created event may be used as an
	 *   interprocess event by ::cuIpcGetEventHandle(). ::CU_EVENT_INTERPROCESS must
	 *   be specified along with ::CU_EVENT_DISABLE_TIMING.
	 *
	 * \param phEvent - Returns newly created event
	 * \param Flags   - Event creation flags
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_VALUE,
	 * ::CUDA_ERROR_OUT_OF_MEMORY
	 * \notefnerr
	 *
	 * \sa
	 * ::cuEventRecord,
	 * ::cuEventQuery,
	 * ::cuEventSynchronize,
	 * ::cuEventDestroy,
	 * ::cuEventElapsedTime,
	 * ::cudaEventCreate,
	 * ::cudaEventCreateWithFlags
	 */
	EventCreate :: proc(phEvent: ^event, Flags: c.uint) -> Result ---


	/**
	 * \brief Records an event
	 *
	 * Captures in \p hEvent the contents of \p hStream at the time of this call.
	 * \p hEvent and \p hStream must be from the same context.
	 * Calls such as ::cuEventQuery() or ::cuStreamWaitEvent() will then
	 * examine or wait for completion of the work that was captured. Uses of
	 * \p hStream after this call do not modify \p hEvent. See note on default
	 * stream behavior for what is captured in the default case.
	 *
	 * ::cuEventRecord() can be called multiple times on the same event and
	 * will overwrite the previously captured state. Other APIs such as
	 * ::cuStreamWaitEvent() use the most recently captured state at the time
	 * of the API call, and are not affected by later calls to
	 * ::cuEventRecord(). Before the first call to ::cuEventRecord(), an
	 * event represents an empty set of work, so for example ::cuEventQuery()
	 * would return ::CUDA_SUCCESS.
	 *
	 * \param hEvent  - Event to record
	 * \param hStream - Stream to record event for
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_HANDLE,
	 * ::CUDA_ERROR_INVALID_VALUE
	 * \note_null_stream
	 * \notefnerr
	 *
	 * \sa ::cuEventCreate,
	 * ::cuEventQuery,
	 * ::cuEventSynchronize,
	 * ::cuStreamWaitEvent,
	 * ::cuEventDestroy,
	 * ::cuEventElapsedTime,
	 * ::cudaEventRecord,
	 * ::cuEventRecordWithFlags
	 */
	EventRecord :: proc(hEvent: event, hStream: stream) -> Result ---

	/**
	 * \brief Waits for an event to complete
	 *
	 * Waits until the completion of all work currently captured in \p hEvent.
	 * See ::cuEventRecord() for details on what is captured by an event.
	 *
	 * Waiting for an event that was created with the ::CU_EVENT_BLOCKING_SYNC
	 * flag will cause the calling CPU thread to block until the event has
	 * been completed by the device.  If the ::CU_EVENT_BLOCKING_SYNC flag has
	 * not been set, then the CPU thread will busy-wait until the event has
	 * been completed by the device.
	 *
	 * \param hEvent - Event to wait for
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_HANDLE
	 * \notefnerr
	 *
	 * \sa ::cuEventCreate,
	 * ::cuEventRecord,
	 * ::cuEventQuery,
	 * ::cuEventDestroy,
	 * ::cuEventElapsedTime,
	 * ::cudaEventSynchronize
	 */
	EventSynchronize :: proc(hEvent: event) -> Result ---

	/**
	 * \brief Computes the elapsed time between two events
	 *
	 * Computes the elapsed time between two events (in milliseconds with a
	 * resolution of around 0.5 microseconds).
	 *
	 * If either event was last recorded in a non-NULL stream, the resulting time
	 * may be greater than expected (even if both used the same stream handle). This
	 * happens because the ::cuEventRecord() operation takes place asynchronously
	 * and there is no guarantee that the measured latency is actually just between
	 * the two events. Any number of other different stream operations could execute
	 * in between the two measured events, thus altering the timing in a significant
	 * way.
	 *
	 * If ::cuEventRecord() has not been called on either event then
	 * ::CUDA_ERROR_INVALID_HANDLE is returned. If ::cuEventRecord() has been called
	 * on both events but one or both of them has not yet been completed (that is,
	 * ::cuEventQuery() would return ::CUDA_ERROR_NOT_READY on at least one of the
	 * events), ::CUDA_ERROR_NOT_READY is returned. If either event was created with
	 * the ::CU_EVENT_DISABLE_TIMING flag, then this function will return
	 * ::CUDA_ERROR_INVALID_HANDLE.
	 *
	 * \param pMilliseconds - Time between \p hStart and \p hEnd in ms
	 * \param hStart        - Starting event
	 * \param hEnd          - Ending event
	 *
	 * \return
	 * ::CUDA_SUCCESS,
	 * ::CUDA_ERROR_DEINITIALIZED,
	 * ::CUDA_ERROR_NOT_INITIALIZED,
	 * ::CUDA_ERROR_INVALID_CONTEXT,
	 * ::CUDA_ERROR_INVALID_HANDLE,
	 * ::CUDA_ERROR_NOT_READY,
	 * ::CUDA_ERROR_UNKNOWN
	 * \notefnerr
	 *
	 * \sa ::cuEventCreate,
	 * ::cuEventRecord,
	 * ::cuEventQuery,
	 * ::cuEventSynchronize,
	 * ::cuEventDestroy,
	 * ::cudaEventElapsedTime
	 */
	EventElapsedTime :: proc(pMilliseconds: [^]c.float, hStart: event, hEnd: event) -> Result ---
}

