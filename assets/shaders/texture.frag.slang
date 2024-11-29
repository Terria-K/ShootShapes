struct VertexOutput 
{
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR1;
}

[vk_binding(0, 2)]
SamplerState Sampler : register(s0, space2);

[vk_binding(0, 2)]
Texture2D<float4> Texture : register(t0, space2);


[shader("fragment")]
float4 main(VertexOutput Output) : SV_Target0 
{
    float4 texture = Texture.Sample(Sampler, Output.TexCoord) * Output.Color;
    if (texture.x == 0) {
        discard;
    }

    return texture;
}