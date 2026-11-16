shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// TARVOKA Base Naval V4: deterministic PBR-like weathering in native Godot.
// World-space salt, wet tide band and sparse oxidation. No external texture
// download, animated noise, costly screen reflections or gameplay effects.
uniform vec4 base_color : source_color = vec4(0.52,0.60,0.62,1.0);
uniform vec4 weather_color : source_color = vec4(0.43,0.31,0.25,1.0);
uniform vec4 wet_color : source_color = vec4(0.18,0.28,0.31,1.0);
uniform float marine_wear : hint_range(0.0,1.0) = 0.28;
uniform float salt_level : hint_range(0.0,1.0) = 0.42;
uniform float tide_height = 0.20;
uniform float surface_metallic : hint_range(0.0,1.0) = 0.1;
uniform float surface_roughness : hint_range(0.0,1.0) = 0.73;
varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash31(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash31(i);
    float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
    float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
    float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
    float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
    float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
    float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
    float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
    float lo = mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y);
    float hi = mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y);
    return mix(lo, hi, f.z);
}

void fragment() {
    float large = value_noise(world_position * 1.58);
    float fleck = value_noise(world_position * 8.2);
    float porous = mix(large, fleck, 0.23);
    float band = 1.0 - smoothstep(0.10, 0.72,
        abs(world_position.y - tide_height));
    float wetness = clamp(band * salt_level *
        (0.78 + porous * 0.34), 0.0, 1.0);
    float oxidation = smoothstep(0.62, 0.84, porous)
        * marine_wear * (0.65 + band * 0.50);
    vec3 dry = base_color.rgb * (0.80 + 0.36 * porous);
    vec3 wet = mix(dry, wet_color.rgb, wetness * 0.82);
    ALBEDO = mix(wet, weather_color.rgb, oxidation);
    ROUGHNESS = clamp(surface_roughness + porous * 0.12
        + oxidation * 0.17 - wetness * 0.22, 0.16, 0.98);
    METALLIC = surface_metallic * (1.0 - oxidation * 0.55);
}
