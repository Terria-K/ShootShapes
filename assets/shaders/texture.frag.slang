struct VertexOutput {
    float4 Color : COLOR0;
    float2 TexCoord : TEXCOORD1;
    float4 Position : SV_Position;
}

[vk_binding(0, 2)]
Texture2D<float> Texture : register(t0, space2);

[vk_binding(0, 2)]
SamplerState Sampler : register(s0, space2);

[shader("fragment")]
float4 main(VertexOutput Output) : SV_Target0 {
    return Texture.Sample(Sampler, Output.TexCoord);
}