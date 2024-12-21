compile() {
    slangc "shaders/$1.slang" -entry main -O3 -o "compiled/$1.spv" -emit-spirv-via-glsl -reflection-json "compiled/$1.json"
}

compile positiontexturecolor.vert
compile positioncolor.vert
compile solidcolor.frag
compile texture.frag
compile spritebatch.comp