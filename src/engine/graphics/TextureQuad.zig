const TextureQuad = @This();
const Texture = @import("Texture.zig");
const UV = @import("main.zig").UV;
const float2 = @import("../math/main.zig").float2;
const int2 = @import("../math/main.zig").int2;
const frect = @import("../math/main.zig").frect;
const FlipMode = @import("../structs/main.zig").FlipMode;

uv: UV,
position: float2,
dimension: float2,
source: frect,
width: u32,
height: u32,

pub fn initFromSize(size: int2, source: frect) TextureQuad {
    const sx = source.x / @as(f32, @floatFromInt(size.x));
    const sy = source.y / @as(f32, @floatFromInt(size.y));

    const sw = source.width / @as(f32, @floatFromInt(size.x));
    const sh = source.height / @as(f32, @floatFromInt(size.y));
    const position = float2.new(sx, sy);
    const dimension = float2.new(sw, sh);
    return .{
        .width = @intFromFloat(source.width),
        .height = @intFromFloat(source.height),
        .uv = UV.initByDimension(position, dimension),
        .position = position,
        .dimension = dimension,
        .source = source
    };
}

pub fn initFromTexture(texture: Texture, source: frect) TextureQuad {
    const sx = source.x / @as(f32, @floatFromInt(texture.width));
    const sy = source.y / @as(f32, @floatFromInt(texture.height));

    const sw = source.width / @as(f32, @floatFromInt(texture.width));
    const sh = source.height / @as(f32, @floatFromInt(texture.height));
    const position = float2.new(sx, sy);
    const dimension = float2.new(sw, sh);
    return .{
        .width = @intFromFloat(source.width),
        .height = @intFromFloat(source.height),
        .uv = UV.initByDimension(position, dimension),
        .position = position,
        .dimension = dimension,
        .source = source
    };
}

pub fn equals(self: TextureQuad, other: TextureQuad) bool {
    return self.source.x == other.source.x and
        self.source.y == other.source.y and
        self.source.width == other.source.width and
        self.source.height == other.source.height;
}

pub fn flipUV(self: TextureQuad, flip_mode: FlipMode) TextureQuad {
    const corner_offset_x = [4]f32 {
        0.0, 0.0, 1.0, 1.0
    };

    const corner_offset_y = [4]f32 {
        0.0, 1.0, 0.0, 1.0
    };

    var new_quad: TextureQuad = .{
        .source = self.source,
        .dimension = self.dimension,
        .height = self.height,
        .width =  self.width,
        .uv = self.uv,
        .position = self.position
    };

    const flip_byte = (@as(u8, @bitCast(flip_mode)) & (2 | 1));
    new_quad.uv.top_left.x = corner_offset_x[0 ^ flip_byte] * self.dimension.x + self.position.x;
    new_quad.uv.top_left.y = corner_offset_y[0 ^ flip_byte] * self.dimension.y + self.position.y;

    new_quad.uv.bottom_left.x = corner_offset_x[1 ^ flip_byte] * self.dimension.x + self.position.x;
    new_quad.uv.bottom_left.y = corner_offset_y[1 ^ flip_byte] * self.dimension.y + self.position.y;

    new_quad.uv.top_right.x = corner_offset_x[2 ^ flip_byte] * self.dimension.x + self.position.x;
    new_quad.uv.top_right.y = corner_offset_y[2 ^ flip_byte] * self.dimension.y + self.position.y;

    new_quad.uv.bottom_right.x = corner_offset_x[3 ^ flip_byte] * self.dimension.x + self.position.x;
    new_quad.uv.bottom_right.y = corner_offset_y[3 ^ flip_byte] * self.dimension.y + self.position.y;

    return new_quad;
}
