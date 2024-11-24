pub const MoveSystem = @import("MoveSystem.zig");
pub const DestroySystem = @import("DestroySystem.zig");
pub const DrawSystem = @import("DrawSystem.zig");


pub const SystemUpdateContainer = struct {
    destroy_system: DestroySystem,
    move_system: MoveSystem,
};

pub const SystemDrawContainer = struct {
    draw_system: DrawSystem,
};