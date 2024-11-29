const generics = @import("generics.zig");

pub const int2 = generics.on(i32).Vec2;
pub const int3 = generics.on(i32).Vec3;
pub const int4 = generics.on(i32).Vec4;

pub const uint2 = generics.on(u32).Vec2;
pub const uint3 = generics.on(u32).Vec3;
pub const uint4 = generics.on(u32).Vec4;

pub const float2 = generics.on(f32).Vec2;
pub const float3 = generics.on(f32).Vec3;
pub const float4 = generics.on(f32).Vec4;
pub const float4x4 = generics.on(f32).Mat4;

pub const double2 = generics.on(f64).Vec2;
pub const double3 = generics.on(f64).Vec3;
pub const double4 = generics.on(f64).Vec4;
pub const double4x4 = generics.on(f64).Mat4;

pub const rect = generics.on(i32).Rectangle;
pub const urect = generics.on(u32).Rectangle;
pub const frect = generics.on(f32).Rectangle;
pub const drect = generics.on(f64).Rectangle;