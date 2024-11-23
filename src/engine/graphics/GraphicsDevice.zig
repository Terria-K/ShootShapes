const GraphicsDevice = @This();

const std = @import("std");
const CommandBuffer = @import("CommandBuffer.zig");
const Window = @import("../Window.zig");
const TextureFormat = @import("../enums/main.zig").TextureFormat;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const checks = @import("checks");

handle: ?*sdl.SDL_GPUDevice,
backend: []const u8,

pub fn init() GraphicsDevice {
    const format = 
    if (checks.is_windows) 
        sdl.SDL_GPU_SHADERFORMAT_DXIL | sdl.SDL_GPU_SHADERFORMAT_DXBC
    else 
        sdl.SDL_GPU_SHADERFORMAT_SPIRV;
    
    const handle = sdl.SDL_CreateGPUDevice(
        format, 
        true, 
        if (checks.is_windows) "direct3d12" else "vulkan");

    if (handle == null) {
        @panic("Graphics Device failed to create.");
    }

    const backend = sdl.SDL_GetGPUDeviceDriver(handle);

    return .{
        .handle = handle,
        .backend = std.mem.span(backend)
    };
}

pub fn claimWindow(self: GraphicsDevice, window: *Window, swapchain_composition: sdl.enum_SDL_GPUSwapchainComposition, present_mode: sdl.enum_SDL_GPUPresentMode) bool {
    if (window.claimed) {
        std.log.err("Window has already been claimed!", .{});
        return false;
    }


    const result = sdl.SDL_ClaimWindowForGPUDevice(self.handle, window.handle);

    if (result) 
    {
        if (!sdl.SDL_SetGPUSwapchainParameters(
            self.handle, 
            window.handle, 
            swapchain_composition, 
            present_mode)) {
                std.log.err("Unsupported swapchain parameters.", .{});
            }
        
        window.claimed = true;
        window.swapchain_composition = swapchain_composition;
        window.swapchain_format = @as(TextureFormat, @enumFromInt(sdl.SDL_GetGPUSwapchainTextureFormat(self.handle, window.handle)));
    }
    return result;
}

pub fn unclaimWindow(self: GraphicsDevice, window: *Window) void {
    if (window.claimed) {
        sdl.SDL_ReleaseWindowFromGPUDevice(self.handle, window.handle);
        window.claimed = false;
    }
}

pub fn acquireCommandBuffer(self: GraphicsDevice) CommandBuffer {
    return CommandBuffer.init(self);
}

pub inline fn release(self: GraphicsDevice, resource: anytype) void {
    if (std.meta.hasFn(@TypeOf(resource), "deinit")) {
        resource.deinit(self);
    } else {
        @compileError("This is not a disposable resource");
    }
}

pub fn deinit(self: GraphicsDevice) void {
    sdl.SDL_DestroyGPUDevice(self.handle);
}