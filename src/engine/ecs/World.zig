const World = @This();
const std = @import("std");
const Type = @import("typeid.zig").Type;
const TypeID = @import("typeid.zig").TypeID;
const filt = @import("filter.zig");
const EntityID = @import("main.zig").EntityID;
const TypeIDSet = @import("ziglangSet").Set(TypeID);
const EntityIDSet = @import("ziglangSet").Set(EntityID);
const Filter = filt.Filter;
const EntityFilter = filt.EntityFilter;
const Signature = filt.Signature;


component_storage: std.AutoHashMap(TypeID, ComponentStorage),
entityid_to_typeid_component: std.ArrayList(TypeIDSet),

relation_storage: std.AutoHashMap(TypeID, RelationComponentStorage),
entityid_to_typeid_relation: std.ArrayList(TypeIDSet),

message_storage: std.AutoHashMap(TypeID, MessageStorage),

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
        .relation_storage = std.AutoHashMap(TypeID, RelationComponentStorage).init(allocator),
        .message_storage = std.AutoHashMap(TypeID, MessageStorage).init(allocator),
        .allocator = allocator,
        .filter_storage = std.AutoHashMap(u64, *EntityFilter).init(allocator),
        .typeid_to_hash = std.AutoHashMap(TypeID, std.ArrayList(u64)).init(allocator),
        .entity_id_stack = std.ArrayList(EntityID).init(allocator),
        .entityid_to_typeid_component = std.ArrayList(TypeIDSet).init(allocator),
        .entityid_to_typeid_relation = std.ArrayList(TypeIDSet).init(allocator),
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
    self.entityid_to_typeid_component.append(TypeIDSet.init(self.allocator)) catch {
        @panic("Out of Memory!");  
    };
    self.entityid_to_typeid_relation.append(TypeIDSet.init(self.allocator)) catch {
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
    var storage = try self.getStorage(T);
    try storage.set(T, data, entity);

    _ = try self.entityid_to_typeid_component.items[entity].add(t);
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

pub fn getReadOnlyComponent(self: *World, comptime T: type, entity: EntityID) *const T {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        if (store.get(T, entity)) |component| {
            return component;
        }
    }

    @panic("Component Type does not existed or used yet.");
}

pub fn getComponent(self: *World, comptime T: type, entity: EntityID) *T {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        if (store.get(T, entity)) |component| {
            return component;
        }
    }

    @panic("Component Type does not existed or used yet.");
}

pub fn tryGetComponent(self: *World, comptime T: type, entity: EntityID) ?*T {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        return store.get(T, entity);
    } else {
        return null;
    }
}

