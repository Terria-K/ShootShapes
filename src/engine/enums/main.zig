pub const LoadOp = enum(i32) {
    Load = 0,
    Clear = 1,
    DontCare = 2
};

pub const StoreOp = enum(i32) {
    Store = 0,
    DontCare = 1,
    Resolve = 2,
    ResolveAndStore = 3
};

pub const ShaderStage = enum(u32) {
    Vertex,
    Fragment
};

pub const PrimitiveType = enum(u32) {
    TriangleList = 0,
    TriangleStrip = 1,
    LineList = 2,
    LineStrip = 3,
    PointList = 4
};

pub const FillMode = enum(u32) {
    Fill,
    Line
};

pub const CullMode = enum(u32) {
    None,
    Front,
    Back
};

pub const FrontFace = enum(u32) {
    CounterClockwise,
    Clockwise
};

pub const SampleCount = enum(u32) {
    One,
    Two,
    Four,
    Eight
};

pub const CompareOp = enum(u32) {
    Invalid,
    Never,
    Less,
    Equal,
    LessOrEqual,
    Greater,
    NotEqual,
    GreaterOrEqual,
    Always
};

pub const StencilOp = enum(u32) {
    Invalid,
    Keep,
    Zero,
    Replace,
    IncrementAndClamp,
    DecrementAndClamp,
    Invert,
    IncrementAndWrap,
    DecrementAndWrap
};

pub const BlendFactor = enum(u32) {
    Invalid,
    Zero,
    One,
    SrcColor,
    OneMinusSrcColor,
    DstColor,
    OneMinusDstColor,
    SrcAlpha,
    OneMinusSrcAlpha,
    DstAlpha,
    OneMinusDstAlpha,
    ConstantColor,
    OneMinusConstantColor,
    SrcAlphaSaturate
};

pub const BlendOp = enum(u32) {
    Invalid,
    Add,
    Subtract,
    ReverseSubtract,
    Min,
    Max
};

pub const TextureFormat = enum(u32) {
    Invalid,
    A8_UNORM = 1,
    R8_UNORM = 2,
    R8G8_UNORM = 3,
    R8G8B8A8_UNORM = 4,
    R16_UNORM = 5,
    R16G16_UNORM = 6,
    R16G16B16A16_UNORM = 7,
    R10G10B10A2_UNORM = 8,
    B5G6R5_UNORM = 9,
    B5G5R5A1_UNORM = 10,
    B4G4R4A4_UNORM = 11,
    B8G8R8A8_UNORM = 12,
    BC1_RGBA_UNORM = 13,
    BC2_RGBA_UNORM = 14,
    BC3_RGBA_UNORM = 15,
    BC4_R_UNORM = 16,
    BC5_RG_UNORM = 17,
    BC7_RGBA_UNORM = 18,
    BC6H_RGB_FLOAT = 19,
    BC6H_RGB_UFLOAT = 20,
    R8_SNORM = 21,
    R8G8_SNORM = 22,
    R8G8B8A8_SNORM = 23,
    R16_SNORM = 24,
    R16G16_SNORM = 25,
    R16G16B16A16_SNORM = 26,
    R16_FLOAT = 27,
    R16G16_FLOAT = 28,
    R16G16B16A16_FLOAT = 29,
    R32_FLOAT = 30,
    R32G32_FLOAT = 31,
    R32G32B32A32_FLOAT = 32,
    R11G11B10_UFLOAT = 33,
    R8_UINT = 34,
    R8G8_UINT = 35,
    R8G8B8A8_UINT = 36,
    R16_UINT = 37,
    R16G16_UINT = 38,
    R16G16B16A16_UINT = 39,
    R32_UINT = 40,
    R32G32_UINT = 41,
    R32G32B32A32_UINT = 42,
    R8_INT = 43,
    R8G8_INT = 44,
    R8G8B8A8_INT = 45,
    R16_INT = 46,
    R16G16_INT = 47,
    R16G16B16A16_INT = 48,
    R32_INT = 49,
    R32G32_INT = 50,
    R32G32B32A32_INT = 51,
    R8G8B8A8_UNORM_SRGB = 52,
    B8G8R8A8_UNORM_SRGB = 53,
    BC1_RGBA_UNORM_SRGB = 54,
    BC2_RGBA_UNORM_SRGB = 55,
    BC3_RGBA_UNORM_SRGB = 56,
    BC7_RGBA_UNORM_SRGB = 57,
    D16_UNORM = 58,
    D24_UNORM = 59,
    D32_FLOAT = 60,
    D24_UNORM_S8_UINT = 61,
    D32_FLOAT_S8_UINT = 62
};

