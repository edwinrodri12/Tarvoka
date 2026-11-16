shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Subtle contact foam over the existing V2 animated sea surface.
// These are separate narrow strips, not a replacement water plane or
// an expensive screen-space effect. No collision or gameplay.
uniform vec4 sea_foam_color : source_color = vec4(0.66,0.85,0.83,1.0);
uniform float foam_opacity : hint_range(0.0,1.0) = 0.36;
uniform float night_factor : hint_range(0.0,1.0) = 1.0;
uniform float motion_speed : hint_range(0.0,2.0) = 0.45;
void fragment() {
    float shore = pow(1.0 - UV.x, 1.45);
    float oscillation = sin(UV.y * 28.0 + TIME * motion_speed * 2.3 +
        sin(UV.x * 7.0 + TIME * 0.33) * 1.8);
    float fine = sin(UV.y * 60.0 - UV.x * 15.0 - TIME * 0.43);
    float broken = smoothstep(-0.28, 0.72,
        oscillation * 0.72 + fine * 0.28);
    float fade_end = smoothstep(0.0,0.10,UV.y) *
        (1.0 - smoothstep(0.90,1.0,UV.y));
    ALBEDO = sea_foam_color.rgb;
    ALPHA = clamp(shore * broken * fade_end *
        foam_opacity * night_factor,0.0,0.70);
}
