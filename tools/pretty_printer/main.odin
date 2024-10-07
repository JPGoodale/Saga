package pretty_printer
import "core:fmt"


main :: proc() {}


// ANSI color codes
RESET      :: "\033[0m"
BLACK      :: "\033[30m"
RED        :: "\033[31m"
GREEN      :: "\033[32m"
YELLOW     :: "\033[33m"
BLUE       :: "\033[34m"
MAGENTA    :: "\033[35m"
CYAN       :: "\033[36m"
WHITE      :: "\033[37m"
BRIGHT_RED :: "\033[91m"


Color :: enum {
    Reset,
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    Bright_Red,
}


get_color_code :: proc(color: Color) -> string {
    switch color {
    case .Reset:      return RESET
    case .Black:      return BLACK
    case .Red:        return RED
    case .Green:      return GREEN
    case .Yellow:     return YELLOW
    case .Blue:       return BLUE
    case .Magenta:    return MAGENTA
    case .Cyan:       return CYAN
    case .White:      return WHITE
    case .Bright_Red: return BRIGHT_RED
    }
    return RESET
}


print :: proc(args: ..any, color: Color = .Reset) {
    fmt.print(get_color_code(color))
    fmt.print(..args)
    fmt.print(RESET)
}


printf :: proc(format: string, args: ..any, color: Color = .Reset) {
    fmt.print(get_color_code(color))
    fmt.printf(format, ..args)
    fmt.print(RESET)
}


println :: proc(args: ..any, color: Color = .Reset) {
    fmt.print(get_color_code(color))
    fmt.println(..args)
    fmt.print(RESET)
}


debug_print :: proc(args: ..any, color: Color = .Cyan) {
    when ODIN_DEBUG {
        print(..args, color = color)
    }
}


debug_printf :: proc(format: string, args: ..any, color: Color = .Cyan) {
    when ODIN_DEBUG {
        printf(format, ..args, color = color)
    }
}


debug_println :: proc(args: ..any, color: Color = .Cyan) {
    when ODIN_DEBUG {
        println(..args, color = color)
    }
}

