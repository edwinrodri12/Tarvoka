shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// V2 restrained, original stylized port water: animated fine wavelets,
// tide bands and clear/shore shallow tint; no reflection probes or physics.
uniform vec4 deep_water : source_color = vec4(0.105, 0.289, 0.361, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.176, 0.382, 0.439, 1.0);
uniform vec4 foam_color : source_color = vec4(0.31, 0.51, 0.56, 1.0);
uniform float wave_strength : hint_range(0.0, 0.35) = 0.15;
uniform float wave_speed : hint_range(0.0, 1.5) = 0.26;

void fragment() {
    vec2 uv = UV;
    float a = sin(uv.x * 17.0 + uv.y * 10.0 + TIME * wave_speed * 5.0);
    float b = sin(uv.y * 29.0 - uv.x * 7.0 - TIME * wave_speed * 3.0);
    float c = sin(uv.x * 24.0 + uv.y * 16.0 + TIME * wave_speed * 2.0);
    float ripple = (a * 0.55 + b * 0.30 + c * 0.15) * wave_strength * 0.32;
    float shallow = smoothstep(0.70, 1.0, uv.x) * 0.50 +
                    (1.0 - smoothstep(0.0, 0.17, uv.y)) * 0.21 +
                    smoothstep(0.84, 1.0, uv.y) * 0.21;
    float foam_edge = smoothstep(0.90, 0.99, uv.x) * 0.55 *
                      smoothstep(0.16, 0.58, a * b + 0.42);
    vec3 color = mix(deep_water.rgb, shallow_water.rgb,
                     clamp(shallow + ripple, 0.0, 1.0));
    color = mix(color, foam_color.rgb, foam_edge);
    float glint = pow(max(0.0, a * 0.60 + b * 0.40), 16.0) * 0.045;
    ALBEDO = clamp(color + vec3(glint), vec3(0.0), vec3(1.0));
    ROUGHNESS = 0.32;
    METALLIC = 0.07;
}