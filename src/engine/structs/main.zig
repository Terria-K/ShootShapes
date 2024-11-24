const std = @import("std");

pub const BufferRegion = @import("BufferRegion.zig");

pub const ColorTargetBlendState = @import("ColorTargetBlendState.zig");
pub const ColorTargetDescription = @import("ColorTargetDescription.zig");
pub const ColorTargetInfo = @import("ColorTargetInfo.zig");
pub const ColorComponentFlags = packed struct {
    r: bool = false,
    g: bool = false,
    b: bool = false,
    a: bool = false,
    _: u4 = 0,

    pub fn convertToSDLBit() void {}
};

pub const TransferBufferUsage = packed struct {
    download: bool = false,
    upload: bool = false,

    _: u30 = 0
};

pub const BufferUsage = packed struct {
    vertex: bool = false,
    index: bool = false,
    indirect: bool = false,
    graphics_storage_read: bool = false,
    compute_storage_read: bool = false,
    compute_storage_write: bool = false,

    _: u26 = 0
};

pub const DepthStencilState = @import("DepthStencilState.zig");
pub const GraphicsPipelineTargetInfo = @import("GraphicsPipelineTargetInfo.zig");
pub const MultisampleState = @import("MultisampleState.zig");
pub const RasterizerState = @import("RasterizerState.zig");
pub const SamplerCreateInfo = @import("SamplerCreateInfo.zig");
pub const StencilOpState = @import("StencilOpState.zig");

pub const TextureSamplerBinding = @import("TextureSamplerBinding.zig");
pub const TransferBufferLocation = @import("TransferBufferLocation.zig");

pub const VertexAttribute = @import("VertexAttribute.zig");
pub const VertexBufferDescription = @import("VertexBufferDescription.zig");
pub const VertexInputState = @import("VertexInputState.zig");

fn Tuple(comptime T1: type, comptime T2: type) type {
    return struct {
        item1: T1,
        item2: T2,

        pub fn init(elem1: T1, elem2: T2) @This() {
            return .{
                .item1 = elem1,
                .item2 = elem2
            };
        }
    };
}
pub const InputStateBuilder = struct {
    slot: usize = 0,
    strides: usize = 0,
    input_states: std.ArrayList(Tuple(VertexBufferDescription, []VertexAttribute)),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) InputStateBuilder {
        return .{
            .allocator = allocator,
            .input_states = std.ArrayList(Tuple(VertexBufferDescription, []VertexAttribute)).init(allocator)
        };
    }

    pub fn deinit(self: InputStateBuilder) void {
        self.input_states.deinit();
    }

    pub fn addVertexInputState(self: *InputStateBuilder, comptime T: type, step_rate: u32) !void {
        const attrib = try VertexAttribute.attributes(self.allocator, T, @intCast(self.slot));
        const description: VertexBufferDescription = .{ 
            .input_rate = .Vertex, 
            .instance_step_rate = step_rate, 
            .pitch = @sizeOf(T),
            .slot = @intCast(self.slot)
        };
        try self.input_states.append(Tuple(VertexBufferDescription, []VertexAttribute).init(description, attrib));
        self.strides += attrib.len;
        self.slot += 1;
    }

    pub fn build(self: InputStateBuilder) !VertexInputState {
        var binding = try self.allocator.alloc(VertexBufferDescription, self.slot);
        var attributes = try self.allocator.alloc(VertexAttribute, self.strides);
        var i: usize = 0;
        var stride: usize = 0;
        for (self.input_states.items) |input| {
            binding[i] = input.item1;
            const attrib = input.item2;
            for (0..attrib.len) |j| {
                attributes[stride] = attrib[j];
                stride += 1;
            }
            i += 1;
        }

        return VertexInputState {
            .vertex_attributes = attributes,
            .vertex_buffer_descriptions = binding
        };
    }
};

pub fn inputStateBuilder(allocator: std.mem.Allocator) InputStateBuilder {
    return InputStateBuilder.init(allocator);
}

pub fn convertToSDL(comptime Type: type, src: anytype) Type {
    const srcFields = std.meta.fields(@TypeOf(src));
    var dest: Type = .{};
    inline for (srcFields) |field| {
        if (@typeInfo(field.type) == .Enum) {
            @field(dest, field.name) = @intCast(@intFromEnum(@field(src, field.name)));
        }
        else if (std.meta.hasFn(field.type, "convertToSDLBit")) {
            @field(dest, field.name) = @bitCast(@field(src, field.name));
        }
        else if (std.meta.hasFn(field.type, "convertToSDLFColor")) {
            @field(dest, field.name) = @field(src, field.name).convertToSDLFColor();
        }
        else if (@typeInfo(field.type) == .Struct and @hasField(field.type, "handle")) {
            @field(dest, field.name) = @field(src, field.name).handle;
        }
        else {
            @field(dest, field.name) = @field(src, field.name);
        }
    }

    return dest;
}