const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const ShaderError = @import("graphics/Shader.zig").Error;
const ImageError = @import("graphics/Image.zig").Error;
const ComputePipelineError = @import("graphics/ComputePipeline.zig").Error;

pub const Error = ShaderError || ComputePipelineError || ImageError || std.mem.Allocator.Error;

const GraphicsDevice = @import("graphics/GraphicsDevice.zig");
const InputDevice = @import("input/InputDevice.zig");
const TimeSpan = @import("TimeSpan.zig");
const Window = @import("Window.zig");
const WindowSettings = Window.WindowSettings;
const FIXED_STEP_TARGET = TimeSpan.fromSeconds(1.0 / 60.0);
const FIXED_STEP_MAX_LAP = TimeSpan.fromSeconds(5.0 / 60.0);

pub fn Events(comptime State: type) type {
    return struct {
        init: ?fn(ctx: *GameContext(State)) void = null,
        load_content: ?fn(ctx: *GameContext(State)) Error!void = null,
        update: ?fn (ctx: *GameContext(State), delta: f64) void = null,
        render: ?fn (ctx: *GameContext(State)) void = null,
        deinit: ?fn (ctx: *GameContext(State)) void = null
    };
}

pub fn GameContext(comptime State: type) type {
    return struct {
        allocator: std.mem.Allocator,
        graphics: GraphicsDevice,
        exiting: bool = false,
        timer: std.time.Timer,
        lastTime: u64 = 0,
        accumulator: u64 = 0,
        window: Window,
        inputs: InputDevice,
        state: *State,

        pub fn init(allocator: std.mem.Allocator, comptime settings: WindowSettings) !GameContext(State) {
            const state = try allocator.create(State);
            var window = Window.init(settings);
            const timer = try std.time.Timer.start();
            var graphics =  GraphicsDevice.init();
            if (!graphics.claimWindow(
                &window, 
                sdl.SDL_GPU_SWAPCHAINCOMPOSITION_SDR, 
                sdl.SDL_GPU_PRESENTMODE_VSYNC)) {
                std.log.err("Cannot claim this window.", .{});
            }
            return .{ 
                .state = state, 
                .allocator = allocator, 
                .timer = timer, 
                .window = window, 
                .graphics = graphics,
                .inputs = InputDevice.init()
            };
        }

        pub fn run(self: *GameContext(State), comptime loop: Events(State)) void {
            if (loop.load_content) |content| {
                content(self) catch {
                    @panic("Not yet");
                };
            }

            if (loop.init) |ini| {
                ini(self);
            }
            self.window.show();
            while (self.tick(loop)) {}

            if (loop.deinit) |deini| {
                deini(self);
            }
            self.deinit();
            self.graphics.unclaimWindow(&self.window);

            self.window.deinit();
            self.graphics.deinit();

            sdl.SDL_Quit();
        }

        pub fn tick(self: *GameContext(State), comptime loop: Events(State)) bool {
            var currentTime = self.timer.read();
            var deltaTime = currentTime - self.lastTime;
            self.lastTime = currentTime;

            while (self.accumulator < FIXED_STEP_TARGET) {
                const ns = FIXED_STEP_TARGET - self.accumulator;
                std.time.sleep(ns);

                currentTime = self.timer.read();

                deltaTime = currentTime - self.lastTime;
                self.lastTime = currentTime;
                self.accumulator += deltaTime;
            }

            self.pollEvents();

            if (self.accumulator > FIXED_STEP_MAX_LAP) {
                self.accumulator = FIXED_STEP_MAX_LAP;
            }

            while (self.accumulator >= FIXED_STEP_TARGET) {
                self.accumulator -= FIXED_STEP_TARGET;
                self.inputs.update();
                if (loop.update) |upd| {
                    upd(self, @as(f64, @floatFromInt(FIXED_STEP_TARGET)) * 1.0 / std.time.ns_per_s);
                }
                if (self.exiting) {
                    return false;
                }
            }
            

            if (loop.render) |rend| {
                rend(self);
            }
            return true;
        }

        fn pollEvents(self: *GameContext(State)) void {
            var event: sdl.SDL_Event = undefined;
            while (sdl.SDL_PollEvent(&event)) {
                switch (event.type) {
                    sdl.SDL_EVENT_QUIT => self.exiting = true,
                    sdl.SDL_EVENT_WINDOW_CLOSE_REQUESTED => {
                        self.graphics.unclaimWindow(&self.window);
                        self.window.deinit();
                    },
                    else => {},
                }
            }
        }

        pub fn deinit(ctx: *GameContext(State)) void {
            ctx.allocator.destroy(ctx.state);
        }
    };
}


