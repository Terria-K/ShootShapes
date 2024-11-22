const GraphicsPipeline = @This();
const GraphicsDevice = @import("GraphicsDevice.zig");
const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const enums = @import("../enums/main.zig");
const Shader = @import("Shader.zig");
const structs = @import("../structs/main.zig");
const RasterizerState = structs.RasterizerState;
const MultisampleState = structs.MultisampleState;
const DepthStencilState = structs.DepthStencilState;
const GraphicsPipelineTargetInfo = structs.GraphicsPipelineTargetInfo;
const VertexInputState = structs.VertexInputState;

handle: ?*sdl.SDL_GPUGraphicsPipeline,

pub fn init(device: GraphicsDevice, info: GraphicsPipelineInfo) GraphicsPipeline {
    var create_info: sdl.SDL_GPUGraphicsPipelineCreateInfo = undefined;
    create_info.depth_stencil_state = info.depth_stencil_state.convertToSDL();
    create_info.rasterizer_state = structs.convertToSDL(sdl.SDL_GPURasterizerState, info.rasterizer_state);
    create_info.primitive_type = @intCast(@intFromEnum(info.primitive_type));
    create_info.multisample_state = structs.convertToSDL(sdl.SDL_GPUMultisampleState, info.multisample_state);
    create_info.vertex_shader = info.vertex_shader.handle;
    create_info.fragment_shader = info.fragment_shader.handle;
    create_info.target_info = .{
            .num_color_targets = @intCast(info.target_info.color_target_descriptions.len),
            .has_depth_stencil_target = info.target_info.depth_stencil_format != null,
            .depth_stencil_format =  @intCast(@intFromEnum(
                if (info.target_info.depth_stencil_format) |format| 
                    format
                else 
                    .Invalid
            )),
            .color_target_descriptions = 
                @ptrCast(&GraphicsPipelineTargetInfo.conversion(info.target_info))
        };
    
    create_info.vertex_input_state = 
        if (info.vertex_input_state) |input| 
            input.conversion()
        else 
            std.mem.zeroes(sdl.SDL_GPUVertexInputState);
    


    const handle = sdl.SDL_CreateGPUGraphicsPipeline(device.handle, &create_info);
    return .{
        .handle = handle
    };
}

pub fn deinit(self: GraphicsPipeline, device: GraphicsDevice) void {
    sdl.SDL_ReleaseGPUGraphicsPipeline(device.handle, self.handle);
}


pub const GraphicsPipelineInfo = struct {
    target_info: GraphicsPipelineTargetInfo,
    depth_stencil_state: DepthStencilState,
    multisample_state: MultisampleState,
    primitive_type: enums.PrimitiveType,
    vertex_shader: Shader,
    fragment_shader: Shader,
    vertex_input_state: ?VertexInputState = null,
    rasterizer_state: RasterizerState
};