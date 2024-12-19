const SpriteBatch = @This();
const ComputePipeline = @import("ComputePipeline.zig");
const CommandBuffer = @import("CommandBuffer.zig");
const std = @import("std");
const GpuBuffer = @import("GpuBuffer.zig");
const TransferBuffer = @import("TransferBuffer.zig");
const GraphicsDevice = @import("GraphicsDevice.zig");
const GraphicsPipeline = @import("GraphicsPipeline.zig");
const TextureQuad = @import("TextureQuad.zig");
const PositionTextureColorConcreteVertex = @import("../vertex/main.zig").PositionTextureColorConcreteVertex;
const UV = @import("main.zig").UV;
const RenderPass = @import("RenderPass.zig");
const Color = @import("main.zig").Color;
const Texture = @import("Texture.zig");
const Sampler = @import("Sampler.zig");
const float2 = @import("../math/main.zig").float2;
const float4 = @import("../math/main.zig").float4;
const float4x4 = @import("../math/main.zig").float4x4;
const structs = @import("../structs/main.zig");

pub const INITIAL_SIZE = 4096;
pub const INITIAL_MAX_QUEUE = 4;

batch_queues: []BatchQueue,
device: GraphicsDevice,
vertex_buffer: GpuBuffer,
index_buffer: GpuBuffer,
comp_buffer: GpuBuffer,
transfer_buffer: TransferBuffer,
allocator: std.mem.Allocator,
rendered: bool = false,
flushed: bool = false,
onQueue: usize = 0,
vertex_index: u32 = 0,
current_max_texture: u32 = 0,
transform: float4x4,
mapped: ?*anyopaque = null,
compute_pipeline: ComputePipeline,

pub fn init(allocator: std.mem.Allocator, device: GraphicsDevice, width: u32, height: u32, pipeline: ComputePipeline) !SpriteBatch {
    const vertices = GpuBuffer.init(
        PositionTextureColorConcreteVertex, 
        device, 
        INITIAL_SIZE, 
        .{ .vertex = true, .compute_storage_read = true , .compute_storage_write = true });
    const computes = GpuBuffer.init(CompData, device, INITIAL_SIZE, .{ .compute_storage_read = true });
    const transfers = TransferBuffer.init(CompData, device, INITIAL_SIZE, .{ .upload = true });
    const indices = generate_index_array(device, INITIAL_SIZE); 
    const batch_queue = try allocator.alloc(BatchQueue, INITIAL_MAX_QUEUE);

    const view = float4x4.createTranslation(0, 0, 0);
    const projection = float4x4.createOrthographicOffCenter(0, @floatFromInt(width), @floatFromInt(height), 0, -1, 1);

    return .{
        .batch_queues = batch_queue,
        .device = device,
        .vertex_buffer = vertices,
        .index_buffer = indices,
        .comp_buffer = computes,
        .transfer_buffer = transfers,
        .allocator = allocator,
        .transform = view.mul(projection),
        .compute_pipeline = pipeline
    };
}

pub fn begin(self: *SpriteBatch, pipeline: GraphicsPipeline, texture: Texture, sampler: Sampler, matrix: ?float4x4) void {
    if (self.rendered) {
        self.vertex_index = 0;
        self.onQueue = 0;
        self.rendered = false;
        self.flushed = false;
    } 

    if (self.batch_queues.len == self.onQueue) {
        _ = self.allocator.realloc(self.batch_queues, self.batch_queues.len + 4) catch {
            @panic("Out of Memory");
        };
    }

    self.batch_queues[self.onQueue] = .{ 
        .count = 0,
        .pipeline = pipeline,
        .matrix = if (matrix) |mat| mat else self.transform,
        .offset = self.vertex_index,
        .binding = .{ .texture = texture, .sampler = sampler }
    };
    self.mapped = self.transfer_buffer.mapUnknown(true);
}

pub fn draw(self: *SpriteBatch, cmd: DrawCommand) void {
    if (self.vertex_index == self.current_max_texture) {
        self.resize_buffer();
    }

    var data = @as([*]CompData, @alignCast(@ptrCast(self.mapped)));
    const index: usize = @intCast(self.vertex_index);
    data[index] = .{
        .position = cmd.position,
        .scale = cmd.scale,
        .origin = cmd.origin,
        .uv = cmd.texture_quad.uv,
        .dimension = float2.new(cmd.texture_quad.source.width, cmd.texture_quad.source.height),
        .rotation = cmd.rotation,
        .depth = cmd.depth,
        .color = cmd.color.toVector4()
    };
    self.vertex_index += 1;
}

pub fn end(self: *SpriteBatch) void {
    self.transfer_buffer.unmap();

    if (self.vertex_index == 0) {
        return;
    }

    const offset = self.batch_queues[self.onQueue].offset;
    self.batch_queues[self.onQueue].count = self.vertex_index - offset;

    self.onQueue += 1;
}

