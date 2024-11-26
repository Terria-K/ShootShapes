const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");
const Batcher = @import("../Batcher.zig");

pub const filterWith  = .{
    components.Transform
};

filter: *EntityFilter = undefined,



pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    const vertices = res.batch.vertex_transfer_buffer.map(PCV, true);
    const indices = res.batch.index_transfer_buffer.map(u32, true);

    var iter = self.filter.entities.iterator();
    while (iter.next()) |e| {
        const transform = world.getComponent(components.Transform, e.*);
        Batcher.addVertex(res.count, vertices, indices, transform.position);
        res.count += 1;
    }

    res.batch.index_transfer_buffer.unmap();
    res.batch.vertex_transfer_buffer.unmap();
}