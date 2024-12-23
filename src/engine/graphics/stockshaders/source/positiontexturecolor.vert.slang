import common;

struct VertexOutput 
{
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR1;
    float4 Position : SV_Position;
}

[vk_binding(0, 1)]
ConstantBuffer<float4x4> MatrixUniform : register(s0, space1);

[shader("vertex")]
VertexOutput main(PositionTextureColorVertex input) 
{
    return { input.TexCoord, input.Color, mul(MatrixUniform, input.Position) };
}