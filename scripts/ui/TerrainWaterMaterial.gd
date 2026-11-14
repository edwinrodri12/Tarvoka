extends RefCounted
class_name TarvokaTerrainWaterMaterial

# Lightweight, original animated water for Godot Compatibility / Android.
# Pixel waves follow WORLD coordinates, not tile UVs, so long rivers share
# a visual current. This affects ONLY material color: no vertex displacement,
# collision, movement, fog, unit selection or battle state.
const RIVER_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform vec4 deep_color : source_color = vec4(0.055, 0.217, 0.284, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.175, 0.446, 0.501, 1.0);
uniform vec4 foam_color : source_color = vec4(0.680, 0.871, 0.869, 1.0);
uniform float current_speed : hint_range(0.0, 3.0) = 0.54;
uniform float detail_scale : hint_range(0.1, 2.0) = 1.0;

varying vec3 river_world;
varying float shore_factor;

void vertex() {
    river_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    shore_factor = clamp(COLOR.a, 0.0, 1.0);
}

void fragment() {
    float drift = TIME * current_speed;
    float large_wave = sin(river_world.x * 4.8 +
        river_world.z * 2.7 - drift + sin(river_world.z * 2.6) * 0.31);
    float fine_wave = sin((river_world.z * 10.7 -
        river_world.x * 5.9) * detail_scale + drift * 1.64);
    float soft = clamp(shore_factor * 0.82 +
        fine_wave * 0.08 + large_wave * 0.06, 0.0, 1.0);
    // A narrow, irregular bank line rather than a bright scalloped
    // ribbon around every water tile.
    float foam = smoothstep(0.79, 1.0, shore_factor) *
        (0.22 + 0.44 * smoothstep(-0.10, 0.88, large_wave));
    vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, soft);
    water_color = mix(water_color, foam_color.rgb, foam * 0.23);
    float reflection = pow(max(0.0,
        large_wave * 0.67 + fine_wave * 0.33), 7.0) * 0.065;
    ALBEDO = water_color;
    ROUGHNESS = 0.21;
    METALLIC = 0.02;
    SPECULAR = 0.69;
    EMISSION = foam_color.rgb * (reflection + foam * 0.020);
    ALPHA = 0.88;
}
"""

static func make_material(high_detail: bool = true) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = RIVER_SHADER
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("current_speed",0.58 if high_detail else 0.40)
    material.set_shader_parameter("detail_scale",1.0 if high_detail else 0.67)
    return material
