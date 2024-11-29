const std = @import("std");
const World = @import("../engine/ecs/World.zig");
const app = @import("../main.zig");
const GameContext = @import("../engine/game.zig").GameContext(app.AppState);
const EntityFilter = @import("../engine/ecs/filter.zig").EntityFilter;
const components = @import("../components.zig");
const float2 = @import("../engine/math/main.zig").float2;


filter: *EntityFilter = undefined,

pub const filterWith = .{
    components.Destroyable
};

pub fn run(self: @This(), world: *World, res: *app.GlobalResource) void {
    var iter = self.filter.entities.iterator();
    while (iter.next()) |entity| {
        if (res.input.mouse.leftButton().pressed()) {
            world.destroy(entity.*);
        } 
        return;
    }
}