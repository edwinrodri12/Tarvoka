extends RefCounted
class_name TarvokaG16EngineerRecoveryV1

# TARVOKA G16 V1: original armored combat-engineering/recovery carrier.
# 8x8 chassis, low forward dozer blade, folding articulated recovery crane,
# towing winch, low armored cab and rear workshop platform.
# ART + STUDIO POSES ONLY. No gameplay repairs, bridge placement,
# income, movement permissions, attack, capture or turn actions.
const FLAG: String="tarvoka_g16_engineer_native_3d_v1"
const ROOT: String="G16_ArmoredRecovery8x8"
const WHEELS: String="G16_WheelRig"
const BLADE: String="G16_BladePivot"
const CRANE: String="G16_CraneTurntable"
const BOOM: String="G16_BoomRoot"
const ELBOW: String="G16_BoomElbow"
const CABLE: String="G16_WinchCable"
const HOOK: String="G16_RecoveryHook"
const DUST: String="G16_DustEffect"
const DAMAGE: String="G16_DamageEffect"
static var _materials: Dictionary={}

static func _material(color: Color,metal: float,rough: float,
        coated: bool=false) -> StandardMaterial3D:
    var key: String="%s/%0.3f/%0.3f/%s" % [
        color.to_html(),metal,rough,str(coated)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.clearcoat_enabled=coated
    if coated:
        mat.clearcoat=0.24
        mat.clearcoat_roughness=0.28
    _materials[key]=mat
    return mat

static func _box(parent: Node3D,label: String,pos: Vector3,
        size3: Vector3,material: Material,
        tilt: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=MeshInstance3D.new()
    mesh.name=label
    var shape:=BoxMesh.new()
    shape.size=size3
    mesh.mesh=shape
    mesh.material_override=material
    mesh.position=pos
    mesh.rotation_degrees=tilt
    parent.add_child(mesh)
    return mesh

static func _cylinder(parent: Node3D,label: String,pos: Vector3,
        radius: float,height: float,material: Material,
        tilt: Vector3=Vector3.ZERO,
        segments: int=18) -> MeshInstance3D:
    var mesh:=MeshInstance3D.new()
    mesh.name=label
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=height
    shape.radial_segments=segments
    mesh.mesh=shape
    mesh.position=pos
    mesh.rotation_degrees=tilt
    mesh.material_override=material
    parent.add_child(mesh)
    return mesh

static func _sphere(parent: Node3D,label: String,pos: Vector3,
        scale3: Vector3,material: Material) -> MeshInstance3D:
    var mesh:=MeshInstance3D.new()
    mesh.name=label
    var shape:=SphereMesh.new()
    shape.radius=0.5
    shape.height=1.0
    shape.radial_segments=12
    shape.rings=8
    mesh.mesh=shape
    mesh.position=pos
    mesh.scale=scale3
    mesh.material_override=material
    parent.add_child(mesh)
    return mesh

static func _group(parent: Node3D,label: String,pos: Vector3) -> Node3D:
    var group:=Node3D.new()
    group.name=label
    group.position=pos
    parent.add_child(group)
    return group

static func _wheel(parent: Node3D,side: int,axle: int,z: float,
        detailed: bool,rubber: Material,steel: Material,
        bolt: Material) -> void:
    var sign: float=float(side)
    var wheel:=_group(parent,"G16_Wheel_%s_%d" % [side,axle],
        Vector3(sign*1.03,0.405,z))
    _cylinder(wheel,"G16_RubberTire_%s_%d" % [side,axle],
        Vector3.ZERO,0.385,0.245,rubber,Vector3(0,0,90),24)
    _cylinder(wheel,"G16_Rim_%s_%d" % [side,axle],
        Vector3(sign*0.133,0,0),0.22,0.031,steel,
        Vector3(0,0,90),20)
    _cylinder(wheel,"G16_Hub_%s_%d" % [side,axle],
        Vector3(sign*0.155,0,0),0.115,0.047,bolt,
        Vector3(0,0,90),14)
    if detailed:
        for n in range(12):
            var a: float=TAU*float(n)/12.0
            var tread:=_box(wheel,
                "G16_Tread_%s_%d_%02d" % [side,axle,n],
                Vector3(0,cos(a)*0.381,sin(a)*0.381),
                Vector3(0.249,0.036,0.112),rubber)
            tread.rotation_degrees.x=rad_to_deg(a)
        for n in range(6):
            var a: float=TAU*float(n)/6.0
            _sphere(wheel,"G16_RimBolt_%s_%d_%d" % [side,axle,n],
                Vector3(sign*0.185,cos(a)*0.165,sin(a)*0.165),
                Vector3(0.038,0.038,0.038),steel)

static func build(model: Node3D,faction_color: Color,
        detailed: bool=true) -> bool:
    if model==null:
        return false
    if has_model(model):
        return true
    var armor:=_material(Color("#72818a"),0.53,0.52)
    var armor_light:=_material(Color("#a3adb0"),0.64,0.43)
    var steel:=_material(Color("#bcc7c6"),0.79,0.32)
    var dark:=_material(Color("#283239"),0.37,0.70)
    var rubber:=_material(Color("#202427"),0.0,0.94)
    var glass:=_material(Color("#47768b"),0.10,0.20,true)
    var faction:=_material(faction_color,0.29,0.49,true)
    var hazard:=_material(Color("#bb9d53"),0.16,0.66)
    var red:=_material(Color("#9d423e"),0.10,0.33)
    var base:=_group(model,ROOT,Vector3.ZERO)
    # Long wheelbase, low cabin and work deck intentionally unlike G15.
    _box(base,"G16_LadderFrame",Vector3(0,0.80,0.0),
        Vector3(1.65,0.31,4.22),dark)
    for side in [-1,1]:
        var sign: float=float(side)
        _box(base,"G16_FrameRail_%s" % side,
            Vector3(sign*0.68,0.75,0.03),
            Vector3(0.15,0.29,4.08),steel)
    _box(base,"G16_ArmoredCab",Vector3(0,1.42,-1.25),
        Vector3(1.59,1.13,1.34),armor)
    _box(base,"G16_SlopedCabNose",Vector3(0,1.35,-1.98),
        Vector3(1.47,0.73,0.28),armor_light,Vector3(-16,0,0))
    _box(base,"G16_CabRoof",Vector3(0,2.005,-1.21),
        Vector3(1.69,0.12,1.42),armor_light)
    _box(base,"G16_EngineCabRear",Vector3(0,1.48,-0.49),
        Vector3(1.45,0.78,0.38),dark)
    # Rear workshop, exposed recovery crane, spare track/tyre supports.
    _box(base,"G16_RecoveryDeck",Vector3(0,1.06,0.99),
        Vector3(1.78,0.24,2.29),armor)
    _box(base,"G16_ToolLocker",Vector3(0,1.37,1.47),
        Vector3(1.24,0.51,0.66),armor_light)
    _box(base,"G16_RearTowingFrame",Vector3(0,0.78,2.13),
        Vector3(1.10,0.33,0.26),dark)
    _cylinder(base,"G16_TowEye",Vector3(0,0.65,2.27),
        0.17,0.09,steel,Vector3(90,0,0),20)
    var wheels:=_group(base,WHEELS,Vector3.ZERO)
    for side in [-1,1]:
        var sign: float=float(side)
        for axle in range(4):
            var z: float=-1.53+float(axle)*1.02
            _wheel(wheels,side,axle,z,detailed,rubber,steel,dark)
            _box(base,"G16_Fender_%s_%d" % [side,axle],
                Vector3(sign*0.88,0.91,z),
                Vector3(0.25,0.09,0.88),dark)
        # Controlled amount of faction paint: two compact identifying bands.
        _box(base,"G16_FactionCabStripe_%s" % side,
            Vector3(sign*0.81,1.70,-1.11),
            Vector3(0.021,0.125,0.68),faction)
        _box(base,"G16_FactionLockerStripe_%s" % side,
            Vector3(sign*0.65,1.47,1.40),
            Vector3(0.025,0.10,0.47),faction)
        _box(base,"G16_CabDoor_%s" % side,
            Vector3(sign*0.805,1.30,-1.10),
            Vector3(0.027,0.53,0.70),armor_light)
        _box(base,"G16_ArmoredSideWindow_%s" % side,
            Vector3(sign*0.821,1.70,-1.44),
            Vector3(0.035,0.32,0.37),glass)
        _box(base,"G16_DoorHandle_%s" % side,
            Vector3(sign*0.833,1.39,-0.82),
            Vector3(0.041,0.045,0.16),steel)
        _box(base,"G16_FrontLamp_%s" % side,
            Vector3(sign*0.55,1.06,-2.15),
            Vector3(0.22,0.11,0.035),glass)
        _box(base,"G16_RearLamp_%s" % side,
            Vector3(sign*0.62,0.94,2.13),
            Vector3(0.20,0.11,0.035),red)
        _box(base,"G16_DeckRail_%s" % side,
            Vector3(sign*0.85,1.36,0.85),
            Vector3(0.045,0.18,1.84),steel)
        if detailed:
            for panel in range(3):
                _box(base,"G16_ServiceVent_%s_%d" % [side,panel],
                    Vector3(sign*0.816,1.19,
                        -0.48+0.15*float(panel)),
                    Vector3(0.031,0.044,0.09),dark)
            _box(base,"G16_RecoveryLockerHandle_%s" % side,
                Vector3(sign*0.645,1.44,1.66),
                Vector3(0.052,0.04,0.15),dark)
    _box(base,"G16_FrontGlass",Vector3(0,1.70,-2.08),
        Vector3(1.15,0.32,0.03),glass,Vector3(-16,0,0))
    _box(base,"G16_WindshieldFrame",Vector3(0,1.70,-2.105),
        Vector3(0.072,0.35,0.047),dark,Vector3(-16,0,0))
    # Working blade: wide, sloped cutting edge with reinforced hinges.
    var blade:=_group(base,BLADE,Vector3(0,0.74,-2.15))
    _box(blade,"G16_BladeFace",Vector3(0,-0.02,-0.18),
        Vector3(2.39,0.57,0.15),armor_light,
        Vector3(-13,0,0))
    _box(blade,"G16_BladeCuttingEdge",Vector3(0,-0.34,-0.23),
        Vector3(2.47,0.082,0.18),steel)
    _box(blade,"G16_BladeSpine",Vector3(0,0.19,-0.13),
        Vector3(2.24,0.10,0.24),dark)
    for side in [-1,1]:
        var sign: float=float(side)
        _box(blade,"G16_BladeSupport_%s" % side,
            Vector3(sign*0.74,0.10,0.24),
            Vector3(0.14,0.15,0.75),steel,
            Vector3(-7,0,0))
        _cylinder(blade,"G16_BladeHinge_%s" % side,
            Vector3(sign*0.73,0.15,0.28),
            0.11,0.16,dark,Vector3(0,0,90),16)
        _box(blade,"G16_HazardStripe_%s" % side,
            Vector3(sign*0.98,0.03,-0.273),
            Vector3(0.14,0.28,0.022),hazard,
            Vector3(0,0,sign*17))
    # Exposed mechanical rotating crane, not a missile launcher.
    var crane:=_group(base,CRANE,Vector3(0,1.22,0.53))
    _cylinder(crane,"G16_SlewBearing",Vector3(0,0.10,0),
        0.42,0.20,dark,Vector3.ZERO,22)
    _cylinder(crane,"G16_RotaryBed",Vector3(0,0.25,0),
        0.35,0.17,steel,Vector3.ZERO,18)
    var boom:=_group(crane,BOOM,Vector3(0,0.33,0))
    _box(boom,"G16_BoomPrimary",Vector3(0,0.12,0.86),
        Vector3(0.31,0.32,1.75),armor_light,
        Vector3(-7,0,0))
    _box(boom,"G16_BoomHydraulicHousing",Vector3(0,-0.10,0.61),
        Vector3(0.22,0.20,1.02),dark)
    for side in [-1,1]:
        var sign: float=float(side)
        _cylinder(boom,"G16_BoomPivotPin_%s" % side,
            Vector3(sign*0.20,0.04,0.10),
            0.125,0.08,steel,Vector3(0,0,90),16)
        _cylinder(boom,"G16_HydraulicRam_%s" % side,
            Vector3(sign*0.18,-0.16,0.59),
            0.062,0.83,steel,Vector3(72,0,0),12)
    var elbow:=_group(boom,ELBOW,Vector3(0,0.07,1.64))
    _box(elbow,"G16_TelescopingBoom",
        Vector3(0,0.06,0.57),Vector3(0.23,0.23,1.25),steel)
    _box(elbow,"G16_TelescopeEnd",
        Vector3(0,0.07,1.19),Vector3(0.35,0.28,0.20),armor)
    _cylinder(elbow,"G16_WinchSheave",
        Vector3(0,0.11,1.35),0.16,0.10,dark,
        Vector3(0,0,90),16)
    var cable:=_group(elbow,CABLE,Vector3(0,-0.26,1.35))
    _cylinder(cable,"G16_SteelCable",
        Vector3(0,-0.30,0),0.018,0.60,dark,Vector3.ZERO,8)
    _sphere(cable,HOOK,Vector3(0,-0.66,0),
        Vector3(0.18,0.25,0.15),steel)
    _box(cable,"G16_HookTip",Vector3(0,-0.77,-0.045),
        Vector3(0.10,0.17,0.13),dark,Vector3(26,0,0))
    _box(base,"G16_TowWinchDrum",Vector3(0,1.20,1.91),
        Vector3(0.44,0.34,0.27),dark)
    _cylinder(base,"G16_WinchRoller",Vector3(0,1.15,2.07),
        0.15,0.41,steel,Vector3(0,0,90),16)
    var dust:=_group(base,DUST,Vector3.ZERO)
    for side in [-1,1]:
        _sphere(dust,"G16_Dust_%s" % side,
            Vector3(float(side)*0.88,0.26,1.72),
            Vector3(0.45,0.22,0.62),
            _material(Color(0.60,0.56,0.50,0.42),0.0,0.91))
    dust.visible=false
    var hit:=_group(base,DAMAGE,Vector3.ZERO)
    _sphere(hit,"G16_ImpactSmoke",Vector3(0.47,1.86,-1.12),
        Vector3(0.55,0.50,0.63),
        _material(Color(0.16,0.18,0.20,0.51),0.0,0.96))
    hit.visible=false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g16_hero",detailed)
    model.set_meta("tarvoka_g16_art_only",true)
    model.set_meta("tarvoka_g16_gameplay_installed",false)
    restore(model)
    return true

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false)!=null)

