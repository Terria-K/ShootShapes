const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const components = @import("../components.zig");
const float2 = @import("../engine/math/main.zig").float2;
const Atlas = @import("../Atlas.zig");
const atlas = @import("atlas");


pub fn run(_: @This(), world: *World, _: *app.GlobalResource) void {
    spawnCursorEntity(world);
    spawnPlayer(world);
    spawnEnemy(world);
}

fn spawnCursorEntity(world: *World) void {
    const mouse_entity = world.createEntity();
    world.setComponent(components.Cursor, .{}, mouse_entity);
    world.setComponent(components.Transform, .{ .position = float2.new(0, 0) }, mouse_entity);
    world.setComponent(components.Sprite, .{ .texture = Atlas.get(atlas.Texture, "arrowselect") }, mouse_entity);
}

fn spawnPlayer(world: *World) void {
    const player_entity = world.createEntity();
    world.setComponent(components.Move, .{ .snap = 1 }, player_entity);
    world.setComponent(components.Turns, .{ .player = 5 }, player_entity);
    world.setComponent(components.Sprite, .{ .texture = Atlas.get(atlas.Texture, "chapter1") }, player_entity);
    world.setComponent(components.Transform, .{ .position = float2.new(100, 100) }, player_entity);
}

fn spawnEnemy(world: *World) void {
    const enemy = world.createEntity();
    world.setComponent(components.Move, .{ .snap = 1 }, enemy);
    world.setComponent(components.Turns, .{ .enemy = 4 }, enemy);
    world.setComponent(components.Sprite, .{ .texture = Atlas.get(atlas.Texture, "chapter1") }, enemy);
    world.setComponent(components.Transform, .{ .position = float2.new(50, 50) }, enemy);
    world.setComponent(components.Timer, components.Timer.init(0.5), enemy);
}