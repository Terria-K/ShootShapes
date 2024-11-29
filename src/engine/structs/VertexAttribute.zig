const VertexAttribute = @This();
const std = @import("std");
const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;
location: u32,
buffer_slot: u32,
format: VertexElementFormat,
offset: u32,

pub fn attributes(allocator: std.mem.Allocator, comptime T: type, slot: u32) ![]VertexAttribute  {
    if (std.meta.hasFn(T, "generate")) {
        const elements = &T.generate();
        var attribs = try allocator.alloc(VertexAttribute, elements.len);

        var i: u32 = 0;
        inline for (elements) |element| {
            attribs[i] = .{
                .location = i,
                .buffer_slot = slot,
                .offset = element.offset,
                .format = element.format
            };
            i += 1;
        }

        return attribs;
    } else {
        @compileError("The type does not have generate() function");
    }
}