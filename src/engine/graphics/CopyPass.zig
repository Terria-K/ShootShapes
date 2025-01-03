const CopyPass = @This();
const structs = @import("../structs/main.zig");
const BufferRegion = structs.BufferRegion;
const TranferBufferLocation = structs.TransferBufferLocation;
const TextureTransferInfo = structs.TextureTransferInfo;
const TextureRegion = structs.TextureRegion;
const TransferBuffer = @import("TransferBuffer.zig");
const Texture = @import("Texture.zig");
const GpuBuffer = @import("GpuBuffer.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

handle: ?*sdl.SDL_GPUCopyPass,
pub fn init(handle: ?*sdl.SDL_GPUCopyPass) CopyPass {
    return .{
        .handle = handle
    };
}

pub fn uploadToSlicedTexture(self: CopyPass, src: TextureTransferInfo, dest: TextureRegion, cycle: bool) void {
    var source: sdl.SDL_GPUTextureTransferInfo = undefined;
    source.offset = src.offset;
    source.transfer_buffer = src.transfer_buffer.handle;
    source.pixels_per_row = src.pixels_per_row;
    source.rows_per_layer = src.rows_per_layer;
    
    var region: sdl.SDL_GPUTextureRegion = undefined;
    region.texture = dest.texture.handle;
    region.mip_level = dest.mip_level;
    region.layer = dest.layer;
    region.x = dest.x;
    region.y = dest.y;
    region.z = dest.z;
    region.w = dest.texture.width;
    region.h = dest.texture.height;
    region.d = dest.d;

    sdl.SDL_UploadToGPUTexture(self.handle, &source, &region, cycle);
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

pub fn downloadFromBuffer(self: CopyPass, src: BufferRegion, dest: TranferBufferLocation) void {
    var source = structs.convertToSDL(sdl.SDL_GPUBufferRegion, src);
    var destination = structs.convertToSDL(sdl.SDL_GPUTransferBufferLocation, dest);
    sdl.SDL_DownloadFromGPUBuffer(self.handle, &source, &destination);
}

pub fn downloadFromTexture(self: CopyPass, src: TextureRegion, dest: TextureTransferInfo) void {
    var source = structs.convertToSDL(sdl.SDL_GPUTextureRegion, src);
    var destination = structs.convertToSDL(sdl.SDL_GPUTextureTransferInfo, dest);
    sdl.SDL_DownloadFromGPUTexture(self.handle, &source, &destination);
}

pub fn end(self: CopyPass) void {
    sdl.SDL_EndGPUCopyPass(self.handle);
}