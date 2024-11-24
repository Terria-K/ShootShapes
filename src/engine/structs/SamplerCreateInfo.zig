const SamplerCreateInfo = @This();
const enums = @import("../enums/main.zig");
const CompareOp = enums.CompareOp;
const Filter = enums.Filter;
const MipmapMode = enums.MipmapMode;
const SamplerAddressMode = enums.SamplerAddressMode;

min_filter: Filter = Filter.Nearest,
mag_filter: Filter = Filter.Nearest,
mipmap_mode: MipmapMode = MipmapMode.Nearest,
address_mode_u: SamplerAddressMode = SamplerAddressMode.Repeat,
address_mode_v: SamplerAddressMode = SamplerAddressMode.Repeat,
address_mode_w: SamplerAddressMode = SamplerAddressMode.Repeat,
mip_lod_bias: f32 = 0,
max_anisotropy: f32 = 0,
compare_op: CompareOp = CompareOp.Invalid,
min_lod: f32 = 0,
max_lod: f32 = 0,
enable_anisotropy: bool = false,
enable_compare: bool = false,

pub fn anisotropicClamp() SamplerCreateInfo {
    return .{
        .min_filter = .Linear,
        .mag_filter = .Linear,
        .mipmap_mode = .Linear,
        .address_mode_u = .ClampToEdge,
        .address_mode_v = .ClampToEdge,
        .address_mode_w = .ClampToEdge,
        .enable_compare = false,
        .enable_anisotropy = false,
        .max_anisotropy = 4,
        .mip_lod_bias = 0,
        .min_lod = 0,
        .max_lod = 1000
    };
}

pub fn anisotropicWrap() SamplerCreateInfo {
    return .{
        .min_filter = .Linear,
        .mag_filter = .Linear,
        .mipmap_mode = .Linear,
        .address_mode_u = .Repeat,
        .address_mode_v = .Repeat,
        .address_mode_w = .Repeat,
        .enable_compare = false,
        .enable_anisotropy = true,
        .max_anisotropy = 4,
        .mip_lod_bias = 0,
        .min_lod = 0,
        .max_lod = 1000
    };
}

pub fn linearClamp() SamplerCreateInfo {
    return .{
        .min_filter = .Linear,
        .mag_filter = .Linear,
        .mipmap_mode = .Linear,
        .address_mode_u = .ClampToEdge,
        .address_mode_v = .ClampToEdge,
        .address_mode_w = .ClampToEdge,
        .enable_compare = false,
        .enable_anisotropy = false,
        .mip_lod_bias = 0,
        .min_lod = 0,
        .max_lod = 1000
    };
}

pub fn linearWrap() SamplerCreateInfo {
    return .{
        .min_filter = .Linear,
        .mag_filter = .Linear,
        .mipmap_mode = .Linear,
        .address_mode_u = .Repeat,
        .address_mode_v = .Repeat,
        .address_mode_w = .Repeat,
        .enable_compare = false,
        .enable_anisotropy = false,
        .mip_lod_bias = 0,
        .min_lod = 0,
        .max_lod = 1000
    };
}

pub fn pointClamp() SamplerCreateInfo {
    return .{
        .min_filter = .Nearest,
        .mag_filter = .Nearest,
        .mipmap_mode = .Nearest,
        .address_mode_u = .ClampToEdge,
        .address_mode_v = .ClampToEdge,
        .address_mode_w = .ClampToEdge,
        .enable_compare = false,
        .enable_anisotropy = false,
        .mip_lod_bias = 0,
        .min_lod = 0,
        .max_lod = 1000
    };
}

pub fn pointWrap() SamplerCreateInfo {
    return .{
        .min_filter = .Nearest,
        .mag_filter = .Nearest,
        .mipmap_mode = .Nearest,
        .address_mode_u = .Repeat,
        .address_mode_v = .Repeat,
        .address_mode_w = .Repeat,
        .enable_compare = false,
        .enable_anisotropy = false,
        .mip_lod_bias = 0,
        .min_lod = 0,
        .max_lod = 100
    };
}