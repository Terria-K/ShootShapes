import common;

struct VertexOutput {
    float4 Color : COLOR0;
    float2 TexCoord : TEXCOORD1;
    float4 Position : SV_Position;
}

[vk_binding(0, 1)]
ConstantBuffer<float4x4> MatrixUniform : register(s0, space1);

[shader("vertex")]
VertexOutput main(PositionTextureColorVertex input) {
    return { input.Color, input.TexCoord, mul(MatrixUniform, input.Position) };
}