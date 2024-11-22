const MultisampleState = @This();
const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const SampleCount = @import("../enums/main.zig").SampleCount;

sample_count: SampleCount = SampleCount.One,
sample_mask: u32 = 0,
enable_mask: bool = false,

pub fn init(sample_count: SampleCount, sample_mask: u32, enable_mask: bool) MultisampleState {
    return .{
        .sample_count = sample_count,
        .sample_mask = sample_mask,
        .enable_mask = enable_mask
    };
}

pub inline fn none() MultisampleState {
    return .{
        .sample_count = SampleCount.One,
        .sample_mask = std.math.maxInt(u32),
        .enable_mask = false
    };
}