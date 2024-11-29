const Mouse = @This();
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const MouseButtonCode = @import("../enums.zig").MouseButtonCode;

any_pressed: bool = false,
x: f32 = 0,
y: f32 = 0,
delta_x: f32 = 0,
delta_y: f32 = 0,
wheel_x: i32 = 0,
wheel_y: i32 = 0,
wheel_x_raw: i32 = 0,
wheel_y_raw: i32 = 0,
prev_wheel_x_raw: i32 = 0,
prev_wheel_y_raw: i32 = 0,
mouse_buttons: [5]Button,

pub fn init() Mouse {
    var buttons: [5]Button = undefined;   

    buttons[0] = Button.init(.Left, sdl.SDL_BUTTON_LMASK);
    buttons[1] = Button.init(.Middle, sdl.SDL_BUTTON_MMASK);
    buttons[2] = Button.init(.Right, sdl.SDL_BUTTON_RMASK);
    buttons[3] = Button.init(.X1, sdl.SDL_BUTTON_X1MASK);
    buttons[4] = Button.init(.X2, sdl.SDL_BUTTON_X2MASK);

    return .{
        .mouse_buttons = buttons
    };
}

pub fn update(self: *Mouse) void {
    var x: f32 = undefined;
    var y: f32 = undefined;
    const button_mask = sdl.SDL_GetMouseState(&x, &y);
    var delta_x: f32 = undefined;
    var delta_y: f32 = undefined;
    _ = sdl.SDL_GetRelativeMouseState(&delta_x, &delta_y);

    self.x = x;
    self.y = y;
    self.delta_x = delta_x;
    self.delta_y = delta_y;

    self.wheel_x = self.wheel_x_raw - self.prev_wheel_x_raw;
    self.prev_wheel_x_raw = self.wheel_x_raw;

    self.wheel_y = self.wheel_y_raw - self.prev_wheel_y_raw;
    self.prev_wheel_y_raw = self.wheel_y_raw;

    inline for (0..self.mouse_buttons.len) |i| {
        var button = &self.mouse_buttons[i];
        button.update(button_mask);

        if (button.pressed()) {
            self.any_pressed = true;
        }
    }
}

pub fn hide() void {
    _ = sdl.SDL_HideCursor();
}

pub fn show() void {
    _ = sdl.SDL_ShowCursor();
}

pub fn leftButton(self: Mouse) Button {
    return self.mouse_buttons[0];
}

pub fn middleButton(self: Mouse) Button {
    return self.mouse_buttons[1];
}

pub fn rightButton(self: Mouse) Button {
    return self.mouse_buttons[2];
}

pub fn x1Button(self: Mouse) Button {
    return self.mouse_buttons[3];
}

pub fn x2Button(self: Mouse) Button {
    return self.mouse_buttons[4];
}

pub const Button = struct {
    status: Status,
    mouse_code: MouseButtonCode,
    flags: u32,
    pub fn init(mouse_code: MouseButtonCode, mask: u32) Button {
        return .{
            .mouse_code = mouse_code,
            .flags = mask,
            .status = Status.Idle
        };
    }

    pub fn update(self: *Button, key: u32) void {
        const is_key_pressed = (key & self.flags) != 0;

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