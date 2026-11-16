extends RefCounted
class_name TarvokaG11TrackFinishV19

# G11 V19: art-only final native close-up of the already calibrated V18
# track assembly. Replaces the 46 identical rectangular blocks on each side
# with ONE shared beveled-link ArrayMesh containing real raised chevrons.
# The two steel mudguards receive tapered ends, without moving their mounts.
# No stacked/duplicated links, stats, ammunition or scene-combat changes.
const FLAG := "tarvoka_g11_track_finish_v19"
const SOURCE := "tarvoka_g11_track_clearance_v18"
const ROOT := "G11_CascoRaiz"
const LINK_COUNT := 46
const LINK_HALF_X: float = 0.137
const LINK_HALF_Z: float = 0.066
const LINK_HALF_Y: float = 0.019
const CHEVRON_HEIGHT: float = 0.009
const CHEVRON_ROWS := 2
const CHEVRONS_PER_LINK := 4
const INNER_CLEARANCE: float = 0.030
const OUTER_HEIGHT: float = LINK_HALF_Y+CHEVRON_HEIGHT
const GUARD_HALF_X: float = 0.0925
const GUARD_HALF_Z: float = 1.45
const GUARD_HALF_Y: float = 0.0455
const GUARD_BOTTOM: float = 0.811-GUARD_HALF_Y
const TRACK_CROWN: float = 0.35+0.35+0.011+OUTER_HEIGHT
const _FINISH = preload("res://scripts/ui/G11FinishV2.gd")

static var _shoe_cache: ArrayMesh
static var _guard_cache: ArrayMesh

