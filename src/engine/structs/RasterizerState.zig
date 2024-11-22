const RasterizerState = @This();
const enums = @import("../enums/main.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
fill_mode: enums.FillMode = enums.FillMode.Fill,
cull_mode: enums.CullMode = enums.CullMode.None,
front_face: enums.FrontFace = enums.FrontFace.Clockwise,
depth_bias_constant_factor: f32 = 0,
depth_bias_clamp: f32 = 0,
depth_bias_slope_factor: f32 = 0,
enable_depth_bias: bool = false,
enable_depth_clip: bool = false,

pub inline fn cwCullFront() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.Front,
        .front_face = enums.FrontFace.Clockwise,
        .fill_mode = enums.FillMode.Fill,
        .enable_depth_bias = false
    };
}	

pub inline fn cwCullBack() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.Back,
        .front_face = enums.FrontFace.Clockwise,
        .fill_mode = enums.FillMode.Fill,
        .enable_depth_bias = false
    };
}

pub inline fn cwCullNone() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.None,
        .front_face = enums.FrontFace.Clockwise,
        .fill_mode = enums.FillMode.Fill,
        .enable_depth_bias = false
    };
}

pub inline fn cwWireframe() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.None,
        .front_face = enums.FrontFace.Clockwise,
        .fill_mode = enums.FillMode.Line,
        .enable_depth_bias = false
    };
}

pub inline fn ccwCullFront() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.Front,
        .front_face = enums.FrontFace.CounterClockwise,
        .fill_mode = enums.FillMode.Fill,
        .enable_depth_bias = false
    };
}

pub inline fn ccwCullBack() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.Back,
        .front_face = enums.FrontFace.CounterClockwise,
        .fill_mode = enums.FillMode.Fill,
        .enable_depth_bias = false
    };
}

pub inline fn ccwCullNone() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.None,
        .front_face = enums.FrontFace.CounterClockwise,
        .fill_mode = enums.FillMode.Fill,
        .enable_depth_bias = false
    };
}

pub inline fn ccwWireframe() RasterizerState {
    return .{
        .cull_mode = enums.CullMode.None,
        .front_face = enums.FrontFace.CounterClockwise,
        .fill_mode = enums.FillMode.Line,
        .enable_depth_bias = false
    };
}