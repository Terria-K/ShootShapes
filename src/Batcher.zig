const graphics = @import("engine/graphics/main.zig");
const Color = graphics.Color;
const PCV = @import("engine/vertex/main.zig").PositionColorVertex;
const float2 = @import("engine/math/main.zig").float2;
const float4 = @import("engine/math/main.zig").float4;

vert_buffer: graphics.GpuBuffer,
index_buffer: graphics.GpuBuffer,
vertex_transfer_buffer: graphics.TransferBuffer,
index_transfer_buffer: graphics.TransferBuffer,

pub fn addVertex(count: u32, vertices: [*]PCV, indices: [*]u32, pos: float2) void {
    const size = 32;
    vertices[count * 4] = .{ .position = float4.new(pos.x, pos.y, 0, 1), .color = Color.init(1, 1, 1, 1) };
    vertices[count * 4 + 1] = .{ .position = float4.new(pos.x + size, pos.y, 0, 1), .color = Color.init(1, 1, 1, 1) };
    vertices[count * 4 + 2] = .{ .position = float4.new(pos.x, pos.y + size, 0, 1), .color = Color.init(1, 1, 1, 1) };
    vertices[count * 4 + 3] = .{ .position = float4.new(pos.x + size, pos.y + size, 0, 1), .color = Color.init(1, 1, 1, 1) };

    indices[count * 6] = (count * 4) + 0;
    indices[count * 6 + 1] = (count * 4) + 1;
    indices[count * 6 + 2] = (count * 4) + 2;
    indices[count * 6 + 3] = (count * 4) + 2;
    indices[count * 6 + 4] = (count * 4) + 1;
    indices[count * 6 + 5] = (count * 4) + 3;
}