pub const VertexInputRate = enum(u32) {
    Vertex,
    Instance
};

pub const VertexElementFormat = enum(u32) {
    Invalid = 0,
    Int = 1,
    Int2 = 2,
    Int3 = 3,
    Int4 = 4,
    Uint = 5,
    Uint2 = 6,
    Uint3 = 7,
    Uint4 = 8,
    Float = 9,
    Float2 = 10,
    Float3 = 11,
    Float4 = 12,
    Byte2 = 13,
    Byte4 = 14,
    UByte2 = 15,
    UByte4 = 16,
    Byte2Norm = 17,
    Byte4Norm = 18,
    UByte2Norm = 19,
    UByte4Norm = 20,
    Short2 = 21,
    Short4 = 22,
    UShort2 = 23,
    UShort4 = 24,
    Short2Norm = 25,
    Short4Norm = 26,
    UShort2Norm = 27,
    UShort4Norm = 28,
    Half2 = 29,
    Half4 = 30,

    pub inline fn offset(self: VertexElementFormat) u32 {
        return switch (self) {
            .Invalid => 0,
            .Int => 4,
            .Int2 => 8,
            .Int3 => 12,
            .Int4 => 16,
            .Uint => 4,
            .Uint2 => 8,
            .Uint3 => 12,
            .Uint4 => 16,
            .Float => 4,
            .Float2 => 8,
            .Float3 => 12,
            .Float4 => 16,
            .Byte2 => 2,
            .Byte4 => 4,
            .UByte2 => 2,
            .UByte4 => 4,
            .Byte2Norm => 2,
            .Byte4Norm => 4,
            .UByte2Norm => 2,
            .UByte4Norm => 4,
            .Short2 => 4,
            .Short4 => 8,
            .UShort2 => 4,
            .UShort4 => 8,
            .Short2Norm => 4,
            .Short4Norm => 8,
            .UShort2Norm => 4,
            .UShort4Norm => 8,
            .Half2 => 4,
            .Half4 => 8,
        };
    }
};

pub const IndexElementSIze = enum(u32) {
    Sixteen = 0,
    ThirtyTwo = 1
};

pub const KeyCode = enum(i32) {
    Unknown = 0,
    A = 4,
    B = 5,
    C = 6,
    D = 7,
    E = 8,
    F = 9,
    G = 10,
    H = 11,
    I = 12,
    J = 13,
    K = 14,
    L = 15,
    M = 16,
    N = 17,
    O = 18,
    P = 19,
    Q = 20,
    R = 21,
    S = 22,
    T = 23,
    U = 24,
    V = 25,
    W = 26,
    X = 27,
    Y = 28,
    Z = 29,
    D1 = 30,
    D2 = 31,
    D3 = 32,
    D4 = 33,
    D5 = 34,
    D6 = 35,
    D7 = 36,
    D8 = 37,
    D9 = 38,
    D0 = 39,
    Return = 40,
    Escape = 41,
    Backspace = 42,
    Tab = 43,
    Space = 44,
    Minus = 45,
    Equals = 46,
    LeftBracket = 47,
    RightBracket = 48,
    Backslash = 49,
    NonUSHash = 50,
    Semicolon = 51,
    Apostrophe = 52,
    Grave = 53,
    Comma = 54,
    Period = 55,
    Slash = 56,
    CapsLock = 57,
    F1 = 58,
    F2 = 59,
    F3 = 60,
    F4 = 61,
    F5 = 62,
    F6 = 63,
    F7 = 64,
    F8 = 65,
    F9 = 66,
    F10 = 67,
    F11 = 68,
    F12 = 69,
    PrintScreen = 70,
    ScrollLock = 71,
    Pause = 72,
    Insert = 73,
    Home = 74,
    PageUp = 75,
    Delete = 76,
    End = 77,
    PageDown = 78,
    Right = 79,
    Left = 80,
    Down = 81,
    Up = 82,
    NumLockClear = 83,
    KeypadDivide = 84,
    KeypadMultiply = 85,
    KeypadMinus = 86,
    KeypadPlus = 87,
    KeypadEnter = 88,
    Keypad1 = 89,
    Keypad2 = 90,
    Keypad3 = 91,
    Keypad4 = 92,
    Keypad5 = 93,
    Keypad6 = 94,
    Keypad7 = 95,
    Keypad8 = 96,
    Keypad9 = 97,
    Keypad0 = 98,
    KeypadPeriod = 99,
    NonUSBackslash = 100,
    LeftControl = 224,
    LeftShift = 225,
    LeftAlt = 226,
    LeftMeta = 227,
    RightControl = 228,
    RightShift = 229,
    RightAlt = 230,
    RightMeta = 231
};