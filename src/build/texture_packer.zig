const std = @import("std");
const math = @import("../engine/math/main.zig");
const Rect = math.rect;
const uint2 = math.uint2;

pub fn Packer(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        max_size: u32,
        nodes: std.ArrayList(Node),
        items: std.ArrayList(Item),


        pub fn init(allocator: std.mem.Allocator, comptime options: PackerOptions) @This() {
            return .{
                .allocator = allocator,
                .max_size = options.max_size,
                .nodes = std.ArrayList(Node).init(allocator),
                .items = std.ArrayList(Item).init(allocator)
            };
        }

        pub fn add(self: *@This(), item: Item) !void {
            try self.items.append(item);
        }

        fn sortItem() fn (void, Item, Item) bool {
            // sort it from smallest to largest
            return struct {
                pub fn inner(_: void, a: Item, b: Item) bool {
                    const sizeA = a.getTotalSize();
                    const sizeB = b.getTotalSize();

                    return sizeA > sizeB;
                }
            }.inner;
        }

        fn findNode(self: @This(), node_id: u32, width: u32, height: u32, score: *Score) u32 {
            const node = self.nodes.items[node_id];
            if (width > node.rect.width or height > node.rect.height) {
                score.* = Score.worst();
                return std.math.maxInt(u32);
            }

            if (node.nodes) |childs| {
                var contesting_node: u32 = std.math.maxInt(u32);
                var contesting_score = Score.worst();

                for (childs) |n| {
                    if (n <= 0) {
                        continue;
                    }

                    var other_score: Score = undefined;
                    const other_n = self.findNode(n, width, height, &other_score);
                    if (other_score.isBetterThan(contesting_score)) {
                        contesting_score = other_score;
                        contesting_node = other_n;
                    }
                }

                score.* = contesting_score;
                return contesting_node;
            }

            score.* = Score.init(node.rect, width, height);
            return node_id;
        }

        fn hasRect(self: @This(), node_id: u32, rect: Rect) bool {
            const node = self.nodes.items[node_id];
            // check if the node rect contains this
            if (!node.rect.contains(rect)) {
                return false;
            }

            // if it does, we check of each child 
            if (node.nodes) |childs| {
                for (childs) |child| {
                    if (child > 0 and self.hasRect(child, rect)) {
                        return true;
                    }
                }
            } else {
                // if its a leaf, then we can simply say it does contains it
                return true;
            }

            return false;
        }

        fn splitNode(self: *@This(), node_id: u32, rect: Rect) !void {
            // we don't want to take a reference because the memory address will change
            // upon append, because it will reallocate memory when needed
            var node = self.nodes.items[node_id];

            if (!node.rect.intersects(rect)) {
                return;
            }

            if (node.nodes) |childs| {
                for (childs) |child| {
                    if (child > 0) {
                        try self.splitNode(child, rect);
                    }
                }

                return;
            }

            node.nodes = [4]u32 {
                0, 0, 0, 0 
            };
            self.nodes.items[node_id] = node;

            // check the sides of the node if the new rect can possibly be fit inside
            // sides in order: left, right, top, bottom
            const new_rect1 = Rect.init(node.rect.x, node.rect.y, rect.x - node.rect.x, node.rect.height);
            if (rect.x > node.rect.x and !self.hasRect(0, new_rect1)) {
                node.nodes.?[0] = @intCast(self.nodes.items.len);
                try self.nodes.append(.{ .rect = new_rect1 });
            }

            const new_rect2 = Rect.init(rect.right(), node.rect.y, node.rect.right() - rect.right(), node.rect.height);
            if (rect.right() < node.rect.right() and !self.hasRect(0, new_rect2)) {
                node.nodes.?[1] = @intCast(self.nodes.items.len);
                try self.nodes.append(.{ .rect = new_rect2 });
            }

            const new_rect3 = Rect.init(node.rect.x, node.rect.y, node.rect.width, rect.y - node.rect.y);
            if (rect.y > node.rect.y and !self.hasRect(0, new_rect3)) {
                node.nodes.?[2] = @intCast(self.nodes.items.len);
                try self.nodes.append(.{ .rect = new_rect3 });
            }

            const new_rect4 = Rect.init(node.rect.x, rect.bottom(), node.rect.width, node.rect.bottom() - rect.bottom());
            if (rect.bottom() < node.rect.bottom() and !self.hasRect(0, new_rect4)) {
                node.nodes.?[3] = @intCast(self.nodes.items.len);
                try self.nodes.append(.{ .rect = new_rect4 });
            }

            self.nodes.items[node_id] = node;
        }

        pub fn pack(self: *@This()) !Result {
            var packed_items = std.ArrayList(PackedItem).init(self.allocator);
            const result = done: {

                if (self.items.items.len == 0) {
                    break :done false;
                }

                if (self.items.items.len == 1) {
                    const item = self.items.items[0];
                    try packed_items.append(.{ .rect = Rect.init(0, 0, @intCast(item.width), @intCast(item.height)), .data = item.data });
                    return .{
                        .ok = true,
                        .packed_items = packed_items,
                        .size = uint2.new(item.width, item.height)
                    };
                }
                const slice = try self.items.toOwnedSlice();
                defer self.allocator.free(slice);

                std.mem.sort(Item, slice, {}, sortItem());

                var sum: u32 = 0;
                for (slice) |item| sum += item.width * item.height;
                

                var page_size: u32 = 2;
                while (page_size * page_size * 2 < sum) {
                    page_size *= 2;
                }

                const sizes: [3]uint2 = [3]uint2 {
                    .{ .x = page_size, .y = page_size },
                    .{ .x = page_size * 2, .y = page_size },
                    .{ .x = page_size, .y = page_size * 2 },
                };

                while (page_size <= self.max_size) {
                    for (sizes) |size| {
                        if (size.x > self.max_size or 
                            size.y > self.max_size or
                            size.x * size.y < sum) { continue; }
                        self.nodes.clearRetainingCapacity();
                        
                        try self.nodes.append(.{ 
                            .rect = .{ .x = 0, .y = 0, .width = @intCast(size.x), .height = @intCast(size.y) },
                        });

                        for (0..slice.len) |i| {
                            const item = slice[i];
                            const iwidth: i32 = @intCast(item.width);
                            const iheight: i32 = @intCast(item.height);

                            var score: Score = undefined;
                            const node_id = self.findNode(0, item.width, item.height, &score);

                            if (node_id == std.math.maxInt(u32)) {
                                // we had to retry packing or abort when there's no best possible node to put
                                continue;
                            }

                            const node = self.nodes.items[node_id];
                            const rect = Rect.init(node.rect.x, node.rect.y, iwidth, iheight);

                            try self.splitNode(0, rect);
                            try packed_items.append(.{ .rect = rect, .data = item.data });
                        }

                        break :done true;
                    }
                }

                break :done false;
            };

            if (!result) {
                return .{
                    .ok = false,
                    .packed_items = packed_items,
                    .size = uint2.new(0, 0)
                };
            }

            const root = self.nodes.items[0];

            const page_width: u32 = @intCast(root.rect.width);
            const page_height: u32 = @intCast(root.rect.height);

            const size = uint2.new(page_width, page_height);

            self.nodes.clearRetainingCapacity();
            self.items.clearRetainingCapacity();

            return .{
                .ok = true,
                .packed_items = packed_items,
                .size = size
            };
        }

        pub fn deinit(self: @This()) void {
            self.items.deinit();
            self.nodes.deinit();
        }

        pub const Result = struct {
            ok: bool,
            packed_items: std.ArrayList(PackedItem),
            size: uint2,

            pub fn deinit(self: @This()) void {
                self.packed_items.deinit();
            }
        };

        pub const Item = struct {
            data: T,
            width: u32,
            height: u32,

            pub fn getTotalSize(self: Item) u32 {
                const area = self.width * self.height;
                const largest_area = @max(self.width, self.height);
                return area + largest_area;
            }
        };

        pub const PackedItem = struct {
            rect: Rect,
            data: T,
        };
    };
}


