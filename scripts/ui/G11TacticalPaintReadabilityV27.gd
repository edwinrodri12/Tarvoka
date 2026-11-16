extends RefCounted
class_name TarvokaG11TacticalPaintReadabilityV27

# V27: increase silhouette-readable, approved faction enamel IN PLACE.
# Exactly the same three existing BoxMeshes and paint materials; no added
# geometry, no shader/overlay, no state, unit or LOD mutations.
const FLAG := "tarvoka_g11_v27_tactical_paint_readability"
const SOURCE := "tarvoka_g11_rocket_face_readability_v25"
const GUARD_NAME := "G11Mobile_Faldon_"
const SIDE_NAME := "G11Mobile_PinturaCostado_"
const ROOF_NAME := "G11Mobile_Techo"
const ROOF_BADGE := "G11Mobile_InsigniaFrontal"

const SIDE_LENGTH: float = 1.88
const SIDE_HEIGHT: float = 0.088
const SIDE_DEPTH: float = 0.015
const SIDE_CENTER_Z: float = 0.05
const ROOF_WIDTH: float = 0.68
const ROOF_LENGTH: float = 0.36
const ROOF_DEPTH: float = 0.028
const ROOF_CENTER_Z: float = -0.84
const CLEARANCE: float = 0.001

static func _mesh(model: Node3D,name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func apply(model: Node3D) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta(SOURCE,false))):
        return false
    var roof := _mesh(model,ROOF_NAME)
    var badge := _mesh(model,ROOF_BADGE)
    if roof==null or badge==null or not roof.mesh is BoxMesh or (
            not badge.mesh is BoxMesh):
        return false
    var roof_box := roof.mesh as BoxMesh
    var badge_box := badge.mesh as BoxMesh
    # Enamel sits on top of the existing cabin roof, not in the glass,
    # and leaves enough space around the original roof edges.
    if ROOF_WIDTH>roof_box.size.x-2.0*CLEARANCE or (
            absf(ROOF_CENTER_Z-roof.position.z)+ROOF_LENGTH*0.5 >
            roof_box.size.z*0.5-CLEARANCE) or (
            badge.position.y-ROOF_DEPTH*0.5 <
            roof.position.y+roof_box.size.y*0.5):
        return false
    var stripes: Array[MeshInstance3D]=[]
    for side in [-1,1]:
        var guard := _mesh(model,GUARD_NAME+str(side))
        var paint := _mesh(model,SIDE_NAME+str(side))
        if guard==null or paint==null or not guard.mesh is BoxMesh or (
                not paint.mesh is BoxMesh):
            return false
        var guard_box := guard.mesh as BoxMesh
        # Existing original guard is 10cm high. The enlarged 8.8cm
        # enamel stays within its top and bottom, not over the rubber.
        if SIDE_HEIGHT>guard_box.size.y-2.0*CLEARANCE or (
                absf(paint.position.y-guard.position.y)+SIDE_HEIGHT*0.5 >
                guard_box.size.y*0.5-CLEARANCE) or (
                absf(SIDE_CENTER_Z-guard.position.z)+SIDE_LENGTH*0.5 >
                guard_box.size.z*0.5-CLEARANCE):
            return false
        # Guaranteed partly embedded in the correct outer steel face:
        # not floating outside and not buried inside the guard.
        var steel_face: float=absf(guard.position.x)+guard_box.size.x*0.5
        var badge_inner: float=absf(paint.position.x)-SIDE_DEPTH*0.5
        var badge_outer: float=absf(paint.position.x)+SIDE_DEPTH*0.5
        if badge_inner>=steel_face or badge_outer<=steel_face:
            return false
        stripes.append(paint)
    # All clearances checked before any mutation. Existing unique BoxMeshes
    # are resized, never replaced, duplicated or overlaid.
    badge_box.size=Vector3(ROOF_WIDTH,ROOF_DEPTH,ROOF_LENGTH)
    badge.position.z=ROOF_CENTER_Z
    for stripe in stripes:
        var band := stripe.mesh as BoxMesh
        band.size=Vector3(SIDE_DEPTH,SIDE_HEIGHT,SIDE_LENGTH)
        stripe.position.z=SIDE_CENTER_Z
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v27_no_new_meshes",true)
    model.set_meta("tarvoka_g11_v27_side_band_length",SIDE_LENGTH)
    model.set_meta("tarvoka_g11_v27_cabin_badge_width",ROOF_WIDTH)
    return true
