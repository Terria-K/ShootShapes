const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");
const float2 = @import("../engine/math.zig").float2;
const Atlas = @import("../Atlas.zig");
const atlas = @import("atlas");

const snap_grid = 16;

pub const filterWith  = .{
    components.Transform,
    components.Cursor
};

pub const pulsingWith = .{
    components.Pulsing,
    components.Sprite
};

filter: *EntityFilter = undefined,
pulsing: *EntityFilter = undefined,


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities.iterator();

    const mouse_pos = snapPosition(
        res.camera_matrix.screenToWorld(1024, 640, float2.new(res.input.mouse.x, res.input.mouse.y))
    );

    while (iter.next()) |e| {
        const transform = world.getComponent(components.Transform, e.*);

        transform.position.x = mouse_pos.x;
        transform.position.y = mouse_pos.y;
        if (res.input.mouse.rightButton().pressed()) {
            world.destroy(e.*);
            break;
        }
    }

    var pulse_iter = self.pulsing.entities.iterator();

    while (pulse_iter.next()) |e| {
        const pulsing = world.getComponent(components.Pulsing, e.*);
        const sprite = world.getComponent(components.Sprite, e.*);

        sprite.color.a = @intFromFloat(@abs(@sin(std.math.pi * pulsing.progress)) * 255);
        pulsing.progress += @floatCast(res.delta);
    }

    if (res.input.mouse.leftButton().pressed()) {
        spawnPlayer(world);
    }
}

fn spawnPlayer(world: *World) void {
    const player_entity = world.createEntity();
    world.setComponent(components.Move, .{ .snap = 1 }, player_entity);
    world.setComponent(components.Turns, .{ .player = 5 }, player_entity);
    world.setComponent(components.Sprite,.{ 
        .texture = Atlas.get(atlas.Texture, "pixel")
    }, player_entity);
    world.setComponent(components.Transform, .{ 
        .position = float2.new(0, 0),
        .scale = float2.new(16, 16)
    }, 
    player_entity);
}

fn snapPosition(pos: float2) float2 {
    return float2.new(
        @floor((pos.x / snap_grid)) * snap_grid, 
        @floor((pos.y / snap_grid)) * snap_grid
    );
}