
import common;
struct ComputeData 
{
    float2 Position;
    float2 Scale;
    float2 Origin;
    float2[4] UV;
    float2 Dimension;
    float Rotation;
    float Depth;
    float4 Color;
}

StructuredBuffer<ComputeData> ComputeBuffer : register(t0, space0);
RWStructuredBuffer<PositionTextureColorVertex> VertexBuffer : register(u0, space1);

[numthreads(64, 1, 1)]
[shader("compute")]
void main(uint3 GlobalInvocationID : SV_DispatchThreadID) 
{
    uint n = GlobalInvocationID.x;
    ComputeData compData = ComputeBuffer[n];

    float2 scaledOrigin = compData.Origin * compData.Scale;

    float4x4 origin = float4x4(
        float4(1, 0, 0, 0),
        float4(0, 1, 0, 0),
        float4(0, 0, 1, 0),
        float4(-scaledOrigin.x, -scaledOrigin.y, 0, 1)
    );

    float val1 = cos(compData.Rotation);
    float val2 = sin(compData.Rotation);

    float x = (compData.Position.x + scaledOrigin.x) * (1 - val1) + (compData.Position.y + scaledOrigin.y) * val2;
    float y = (compData.Position.y + scaledOrigin.y) * (1 - val1) - (compData.Position.x + scaledOrigin.x) * val2;

    float4x4 rotation = float4x4(
        float4(val1, val2, 0, 0),
        float4(-val2, val1, 0, 0),
        float4(x, y, 1, 0),
        float4(0, 0, 0, 1)
    );

    float4x4 transform = origin * rotation;

    float width = compData.Dimension.x * compData.Scale.x;
    float height = compData.Dimension.y * compData.Scale.y;

    float4 topLeft = float4(compData.Position.x, compData.Position.y, compData.Depth, 1);
    float4 topRight = float4(compData.Position.x + width, compData.Position.y, compData.Depth, 1);
    float4 bottomLeft = float4(compData.Position.x, compData.Position.y + height, compData.Depth, 1);
    float4 bottomRight = float4(compData.Position.x + width, compData.Position.y + height, compData.Depth, 1);

    VertexBuffer[n * 4u].Position = mul(topLeft, transform);
    VertexBuffer[n * 4u + 1].Position = mul(topRight, transform);
    VertexBuffer[n * 4u + 2].Position = mul(bottomLeft, transform);
    VertexBuffer[n * 4u + 3].Position = mul(bottomRight, transform);

    VertexBuffer[n * 4u].TexCoord = compData.UV[0];
    VertexBuffer[n * 4u + 1].TexCoord = compData.UV[1];
    VertexBuffer[n * 4u + 2].TexCoord = compData.UV[2];
    VertexBuffer[n * 4u + 3].TexCoord = compData.UV[3];

    VertexBuffer[n * 4u].Color = compData.Color;
    VertexBuffer[n * 4u + 1].Color = compData.Color;
    VertexBuffer[n * 4u + 2].Color = compData.Color;
    VertexBuffer[n * 4u + 3].Color = compData.Color;
}