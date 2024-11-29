const math = @import("../math/main.zig");
const std = @import("std");
const Color = @import("../graphics/main.zig").Color;
const float4 = math.float4;
const float2 = math.float2;
const Attribute = @import("../structs/main.zig").VertexElementAttribute;

pub const PositionTextureColorVertex = extern struct {
    position: float4,
    tex_coord: float2,
    color: Color,

    pub fn generate() [3]Attribute {
        return [3]Attribute {
            Attribute { .format = .Float4, .offset = 0 },
            Attribute { .format = .Float2, .offset = 16 },
            Attribute { .format = .UByte4Norm, .offset = 24 }
        };
    }
};

pub const PositionTextureColorConcreteVertex = extern struct {
    position: float4,
    tex_coord: float2,
    color: float4 align(16),

    pub fn generate() [3]Attribute {
        return [3]Attribute {
            Attribute { .format = .Float4, .offset = 0 },
            Attribute { .format = .Float2, .offset = 16 },
            Attribute { .format = .Float4, .offset = 32 }
        };
    }
};

pub const PositionColorVertex = extern struct {
    position: float4,
    color: Color,

    pub fn generate() [2]Attribute {
        return [2]Attribute {
            Attribute { .format = .Float4, .offset = 0 },
            Attribute { .format = .Float2, .offset = 16 },
        };
    }
};