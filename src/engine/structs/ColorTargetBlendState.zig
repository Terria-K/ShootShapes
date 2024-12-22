const ColorTargetBlendState = @This();
const enums = @import("../enums/main.zig");
const ColorComponentFlags = @import("main.zig").ColorComponentFlags;
const BlendFactor = enums.BlendFactor;
const BlendOp = enums.BlendOp;
src_color_blendfactor: BlendFactor,
dst_color_blendfactor: BlendFactor,
color_blend_op: BlendOp,
src_alpha_blendfactor: BlendFactor,
dst_alpha_blendfactor: BlendFactor,
alpha_blend_op: BlendOp,
color_write_mask: ColorComponentFlags,
enable_blend: bool = false,
enable_color_write_mask: bool = false,

pub inline fn premultipliedAlphaBlend() ColorTargetBlendState {
    return .{
        .enable_blend = true,
        .alpha_blend_op = BlendOp.Add,
        .color_blend_op = BlendOp.Add,
        .color_write_mask = .{ .r = true, .g = true, .b = true, .a = true },
        .src_alpha_blendfactor = BlendFactor.One,
        .src_color_blendfactor = BlendFactor.One,
        .dst_color_blendfactor = BlendFactor.OneMinusSrcAlpha,
        .dst_alpha_blendfactor = BlendFactor.OneMinusSrcAlpha
    };
}

pub inline fn nonPremultipliedAlphaBlend() ColorTargetBlendState {
    return .{
        .enable_blend = true,
        .alpha_blend_op = BlendOp.Add,
        .color_blend_op = BlendOp.Add,
        .color_write_mask = .{ .r = true, .g = true, .b = true, .a = true },
        .src_alpha_blendfactor = BlendFactor.SrcAlpha,
        .src_color_blendfactor = BlendFactor.SrcAlpha,
        .dst_color_blendfactor = BlendFactor.OneMinusSrcAlpha,
        .dst_alpha_blendfactor = BlendFactor.OneMinusSrcAlpha
    };
}

pub inline fn opaqueBlend() ColorTargetBlendState {
    return .{
        .enable_blend = true,
        .alpha_blend_op = BlendOp.Add,
        .color_blend_op = BlendOp.Add,
        .color_write_mask = .{ .r = true, .g = true, .b = true, .a = true },
        .src_alpha_blendfactor = BlendFactor.One,
        .src_color_blendfactor = BlendFactor.One,
        .dst_color_blendfactor = BlendFactor.Zero,
        .dst_alpha_blendfactor = BlendFactor.Zero
    };
}