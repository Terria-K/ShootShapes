struct PositionColorVertex {
    float4 Position : POSITION0;
    float4 Color : COLOR1;
}

struct PositionTextureColorVertex {
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD1;
    float4 Color : COLOR2;
}