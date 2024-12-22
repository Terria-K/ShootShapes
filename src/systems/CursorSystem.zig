const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const filter = @import("../engine/ecs/filter.zig");
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");
const float2 = @import("../engine/math.zig").float2;
const Atlas = @import("../Atlas.zig");
const atlas = @import("atlas");

const snap_grid = 16;


filter: filter.QueryFilter(.{
    components.Transform,
    components.Cursor
}),

pulsing: filter.QueryFilter(.{
    components.Pulsing,
    components.Sprite
}),


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities().iterator();

    const mouse_pos = snapPosition(
        res.camera_matrix.screenToWorld(1024, 640, float2.new(res.input.mouse.x, res.input.mouse.y))
    );

    while (iter.next()) |e| {
        const transform = world.getComponent(components.Transform, e.*);

        transform.position.x = mouse_pos.x;
        transform.position.y = mouse_pos.y;

        // const dist = mouse_pos.distance(float2.new(200, 50));

        // std.log.debug("{d}", .{dist});
    }

    var pulse_iter = self.pulsing.entities().iterator();

    while (pulse_iter.next()) |e| {
        const pulsing = world.getComponent(components.Pulsing, e.*);
        const sprite = world.getComponent(components.Sprite, e.*);

        sprite.color.a = @intFromFloat(@abs(@sin(std.math.pi * pulsing.progress)) * 255);
        pulsing.progress += @floatCast(res.delta);
    }
}

fn snapPosition(pos: float2) float2 {
    return float2.new(
        @floor((pos.x / snap_grid)) * snap_grid, 
        @floor((pos.y / snap_grid)) * snap_grid
    );
}