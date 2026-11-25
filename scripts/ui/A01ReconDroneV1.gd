extends RefCounted
class_name TarvokaA01ReconDroneV1

# A01 is the RECONNAISSANCE UAV from ModernArsenal, not the historical
# HAT-29 attack-helicopter art label. This file is visual-only and does not
# reveal fog tiles, spend resources or give combat abilities.
const FLAG:String="tarvoka_a01_recon_uav_v1_native"
const BODY:String="A01_V1_ClosedReconAirframe"
const SENSOR:String="A01_V1_OpticalGimbal"
const PROPELLER:String="A01_V1_PusherPropeller"
const WING_L:String="A01_V1_MainWing_Left"
const WING_R:String="A01_V1_MainWing_Right"
const COLOR_MARK:String="A01_V1_FactionWingMark"
const VALID_POSES=["idle","move","scan","hit"]

static func _material(color:Color,metal:float=0.27,rough:float=0.54)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _box(parent:Node3D,label:String,position:Vector3,size:Vector3,
        material:Material,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.material_override=material
    node.position=position
    node.rotation_degrees=rot
    parent.add_child(node)
    return node

static func _ellipsoid(parent:Node3D,label:String,position:Vector3,
        scale3d:Vector3,material:Material,hero:bool)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=16 if hero else 8
    mesh.rings=8 if hero else 4
    node.mesh=mesh
    node.material_override=material
    node.position=position
    node.scale=scale3d
    parent.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false)) and (
        root.find_child(BODY,true,false)!=null) and (
        root.find_child(SENSOR,true,false)!=null) and (
        root.find_child(PROPELLER,true,false)!=null)

static func build(root:Node3D,faction_paint:Color,hero:bool=true)->bool:
    if root==null or root.get_meta(FLAG,false):
        return false
    var metal:=_material(Color("#87979c"),0.44,0.52)
    var shell:=_material(Color("#c3cdd1"),0.31,0.49)
    var dark:=_material(Color("#25333a"),0.12,0.84)
    var rubber:=_material(Color("#151e24"),0.0,0.95)
    var optics:=_material(Color("#387d9d"),0.10,0.16)
    var faction:=_material(faction_paint,0.20,0.45)

    var body:=Node3D.new()
    body.name=BODY
    root.add_child(body)
    _ellipsoid(body,"A01_V1_SealedCompositeFuselage",
        Vector3(0,0.95,0.02),Vector3(0.62,0.48,2.34),shell,hero)
    _ellipsoid(body,"A01_V1_ClosedNoseSensorBay",
        Vector3(0,0.92,-0.88),Vector3(0.47,0.39,0.73),metal,hero)
    _box(body,"A01_V1_FactionSpine",
        Vector3(0,1.21,-0.08),Vector3(0.25,0.035,1.05),faction)
    _box(body,"A01_V1_AntennaSpine",
        Vector3(0,1.29,0.17),Vector3(0.08,0.19,0.16),dark)
    # Real solid wings with strong recognizable long-endurance UAV silhouette.
    # Identical physical wingspan in hero and Android LOD8.
    _box(body,WING_L,
        Vector3(-0.89,1.03,-0.10),Vector3(1.61,0.095,0.48),shell,
        Vector3(0,0,-2.0))
    _box(body,WING_R,
        Vector3(0.89,1.03,-0.10),Vector3(1.61,0.095,0.48),shell,
        Vector3(0,0,2.0))
    for side in [-1,1]:
        var sg:float=float(side)
        _box(body,COLOR_MARK+("_L" if side<0 else "_R"),
            Vector3(sg*1.56,1.10,-0.10),Vector3(0.19,0.028,0.41),faction)
        _box(body,"A01_V1_ClosedTailBoom_"+str(side),
            Vector3(sg*0.46,0.91,0.78),Vector3(0.105,0.12,1.43),metal)
        _box(body,"A01_V1_DihedralTail_"+str(side),
            Vector3(sg*0.55,1.04,1.47),Vector3(0.69,0.07,0.27),shell,
            Vector3(0,0,sg*16.0))
        _box(body,"A01_V1_WingtipID_"+str(side),
            Vector3(sg*1.65,1.09,-0.12),Vector3(0.073,0.05,0.33),faction)

    var gimbal:=Node3D.new()
    gimbal.name=SENSOR
    gimbal.position=Vector3(0,0.57,-0.58)
    body.add_child(gimbal)
    _ellipsoid(gimbal,"A01_V1_SealedThreeAxisOpticalPod",
        Vector3.ZERO,Vector3(0.37,0.35,0.40),dark,hero)
    _ellipsoid(gimbal,"A01_V1_BlueEOIRLens",
        Vector3(0,0,-0.215),Vector3(0.19,0.18,0.048),optics,hero)
    _box(gimbal,"A01_V1_CameraBrow",Vector3(0,0.12,-0.17),
        Vector3(0.29,0.04,0.10),metal)
    # Pusher propeller is visibly distinct from a weapon or helicopter rotor.
    var prop:=Node3D.new()
    prop.name=PROPELLER
    prop.position=Vector3(0,0.95,1.12)
    body.add_child(prop)
    _ellipsoid(prop,"A01_V1_ClosedMotorHub",
        Vector3.ZERO,Vector3(0.20,0.20,0.22),metal,hero)
    for index in range(3):
        _box(prop,"A01_V1_PusherBlade_"+str(index),
            Vector3.ZERO,Vector3(0.09,0.94,0.05),rubber,
            Vector3(0,0,60.0*float(index)))
    if hero:
        for side in [-1,1]:
            var sg:float=float(side)
            _box(body,"A01_V1_WingSparJoint_"+str(side),
                Vector3(sg*0.38,0.92,-0.12),
                Vector3(0.20,0.17,0.35),dark)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_visual_only",true)
    root.set_meta("tarvoka_a01_unarmed",true)
    root.set_meta("tarvoka_a01_native_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_catalog_role","uav_recon")
    return has_model(root)

