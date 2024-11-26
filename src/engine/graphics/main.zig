const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

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

    pub fn mulScalar(self: Color, scale: f32) Color {
        return .{
            .r = @intFromFloat(@as(f32, @floatFromInt(self.r)) * scale),
            .g = @intFromFloat(@as(f32, @floatFromInt(self.g)) * scale),
            .b = @intFromFloat(@as(f32, @floatFromInt(self.b)) * scale),
            .a = @intFromFloat(@as(f32, @floatFromInt(self.a)) * scale)
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
	pub const transparent = Color.fromIntAlpha(0xffffffff);
	pub const red = Color.fromInt(0xff0000);
	pub const green = Color.fromInt(0x00ff00);
	pub const blue = Color.fromInt(0x0000ff);
	pub const cyan = Color.fromInt(0x00ffff);
	pub const magenta = Color.fromInt(0xff00ff);
	pub const yellow = Color.fromInt(0xffff00);
};

pub const CommandBuffer = @import("CommandBuffer.zig");
pub const Fence = @import("Fence.zig");
pub const GraphicsDevice = @import("GraphicsDevice.zig");
pub const GraphicsPipeline = @import("GraphicsPipeline.zig");
pub const Image = @import("Image.zig");
pub const RenderPass = @import("RenderPass.zig");
pub const Sampler = @import("Sampler.zig");
pub const Shader = @import("Shader.zig");
pub const Texture = @import("Texture.zig");
pub const TextureUploader = @import("TextureUploader.zig");
pub const TransferBuffer = @import("TransferBuffer.zig");