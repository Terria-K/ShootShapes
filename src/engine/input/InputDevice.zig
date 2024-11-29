const InputDevice = @This();
const Keyboard = @import("Keyboard.zig");
const Mouse = @import("Mouse.zig");
keyboard: Keyboard,
mouse: Mouse,
disabled: bool,
pub fn init() InputDevice {
    const keyboard = Keyboard.init();
    const mouse = Mouse.init();
    return .{
        .keyboard = keyboard,
        .disabled = false,
        .mouse = mouse
    };
}

pub fn update(self: *InputDevice) void {
    if (self.disabled) {
        return;
    }

    self.keyboard.update();
    self.mouse.update();
}