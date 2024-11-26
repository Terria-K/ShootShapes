const Texture = @This();
const TextureRegion = @import("../structs/main.zig").TextureRegion;
const GraphicsDevice = @import("../graphics/GraphicsDevice.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const TextureFormat = @import("../enums/main.zig").TextureFormat;
handle: ?*sdl.SDL_GPUTexture,
width: u32,
height: u32,
depth: u32,

pub fn init(device: GraphicsDevice, w: u32, h: u32, format: TextureFormat) Texture {
    var create_info: sdl.SDL_GPUTextureCreateInfo = undefined;
    create_info.width = w;
    create_info.height = h;
    create_info.format = @intCast(@intFromEnum(format));
    create_info.type = sdl.SDL_GPU_TEXTURETYPE_2D;
    create_info.usage = sdl.SDL_GPU_TEXTUREUSAGE_SAMPLER;
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