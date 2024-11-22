const Texture = @This();
const GraphicsDevice = @import("../graphics/GraphicsDevice.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const TextureFormat = @import("../enums/main.zig").TextureFormat;
handle: ?*sdl.SDL_GPUTexture,
width: u32,
height: u32,

pub fn init(device: GraphicsDevice, w: u32, h: u32, format: TextureFormat) Texture {
    return .{
        .width = w,
        .height = h,
        .handle = sdl.SDL_CreateGPUTexture(device.handle, sdl.SDL_GPUTextureCreateInfo {
            .width = w,
            .height = h,
            .format = @intCast(@intFromEnum(format)),
            .type = sdl.SDL_GPU_TEXTURETYPE_2D,
            .usage = sdl.SDL_GPU_TEXTUREUSAGE_SAMPLER,
            .layer_count_or_depth = 1,
            .sample_count = 1,
            .num_levels = 1
        })
    };
}

pub fn deinit(self: Texture, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUTexture(device.handle, self.handle);
}