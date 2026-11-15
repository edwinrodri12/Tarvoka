shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// V2 restrained, original stylized port water: animated fine wavelets,
// tide bands and clear/shore shallow tint; no reflection probes or physics.
uniform vec4 deep_water : source_color = vec4(0.057, 0.202, 0.305, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.135, 0.350, 0.414, 1.0);
uniform vec4 foam_color : source_color = vec4(0.36, 0.57, 0.61, 1.0);
uniform float wave_strength : hint_range(0.0, 0.35) = 0.15;
uniform float wave_speed : hint_range(0.0, 1.5) = 0.26;

void fragment() {
    vec2 uv = UV;
    float a = sin(uv.x * 61.0 + uv.y * 23.0 + TIME * wave_speed * 5.0);
    float b = sin(uv.y * 102.0 - uv.x * 20.0 - TIME * wave_speed * 3.0);
    float c = sin(uv.x * 119.0 + uv.y * 49.0 + TIME * wave_speed * 2.0);
    float ripple = (a * 0.46 + b * 0.34 + c * 0.20) * wave_strength;
    float shallow = smoothstep(0.70, 1.0, uv.x) * 0.50 +
                    (1.0 - smoothstep(0.0, 0.17, uv.y)) * 0.21 +
                    smoothstep(0.84, 1.0, uv.y) * 0.21;
    float foam_edge = smoothstep(0.90, 0.99, uv.x) * 0.55 *
                      smoothstep(0.16, 0.58, a * b + 0.42);
    vec3 color = mix(deep_water.rgb, shallow_water.rgb,
                     clamp(shallow + ripple, 0.0, 1.0));
    color = mix(color, foam_color.rgb, foam_edge);
    float glint = pow(max(0.0, a * b), 8.0) * 0.11;
    ALBEDO = clamp(color + vec3(glint), vec3(0.0), vec3(1.0));
    ROUGHNESS = 0.32;
    METALLIC = 0.07;
}