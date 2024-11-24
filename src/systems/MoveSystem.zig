const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const GameContext = @import("../engine/game.zig").GameContext(app.AppState);
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const components = @import("../components.zig");
const float2 = @import("../engine/math/main.zig").float2;
const float = @import("../engine/math/generics.zig").on(f32);

filter: *EntityFilter = undefined,

pub const filterWith = .{
    components.Transform,
    components.Move,
    components.Turns,
};


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    // const delta_float: f32 = @floatCast(res.delta);
    var iter = self.filter.entities.iterator();
    while (iter.next()) |entity| {
        // get all components that entity could have
        var transform = world.getComponent(components.Transform, entity.*);
        var turns = world.getComponent(components.Turns, entity.*);
        const move = world.getReadOnlyComponent(components.Move, entity.*);

        if (turns.turn_count <= 0) {
            continue;
        }

        // get an axis from a user input
        const axisX = res.input.keyboard.pressedAxisF(.Left, .Right);

        if (axisX != 0) {
            turns.turn_count -= 1;
            transform.position.x += float.snapped(move.snap * 32 * axisX, axisX);
        }

        const axisY = res.input.keyboard.pressedAxisF(.Up, .Down);
        if (axisY != 0) {
            turns.turn_count -= 1;
            transform.position.y += float.snapped(move.snap * 32 * axisY, axisY);
        }
    }

    if (res.input.keyboard.isPressed(.Space)) {
        spawn(world);
    }
}

fn spawn(world: *World) void {
    const ent = world.createEntity();
    world.setComponent(components.Move, .{ .snap = 2 }, ent);
    world.setComponent(components.Transform, .{ .position = float2.new(0, 0) }, ent);
    world.setComponent(components.Destroyable, .{}, ent);
    world.setComponent(components.Turns, .{ .turn_count = 4 }, ent);
}