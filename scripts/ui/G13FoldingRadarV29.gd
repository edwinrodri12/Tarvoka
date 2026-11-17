extends RefCounted
class_name TarvokaG13FoldingRadarV29

# Visual-only telescoping/tilting mast for the G13 twin-autocannon LOD8.
# Keeps the 12-sided V28 mast, dish and receiver on the EXISTING independent
# radar pivot: no new MeshInstance3D, no missile, no weapon stats.
# Re-homes the pivot to the deck contact BEFORE the aft fold so the support
# remains physically rooted rather than hovering through the roof.
const FLAG:="tarvoka_g13_v29_rear_folding_radar"
const RADAR:="G13_RadarAzimut"
const MAST:="G13_RadarMast"
const DISH:="G13_TiltedRadarDish"
const RECEIVER:="G13_RadarReceiver"
const TURRET:="G13_TorretaAzimut"
const REST_Y:=1.360
const FOOT_SHIFT_Y:=0.265
const MAX_FOLD_DEG:=35.0
const FOLD_BEGIN_YAW_DEG:=40.0
const FULL_FOLD_YAW_DEG:=80.0
const MAST_STOWED_SCALE:=0.22
const DISH_STOWED_LOCAL_PITCH_DEG:=-35.0
const ROTATING_MODES:=[ "aim","attack","aim_air",
    "attack_air","aim_ground","attack_ground" ]
const METADATA:="tarvoka_g13_v29_original_pose"
const NEW_DRAW_NODES:=0

static func _parts(root:Node3D)->Dictionary:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return {}
    var radar:=root.find_child(RADAR,true,false) as Node3D
    var mast:=root.find_child(MAST,true,false) as MeshInstance3D
    var dish:=root.find_child(DISH,true,false) as MeshInstance3D
    var receiver:=root.find_child(RECEIVER,true,false) as MeshInstance3D
    if radar==null or mast==null or dish==null or receiver==null:
        return {}
    if mast.get_parent()!=radar or dish.get_parent()!=radar or (
            receiver.get_parent()!=radar):
        return {}
    return {"radar":radar,"mast":mast,"dish":dish,
        "receiver":receiver}

static func install(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta(
                "tarvoka_g13_v28_radar_deck_mounted",false))) or (
            bool(root.get_meta("tarvoka_g13_v1_high_detail",true))):
        return false
    var radar:=root.find_child(RADAR,true,false) as Node3D
    var mast:=root.find_child(MAST,true,false) as MeshInstance3D
    var dish:=root.find_child(DISH,true,false) as MeshInstance3D
    var receiver:=root.find_child(RECEIVER,true,false) as MeshInstance3D
    if radar==null or mast==null or dish==null or receiver==null or (
            mast.get_parent()!=radar) or (
            dish.get_parent()!=radar) or (
            receiver.get_parent()!=radar) or (
            not mast.mesh is ArrayMesh) or (
            not dish.mesh is CylinderMesh):
        return false
    if not is_equal_approx(radar.position.y,REST_Y) or (
            not is_equal_approx(radar.position.z,1.135)) or (
            not mast.position.is_equal_approx(Vector3(0,0.375,0))) or (
            not dish.position.is_equal_approx(Vector3(0,0.780,0))) or (
            not receiver.position.is_equal_approx(Vector3(0,0.790,-0.12))):
        return false
    root.set_meta(METADATA,{
        "radar":radar.position,
        "mast":mast.position,
        "dish":dish.position,
        "receiver":receiver.position,
        "mast_scale":mast.scale,
        "dish_pitch":dish.rotation_degrees.x
    })
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v29_new_draw_nodes",NEW_DRAW_NODES)
    root.set_meta("tarvoka_g13_v29_visual_only",true)
    root.set_meta("tarvoka_g13_v29_weapons",
        "two_original_autocannons_no_missiles")
    return true

static func reset(root:Node3D)->void:
    var p:=_parts(root)
    if p.is_empty():
        return
    var source:Dictionary=root.get_meta(METADATA,{})
    if source.is_empty():
        return
    (p["radar"] as Node3D).position=source["radar"]
    (p["mast"] as MeshInstance3D).position=source["mast"]
    (p["dish"] as MeshInstance3D).position=source["dish"]
    (p["receiver"] as MeshInstance3D).position=source["receiver"]
    (p["mast"] as MeshInstance3D).scale=source["mast_scale"]
    (p["dish"] as MeshInstance3D).rotation_degrees.x=source["dish_pitch"]
    (p["radar"] as Node3D).rotation_degrees.x=0.0
    root.set_meta("tarvoka_g13_v29_fold_degrees",0.0)

static func set_fold(root:Node3D,fraction:float)->bool:
    var p:=_parts(root)
    if p.is_empty():
        return false
    var original:Dictionary=root.get_meta(METADATA,{})
    if original.is_empty():
        return false
    var blend:float=clampf(fraction,0.0,1.0)
    var mast_factor:float=lerpf(1.0,MAST_STOWED_SCALE,blend)
    var radar:=p["radar"] as Node3D
    var mast:=p["mast"] as MeshInstance3D
    mast.position=Vector3(0,lerpf(
        (original["mast"] as Vector3).y,0.640*MAST_STOWED_SCALE,blend),0)
    mast.scale=Vector3(1.0,mast_factor,1.0)
    var dish:=p["dish"] as MeshInstance3D
    dish.position=Vector3(0,lerpf(
        (original["dish"] as Vector3).y,
        (0.780+FOOT_SHIFT_Y)*MAST_STOWED_SCALE,blend),0)
    dish.rotation_degrees.x=lerpf(
        float(original["dish_pitch"]),DISH_STOWED_LOCAL_PITCH_DEG,blend)
    var receiver:=p["receiver"] as MeshInstance3D
    receiver.position=Vector3(0,lerpf(
        (original["receiver"] as Vector3).y,
        (0.790+FOOT_SHIFT_Y)*MAST_STOWED_SCALE,blend),-0.12)
    radar.rotation_degrees.x=MAX_FOLD_DEG*blend
    # The hinge is pinned to the physical deck for EVERY fold fraction.
    # Calculate the actual mast-foot offset in the radar's own yaw/pitch
    # basis and solve the original pivot translation so the foot is fixed
    # at (0,1.095,1.135), not floating through its animation.
    var local_foot:=Vector3(
        0,mast.position.y-0.640*mast_factor,0)
    var fixed_foot:Vector3=(
        (original["radar"] as Vector3)-Vector3(0,FOOT_SHIFT_Y,0))
    radar.position=fixed_foot-radar.basis*local_foot
    root.set_meta("tarvoka_g13_v29_fold_degrees",
        radar.rotation_degrees.x)
    root.set_meta("tarvoka_g13_v29_mast_telescopic_scale",mast_factor)
    root.set_meta("tarvoka_g13_v29_dish_local_pitch",
        dish.rotation_degrees.x)
    root.set_meta("tarvoka_g13_v29_mast_base_y_m",
        radar.position.y+(
            radar.basis*local_foot).y)
    return true

static func apply_pose(root:Node3D,kind:String)->bool:
    var p:=_parts(root)
    if p.is_empty():
        return false
    var turret:=root.find_child(TURRET,true,false) as Node3D
    if turret==null:
        return false
    var yaw:float=absf(wrapf(turret.rotation_degrees.y,
        -180.0,180.0))
    var fraction:float=0.0
    if kind in ROTATING_MODES:
        fraction=smoothstep(
            FOLD_BEGIN_YAW_DEG,FULL_FOLD_YAW_DEG,yaw)
    return set_fold(root,fraction)
