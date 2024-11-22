const std = @import("std");


pub inline fn fromSeconds(value: f64) u64 {
    return fromInterval(value, std.time.ms_per_s);
}

pub inline fn fromInterval(value: f64, scale: i32) u64 {
    const tmp = value * scale;
    var millis: f64 = 0;
    if (value >= 0) {
        millis = tmp + 0.5;
    } else {
        millis = tmp - 0.5;
    }

    return @intFromFloat(millis * std.time.ns_per_ms);
}