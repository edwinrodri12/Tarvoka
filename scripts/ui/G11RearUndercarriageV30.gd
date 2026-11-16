extends RefCounted
class_name TarvokaG11RearUndercarriageV30

# V30: correct the square rear-underbody clipping reported in the G11.
# Both hero and Android LODs reuse their ORIGINAL mesh instances.
# No extra nodes, no team color, track, wheel or battle rules changes.
const FLAG := "tarvoka_g11_v30_rear_track_clearance"
const HERO_TRACK_X := 0.79
const HERO_TRACK_HALF_X := 0.142
const MOBILE_TRACK_X := 0.79
const MOBILE_TRACK_HALF_X := 0.145
const MIN_CLEARANCE := 0.055
const FOOT_X := 0.385
const FOOT_MAX_HALF_X := 0.135
const FOOT_Z := 1.52
const SUPPORT_X := 0.405
const SUPPORT_HALF_X := 0.070
const HERO_BELLY_HALF_X := 0.580
const MOBILE_HULL_HALF_X := 0.620

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

# Rounded by physically clipping the corners in XZ, not a decal.
static func _octagon(half_x: float, half_z: float,
        bevel: float, y: float) -> Array[Vector3]:
    return [
        Vector3(-half_x+bevel,y,-half_z),
        Vector3(half_x-bevel,y,-half_z),
        Vector3(half_x,y,-half_z+bevel),
        Vector3(half_x,y,half_z-bevel),
        Vector3(half_x-bevel,y,half_z),
        Vector3(-half_x+bevel,y,half_z),
        Vector3(-half_x,y,half_z-bevel),
        Vector3(-half_x,y,-half_z+bevel)
    ]

static func _wedge(bottom: Array[Vector3],
        top: Array[Vector3]) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for n in range(8):
        var next: int=(n+1)%8
        _tri(st,bottom[n],bottom[next],top[next])
        _tri(st,bottom[n],top[next],top[n])
    for n in range(1,7):
        _tri(st,bottom[0],bottom[n+1],bottom[n])
        _tri(st,top[0],top[n],top[n+1])
    st.generate_normals()
    return st.commit()

static func _part(model: Node3D,title: String) -> MeshInstance3D:
    return model.find_child(title,true,false) as MeshInstance3D

static func _hero_foot() -> ArrayMesh:
    return _wedge(
        _octagon(0.135,0.132,0.027,-0.050),
        _octagon(0.115,0.118,0.024,0.050))

static func _belly() -> ArrayMesh:
    # Local frame of G11_ProteccionInferior, centered at z=-0.10.
    # Tapered at the back instead of a large under-track rectangular slab.
    return _wedge(
        _octagon(0.550,1.345,0.085,-0.110),
        _octagon(HERO_BELLY_HALF_X,1.365,0.080,0.110))

static func _mobile_hull() -> ArrayMesh:
    # Local frame of ChasisLanzacohetes (y=.68, z=.02).
    # Taper and narrow the former 1.45m-wide rectangular slab;
    # its upper edge is now inside the 0.645m track inner face.
    return _wedge(
        _octagon(0.535,1.185,0.075,-0.310),
        _octagon(MOBILE_HULL_HALF_X,1.245,0.075,0.310))

static func hero_clearance() -> float:
    return HERO_TRACK_X-HERO_TRACK_HALF_X-maxf(
        FOOT_X+FOOT_MAX_HALF_X,
        SUPPORT_X+SUPPORT_HALF_X,HERO_BELLY_HALF_X)

static func mobile_clearance() -> float:
    return MOBILE_TRACK_X-MOBILE_TRACK_HALF_X-MOBILE_HULL_HALF_X

static func apply_hero(model: Node3D) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta("tarvoka_g11_joint_finish_v23",false))):
        return false
    var belly:=_part(model,"G11_ProteccionInferior")
    if belly==null or not belly.mesh is BoxMesh:
        return false
    var supports: Array[MeshInstance3D]=[]
    var feet: Array[MeshInstance3D]=[]
    for side in [-1,1]:
        var support:=_part(model,"G11_Estabilizador_%d" % side)
        var foot:=_part(model,"G11_ZapataEstabilizador_%d" % side)
        if support==null or foot==null or not support.mesh is BoxMesh or (
                not foot.mesh is BoxMesh):
            return false
        supports.append(support)
        feet.append(foot)
    if hero_clearance()<MIN_CLEARANCE:
        return false
    # Atomic after verifying all four braces and the original underbody.
    belly.mesh=_belly()
    for i in range(2):
        var side: float=-1.0 if i==0 else 1.0
        var support:=supports[i]
        var shape: BoxMesh=(support.mesh as BoxMesh).duplicate() as BoxMesh
        shape.size=Vector3(2.0*SUPPORT_HALF_X,0.72,0.145)
        support.mesh=shape
        support.position=Vector3(side*SUPPORT_X,0.66,1.435)
        support.rotation_degrees=Vector3(8.0,0,side*3.0)
        feet[i].mesh=_hero_foot()
        feet[i].position=Vector3(side*FOOT_X,0.25,FOOT_Z)
        feet[i].rotation_degrees=Vector3.ZERO
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v30_rear_clearance_m",hero_clearance())
    model.set_meta("tarvoka_g11_v30_replaced_original_parts",5)
    return true

static func apply_mobile(model: Node3D) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta(
                "tarvoka_g11_v27_tactical_paint_readability",false))):
        return false
    var chassis:=_part(model,"ChasisLanzacohetes")
    if chassis==null or not chassis.mesh is BoxMesh or (
            mobile_clearance()<0.020):
        return false
    chassis.mesh=_mobile_hull()
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v30_rear_clearance_m",mobile_clearance())
    model.set_meta("tarvoka_g11_v30_replaced_original_parts",1)
    return true
