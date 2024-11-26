const std = @import("std");
const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;
const math = std.math;

pub fn on(comptime Type: type) type {
    return struct {
        pub inline fn snapped(px: Type, step: Type) Type {
            if (step != 0) {
                if (@typeInfo(Type) == .Float) {
                    return math.floor((px / step) + 0.5) * step;
                } else {
                    return @divFloor(px, step) + step;
                }
            }
            return px;
        }

        pub inline fn moveTowards(current: Type, target: Type, max_delta: Type) Type {
            if (@abs(target - current) <= max_delta) {
                return target;
            }

            return current + math.sign(target - current) * max_delta;
        }

        pub inline fn lookAt(x: Type, y: Type) Type {
            return math.atan2(y, x);
        }

        pub const Vec2 = extern struct {
            x: Type,
            y: Type,

            pub inline fn new(x: Type, y: Type) Vec2 {
                const vec: @Vector(2, Type) = .{ x, y };
                return @bitCast(vec);
            }

            pub inline fn rotated(self: Vec2, angle: Type) Vec2 {
                const sin = math.sin(angle);
                const cos = math.cos(angle);
                return Vec2.new(self.x * cos - self.y * sin, self.x * sin + self.y * cos);
            }

            pub inline fn floor(self: Vec2) Vec2 {
                return Vec2.new(math.floor(self.x), math.floor(self.y));
            }

            pub inline fn ceil(self: Vec2) Vec2 {
                return Vec2.new(math.ceil(self.x), math.ceil(self.y));
            }

            pub inline fn snappedVec(self: Vec2, step: Vec2) Vec2 {
                return Vec2.new(snapped(self.x, step.x), snapped(self.y, step.y));
            }

            pub inline fn add(self: Vec2, other: Vec2) Vec2 {
                return .{
                    .x = self.x + other.x,
                    .y = self.y + other.y,
                };
            }

            pub inline fn sub(self: Vec2, other: Vec2) Vec2 {
                return .{
                    .x = self.x - other.x,
                    .y = self.y - other.y,
                };
            }

            pub inline fn mulScalar(self: Vec2, scale: Type) Vec2 {
                return .{
                    .x = self.x * scale,
                    .y = self.y * scale,
                };
            }

            pub inline fn mul(self: Vec2, other: Vec2) Vec2 {
                return .{
                    .x = self.x * other.x,
                    .y = self.y * other.y,
                };
            }

            pub inline fn divScalar(self: Vec2, scale: Type) Vec2 {
                return .{
                    .x = self.x / scale,
                    .y = self.y / scale,
                };
            }

            pub inline fn div(self: Vec2, other: Vec2) Vec2 {
                return .{
                    .x = self.x / other.x,
                    .y = self.y / other.y,
                };
            }

            pub inline fn toVertexFormat() VertexElementFormat {
                return switch (@typeInfo(Type)) {
                    .Float => VertexElementFormat.Float2,
                    .Int => VertexElementFormat.Int2,
                    else => @panic("Not supported Type")
                };
            }
        };

        pub const Vec3 = extern struct {
            x: Type,
            y: Type,
            z: Type,

            pub inline fn new(x: Type, y: Type, z: Type) Vec3 {
                return .{ .x = x, .y = y, .z = z };
            }

            pub inline fn floor(self: Vec3) Vec3 {
                return Vec3.new(math.floor(self.x), math.floor(self.y), math.floor(self.z));
            }

            pub inline fn ceil(self: Vec3) Vec3 {
                return Vec3.new(math.ceil(self.x), math.ceil(self.y), math.floor(self.z));
            }

            pub inline fn toVertexFormat() VertexElementFormat {
                return switch (@typeInfo(Type)) {
                    .Float => VertexElementFormat.Float3,
                    .Int => VertexElementFormat.Int3,
                    else => @panic("Not supported Type")
                };
            }
        };

        pub const Vec4 = extern struct {
            x: Type,
            y: Type,
            z: Type,
            w: Type,

            pub inline fn new(x: Type, y: Type, z: Type, w: Type) Vec4 {
                return .{ .x = x, .y = y, .z = z, .w = w };
            }

            pub inline fn floor(self: Vec4) Vec4 {
                return Vec4.new(math.floor(self.x), math.floor(self.y), math.floor(self.z), math.floor(self.w));
            }

            pub inline fn ceil(self: Vec4) Vec4 {
                return Vec4.new(math.ceil(self.x), math.ceil(self.y), math.floor(self.z), math.floor(self.w));
            }

            pub inline fn toVertexFormat() VertexElementFormat {
                return switch (@typeInfo(Type)) {
                    .Float => VertexElementFormat.Float4,
                    .Int => VertexElementFormat.Int4,
                    else => @panic("Not supported Type")
                };
            }
        };

        pub const Rectangle = extern struct {
            x: Type, y: Type, width: Type, height: Type,

            pub inline fn init(x: Type, y: Type, width: Type, height: Type) Rectangle {
                return .{
                    .x = x,
                    .y = y,
                    .width = width,
                    .height = height
                };
            }
        };

        pub const Mat4 = extern struct {
            m11: Type, m12: Type, m13: Type, m14: Type,
            m21: Type, m22: Type, m23: Type, m24: Type,
            m31: Type, m32: Type, m33: Type, m34: Type,
            m41: Type, m42: Type, m43: Type, m44: Type,

            pub inline fn init(m11: Type, m12: Type, m13: Type, m14: Type, m21: Type, m22: Type, m23: Type, m24: Type, m31: Type, m32: Type, m33: Type, m34: Type, m41: Type, m42: Type, m43: Type, m44: Type) Mat4 {
                return .{
                    .m11 = m11,
                    .m12 = m12,
                    .m13 = m13,
                    .m14 = m14,
                    .m21 = m21,
                    .m22 = m22,
                    .m23 = m23,
                    .m24 = m24,
                    .m31 = m31,
                    .m32 = m32,
                    .m33 = m33,
                    .m34 = m34,
                    .m41 = m41,
                    .m42 = m42,
                    .m43 = m43,
                    .m44 = m44,
                };
            }

            pub inline fn identity() Mat4 {
                return Mat4.init(
                    1, 0, 0, 0, 
                    0, 1, 0, 0, 
                    0, 0, 1, 0,
                    0, 0, 0, 1
                );
            }

            pub inline fn isIdentity(self: Mat4) bool {
                return self.m11 == 1 and self.m12 == 0 and self.m13 == 0 and self.m14 == 0 and
                        self.m21 == 0 and self.m22 == 1 and self.m23 == 0 and self.m24 == 0 and
                        self.m31 == 0 and self.m32 == 0 and self.m33 == 1 and self.m34 == 0 and
                        self.m41 == 0 and self.m42 == 0 and self.m43 == 0 and self.m44 == 1;
            }

            pub inline fn createOrthographicOffCenter(left: Type, right: Type, bottom: Type, top: Type, zNearPlane: Type, zFarPlane: Type) Mat4 {
                const mleft = 2.0 / (right - left);
                const mtop = 2.0 / (top - bottom);
                const mside = 1.0 / (zNearPlane - zFarPlane);
                return Mat4.init(
                    mleft, 0, 0, 0, 
                    0, mtop, 0, 0, 
                    0, 0, mside, 0,
                    (left + right) / (left - right), (top + bottom) / (bottom - top), zNearPlane / (zNearPlane - zFarPlane), 1
                );
            }

            pub inline fn getTranslation(self: Mat4) Vec3 {
                return Vec3.new(self.m41, self.m42, self.m43);
            }
            
            pub inline fn setTranslation(self: *Mat4, vec3: Vec3) void {
                self.m41 = vec3.x;
                self.m42 = vec3.y;
                self.m43 = vec3.z;
            }

            pub inline fn createTranslation(xPos: Type, yPos: Type, zPos: Type) Mat4 {
                return Mat4.init(
                    1, 0, 0, 0, 
                    0, 1, 0, 0, 
                    0, 0, 1, 0,
                    xPos, yPos, zPos, 1
                );
            }

            pub inline fn createScale(xScale: Type, yScale: Type, zScale: Type) Mat4 {
                return Mat4.init(
                    xScale, 0, 0, 0, 
                    0, yScale, 0, 0, 
                    0, 0, zScale, 0,
                    0, 0, 0, 1
                );
            }

            pub inline fn negate(self: Mat4) Mat4 {
                return Mat4.init(
                    -self.m11, -self.m12, -self.m13, -self.m14, 
                    -self.m21, -self.m22, -self.m23, -self.m24,
                    -self.m31, -self.m32, -self.m33, -self.m34,
                    -self.m41, -self.m42, -self.m43, -self.m44,
                );
            }

            pub inline fn add(self: Mat4, other: Mat4) Mat4 {
                return Mat4.init(
                    self.m11 + other.m11, self.m12 + other.m12, self.m13 + other.m13, self.m14 + other.m14, 
                    self.m21 + other.m21, self.m22 + other.m22, self.m23 + other.m23, self.m24 + other.m24,
                    self.m31 + other.m31, self.m32 + other.m32, self.m33 + other.m33, self.m34 + other.m34,
                    self.m41 + other.m41, self.m42 + other.m42, self.m43 + other.m43, self.m44 + other.m44,
                );
            }

            pub inline fn sub(self: Mat4, other: Mat4) Mat4 {
                return Mat4.init(
                    self.m11 - other.m11, self.m12 - other.m12, self.m13 - other.m13, self.m14 - other.m14, 
                    self.m21 - other.m21, self.m22 - other.m22, self.m23 - other.m23, self.m24 - other.m24,
                    self.m31 - other.m31, self.m32 - other.m32, self.m33 - other.m33, self.m34 - other.m34,
                    self.m41 - other.m41, self.m42 - other.m42, self.m43 - other.m43, self.m44 - other.m44,
                );
            }

            pub inline fn mulScalar(self: Mat4, scale: Type) Mat4 {
                return Mat4.init(
                    self.m11 * scale, self.m12 * scale, self.m13 * scale, self.m14 * scale, 
                    self.m21 * scale, self.m22 * scale, self.m23 * scale, self.m24 * scale,
                    self.m31 * scale, self.m32 * scale, self.m33 * scale, self.m34 * scale,
                    self.m41 * scale, self.m42 * scale, self.m43 * scale, self.m44 * scale,
                );
            }

            pub inline fn mul(self: Mat4, other: Mat4) Mat4 {
                const m11 = self.m11 * other.m11 + self.m12 * other.m21 + self.m13 * other.m31 + self.m14 * other.m41;
                const m12 = self.m11 * other.m12 + self.m12 * other.m22 + self.m13 * other.m32 + self.m14 * other.m42;
                const m13 = self.m11 * other.m13 + self.m12 * other.m23 + self.m13 * other.m33 + self.m14 * other.m43;
                const m14 = self.m11 * other.m14 + self.m12 * other.m24 + self.m13 * other.m34 + self.m14 * other.m44;

                const m21 = self.m21 * other.m11 + self.m22 * other.m21 + self.m23 * other.m31 + self.m24 * other.m41;
                const m22 = self.m21 * other.m12 + self.m22 * other.m22 + self.m23 * other.m32 + self.m24 * other.m42;
                const m23 = self.m21 * other.m13 + self.m22 * other.m23 + self.m23 * other.m33 + self.m24 * other.m43;
                const m24 = self.m21 * other.m14 + self.m22 * other.m24 + self.m23 * other.m34 + self.m24 * other.m44;

                const m31 = self.m31 * other.m11 + self.m32 * other.m21 + self.m33 * other.m31 + self.m34 * other.m41;
                const m32 = self.m31 * other.m12 + self.m32 * other.m22 + self.m33 * other.m32 + self.m34 * other.m42;
                const m33 = self.m31 * other.m13 + self.m32 * other.m23 + self.m33 * other.m33 + self.m34 * other.m43;
                const m34 = self.m31 * other.m14 + self.m32 * other.m24 + self.m33 * other.m34 + self.m34 * other.m44;

                const m41 = self.m41 * other.m11 + self.m42 * other.m21 + self.m43 * other.m31 + self.m44 * other.m41;
                const m42 = self.m41 * other.m12 + self.m42 * other.m22 + self.m43 * other.m32 + self.m44 * other.m42;
                const m43 = self.m41 * other.m13 + self.m42 * other.m23 + self.m43 * other.m33 + self.m44 * other.m43;
                const m44 = self.m41 * other.m14 + self.m42 * other.m24 + self.m43 * other.m34 + self.m44 * other.m44;

                return Mat4.init(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44);
            }
        };
    };
}
