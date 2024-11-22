const std = @import("std");
const structs = @import("main.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const TextureFormat = @import("../enums/main.zig").TextureFormat;
const ColorTargetDescription = @import("ColorTargetDescription.zig");

color_target_descriptions: []const ColorTargetDescription,
depth_stencil_format: ?TextureFormat = null,

pub fn conversion(self: @This()) [64]sdl.SDL_GPUColorTargetDescription {
    var bounded 
        = std.BoundedArray(sdl.SDL_GPUColorTargetDescription, 64).init(self.color_target_descriptions.len) catch {
            @panic("Overflowed");
        };
    var i: usize = 0;
    for (self.color_target_descriptions) |description| {
        bounded.set(i, .{
            .format = @intCast(@intFromEnum(description.format)),
            .blend_state = structs.convertToSDL(sdl.SDL_GPUColorTargetBlendState, description.blend_state)
        });
        i += 1;
    }

    return bounded.buffer;
}