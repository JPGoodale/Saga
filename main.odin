package saga
import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import "core:c/libc"
import "core:path/filepath"
import sagac "./compiler"
import sagart "./runtime"


main :: proc() {
    context.logger = log.create_console_logger()
    spirv_file, grid_layout := sagac.compile("./hello.saga", "./spirv_gen/")
}

