const Image = @This();
const Rect = @import("../math/main.zig").rect;
const int2 = @import("../math/main.zig").int2;
const Color = @import("../graphics/main.zig").Color;
const stb_image = @cImport(@cInclude("stb_image.h"));

const stb_image_write = @cImport(@cInclude("stb_image_write.h"));
const std = @import("std");

pub const Error = error {
    imageNotFound
};

width: u32,
height: u32,
allocator: std.mem.Allocator,
data: []u8,

pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, comptime fill: ?u8) std.mem.Allocator.Error!Image {
    const len = width * height * 4;
    var data = try allocator.alloc(u8, len);
    if (fill) |f| {
        var i: usize = 0;
        while (i < len) {
            data[i] = f;
            data[i + 1] = f;
            data[i + 2] = f;
            data[i + 3] = 255;
            i += 4;
        }
    } else {
        var i: usize = 0;
        while (i < len) {
            data[i] = 0;
            data[i + 1] = 0;
            data[i + 2] = 0;
            data[i + 3] = 0;
            i += 4;
        }
    }

    return .{ .allocator = allocator, .width = width, .height = height, .data = data };
}

pub fn loadImage(allocator: std.mem.Allocator, path: []const u8) (Error || std.mem.Allocator.Error)!Image {
    const file = std.fs.cwd().openFile(path, .{}) catch {
        return Error.imageNotFound;
    };
    defer file.close();
    const len = file.getEndPos() catch {
        unreachable;
    };

    const buffer = try allocator.alloc(u8, len);
    defer allocator.free(buffer);
    _ = file.readAll(buffer) catch {
        unreachable;
    };
    var x: c_int = undefined;
    var y: c_int = undefined;
    var channels_in_file: c_int = undefined;
    const data = stb_image.stbi_load_from_memory(@ptrCast(buffer), @intCast(len), &x, &y, &channels_in_file, 4);
    defer std.c.free(data);
    const actual_data = try allocator.dupe(u8, data[0..@intCast(x * y * channels_in_file)]);

    const image: Image = .{ .width = @intCast(x), .height = @intCast(y), .data = actual_data, .allocator = allocator };

    return image;
}

pub fn copyFromPixels(self: *Image, pixels: []u8, x: u32, y: u32, src_width: u32, src_height: u32) void {
    const width: i32 = @intCast(src_width);
    const height: i32 = @intCast(src_height);
    const dest = Rect.init(@intCast(x), @intCast(y), width, height);

    const overlaps = Rect.init(0, 0, @intCast(self.width), @intCast(self.height)).overlap(dest);

    if (overlaps.width <= 0 or overlaps.height <= 0) {
        return;
    }

    const pixel = int2.new(overlaps.x - dest.x, overlaps.y - dest.y);
    const size: usize = @intCast(overlaps.width * 4);

    for (0..@intCast(overlaps.height)) |yh| {
        const stride = yh;
        const pix_x = @as(usize, @intCast(pixel.x));
        const pix_y = @as(usize, @intCast(pixel.y));

        const over_x = @as(usize, @intCast(overlaps.x));
        const over_y = @as(usize, @intCast(overlaps.y));
        const start_src = ((pix_y + stride) * @as(usize, @intCast(width)) + pix_x) * 4;
        const start_dest = ((over_y + stride) * @as(usize, @intCast(self.width)) + over_x) * 4;
        const src_ptr = pixels.ptr[start_src .. start_src + size];
        const dest_ptr = self.data.ptr[start_dest .. start_dest + size];

        @memcpy(dest_ptr, src_ptr);
    }
}

pub fn copyFromImage(self: *Image, image: Image, x: u32, y: u32) void {
    self.copyFromPixels(image.data, x, y, image.width, image.height);
}

pub fn save(self: Image, path: []const u8) void {
    _ = stb_image_write.stbi_write_png(@ptrCast(path), @intCast(self.width), @intCast(self.height), 4, @ptrCast(self.data), @intCast(self.width * 4));
}

pub fn deinit(self: Image) void {
    self.allocator.free(self.data);
}
