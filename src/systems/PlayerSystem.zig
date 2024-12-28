const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const filter = @import("../engine/ecs/filter.zig");
const components = @import("../components.zig");
const float2 = @import("../engine/math.zig").float2;
const frect = @import("../engine/math.zig").frect;
const float = @import("../engine/math/generics.zig").on(f32);
const spawner = @import("SpawnWorldSystem.zig");

const snap_grid = 16;

kill_cursors: filter.QueryFilter(.{
    components.Cursor
}),

filter: filter.QueryFilter(.{
    components.TargetTurn,
    components.Player,
    components.Transform
}),


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities().iterator();
    while (iter.next()) |entity| {
        const transform = world.getComponent(components.Transform, entity.*);
        const turn = world.getComponent(components.TargetTurn, entity.*);

        if (world.getAllTargetRelations(components.PlayerStateTransfers, entity.*)) |relations| {
            var relation_iter = relations.iterator();

            while (relation_iter.next()) |e| {
                if (world.getComponentRelation(components.PlayerStateTransfers, entity.*, e.*)) |transfers| {
                    transfers.position = transform.position;
                }
            }
        }

        const grid_pos = float2.new(transform.position.x / 16, transform.position.y / 16);

        if (world.receiveFirstMessage(components.Clicked)) |click| {
            const distance = click.pos.sub(grid_pos);
            const x = @abs(distance.x);
            const y = @abs(distance.y);
            const normalized_pixels_x = std.math.sign(distance.x);
            const normalized_pixels_y = std.math.sign(distance.y);

            if (x > y) {
                turn.turns = @intFromFloat(@min(x, 5));
                turn.target_dir = .{ .horizontal = normalized_pixels_x };
            } else {
                turn.turns = @intFromFloat(@min(y, 5));
                turn.target_dir = .{ .vertical = normalized_pixels_y };
            }
        }
        const rect = frect.init(transform.position.x, transform.position.y, 16, 16);

        const mouse_pos = snapPosition(
            res.camera_matrix.screenToWorld(1024, 640, float2.new(res.input.mouse.x, res.input.mouse.y))
        );

        if (rect.containsPoint(mouse_pos) and res.input.mouse.leftButton().pressed()) {
            self.killAllCursors(world);
            const cursor = spawner.spawnCursorEntity(world);
            world.setComponentRelation(components.PlayerStateTransfers, .{}, entity.*, cursor);
        }
    }
}

fn killAllCursors(self: @This(), world: *World) void {
    var cursors = self.kill_cursors.entities();
    var iter = cursors.iterator();
    while (iter.next()) |entity| {
        world.destroy(entity.*);
    }
}

fn snapPosition(pos: float2) float2 {
    return float2.new(
        @floor((pos.x / snap_grid)) * snap_grid, 
        @floor((pos.y / snap_grid)) * snap_grid
    );
}