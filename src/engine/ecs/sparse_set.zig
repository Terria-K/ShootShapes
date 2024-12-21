const std = @import("std");


pub fn SparseSet(comptime page_size: usize) type {
    const dead = std.math.maxInt(u32);
    const Page = struct {
        sparse: [page_size]u32 = [_]u32{0} ** page_size,
    };

    return struct {
        const SparseSetPaginated = @This();
        allocator: std.mem.Allocator,
        sparse_page: []*Page,
        dense: *anyopaque,
        dense_size: usize = 0,
        dense_capacity: usize,
        dense_elem_size: usize,

        pub fn init(comptime T: type, allocator: std.mem.Allocator) !SparseSetPaginated {
            const data_size = @sizeOf(T);
            const sparse = try allocator.alloc(*Page, 1);
            const dense = try allocator.alloc(u8, data_size * 16);

            var sparse_page = try allocator.create(Page);
            @memset(&sparse_page.sparse, dead);
            sparse[0] = sparse_page;

            return .{
                .sparse_page = sparse,
                .dense = @ptrCast(dense),
                .allocator = allocator,
                .dense_elem_size = data_size,
                .dense_capacity = 16
            };
        }
        
        pub fn set(self: *SparseSetPaginated, comptime T: type, id: u32, value: T) !void {
            const page = id / page_size;
            const sparse_index = id % page_size;

            if (page >= self.sparse_page.len) {
                const old_size = self.sparse_page.len;
                if (self.allocator.resize(self.sparse_page, self.sparse_page.len + 1)) {
                    self.sparse_page.len += 1;
                } else {
                    self.sparse_page = try self.allocator.realloc(self.sparse_page, self.sparse_page.len + 1);
                }
                var sparse_page = try self.allocator.create(Page);
                @memset(&sparse_page.sparse, dead);
                self.sparse_page[old_size] = sparse_page;
            }

            var sparse_page = self.sparse_page[page];

            const size = self.dense_size;
            if (size >= self.dense_capacity) {
                try self.resizeDense();
            }

            @as([*]T, @alignCast(@ptrCast(self.dense)))[size] = value;
            sparse_page.sparse[sparse_index] = @intCast(size);
            self.dense_size += 1;
        }

        fn resizeDense(self: *SparseSetPaginated) !void {
            const bytes: []u8 = @as([*]u8, @alignCast(@ptrCast(self.dense)))[0..self.dense_elem_size * self.dense_capacity];
            self.dense_capacity *= 2;
            self.dense = @ptrCast(try self.allocator.realloc(bytes, self.dense_elem_size * self.dense_capacity));
        }

        pub inline fn get_index(self: SparseSetPaginated, id: u32) u32 {
            const page = id / page_size;
            const sparse_index = id % page_size;

            if (page < self.sparse_page.len) {
                const sparse_page = self.sparse_page[page];
                if (sparse_index < sparse_page.sparse.len) {
                    return sparse_page.sparse[sparse_index];
                }
            }

            return dead;
        }

        pub fn get(self: SparseSetPaginated, comptime T: type, id: u32) ?*T {
            const index = self.get_index(id);
            if (index == dead) {
                return null;
            }
            return &@as([*]T, @alignCast(@ptrCast(self.dense)))[index];
        }

        pub fn contains(self: SparseSetPaginated, id: u32) bool {
            return self.get_index(id) != dead;
        }

        pub fn remove(self: *SparseSetPaginated, id: u32) bool {
            const page = id / page_size;
            const sparse_index = id % page_size;

            const index = self.sparse_page[page].sparse[sparse_index];
            if (index == dead) {
                return false;
            }

            const last_index = self.dense_size - 1;
            var dense_aligned = @as([*]u8, @alignCast(@ptrCast(self.dense)));
            std.mem.swap(
                []u8, 
                @constCast(&dense_aligned[self.dense_elem_size * last_index..self.dense_elem_size * last_index + self.dense_elem_size]), 
                @constCast(&dense_aligned[self.dense_elem_size * index..self.dense_elem_size * index + self.dense_elem_size]));
            self.sparse_page[page].sparse[sparse_index] = dead;
            self.dense_size -= 1;
            return true;
        }

        pub fn deinit(self: SparseSetPaginated) void {
            self.allocator.free(@as([*]u8, @alignCast(@ptrCast(self.dense)))[0..self.dense_elem_size * self.dense_capacity]);
            for (self.sparse_page) |page| {
                self.allocator.destroy(page);
            }
            self.allocator.free(self.sparse_page);
        }
    };
}

test "Adding more elements" {
    var sparse_set =  try SparseSet(100).init(usize, std.testing.allocator);
    defer sparse_set.deinit();

    for (0..1000) |i| {
        try sparse_set.set(usize, @intCast(i), i);
    }
}

test "Sparse Set" {
    var sparse_set =  try SparseSet(10).init(u32, std.testing.allocator);
    defer sparse_set.deinit();
    try sparse_set.set(u32, 3, 5);
    try sparse_set.set(u32, 17, 8);

    try std.testing.expect(sparse_set.get(u32, 3).?.* == 5);
    try std.testing.expect(sparse_set.get(u32, 17).?.* == 8);

    try std.testing.expect(sparse_set.remove(3));
    try std.testing.expect(sparse_set.get(u32, 3) == null);

    try sparse_set.set(u32, 3, 9);
    try std.testing.expect(sparse_set.get(u32, 3).?.* == 9);
}