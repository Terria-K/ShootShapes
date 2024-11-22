const GpuBuffer = @This();
const GraphicsDevice = @import("GraphicsDevice.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const structs = @import("../structs/main.zig");
handle: ?*sdl.SDL_GPUBuffer,
size: u32,

pub fn init(comptime TypeSize: type, device: GraphicsDevice, size: u32, usage: structs.BufferUsage) GpuBuffer {
    const tsize = @sizeOf(TypeSize) * size;
    var create_info: sdl.SDL_GPUBufferCreateInfo = undefined;
    create_info.size = tsize;
    create_info.usage = @bitCast(usage);
    const handle = sdl.SDL_CreateGPUBuffer(device.handle, &create_info);
    return .{
        .handle = handle,
        .size = tsize
    };
}

pub fn deinit(self: GpuBuffer, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUBuffer(device.handle, self.handle);
}