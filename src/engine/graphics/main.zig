const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const float2 = @import("../math/main.zig").float2;
const float4 = @import("../math/main.zig").float4;

pub const qoi = @import("qoi.zig");
pub const stockshaders = @import("stockshaders.zig");
pub const GpuBuffer = @import("GpuBuffer.zig");

pub const Color = packed struct {
    r: u8, g: u8, b: u8, a: u8,

    pub fn init(r: f32, b: f32, g: f32, a: f32) Color {
        return .{
            .r = @intFromFloat(r * 255),
            .g = @intFromFloat(g * 255),
            .b = @intFromFloat(b * 255),
            .a = @intFromFloat(a * 255)
        };
    }

    pub fn fromRGBA(r: u8, g: u8, b: u8, a: u8) Color {
        return .{
            .r =  r,
            .g = g,
            .b = b,
            .a = a
        };
    }

    pub inline fn fromRGBAPremultiply(r: u8, g: u8, b: u8, a: u8) Color {
        const alpha: u16 = @intCast(a);
        const r1 = r * alpha / 255;
        const g1 = g * alpha / 255;
        const b1 = b * alpha / 255;
        return .{
            .r =  r1,
            .g = g1,
            .b = b1,
            .a = a
        };
    }

    pub fn fromInt(color: i32) Color {
        return .{
            .r =  color >> 16 & 0xff,
            .g = color >> 8 & 0xff,
            .b = color & 0xff,
            .a = 255
        };
    }

    pub fn fromIntAlpha(color: u32) Color {
        return .{
            .r = color >> 24 & 0xff,
            .g = color >> 16 & 0xff,
            .b = color >> 8 & 0xff,
            .a = color & 0xff
        };
    }

    pub fn premultiply(self: Color) Color {
        const alpha: u16 = @intCast(self.a);
        const r = self.r * alpha / 255;
        const g = self.g * alpha / 255;
        const b = self.b * alpha / 255;
        return .{
            .r = @intCast(r),
            .g = @intCast(g),
            .b = @intCast(b),
            .a = self.a
        };
    }

    pub fn mulScalar(self: Color, scale: f32) Color {
        return .{
            .r = @intFromFloat(@as(f32, @floatFromInt(self.r)) * scale),
            .g = @intFromFloat(@as(f32, @floatFromInt(self.g)) * scale),
            .b = @intFromFloat(@as(f32, @floatFromInt(self.b)) * scale),
            .a = @intFromFloat(@as(f32, @floatFromInt(self.a)) * scale)
        };
    }

    pub inline fn toVector4(self: Color) float4 {
        return .{
            .x = @as(f32, @floatFromInt(self.r)) / 255.0,
            .y = @as(f32, @floatFromInt(self.g)) / 255.0,
            .z = @as(f32, @floatFromInt(self.b)) / 255.0,
            .w = @as(f32, @floatFromInt(self.a)) / 255.0
        };
    }

    pub inline fn convertToSDLFColor(self: Color) sdl.SDL_FColor {
        const t: sdl.SDL_FColor = .{
            .r = @as(f32, @floatFromInt(self.r)) / 255.0,
            .g = @as(f32, @floatFromInt(self.g)) / 255.0,
            .b = @as(f32, @floatFromInt(self.b)) / 255.0,
            .a = @as(f32, @floatFromInt(self.a)) / 255.0
        };
        return t;
    }

	pub const cornflowerBlue = Color.fromInt(0x6495ed);
	pub const white = Color.fromInt(0xffffff);
	pub const black = Color.fromInt(0x000000);
	pub const transparent = Color.fromIntAlpha(0x00000000);
	pub const red = Color.fromInt(0xff0000);
	pub const green = Color.fromInt(0x00ff00);
	pub const blue = Color.fromInt(0x0000ff);
	pub const cyan = Color.fromInt(0x00ffff);
	pub const magenta = Color.fromInt(0xff00ff);
	pub const yellow = Color.fromInt(0xffff00);
};

pub const CommandBuffer = @import("CommandBuffer.zig");
pub const ComputePipeline = @import("ComputePipeline.zig");
pub const ComputePass = @import("ComputePass.zig");
pub const Fence = @import("Fence.zig");
pub const GraphicsDevice = @import("GraphicsDevice.zig");
pub const GraphicsPipeline = @import("GraphicsPipeline.zig");
pub const Image = @import("Image.zig");
pub const RenderPass = @import("RenderPass.zig");
pub const Sampler = @import("Sampler.zig");
pub const Shader = @import("Shader.zig");
pub const SpriteBatch = @import("SpriteBatch.zig");
pub const Texture = @import("Texture.zig");
pub const TextureUploader = @import("TextureUploader.zig");
pub const TextureQuad = @import("TextureQuad.zig");
pub const TransferBuffer = @import("TransferBuffer.zig");

pub const UV = extern struct {
    top_left: float2,
    top_right: float2,
    bottom_left: float2,
    bottom_right: float2,

    pub fn init(top_left: float2, top_right: float2, bottom_left: float2, bottom_right: float2) UV {
        return .{
            .top_left = top_left,
            .top_right = top_right,
            .bottom_left = bottom_left,
            .bottom_right = bottom_right
        };
    }

    pub fn initByDimension(position: float2, dimension: float2) UV {
        return .{
            .top_left = position,
            .top_right = position.add(float2.new(dimension.x, 0)),
            .bottom_left = position.add(float2.new(0, dimension.y)),
            .bottom_right = position.add(dimension)
        };
    }
};