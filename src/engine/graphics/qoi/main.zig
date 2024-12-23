const std = @import("std");
const Allocator = std.mem.Allocator;

const ColorChannel = u8;
pub const Error = error {
    DimensionIsZero,
    ChannelsHigherThanFour,
    ChannelsLowerThanThree,
    MaximumSizeReached,
    InvalidMagic,
    TooLow
} || Allocator.Error;

pub const header_size = 14;
pub const magic = @as(u32, @intCast('q')) << 24 |
                  @as(u32, @intCast('o')) << 16 |
                  @as(u32, @intCast('i')) << 8 |
                  @as(u32, @intCast('f'));

pub const max_pixels: u32 = 400000000; // 2GB

pub const Colorspace = enum(u8) {
    SRGB,
    Linear
};

pub const ImageDescription = struct {
    width: u32,
    height: u32,
    channels: ColorChannel,
    colorspace: Colorspace
};

const OP = struct {
    index: u8,
    diff: u8,
    luma: u8,
    run: u8,
    rgb: u8,
    rgba: u8
};

const op: OP = .{
    .index = 0x00,
    .diff = 0x40,
    .luma = 0x80,
    .run = 0xc0,
    .rgb = 0xfe,
    .rgba = 0xff
};

const mask2 = 0xc0;

const RGBA = packed struct {
    r: u8, g: u8, b: u8, a: u8,
    pub inline fn cmp(self: RGBA, other: RGBA) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a;
    }
};

const padding = [8]u8 { 0, 0, 0, 0, 0, 0, 0, 1 };

fn colorHash(r: RGBA) usize {
    const red: usize = @as(u32, @intCast(r.r)) * 3;
    const green: usize = @as(u32, @intCast(r.g)) * 5;
    const blue: usize = @as(u32, @intCast(r.b)) * 7;
    const alpha: usize = @as(u32, @intCast(r.a)) * 11;
    return red + green + blue + alpha;
}

inline fn write32(bytes: []u8, p: *usize, rgba: u32) void {
    bytes[p.*] = @intCast((0xff000000 & rgba) >> 24);
    p.* += 1;
    bytes[p.*] = @intCast((0x00ff0000 & rgba) >> 16);
    p.* += 1;
    bytes[p.*] = @intCast((0x0000ff00 & rgba) >> 8);
    p.* += 1;
    bytes[p.*] = @intCast(0x000000ff & rgba);
    p.* += 1;
}

inline fn read32(bytes: []const u8, p: *usize) u32 {
    const r: u32 = @intCast(bytes[p.*]);
    p.* += 1;
    const g: u32 = @intCast(bytes[p.*]);
    p.* += 1;
    const b: u32 = @intCast(bytes[p.*]);
    p.* += 1;
    const a: u32 = @intCast(bytes[p.*]);
    p.* += 1;

    return r << 24 | g << 16 | b << 8 | a;
}

pub fn encode(allocator: Allocator, data: []const u8, desc: *const ImageDescription, len: *usize) Error![]u8 {
    if (desc.width == 0 or desc.height == 0) {
        return Error.DimensionIsZero;    
    }
    if (desc.channels < 3) {
        return Error.ChannelsLowerThanThree;
    }
    if (desc.channels > 4) {
        return Error.ChannelsHigherThanFour;
    }
    if (desc.height >= max_pixels / desc.width) {
        return Error.MaximumSizeReached;
    }

    var index: [64]RGBA = [_]RGBA {.{ .r = 0, .g = 0, .b = 0, .a = 0 }} ** 64;

    const max_size = desc.width * desc.height * (desc.channels + 1) + header_size + padding.len;
    var p: usize = 0;
    const bytes = try allocator.alloc(u8, @intCast(max_size));

    @memset(bytes, 0);

    write32(bytes, &p, magic);
    write32(bytes, &p, desc.width);
    write32(bytes, &p, desc.height);
    bytes[p] = desc.channels;
    p += 1;
    bytes[p] = @intFromEnum(desc.colorspace);
    p += 1;

    const pixels = data;

    var run: u32 = 0;
    var px: RGBA = undefined;
    var px_prev: RGBA = undefined;
    px_prev.r = 0;
    px_prev.g = 0;
    px_prev.b = 0;
    px_prev.a = 255;
    px = px_prev;
    const px_len = desc.width * desc.height * desc.channels;
    const px_end = px_len - desc.channels;
    const channels = desc.channels;

    var px_pos: usize = 0;
    while (px_pos < px_len) {
        px.r = pixels[px_pos + 0];
        px.g = pixels[px_pos + 1];
        px.b = pixels[px_pos + 2];

        if (channels == 4) {
            px.a = pixels[px_pos + 3];
        }

        if (px.cmp(px_prev)) {
            run += 1;
            if (run == 62 or px_pos == px_end) {
                bytes[p] = @intCast(op.run | (run - 1));
                p += 1;
                run = 0;
            }
        } else {
            var index_pos: usize = 0;

            if (run > 0) {
                bytes[p] = @intCast(op.run | (run - 1));
                p += 1;
                run = 0;
            }

            index_pos = colorHash(px) % 64;
            if (index[index_pos].cmp(px)) {
                bytes[p] = @intCast(op.index | index_pos);
                p += 1;
            } else {
                index[index_pos] = px;

                if (px.a == px_prev.a) {
                    const vr: i8 = @bitCast(px.r -% px_prev.r);
                    const vg: i8 = @bitCast(px.g -% px_prev.g);
                    const vb: i8 = @bitCast(px.b -% px_prev.b);

                    const vg_r: i8 = vr -% vg;
                    const vg_b: i8 = vb -% vg;

                    if (vr > -3 and vr < 2 and 
                        vg > -3 and vg < 2 and 
                        vb > -3 and vb < 2) {
                        bytes[p] = op.diff | @as(u8, @bitCast((vr + 2) << 4)) | @as(u8, @bitCast((vg + 2) << 2)) | @as(u8, @bitCast(vb + 2));
                        p += 1;
                    } else if (vg_r > -9 and vg_r < 8 and vg > -33 and vg < 32 and vg_b > -9 and vg_b < 8) {
                        bytes[p] = op.luma | @as(u8, @bitCast(vg + 32));
                        p += 1;
                        bytes[p] = @as(u8, @bitCast((vg_r + 8) << 4)) | @as(u8, @bitCast(vg_b + 8));
                        p += 1;
                    } else {
                        bytes[p] = @intCast(op.rgb);
                        p += 1;
                        bytes[p] = px.r;
                        p += 1;
                        bytes[p] = px.g;
                        p += 1;
                        bytes[p] = px.b;
                        p += 1;
                    }
                } else {
                    bytes[p] = @intCast(op.rgba);
                    p += 1;
                    bytes[p] = px.r;
                    p += 1;
                    bytes[p] = px.g;
                    p += 1;
                    bytes[p] = px.b;
                    p += 1;
                    bytes[p] = px.a;
                    p += 1;
                }
            }
        }

        px_prev = px;
        px_pos += channels;
    }

    inline for (0..padding.len) |i| {
        bytes[p] = padding[i];
        p += 1;
    }

    len.* = p;
    return bytes;
}

