package saga_compiler
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:unicode"


is_space            :: unicode.is_space
is_alpha            :: unicode.is_alpha
is_digit            :: unicode.is_digit

split               :: strings.split
split_n             :: strings.split_n
count               :: strings.count
join                :: strings.join
remove_all          :: strings.remove_all
replace_all         :: strings.replace_all
contains            :: strings.contains
contains_any        :: strings.contains_any
has_prefix          :: strings.has_prefix
clone_to_cstring    :: strings.clone_to_cstring
atoi                :: strconv.atoi
atof                :: strconv.atof


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