pub const PackerOptions = struct {
    max_size: u32 = 8192
};

const Score = struct {
    s1: u32,
    s2: u32,

    pub fn init(rect: Rect, width: u32, height: u32) Score {
        return .{
            .s1 = (@as(u32, @intCast(rect.width * rect.height))) - width * height,
            .s2 = @min(@as(u32, @intCast(rect.width)) - width, @as(u32, @intCast(rect.height)) - height)
        };
    }

    pub inline fn worst() Score {
        return .{ .s1 = std.math.maxInt(u32), .s2 = std.math.maxInt(u32) };
    }

    pub inline fn isBetterThan(self: Score, other: Score) bool {
        return self.s1 < other.s1 or (self.s1 == other.s1 and self.s2 < other.s2);
    }
};

const Node = struct {
    rect: Rect,
    nodes: ?[4]u32 = null
};

test "texture_packer" {
    const fs = std.fs;
    const Image = @import("../engine/graphics/main.zig").Image;
    const expect = @import("std").testing.expect;
    var packer = Packer(Image).init(std.testing.allocator, .{});
    defer packer.deinit();

    var dir = try fs.cwd().openDir("assets/textures", .{ .iterate = true });
    var walker = try dir.walk(std.testing.allocator);
    defer walker.deinit();

    var images = std.ArrayList(Image).init(std.testing.allocator);
    defer images.deinit();

    defer {
        for (images.items) |image| {
            image.deinit();
        }    
    }

    while (try walker.next()) |entry| {
        const source = try std.fs.path.join(std.testing.allocator, &[_][]const u8 { "assets/textures", entry.path });
        defer std.testing.allocator.free(source);
        try images.append(try Image.loadImage(std.testing.allocator, source));
    }

    for (images.items) |image| {
        try packer.add(.{ .width = image.width, .height = image.height, .data = image });
    }


    var result = try packer.pack();
    defer result.packed_items.deinit();
    try expect(result.ok);

    var atlas_image = try Image.init(std.testing.allocator, result.size.x, result.size.y, null);
    defer atlas_image.deinit();
    for (result.packed_items.items) |n| {
        atlas_image.copyFromImage(n.data, @intCast(n.rect.x), @intCast(n.rect.y));
    }
    atlas_image.save("result.png");
}