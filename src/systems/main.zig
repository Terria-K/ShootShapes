pub const SystemInitContainer = struct {
    mouse_system: @import("SpawnWorldSystem.zig"),
};

pub const SystemUpdateContainer = struct {
    cursor_system: @import("CursorSystem.zig"),
    timer_system: @import("TimerSystem.zig"),

    player_system: @import("PlayerSystem.zig"),
    move_system: @import("MoveSystem.zig"),

    tween_system: @import("TweenSystem.zig"),
    card_system: @import("CardSystem.zig"),
};

pub const SystemDrawContainer = struct {
    draw_system: @import("DrawSystem.zig"),
};