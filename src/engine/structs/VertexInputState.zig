const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const structs = @import("main.zig");
const VertexInputState = @This();
const VertexBufferDescription = @import("VertexBufferDescription.zig");
const VertexAttribute = @import("VertexAttribute.zig");
vertex_buffer_descriptions: []VertexBufferDescription,
vertex_attributes:  []VertexAttribute,

pub inline fn conversion(self: VertexInputState) sdl.SDL_GPUVertexInputState {
    var attributes_bound 
        = std.BoundedArray(sdl.SDL_GPUVertexAttribute, 32).init(self.vertex_attributes.len) catch {
            @panic("Overflowed");
        };
    var i: usize = 0;
    for (self.vertex_attributes) |attribute| {
        attributes_bound.set(i, structs.convertToSDL(sdl.SDL_GPUVertexAttribute, attribute));
        i += 1;
    }

    var description_bound 
        = std.BoundedArray(sdl.SDL_GPUVertexBufferDescription, 8).init(self.vertex_buffer_descriptions.len) catch {
            @panic("Overflowed");
        };
    var j: usize = 0;
    for (self.vertex_buffer_descriptions) |description| {
        description_bound.set(j, structs.convertToSDL(sdl.SDL_GPUVertexBufferDescription, description));
        j += 1;
    }

    return sdl.SDL_GPUVertexInputState {
        .num_vertex_attributes = @intCast(self.vertex_attributes.len),
        .num_vertex_buffers = @intCast(self.vertex_buffer_descriptions.len),
        .vertex_attributes = @ptrCast(&attributes_bound.buffer),
        .vertex_buffer_descriptions = @ptrCast(&description_bound.buffer)
    };
}