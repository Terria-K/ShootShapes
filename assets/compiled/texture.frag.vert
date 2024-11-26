#version 450
layout(row_major) uniform;
layout(row_major) buffer;

#line 8 0
layout(binding = 0, set = 2)
uniform texture2D Texture_0;

layout(binding = 0, set = 2)
uniform sampler Sampler_0;


#line 1828 1
layout(location = 0)
out vec4 entryPointParam_main_0;


#line 1828
layout(location = 1)
in vec2 Output_TexCoord_0;


#line 14 0
void main()
{

#line 14
    entryPointParam_main_0 = vec4((texture(sampler2D(Texture_0,Sampler_0), (Output_TexCoord_0)).x));

#line 14
    return;
}

