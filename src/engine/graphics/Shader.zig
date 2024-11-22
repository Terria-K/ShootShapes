const Shader = @This();
const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const GraphicsDevice = @import("GraphicsDevice.zig");
const ShaderStage = @import("../enums/main.zig").ShaderStage;

handle: ?*sdl.SDL_GPUShader,

pub fn init(device: GraphicsDevice, code: ?*anyopaque, size: usize, stage: ShaderStage, shader_info: ShaderInfo) !Shader {
    const create_info: sdl.SDL_GPUShaderCreateInfo = .{ 
        .code = @ptrCast(code),
        .code_size = size,
        .entrypoint = "main",
        .format =  sdl.SDL_GPU_SHADERFORMAT_SPIRV,
        .stage = @intCast(@intFromEnum(stage)),
        .num_samplers = shader_info.sampler_count,
        .num_storage_buffers = shader_info.storage_buffer_count,
        .num_uniform_buffers = shader_info.uniform_buffer_count,
        .num_storage_textures = shader_info.storage_texture_count
    };

    const shader = sdl.SDL_CreateGPUShader(device.handle, &create_info);
    if (shader == null) {
        sdl.SDL_free(shader);
        return error.FailedToCreateShader;
    }

    return .{
        .handle = shader
    };
}

pub fn loadFile(device: GraphicsDevice, filename: []const u8, shader_info: ShaderInfo) !Shader {
    var stage: sdl.SDL_GPUShaderStage = 0;

    // TODO make it a comptime evaluation
    if (sdl.SDL_strstr(@ptrCast(filename), ".vert") != null) {
        stage = sdl.SDL_GPU_SHADERSTAGE_VERTEX;
    } else if (sdl.SDL_strstr(@ptrCast(filename), ".frag") != null) {
        stage = sdl.SDL_GPU_SHADERSTAGE_FRAGMENT;
    } else {
        return error.InvalidShaderStage;
    }

    var size: usize = undefined;
    const code = sdl.SDL_LoadFile(@ptrCast(filename), &size);
    defer sdl.SDL_free(code);
    if (code == null) {
        return error.FailedToLoadShaderFromDisk;
    }

    return try init(device, code, size, @enumFromInt(@as(u32, @intCast(stage))), shader_info);
}

pub fn deinit(self: Shader, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUShader(device.handle, self.handle);
}

pub const ShaderInfo = struct {
    sampler_count: u32 = 0,
    uniform_buffer_count: u32 = 0,
    storage_buffer_count: u32 = 0,
    storage_texture_count: u32 = 0
};