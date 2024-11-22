const RenderPass = @This();
const GpuBuffer = @import("GpuBuffer.zig");
const GraphicsPipeline = @import("GraphicsPipeline.zig");
const enums = @import("../enums/main.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
handle: ?*sdl.SDL_GPURenderPass,
pub fn init(handle: ?*sdl.SDL_GPURenderPass) RenderPass {
    return .{
        .handle = handle
    };
}

pub fn bindGraphicsPipeline(self: RenderPass, pipeline: GraphicsPipeline) void {
    sdl.SDL_BindGPUGraphicsPipeline(self.handle, pipeline.handle);
}

pub fn bindVertexBuffer(self: RenderPass, buffer: GpuBuffer, slot: u32) void {
    var bindings: [1]sdl.SDL_GPUBufferBinding = [1]sdl.SDL_GPUBufferBinding {
        .{ .buffer = buffer.handle, .offset = 0 }
    };
    sdl.SDL_BindGPUVertexBuffers(self.handle, slot, @ptrCast(&bindings), 1);
}

pub fn bindIndexBuffer(self: RenderPass, buffer: GpuBuffer, size: enums.IndexElementSIze) void {
    var binding: sdl.SDL_GPUBufferBinding = undefined;
    binding.buffer = buffer.handle;
    binding.offset = 0;

    sdl.SDL_BindGPUIndexBuffer(self.handle, &binding, @intCast(@intFromEnum(size)));
}

pub fn drawPrimitives(self: RenderPass, vert_count: u32, instance_count: u32, first_vert: u32, first_instance: u32) void {
    sdl.SDL_DrawGPUPrimitives(self.handle, vert_count, instance_count, first_vert, first_instance);
}

pub fn drawIndexedPrimitives(self: RenderPass, index_count: u32, instance_count: u32, first_index: u32, offset: i32, first_instance: u32) void {
    sdl.SDL_DrawGPUIndexedPrimitives(self.handle, index_count, instance_count, first_index, offset, first_instance);
}

pub fn end(self: RenderPass) void {
    sdl.SDL_EndGPURenderPass(self.handle);
}