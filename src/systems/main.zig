pub const SystemInitContainer = struct {
    mouse_system: @import("SpawnWorldSystem.zig"),
};

pub const SystemUpdateContainer = struct {
    move_system: @import("MoveSystem.zig"),
    mouse_system: @import("CursorSystem.zig"),
    timer_system: @import("TimerSystem.zig"),
    card_system: @import("CardSystem.zig"),
    tween_system: @import("TweenSystem.zig")
};

pub const SystemDrawContainer = struct {
    draw_system: @import("DrawSystem.zig"),
};