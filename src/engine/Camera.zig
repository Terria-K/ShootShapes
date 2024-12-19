const Camera = @This();
const float4x4 = @import("math.zig").float4x4;
const float2 = @import("math.zig").float2;
const float3 = @import("math.zig").float3;

unprotected_transform: float4x4 = float4x4.identity(),
unprotected_inverse: float4x4 = float4x4.identity(),
position: float2 = float2.new(0, 0),
zoom: float2 = float2.new(1, 1),
origin: float2 = float2.new(0, 0),
offset: float2 = float2.new(0, 0),
angle: f32 = 0,
dirty: bool = true,
// viewport
x: f32 = 0,
y: f32 = 0,
width: f32,
height: f32,

pub fn init(width: f32, height: f32) Camera {
    return .{
        .width = width,
        .height = height
    };
}

fn update_matrix(self: *Camera) void {
    const xy = float2.new(@floor(self.position.x + self.offset.x), @floor(self.position.y + self.offset.y));
    const pos = float3.new(xy.x, xy.y, 0);

    const zooming = float3.new(self.zoom.x, self.zoom.y, -1);
    const orig_xy = float2.new(@floor(self.origin.x), @floor(self.origin.y));
    const orig = float3.new(orig_xy.x, orig_xy.y, 0);

    const model = float4x4.identity()
                    .mul(float4x4.createTranslation(pos.x, pos.y, pos.z))
                    .mul(float4x4.createScale(zooming.x, zooming.y, zooming.z))
                    .mul(float4x4.createTranslation(orig.x, orig.y, orig.z));
    
    const view = float4x4.createTranslation(0, 0, 1);
    const projection = float4x4.createOrthographicOffCenter(0, self.width, self.height, 0, -1, 1);

    self.unprotected_transform = model.mul(view).mul(projection);

    if (model.invert()) |minverse| {
        self.unprotected_inverse = minverse;
    }
    self.dirty = false;
}

pub fn transform(self: *Camera) float4x4 {
    if (self.dirty) {
        self.update_matrix();
    }

    return self.unprotected_transform;
}

pub fn screenToViewport(self: *Camera, width: f32, height: f32, pos: float2) float2 {
    const current_x = pos.x - self.x;
    const current_y = pos.y - self.y;

    return float2.new(current_x / width * self.width, current_y / height * self.height);
}

pub fn screenToWorld(self: *Camera, width: f32, height: f32, pos: float2) float2 {
    return self.screenToCamera(self.screenToViewport(width, height, pos));
}

pub fn screenToCamera(self: *Camera, pos: float2) float2 {
    if (self.dirty) {
        self.update_matrix();
    }
    return float2.transform(pos, self.unprotected_inverse);
}