static func _pbr(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _profile_x(st: SurfaceTool, half_x: float,
        profile: Array[Vector2]) -> void:
    # Profile consists of (z,y) local coordinates; extruded in X. The
    # complete body is one watertight volume, not several overlapping boxes.
    for i in range(profile.size()):
        var a: Vector2 = profile[i]
        var b: Vector2 = profile[(i+1)%profile.size()]
        _quad(st,
            Vector3(-half_x,a.y,a.x),Vector3(-half_x,b.y,b.x),
            Vector3(half_x,b.y,b.x),Vector3(half_x,a.y,a.x))
    for i in range(1,profile.size()-1):
        var a: Vector2 = profile[0]
        var b: Vector2 = profile[i]
        var c: Vector2 = profile[i+1]
        _tri(st,Vector3(-half_x,a.y,a.x),
            Vector3(-half_x,c.y,c.x),Vector3(-half_x,b.y,b.x))
        _tri(st,Vector3(half_x,a.y,a.x),
            Vector3(half_x,b.y,b.x),Vector3(half_x,c.y,c.x))

static func _raised_chevron(st: SurfaceTool, side: int, base_z: float) -> void:
    # 3D oblique anti-slip raking on the OUTSIDE of each link. Four short
    # raised ribs are completely inside the pad's z ends; even at either
    # 0.35 m-radius bend they cannot touch the next link.
    var sign: float = float(side)
    var x0: float = sign*0.010
    var x1: float = sign*0.119
    var z0: float = base_z+0.008
    var z1: float = base_z-0.008
    var half: float = 0.006
    var bottom_y: float = LINK_HALF_Y-0.002
    var top_y: float = LINK_HALF_Y+CHEVRON_HEIGHT
    var lower: Array[Vector3] = [
        Vector3(x0,bottom_y,z0-half),Vector3(x1,bottom_y,z1-half),
        Vector3(x1,bottom_y,z1+half),Vector3(x0,bottom_y,z0+half)
    ]
    var upper: Array[Vector3] = [
        Vector3(x0,top_y,z0-half),Vector3(x1,top_y,z1-half),
        Vector3(x1,top_y,z1+half),Vector3(x0,top_y,z0+half)
    ]
    for k in range(4):
        var next: int = (k+1)%4
        _quad(st,lower[k],lower[next],upper[next],upper[k])
    _quad(st,upper[0],upper[1],upper[2],upper[3])

static func _link_mesh() -> ArrayMesh:
    if _shoe_cache != null:
        return _shoe_cache
    var body := SurfaceTool.new()
    body.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Chamfered pads: y/thickness and z/end corners clipped 8 mm.
    var bevel: float = 0.008
    var outline: Array[Vector2] = [
        Vector2(-LINK_HALF_Z+bevel,-LINK_HALF_Y),
        Vector2(LINK_HALF_Z-bevel,-LINK_HALF_Y),
        Vector2(LINK_HALF_Z,-LINK_HALF_Y+bevel),
        Vector2(LINK_HALF_Z,LINK_HALF_Y-bevel),
        Vector2(LINK_HALF_Z-bevel,LINK_HALF_Y),
        Vector2(-LINK_HALF_Z+bevel,LINK_HALF_Y),
        Vector2(-LINK_HALF_Z,LINK_HALF_Y-bevel),
        Vector2(-LINK_HALF_Z,-LINK_HALF_Y+bevel)
    ]
    _profile_x(body,LINK_HALF_X,outline)
    body.generate_normals()
    body.set_material(_pbr(Color("#313b3b"),0.24,0.82))
    var mesh := body.commit()

    var cleats := SurfaceTool.new()
    cleats.begin(Mesh.PRIMITIVE_TRIANGLES)
    _raised_chevron(cleats,-1,-0.032)
    _raised_chevron(cleats,1,-0.032)
    _raised_chevron(cleats,-1,0.032)
    _raised_chevron(cleats,1,0.032)
    cleats.generate_normals()
    cleats.set_material(_pbr(Color("#626b65"),0.35,0.73))
    cleats.commit(mesh)
    _shoe_cache = mesh
    return _shoe_cache

static func _tapered_guard() -> ArrayMesh:
    if _guard_cache != null:
        return _guard_cache
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Actual angular end folds, replacing the old long rectangular slab.
    # Minimum y remains unchanged so the top of the rolling shoes has the
    # same safe 25+ mm clearance. Mounts and length remain identical.
    var z: float = GUARD_HALF_Z
    var h: float = GUARD_HALF_Y
    var profile: Array[Vector2] = [
        Vector2(-z,0.010),Vector2(-z+0.080,-h),
        Vector2(z-0.080,-h),Vector2(z,0.010),
        Vector2(z,0.025),Vector2(z-0.065,h),
        Vector2(-z+0.065,h),Vector2(-z,0.025)
    ]
    _profile_x(st,GUARD_HALF_X,profile)
    st.generate_normals()
    _guard_cache = st.commit()
    return _guard_cache

static func _guard_clearance() -> bool:
    return GUARD_BOTTOM-TRACK_CROWN >= 0.020

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta(SOURCE,false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null or not _guard_clearance():
        return false
    # Check all parts before mutating: no partial V19 if a model was built
    # with an incompatible LOD or incomplete V18 sculpture.
    for side in [-1,1]:
        var shoe := root.find_child(
            "G11V2_OrugaAnimada_%d" % side,true,false
        ) as MultiMeshInstance3D
        var mudguard := root.find_child(
            "G11_Faldon_%d" % side,true,false
        ) as MeshInstance3D
        if shoe == null or shoe.multimesh == null or mudguard == null:
            return false
        if shoe.multimesh.instance_count != LINK_COUNT:
            return false
        if not mudguard.mesh is BoxMesh:
            return false
        if absf(mudguard.position.y-0.811)>0.001:
            return false
        if root.find_child("G11_PanelLateral_%d_0" % side,
                true,false) != null:
            return false

    var shoe_mesh: ArrayMesh = _link_mesh()
    var guard_mesh: ArrayMesh = _tapered_guard()
    for side in [-1,1]:
        var shoe := root.find_child(
            "G11V2_OrugaAnimada_%d" % side,true,false
        ) as MultiMeshInstance3D
        shoe.multimesh.mesh = shoe_mesh
        var mudguard := root.find_child(
            "G11_Faldon_%d" % side,true,false
        ) as MeshInstance3D
        mudguard.mesh = guard_mesh
        # Continue using the original PBR armor finish; no duplication.
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v19_real_beveled_links",2*LINK_COUNT)
    model.set_meta("tarvoka_g11_v19_real_raised_chevrons",
        2*LINK_COUNT*CHEVRONS_PER_LINK)
    model.set_meta("tarvoka_g11_v19_tapered_steel_guards",2)
    return true
