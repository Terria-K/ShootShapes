const ComputePipeline = @This();
const GraphicsDevice = @import("GraphicsDevice.zig");
const uint3 = @import("../math/generics.zig").on(u32).Vec3;

const reflection = @import("reflection/shader_reflection.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");
const checks = @import("checks");

pub const Error = @import("Shader.zig").Error || error {
    FailedToCreateComputePipeline
};

handle: ?*sdl.SDL_GPUComputePipeline,

pub fn init(device: GraphicsDevice, code: ?*anyopaque, size: usize, info: ComputePipelineCreateInfo) Error!ComputePipeline {
    const format = 
    if (checks.is_windows) 
        sdl.SDL_GPU_SHADERFORMAT_DXIL
    else 
        sdl.SDL_GPU_SHADERFORMAT_SPIRV;
    
    var create_info: sdl.SDL_GPUComputePipelineCreateInfo = undefined;
    create_info.code = @ptrCast(code);
    create_info.code_size = @intCast(size);
    create_info.entrypoint = "main";
    create_info.format = format;
    create_info.num_readonly_storage_buffers = info.readonly_storage_buffer_count;
    create_info.num_readonly_storage_textures = info.readonly_storage_texture_count;
    create_info.num_readwrite_storage_buffers = info.readwrite_storage_buffer_count;
    create_info.num_readwrite_storage_textures = info.readwrite_storage_texture_count;
    create_info.num_samplers = info.sampler_count;
    create_info.num_uniform_buffers = info.uniform_buffer_count;
    create_info.threadcount_x = info.thread_count.x;
    create_info.threadcount_y = info.thread_count.y;
    create_info.threadcount_z = info.thread_count.z;

    const handle = sdl.SDL_CreateGPUComputePipeline(device.handle, &create_info);

    if (handle == null) {
        sdl.SDL_free(handle);
        return Error.FailedToCreateComputePipeline;
    }

    return .{
        .handle = handle
    };
}

pub fn loadFile(device: GraphicsDevice, filename: []const u8, info: ComputePipelineCreateInfo) Error!ComputePipeline {
    var size: usize = undefined;
    const code = sdl.SDL_LoadFile(@ptrCast(filename), &size);
    defer sdl.SDL_free(code);
    if (code == null) {
        return Error.FailedToLoadShaderFromDisk;
    }

    return try init(device, code, size, info);
}

pub fn loadFileAuto(allocator: std.mem.Allocator, device: GraphicsDevice, filename: []const u8, thread_count: uint3) (Error || std.mem.Allocator.Error)!ComputePipeline {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator(); 

    const buffer = try arena_allocator.alloc(u8, filename.len + 1);

    _ = std.mem.replace(u8, filename, ".spv", ".json", buffer);
    const r = reflection.loadReflection(arena_allocator, buffer) catch {
        return Error.ShaderReflectionFileNotFound;
    };

    const compute_info: ComputePipelineCreateInfo = .{
        .sampler_count = r.sampler_count,
        .thread_count = thread_count,
        .uniform_buffer_count = r.uniform_buffer_count,
        .readonly_storage_buffer_count = r.storage_buffer_count,
        .readonly_storage_texture_count = r.storage_texture_count,
        .readwrite_storage_buffer_count = r.readwrite_storage_buffer_count,
        .readwrite_storage_texture_count = r.readwrite_storage_texture_count
    };
    return try loadFile(device, filename, compute_info);
}

pub fn deinit(self: ComputePipeline, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUComputePipeline(device.handle, self.handle);
}

pub const ComputePipelineCreateInfo = struct {
    sampler_count: u32 = 0,
    uniform_buffer_count: u32 = 0,
    readonly_storage_texture_count: u32 = 0,
    readonly_storage_buffer_count: u32 = 0,
    readwrite_storage_texture_count: u32 = 0,
    readwrite_storage_buffer_count: u32 = 0,
    thread_count: uint3
};