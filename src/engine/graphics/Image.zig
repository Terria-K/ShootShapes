const Image = @This();
const stb_image = @cImport(@cInclude("stb_image.h"));

const stb_image_write = @cImport(@cInclude("stb_image_write.h"));
const std = @import("std");
width: u32,
height: u32,
allocator: std.mem.Allocator,
data: []u8,

pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, comptime fill: ?u8) !Image {
    const len = width * height * 4;
    var data = try allocator.alloc(u8, len);
    if (fill) |f| {
        var i = 0;
        while (i < len) {
            data[i] = f;
            data[i + 1] = f;
            data[i + 2] = f;
            data[i + 3] = 255;
            i += 4;
        }
    }

    return .{ .allocator = allocator, .width = width, .height = height, .data = data };
}

pub fn loadImage(allocator: std.mem.Allocator, path: []const u8) !Image {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const len = try file.getEndPos();

    const buffer = try allocator.alloc(u8, len);
    defer allocator.free(buffer);
    _ = try file.readAll(buffer);
    var x: c_int = undefined;
    var y: c_int = undefined;
    var channels_in_file: c_int = undefined;
    const data = stb_image.stbi_load_from_memory(@ptrCast(buffer), @intCast(len), &x, &y, &channels_in_file, 4);
    const spanned_data = std.mem.span(data);
    defer std.c.free(data);

    // we wanted the allocated buffer to be tracked by allocator, so we allocate it twice.
    const real_data = try allocator.alloc(u8, spanned_data.len);
    @memcpy(real_data, spanned_data);

    const image: Image = .{ .width = @intCast(x), .height = @intCast(y), .data = real_data, .allocator = allocator };

    return image;
}

pub fn save(self: Image, path: []const u8) void {
    _ = stb_image_write.stbi_write_png(@ptrCast(path), @intCast(self.width), @intCast(self.height), 4, @ptrCast(self.data), @intCast(self.width * 4));
}

pub fn deinit(self: Image) void {
    self.allocator.free(self.data);
}
