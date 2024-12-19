const Sampler = @This();
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const GraphicsDevice = @import("GraphicsDevice.zig");
const structs = @import("../structs/main.zig");
const enums = @import("../enums/main.zig");
pub const SamplerCreateInfo = structs.SamplerCreateInfo;


handle: ?*sdl.SDL_GPUSampler,

pub fn init(device: GraphicsDevice, info: SamplerCreateInfo) Sampler {
    var create_info = structs.convertToSDL(sdl.SDL_GPUSamplerCreateInfo, info);

    const handle = sdl.SDL_CreateGPUSampler(device.handle, &create_info);
    return .{
        .handle = handle
    };
}

pub fn deinit(self: Sampler, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUSampler(device.handle, self.handle);
}