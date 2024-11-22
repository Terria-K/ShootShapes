const Window = @This();
const TextureFormat = @import("enums/main.zig").TextureFormat;
const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const ids: u32 = 0;

handle: ?*sdl.SDL_Window = undefined,
claimed: bool = false,
swapchain_composition: sdl.enum_SDL_GPUSwapchainComposition = undefined,
swapchain_format: TextureFormat = undefined,

pub fn init(comptime window: WindowSettings) Window {
    var flags = sdl.SDL_WINDOW_VULKAN | sdl.SDL_WINDOW_HIDDEN;
    if (window.flags.fullscreen) {
        flags |= sdl.SDL_WINDOW_FULLSCREEN;
    }
    if (window.flags.resizable) {
        flags |= sdl.SDL_WINDOW_RESIZABLE;
    }
    if (window.flags.start_maximized) {
        flags |= sdl.SDL_WINDOW_MAXIMIZED;
    }
    const handle = sdl.SDL_CreateWindow(
        @ptrCast(window.title), 
        @intCast(window.width), 
        @intCast(window.height), 
        flags);
    return .{ .handle = handle };
}

pub fn deinit(self: Window) void {
    sdl.SDL_DestroyWindow(self.handle);
}

pub fn show(self: Window) void {
    _ = sdl.SDL_ShowWindow(self.handle);
}

pub const WindowFlags = packed struct {
    resizable: bool = false,
    start_maximized: bool = false,
    fullscreen: bool = false
};

pub const WindowSettings = struct {
    title: []const u8,
    width: u64,
    height: u64,
    flags: WindowFlags,

    pub fn init(comptime title: []const u8, comptime width: u64, comptime height: u64, comptime flags: WindowFlags) @This() {
        return .{
            .title = title,
            .width = width,
            .height = height,
            .flags = flags
        };
    }
};