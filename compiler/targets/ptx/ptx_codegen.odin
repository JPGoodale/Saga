package saga_compiler
import "core:os"
import "core:fmt"


// Version_Directive :: struct {
// 	major: int,
// 	minor: int
// }
//
//
// Target_Directive :: struct {
// 	target:				Target,
// 	texturing_mode:		Texturing_Mode,
// 	platform_option:	Platform_Option,
// }
//
//
// Address_Size_Directive :: struct {
// 	size: Address_Size,
// }


// generate_ptx_directive :: proc(file_handle: os.Handle, directive: Directive) {
// 	switch d in directive {
// 	case Module_Directive:
// 		switch md in d {
// 		case Version_Directive:
// 			s:  string = fmt.aprintln(n)
// 			ss: []string = split(s, "{")
// 			s = ss[0]
// 		case Target_Directive:
// 		case Address_Size_Directive:
// 		}
// 	}
// }
