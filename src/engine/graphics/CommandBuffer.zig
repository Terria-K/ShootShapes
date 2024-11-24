const CommandBuffer = @This();
const structs = @import("../structs/main.zig");
const RenderPass = @import("RenderPass.zig");
const CopyPass = @import("CopyPass.zig");
const Fence = @import("Fence.zig");
const Texture = @import("Texture.zig");
const std = @import("std");
const ColorTargetInfo = structs.ColorTargetInfo;
const GraphicsDevice = @import("GraphicsDevice.zig");
const Window = @import("../Window.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
handle: ?*sdl.SDL_GPUCommandBuffer,

pub fn init(device: GraphicsDevice) CommandBuffer {
    return .{
        .handle = sdl.SDL_AcquireGPUCommandBuffer(device.handle)
    };
}

pub fn acquireSwapchainTexture(self: CommandBuffer, window: Window) ?Texture {
    var texture: *sdl.SDL_GPUTexture = undefined;
    var width: u32 = undefined;
    var height: u32 = undefined;
    if (!sdl.SDL_AcquireGPUSwapchainTexture(self.handle, window.handle, @ptrCast(&texture), &width, &height)) {
        std.log.err("Cannot acquire this texture.", .{});
        return null;
    }
    return Texture { .handle = texture, .width = width, .height = height };
}

pub fn beginSingleRenderPass(self: CommandBuffer, target: ColorTargetInfo) RenderPass {
    var color_target_infos = [1]sdl.SDL_GPUColorTargetInfo { structs.convertToSDL(sdl.SDL_GPUColorTargetInfo, target) };

    return RenderPass.init(sdl.SDL_BeginGPURenderPass(
        self.handle, 
        @ptrCast(&color_target_infos), 
        1, 
        null));
}

pub fn beginRenderPass(self: CommandBuffer, targets: []const ColorTargetInfo, comptime len: usize) RenderPass {
    var color_target_infos: [len]sdl.SDL_GPUColorTargetInfo = undefined;
    inline for (0..len) |i| {
        color_target_infos[i] = structs.convertToSDL(sdl.SDL_GPUColorTargetInfo, targets[i]);
    }

    return RenderPass.init(sdl.SDL_BeginGPURenderPass(
        self.handle, 
        @ptrCast(&color_target_infos), 
        @intCast(len), 
        null));
}

pub fn endRenderPass(_: CommandBuffer, render_pass: RenderPass) void {
    sdl.SDL_EndGPURenderPass(render_pass.handle);
}

pub fn beginCopyPass(self: CommandBuffer) CopyPass {
    return CopyPass.init(sdl.SDL_BeginGPUCopyPass(self.handle));
}

pub fn endCopyPass(_: CommandBuffer, copy_pass: CopyPass) void {
    sdl.SDL_EndGPUCopyPass(copy_pass.end());
}

pub fn pushVertexUniformData(self: CommandBuffer, comptime T: type, data: T, slot: u32) void{
    sdl.SDL_PushGPUVertexUniformData(self.handle, slot, &data, @sizeOf(T));
}

pub fn submit(self: CommandBuffer) void {
    if (!sdl.SDL_SubmitGPUCommandBuffer(self.handle)) {
        std.log.err("Failed to submit a command buffer.", .{});
    }
}

pub fn submitAndAcquireFence(self: CommandBuffer) Fence {
    return Fence.init(sdl.SDL_SubmitGPUCommandBufferAndAcquireFence(self.handle));
}