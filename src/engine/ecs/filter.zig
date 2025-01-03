const Set = @import("ziglangSet").Set;
const std = @import("std");
const Type = @import("typeid.zig").Type;
const TypeID = @import("typeid.zig").TypeID;
const World = @import("World.zig");
const math = @import("../math/main.zig");
const EntityID = @import("main.zig").EntityID;

pub const Filter = struct {
    included: std.ArrayList(TypeID),
    excluded: std.ArrayList(TypeID),
    world: *World,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, world: *World) @This() {
        const included = std.ArrayList(TypeID).init(allocator);
        const excluded = std.ArrayList(TypeID).init(allocator);

        return .{
            .allocator = allocator,
            .included = included,
            .excluded = excluded,
            .world = world
        };
    }

    pub fn with(self: *Filter, comptime T: type) !void {
        try self.included.append(try self.world.getTypeAndInit(T));
    }

    pub fn without(self: *Filter, comptime T: type) !void {
        try self.excluded.append(try self.world.getTypeAndInit(T));
    }

    pub fn build(self: Filter, world: *World) !*EntityFilter {
        return try world.build(self);
    }

    pub fn deinit(self: @This()) void {
        self.included.deinit();
        self.excluded.deinit();
    }
};

pub const EntityFilter = struct {
    entities: Set(EntityID),
    filter: Filter,

    pub fn init(allocator: std.mem.Allocator, filter: Filter) EntityFilter {
        const entities = Set(EntityID).init(allocator);

        return .{
            .entities = entities,
            .filter = filter
        };
    }

    pub fn check(self: *EntityFilter, world: *World, entity: EntityID) void {
        for (self.filter.included.items) |included| {
            if (!world.hasComponentTypeID(included, entity)) {
                _ = self.entities.remove(entity);
                return;
            }
        }

        for (self.filter.excluded.items) |excluded| {
            if (world.hasComponentTypeID(excluded, entity)) {
                _ = self.entities.remove(entity);
                return;
            }
        }

        _ = self.entities.add(entity) catch {
            @panic("Out of memory!");
        };
    }

    pub fn remove(self: *EntityFilter, entity: EntityID) void {
        _ = self.entities.remove(entity);
    }

    pub fn deinit(self: *EntityFilter) void {
        self.entities.deinit();
        self.filter.deinit();
    }
};

pub const Signature = struct {
    hash: u64,

    pub fn init(hash: *std.hash.XxHash64, filter: Filter) Signature {
        var has_type = false;
        for (filter.included.items) |includ| {
            std.hash.autoHash(hash, @intFromPtr(includ));
            has_type = true;
        }

        for (filter.excluded.items) |exclud| {
            std.hash.autoHash(hash, @intFromPtr(exclud));
            has_type = true;
        }

        return .{
            .hash = if (has_type) hash.final() else 0
        };
    }
};

pub fn QueryFilter(tuples: anytype) type {
    return struct {
        const Self = @This();
        filter: *EntityFilter,
        tuples: @TypeOf(tuples),
        pub fn init(allocator: std.mem.Allocator, world: *World) !@This() {
            var filter = Filter.init(allocator, world);
            inline for (tuples) |t| {
                const contains = comptime blk: {
                    break :blk std.mem.containsAtLeast(u8, @typeName(t), 1, "ecs.filter.Without");
                };
                if (contains) {
                    try filter.without((t{}).t);
                } else {
                    try filter.with(t);
                }
            }

            return .{
                .filter = try filter.build(world),
                .tuples = tuples
            };
        }

        pub fn entities(self: Self) Set(EntityID) {
            return self.filter.entities;
        }
    };
}

pub fn Without(comptime T: type) type {
    return struct {
        t: type = T
    };
}