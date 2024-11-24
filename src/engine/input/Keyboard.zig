const Keyboard = @This();
const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const Keycode = @import("../enums/main.zig").KeyCode;
const Trigger = [*c]const bool;

any_pressed: bool,
buttons: [255]Button,

pub fn init() Keyboard {
    var num_keys: c_int = undefined;
    _ = sdl.SDL_GetKeyboardState(&num_keys); 


    const keycodes = std.meta.fields(Keycode);
    var buttons: [255]Button = undefined;

    inline for (keycodes) |keycode| {
        buttons[keycode.value] = Button.new(@enumFromInt(keycode.value));
    }

    const keyboard: Keyboard = .{
        .any_pressed = false,
        .buttons = buttons
    };

    return keyboard;
}

pub fn update(self: *Keyboard) void {
    self.any_pressed = false;
    var num_keys: c_int = undefined;
    const state = sdl.SDL_GetKeyboardState(&num_keys); 

    const keycodes = std.meta.fields(Keycode);
    inline for (keycodes) |keycode| {
        var keyboard_button = &self.buttons[keycode.value];
        keyboard_button.update(state);

        if (keyboard_button.pressed()) {
            self.any_pressed = true;
        }
    }
}

inline fn boolCastToI32(b: bool) i32 {
    return @as(i32, @intFromBool(b));
}

pub fn axis(self: Keyboard, left: Keycode, right: Keycode) i32 {
    const left_button = self.buttons[@intCast(@intFromEnum(left))];
    const right_button = self.buttons[@intCast(@intFromEnum(right))];

    return (-@as(i32, boolCastToI32(left_button.isHeld()))) + @as(i32, boolCastToI32(right_button.isHeld()));
}

pub fn axisF(self: Keyboard, left: Keycode, right: Keycode) f32 {
    const left_button = self.buttons[@intCast(@intFromEnum(left))];
    const right_button = self.buttons[@intCast(@intFromEnum(right))];

    return (-@as(f32, @floatFromInt(boolCastToI32(left_button.isHeld())))) + @as(f32, @floatFromInt(boolCastToI32(right_button.isHeld())));
}

pub fn pressedAxisF(self: Keyboard, left: Keycode, right: Keycode) f32 {
    const left_button = self.buttons[@intCast(@intFromEnum(left))];
    const right_button = self.buttons[@intCast(@intFromEnum(right))];

    return (-@as(f32, @floatFromInt(boolCastToI32(left_button.pressed())))) + @as(f32, @floatFromInt(boolCastToI32(right_button.pressed())));
}

pub fn isPressed(self: Keyboard, code: Keycode) bool {
    const button = self.buttons[@intCast(@intFromEnum(code))];
    return button.pressed();
}

pub fn isReleased(self: Keyboard, code: Keycode) bool {
    const button = self.buttons[@intCast(@intFromEnum(code))];
    return button.isReleased();
}

pub fn isHeld(self: Keyboard, code: Keycode) bool {
    const button = self.buttons[@intCast(@intFromEnum(code))];
    return button.isHeld();
}

pub fn isDown(self: Keyboard, code: Keycode) bool {
    const button = self.buttons[@intCast(@intFromEnum(code))];
    return button.isDown();
}

pub fn isUp(self: Keyboard, code: Keycode) bool {
    const button = self.buttons[@intCast(@intFromEnum(code))];
    return button.isUp();
}

pub fn isIdle(self: Keyboard, code: Keycode) bool {
    const button = self.buttons[@intCast(@intFromEnum(code))];
    return button.isIdle();
}

pub const Button = struct {
    keycode: Keycode,
    status: Status,
    pub fn new(keycode: Keycode) Button {
        return .{
            .keycode = keycode,
            .status = Status.Idle
        };
    }

    pub fn update(self: *Button, key: Trigger) void {
        const is_key_pressed = key[@intCast(@intFromEnum(self.*.keycode))];

        if (is_key_pressed) {
            if (self.isUp()) {
                self.status = Status.Pressed;
            } else {
                self.status = Status.Held;
            }
        } else if (self.isDown()) {
            self.status = Status.Released;
        } else {
            self.status = Status.Idle;
        }
    }

    pub fn pressed(self: Button) bool {
        return self.status == Status.Pressed;
    }

    pub fn isDown(self: Button) bool {
        return self.status == Status.Pressed or self.status == Status.Held;
    }

    pub fn isHeld(self: Button) bool {
        return self.status == Status.Held;
    }

    pub fn isReleased(self: Button) bool {
        return self.status == Status.Released;
    }

    pub fn isUp(self: Button) bool {
        return self.status == Status.Released or self.status == Status.Idle;
    }

    pub fn isIdle(self: Button) bool {
        return self.status == Status.Idle;
    }
};

const Status = enum(u32) {
    Idle,
    Pressed,
    Held,
    Released
};