const std = @import("std");
const TextureQuad = @import("engine/graphics/TextureQuad.zig");

pub fn get(atlas: anytype, comptime str: []const u8) TextureQuad {
    const T = @TypeOf(atlas);
    const index = std.meta.fieldIndex(T, str);
    if (index) |i| {
        const field_info = std.meta.fields(T)[i];
        const field = @field(atlas, field_info.name);
        return TextureQuad.initFromSize(.{
            .x = field.width,
            .y = field.height
        }, .{
            .x = field.x,
            .y = field.y,
            .width = field.width,
            .height = field.height,
        });
    } 
    @compileError("No texture named: '" ++ str ++ "'");
}