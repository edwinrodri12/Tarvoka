shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Original TARVOKA V9 rubber: subtle procedural rubber grain, waterline
// abrasion, oily salt deposits. Nonmetallic PBR; no texture downloads.
uniform vec4 rubber_base : source_color = vec4(0.115, 0.161, 0.181, 1.0);
uniform vec4 salt_scuff : source_color = vec4(0.275, 0.337, 0.344, 1.0);
uniform vec4 wet_rubber : source_color = vec4(0.072, 0.115, 0.132, 1.0);
uniform float abrasion : hint_range(0.0, 1.0) = 0.17;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.88;
varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float grain(vec3 v) {
    vec3 p = floor(v);
    return fract(sin(dot(p, vec3(12.9898,78.233,48.512))) * 43758.545);
}
void fragment() {
    float macro = grain(world_pos * 21.0);
    float micro = grain(world_pos * 142.0);
    float porous = mix(macro, micro, 0.40);
    float wet = 1.0 - smoothstep(0.07,0.53,world_pos.y);
    float scratches = smoothstep(0.74,0.95,porous) * abrasion;
    vec3 dry = rubber_base.rgb * (0.88 + porous * 0.23);
    dry = mix(dry, salt_scuff.rgb, scratches);
    ALBEDO = mix(dry,wet_rubber.rgb,wet * 0.36);
    ROUGHNESS = clamp(roughness_base + (porous-0.5)*0.16 -
        wet * 0.22, 0.38, 0.99);
    METALLIC = 0.0;
}
