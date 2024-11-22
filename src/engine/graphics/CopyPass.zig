const CopyPass = @This();
const structs = @import("../structs/main.zig");
const BufferRegion = structs.BufferRegion;
const TranferBufferLocation = structs.TransferBufferLocation;
const TransferBuffer = @import("TransferBuffer.zig");
const Texture = @import("../structs/Texture.zig");
const GpuBuffer = @import("GpuBuffer.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

handle: ?*sdl.SDL_GPUCopyPass,
pub fn init(handle: ?*sdl.SDL_GPUCopyPass) CopyPass {
    return .{
        .handle = handle
    };
}

pub fn uploadToTexture(self: CopyPass, src: TransferBuffer, dest: Texture, cycle: bool) void {
    var source: sdl.SDL_GPUTextureTransferInfo = undefined;
    source.offset = 0;
    source.transfer_buffer = src.handle;
    source.pixels_per_row = 0;
    source.rows_per_layer = 0;
    
    var region: sdl.SDL_GPUTextureRegion = undefined;
    region.texture = dest.handle;
    region.w = dest.width;
    region.h = dest.height;

    sdl.SDL_UploadToGPUTexture(self.handle, &source, &region, cycle);
}

pub fn uploadToSlicedBuffer(self: CopyPass, src: TranferBufferLocation, dest: BufferRegion, cycle: bool) void {
    var source = structs.convertToSDL(sdl.SDL_GPUTransferBufferLocation, src);
    var destination = structs.convertToSDL(sdl.SDL_GPUBufferRegion, dest);

    sdl.SDL_UploadToGPUBuffer(self.handle, &source, &destination, cycle);
}

pub fn uploadToBuffer(self: CopyPass, src: TransferBuffer, dest: GpuBuffer, cycle: bool) void {
    var source: sdl.SDL_GPUTransferBufferLocation = undefined;
    source.offset = 0;
    source.transfer_buffer = src.handle;

    var destination: sdl.SDL_GPUBufferRegion = undefined;
    destination.buffer = dest.handle;
    destination.offset = 0;
    destination.size = dest.size;

    sdl.SDL_UploadToGPUBuffer(self.handle, &source, &destination, cycle);
}

pub fn end(self: CopyPass) void {
    sdl.SDL_EndGPUCopyPass(self.handle);
}