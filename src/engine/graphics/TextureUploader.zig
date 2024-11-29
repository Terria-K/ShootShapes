const TextureUploader = @This();
const std = @import("std");
const TransferBuffer = @import("TransferBuffer.zig");
const GraphicsDevice = @import("GraphicsDevice.zig");
const TextureRegion = @import("../structs/main.zig").TextureRegion;
const Image = @import("Image.zig");
const Texture = @import("Texture.zig");

transfer_buffer: TransferBuffer,
allocator: std.mem.Allocator,
texture_uploads: std.ArrayList(TextureUploads),
buffer: ?*anyopaque,
offset: usize,
device: GraphicsDevice,

pub fn init(allocator: std.mem.Allocator, device: GraphicsDevice, info: TextureUploaderInfo) TextureUploader {
    var transfer_buffer = TransferBuffer.initUnknown(device, info.max_size, .{ .upload = true });

    const buffer = transfer_buffer.mapUnknown(true);

    return .{
        .transfer_buffer = transfer_buffer,
        .buffer = buffer,
        .allocator = allocator,
        .texture_uploads = std.ArrayList(TextureUploads).init(allocator),
        .offset = 0,
        .device = device 
    };
}

pub fn createTextureFromImage(self: *TextureUploader, image: Image) !Texture {
    const texture = Texture.init(self.device, image.width, image.height, .R8G8B8A8_UNORM);
    const len = image.data.len;
    const ptr = image.data.ptr;
    const offset = self.copyTextureToTransferBuffer(ptr, len, 16); 
    try self.texture_uploads.append(.{ .offset = offset, .texture = texture.toRegion() });

    return texture;
}

pub inline fn upload(self: *TextureUploader) void {
    self.transfer_buffer.unmap();
    uploadInternal(self);
}

fn uploadInternal(self: *TextureUploader) void {
    const cmd_buffer = self.device.acquireCommandBuffer();
    const copy_pass = cmd_buffer.beginCopyPass();
    for (self.texture_uploads.items) |u| {
        copy_pass.uploadToSlicedTexture(
            .{ .transfer_buffer = self.transfer_buffer, .offset = @intCast(u.offset) }, 
            u.texture, 
            true);
    }
    copy_pass.end();
    cmd_buffer.submit();

    self.texture_uploads.clearRetainingCapacity();
    self.offset = 0;
}

fn copyTextureToTransferBuffer(self: *TextureUploader, ptr: [*]u8, length: usize, alignment: u32) usize {
    self.offset = alignment * ((self.offset + alignment - 1) / alignment);

    if (length > self.transfer_buffer.size) {
        self.resize(@intCast(length));
    }

    if (self.offset + length >= self.transfer_buffer.size) {
        self.transfer_buffer.unmap();
        self.uploadInternal();
        self.buffer = self.transfer_buffer.mapUnknown(true);
    }

    const offset = self.offset;
    @memcpy(@as([*]u8, @ptrCast(@alignCast(self.buffer)))[self.offset..(self.offset + length)], ptr[0..length]);
    self.offset += length;

    return offset;
}

fn resize(self: *TextureUploader, size: u32) void {
    self.transfer_buffer.unmap();
    self.uploadInternal();
    self.transfer_buffer.deinit(self.device);
    self.transfer_buffer = TransferBuffer.initUnknown(self.device, size, .{ .upload = true });
    self.buffer = self.transfer_buffer.mapUnknown(true);
}

pub fn deinit(self: TextureUploader, device: GraphicsDevice) void {
    self.texture_uploads.deinit();
    device.release(self.transfer_buffer);
}

pub const TextureUploaderInfo = struct { max_size: u32 = 4096 };
const TextureUploads = struct {
    texture: TextureRegion,
    offset: usize,

    pub fn init(texture: TextureRegion, offset: u32) TextureUploads {
        return .{
            .texture = texture,
            .offset = offset
        };
    }
};