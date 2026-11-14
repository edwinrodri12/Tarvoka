extends RefCounted
class_name TarvokaHeadquartersEmblems3D

# The eight already-approved shields, cropped from original project atlases.
# Never invents a different faction insignia; uses shared materials and mesh.
const Style = preload("res://scripts/ui/VisualStyle.gd")
static var _textures: Dictionary = {}
static var _materials: Dictionary = {}
static var _shield_mesh: ArrayMesh

static func emblem_texture(faction: int) -> Texture2D:
    # The battle and HQ must use precisely the same eight approved emblems.
    # Avoid preloading raw .webp before Godot import completes in headless CI.
    if faction < 0 or faction >= 8:
        return null
    if not _textures.has(faction):
        _textures[faction] = Style.emblem_texture(faction)
    return _textures[faction]

static func _material(faction: int) -> StandardMaterial3D:
    if _materials.has(faction):
        return _materials[faction]
    var tex: Texture2D = emblem_texture(faction)
    if tex == null:
        return null
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color.WHITE
    mat.albedo_texture = tex
    mat.roughness = 0.82
    mat.metallic = 0.08
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _materials[faction] = mat
    return mat

static func _geometry() -> ArrayMesh:
    if _shield_mesh != null:
        return _shield_mesh
    # Front face only, matching V4's seven-point real 3D shield.
    var outline: Array[Vector2] = [
        Vector2(-0.49,0.48),Vector2(0.49,0.48),
        Vector2(0.46,-0.18),Vector2(0.28,-0.46),
        Vector2(0,-0.67),Vector2(-0.28,-0.46),
        Vector2(-0.46,-0.18)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(outline.size()):
        var j: int = (i+1)%outline.size()
        for p in [Vector2.ZERO,outline[i],outline[j]]:
            st.set_uv(Vector2(p.x+0.5,(0.48-p.y)/1.15))
            st.set_normal(Vector3.FORWARD)
            st.add_vertex(Vector3(p.x,p.y,0.0))
    _shield_mesh = st.commit()
    return _shield_mesh

static func apply(model: Node3D, faction: int) -> bool:
    if model == null or faction < 0 or faction >= 8:
        return false
    var backing: MeshInstance3D = model.find_child(
        "EscudoDeFaccionModular",true,false) as MeshInstance3D
    if backing == null:
        backing = model.find_child(
            "EscudoFragmentadoEnSuelo",true,false) as MeshInstance3D
    if backing == null:
        return false
    var material: StandardMaterial3D = _material(faction)
    if material == null:
        return false
    var artwork := MeshInstance3D.new()
    artwork.name = "EscudoOficialFaccion3D"
    artwork.mesh = _geometry()
    artwork.material_override = material
    # V4 backing front lies at local z=-0.07; move a little forward
    # to avoid z-fighting, without changing the approved sculpted mount.
    artwork.position = Vector3(0,0,-0.098)
    artwork.set_meta("tarvoka_official_emblem_index",faction)
    artwork.set_meta("tarvoka_atlas_first_or_last",
        "first" if faction < 4 else "last")
    backing.add_child(artwork)
    model.set_meta("tarvoka_hq_official_emblem",true)
    return true
