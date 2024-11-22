struct VertexInput {
    float4 Position;
    float4 Color;
}

struct VertexOutput {
    float4 Color : COLOR0;
    float4 Position : SV_Position;
}

[vk_binding(0, 1)]
cbuffer UniformBlock : register(b0, space1) {
    float4x4 MatrixUniform : packoffset(c0);  
};

[shader("vertex")]
VertexOutput main(VertexInput input) {
    VertexOutput out;
    out.Color = input.Color;
    out.Position = mul(MatrixUniform, input.Position);
    return out;
}