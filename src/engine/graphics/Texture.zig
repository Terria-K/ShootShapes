const Texture = @This();
const structs = @import("../structs.zig");
const TextureRegion = structs.TextureRegion;
const TextureUsage = structs.TextureUsage;
const TransferBuffer = @import("TransferBuffer.zig");
const GraphicsDevice = @import("../graphics/GraphicsDevice.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const TextureFormat = @import("../enums/main.zig").TextureFormat;

pub const Error = error { TransferNotUsedForDownload };

handle: ?*sdl.SDL_GPUTexture,
width: u32,
height: u32,
depth: u32,

pub fn init(device: GraphicsDevice, w: u32, h: u32, format: TextureFormat, usage: TextureUsage) Texture {
    var create_info: sdl.SDL_GPUTextureCreateInfo = undefined;
    create_info.width = w;
    create_info.height = h;
    create_info.format = @intCast(@intFromEnum(format));
    create_info.type = sdl.SDL_GPU_TEXTURETYPE_2D;
    create_info.usage = @bitCast(usage);
    create_info.layer_count_or_depth = 1;
    create_info.sample_count = sdl.SDL_GPU_SAMPLECOUNT_1;
    create_info.num_levels = 1;
    return .{
        .width = w,
        .height = h,
        .handle = sdl.SDL_CreateGPUTexture(device.handle, &create_info),
        .depth = 1
    };
}

pub fn download(self: Texture, device: GraphicsDevice, transfer_buffer: TransferBuffer) Error!void {
    if (!transfer_buffer.usage.download) {
        return Error.TransferNotUsedForDownload;
    }

    const buffer = device.acquireCommandBuffer();
    const copy_pass = buffer.beginCopyPass();
    copy_pass.downloadFromTexture(self.toRegion(), .{
        .transfer_buffer = transfer_buffer
    });
    copy_pass.end();
    buffer.submit();
}

pub fn toRegion(self: Texture) TextureRegion {
    return .{
        .texture = self,
        .w = self.width,
        .h = self.height,
        .d = self.depth
    };
}

pub fn deinit(self: Texture, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUTexture(device.handle, self.handle);
}