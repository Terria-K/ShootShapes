const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");


pub const filterWith  = .{
    components.Transform
};

filter: *EntityFilter = undefined,


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    res.batch.begin(res.default, res.texture, res.sampler);

    var iter = self.filter.entities.iterator();
    while (iter.next()) |e| {
        const transform = world.getComponent(components.Transform, e.*);
        const sprite = world.getComponent(components.Sprite, e.*);
        res.batch.draw(.{
            .texture_quad = sprite.texture,
            .color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
            .position = transform.position
        });
    }

    res.batch.end();
}