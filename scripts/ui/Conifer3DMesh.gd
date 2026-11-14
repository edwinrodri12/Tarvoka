extends RefCounted
class_name TarvokaConifer3DMesh

# Three native, original low-poly tree silhouettes; forest terrain is still
# the one authoritative cell type. A handful of shared MultiMeshes replace
# per-tree nodes, using deterministic world positions and per-instance tint.
const PROFILE_SPRUCE := 0
const PROFILE_FIR := 1
const PROFILE_YOUNG := 2
const PROFILE_COUNT := 3

# Subtle vertex wind is a FULL-quality material only. Mobile uses an opaque
# StandardMaterial3D and fewer triangles/instances. No physics or rules.
const FOLIAGE_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform float wind_speed : hint_range(0.0, 4.0) = 1.15;
uniform float wind_amount : hint_range(0.0, 0.06) = 0.015;
varying vec3 local_leaf;

void vertex() {
    vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    float height_weight = smoothstep(0.18, 0.89, VERTEX.y);
    float gust = sin(TIME * wind_speed +
        origin.x * 1.83 + origin.z * 1.27 + VERTEX.y * 2.48);
    float sidestep = cos(TIME * wind_speed * 0.71 +
        origin.z * 2.01 - origin.x * 0.68);
    VERTEX.x += gust * height_weight * wind_amount;
    VERTEX.z += sidestep * height_weight * wind_amount * 0.54;
    local_leaf = VERTEX;
}
void fragment() {
    float needles = sin(local_leaf.y * 27.0 +
        local_leaf.x * 18.0 - local_leaf.z * 13.0);
    // Small-scale needle tonal detail without any texture download.
    // Layered boughs also receive a soft, position-based darkening at
    // their lower edge; conventional scene shadows remain enabled.
    float branch_underside = smoothstep(0.22, 0.91, local_leaf.y);
    float fine_variation = 0.935 + needles * 0.046;
    ALBEDO = COLOR.rgb * fine_variation *
        mix(0.80, 1.05, branch_underside);
    ROUGHNESS = 0.88 + 0.045 * (1.0 - branch_underside);
    METALLIC = 0.0;
}
"""

static func profile_for(cell: Vector2i, tree_index: int) -> int:
    # Spatially stable mix: large evergreen, broad fir, and young sapling.
    return posmod(cell.x*37+cell.y*53+tree_index*17,PROFILE_COUNT)

static func make_material(high_detail: bool = true) -> Material:
    if high_detail:
        var shader := Shader.new()
        shader.code = FOLIAGE_SHADER
        var material := ShaderMaterial.new()
        material.shader = shader
        return material
    var foliage := StandardMaterial3D.new()
    foliage.vertex_color_use_as_albedo = true
    foliage.roughness = 0.93
    foliage.cull_mode = BaseMaterial3D.CULL_DISABLED
    return foliage

static func build_crown(high_detail: bool = true,
        profile: int = PROFILE_SPRUCE) -> ArrayMesh:
    var mesh := ArrayMesh.new()
    if profile < 0 or profile >= PROFILE_COUNT:
        return mesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var layers: int = 4 if high_detail else 2
    var sections: int = 11 if high_detail else 6
    var tall: float = 1.0 if profile == PROFILE_SPRUCE else (
        0.85 if profile == PROFILE_FIR else 0.68)
    var spread: float = 0.33 if profile == PROFILE_SPRUCE else (
        0.43 if profile == PROFILE_FIR else 0.24)
    for layer in range(layers):
        var level: float = float(layer)/float(layers)
        var base_y: float = (0.16+level*0.54)*tall
        var tip_y: float = base_y+(0.50-level*0.10)*tall
        var width: float = spread*(1.0-level*0.63)
        var offset := Vector3(
            0.014*sin(float(layer)*2.3+float(profile)),
            0.0,0.019*cos(float(layer)*2.9+float(profile)))
        var apex := Vector3(offset.x,tip_y,offset.z)
        for section in range(sections):
            var az0: float = TAU*float(section)/float(sections)+(
                float(layer)*0.17)
            var az1: float = TAU*float(section+1)/float(sections)+(
                float(layer)*0.17)
            var oscillation: float = float(section)*2.46+(
                float(layer)*1.82+float(profile)*0.73)
            var mod0: float = 0.85+0.17*sin(oscillation)
            var mod1: float = 0.85+0.17*sin(oscillation+2.46)
            var p0 := Vector3(cos(az0)*width*mod0+offset.x,
                base_y-0.031*sin(oscillation),sin(az0)*width*mod0+offset.z)
            var p1 := Vector3(cos(az1)*width*mod1+offset.x,
                base_y-0.031*sin(oscillation+2.46),
                sin(az1)*width*mod1+offset.z)
            var roughness: float = 0.86+0.13*sin(
                oscillation*0.72)
            # Self-shading is built into vertex tones for low-end
            # devices where dynamic canopy shadows are disabled.
            var branch_tint := Color(
                roughness*(0.91+0.08*level),
                roughness*(0.89+0.10*level),
                roughness*(0.79+0.15*level),1.0)
            st.set_color(branch_tint.lightened(0.08))
            st.add_vertex(apex)
            st.set_color(branch_tint)
            st.add_vertex(p0)
            st.set_color(branch_tint.darkened(0.17))
            st.add_vertex(p1)
            if high_detail and (section+layer)%3 == 0:
                # One short, downward needle spur every few branches.
                # This creates a less geometric outline up close, and
                # disappears altogether in the low-cost mobile mesh.
                var midway: Vector3 = (p0+p1)*0.5
                var outwards: Vector3 = Vector3(
                    cos((az0+az1)*0.5)*0.084,-0.065,
                    sin((az0+az1)*0.5)*0.084)
                st.set_color(branch_tint.darkened(0.19))
                st.add_vertex(p0)
                st.set_color(branch_tint.darkened(0.09))
                st.add_vertex(midway+outwards)
                st.set_color(branch_tint)
                st.add_vertex(p1)
    st.generate_normals()
    st.commit(mesh)
    mesh.surface_set_material(0,make_material(high_detail))
    return mesh
