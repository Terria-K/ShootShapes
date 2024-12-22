const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const filter = @import("../engine/ecs/filter.zig");
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");


gameplay: filter.QueryFilter(.{
    filter.Without(components.Card),
    components.Transform,
    components.Sprite,
}),


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    // gameplay
    res.batch.begin(res.default, res.texture, res.sampler, res.camera_matrix.transform());

    var iter = self.gameplay.entities().iterator();
    while (iter.next()) |e| {
        const transform = world.getReadOnlyComponent(components.Transform, e.*);
        const sprite = world.getReadOnlyComponent(components.Sprite, e.*);
        res.batch.draw(.{
            .texture_quad = sprite.texture,
            .color = sprite.color,
            .position = transform.position,
            .scale = transform.scale
        });
    }

    res.batch.end();
}