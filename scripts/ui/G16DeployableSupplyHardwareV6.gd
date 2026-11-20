extends RefCounted
class_name TarvokaG16ServiceHardwareV6

# TARVOKA G16 V6 / WIP: working physical 3D supply hose and couplings.
# Installed on the same V1-V4 six-wheel rig, no extra viewer and no
# ammo/fuel/HP/economy or battle-turn mutations. Camp stays VISUAL only.
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const V5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")

const FLAG="tarvoka_g16_v6_physical_deployable_supply_kit"
const ROOT="G16_V6_ExternalSupplyHardware"
const HOSE="G16_V6_ArticulatedSupplyHose"
const COUPLING="G16_V6_QuickConnectNozzle"
const LID="G16_V6_EquipmentServiceLid"
const GAUGE="G16_V6_PumpPressureGauge"
const MARK="G16_V6_FactionServiceMark"
const MODE="tarvoka_g16_v6_last_pose"
const SHOW="tarvoka_g16_v6_preview_enabled"

static func _mat(color:Color,metal:float,roughness:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color.r,color.g,color.b,1.0)
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
    m.metallic=metal
    m.roughness=roughness
    return m

static func _box(parent:Node3D,label:String,center:Vector3,
        dimensions:Vector3,material:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var m:=BoxMesh.new()
    m.size=dimensions
    n.mesh=m
    n.position=center
    n.material_override=material
    parent.add_child(n)
    return n

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,material:Material,detail:int)->MeshInstance3D:
    var delta:Vector3=b-a
    var m:=CylinderMesh.new()
    m.top_radius=radius
    m.bottom_radius=radius
    m.height=delta.length()
    m.radial_segments=detail
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=m
    n.position=(a+b)*0.5
    n.quaternion=Quaternion(Vector3.UP,delta.normalized())
    n.material_override=material
    parent.add_child(n)
    return n

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func apply(root:Node3D,paint:Color)->bool:
    if root==null or not V1.has_model(root) or not (
            V2.has_model(root) and V3.has_model(root) and V4.has_model(root) and V5.has_model(root)):
        return false
    if has_model(root):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var old_reel:=root.find_child(
        "G16_V3_RetractableHoseReel",true,false) as MeshInstance3D
    if chassis==null or old_reel==null or root.find_child(
            ROOT,true,false)!=null:
        return false
    var hero:bool=bool(root.get_meta("tarvoka_g16_v1_high_detail",false))
    var metal:=_mat(Color("#9eb3bc"),0.73,0.36)
    var frame:=_mat(Color("#2d3940"),0.38,0.72)
    var hose_black:=_mat(Color("#1b2226"),0.0,0.97)
    var bright:=_mat(paint,0.28,0.44)
    var dial:=_mat(Color("#cce2e9"),0.15,0.20)
    var hose_ridge:=_mat(Color("#53666b"),0.33,0.73)
    var coupling_latch:=_mat(Color("#e0ebeb"),0.77,0.27)
    var active:=Node3D.new()
    active.name=ROOT
    chassis.add_child(active)

    # Hose reel protection: two thick-backed mounting plates and six-face
    # case, located OUTSIDE the left rear utility deck, not in the cabin.
    _box(active,"G16_V6_ClosedReelBackplate",
        Vector3(-1.036,1.367,-0.136),
        Vector3(0.089,0.326,0.416),frame)
    _box(active,"G16_V6_ArmoredReelCase",
        Vector3(-1.107,1.362,-0.135),
        Vector3(0.084,0.253,0.324),metal)
    _box(active,"G16_V6_ReelFaceGasket",
        Vector3(-1.155,1.363,-0.136),
        Vector3(0.021,0.198,0.270),hose_black)
    _box(active,MARK,
        Vector3(-1.172,1.369,-0.135),
        Vector3(0.019,0.067,0.233),bright)
    _box(active,"G16_V6_FuelTypeSafetyLabel",
        Vector3(-1.173,1.441,-0.135),
        Vector3(0.019,0.036,0.173),dial)
    _box(active,GAUGE,
        Vector3(-1.182,1.319,-0.226),
        Vector3(0.018,0.061,0.066),dial)

    # Visible, 3D external supply loop. The previous 0.72 m hose rotated
    # 80 degrees into the cargo bay and was almost invisible in the actual
    # isometric Godot screenshots. This longer hose extends OUTWARD, away
    # from the chassis (X negative), and droops naturally under gravity.
    # Everything remains a rigid articulated Studio preview; not a fuel rule.
    var hinge:=Node3D.new()
    hinge.name=HOSE
    hinge.position=Vector3(-1.181,1.342,-0.175)
    active.add_child(hinge)
    var step_count:int=6 if hero else 3
    var points:Array[Vector3]=[]
    for i in range(step_count+1):
        var t:float=float(i)/float(step_count)
        points.append(Vector3(
            -0.085-1.17*t,
            -0.046-0.27*sin(t*PI)-0.14*t,
            0.047+0.23*t+0.042*sin(t*PI)))
    for j in range(step_count):
        _rod(hinge,"G16_V6_RealRubberHoseSegment_%02d" % j,
            points[j],points[j+1],
            0.048 if hero else 0.055,hose_black,12 if hero else 8)
        # Opaque physical strain-relief collars (not decal rings) keep the
        # curved assembly readable in LOD8 and avoid detached pipe seams.
        if j<step_count-1:
            var collar_a:Vector3=points[j].lerp(points[j+1],0.88)
            var collar_b:Vector3=points[j].lerp(points[j+1],1.0)
            _rod(hinge,"G16_V6_HoseStrainCollar_%02d" % j,
                collar_a,collar_b,0.061,hose_ridge,12 if hero else 8)
    var nozzle:=Node3D.new()
    nozzle.name=COUPLING
    nozzle.position=points[step_count]
    hinge.add_child(nozzle)
    _rod(nozzle,"G16_V6_MetalCoupling",
        Vector3.ZERO,Vector3(-0.175,-0.018,0.028),
        0.067,metal,16 if hero else 10)
    _rod(nozzle,"G16_V6_SealWasher",
        Vector3(-0.165,-0.017,0.029),Vector3(-0.203,-0.019,0.034),
        0.070,hose_black,12 if hero else 8)
    _box(nozzle,"G16_V6_ColorCodedQuickConnect",
        Vector3(-0.117,-0.012,0.020),
        Vector3(0.110,0.138,0.099),bright)
    _box(nozzle,"G16_V6_MechanicalLockingClaw",
        Vector3(-0.205,0.009,0.028),
        Vector3(0.046,0.072,0.095),coupling_latch)

    # Hinged external cover built with actual thickness. Its existence
    # remains visible while folded, unlike an untextured flat decal.
    var lid:=Node3D.new()
    lid.name=LID
    lid.position=Vector3(-1.180,1.505,-0.137)
    active.add_child(lid)
    _box(lid,"G16_V6_ThickServiceCover",
        Vector3(-0.013,0.046,0),
        Vector3(0.049,0.115,0.345),metal)
    _box(lid,"G16_V6_ServiceCoverRubberSeal",
        Vector3(-0.046,0.037,0),
        Vector3(0.019,0.090,0.298),hose_black)
    _box(lid,"G16_V6_ServiceCoverFactionStripe",
        Vector3(-0.050,0.083,0),
        Vector3(0.019,0.028,0.285),bright)
    root.set_meta(FLAG,true)
    root.set_meta(SHOW,true)
    root.set_meta("tarvoka_g16_v6_pbr_opaque_physical_solids",true)
    root.set_meta("tarvoka_g16_v6_hero_segments",step_count)
    root.set_meta("tarvoka_g16_v6_extended_hose_clears_chassis",true)
    root.set_meta("tarvoka_g16_v6_visual_only",true)
    root.set_meta("tarvoka_g16_v6_original_tactical_rules_unchanged",true)
    return sync(root,"idle",0.0)

