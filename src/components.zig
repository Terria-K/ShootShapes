const float2 = @import("engine/math/main.zig").float2;
const KeyCode = @import("engine/enums/main.zig").KeyCode;
const TextureQuad = @import("engine/graphics.zig").TextureQuad;
const TurnState = @import("game/main.zig").TurnState;

pub const Transform = struct {
    position: float2
};

pub const Sprite = struct {
    texture: TextureQuad
};

pub const Move = struct {
    snap: f32
};

pub const Turns = union(enum) {
    player: i32,
    enemy: i32
};

const TimerState = enum(u8) {
    Reset,
    Started,
    Ended,
};

pub const Timer = struct {
    initial_time: f32,
    time: f32,
    status: TimerState,

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

pub const Destroyable = struct {
    _: u1 = 0
};

pub const Cursor = struct {
    _: u1 = 0
};