pub fn flush(self: *SpriteBatch) void {
    self.flushed = true;
    const cmd_buf = self.device.acquireCommandBuffer();
    const copy_pass = cmd_buf.beginCopyPass();
    copy_pass.uploadToBuffer(self.transfer_buffer, self.comp_buffer, true);
    copy_pass.end();

    const workgroup_size = (self.vertex_index + 64 - 1) / 64;
    const compute_pass = cmd_buf.beginSingleBufferComputePass(.{ .buffer = self.vertex_buffer, .cycle = true });
    compute_pass.bindComputePipeline(self.compute_pipeline);
    compute_pass.bindStorageBuffer(self.comp_buffer, 0);
    compute_pass.dispatch(workgroup_size, 1, 1);
    compute_pass.end();

    cmd_buf.submit();
}

pub fn bind_default_uniform_matrix(self: *SpriteBatch, cmd: CommandBuffer) void {
    cmd.pushVertexUniformData(float4x4, self.transform, 0);
}


pub fn render(self: *SpriteBatch, render_pass: RenderPass) void {
    self.rendered = true;
    if (self.vertex_index == 0) {
        return;
    }
    if (!self.flushed) {
        self.flush();
    }

    for (0..self.onQueue) |i| {
        const queue = self.batch_queues[i];
        render_pass.command_buffer.pushVertexUniformData(float4x4, queue.matrix, 0);
        render_pass.bindGraphicsPipeline(queue.pipeline);
        render_pass.bindVertexBuffer(self.vertex_buffer, 0);
        render_pass.bindIndexBuffer(self.index_buffer, .ThirtyTwo);
        render_pass.bindFragmentSampler(0, queue.binding);
        render_pass.drawIndexedPrimitives(queue.count * 6, 1, 0, @intCast(queue.offset * 4), 0);
    }
}

fn resize_buffer(self: *SpriteBatch) void {
    self.transfer_buffer.unmap();

    self.current_max_texture += 2048;
    const max_textures = self.current_max_texture;

    self.device.release(self.index_buffer);
    self.device.release(self.vertex_buffer);
    self.device.release(self.comp_buffer);
    self.device.release(self.transfer_buffer);

    self.vertex_buffer = GpuBuffer.init(
        PositionTextureColorConcreteVertex, 
        self.device, 
        max_textures, 
        .{ .vertex = true, .compute_storage_read = true , .compute_storage_write = true });
    self.comp_buffer = GpuBuffer.init(CompData, self.device, max_textures, .{ .compute_storage_read = true });
    self.transfer_buffer = TransferBuffer.init(CompData, self.device, max_textures, .{ .upload = true });
    self.index_buffer = generate_index_array(self.device, max_textures); 

    self.mapped = self.transfer_buffer.mapUnknown(true); 
}

fn generate_index_array(device: GraphicsDevice, max_indices: u32) GpuBuffer {
    var transfer_buffer = TransferBuffer.init(u32, device, max_indices, .{ .upload = true });
    defer device.release(transfer_buffer);

    const index_buffer = GpuBuffer.init(u32, device, max_indices, .{ .index = true });

    var mapped = transfer_buffer.map(u32, false);

    var i: usize = 0;
    var j: u32 = 0;
    while (i < max_indices) {
        mapped[i] = j;
        mapped[i + 1] = j + 1;
        mapped[i + 2] = j + 2;
        mapped[i + 3] = j + 2;
        mapped[i + 4] = j + 1;
        mapped[i + 5] = j + 3;
        i += 6;
        j += 4;
    }
    transfer_buffer.unmap();

    const cmd_buffer = device.acquireCommandBuffer();
    const copy_pass = cmd_buffer.beginCopyPass();
    copy_pass.uploadToBuffer(transfer_buffer, index_buffer, false);
    copy_pass.end();
    cmd_buffer.submit();

    return index_buffer;
}

pub fn deinit(self: SpriteBatch, device: GraphicsDevice) void {
    device.release(self.vertex_buffer);
    device.release(self.index_buffer);
    device.release(self.transfer_buffer);
    device.release(self.comp_buffer);
    self.allocator.free(self.batch_queues);
}

const DrawCommand = struct {
    texture_quad: TextureQuad,
    position: float2,
    scale: float2 = float2.new(1, 1),
    origin: float2 = float2.new(0, 0),
    rotation: f32 = 0,
    depth: f32 = 1,
    color: Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 }
};

const BatchQueue = struct {
    count: u32,
    offset: u32,
    binding: structs.TextureSamplerBinding,
    pipeline: GraphicsPipeline,
    matrix: float4x4
};

const CompData = extern struct {
    position: float2,
    scale: float2,
    origin: float2,
    uv: UV,
    dimension: float2,
    rotation: f32,
    depth: f32,
    color: float4 align(16)
};