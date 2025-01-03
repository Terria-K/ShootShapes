const std = @import("std");
const structs = @import("engine/structs.zig");
const graphics = @import("engine/graphics.zig");
const components = @import("components.zig");
const systems = @import("systems/main.zig");
const ecs = @import("engine/ecs.zig");
const game = @import("engine/game.zig");

const GraphicsPipeline = graphics.GraphicsPipeline;
const ComputePipeline = graphics.ComputePipeline;
const Color = graphics.Color;

const GameContext = game.GameContext(AppState);
const WindowSettings = @import("engine/Window.zig").WindowSettings;
const float2 = @import("engine/math.zig").float2;
const frect = @import("engine/math.zig").frect;
const Camera = @import("engine/Camera.zig");
const InputDevice = @import("engine/input/InputDevice.zig");
const PCV = @import("engine/vertex.zig").PositionTextureColorConcreteVertex;

const TurnState = @import("game/main.zig").TurnState;


pub const GlobalResource = struct {
    delta: f64,
    input: *InputDevice,
    batch: graphics.SpriteBatch,
    default: GraphicsPipeline,
    count: u32,
    texture: graphics.Texture,
    sampler: graphics.Sampler,
    camera_matrix: Camera,
    turn_state: TurnState
};


pub const AppState = struct {
    world: ecs.World,
    res: GlobalResource,
    init_container: systems.SystemInitContainer,
    update_container: systems.SystemUpdateContainer,
    draw_container: systems.SystemDrawContainer,
    sprite_batch_pipeline: ComputePipeline,
    target: graphics.Texture,

    fn init(ctx: *GameContext) void {
        load_content(ctx) catch {
            @panic("Error!");
        };
        ctx.state.res.count = 0;
        ctx.state.res.sampler = graphics.Sampler.init(ctx.graphics, structs.SamplerCreateInfo.pointClamp());

        local_init(ctx) catch {
            @panic("Something wrong!");
        };
        ctx.state.world.runSystems(&ctx.state.init_container, &ctx.state.res);

        ctx.state.res.camera_matrix = Camera.init(1024 / 2, 640 / 2);
        ctx.state.res.turn_state = .PlayerTurn;
        ctx.state.target = graphics.Texture.init(ctx.graphics, 1024, 640, .B8G8R8A8_UNORM, .{ .color_target = true, .sampler = true });
    }

    fn load_content(ctx: *GameContext) game.Error!void {
        var content_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer content_allocator.deinit();

        const allocator = content_allocator.allocator();

        var uploader = graphics.TextureUploader.init(allocator, ctx.graphics, .{});
        defer ctx.graphics.release(uploader);
        const result = try graphics.Image.loadImage(allocator, "assets/result.png");
        ctx.state.res.texture = try uploader.createTextureFromImage(result);
        uploader.upload();

        const builtin = try graphics.stockshaders.useBuiltins(ctx.graphics, .{ 
            .positiontexturecolor_vert = true, 
            .texture_frag = true,
            .spritebatch_comp = true 
        });

        ctx.state.sprite_batch_pipeline = builtin.spritebatch_comp;

        const sprite_batch = try graphics.SpriteBatch.init(ctx.allocator, ctx.graphics, 1024, 640, ctx.state.sprite_batch_pipeline);

        ctx.state.res.batch = sprite_batch;

        const vertex = builtin.positiontexturecolor_vert;
        const fragment = builtin.texture_frag;

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
                        .blend_state = structs.ColorTargetBlendState.premultipliedAlphaBlend()
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
        ctx.state.init_container = try world.createSystems(systems.SystemInitContainer);
        ctx.state.update_container = try world.createSystems(systems.SystemUpdateContainer);
        ctx.state.draw_container = try world.createSystems(systems.SystemDrawContainer);
    }

    fn update(ctx: *GameContext, delta: f64) void {
        ctx.state.res.delta = delta;
        ctx.state.res.input = &ctx.inputs;
        ctx.state.world.runSystems(&ctx.state.update_container, &ctx.state.res);
        ctx.state.world.update();
    }

    fn render(ctx: *GameContext) void {
        var command_buffer = ctx.graphics.acquireCommandBuffer();
        const texture = command_buffer.acquireSwapchainTexture(ctx.window);

        if (texture) |tex| {
            {
                ctx.state.world.runSystems(&ctx.state.draw_container, &ctx.state.res);

                const render_pass = command_buffer.beginSingleRenderPass(.{ 
                        .texture = ctx.state.target, 
                        .clear_color = Color.transparent,
                        .load_op = .Clear, 
                        .store_op = .Store,
                        .cycle = true
                    }
                );

                ctx.state.res.batch.render(render_pass);
                render_pass.end();
            }


            {
                ctx.state.res.batch.begin(.{
                    .pipeline = ctx.state.res.default,
                    .texture = ctx.state.target,
                    .sampler = ctx.state.res.sampler
                });
                ctx.state.res.batch.draw(.{
                    .position = float2.new(0, 0),
                    .texture_quad = graphics.TextureQuad.initFromTexture(ctx.state.target, frect.init(0, 0, 1024, 640))
                });
                ctx.state.res.batch.end();
                const render_pass = command_buffer.beginSingleRenderPass(.{ 
                        .texture = tex, 
                        .clear_color = Color.cornflowerBlue,
                        .load_op = .Clear, 
                        .store_op = .Store,
                        .cycle = true
                    }
                );
                ctx.state.res.batch.render(render_pass);
                render_pass.end();
            }

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
        ctx.graphics.release(ctx.state.target);
    }
};


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();
    var context = try GameContext.init(allocator, WindowSettings.init("ShootShapes", 1024, 640, .{}));

    try context.run(.{
        .init = AppState.init,
        .update = AppState.update,
        .render = AppState.render,
        .deinit = AppState.deinit
    });
    std.log.info("{any}", .{gpa.deinit()});
}

test "full test" {
    _ = @import("build/texture_packer.zig");
    _ = @import("engine/ecs.zig");
    _ = @import("engine/ecs.zig").SparseSet;
    _ = @import("engine/graphics.zig").Shader;
    _ = @import("engine/graphics/reflection/shader_reflection.zig");
}