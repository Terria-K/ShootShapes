slangc shaders/positiontexturecolor.vert.slang -entry main -o compiled/positiontexturecolor.vert.spv -emit-spirv-via-glsl
slangc shaders/positioncolor.vert.slang -entry main -o compiled/positioncolor.vert.spv -emit-spirv-via-glsl
slangc shaders/solidcolor.frag.slang -entry main -o compiled/solidcolor.frag.spv -emit-spirv-via-glsl
slangc shaders/texture.frag.slang -entry main -o compiled/texture.frag.spv -emit-spirv-via-glsl
slangc shaders/spritebatch.comp.slang -entry main -o compiled/spritebatch.comp.spv -emit-spirv-via-glsl