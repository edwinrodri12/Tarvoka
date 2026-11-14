extends RefCounted
class_name TarvokaConifer3DMesh

# Procedural original pine geometry. One reusable mesh per LOD, instanced
# for whole forest through a MultiMesh. Serrated irregular branches replace
# the previous smooth two-cone silhouette without creating one Node per tree.
# Decoration is read-only and cannot change tactical forest coverage.
static func build_crown(high_detail: bool = true) -> ArrayMesh:
    var mesh := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var layers: int = 3 if high_detail else 2
    var sections: int = 11 if high_detail else 7
    for layer in range(layers):
        var t: float = float(layer)
        var base_y: float = 0.19+t*0.22
        var tip_y: float = base_y+0.46-t*0.036
        var width: float = 0.385-t*0.094
        var apex := Vector3(
            0.018*sin(t*2.7),tip_y,0.021*cos(t*3.1))
        for section in range(sections):
            var angle0: float = TAU*float(section)/float(sections)+t*0.21
            var angle1: float = TAU*float(section+1)/float(sections)+t*0.21
            var irregular0: float = 0.90+0.12*sin(
                float(section)*2.4+t*1.77)
            var irregular1: float = 0.90+0.12*sin(
                float(section+1)*2.4+t*1.77)
            var p0 := Vector3(cos(angle0)*width*irregular0,
                base_y-0.030*sin(float(section)*2.5+t),
                sin(angle0)*width*irregular0)
            var p1 := Vector3(cos(angle1)*width*irregular1,
                base_y-0.030*sin(float(section+1)*2.5+t),
                sin(angle1)*width*irregular1)
            var facet: float = 0.84+0.12*sin(
                float(section)*1.73+t*2.1)
            var branch_color := Color(
                facet,facet*(0.94+0.05*t),facet*0.93,1.0)
            # Triangular boughs with alternating offsets produce a
            # serrated forest silhouette readable at tactical zoom.
            st.set_color(branch_color.lightened(0.08))
            st.add_vertex(apex)
            st.set_color(branch_color)
            st.add_vertex(p0)
            st.set_color(branch_color.darkened(0.20))
            st.add_vertex(p1)
    st.generate_normals()
    st.commit(mesh)
    var foliage := StandardMaterial3D.new()
    foliage.vertex_color_use_as_albedo = true
    foliage.roughness = 0.91
    foliage.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.surface_set_material(0,foliage)
    return mesh