pub fn decode(allocator: Allocator, data: []const u8, size: u32, desc: *ImageDescription, channels: ColorChannel) Error![]u8 {
    if (channels < 3) {
        return Error.ChannelsLowerThanThree;
    }
    if (channels > 4) {
        return Error.ChannelsHigherThanFour;
    }
    if (size < header_size + padding.len) {
        return Error.TooLow;
    }

    var p: usize = 0;
    const bytes = data;
    const header_magic = read32(bytes, &p);
    desc.width = read32(bytes, &p);
    desc.height = read32(bytes, &p);
    desc.channels = bytes[p];
    p += 1;
    desc.colorspace = @enumFromInt(bytes[p]);
    p += 1;

    if (desc.width == 0 or desc.height == 0) {
        return Error.DimensionIsZero;    
    }
    if (desc.channels < 3) {
        return Error.ChannelsLowerThanThree;
    }
    if (desc.channels > 4) {
        return Error.ChannelsHigherThanFour;
    }
    if (desc.height >= max_pixels / desc.width) {
        return Error.MaximumSizeReached;
    }
    if (header_magic != magic) {
        return Error.InvalidMagic;
    }

    var index: [64]RGBA = [_]RGBA {.{ .r = 0, .g = 0, .b = 0, .a = 0 }} ** 64;

    const ch = if (channels == 0) 
        desc.channels
    else 
        channels;

    const px_len = desc.width * desc.height * ch;

    const pixels = try allocator.alloc(u8, px_len);
    @memset(pixels, 0);
    
    var run: u32 = 0;
    var px: RGBA = undefined;
    px.r = 0;
    px.g = 0;
    px.b = 0;
    px.a = 255;

    const chunks_len = size - padding.len;
    var px_pos: usize = 0;
    while (px_pos < px_len) {
        if (run > 0) {
            run -= 1;
        } else if (p < chunks_len) {
            const b1 = bytes[p];
            p += 1;

            if (b1 == op.rgb) {
                px.r = bytes[p];
                p += 1;
                px.g = bytes[p];
                p += 1;
                px.b = bytes[p];
                p += 1;
            } else if (b1 == op.rgba) {
                px.r = bytes[p];
                p += 1;
                px.g = bytes[p];
                p += 1;
                px.b = bytes[p];
                p += 1;
                px.a = bytes[p];
                p += 1;
            } else if ((b1 & mask2) == op.index) {
                px = index[b1];
            } else if ((b1 & mask2) == op.diff) {
                px.r +%= ((b1 >> 4) & 0x03) -% 2;
                px.g +%= ((b1 >> 2) & 0x03) -% 2;
                px.b +%= (b1 & 0x03) -% 2;
            } else if ((b1 & mask2) == op.luma) {
                const b2 = bytes[p];
                p += 1;
                const vg = (b1 & 0x3f) -% 32;
                px.r +%= vg - 8 + ((b2 >> 4) & 0x0f);
                px.g +%= vg;
                px.b +%= vg - 8 + (b2 & 0x0f);
            } else if ((b1 & mask2) == op.run) {
                run = (b1 & 0x3f);
            }

            index[colorHash(px) % 64] = px;
        }

        pixels[px_pos] = px.r;
        pixels[px_pos + 1] = px.g;
        pixels[px_pos + 2] = px.b;

        if (channels == 4) {
            pixels[px_pos + 3] = px.a;
        }

        px_pos += ch;
    }

    return pixels;
}