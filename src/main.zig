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

const PCV = @import("engine/vertex/main.zig").PositionColorVertex;
const components = @import("components.zig");


pub const AppState = struct {
    default: GraphicsPipeline,
    vert_buffer: graphics.GpuBuffer,
    index_buffer: graphics.GpuBuffer,
    vertex_transfer_buffer: graphics.TransferBuffer,
    index_transfer_buffer: graphics.TransferBuffer,
    count: u32,
    mat: float4x4,
    world: ecs.World,
    move: *ecs.filter.EntityFilter,
    drawable: *ecs.filter.EntityFilter,

    fn init(ctx: *GameContext) void {
        load_content(ctx) catch {
            @panic("Error!");
        };
        ctx.state.count = 0;

        const vertex_transfer_buffer = TransferBuffer.init(PCV, ctx.graphics, 1024, .{ .upload = true });
        const index_transfer_buffer = TransferBuffer.init(u32, ctx.graphics, 1024, .{ .upload = true });
        const vert_buffer = graphics.GpuBuffer.init(PCV, ctx.graphics, 1024, .{ .vertex = true });
        const index_buffer = graphics.GpuBuffer.init(u32, ctx.graphics, 1024, .{ .index = true });

        ctx.state.vertex_transfer_buffer = vertex_transfer_buffer;
        ctx.state.index_transfer_buffer = index_transfer_buffer;    
        ctx.state.vert_buffer = vert_buffer;
        ctx.state.index_buffer = index_buffer;

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

        const vertex = try Shader.loadFile(ctx.graphics, "assets/compiled/positioncolor.vert.spv", .{
            .uniform_buffer_count = 1
        });
        const fragment = try Shader.loadFile(ctx.graphics, "assets/compiled/solidcolor.frag.spv", .{});
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
        var world = try ecs.World.init(ctx.allocator);

        var filter = world.createFilter();
        try filter.with(float2);
        ctx.state.move = try filter.build(&world);

        var drawable = world.createFilter();
        try drawable.with(float2);
        try drawable.with(components.Movable);
        ctx.state.drawable = try drawable.build(&world);

        const entity1 = world.createEntity();
        try world.setComponent(float2, float2.new(40, 80), entity1);
        try world.setComponent(components.Movable, .{}, entity1);

        const entity2 = world.createEntity();
        try world.setComponent(float2, float2.new(20, 50), entity2);

        ctx.state.world = world;
    }

    fn update(ctx: *GameContext, delta: f64) void {
        var iter = ctx.state.move.entities.iterator();
        while (iter.next()) |entity| {
            const pos = ctx.state.world.getComponent(float2, entity.*);
            pos.*.x += @floatCast(delta);
        }
    }

    fn addVertex(count: u32, vertices: [*]PCV, indices: [*]u32, pos: float2) void {
        const size = 32;
        vertices[count * 4] = .{ .position = float4.new(pos.x, pos.y, 0, 1), .color = Color.init(1, 1, 1, 1) };
        vertices[count * 4 + 1] = .{ .position = float4.new(pos.x + size, pos.y, 0, 1), .color = Color.init(1, 1, 1, 1) };
        vertices[count * 4 + 2] = .{ .position = float4.new(pos.x, pos.y + size, 0, 1), .color = Color.init(1, 1, 1, 1) };
        vertices[count * 4 + 3] = .{ .position = float4.new(pos.x + size, pos.y + size, 0, 1), .color = Color.init(1, 1, 1, 1) };

        indices[count * 6] = (count * 4) + 0;
        indices[count * 6 + 1] = (count * 4) + 1;
        indices[count * 6 + 2] = (count * 4) + 2;
        indices[count * 6 + 3] = (count * 4) + 2;
        indices[count * 6 + 4] = (count * 4) + 1;
        indices[count * 6 + 5] = (count * 4) + 3;
    }

    fn render(ctx: *GameContext) void {
        var command_buffer = ctx.graphics.acquireCommandBuffer();
        const texture = command_buffer.acquireSwapchainTexture(ctx.window);

        if (texture) |tex| {
            const vertices = ctx.state.vertex_transfer_buffer.map(PCV, true);
            const indices= ctx.state.index_transfer_buffer.map(u32, true);

            var iter = ctx.state.drawable.entities.iterator();
            while (iter.next()) |entity| {
                const pos = ctx.state.world.getComponent(float2, entity.*);
                addVertex(ctx.state.count, vertices, indices, pos.*);
                ctx.state.count += 1;
            }
            ctx.state.index_transfer_buffer.unmap();
            ctx.state.vertex_transfer_buffer.unmap();

            const copy_pass = command_buffer.beginCopyPass();
            copy_pass.uploadToBuffer(ctx.state.vertex_transfer_buffer, ctx.state.vert_buffer, true);
            copy_pass.uploadToBuffer(ctx.state.index_transfer_buffer, ctx.state.index_buffer, true);
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
            render_pass.bindVertexBuffer(ctx.state.vert_buffer, 0);
            render_pass.bindIndexBuffer(ctx.state.index_buffer, .ThirtyTwo);
            command_buffer.pushVertexUniformData(float4x4, ctx.state.mat, 0);
            render_pass.drawIndexedPrimitives(ctx.state.count * 6, 1, 0, 0, 0);
            render_pass.end();

            ctx.state.count = 0;
        }

        command_buffer.submit();
    }
};


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();
    var context = try GameContext.init(allocator, WindowSettings.init("ShootShapes", 1024, 640, .{}));

    context.run(.{
        .init = AppState.init,
        .update = AppState.update,
        .render = AppState.render
    });
}