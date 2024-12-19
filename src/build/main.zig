pub const texture_packer = @import("texture_packer.zig");
const StringBuilder = @import("../engine/StringBuilder.zig");
const Image = @import("../engine/graphics/main.zig").Image;

const std = @import("std");

pub fn createAtlas(target: []const u8) !void {
    const Item = struct {
        name: []u8,
        image: Image,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, name: []const u8, image: Image) std.mem.Allocator.Error!@This() {
            const n = try allocator.alloc(u8, name.len - 4);
            @memcpy(n, name[0..name.len - 4]);
            return .{
                .allocator = allocator,
                .name = n,
                .image = image
            };
        }

        pub fn deinit(self: @This()) void {
            self.allocator.free(self.name);
            self.image.deinit();
        }
    };

    const Packer = texture_packer.Packer(Item);

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const fs = std.fs;
    const expect = @import("std").testing.expect;
    var packer = Packer.init(allocator, .{});
    defer packer.deinit();

    var images = std.ArrayList(Item).init(allocator);
    defer images.deinit();

    defer {
        for (images.items) |item| {
            item.deinit();
        }
    }

    var dir = try fs.cwd().openDir(target, .{ .iterate = true });
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    try walkThru(allocator, target, &struct {
        images: *std.ArrayList(Item),
        allocator: std.mem.Allocator,
        fn call(self: *@This(), path: []const u8, source: []u8) !void {
            const new_path = try self.allocator.alloc(u8, path.len);
            defer self.allocator.free(new_path);
            _ = std.mem.replace(u8, path, "/", "_", new_path);
            try self.images.append(
                try Item.init(
                    self.allocator, 
                    new_path, 
                    try Image.loadImage(self.allocator, source)
                )
            );
        }
    } { .images = &images, .allocator = allocator });


    for (images.items) |item| {
        try packer.add(.{ .width = item.image.width, .height = item.image.height, .data = item });
    }


    var result = try packer.pack();
    defer result.packed_items.deinit();
    try expect(result.ok);

    var atlas_image = try Image.init(allocator, result.size.x, result.size.y, null);
    defer atlas_image.deinit();

    var string_builder = try StringBuilder.init(allocator);
    defer string_builder.deinit();

    try string_builder.append("pub const Texture = .{ \n");
    try string_builder.append("   .__metadata");
    try string_builder.append(" = .{\n");
    try string_builder.append("      .width = ");
    try string_builder.append(result.size.x);
    try string_builder.append(", ");
    try string_builder.append(".height = ");
    try string_builder.append(result.size.y);
    try string_builder.append(", \n");
    try string_builder.append("   },\n");

    for (result.packed_items.items) |n| {
        const t = try std.fmt.allocPrint(allocator, "   .{s} = .{{ .x = {d}, .y = {d}, .width = {d}, .height = {d} }},\n", .{n.data.name, n.rect.x, n.rect.y, n.rect.width, n.rect.height});
        defer allocator.free(t);

        try string_builder.append(t);
        atlas_image.copyFromImage(n.data.image, @intCast(n.rect.x), @intCast(n.rect.y));
    }
    atlas_image.save("assets/result.png");

    try string_builder.append("};");

    const built_str = try string_builder.build();
    defer allocator.free(built_str);

    std.log.warn("{s}", .{built_str});

    const file = try std.fs.cwd().createFile("assets/result.zig", .{});
    defer file.close();
    _ = try file.write(built_str);
}

fn walkThru(allocator: std.mem.Allocator, dir_path: []const u8, caller: anytype) !void {
    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    var walker = try dir.walk(allocator);
    defer walker.deinit();
    var caller_no_const = @constCast(caller);

    while (try walker.next()) |entry| {
        const source = try std.fs.path.join(allocator, &[_][]const u8 { dir_path, entry.path });
        defer allocator.free(source);
        if (entry.kind == .directory) {
            try walkThru(allocator, source, caller);
            continue;
        }
        std.log.warn("{s}", .{entry.path});
        try caller_no_const.call(entry.path, source);
    }
}