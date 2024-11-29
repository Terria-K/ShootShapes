const float2 = @import("engine/math/main.zig").float2;
const KeyCode = @import("engine/enums/main.zig").KeyCode;
const TextureQuad = @import("engine/graphics.zig").TextureQuad;

pub const Transform = struct {
    position: float2
};

pub const Sprite = struct {
    texture: TextureQuad
};

pub const Move = struct {
    snap: f32
};

pub const Turns = struct {
    turn_count: i32 = 5
};

pub const Object = union(enum) {
    Normal: u32,
    Hard: bool
};

pub const Destroyable = struct {
    _: u1 = 0
};