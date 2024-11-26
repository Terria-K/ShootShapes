const std = @import("std");
pub const Type = @import("typeid.zig").Type;

pub const World = @import("World.zig");
pub const filter = @import("filter.zig");
pub const EntityID = u32;

test "ecs" {
    const EntityFilter = filter.EntityFilter;
    const expect = std.testing.expect;
    const ValueComponent = struct {
        value: i32
    };
    const AdderComponent = struct {
        adding: i32
    };

    const AddSystem = struct {
        filter: *EntityFilter,
        pub const filterWith = .{
            ValueComponent,
            AdderComponent
        };

        pub fn run(self: @This(), world: *World, _: anytype) void {
            var iter = self.filter.entities.iterator();
            while (iter.next()) |e| {
                const adding = world.getReadOnlyComponent(AdderComponent, e.*);
                var value = world.getComponent(ValueComponent, e.*);

                value.value += adding.adding;
            }
        }
    };

    const SystemContainer = struct {
        add_system: AddSystem
    };
    var world = try World.init(std.testing.allocator);
    defer world.deinit();
    var system_container = try world.createSystems(SystemContainer);
    defer world.deinitSystems(system_container);

    const entity1 = world.createEntity();
    world.setComponent(ValueComponent, .{ .value = 1}, entity1);
    world.setComponent(AdderComponent, .{ .adding = 1}, entity1);

    const entity2 = world.createEntity();
    world.setComponent(ValueComponent, .{ .value = 4 }, entity2);
    world.setComponent(AdderComponent, .{ .adding = 3}, entity2);

    const entity3 = world.createEntity();
    world.setComponent(ValueComponent, .{ .value = 4 }, entity3);

    world.runSystems(&system_container, .{});

    const value1 = world.getReadOnlyComponent(ValueComponent, entity1).*;
    const value2 = world.getReadOnlyComponent(ValueComponent, entity2).*;
    const value3 = world.getReadOnlyComponent(ValueComponent, entity3).*;

    try expect(value1.value == 2);
    try expect(value2.value == 7);
    try expect(value3.value == 4);

    world.removeComponent(AdderComponent, entity2);

    world.runSystems(&system_container, .{});

    const value1New = world.getReadOnlyComponent(ValueComponent, entity1).*;
    const value2New = world.getReadOnlyComponent(ValueComponent, entity2).*;

    try expect(value1New.value == 3);
    try expect(value2New.value == 7);
}