const World = @This();
const std = @import("std");
const Type = @import("typeid.zig").Type;
const TypeID = @import("typeid.zig").TypeID;
const filt = @import("filter.zig");
const EntityID = @import("main.zig").EntityID;
const TypeIDSet = @import("ziglangSet").Set(TypeID);
const Filter = filt.Filter;
const EntityFilter = filt.EntityFilter;
const Signature = filt.Signature;


component_storage: std.AutoHashMap(TypeID, ComponentStorage),
filter_storage: std.AutoHashMap(u64, *EntityFilter),
typeid_to_hash: std.AutoHashMap(TypeID, std.ArrayList(u64)),
entityid_to_typeid: std.ArrayList(TypeIDSet),
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
        .entityid_to_typeid = std.ArrayList(TypeIDSet).init(allocator),
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
    self.entityid_to_typeid.append(TypeIDSet.init(self.allocator)) catch {
        @panic("Out of Memory!");  
    };

    self.current_id += 1;
    return id;
}

pub fn createSystems(self: *World, comptime T: type) !T {
    var c: T = undefined;
    const fields = std.meta.fields(T);
    inline for (fields) |field| {
        @field(c, field.name) = try self.createSystem(field.type);
    }
    return c;
}

pub fn runSystems(self: *World, system_container: anytype, res: anytype) void {
    const fields = std.meta.fields(@TypeOf(system_container.*));
    inline for (fields) |field| {
        @field(system_container, field.name).run(self, res);
    }
}

