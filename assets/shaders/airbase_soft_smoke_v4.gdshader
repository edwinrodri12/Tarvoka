shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

// Volumetric-looking edge, swirling vapor and non-spherical silhouette.
// Real-time shader on one instanced MultiMesh. No particles or extra lights.
uniform vec4 smoke_tint : source_color = vec4(0.27,0.30,0.32,0.53);
uniform float drift_speed : hint_range(0.0,1.0) = 0.16;
uniform float edge_breakup : hint_range(0.0,2.0) = 1.0;
varying vec3 puff_local;
varying float puff_seed;
varying float puff_age;
float hash3(vec3 p) {
    p=fract(p*0.1031);
    p+=dot(p,p.yxz+33.33);
    return fract((p.x+p.y)*p.z);
}
float noise3(vec3 p) {
    vec3 i=floor(p);
    vec3 f=fract(p);
    f=f*f*(3.0-2.0*f);
    float v00=mix(hash3(i),hash3(i+vec3(1,0,0)),f.x);
    float v10=mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x);
    float v01=mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x);
    float v11=mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x);
    return mix(mix(v00,v10,f.y),mix(v01,v11,f.y),f.z);
}
void vertex() {
    puff_local=VERTEX;
    puff_seed=INSTANCE_CUSTOM.r;
    puff_age=INSTANCE_CUSTOM.g;
}
void fragment() {
    vec3 p=puff_local;
    vec3 coord=p*3.55+vec3(puff_seed*6.9,puff_seed*4.3,puff_seed*5.8);
    coord+=vec3(TIME*0.08,TIME*drift_speed,TIME*0.043);
    float coarse=noise3(coord);
    float fine=noise3(coord*1.88+vec3(5.29,2.41,7.16));
    float curl=coarse*0.70+fine*0.30;
    // Break the perfect sphere outline; keep the central density thick.
    float radius=length(p*vec3(1.30,1.07,1.30));
    float warped=radius+(0.42-curl)*0.29*edge_breakup;
    float outline=1.0-smoothstep(0.40,0.91,warped);
    float wisps=smoothstep(0.17,0.67,curl+0.12);
    float height_fade=1.0-smoothstep(0.49,1.0,puff_age);
    float alpha=clamp(smoke_tint.a*outline*wisps*(0.32+0.68*height_fade),0.0,0.48);
    alpha*=1.0-0.40*smoothstep(0.75,1.0,puff_age);
    ALBEDO=smoke_tint.rgb*mix(0.78,1.15,coarse);
    ALPHA=alpha;
}
