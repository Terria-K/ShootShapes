const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const enums = @import("../enums/main.zig");

fail_op: enums.StencilOp,
pass_op: enums.StencilOp,
depth_fail_op: enums.StencilOp,
compare_op: enums.CompareOp,