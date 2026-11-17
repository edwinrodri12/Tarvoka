extends RefCounted
class_name TarvokaG13ElevatedRadarV27

# G13 V27 ART ONLY: increase tactical recognition at zoom 14 by sculpting
# an actually taller, tapered search radar mast and broader dish.
# Modifies ONLY already existing nodes in the Android LOD8 asset.
# No new meshes/nodes/draw calls, no missiles, no antenna targeting logic,
# no game stats, and no modifications to the finished LOD13 V24 hero art.
const FLAG:="tarvoka_g13_v27_elevated_mobile_radar"
const SOURCE:="tarvoka_g13_v27_original_and_new_radar"
const PIVOT:="G13_RadarAzimut"
const MAST:="G13_RadarMast"
const DISH:="G13_TiltedRadarDish"
const RECEIVER:="G13_RadarReceiver"
const MAST_HEIGHT:=0.70
const MAST_BASE_RADIUS:=0.107
const MAST_TOP_RADIUS:=0.086
const MAST_CENTER:=Vector3(0,0.375,0)
const DISH_RADIUS:=0.445
const DISH_CENTER:=Vector3(0,0.780,0)
const RECEIVER_CENTER:=Vector3(0,0.790,-0.12)
const ADDED_DRAW_NODES:=0
const ADDED_TRIANGLES:=0

static func _parts(root:Node3D)->Dictionary:
    var radar:=root.find_child(PIVOT,true,false) as Node3D
    if radar==null:
        return {}
    var mast:=radar.find_child(MAST,false,false) as MeshInstance3D
    var dish:=radar.find_child(DISH,false,false) as MeshInstance3D
    var receiver:=radar.find_child(
        RECEIVER,false,false) as MeshInstance3D
    if mast==null or dish==null or receiver==null or (
            not (mast.mesh is CylinderMesh or (
                bool(root.get_meta("tarvoka_g13_v28_radar_deck_mounted",false))
                and mast.mesh is ArrayMesh))) or (
            not dish.mesh is CylinderMesh) or (
            not receiver.mesh is BoxMesh):
        return {}
    return {"mast":mast,"dish":dish,"receiver":receiver}

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta(
                "tarvoka_g13_v26_mobile_faceted_armor",false))) or (
            bool(root.get_meta("tarvoka_g13_v1_high_detail",true))):
        return false
    var parts:=_parts(root)
    if parts.is_empty():
        return false
    var mast:=parts["mast"] as MeshInstance3D
    var dish:=parts["dish"] as MeshInstance3D
    var receiver:=parts["receiver"] as MeshInstance3D
    var old_mast:=mast.mesh as CylinderMesh
    var old_dish:=dish.mesh as CylinderMesh
    if not is_equal_approx(old_mast.height,0.47) or (
            not is_equal_approx(old_mast.top_radius,0.075)) or (
            not mast.position.is_equal_approx(Vector3(0,0.26,0))) or (
            not is_equal_approx(old_dish.top_radius,0.338)) or (
            not dish.position.is_equal_approx(Vector3(0,0.53,0))) or (
            not receiver.position.is_equal_approx(
                Vector3(0,0.54,-0.12))):
        return false

    # Taper is a true 3D surface; cylinder radial/height segments stay the
    # same so the longer mast has zero additional triangle cost.
    var new_mast:=old_mast.duplicate(true) as CylinderMesh
    new_mast.height=MAST_HEIGHT
    new_mast.bottom_radius=MAST_BASE_RADIUS
    new_mast.top_radius=MAST_TOP_RADIUS
    var new_dish:=old_dish.duplicate(true) as CylinderMesh
    new_dish.top_radius=DISH_RADIUS
    new_dish.bottom_radius=DISH_RADIUS

    var old_shapes:Dictionary={
        "mast_mesh":mast.mesh,
        "dish_mesh":dish.mesh,
        "mast_position":mast.position,
        "dish_position":dish.position,
        "receiver_position":receiver.position
    }
    var sculpted:Dictionary={
        "mast_mesh":new_mast,
        "dish_mesh":new_dish,
        "mast_position":MAST_CENTER,
        "dish_position":DISH_CENTER,
        "receiver_position":RECEIVER_CENTER
    }
    mast.mesh=new_mast
    mast.position=MAST_CENTER
    dish.mesh=new_dish
    dish.position=DISH_CENTER
    receiver.position=RECEIVER_CENTER
    root.set_meta(SOURCE,{"old":old_shapes,"new":sculpted})
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v27_added_draw_nodes",ADDED_DRAW_NODES)
    root.set_meta("tarvoka_g13_v27_added_triangles",ADDED_TRIANGLES)
    root.set_meta("tarvoka_g13_v27_tactical_sculpt_only",true)
    root.set_meta("tarvoka_g13_v27_weapon_identity",
        "twin_autocannons_no_missiles")
    return true

static func show_v26_reference(root:Node3D,old:bool)->bool:
    # No second model. Same 3D camera, faction, two guns and animations.
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var parts:=_parts(root)
    var variants:Dictionary=root.get_meta(SOURCE,{})
    if parts.is_empty() or not variants.has("old") or (
            not variants.has("new")):
        return false
    var selected:Dictionary=variants["old"] if old else variants["new"]
    var mast:=parts["mast"] as MeshInstance3D
    var dish:=parts["dish"] as MeshInstance3D
    var receiver:=parts["receiver"] as MeshInstance3D
    mast.mesh=selected["mast_mesh"]
    dish.mesh=selected["dish_mesh"]
    mast.position=selected["mast_position"]
    dish.position=selected["dish_position"]
    receiver.position=selected["receiver_position"]
    root.set_meta("tarvoka_g13_v27_v26_comparison",old)
    return true
