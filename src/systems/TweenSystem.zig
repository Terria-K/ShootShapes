const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");
const float2 = @import("../engine/math.zig").float2;
const frect = @import("../engine/math.zig").frect;
const rmath = @import("../engine/math/generics.zig").on(f32);

pub const filterWith  = .{
    components.Tween
};

filter: *EntityFilter = undefined,


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities.iterator();

    while (iter.next()) |e| {
        const tween = world.getComponent(components.Tween, e.*);

        if (!tween.started) {
            continue;
        }

        tween.progress += res.delta;

        const value = switch (tween.ease) {
            .EaseIn => @cos((std.math.pi / 2.0) * tween.progress) + 1,
            .EaseOut => @sin((std.math.pi / 2.0) * tween.progress),
            .EaseInOut => @cos(std.math.pi * tween.progress) / 2.0 + 5.0
        };

        tween.value = @floatCast(@min(1, value));

        if (tween.progress >= 1) {
            tween.started = false;
        }
    }
}
