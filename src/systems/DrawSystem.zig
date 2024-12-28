const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const filter = @import("../engine/ecs/filter.zig");
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const float2 = @import("../engine/math.zig").float2;
const components = @import("../components.zig");
const Atlas = @import("../Atlas.zig");
const atlas = @import("atlas");


gameplay: filter.QueryFilter(.{
    components.Transform,
    components.Sprite,
}),


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    // gameplay
    res.batch.begin(.{
        .pipeline = res.default,
        .texture = res.texture,
        .sampler = res.sampler,
        .matrix = res.camera_matrix.transform()
    });

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

        if (world.tryGetComponent(components.Cursor, e.*)) |cursor| {
            const x = @abs(cursor.grid.x);
            const y = @abs(cursor.grid.y);

            const max_x = if (cursor.grid.x < 0) 
                    @max(cursor.grid.x, -5)
                else
                    @min(cursor.grid.x, 5);

            const max_y = if (cursor.grid.y < 0) 
                    @max(cursor.grid.y, -5)
                else
                    @min(cursor.grid.y, 5);

            res.batch.draw(.{
                .position = cursor.player_position,
                .color = sprite.color,
                .scale = if (x > y) float2.new(max_x * 16, 16) else float2.new(16, max_y * 16),
                .texture_quad = Atlas.get(atlas.Texture, "pixel"),
            });
        }
    }

    res.batch.end();
}