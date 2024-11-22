const DepthStencilState = @This();
const structs = @import("main.zig");
const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const enums = @import("../enums/main.zig");
const StencilOpState = @import("StencilOpState.zig");

compare_op: enums.CompareOp,
back_stencil_state: StencilOpState = std.mem.zeroes(StencilOpState),
front_stencil_state: StencilOpState = std.mem.zeroes(StencilOpState),
compare_mask: u8 = 0,
write_mask: u8 = 0,
enable_depth_test: bool = false,
enable_depth_write: bool = false,
enable_stencil_test: bool = false,

pub inline fn convertToSDL(self: DepthStencilState) sdl.SDL_GPUDepthStencilState {
    return .{
        .compare_op = @intCast(@intFromEnum(self.compare_op)),
        .back_stencil_state = structs.convertToSDL(sdl.SDL_GPUStencilOpState, self.back_stencil_state),
        .front_stencil_state = structs.convertToSDL(sdl.SDL_GPUStencilOpState, self.front_stencil_state),
        .compare_mask = self.compare_mask,
        .write_mask = self.write_mask,
        .enable_depth_test = self.enable_depth_test,
        .enable_depth_write = self.enable_depth_write,
        .enable_stencil_test = self.enable_stencil_test
    };
}

pub inline fn depthReadWrite() DepthStencilState {
    return .{
        .enable_depth_test = true,
        .enable_depth_write = true,
        .enable_stencil_test = false,
        .compare_op = enums.CompareOp.LessOrEqual
    };
}

pub inline fn depthRead() DepthStencilState {
    return .{
        .enable_depth_test = true,
        .enable_depth_write = false,
        .enable_stencil_test = false,
        .compare_op = enums.CompareOp.LessOrEqual
    };
}

pub inline fn disable() DepthStencilState {
    return .{
        .enable_depth_test = false,
        .enable_depth_write = false,
        .enable_stencil_test = false,
        .compare_op = enums.CompareOp.Invalid
    };
}