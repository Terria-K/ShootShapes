const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const Color = @import("../engine/graphics.zig").Color;
const components = @import("../components.zig");
const float2 = @import("../engine/math/main.zig").float2;
const Atlas = @import("../Atlas.zig");
const atlas = @import("atlas");

const entity_cube_size = float2.new(16, 16);

pub fn run(_: @This(), world: *World, _: *app.GlobalResource) void {
    spawnCursorEntity(world);
    const player = spawnPlayer(world);
    const enemy = spawnEnemy(world);
    spawnArena(world);
    spawnCard(world, 0);
    spawnCard(world, 1);
    spawnCard(world, 2);

    world.setComponentRelation(components.Tracked, .{}, player, enemy);
}

fn spawnArena(world: *World) void {
    const arena_entity = world.createEntity();

    world.setComponent(components.Transform, .{
        .position = float2.new(0, 223)
    }, arena_entity);

    world.setComponent(components.Sprite, .{
        .texture = Atlas.get(atlas.Texture, "ui_arena")
    }, arena_entity);
}

fn spawnCard(world: *World, comptime i: u32) void {
    const card = world.createEntity();
    world.setComponent(components.Transform, .{
        .position = float2.new(130 + (50 * i), 221)
    }, card);
    world.setComponent(components.Sprite, .{
        .texture = Atlas.get(atlas.Texture, "ui_card")
    }, card);

    world.setComponent(components.Card, .{}, card);
    world.setComponent(components.Tween, .{
        .ease = .EaseIn
    }, card);
}

fn spawnCursorEntity(world: *World) void {
    const mouse_entity = world.createEntity();
    world.setComponent(components.Cursor, .{}, mouse_entity);
    world.setComponent(components.Transform, .{ 
        .position = float2.new(0, 0),
        .scale = entity_cube_size
    }, mouse_entity);

    world.setComponent(components.Sprite, .{ 
        .texture = Atlas.get(atlas.Texture, "pixel"),
        .color = .{ .r = 255, .g = 255, .b = 255, .a = 128 }
    }, mouse_entity);
    world.setComponent(components.Pulsing, .{}, mouse_entity);
}

fn spawnPlayer(world: *World) u32 {
    const player_entity = world.createEntity();
    world.setComponent(components.Move, .{ .snap = 1 }, player_entity);
    world.setComponent(components.Turns, .{ .player = 5 }, player_entity);
    world.setComponent(components.Sprite,.{ 
        .texture = Atlas.get(atlas.Texture, "pixel")
    }, player_entity);
    world.setComponent(components.Transform, .{ 
        .position = float2.new(0, 0),
        .scale = entity_cube_size
    }, 
    player_entity);
    return player_entity;
}

fn spawnEnemy(world: *World) u32 {
    const enemy = world.createEntity();
    world.setComponent(components.Move, .{ .snap = 1 }, enemy);
    world.setComponent(components.Turns, .{ .enemy = 4 }, enemy);
    world.setComponent(components.Sprite, .{ .texture = Atlas.get(atlas.Texture, "pixel") }, enemy);
    world.setComponent(components.Timer, components.Timer.init(0.5), enemy);
    world.setComponent(components.Transform, .{ 
        .position = float2.new(128, 48),
        .scale = entity_cube_size
    }, 
    enemy);
    return enemy;
}