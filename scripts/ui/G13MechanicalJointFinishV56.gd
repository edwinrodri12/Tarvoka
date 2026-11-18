extends RefCounted
class_name TarvokaG13MechanicalJointFinishV56

# G13 V56 — native hard-surface chassis, suspension and turret coupling.
# The four shocks connect the original V6 spring brackets to the axles;
# the rotating outer grease/bearing ring follows the ORIGINAL turret pivot.
# No new joints, physics, faction colors, wheel motion or weapon mechanics.
# HERO LOD13 only. Four lightweight GPU batches, no per-frame processing.
const FLAG := "tarvoka_g13_v56_integrated_suspension_and_turret_joints"
const PREVIOUS := "tarvoka_g13_v55_brushed_armor_microfinish_and_panel_seals"
const BODIES := "G13_V56_FourHydraulicDamperBodies"
const PISTONS := "G13_V56_FourExposedPistonRods"
const PINS := "G13_V56_EightCaptivePivotPins"
const BEARING := "G13_V56_RotatingOuterBearingBand"
const DRAW_NODES := 4
const DAMPERS := 4
const PIN_COUNT := 8
const TURRET_RING_OUTER := 0.539
const TURRET_RING_INNER := 0.512
const TURRET_RING_Y := 0.068
const SAVED := "tarvoka_g13_v56_preexisting_rig_parent_links"

static func _surface(color: String, metallic: float,
        roughness: float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color)
    m.metallic=metallic
    m.roughness=roughness
    return m

static func _batch(parent: Node3D, label: String, mesh: Mesh,
        coat: Material, poses: Array[Transform3D])->MultiMeshInstance3D:
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=mesh
    mm.instance_count=poses.size()
    for i in range(poses.size()):
        mm.set_instance_transform(i,poses[i])
    var node:=MultiMeshInstance3D.new()
    node.name=label
    node.multimesh=mm
    node.material_override=coat
    parent.add_child(node)
    return node

static func _cylinder(radius: float, length: float)->CylinderMesh:
    var out:=CylinderMesh.new()
    out.bottom_radius=radius
    out.top_radius=radius
    out.height=length
    out.radial_segments=12
    return out

static func _damper_anchors(side:int,axle:int)->Array[Vector3]:
    # All dimensions in the ORIGINAL hull frame. The inner wheel face
    # is at |X|=0.73; max suspension outer radius is < 0.685.
    # V6 fixed spring brackets sit at |X|=.45, Y=.387, Z=±.85.
    # V22 leaf spring pack is centered at |X|=.545, Y=.313.
    var s:float=float(side)
    var z:float=float(axle)*0.85
    return [
        Vector3(s*0.500,0.447,z+float(axle)*0.100),
        Vector3(s*0.631,0.300,z+float(axle)*0.025)
    ]

static func _rod_pose(start:Vector3,finish:Vector3,
        t:float)->Transform3D:
    var direction:Vector3=(finish-start).normalized()
    var b:Basis=Basis(Quaternion(Vector3.UP,direction))
    return Transform3D(b,start.lerp(finish,t))

static func _poses()->Dictionary:
    var cylinders:Array[Transform3D]=[]
    var shafts:Array[Transform3D]=[]
    var pins:Array[Transform3D]=[]
    for side in [-1,1]:
        for axle in [-1,1]:
            var ends:Array[Vector3]=_damper_anchors(side,axle)
            var a:Vector3=ends[0]
            var b:Vector3=ends[1]
            cylinders.append(_rod_pose(a,b,0.34))
            shafts.append(_rod_pose(a,b,0.75))
            pins.append(Transform3D(Basis.IDENTITY,a))
            pins.append(Transform3D(Basis.IDENTITY,b))
    return {"body":cylinders,"shaft":shafts,"pin":pins}

static func _ring()->TorusMesh:
    var ring:=TorusMesh.new()
    ring.inner_radius=TURRET_RING_INNER
    ring.outer_radius=TURRET_RING_OUTER
    ring.rings=8
    ring.ring_segments=40
    return ring

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(PREVIOUS,false)) or (
            not bool(root.get_meta("tarvoka_g13_v1_high_detail",false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var turret:=root.find_child("G13_TorretaAzimut",true,false) as Node3D
    var weapon:=root.find_child("G13_ElevacionCanones",true,false) as Node3D
    var fixed:=root.find_child(
        "G13_V15_FixedTurretPedestal",true,false) as MeshInstance3D
    var rotating:=root.find_child(
        "G13_V15_RotatingTurretSeal",true,false) as MeshInstance3D
    if hull==null or turret==null or weapon==null or (
            fixed==null or rotating==null) or (
            turret.get_parent()!=hull or weapon.get_parent()!=turret or (
            fixed.get_parent()!=hull or rotating.get_parent()!=turret)):
        return false
    for side in [-1,1]:
        for axle in [-1,1]:
            if root.find_child("G13_V6_SuspensionMount_%d_%d" % [
                    side,axle],true,false)==null or root.find_child(
                    "G13_V22_LeafSpringPack_%d_%d" % [
                    side,axle],true,false)==null:
                return false
    if not turret.position.is_equal_approx(Vector3(0,1.41,0.35)):
        return false
    for name in [BODIES,PISTONS,PINS,BEARING]:
        if root.find_child(name,true,false)!=null:
            return false
    var poses:Dictionary=_poses()
    var body_poses:Array[Transform3D]=poses["body"]
    var shaft_poses:Array[Transform3D]=poses["shaft"]
    var pin_poses:Array[Transform3D]=poses["pin"]
    if body_poses.size()!=DAMPERS or shaft_poses.size()!=DAMPERS or (
            pin_poses.size()!=PIN_COUNT):
        return false
    var body:=_surface("#49565d",0.61,0.55)
    var piston:=_surface("#b1bcb9",0.85,0.28)
    var alloy:=_surface("#75848a",0.66,0.43)
    var bearing:=_surface("#364349",0.58,0.52)
    # Body/shaft overlap to create one genuine telescopic assembly.
    # Nothing rotates with the wheel and nothing enters the V54 tire.
    _batch(hull,BODIES,_cylinder(0.034,0.126),body,body_poses)
    _batch(hull,PISTONS,_cylinder(0.015,0.105),piston,shaft_poses)
    var pin:=SphereMesh.new()
    pin.radius=0.029
    pin.height=0.042
    pin.radial_segments=10
    pin.rings=5
    _batch(hull,PINS,pin,alloy,pin_poses)
    var collar:=MeshInstance3D.new()
    collar.name=BEARING
    collar.mesh=_ring()
    collar.position=Vector3(0,TURRET_RING_Y,0)
    collar.material_override=bearing
    turret.add_child(collar)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v56_four_hydraulic_shocks",4)
    root.set_meta("tarvoka_g13_v56_real_pivot_pins",8)
    root.set_meta("tarvoka_g13_v56_added_draw_nodes",DRAW_NODES)
    root.set_meta("tarvoka_g13_v56_lod8_unchanged",true)
    root.set_meta("tarvoka_g13_v56_turret_yaw_parent",turret.name)
    root.set_meta("tarvoka_g13_v56_weapon_identity","dual_autocannon_no_missiles")
    root.set_meta(SAVED,{"hull":hull.name,"turret":turret.name,
        "pitch":weapon.name})
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var parts:Array[Node3D]=[]
    for name in [BODIES,PISTONS,PINS,BEARING]:
        var item:=root.find_child(name,true,false) as Node3D
        if item==null:
            return false
        parts.append(item)
    for part in parts:
        part.visible=enabled
    root.set_meta("tarvoka_g13_v56_preview_enabled",enabled)
    return true
