shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

// Mobile-friendly pseudo-volume: per-pixel evolving 3D fractal noise on
// several intersecting ellipsoid shells. No particle nodes or added lights.
uniform vec4 smoke_tint : source_color = vec4(0.21,0.24,0.26,0.50);
uniform float drift_speed : hint_range(0.0, 1.0) = 0.12;
uniform float turbulence : hint_range(0.0, 2.0) = 0.84;
varying vec3 local_pos;
varying float per_puff_seed;
varying float puff_age;

float hash3(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p,p.yxz + 33.33);
    return fract((p.x+p.y)*p.z);
}

float smooth_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    float a = hash3(i);
    float b = hash3(i+vec3(1.0,0.0,0.0));
    float c = hash3(i+vec3(0.0,1.0,0.0));
    float d = hash3(i+vec3(1.0,1.0,0.0));
    float e = hash3(i+vec3(0.0,0.0,1.0));
    float g = hash3(i+vec3(1.0,0.0,1.0));
    float h = hash3(i+vec3(0.0,1.0,1.0));
    float j = hash3(i+vec3(1.0,1.0,1.0));
    return mix(mix(mix(a,b,f.x),mix(c,d,f.x),f.y),
               mix(mix(e,g,f.x),mix(h,j,f.x),f.y),f.z);
}

void vertex() {
    local_pos = VERTEX;
    per_puff_seed = INSTANCE_CUSTOM.r;
    puff_age = INSTANCE_CUSTOM.g;
}

void fragment() {
    vec3 uv = local_pos*4.1 + vec3(per_puff_seed*7.13);
    uv.y += TIME*drift_speed;
    float large = smooth_noise(uv);
    float small = smooth_noise(uv*2.14 + vec3(8.91,-3.12,1.92));
    float density = mix(large,small,0.30)*turbulence;
    float body = 1.0-smoothstep(0.31,1.22,length(local_pos*1.40));
    float wave = smoothstep(0.17,0.68,density+0.18);
    // Internal density and smooth silhouette; reject hollow black spheres.
    float shade = mix(0.70,1.09,large);
    ALBEDO = smoke_tint.rgb*shade;
    float age_fade = 1.0-0.78*smoothstep(0.48,1.0,puff_age);
    ALPHA = clamp(smoke_tint.a*body*wave*age_fade,0.0,0.56);
}