pub fn removeComponent(self: *World, comptime T: type, entity: EntityID) void {
    const t = Type.id(T);
    const storage = self.component_storage.get(t);
    if (storage) |store| {
        var stor = @constCast(&store);
        if (stor.remove(entity)) {
            _ = self.entityid_to_typeid_component.items[entity].remove(t);
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

fn getRelationStorage(self: *World, comptime T: type) !*RelationComponentStorage {
    const t = Type.id(T);
    const storage = try self.relation_storage.getOrPut(t);
    if (!storage.found_existing) {
        storage.value_ptr.* = try RelationComponentStorage.init(T, self.allocator);
    }
    return storage.value_ptr;
}

fn setComponentRelationInternal(self: *World, comptime T: type, data: T, admirer: EntityID, target: EntityID) !void {
    const t = Type.id(T);
    var storage = try self.getRelationStorage(T);
    try storage.set(T, data, admirer, target);

    _ = try self.entityid_to_typeid_relation.items[admirer].add(t);
    _ = try self.entityid_to_typeid_relation.items[target].add(t);
}

pub fn setComponentRelation(self: *World, comptime T: type, data: T, admirer: EntityID, target: EntityID) void {
    self.setComponentRelationInternal(T, data, admirer, target) catch {
        @panic("Out of Memory");
    };
}

pub fn hasComponentRelation(self: *World, comptime T: type, admirer: EntityID, target: EntityID) bool {
    const t = Type.id(T);
    const storage = self.relation_storage.get(t);
    if (storage) |store| {
        return store.hasRelations(admirer, target);
    }

    return false;
}

pub fn hasAdmirerComponentRelation(self: *World, comptime T: type, entity: EntityID) bool {
    const t = Type.id(T);
    const storage = self.relation_storage.get(t);
    if (storage) |store| {
        return store.has(entity);
    }

    return false;
}

pub fn getAllAdmirerRelations(self: *World, comptime T: type, target: EntityID) ?EntityIDSet {
    const t = Type.id(T);
    const storage = self.relation_storage.get(t);
    if (storage) |store| {
        return store.targets.get(target);
    }

    return null;
}

pub fn getAllTargetRelations(self: *World, comptime T: type, admirer: EntityID) ?EntityIDSet {
    const t = Type.id(T);
    const storage = self.relation_storage.get(t);
    if (storage) |store| {
        return store.admirers.get(admirer);
    }
    return null;
}

pub fn getComponentRelation(self: *World, comptime T: type, admirer: EntityID, target: EntityID) ?*T {
    const t = Type.id(T);
    const storage = self.relation_storage.get(t);
    if (storage) |store| {
        return store.get(T, admirer, target);
    }

    return null;
}

pub fn sendMessage(self: *World, comptime T: type, data: T) void {
    const id = Type.id(T);
    const result = self.message_storage.getOrPut(id) catch @panic("Out of Memory");
    if (!result.found_existing) {
        result.value_ptr.* = MessageStorage.init(T, self.allocator) catch @panic("Out of Memory");
    } 

    result.value_ptr.*.add(T, data) catch @panic("Out of Memory");
}

pub fn receiveFirstMessage(self: *World, comptime T: type) ?*const T {
    const id = Type.id(T);
    const storage = self.message_storage.get(id);
    if (storage) |message| {
        if (message.count > 0) {
            return message.getFirst(T);
        }
    }

    return null;
}

pub fn receiveAllMessage(self: *World, comptime T: type) ?[]T {
    const id = Type.id(T);
    if (self.message_storage.get(id)) |message| {
        if (message.count > 0) {
            return message.getAll(T);
        }
    }

    return null;
}

pub fn hasMessage(self: *World, comptime T: type) bool {
    const id = Type.id(T);
    if (self.message_storage.get(id)) |message| {
        return message.hasSome();
    }
    return false;
}

pub fn update(self: *World) void {
    var storage = self.message_storage.valueIterator();
    while (storage.next()) |n| {
        n.clear();
    }
}

pub fn destroy(self: *World, entity: EntityID) void {
    var relation_set = self.entityid_to_typeid_relation.items[entity];
    var component_set = self.entityid_to_typeid_component.items[entity];
    var iter = component_set.iterator();
    while (iter.next()) |component_id| {
        // we used ? because we are sure that component_storage is not null at this point
        var store = self.component_storage.getPtr(component_id.*).?;
        _ = store.remove(entity);

        if (self.typeid_to_hash.get(component_id.*)) |h| {
            for (h.items) |filter_hashes| {
                if (self.filter_storage.get(filter_hashes)) |filter| {
                    filter.remove(entity);
                }
            }
        }
    }

    var iter_relation = relation_set.iterator();
    while (iter_relation.next()) |relation_id| {
        var store = self.relation_storage.getPtr(relation_id.*).?;
        store.remove(entity);
    }

    component_set.clearRetainingCapacity();
    relation_set.clearRetainingCapacity();
    self.entity_id_stack.append(entity) catch {
        @panic("Out of memory!");
    };
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


fn deinitSystem(self: *World, system: anytype) void {
    const fields = std.meta.fields(@TypeOf(system));
    inline for (fields) |field| {
        @field(system, field.name).filter.deinit();
        self.allocator.destroy(@field(system, field.name).filter);
    }
}

fn createSystem(self: *World, comptime T: type) !T {
    const fields = std.meta.fields(T);
    var system: T = undefined;
    inline for (fields) |field| {
        const query = try field.type.init(self.allocator, self);

        @field(system, field.name) = query;
    }
    return system;
}


pub fn deinit(self: *World) void {
    var citer = self.component_storage.valueIterator();
    while (citer.next()) |storage| {
        storage.deinit();
    }

    var rciter = self.relation_storage.valueIterator();
    while (rciter.next()) |storage| {
        storage.deinit();
    }

    var mciter = self.message_storage.valueIterator();
    while (mciter.next()) |storage| {
        storage.deinit();
    }

    var tider = self.typeid_to_hash.valueIterator();
    while (tider.next()) |arr| {
        arr.deinit();
    }

    for (0..self.entityid_to_typeid_component.items.len) |i| {
        var item: TypeIDSet = self.entityid_to_typeid_component.items[i];
        item.deinit();
    }

    for (0..self.entityid_to_typeid_relation.items.len) |i| {
        var item: TypeIDSet = self.entityid_to_typeid_relation.items[i];
        item.deinit();
    }

    self.component_storage.deinit();
    self.relation_storage.deinit();
    self.message_storage.deinit();
    self.filter_storage.deinit();
    self.typeid_to_hash.deinit();
    self.entityid_to_typeid_component.deinit();
    self.entityid_to_typeid_relation.deinit();
    self.entity_id_stack.deinit();
}

const SparseSet = @import("sparse_set.zig").SparseSet(100);


pub const ComponentStorage = struct {
    const Self = @This();
    sparse_set: SparseSet,
    allocator: std.mem.Allocator,

    pub fn init(comptime T: type, allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .sparse_set = try SparseSet.init(T, allocator)
        };
    }

    pub fn has(self: *Self, entity: EntityID) bool {
        return self.sparse_set.contains(entity);
    }

    pub fn set(self: *Self, comptime T: type, data: T, entity_id: EntityID) !void {
        try self.sparse_set.set(T, entity_id, data);
    }

    pub fn get(self: Self, comptime T: type, i: u32) ?*T {
        return self.sparse_set.get(T, i);
    }

    pub fn remove(self: *Self, i: u32) bool {
        return self.sparse_set.remove(i);
    }

    pub fn deinit(self: *Self) void {
        self.sparse_set.deinit();
    }
};

const Relationship = struct {
    a1: EntityID,
    a2: EntityID
};

const RelationshipIndex = u32;

pub const RelationComponentStorage = struct {
    const Self = @This();
    sparse_set: SparseSet,
    relation_map: std.AutoHashMap(Relationship, RelationshipIndex),
    index_to_relationship: std.AutoHashMap(RelationshipIndex, Relationship),
    admirers: std.AutoHashMap(EntityID, EntityIDSet),
    targets: std.AutoHashMap(EntityID, EntityIDSet),
    id_set_pool: std.ArrayList(EntityIDSet),
    allocator: std.mem.Allocator,

    pub fn init(comptime T: type, allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .relation_map = std.AutoHashMap(Relationship, RelationshipIndex).init(allocator),
            .admirers = std.AutoHashMap(EntityID, EntityIDSet).init(allocator),
            .targets = std.AutoHashMap(EntityID, EntityIDSet).init(allocator),
            .index_to_relationship = std.AutoHashMap(RelationshipIndex, Relationship).init(allocator),
            .sparse_set = try SparseSet.init(T, allocator),
            .id_set_pool = std.ArrayList(EntityIDSet).init(allocator)
        };
    }

    fn createOrGetIDSet(self: *Self) EntityIDSet {
        if (self.id_set_pool.popOrNull()) |id_set| {
            var no_const_id_set = @constCast(&id_set);
            no_const_id_set.clearRetainingCapacity();
            return no_const_id_set.*;
        }

        return EntityIDSet.init(self.allocator);
    }

    fn removeIDSet(self: *Self, id_set: EntityIDSet) void {
        self.id_set_pool.append(id_set) catch {
            @panic("Out of Memory");
        };
    }

    pub fn hasRelations(self: *const Self, admirer: EntityID, target: EntityID) bool {
        const relationship = Relationship { .a1 = admirer, .a2 = target };
        return self.relation_map.contains(relationship);
    }

    pub fn has(self: *const Self, entity: EntityID) bool {
        if (self.admirers.get(entity)) |sets| {
            return !sets.isEmpty();
        }
        return false;
    }

    pub fn set(self: *Self, comptime T: type, data: T, admirer: EntityID, target: EntityID) !void {
        const index: u32 = @intCast(self.sparse_set.dense_size);
        const relationship = Relationship { .a1 = admirer, .a2 = target };
        try self.relation_map.put(relationship, index);
        try self.sparse_set.set(T, index, data);
        try self.index_to_relationship.put(index, relationship);
        const admirer_relation = try self.admirers.getOrPut(admirer);
        if (!admirer_relation.found_existing) {
            admirer_relation.value_ptr.* = self.createOrGetIDSet();
        }

        _ = try admirer_relation.value_ptr.*.add(target);

        const target_relation = try self.targets.getOrPut(target);
        if (!target_relation.found_existing) {
            target_relation.value_ptr.* = self.createOrGetIDSet();
        }

        _ = try target_relation.value_ptr.*.add(admirer);
    }

    pub fn get(self: Self, comptime T: type, admirer: u32, target: u32) ?*T {
        if (self.relation_map.get(Relationship { .a1 = admirer, .a2 = target })) |index| {
            return self.sparse_set.get(T, index);
        }
        return null;
    }

    pub fn removeRelation(self: *Self, admirer: u32, target: u32) void {
        // removed all admirer's target
        if (self.admirers.getPtr(admirer)) |sets| {
            _ = sets.remove(target);
        }

        // removed all target's admirer
        if (self.targets.getPtr(target)) |sets| {
            _ = sets.remove(admirer);
        }

        const key = Relationship { .a1 = admirer, .a2 = target};
        if (self.relation_map.get(key)) |index| {
            const last_element: u32 = @intCast(self.sparse_set.dense_size - 1);
            // we swapped the element that is about to removed to the last element

            // [0: 1] [R: 2] [0: 3] [L: 4]
            if (index != last_element) {
                const last_relationship = self.index_to_relationship.get(last_element).?;
                // [0: 1] [R: 2] [0: 3] [L: 2]
                _ = self.relation_map.remove(key);
                self.relation_map.putAssumeCapacity(last_relationship, index);
            }
            // [0: 1] [R: null] [0: 3] [L: 2]
            _ = self.index_to_relationship.remove(index);
            self.index_to_relationship.putAssumeCapacity(last_element, key);
            // [0: 1] [L: 2] [0: 3] [R: null]
            _ = self.sparse_set.remove(index);
        }
    }

    pub fn remove(self: *Self, i: u32) void {
        if (self.targets.get(i)) |sets| {
            var iter = sets.iterator();
            while (iter.next()) |admirer| {
                self.removeRelation(admirer.*, i);
            } 

            self.removeIDSet(sets);
            _ = self.targets.remove(i);
        }

        if (self.admirers.get(i)) |sets| {
            var iter = sets.iterator();
            while (iter.next()) |target| {
                self.removeRelation(i, target.*);
            } 

            self.removeIDSet(sets);
            _ = self.admirers.remove(i);
        }
        if (self.admirers.get(i)) |sets| {
            std.log.info("{any}", .{sets.isEmpty()});
        }
    }

    pub fn deinit(self: *Self) void {
        self.sparse_set.deinit();
        self.relation_map.deinit();
        self.index_to_relationship.deinit();

        var iter = self.admirers.valueIterator();
        while (iter.next()) |r| {
            r.deinit();
        }

        var iter_2 = self.targets.valueIterator();
        while (iter_2.next()) |r| {
            r.deinit();
        }

        for (0..self.id_set_pool.items.len) |i| {
            self.id_set_pool.items[i].deinit();
        }
        self.admirers.deinit();
        self.targets.deinit();
        self.id_set_pool.deinit();
    } 
};

pub const MessageStorage = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    elem_size: usize,
    data: ?*anyopaque,
    capacity: usize,
    count: usize,

    pub fn init(comptime T: type, allocator: std.mem.Allocator) !Self {
        const data_size = @sizeOf(T);
        const data = try allocator.alloc(u8, data_size * 16);
        return .{
            .allocator = allocator,
            .data = @ptrCast(data),
            .capacity = 16,
            .count = 0,
            .elem_size = data_size
        };
    }

    fn resize(self: *Self) !void {
        const data = @as([*]u8, @alignCast(@ptrCast(self.data)))[0..self.elem_size * self.capacity];
        self.capacity *= 2;
        self.data = @ptrCast(try self.allocator.realloc(data, self.elem_size * self.capacity));
    }

    pub fn add(self: *Self, comptime T: type, data: T) !void {
        if (self.count >= self.capacity) {
            try self.resize();
        }
        @as([*]T, @alignCast(@ptrCast(self.data)))[self.count] = data;
        self.count += 1;
    }

    pub fn hasSome(self: *const Self) bool {
        return self.count > 0;
    }

    pub fn getAll(self: *Self, comptime T: type) []T {
        return @as([*]T, @alignCast(@ptrCast(self.data)))[0..self.count];
    }

    pub fn getFirst(self: *const Self, comptime T: type) *T {
        return &@as([*]T, @alignCast(@ptrCast(self.data)))[0];
    }

    pub fn clear(self: *Self) void {
        self.count = 0;
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(@as([*]u8, @alignCast(@ptrCast(self.data)))[0..self.elem_size * self.capacity]);
    }
};