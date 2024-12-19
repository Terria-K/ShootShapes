const std = @import("std");
const Allocator = std.mem.Allocator;

const RawJsonShaderParameter = struct {
    name: []const u8,
    type: std.json.Value
};

const RawJsonReflection = struct {
    parameters: []RawJsonShaderParameter
};

pub const Uniform = struct {
    kind: []const u8,
};

pub const Resource = struct {
    kind: []const u8,
    baseShape: []const u8
};

pub const ComputeResource = struct {
    kind: []const u8,
    baseShape: []const u8,
    access: []const u8
};

pub const UnifiedResource = union(enum) {
    uniform: Uniform,
    resource: Resource,
    compute_resource: ComputeResource,

    pub fn jsonParseFromValue(allocator: Allocator, source: std.json.Value, _: std.json.ParseOptions) !@This() {
        switch (source) {
            .object => |v| {
                if (v.get("kind")) |kind_json| {
                    const kind = try allocator.dupe(u8, kind_json.string);

                    if (v.get("baseShape")) |base_shape_json| {
                        const shape = try allocator.dupe(u8, base_shape_json.string);

                        if (v.get("access")) |access_json| {
                            const access = try allocator.dupe(u8, access_json.string);
                            return UnifiedResource {
                                .compute_resource = .{
                                    .kind = kind,
                                    .baseShape = shape,
                                    .access = access
                                }
                            };
                        } else {
                            return UnifiedResource { .resource = .{ 
                                    .kind = kind, 
                                    .baseShape = shape
                                }
                            };
                        }
                    } else {
                        return UnifiedResource { .uniform = .{ .kind = kind } };
                    }
                }

                return error.UnexpectedToken;
            },
            else => return error.UnexpectedToken
        }
    }
};

pub const ShaderReflection = struct {
    sampler_count: u32 = 0,
    storage_buffer_count: u32 = 0,
    storage_texture_count: u32 = 0,
    uniform_buffer_count: u32 = 0,
    readwrite_storage_texture_count: u32 = 0,
    readwrite_storage_buffer_count: u32 = 0,
};

/// Load shader json file output. It is recommended to use the ArenaAllocator here.
pub fn loadReflection(allocator: Allocator, json_path: []const u8) !ShaderReflection {
    const fs = try std.fs.cwd().openFile(json_path, .{});
    defer fs.close();

    const buffer = try allocator.alloc(u8, try fs.getEndPos());
    defer allocator.free(buffer);
    _ = try fs.readAll(buffer);

    const json = try std.json.parseFromSlice(RawJsonReflection, allocator, buffer, .{ .ignore_unknown_fields = true });
    defer json.deinit();

    var reflection: ShaderReflection = .{};

    for (json.value.parameters) |param| {
        const kind = try std.json.parseFromValue(UnifiedResource, allocator, param.type, .{});
        defer kind.deinit();

        // TODO storage textures
        switch (kind.value) {
            .uniform => |v| {
                if (std.mem.eql(u8, v.kind, "constantBuffer")) {
                    reflection.uniform_buffer_count += 1;
                }

                if (std.mem.eql(u8, v.kind, "samplerState")) {
                    reflection.sampler_count += 1;
                }
            },
            .resource => |v| {
                if (std.mem.eql(u8, v.kind, "resource")) {
                    if (std.mem.eql(u8, v.baseShape, "structuredBuffer")) {
                        reflection.storage_buffer_count += 1;
                    }
                }

                if (std.mem.eql(u8, v.kind, "samplerState")) {
                    reflection.sampler_count += 1;
                }
            },
            .compute_resource => |v| {
                if (std.mem.eql(u8, v.kind, "resource")) {
                    if (std.mem.eql(u8, v.baseShape, "structuredBuffer")) {
                        if (std.mem.eql(u8, v.access, "readWrite")) {
                            reflection.readwrite_storage_buffer_count += 1;
                        }
                    }
                }
            }
        }

    }

    return reflection;
}

test "shader_reflection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();
    const reflection = try loadReflection(arena_allocator, "assets/compiled/positiontexturecolor.vert.json");

    try std.testing.expect(reflection.uniform_buffer_count == 1);
}