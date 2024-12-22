const std = @import("std");
const VertexElementFormat = @import("../enums/main.zig").VertexElementFormat;
const math = std.math;

pub fn on(comptime Type: type) type {
    return struct {
        pub inline fn snapped(px: Type, step: Type) Type {
            if (step != 0) {
                if (@typeInfo(Type) == .Float) {
                    return @floor((px / step) + 0.5) * step;
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
                const sin = @sin(angle);
                const cos = @cos(angle);
                return Vec2.new(self.x * cos - self.y * sin, self.x * sin + self.y * cos);
            }

            pub inline fn floor(self: Vec2) Vec2 {
                return Vec2.new(@floor(self.x), @floor(self.y));
            }

            pub inline fn ceil(self: Vec2) Vec2 {
                return Vec2.new(@ceil(self.x), @ceil(self.y));
            }

            pub inline fn dot(self: Vec2, other: Vec2) Type {
                return (self.x * other.x) + (self.y * other.y);
            }

            pub inline fn normalize(self: Vec2) Vec2 {
                const val = 1.0 / @sqrt((self.x * self.x) + (self.y * self.y));
                return Vec2.new(self.x * val, self.y * val);
            }

            pub inline fn distance(self: Vec2, other: Vec2) Type {
                const v1 = self.x - other.x;
                const v2 = self.y - other.y;
                return @sqrt((v1 * v1) + (v2 * v2));
            }

            pub inline fn negate(self: Vec2) Vec2 {
                return Vec2.new(-self.x, -self.y);
            }

            pub inline fn snappedVec(self: Vec2, step: Vec2) Vec2 {
                return Vec2.new(snapped(self.x, step.x), snapped(self.y, step.y));
            }

            pub inline fn transform(self: Vec2, mat: Mat4) Vec2 {
                return Vec2.new(
                    self.x * mat.m11 + self.y * mat.m21 + mat.m41, 
                    self.x * mat.m12 + self.y * mat.m22 + mat.m42
                );
            }

            pub inline fn add(self: Vec2, other: Vec2) Vec2 {
                return Vec2.new(self.x + other.x, self.y + other.y);
            }

            pub inline fn sub(self: Vec2, other: Vec2) Vec2 {
                return Vec2.new(self.x - other.x, self.y - other.y);
            }

            pub inline fn mulScalar(self: Vec2, scale: Type) Vec2 {
                return Vec2.new(self.x * scale, self.y * scale);
            }

            pub inline fn mul(self: Vec2, other: Vec2) Vec2 {
                return Vec2.new(self.x * other.x, self.y * other.y);
            }

            pub inline fn divScalar(self: Vec2, scale: Type) Vec2 {
                return Vec2.new(self.x / scale, self.y / scale);
            }

            pub inline fn div(self: Vec2, other: Vec2) Vec2 {
                return Vec2.new(self.x / other.x, self.y / other.y);
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
                const vec: @Vector(3, Type) = .{ x, y, z };
                return @bitCast(vec);
            }

            pub inline fn floor(self: Vec3) Vec3 {
                return Vec3.new(@floor(self.x), @floor(self.y), @floor(self.z));
            }

            pub inline fn ceil(self: Vec3) Vec3 {
                return Vec3.new(@ceil(self.x), @ceil(self.y), @floor(self.z));
            }

            pub inline fn negate(self: Vec3) Vec3 {
                return Vec3.new(-self.x, -self.y, -self.z);
            }

            pub inline fn add(self: Vec3, other: Vec3) Vec3 {
                return Vec3.new(self.x + other.x, self.y + other.y, self.z + other.z);
            }

            pub inline fn sub(self: Vec3, other: Vec3) Vec3 {
                return Vec3.new(self.x - other.x, self.y - other.y, self.z - other.z);
            }

            pub inline fn mulScalar(self: Vec3, scale: Type) Vec3 {
                return Vec3.new(self.x * scale, self.y * scale, self.z * scale);
            }

            pub inline fn mul(self: Vec3, other: Vec3) Vec3 {
                return Vec3.new(self.x * other.x, self.y * other.y, self.z * other.z);
            }

            pub inline fn divScalar(self: Vec3, scale: Type) Vec3 {
                return Vec3.new(self.x / scale, self.y / scale, self.z / scale);
            }

            pub inline fn div(self: Vec3, other: Vec3) Vec3 {
                return Vec3.new(self.x / other.x, self.y / other.y, self.z / other.z);
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
                const vec: @Vector(4, Type) = .{ x, y, z, w };
                return @bitCast(vec);
            }

            pub inline fn floor(self: Vec4) Vec4 {
                return Vec4.new(@floor(self.x), @floor(self.y), @floor(self.z), @floor(self.w));
            }

            pub inline fn ceil(self: Vec4) Vec4 {
                return Vec4.new(@ceil(self.x), @ceil(self.y), @floor(self.z), @floor(self.w));
            }

            pub inline fn negate(self: Vec4) Vec4 {
                return Vec4.new(-self.x, -self.y, -self.z, -self.w);
            }

            pub inline fn add(self: Vec4, other: Vec4) Vec4 {
                return Vec4.new(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w);
            }

            pub inline fn sub(self: Vec4, other: Vec4) Vec4 {
                return Vec4.new(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w);
            }

            pub inline fn mulScalar(self: Vec4, scale: Type) Vec4 {
                return Vec4.new(self.x * scale, self.y * scale, self.z * scale, self.w * scale);
            }

            pub inline fn mul(self: Vec4, other: Vec4) Vec4 {
                return Vec4.new(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w);
            }

            pub inline fn divScalar(self: Vec4, scale: Type) Vec4 {
                return Vec4.new(self.x / scale, self.y / scale, self.z / scale, self.w / scale);
            }

            pub inline fn div(self: Vec4, other: Vec4) Vec4 {
                return Vec4.new(self.x / other.x, self.y / other.y, self.z / other.z, self.w / other.w);
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

            pub inline fn containsPoint(self: Rectangle, point: Vec2) bool {
                return self.left() <= point.x and
                        point.x < self.right() and
                        self.top() <= point.y and
                        point.y < self.bottom();
            }

            pub inline fn contains(self: Rectangle, other: Rectangle) bool {
                return other.left() >= self.left() and
                        other.top() >= self.top() and
                        other.right() <= self.right() and
                        other.bottom() <= self.bottom();
            }

            pub inline fn intersects(self: Rectangle, other: Rectangle) bool {
                return other.left() < self.right() and
                        self.left() < other.right() and
                        other.top() < self.bottom() and
                        self.top() < other.bottom();
            }

            pub inline fn overlap(self: Rectangle, other: Rectangle) Rectangle {
                const overlap_x = self.right() > other.left() and self.left() < other.right();
                const overlap_y = self.bottom() > other.top() and self.top() < other.bottom();

                var result: Rectangle = std.mem.zeroes(Rectangle);

                if (overlap_x) {
                    result.x = @max(self.left(), other.left());
                    result.width = @min(self.right(), other.right()) - result.x;
                }

                if (overlap_y) {
                    result.y = @max(self.top(), other.top());
                    result.height = @min(self.bottom(), other.bottom()) - result.y;
                }

                return result;
            }

            pub inline fn left(self: Rectangle) Type {
                return self.x;
            }

            pub inline fn right(self: Rectangle) Type {
                return self.x + self.width;
            }

            pub inline fn top(self: Rectangle) Type {
                return self.y;
            }

            pub inline fn bottom(self: Rectangle) Type {
                return self.y + self.height;
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

            pub inline fn invert(self: Mat4) ?Mat4 {
                // Only floats can be evaluated with invert
                if (@typeInfo(Type) != .Float) {
                    return null;
                }

                const d0 = self.m11 * self.m22 - self.m12 * self.m21;
                const d1 = self.m11 * self.m23 - self.m13 * self.m21;
                const d2 = self.m11 * self.m24 - self.m14 * self.m21;
                const d3 = self.m12 * self.m23 - self.m13 * self.m22;
                const d4 = self.m12 * self.m24 - self.m14 * self.m22;
                const d5 = self.m13 * self.m24 - self.m14 * self.m23;
                const d6 = self.m31 * self.m42 - self.m32 * self.m41;
                const d7 = self.m31 * self.m43 - self.m33 * self.m41;
                const d8 = self.m31 * self.m44 - self.m34 * self.m41;
                const d9 = self.m32 * self.m43 - self.m33 * self.m42;
                const d10 = self.m32 * self.m44 - self.m34 * self.m42;
                const d11 = self.m33 * self.m44 - self.m34 * self.m43;

                const determinant = d0 * d11 - d1 * d10 + 
                                    d2 * d9 + d3 * d8 - 
                                    d4 * d7 + d5 * d6;
                
                if (@abs(determinant) < std.math.floatEps(Type)) {
                    return null;
                }

                const inverse_det = 1.0 / determinant;

                return Mat4.init(
                    (self.m22 * d11 - self.m23 * d10 + self.m24 * d9) * inverse_det,
                    (self.m13 * d10 - self.m12 * d11 - self.m14 * d9) * inverse_det,
                    (self.m42 * d5 - self.m43 * d4 + self.m44 * d3) * inverse_det,
                    (self.m33 * d4 - self.m32 * d5 - self.m34 * d3) * inverse_det,
                    (self.m23 * d8 - self.m21 * d11 - self.m24 * d7) * inverse_det,
                    (self.m11 * d11 - self.m13 * d8 + self.m14 * d7) * inverse_det,
                    (self.m43 * d2 - self.m41 * d5 - self.m44 * d1) * inverse_det,
                    (self.m31 * d5 - self.m33 * d2 + self.m34 * d1) * inverse_det,
                    (self.m21 * d10 - self.m22 * d8 + self.m24 * d6) * inverse_det,
                    (self.m12 * d8 - self.m11 * d10 - self.m14 * d6) * inverse_det,
                    (self.m41 * d4 - self.m42 * d2 + self.m44 * d0) * inverse_det,
                    (self.m32 * d2 - self.m31 * d4 - self.m34 * d0) * inverse_det,
                    (self.m22 * d7 - self.m21 * d9 - self.m23 * d6) * inverse_det,
                    (self.m11 * d9 - self.m12 * d7 + self.m13 * d6) * inverse_det,
                    (self.m42 * d1 - self.m41 * d3 - self.m43 * d0) * inverse_det,
                    (self.m31 * d3 - self.m32 * d1 + self.m33 * d0) * inverse_det,
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
