const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const filter = @import("../engine/ecs/filter.zig");
const components = @import("../components.zig");
const float2 = @import("../engine/math/main.zig").float2;
const float = @import("../engine/math/generics.zig").on(f32);

const snap_grid = 16;

filter: filter.QueryFilter(.{
    components.Transform,
    components.Move,
    components.Turns,
}),


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    // const delta_float: f32 = @floatCast(res.delta);
    var iter = self.filter.entities().iterator();
    while (iter.next()) |entity| {
        // get all components that entity could have
        const turns = world.getComponent(components.Turns, entity.*);
        var transform = world.getComponent(components.Transform, entity.*);
        const move = world.getReadOnlyComponent(components.Move, entity.*);

        switch (turns.*) {
            .enemy => |*e| if (res.turn_state == .EnemyTurn) {
                // Enemy could have a timer
                if (world.tryGetComponent(components.Timer, entity.*)) |timer| {
                    switch (timer.status) {
                        .Reset => timer.start(),
                        .Started => {},
                        .Ended => {
                            e.* -= 1;
                            var relations = world.getAllAdmirerRelations(components.Tracked, entity.*);
                            var relation_iter = relations.iterator();

                            var direction: float2 = undefined;

                            while (relation_iter.next()) |er| {
                                if (world.getComponentRelation(components.Tracked, er.*, entity.*)) |tracker| {
                                    const move_dir = tracker.current_pos.sub(transform.position);
                                    direction = move_dir.normalize();
                                }
                            }
                            const rounded = float2.new(@round(direction.x), @round(direction.y));
                            
                            if (rounded.x != 0) {
                                transform.position.x += float.snapped(move.snap * snap_grid * rounded.x, 1);
                            }

                            else if (rounded.y != 0) {
                                transform.position.y += float.snapped(move.snap * snap_grid * rounded.y, 1);
                            }

                            timer.reset();

                            if (e.* <= 0) {
                                res.turn_state = .PlayerTurn;
                                e.* = 4;
                            }
                        }
                    }
                }
            },
            .player => |*p| if (res.turn_state == .PlayerTurn) {
                // get an axis from a user input
                const axisX = res.input.keyboard.pressedAxisF(.Left, .Right);

                if (axisX != 0) {
                    p.* -= 1;
                    transform.position.x += float.snapped(move.snap * snap_grid * axisX, axisX);
                }

                const axisY = res.input.keyboard.pressedAxisF(.Up, .Down);
                if (axisY != 0) {
                    p.* -= 1;
                    transform.position.y += float.snapped(move.snap * snap_grid * axisY, axisY);
                }

                if (p.* <= 0) {
                    var relations = world.getAllTargetRelations(components.Tracked, entity.*);
                    var relation_iter = relations.iterator();
                    while (relation_iter.next()) |e|{
                        if (world.getComponentRelation(components.Tracked, entity.*, e.*)) |tracker|{
                            tracker.current_pos = transform.position;
                        }
                    }
                    res.turn_state = .EnemyTurn;
                    p.* = 5;
                }
            }
        }
    }
}