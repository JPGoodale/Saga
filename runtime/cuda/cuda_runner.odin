package cuda_runtime
import "core:fmt"


// Just a POC... Many more errors to handle..
check :: proc(result: Result, loc := #caller_location) {
    #partial switch result {
        case .SUCCESS:
        case .ERROR_OUT_OF_MEMORY:
        fmt.eprintln("ERROR: Out of device memory.")
        case:
        fmt.eprintln("ERROR: Unknown error! Yike!")
    }
    if result != .SUCCESS {
        fmt.println("ERROR: cuda procedure result was not .SUCCESS")
        fmt.println("Result was instead:", result)
        fmt.println("Error at:\n", loc)
        assert(false)
    }
}

