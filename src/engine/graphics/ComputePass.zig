const ComputePass = @This();
const GpuBuffer = @import("GpuBuffer.zig");
const ComputePipeline = @import("ComputePipeline.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

handle: ?*sdl.SDL_GPUComputePass,

pub fn init(handle: ?*sdl.SDL_GPUComputePass) ComputePass {
    return .{
        .handle = handle
    };
}

pub fn bindComputePipeline(self: ComputePass, compute_pipeline: ComputePipeline) void {
    sdl.SDL_BindGPUComputePipeline(self.handle, compute_pipeline.handle);
}

pub fn bindStorageBuffer(self: ComputePass, buffer: GpuBuffer, slot: u32) void {
    var buffer_binding = [1]?*sdl.SDL_GPUBuffer { buffer.handle };
    sdl.SDL_BindGPUComputeStorageBuffers(self.handle, slot, @ptrCast(&buffer_binding), 1);
}

pub fn dispatch(self: ComputePass, groupX: u32, groupY: u32, groupZ: u32) void {
    sdl.SDL_DispatchGPUCompute(self.handle, groupX, groupY, groupZ);
}

pub fn end(self: ComputePass) void {
    sdl.SDL_EndGPUComputePass(self.handle);
}