const math = @import("../math/main.zig");
const std = @import("std");
const Color = @import("../graphics/main.zig").Color;
const float4 = math.float4;
const float2 = math.float2;
const VertexAttribute = @import("../structs/VertexAttribute.zig");
const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;

pub const PositionTextureColorVertex = extern struct {
    position: float4,
    tex_coord: float2,
    color: Color,

    pub fn generate() [3]VertexElementFormat {
        return [3]VertexElementFormat {
            VertexElementFormat.Float4,
            VertexElementFormat.Float2,
            VertexElementFormat.UByte4Norm
        };
    }
};

pub const PositionColorVertex = extern struct {
    position: float4,
    color: Color,

    pub fn generate() [2]VertexElementFormat {
        return [2]VertexElementFormat {
            VertexElementFormat.Float4,
            VertexElementFormat.UByte4Norm
        };
    }
};