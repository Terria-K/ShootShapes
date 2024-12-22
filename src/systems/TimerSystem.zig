const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const filter = @import("../engine/ecs/filter.zig");
const components = @import("../components.zig");

filter: filter.QueryFilter(.{
    components.Timer
}),


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities().iterator();
    const delta_float: f32 = @floatCast(res.delta);

    while (iter.next()) |entity| {
        var timer = world.getComponent(components.Timer, entity.*);
        if (timer.status != .Started) {
            continue;
        }

        timer.time -= delta_float;
        if (timer.time <= 0) {
            timer.status = .Ended;
        }
    }
}