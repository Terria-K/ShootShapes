const std = @import("std");
const structs = @import("engine/structs/main.zig");
const graphics = @import("engine/graphics/main.zig");

const Shader = graphics.Shader; 
const GraphicsPipeline = graphics.GraphicsPipeline;
const Color = graphics.Color;
const TransferBuffer = graphics.TransferBuffer;

const GameContext = @import("engine/game.zig").GameContext(AppState);
const WindowSettings = @import("engine/Window.zig").WindowSettings;
const ColorTargetInfo = @import("engine/structs/ColorTargetInfo.zig");
const enums = @import("engine/enums/main.zig");
const float4x4 = @import("engine/math/main.zig").float4x4;
const float4 = @import("engine/math/main.zig").float4;
const float2 = @import("engine/math/main.zig").float2;
const ecs = @import("engine/ecs/main.zig");
const InputDevice = @import("engine/input/InputDevice.zig");

const PCV = @import("engine/vertex/main.zig").PositionColorVertex;
const components = @import("components.zig");
const systems = @import("systems/main.zig");
const Batcher = @import("Batcher.zig");

pub const GlobalResource = struct {
    delta: f64,
    input: *InputDevice,
    batch: Batcher,
    count: u32,
};


pub const AppState = struct {
    default: GraphicsPipeline,

    mat: float4x4,
    world: ecs.World,
    res: GlobalResource,
    update_container: systems.SystemUpdateContainer,
    draw_container: systems.SystemDrawContainer,
    point_clamp: graphics.Sampler,

    fn init(ctx: *GameContext) void {
        load_content(ctx) catch {
            @panic("Error!");
        };
        ctx.state.res.count = 0;
        ctx.state.point_clamp = graphics.Sampler.init(ctx.graphics, structs.SamplerCreateInfo.pointClamp());

        const vertex_transfer_buffer = TransferBuffer.init(PCV, ctx.graphics, 1024, .{ .upload = true });
        const index_transfer_buffer = TransferBuffer.init(u32, ctx.graphics, 1024, .{ .upload = true });
        const vert_buffer = graphics.GpuBuffer.init(PCV, ctx.graphics, 1024, .{ .vertex = true });
        const index_buffer = graphics.GpuBuffer.init(u32, ctx.graphics, 1024, .{ .index = true });

        const batch_data: Batcher = .{
            .vertex_transfer_buffer = vertex_transfer_buffer,
            .index_transfer_buffer = index_transfer_buffer,
            .vert_buffer = vert_buffer,
            .index_buffer = index_buffer
        };
        ctx.state.res.batch = batch_data;

        const view = float4x4.createTranslation(0, 0, 0);
        const projection = float4x4.createOrthographicOffCenter(0, 1024, 640, 0, -1, 1);
        ctx.state.mat = view.mul(projection);

        local_init(ctx) catch {
            @panic("Something wrong!");
        };
    }

    fn load_content(ctx: *GameContext) !void {
        var content_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer content_allocator.deinit();

        const allocator = content_allocator.allocator();

        const vertex = try Shader.loadFile(
            ctx.graphics, 
            "assets/compiled/positioncolor.vert" ++ Shader.shaderFormatExtension(),
            .{
            .uniform_buffer_count = 1
        });
        const fragment = try Shader.loadFile(
            ctx.graphics, 
            "assets/compiled/solidcolor.frag" ++ Shader.shaderFormatExtension(), 
            .{});
        defer ctx.graphics.release(vertex);
        defer ctx.graphics.release(fragment);

        var input_builder = structs.inputStateBuilder(allocator);
        try input_builder.addVertexInputState(PCV, 1);
        
        ctx.state.default = GraphicsPipeline.init(ctx.graphics, .{
            .target_info = .{ 
                .color_target_descriptions = &[1]structs.ColorTargetDescription {
                    .{
                        .format = ctx.window.swapchain_format,
                        .blend_state = structs.ColorTargetBlendState.alphaBlend()
                    }
                }
            },
            .depth_stencil_state = structs.DepthStencilState.disable(),
            .multisample_state = structs.MultisampleState.none(),
            .rasterizer_state = structs.RasterizerState.ccwCullNone(),
            .vertex_shader = vertex,
            .fragment_shader = fragment,
            .primitive_type = enums.PrimitiveType.TriangleList,
            .vertex_input_state = try input_builder.build()
        });
    }

    fn local_init(ctx: *GameContext) !void {
        ctx.state.world = try ecs.World.init(ctx.allocator);
        var world = &ctx.state.world;
        ctx.state.update_container = try world.createSystems(systems.SystemUpdateContainer);
        ctx.state.draw_container = try world.createSystems(systems.SystemDrawContainer);
    }

    fn update(ctx: *GameContext, delta: f64) void {
        ctx.state.res.delta = delta;
        ctx.state.res.input = &ctx.inputs;
        ctx.state.world.runSystems(&ctx.state.update_container, &ctx.state.res);
    }

    fn render(ctx: *GameContext) void {
        var command_buffer = ctx.graphics.acquireCommandBuffer();
        const texture = command_buffer.acquireSwapchainTexture(ctx.window);

        if (texture) |tex| {
            ctx.state.world.runSystems(&ctx.state.draw_container, &ctx.state.res);

            const copy_pass = command_buffer.beginCopyPass();
            copy_pass.uploadToBuffer(ctx.state.res.batch.vertex_transfer_buffer, ctx.state.res.batch.vert_buffer, true);
            copy_pass.uploadToBuffer(ctx.state.res.batch.index_transfer_buffer, ctx.state.res.batch.index_buffer, true);
            copy_pass.end();

            const render_pass = command_buffer.beginSingleRenderPass(.{ 
                    .texture = tex, 
                    .clear_color = Color.init(0.3, 0.4, 0.5, 1.0), 
                    .load_op = enums.LoadOp.Clear, 
                    .store_op = enums.StoreOp.Store,
                    .cycle = true
                }
            );
            render_pass.bindGraphicsPipeline(ctx.state.default);
            render_pass.bindVertexBuffer(ctx.state.res.batch.vert_buffer, 0);
            render_pass.bindIndexBuffer(ctx.state.res.batch.index_buffer, .ThirtyTwo);
            command_buffer.pushVertexUniformData(float4x4, ctx.state.mat, 0);
            render_pass.drawIndexedPrimitives(ctx.state.res.count * 6, 1, 0, 0, 0);
            render_pass.end();

            ctx.state.res.count = 0;
        }

        command_buffer.submit();
    }

    fn deinit(ctx: *GameContext) void {
        ctx.graphics.release(ctx.state.default);
        ctx.graphics.release(ctx.state.res.batch.vert_buffer);
        ctx.graphics.release(ctx.state.res.batch.index_buffer);
        ctx.graphics.release(ctx.state.res.batch.index_transfer_buffer);
        ctx.graphics.release(ctx.state.res.batch.vertex_transfer_buffer);
        ctx.graphics.release(ctx.state.point_clamp);
    }
};


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();
    var context = try GameContext.init(allocator, WindowSettings.init("ShootShapes", 1024, 640, .{}));

    context.run(.{
        .init = AppState.init,
        .update = AppState.update,
        .render = AppState.render,
        .deinit = AppState.deinit
    });
}