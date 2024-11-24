import common;

struct VertexOutput {
    float4 Color : COLOR0;
    float4 Position : SV_Position;
}

[vk_binding(0, 1)]
ConstantBuffer<float4x4> MatrixUniform : register(s0, space1);

[shader("vertex")]
VertexOutput main(PositionColorVertex input) {
    return { input.Color, mul(MatrixUniform, input.Position) };
}