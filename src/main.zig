const std = @import("std");
const structs = @import("engine/structs/main.zig");
const graphics = @import("engine/graphics/main.zig");

const Shader = graphics.Shader; 
const GraphicsPipeline = graphics.GraphicsPipeline;
const ComputePipeline = graphics.ComputePipeline;
const Color = graphics.Color;
const TransferBuffer = graphics.TransferBuffer;

const GameContext = @import("engine/game.zig").GameContext(AppState);
const WindowSettings = @import("engine/Window.zig").WindowSettings;
const ColorTargetInfo = @import("engine/structs/ColorTargetInfo.zig");
const float4x4 = @import("engine/math/main.zig").float4x4;
const float4 = @import("engine/math/main.zig").float4;
const float2 = @import("engine/math/main.zig").float2;
const ecs = @import("engine/ecs/main.zig");
const InputDevice = @import("engine/input/InputDevice.zig");

const PCV = @import("engine/vertex/main.zig").PositionTextureColorConcreteVertex;
const components = @import("components.zig");
const systems = @import("systems/main.zig");
const Batcher = @import("Batcher.zig");

pub const GlobalResource = struct {
    delta: f64,
    input: *InputDevice,
    batch: graphics.SpriteBatch,
    default: GraphicsPipeline,
    count: u32,
    texture: graphics.Texture,
    sampler: graphics.Sampler,
};


pub const AppState = struct {
    mat: float4x4,
    world: ecs.World,
    res: GlobalResource,
    update_container: systems.SystemUpdateContainer,
    draw_container: systems.SystemDrawContainer,
    sprite_batch_pipeline: ComputePipeline,

    fn init(ctx: *GameContext) void {
        load_content(ctx) catch {
            @panic("Error!");
        };
        ctx.state.res.count = 0;
        ctx.state.res.sampler = graphics.Sampler.init(ctx.graphics, structs.SamplerCreateInfo.pointClamp());

        const view = float4x4.createTranslation(0, 0, 0);
        const projection = float4x4.createOrthographicOffCenter(0, 1024, 640, 0, -1, 1);
        ctx.state.mat = view.mul(projection);

        local_init(ctx) catch {
            @panic("Something wrong!");
        };
    }

    fn test_void(allocator: std.mem.Allocator) !void {
        const fs = std.fs;
        const Image = @import("engine/graphics/main.zig").Image;
        const Packer = @import("build/texture_packer.zig").Packer(Image);
        const expect = @import("std").testing.expect;
        var packer = Packer.init(allocator, .{});
        defer packer.deinit();

        var dir = try fs.cwd().openDir("assets/textures", .{ .iterate = true });
        var walker = try dir.walk(allocator);
        defer walker.deinit();

        var images = std.ArrayList(Image).init(allocator);
        defer images.deinit();

        defer {
            for (images.items) |image| {
                image.deinit();
            }    
        }

        while (try walker.next()) |entry| {
            const source = try std.fs.path.join(allocator, &[_][]const u8 { "assets/textures", entry.path });
            std.log.warn("{s}", .{source});
            defer allocator.free(source);
            try images.append(try Image.loadImage(allocator, source));
        }

        for (images.items) |image| {
            try packer.add(.{ .width = image.width, .height = image.height, .data = image });
        }

        var result = try packer.pack();
        defer result.packed_items.deinit();
        try expect(result.ok);
    }

    fn load_content(ctx: *GameContext) !void {
        var content_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer content_allocator.deinit();

        const allocator = content_allocator.allocator();

        // try test_void(allocator);


        var uploader = graphics.TextureUploader.init(allocator, ctx.graphics, .{});
        defer ctx.graphics.release(uploader);
        ctx.state.res.texture = try uploader.createTextureFromImage(try graphics.Image.loadImage(allocator, "assets/textures/chapter1.png"));
        uploader.upload();

        ctx.state.sprite_batch_pipeline = try ComputePipeline.loadFile(ctx.graphics, "assets/compiled/spritebatch.comp.spv", .{
            .thread_count = .{ .x = 64, .y = 1, .z = 1 },
            .readwrite_storage_buffer_count = 1,
            .readonly_storage_buffer_count = 1
        });

        const sprite_batch = try graphics.SpriteBatch.init(ctx.allocator, ctx.graphics, 1024, 640, ctx.state.sprite_batch_pipeline);

        ctx.state.res.batch = sprite_batch;

        const vertex = try Shader.loadFile(
            ctx.graphics, 
            "assets/compiled/positiontexturecolor.vert" ++ Shader.shaderFormatExtension(),
            .{
            .uniform_buffer_count = 1
        });
        const fragment = try Shader.loadFile(
            ctx.graphics, 
            "assets/compiled/texture.frag" ++ Shader.shaderFormatExtension(), 
            .{ .sampler_count = 1 });
        defer ctx.graphics.release(vertex);
        defer ctx.graphics.release(fragment);

        var input_builder = structs.inputStateBuilder(allocator);
        try input_builder.addVertexInputState(PCV, 1);
        defer input_builder.deinit();
        
        ctx.state.res.default = GraphicsPipeline.init(ctx.graphics, .{
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
            .primitive_type = .TriangleList,
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

            const render_pass = command_buffer.beginSingleRenderPass(.{ 
                    .texture = tex, 
                    .clear_color = Color.cornflowerBlue,
                    .load_op = .Clear, 
                    .store_op = .Store,
                    .cycle = true
                }
            );
            ctx.state.res.batch.bind_default_uniform_matrix(command_buffer);
            ctx.state.res.batch.render(render_pass);
            render_pass.end();

            ctx.state.res.count = 0;
        }

        command_buffer.submit();
    }

    fn deinit(ctx: *GameContext) void {
        ctx.state.world.deinitSystems(ctx.state.update_container);
        ctx.state.world.deinitSystems(ctx.state.draw_container);
        ctx.state.world.deinit();
        ctx.graphics.release(ctx.state.sprite_batch_pipeline);
        ctx.graphics.release(ctx.state.res.batch);
        ctx.graphics.release(ctx.state.res.texture);
        ctx.graphics.release(ctx.state.res.sampler);
        ctx.graphics.release(ctx.state.res.default);
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
    std.log.info("{any}", .{gpa.deinit()});
}

test {
    _ = @import("build/texture_packer.zig");
    _ = @import("engine/ecs/main.zig");
}