const ColorTargetInfo = @This();
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const Texture = @import("Texture.zig");
const Color = @import("../graphics/main.zig").Color;
const std = @import("std");
const enums = @import("../enums/main.zig");

texture: Texture,
mip_level: u32 = std.mem.zeroes(u32),
layer_or_depth_plane: u32 = std.mem.zeroes(u32),
clear_color: Color,
load_op: enums.LoadOp = enums.LoadOp.Clear,
store_op: enums.StoreOp = enums.StoreOp.Store,
resolve_texture: Texture = std.mem.zeroes(Texture),
resolve_mip_level: u32 = std.mem.zeroes(u32),
resolve_layer: u32 = std.mem.zeroes(u32),
cycle: bool = std.mem.zeroes(bool),
cycle_resolve_texture: bool = std.mem.zeroes(bool),