static func pose(model: Node3D,kind: String,progress: float,
        heading: Vector2i=Vector2i(0,-1)) -> bool:
    if not has_model(model):
        return false
    if kind not in ["idle","move","deploy","lift","tow","damage"]:
        return false
    restore(model)
    var t: float=clampf(progress,0.0,1.0)
    var body: Node3D=model.find_child(ROOT,true,false) as Node3D
    var wheels: Node3D=model.find_child(WHEELS,true,false) as Node3D
    var blade: Node3D=model.find_child(BLADE,true,false) as Node3D
    var crane: Node3D=model.find_child(CRANE,true,false) as Node3D
    var boom: Node3D=model.find_child(BOOM,true,false) as Node3D
    var elbow: Node3D=model.find_child(ELBOW,true,false) as Node3D
    var cable: Node3D=model.find_child(CABLE,true,false) as Node3D
    var dust: Node3D=model.find_child(DUST,true,false) as Node3D
    var smoke: Node3D=model.find_child(DAMAGE,true,false) as Node3D
    if body==null or wheels==null or blade==null or (
            crane==null or boom==null or elbow==null
            or cable==null or dust==null or smoke==null):
        return false
    body.rotation.y=atan2(float(heading.x),-float(heading.y))
    match kind:
        "move":
            blade.rotation_degrees.x=-24.0
            boom.rotation_degrees.x=-15.0
            dust.visible=true
            dust.scale=Vector3.ONE*lerpf(0.70,1.35,t)
            for wheel in wheels.get_children():
                (wheel as Node3D).rotation.x=t*TAU*1.75
        "deploy":
            blade.rotation_degrees.x=lerpf(-24.0,15.0,t)
            boom.rotation_degrees.x=lerpf(-15.0,-34.0,t)
            crane.rotation_degrees.y=lerpf(0.0,28.0,t)
        "lift":
            blade.rotation_degrees.x=15.0
            crane.rotation_degrees.y=lerpf(0.0,72.0,t)
            boom.rotation_degrees.x=lerpf(-15.0,-47.0,t)
            elbow.rotation_degrees.x=lerpf(0.0,-22.0,t)
            cable.scale.y=lerpf(1.0,1.65,t)
        "tow":
            blade.rotation_degrees.x=-24.0
            crane.rotation_degrees.y=lerpf(0.0,110.0,t)
            cable.scale.y=lerpf(1.0,1.40,t)
        "damage":
            smoke.visible=true
            smoke.scale=Vector3.ONE*lerpf(0.60,1.25,t)
            body.rotation_degrees.z=lerpf(0.0,4.5,t)
            boom.rotation_degrees.x=lerpf(0.0,18.0,t)
        _:
            pass
    model.set_meta("tarvoka_g16_visual_pose",kind)
    return true

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    var names: Array[String]=[
        ROOT,BLADE,CRANE,BOOM,ELBOW,CABLE]
    for name in names:
        var node: Node3D=model.find_child(name,true,false) as Node3D
        if node!=null:
            node.rotation=Vector3.ZERO
            node.scale=Vector3.ONE
    var wheels: Node3D=model.find_child(WHEELS,true,false) as Node3D
    if wheels!=null:
        for wheel in wheels.get_children():
            (wheel as Node3D).rotation=Vector3.ZERO
    for name in [DUST,DAMAGE]:
        var effect: Node3D=model.find_child(name,true,false) as Node3D
        if effect!=null:
            effect.visible=false
            effect.scale=Vector3.ONE
    model.set_meta("tarvoka_g16_visual_pose","idle")
