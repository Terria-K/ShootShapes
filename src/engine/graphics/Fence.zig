const Fence = @This();
const GraphicsDevice = @import("GraphicsDevice.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

handle: ?*sdl.SDL_GPUFence,
pub fn init(handle: ?*sdl.SDL_GPUFence) Fence {
    return .{
        .handle = handle
    };
}

pub fn deinit(self: Fence, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUFence(device.handle, self.handle);
}