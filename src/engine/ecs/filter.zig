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
        self.allocator.destroy(self.included);
        self.allocator.destroy(self.excluded);
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

    pub fn check(self: *EntityFilter, world: *World, entity: EntityID) !void {
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

        _ = try self.entities.add(entity);
    }
};

pub const Signature = struct {
    hash: u64,

    pub fn init(hash: *std.hash.XxHash64, filter: Filter) Signature {
        for (filter.included.items) |includ| {
            std.hash.autoHash(hash, @intFromPtr(includ));
        }

        for (filter.excluded.items) |exclud| {
            std.hash.autoHash(hash, @intFromPtr(exclud));
        }

        return .{
            .hash = hash.final()
        };
    }
};