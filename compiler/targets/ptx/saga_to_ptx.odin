package saga_compiler
import "core:fmt"
import "core:log"
import "core:strings"
import "core:strconv"


Ctx :: struct {
    module_name:	    string,
    version:                Version_Directive,
    target:                 Target_Directive,
    address_size:           Address_Size_Directive,
    entry:                  Entry_Directive,
    params:		    [dynamic]Param
}


set_version :: proc(ctx: ^Ctx, major: int = 8, minor: int = 1) {
    ctx.version = Version_Directive {major, minor}
}


set_target :: proc(ctx: ^Ctx, target: Target = .SM_86, texturing_mode: Texturing_Mode = nil, platform_option: Platform_Option = nil) {
    ctx.target = Target_Directive{target, texturing_mode, platform_option}
}


set_address_size :: proc(ctx: ^Ctx, address_size: Address_Size = .B64) {
    ctx.address_size = Address_Size_Directive {address_size}
}


translate_module :: proc(ctx: ^Ctx, node: Module) {
    set_version(ctx)
    set_target(ctx)
    set_address_size(ctx)
    ctx.module_name = node.name
}


translate_kernel :: proc(ctx: ^Ctx, node: Kernel) {
    translate_kernel_signature(ctx, node.signature)
}


translate_kernel_signature :: proc(ctx: ^Ctx, node: Kernel_Signature) {
    entry: Entry_Directive
    entry.name = ctx.module_name
    

}


translate_kernel_args :: proc(ctx: ^Ctx, nodes: [dynamic]Argument) {
    for node, idx in nodes {
        switch t in node.type {
        case Array_Type:
	     
        case Scalar_Type:
        } 
    }
}
