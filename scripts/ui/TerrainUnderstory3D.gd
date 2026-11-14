extends RefCounted
class_name TarvokaTerrainUnderstory3D

# Low-cost original shrubs and grasses. Each shared mesh is instantiated
# with MultiMesh; no physics, cover or vision changes. The ground patch
# stays intentionally lower than unit models at tactical camera distances.
static func shrub_mesh(high_detail: bool = true) -> ArrayMesh:
    var result := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var blades: int = 7 if high_detail else 4
    for index in range(blades):
        var theta: float = TAU*float(index)/float(blades)
        var spread: float = 0.07+0.035*float(index%3)
        var height: float = 0.14+0.055*float(index%4)
        var base := Vector3(cos(theta)*spread*0.40,0.008,
            sin(theta)*spread*0.40)
        var left := base+Vector3(
            -sin(theta)*0.048,0.0,cos(theta)*0.048)
        var right := base-Vector3(
            -sin(theta)*0.048,0.0,cos(theta)*0.048)
        var tip := base+Vector3(
            cos(theta)*spread,height,sin(theta)*spread)
        var tint := Color("#597B42") if index%3 == 0 else (
            Color("#3E6A3D"))
        st.set_color(tint.darkened(0.20))
        st.add_vertex(left)
        st.set_color(tint.lightened(0.07))
        st.add_vertex(tip)
        st.set_color(tint)
        st.add_vertex(right)
    st.generate_normals()
    st.commit(result)
    var foliage := StandardMaterial3D.new()
    foliage.vertex_color_use_as_albedo = true
    foliage.cull_mode = BaseMaterial3D.CULL_DISABLED
    foliage.roughness = 1.0
    result.surface_set_material(0,foliage)
    return result

# Normalized local positions. They are deliberately inside the parent
# forest tile to avoid overlap onto roads, rivers or fogged neighbors.
static func placement(cell: Vector2i, index: int) -> Vector2:
    var salt: int = posmod(
        cell.x*173+cell.y*257+index*59,997)
    return Vector2(
        0.16+float(posmod(salt*13+index*11,69))*0.010,
        0.16+float(posmod(salt*19+index*17,69))*0.010)
