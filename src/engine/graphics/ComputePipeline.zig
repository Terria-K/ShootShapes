const ComputePipeline = @This();
const GraphicsDevice = @import("GraphicsDevice.zig");
const uint3 = @import("../math/generics.zig").on(u32).Vec3;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const checks = @import("checks");

handle: ?*sdl.SDL_GPUComputePipeline,

pub fn init(device: GraphicsDevice, code: ?*anyopaque, size: usize, info: ComputePipelineCreateInfo) !ComputePipeline {
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
        return error.FailedToCreateComputePipeline;
    }

    return .{
        .handle = handle
    };
}

pub fn loadFile(device: GraphicsDevice, filename: []const u8, info: ComputePipelineCreateInfo) !ComputePipeline {
    var size: usize = undefined;
    const code = sdl.SDL_LoadFile(@ptrCast(filename), &size);
    defer sdl.SDL_free(code);
    if (code == null) {
        return error.FailedToLoadShaderFromDisk;
    }

    return try init(device, code, size, info);
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