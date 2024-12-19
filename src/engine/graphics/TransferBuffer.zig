const TransferBuffer = @This();
const GraphicsDevice = @import("GraphicsDevice.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

pub const TransferBufferUsage = @import("../structs/main.zig").TransferBufferUsage;

handle: ?*sdl.SDL_GPUTransferBuffer,
device: GraphicsDevice,
is_mapped: bool = false,
size: u32,
usage: TransferBufferUsage,

pub fn init(comptime TypeSize: type, device: GraphicsDevice, size: u32, usage: TransferBufferUsage) TransferBuffer {
    var create_info: sdl.SDL_GPUTransferBufferCreateInfo = undefined;
    create_info.size = size * @sizeOf(TypeSize);
    create_info.usage = @bitCast(usage);
    const handle = sdl.SDL_CreateGPUTransferBuffer(device.handle, &create_info);
    return .{
        .handle = handle,
        .device = device,
        .size = size,
        .usage = usage
    };
}

pub fn initUnknown(device: GraphicsDevice, size: u32, usage: TransferBufferUsage) TransferBuffer {
    var create_info: sdl.SDL_GPUTransferBufferCreateInfo = undefined;
    create_info.size = size;
    create_info.usage = @bitCast(usage);
    const handle = sdl.SDL_CreateGPUTransferBuffer(device.handle, &create_info);
    return .{
        .usage = usage,
        .handle = handle,
        .device = device,
        .size = size,
    };
}

pub fn mapUnknown(self: *TransferBuffer, cycle: bool) ?*anyopaque {
    if (self.is_mapped) {
        @panic("Transfer Buffer is already mapped yet, unmapped it first to map it.");
    }

    self.is_mapped = true;

    const map_buffer = sdl.SDL_MapGPUTransferBuffer(self.device.handle, self.handle, cycle);
    return map_buffer;
    
}

pub fn map(self: *TransferBuffer, comptime T: type, cycle: bool) [*]T {
    if (self.is_mapped) {
        @panic("Transfer Buffer is already mapped yet, unmapped it first to map it.");
    }

    self.is_mapped = true;

    const map_buffer = sdl.SDL_MapGPUTransferBuffer(self.device.handle, self.handle, cycle);
    if (map_buffer) |m| {
        return @as([*]T, @ptrCast(@alignCast(m)))[0..];
    } else {
        @panic("Failed to mapped a transfer buffer.");
    }
}

pub fn unmap(self: *TransferBuffer) void {
    if (!self.is_mapped) {
        @panic("Transfer Buffer has not been mapped yet, map it first to unmap it.");
    }

    self.is_mapped = false;

    sdl.SDL_UnmapGPUTransferBuffer(self.device.handle, self.handle);
}

pub fn deinit(self: TransferBuffer, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUTransferBuffer(device.handle, self.handle); 
}