static func sync(root:Node3D,kind:String,progress:float)->bool:
    if not has_model(root):
        return false
    var hinge:=root.find_child(HOSE,true,false) as Node3D
    var lid:=root.find_child(LID,true,false) as Node3D
    if hinge==null or lid==null:
        return false
    var p:float=clampf(progress,0.0,1.0)
    var exposure:float=0.0
    if kind=="resupply":
        exposure=smoothstep(0.08,0.80,p)
    elif kind=="camp":
        exposure=smoothstep(0.0,0.55,p)
    elif kind=="deploy":
        exposure=0.37*smoothstep(0.0,0.85,p)
    elif kind=="pack":
        exposure=1.0-smoothstep(0.0,0.88,p)
    elif kind=="unload":
        exposure=0.15*smoothstep(0.0,0.80,p)
    hinge.visible=bool(root.get_meta(SHOW,true)) and exposure>0.035
    # A small swivel keeps the whole nozzle OUTSIDE the vehicle. A broad
    # 80-degree rotation had hidden it behind the service body in LOD8.
    hinge.rotation_degrees.y=-18.0*exposure
    hinge.rotation_degrees.z=11.0*exposure
    lid.rotation_degrees.z=-67.0*exposure
    root.set_meta(MODE,kind)
    root.set_meta("tarvoka_g16_v6_last_progress",p)
    root.set_meta("tarvoka_g16_v6_service_extension",exposure)
    return true

static func show_finish(root:Node3D,visible:bool)->bool:
    if not has_model(root):
        return false
    var group:=root.find_child(ROOT,true,false) as Node3D
    if group==null:
        return false
    root.set_meta(SHOW,visible)
    group.visible=visible
    return sync(root,str(root.get_meta(MODE,"idle")),float(root.get_meta("tarvoka_g16_v6_last_progress",0.0)))

static func restore(root:Node3D)->bool:
    # Never alter V3 ammunition lids, V4 damage or live battle inventory.
    return sync(root,"idle",0.0)
