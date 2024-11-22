const World = @This();
const std = @import("std");
const Type = @import("typeid.zig").Type;
const TypeID = @import("typeid.zig").TypeID;
const filt = @import("filter.zig");
const EntityID = @import("main.zig").EntityID;
const Filter = filt.Filter;
const EntityFilter = filt.EntityFilter;
const Signature = filt.Signature;
component_storage: std.AutoHashMap(TypeID, ComponentStorage),
filter_storage: std.AutoHashMap(u64, *EntityFilter),
typeid_to_hash: std.AutoHashMap(TypeID, std.ArrayList(u64)),
hash: std.hash.XxHash64,
entity_id_stack: std.ArrayList(EntityID),
current_id: EntityID,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !World {
    return .{
        .current_id = 0,
        .component_storage = std.AutoHashMap(TypeID, ComponentStorage).init(allocator),
        .allocator = allocator,
        .filter_storage = std.AutoHashMap(u64, *EntityFilter).init(allocator),
        .typeid_to_hash = std.AutoHashMap(TypeID, std.ArrayList(u64)).init(allocator),
        .entity_id_stack = std.ArrayList(EntityID).init(allocator),
        .hash = std.hash.XxHash64.init(blk: { 
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed)) ;
            break :blk seed;
        })
    };
}

pub fn createEntity(self: *World) EntityID {
    const popped_id = self.entity_id_stack.popOrNull();
    if (popped_id) |id| {
        return id;
    }
    const id = self.current_id;

    self.current_id += 1;
    return id;
}

fn getStorage(self: *World, comptime T: type) !*ComponentStorage {
    const t = Type.id(T);
    const storage = try self.component_storage.getOrPut(t);
    if (!storage.found_existing) {
        storage.value_ptr.* = try ComponentStorage.init(T, self.allocator);
        try self.typeid_to_hash.put(t, std.ArrayList(u64).init(self.allocator));
    }
    return storage.value_ptr;
}

pub fn getTypeAndInit(self: *World, comptime T: type) !TypeID {
    const t = Type.id(T);
    const storage = try self.component_storage.getOrPut(t);
    if (!storage.found_existing) {
        storage.value_ptr.* = try ComponentStorage.init(T, self.allocator);
        try self.typeid_to_hash.put(t, std.ArrayList(u64).init(self.allocator));
    }

    return t;
}

pub fn setComponent(self: *World, comptime T: type, data: anytype, entity: EntityID) !void {
    const t = Type.id(T);
    var storage = try getStorage(self, T);
    try storage.set(T, data, entity);

    if (self.typeid_to_hash.get(t)) |h| {
        for (h.items) |filter_hashes| {
            if (self.filter_storage.get(filter_hashes)) |filter| {
                try EntityFilter.check(filter, self, entity);
            }
        }
    }
}

pub fn hasComponent(self: *World, comptime T: type, entity: EntityID) bool {
    return self.hasComponentTypeID(Type.id(T), entity);
}

pub fn hasComponentTypeID(self: *World, t: TypeID, entity: EntityID) bool {
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        return ComponentStorage.has(@constCast(&store), entity);
    }
    return false;
}

pub fn getComponent(self: *World, comptime T: type, entity: EntityID) *T {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        return store.get(T, entity);
    }

    @panic("Component Type does not existed or used yet.");
}

pub fn createFilter(self: *World) Filter {
    return Filter.init(self.allocator, self);
}

pub fn build(self: *World, filter: Filter) !*EntityFilter {
    const sign = Signature.init(&self.hash, filter);

    const filter_storage = try self.filter_storage.getOrPut(sign.hash);
    if (!filter_storage.found_existing) {
        const entity_filter = try self.allocator.create(EntityFilter);
        entity_filter.* = EntityFilter.init(self.allocator, filter);

        for (filter.included.items) |include| {
            const arr = self.typeid_to_hash.getPtr(include);
            if (arr) |a| {
                try a.append(sign.hash);
            }
        }

        for (filter.excluded.items) |exclude| {
            const arr = self.typeid_to_hash.getPtr(exclude);
            if (arr) |a| {
                try a.append(sign.hash);
            }
        }

        filter_storage.value_ptr.* = entity_filter;
    }

    return filter_storage.value_ptr.*;
}


pub fn forEach(self: *World, comptime T: type, comptime update: fn(e: EntityID, c: *T) void) void {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);

    if (storage) | store| {
        for (0..2) |i| {
            const data = store.get(T, @intCast(i));
            update(@intCast(i), data);
        }
    } else {
        @panic("Component Type does not existed or used yet.");
    }
}

pub const ComponentStorage = struct {
    data: *anyopaque,
    entities: std.ArrayList(EntityID),
    capacity: usize,
    count: usize,
    elem_size: usize,
    allocator: std.mem.Allocator,
    entity_index: std.AutoHashMap(EntityID, u32),

    pub fn init(comptime T: type, allocator: std.mem.Allocator) !ComponentStorage {
        const data_size = @sizeOf(T);
        const initial_size = data_size * 16;
        const data = try allocator.alloc(T, 16);
        return .{
            .data = @ptrCast(data),
            .capacity = initial_size,
            .elem_size = data_size,
            .count = 0,
            .allocator = allocator,
            .entities = std.ArrayList(EntityID).init(allocator),
            .entity_index = std.AutoHashMap(EntityID, u32).init(allocator)
        };
    }

    pub fn has(self: *ComponentStorage, entity: EntityID) bool {
        return self.entity_index.contains(entity);
    }

    pub fn set(self: *ComponentStorage, comptime T: type, data: T, entity_id: EntityID) !void {
        const entity_idx = try self.entity_index.getOrPut(entity_id);

        if (entity_idx.found_existing) {
            @as([*]T, @alignCast(@ptrCast(self.data)))[entity_idx.value_ptr.*] = data;
        } else {
            entity_idx.value_ptr.* = self.entity_index.count();

            try self.entities.append(entity_id);
            if (self.count >= self.capacity) {
                try self.resize();
            }

            @as([*]T, @alignCast(@ptrCast(self.data)))[self.count] = data;

            self.count += 1;
        }
    }

    pub fn get(self: ComponentStorage, comptime T: type, i: u32) *T {
        return &@as([*]T, @alignCast(@ptrCast(self.data)))[i];
    }

    pub fn deinit(self: *ComponentStorage) void {
        self.allocator.free(self.data);
    }

    fn resize(self: *ComponentStorage) !void {
        const bytes: []u8 = @as([*]u8, @ptrCast(self.data))[0..self.elem_size * self.capacity];
        self.capacity *= 2;
        self.data = @ptrCast(try self.allocator.realloc(bytes, self.elem_size * self.capacity));
    }
};