pub fn deinitSystems(self: *World, system_container: anytype) void {
    const fields = std.meta.fields(@TypeOf(system_container));
    inline for (fields) |field| {
        self.deinitSystem(@field(system_container, field.name));
    }
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

inline fn setComponentInternal(self: *World, comptime T: type, data: T, entity: EntityID) !TypeID {
    const t = Type.id(T);
    var storage = try getStorage(self, T);
    try storage.set(T, data, entity);

    _ = try self.entityid_to_typeid.items[entity].add(t);
    return t;
}

pub fn setComponent(self: *World, comptime T: type, data: T, entity: EntityID) void {
    // can we just have a try block?
    const t = setComponentInternal(self, T, data, entity) catch |err| switch (err) {
        std.mem.Allocator.Error.OutOfMemory => @panic("Out of memory!")
    };

    if (self.typeid_to_hash.get(t)) |h| {
        for (h.items) |filter_hashes| {
            if (self.filter_storage.get(filter_hashes)) |filter| {
                filter.check(self, entity);
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

pub fn removeComponent(self: *World, comptime T: type, entity: EntityID) void {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        var stor = @constCast(&store);
        if (stor.remove(entity)) {
            _ = self.entityid_to_typeid.items[entity].remove(t);
            if (self.typeid_to_hash.get(t)) |h| {
                for (h.items) |filter_hashes| {
                    if (self.filter_storage.get(filter_hashes)) |filter| {
                        filter.check(self, entity);
                    }
                }
            }
        }
    }
}

pub fn destroy(self: *World, entity: EntityID) void {
    var component_set = self.entityid_to_typeid.items[entity];
    var iter = component_set.iterator();
    while (iter.next()) |component_id| {
        // we used ? because we are sure that component_storage is not null at this point
        var store = self.component_storage.get(component_id.*).?;
        _ = store.remove(entity);

        if (self.typeid_to_hash.get(component_id.*)) |h| {
            for (h.items) |filter_hashes| {
                if (self.filter_storage.get(filter_hashes)) |filter| {
                    filter.remove(entity);
                }
            }
        }
    }

    component_set.clearRetainingCapacity();
    self.entity_id_stack.append(entity) catch {
        @panic("Out of memory!");
    };
}

pub fn getReadOnlyComponent(self: *World, comptime T: type, entity: EntityID) *const T {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        return store.get(T, entity);
    }

    @panic("Component Type does not existed or used yet.");
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


const type_to_compare = @import("../ecs/filter.zig").EntityFilter;
fn deinitSystem(self: *World, system: anytype) void {
    const fields = std.meta.fields(@TypeOf(system));
    inline for (fields) |field| {
        if (field.type != *type_to_compare) {
            continue;
        }

        @field(system, field.name).deinit();
        self.allocator.destroy(@field(system, field.name));
    }
}

fn createSystem(self: *World, comptime T: type) !T {
    const fields = std.meta.fields(T);
    var system: T = undefined;
    inline for (fields) |field| {
        if (field.type != *type_to_compare) {
            continue;
        }

        var filter = createFilter(self);
        if (@hasDecl(T, field.name ++ "With")) {
            const types =  @field(T, field.name ++ "With");
            inline for (types) |t| {
                try filter.with(t);
            }

        } 

        if (@hasDecl(T, field.name ++ "Without"))  {
            const types =  @field(T, field.name ++ "Without");
            inline for (types) |t| {
                try filter.without(t);
            }
        }

        @field(system, field.name) = try filter.build(self);
    }
    return system;
}


pub fn deinit(self: *World) void {
    var citer = self.component_storage.valueIterator();
    while (citer.next()) |storage| {
        storage.deinit();
    }

    var tider = self.typeid_to_hash.valueIterator();
    while (tider.next()) |arr| {
        arr.deinit();
    }

    for (0..self.entityid_to_typeid.items.len) |i| {
        var item: TypeIDSet = self.entityid_to_typeid.items[i];
        item.deinit();
    }

    self.component_storage.deinit();
    self.filter_storage.deinit();
    self.typeid_to_hash.deinit();
    self.entityid_to_typeid.deinit();
    self.entity_id_stack.deinit();
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
        const data = try allocator.alloc(u8, data_size * 16);
        return .{
            .data = @ptrCast(data),
            .capacity = 16,
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
            entity_idx.value_ptr.* = @intCast(self.count);

            try self.entities.append(entity_id);
            if (self.count >= self.capacity) {
                try self.resize();
            }

            @as([*]T, @alignCast(@ptrCast(self.data)))[self.count] = data;

            self.count += 1;
        }
    }

    pub fn get(self: ComponentStorage, comptime T: type, i: u32) *T {
        const index = self.entity_index.get(i);
        return &@as([*]T, @alignCast(@ptrCast(self.data)))[index.?];
    }

    pub fn remove(self: *ComponentStorage, i: u32) bool {
        const index = self.entity_index.get(i);

        if (index) |ind| {
            const last_element_index = self.count - 1;
            const last_entity = self.entities.items[last_element_index];

            if (ind != last_element_index) {
                const dest_dist = (ind * self.elem_size);
                const src_dist = (last_element_index * self.elem_size);
                @memcpy(
                    @as([*]u8, @ptrCast(self.data))[dest_dist..dest_dist + self.elem_size], 
                    @as([*]u8, @ptrCast(self.data))[src_dist..src_dist + self.elem_size]
                );
            }
            self.count -= 1;
            _ = self.entities.orderedRemove(ind);
            _ = self.entity_index.remove(i);
            if (last_element_index != ind) {
                self.entity_index.putAssumeCapacity(last_entity, ind);
            }
            return true;
        }
        return false;
    }

    pub fn deinit(self: *ComponentStorage) void {
        self.allocator.free(@as([*]u8, @alignCast(@ptrCast(self.data)))[0..self.elem_size * self.capacity]);
        self.entity_index.deinit();
        self.entities.deinit();
    }

    fn resize(self: *ComponentStorage) !void {
        const bytes: []u8 = @as([*]u8, @alignCast(@ptrCast(self.data)))[0..self.elem_size * self.capacity];
        self.capacity *= 2;
        self.data = @ptrCast(try self.allocator.realloc(bytes, self.elem_size * self.capacity));
    }
};