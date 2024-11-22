const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

pub const GpuBuffer = @import("GpuBuffer.zig");

pub const Color = extern struct {
    r: u8, b: u8, g: u8, a: u8,

    pub fn init(r: f32, b: f32, g: f32, a: f32) Color {
        return .{
            .r = @intFromFloat(r * 255),
            .g = @intFromFloat(g * 255),
            .b = @intFromFloat(b * 255),
            .a = @intFromFloat(a * 255)
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
};

pub const CommandBuffer = @import("CommandBuffer.zig");
pub const Fence = @import("Fence.zig");
pub const GraphicsDevice = @import("GraphicsDevice.zig");
pub const GraphicsPipeline = @import("GraphicsPipeline.zig");
pub const Image = @import("Image.zig");
pub const RenderPass = @import("RenderPass.zig");
pub const Shader = @import("Shader.zig");
pub const TransferBuffer = @import("TransferBuffer.zig");