const float2 = @import("engine/math/main.zig").float2;
const KeyCode = @import("engine/enums/main.zig").KeyCode;
const TextureQuad = @import("engine/graphics.zig").TextureQuad;
const TurnState = @import("game/main.zig").TurnState;
const Color = @import("engine/graphics.zig").Color;

pub const Transform = struct {
    position: float2,
    scale: float2 = float2.new(1, 1)
};

pub const Pulsing = struct {
    progress: f32 = 0
};

pub const Sprite = struct {
    texture: TextureQuad,
    color: Color = Color.white
};

pub const Move = struct {
    snap: f32
};

pub const Turns = union(enum) {
    player: i32,
    enemy: i32
};

pub const Timer = struct {
    const State = enum(u8) {
        Reset,
        Started,
        Ended,
    };

    initial_time: f32,
    time: f32,
    status: State,

    pub fn init(time: f32) Timer {
        return .{
            .initial_time = time,
            .time = 0,
            .status = .Reset,
        };
    }

    pub fn start(self: *Timer) void {
        self.time = self.initial_time;
        self.status = .Started;
    }

    pub fn reset(self: *Timer) void {
        self.time = 0;
        self.status = .Reset;
    }
};

pub const Cursor = struct {
    _: u1 = 0
};

pub const Card = struct {
    progress: f32 = 0,
    hovering: bool = false,
    target: f32 = 20,
    _: u1 = 0
};


pub const Tween = struct {
    const EaseType = enum {
        EaseIn,
        EaseOut,
        EaseInOut
    };

    progress: f64 = 0,
    value: f32 = 0,
    started: bool = false,
    ease: EaseType = .EaseIn,

    pub fn start(self: *@This()) void {
        self.progress = 0;
        self.value = 0;
        self.started = true;
    }
};
