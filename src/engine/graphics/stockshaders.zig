const Shader = @import("Shader.zig");
const ComputePipeline = @import("ComputePipeline.zig");
const ShaderInfo = Shader.ShaderInfo;
const std = @import("std");
const GraphicsDevice = @import("GraphicsDevice.zig");
const uint3 = @import("../math.zig").uint3;
pub const ShaderStage = @import("../enums/main.zig").ShaderStage;


const Builtins = struct {
    positioncolor_vert: bool = false,
    solidcolor_frag: bool = false,

    positiontexturecolor_vert: bool = false,
    texture_frag: bool = false,

    spritebatch_comp: bool = false,
};

pub fn useBuiltins(device: GraphicsDevice, comptime builtin: Builtins) !getBuiltins(builtin) {
    var shaders: getBuiltins(builtin) = undefined;
    if (builtin.positiontexturecolor_vert) {
        shaders.positiontexturecolor_vert = try loadBuiltinGraphicsShader(device, "positiontexturecolor.vert", .Vertex, .{ .uniform_buffer_count = 1 });
    }

    if (builtin.positioncolor_vert) {
        shaders.positioncolor_vert = try loadBuiltinGraphicsShader(device, "positioncolor.vert", .Vertex, .{ .uniform_buffer_count = 1 });
    }

    if (builtin.solidcolor_frag) {
        shaders.solidcolor_frag = try loadBuiltinGraphicsShader(device, "solidcolor.frag", .Fragment, .{});
    }

    if (builtin.texture_frag) {
        shaders.texture_frag = try loadBuiltinGraphicsShader(device, "texture.frag", .Fragment, .{ .sampler_count = 1});
    }

    if (builtin.spritebatch_comp) {
        shaders.spritebatch_comp = try loadBuiltinComputeShader(device, "spritebatch.comp", .{ 
            .readonly_storage_buffer_count = 1,
            .readwrite_storage_buffer_count = 1,
            .thread_count = uint3.new(64, 1, 1),
            
        });
    }
    
    return shaders;
}

fn loadBuiltinComputeShader(device: GraphicsDevice, comptime name: []const u8, compute_info: ComputePipeline.ComputePipelineCreateInfo) !ComputePipeline {
    const embedded_shader = @embedFile("stockshaders/compiled/" ++ name ++ ".spv");
    return try ComputePipeline.loadMem(device, @constCast(embedded_shader), compute_info);
}

fn loadBuiltinGraphicsShader(device: GraphicsDevice, comptime name: []const u8, stage: ShaderStage, shader_info: ShaderInfo) !Shader {
    const embedded_shader = @embedFile("stockshaders/compiled/" ++ name ++ ".spv");
    return try Shader.loadMem(device, @constCast(embedded_shader), stage, shader_info);
}

fn getBuiltins(builtin_data: Builtins) type {
    const Empty = struct {};
    var fields = @typeInfo(Empty).Struct.fields;
    const builtin_fields = @typeInfo(Builtins).Struct.fields;
    inline for (builtin_fields) |field| {
        if (@field(builtin_data, field.name)) {
            const is_compute = comptime blk: {
                const does_contain = std.mem.containsAtLeast(u8, field.name, 1, "comp");
                break :blk does_contain;
            };

            const ShaderType = 
            if (is_compute) 
                ComputePipeline 
            else 
                Shader;
            fields = fields ++ [_]std.builtin.Type.StructField {.{
                .name = field.name,
                .type = ShaderType,
                .default_value = null,
                .is_comptime = false,
                .alignment = @alignOf(ShaderType)
            }};
        }

    }

    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &.{}
        }
    });
}