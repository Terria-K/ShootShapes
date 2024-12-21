const std = @import("std");
const app = @import("../main.zig");
const World = @import("../engine/ecs/World.zig");
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const PCV = @import("../engine/vertex/main.zig").PositionTextureColorVertex;
const components = @import("../components.zig");
const float2 = @import("../engine/math.zig").float2;
const frect = @import("../engine/math.zig").frect;
const rmath = @import("../engine/math/generics.zig").on(f32);

const snap_grid = 16;

pub const filterWith  = .{
    components.Card,
    components.Tween,
    components.Transform
};

filter: *EntityFilter = undefined,


pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities.iterator();

    const mouse_pos = res.camera_matrix.screenToWorld(1024, 640, float2.new(res.input.mouse.x, res.input.mouse.y));

    while (iter.next()) |e| {
        const card = world.getComponent(components.Card, e.*);
        const tween = world.getComponent(components.Tween, e.*);
        const transform = world.getComponent(components.Transform, e.*);
        const rect = frect.init(transform.position.x, transform.position.y, 50, 64);
 
        if (card.hovering) {
            if (!rect.containsPoint(mouse_pos)) {
                card.hovering = false;
                tween.start();
                continue;
            }

            if (tween.started) {
                transform.position.y = rmath.moveTowards(
                    transform.position.y, 
                    221 - 10, 
                    tween.value);
            }
            continue;
        }

        if (!card.hovering) {
            if (rect.containsPoint(mouse_pos)) {
                card.hovering = true;
                tween.start();
                continue;
            }

            if (tween.started) {
                transform.position.y = rmath.moveTowards(
                    transform.position.y, 
                    211 + 10, 
                    tween.value);
            }
        }
    }
}