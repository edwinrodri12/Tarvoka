shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

// Soft, fluttering translucent tongues instead of solid polygonal cones.
// The nine instances remain ONE MultiMesh draw, mobile safe.
uniform vec4 flame_tint : source_color = vec4(1.0,0.43,0.07,0.93);
uniform float flicker_speed : hint_range(0.0,15.0) = 7.2;
varying vec2 flame_uv;
varying vec3 instance_tint;
void vertex() {
    flame_uv=UV;
    instance_tint=COLOR.rgb;
    float upper=clamp(VERTEX.y+0.52,0.0,1.0);
    float wobble=sin(TIME*flicker_speed+upper*5.1+float(INSTANCE_ID)*1.73);
    VERTEX.x+=wobble*upper*0.105;
    VERTEX.z+=cos(TIME*(flicker_speed*0.67)+upper*4.4+float(INSTANCE_ID))*upper*0.075;
}
void fragment() {
    float h=clamp(flame_uv.y,0.0,1.0);
    float flicker=sin(TIME*flicker_speed+h*8.3+flame_uv.x*10.0);
    float high=sin(TIME*(flicker_speed*1.29)+h*13.7+flame_uv.x*14.4);
    float feather=smoothstep(0.02,0.19,h)*(1.0-smoothstep(0.56,0.99,h));
    float opacity=feather*(0.64+0.20*flicker+0.09*high);
    vec3 lower=mix(flame_tint.rgb,vec3(1.0,0.82,0.38),1.0-h);
    ALBEDO=mix(lower,instance_tint,0.30);
    EMISSION=ALBEDO*(1.38+0.29*sin(TIME*6.2+h*9.1));
    ALPHA=clamp(opacity*flame_tint.a,0.0,0.83);
}
