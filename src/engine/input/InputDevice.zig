const InputDevice = @This();
const Keyboard = @import("Keyboard.zig");
keyboard: Keyboard,
disabled: bool,
pub fn init() InputDevice {
    const keyboard = Keyboard.init();
    return .{
        .keyboard = keyboard,
        .disabled = false
    };
}

pub fn update(self: *InputDevice) void {
    if (self.disabled) {
        return;
    }

    Keyboard.update(&self.keyboard);
}