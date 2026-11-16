extends RefCounted
class_name TarvokaG11RearUndercarriageV30

# V30: correct the square rear-underbody clipping reported in the G11.
# Two redundant V1 square slabs were behind/under the rear gear:
# G11_ProteccionInferior AND G11_RampaPosteriorCerrada. Physically delete
# BOTH. The approved V2 octagonal hull has a real sealed rear and underside.
# Refit four original stabilizer meshes and reanchor the rear-door locks
# to the existing octagonal back surface. No new panels or game stat edits.
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
        # Profile winding in XZ is CCW when viewed from below;
        # invert the side faces to expose outward-facing front/rear armor.
        _tri(st,bottom[n],top[next],bottom[next])
        _tri(st,bottom[n],top[n],top[next])
    for n in range(1,7):
        # Correct Godot +Y top and -Y underside normals (no culled rear).
        _tri(st,bottom[0],bottom[n],bottom[n+1])
        _tri(st,top[0],top[n+1],top[n])
    st.generate_normals()
    return st.commit()

static func _part(model: Node3D,title: String) -> MeshInstance3D:
    return model.find_child(title,true,false) as MeshInstance3D

static func _hero_foot() -> ArrayMesh:
    return _wedge(
        _octagon(0.135,0.132,0.027,-0.050),
        _octagon(0.115,0.118,0.024,0.050))

static func _mobile_hull() -> ArrayMesh:
    # Local frame of ChasisLanzacohetes (y=.68, z=.02).
    # Taper and narrow the former 1.45m-wide rectangular slab;
    # its upper edge is now inside the 0.645m track inner face.
    return _wedge(
        _octagon(0.535,1.185,0.075,-0.310),
        _octagon(MOBILE_HULL_HALF_X,1.245,0.075,0.310))

static func hero_clearance() -> float:
    return HERO_TRACK_X-HERO_TRACK_HALF_X-maxf(
        FOOT_X+FOOT_MAX_HALF_X,SUPPORT_X+SUPPORT_HALF_X)

static func mobile_clearance() -> float:
    return MOBILE_TRACK_X-MOBILE_TRACK_HALF_X-MOBILE_HULL_HALF_X

static func apply_hero(model: Node3D) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta("tarvoka_g11_joint_finish_v23",false))):
        return false
    var belly:=_part(model,"G11_ProteccionInferior")
    var rear_ramp:=_part(model,"G11_RampaPosteriorCerrada")
    if belly==null or not belly.mesh is BoxMesh or (
            rear_ramp==null or not rear_ramp.mesh is BoxMesh):
        return false
    # The later V2 sculpt already contains a sealed octagonal central hull.
    # Removing the old lower slab must not create a hole.
    var closed_hull:=_part(model,"G11V2_CascoOctogonalCerrado")
    if closed_hull==null or not closed_hull.mesh is ArrayMesh:
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
    var door_clamps: Array[MeshInstance3D]=[]
    var locks: Array[MeshInstance3D]=[]
    var pinheads: Array[MeshInstance3D]=[]
    for side in [-1,1]:
        var close:=_part(model,"G11V12_CierrePorton_%d" % side)
        var keyhole:=_part(model,"G11V12_BocallavePorton_%d" % side)
        var pin:=_part(model,"G11V2_PernoPorton_%d" % side)
        if close==null or keyhole==null or pin==null:
            return false
        door_clamps.append(close)
        locks.append(keyhole)
        pinheads.append(pin)
    if hero_clearance()<MIN_CLEARANCE:
        return false
    # Atomic once all required original rear nodes were validated.
    # The square plates used to overlap the rear tracks despite the V2
    # octagonal chassis already having a closed underside and rear face.
    # Physically remove both offending MeshInstance3D nodes.
    belly.get_parent().remove_child(belly)
    belly.free()
    rear_ramp.get_parent().remove_child(rear_ramp)
    rear_ramp.free()
    # The old hinges were anchored on the deleted 13cm-thick rear ramp.
    # Re-seat them on the actual V2 end face at z=1.40, no floating knobs.
    for i in range(2):
        pinheads[i].position.z=1.414
        door_clamps[i].position.z=1.426
        locks[i].position.z=1.440
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
    model.set_meta("tarvoka_g11_v30_replaced_original_parts",4)
    model.set_meta("tarvoka_g11_v30_redundant_underbody_removed",true)
    model.set_meta("tarvoka_g11_v30_redundant_rear_square_removed",true)
    model.set_meta("tarvoka_g11_v30_reanchored_rear_locks",6)
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