static func pose(root:Node3D,kind:String,progress:float)->bool:
    if not has_model(root) or kind not in VALID_POSES:
        return false
    var p:float=clampf(progress,0.0,1.0)
    var prop:=root.find_child(PROPELLER,true,false) as Node3D
    var camera:=root.find_child(SENSOR,true,false) as Node3D
    if prop==null or camera==null:
        return false
    # V22: continuous motor acceleration, eased sweep and damped recoil.
    var stage:int=int(root.get_meta("tarvoka_a01_v6_damage_stage",0))
    if stage==4 and kind in ["move","scan"]:
        return false
    var spin:float=p-sin(p*TAU)/TAU*0.72
    var turns:float=3.0 if kind=="move" else (2.0 if kind=="scan" else 0.0)
    if stage==3 and turns>0.0:
        turns=1.0
    prop.rotation_degrees.z=360.0*turns*spin
    var sweep:float=TAU*smoothstep(0.0,1.0,p)
    camera.rotation_degrees.y=38.0*sin(sweep) if kind=="scan" else 0.0
    camera.rotation_degrees.x=12.0*pow(sin(p*PI),2.0) if kind=="scan" else 0.0
    var envelope:float=pow(sin(p*PI),2.0)
    root.position.y=0.08*envelope if kind=="move" else 0.0
    var roll:float=0.0
    if kind=="move":
        roll=2.4*sin(p*TAU)*envelope
    elif kind=="hit":
        roll=7.0*sin(p*TAU*2.0)*exp(-3.5*p)*(1.0-p)
        root.position.y=-0.035*sin(p*PI)*exp(-2.5*p)
    root.rotation_degrees.z=roll
    return true

static func restore(root:Node3D)->void:
    if not has_model(root):
        return
    var prop:=root.find_child(PROPELLER,true,false) as Node3D
    var camera:=root.find_child(SENSOR,true,false) as Node3D
    if prop!=null:
        prop.rotation_degrees=Vector3.ZERO
    if camera!=null:
        camera.rotation_degrees=Vector3.ZERO
    root.position.y=0.0
    root.rotation_degrees.z=0.0
