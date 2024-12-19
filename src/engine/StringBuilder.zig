const StringBuilder = @This();
const std = @import("std");
const Error = std.mem.Allocator.Error;

allocator: std.mem.Allocator,
buffer: []u8,
count: usize,

pub fn init(allocator: std.mem.Allocator) Error!StringBuilder {
    const buffer = try allocator.alloc(u8, 16);
    return .{
        .allocator = allocator,
        .buffer = buffer,
        .count = 0
    };
}

pub fn append(self: *StringBuilder, str: anytype) Error!void {
    const t = @typeInfo(@TypeOf(str));

    if (t == .Int or t == .Float) {
        const p = try std.fmt.allocPrint(self.allocator, "{d}", .{str});
        defer self.allocator.free(p);
        try self.putToBuffer(p);
    } else {
        try self.putToBuffer(@constCast(str));
    }
}

fn putToBuffer(self: *StringBuilder, str: []u8) Error!void {
    const str_len = str.len;
    if (self.count + str_len >= self.buffer.len) {
        try self.resize((self.count + str_len) * 2);
    }

    @memcpy(self.buffer[self.count..self.count + str_len], str);
    self.count += str_len;
}

/// Caller owns this memory, this does not deinitialized the StringBuilder
pub fn build(self: StringBuilder) Error![]u8 {
    const buffer = try self.allocator.alloc(u8, self.count);
    @memcpy(buffer, self.buffer[0..self.count]);

    return buffer;
}

pub fn clearRetainingCapacity(self: StringBuilder) void {
    self.count = 0;
}

pub fn clearAndFree(self: StringBuilder) void {
    self.deinit();
    self.clearRetainingCapacity();
}

pub fn capacity(self: StringBuilder) usize {
    return self.buffer.len;
}

pub fn deinit(self: StringBuilder) void {
    self.allocator.free(self.buffer);
}

fn resize(self: *StringBuilder, new_capacity: usize) Error!void {
    const new_memory = try self.allocator.alloc(u8, new_capacity);
    @memcpy(new_memory[0..self.buffer.len], self.buffer);
    self.allocator.free(self.buffer);
    self.buffer.ptr = new_memory.ptr;
    self.buffer.len = new_memory.len;
}