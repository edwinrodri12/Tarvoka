extends RefCounted
class_name TarvokaAPCBoardingV3

# Native Godot 3D loading rig for the real P06 V2 sculpt, NOT a sprite overlay.
# Entirely art/studio-only: the source of truth for multiplayer/battle actions
# remains BattleSession + CargoActions on the separate gameplay branch.
# Two articulated seat occupants and one moving rig reuse fixed low-poly
# materials; the 3D APC retains the original open rear geometry and hinge.
const ART_ROOT := "APC_P06_V1_Blindado6x6"
const RIG_ROOT := "TropasAnimadasP06V3"
const HINGE := "BisagraRampaP06"
const MOVING := "SoldadoAbordandoP06V3"
const COUNT := "tarvoka_p06_v3_seated"
const ACTIVE := "tarvoka_p06_v3_active_kind"
const INITIAL := "tarvoka_p06_v3_before"
const FINISHED := "tarvoka_p06_v3_complete"
const DURATION := 2.20
const CAPACITY := 2
const START := Vector3(0.0,0.09,2.48)
const INSIDE := Vector3(0.0,0.56,0.80)
const CLOSED_DEGREES := 8.0
const OPEN_DEGREES := 78.0

static func _smooth(v: float) -> float:
    var t: float = clampf(v,0.0,1.0)
    return t*t*(3.0-2.0*t)

static func _apc(model: Node3D) -> Node3D:
    if model==null or not bool(model.get_meta("tarvoka_apc_sculpt_v1",false)):
        return null
    return model.find_child(ART_ROOT,true,false) as Node3D

static func _solid(hex: String,metal: float=0.1) -> StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(hex)
    material.roughness=0.81
    material.metallic=metal
    material.cull_mode=BaseMaterial3D.CULL_BACK
    return material

static func _mesh(parent: Node3D,label: String,shape: Mesh,
        at: Vector3,material: StandardMaterial3D) -> MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=shape
    part.material_override=material
    part.position=at
    part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    parent.add_child(part)
    return part

static func _box(parent: Node3D,name: String,size: Vector3,at: Vector3,
        material: StandardMaterial3D) -> MeshInstance3D:
    var cube:=BoxMesh.new()
    cube.size=size
    return _mesh(parent,name,cube,at,material)

static func _ball(parent: Node3D,name: String,radius: float,at: Vector3,
        material: StandardMaterial3D) -> MeshInstance3D:
    var sphere:=SphereMesh.new()
    sphere.radius=radius
    sphere.height=radius*2.0
    sphere.radial_segments=8
    sphere.rings=4
    return _mesh(parent,name,sphere,at,material)

static func _soldier(parent: Node3D,name: String,
        uniform: StandardMaterial3D,armor: StandardMaterial3D,
        dark: StandardMaterial3D,visor: StandardMaterial3D) -> Node3D:
    var root:=Node3D.new()
    root.name=name
    parent.add_child(root)
    # A recognizable physical infantry figure, not a billboard: head,
    # ballistic helmet and visor, weighted vest, backpack and movable limbs.
    _box(root,"PechoVestP06V3",Vector3(0.24,0.28,0.18),
        Vector3(0.0,0.37,0.0),armor)
    _box(root,"TorsoTextilP06V3",Vector3(0.21,0.20,0.16),
        Vector3(0.0,0.32,0.005),uniform)
    _box(root,"MochilaP06V3",Vector3(0.22,0.25,0.09),
        Vector3(0.0,0.34,0.15),dark)
    _ball(root,"CabezaP06V3",0.082,Vector3(0.0,0.605,-0.015),uniform)
    _ball(root,"CascoP06V3",0.104,Vector3(0.0,0.655,-0.008),armor)
    _box(root,"VisorP06V3",Vector3(0.135,0.040,0.036),
        Vector3(0.0,0.620,-0.101),visor)
    _box(root,"ProtectorCuelloP06V3",Vector3(0.14,0.085,0.12),
        Vector3(0.0,0.525,0.015),dark)
    for side in [-1,1]:
        var sign: float=float(side)
        var arm:=Node3D.new()
        arm.name="BrazoArticuladoP06V3_%d" % side
        arm.position=Vector3(sign*0.16,0.48,0.0)
        root.add_child(arm)
        _box(arm,"MangaP06V3",Vector3(0.09,0.27,0.095),
            Vector3(sign*0.025,-0.14,0.0),uniform)
        _box(arm,"GuanteP06V3",Vector3(0.105,0.07,0.10),
            Vector3(sign*0.025,-0.275,-0.018),dark)
        var leg:=Node3D.new()
        leg.name="PiernaArticuladaP06V3_%d" % side
        leg.position=Vector3(sign*0.07,0.20,0.015)
        root.add_child(leg)
        _box(leg,"PantalonP06V3",Vector3(0.106,0.24,0.11),
            Vector3(0.0,-0.115,0.0),uniform)
        _box(leg,"BotasP06V3",Vector3(0.12,0.095,0.175),
            Vector3(0.0,-0.267,-0.035),dark)
    return root

static func _troop(root: Node3D,name: String) -> Node3D:
    return root.find_child(name,false,false) as Node3D

static func prepare(model: Node3D,faction: int=0) -> bool:
    var hull: Node3D=_apc(model)
    if hull==null or hull.find_child(HINGE,false,false)==null:
        return false
    if hull.find_child(RIG_ROOT,false,false)!=null:
        return true
    # Limited, shared material library per model; no continuous allocation
    # during animation updates on Android.
    var tint: String="#A5B2A1" if faction%2==0 else "#B9A79C"
    var uniform:=_solid(tint)
    var armor:=_solid("#5E746E",0.20)
    var dark:=_solid("#1C2930",0.05)
    var visor:=_solid("#709EB0",0.24)
    var root:=Node3D.new()
    root.name=RIG_ROOT
    hull.add_child(root)
    for index in range(CAPACITY):
        var soldier:=_soldier(root,"SoldadoSentadoP06V3_%d" % index,
            uniform,armor,dark,visor)
        soldier.position=Vector3(-0.34 if index==0 else 0.34,0.57,0.72)
        soldier.rotation_degrees.y=-10.0 if index==0 else 10.0
        soldier.scale=Vector3.ONE*0.70
    var moving:=_soldier(root,MOVING,uniform,armor,dark,visor)
    moving.position=START
    moving.scale=Vector3.ONE*0.93
    moving.visible=false
    model.set_meta(COUNT,0)
    model.set_meta(FINISHED,false)
    model.set_meta("tarvoka_apc_boarding_v3",true)
    return true

static func occupants(model: Node3D) -> int:
    if _apc(model)==null:
        return 0
    return clampi(int(model.get_meta(COUNT,0)),0,CAPACITY)

static func _show_seats(root: Node3D,count: int) -> void:
    for i in range(CAPACITY):
        var soldier: Node3D=_troop(root,"SoldadoSentadoP06V3_%d" % i)
        if soldier!=null:
            soldier.visible=i<count

static func set_occupants(model: Node3D,count: int) -> bool:
    var hull: Node3D=_apc(model)
    if hull==null or count<0 or count>CAPACITY:
        return false
    var root: Node3D=hull.find_child(RIG_ROOT,false,false) as Node3D
    if root==null:
        return false
    model.set_meta(COUNT,count)
    model.set_meta(ACTIVE,"")
    model.set_meta(FINISHED,false)
    _show_seats(root,count)
    var moving: Node3D=_troop(root,MOVING)
    if moving!=null:
        moving.visible=false
    return true

static func _ramp(model: Node3D) -> Node3D:
    var hull: Node3D=_apc(model)
    return hull.find_child(HINGE,false,false) as Node3D if hull!=null else null

static func pose(model: Node3D,kind: String,time: float) -> bool:
    if kind not in ["embark","disembark"]:
        return false
    var hull: Node3D=_apc(model)
    var ramp: Node3D=_ramp(model)
    if hull==null or ramp==null:
        return false
    var root: Node3D=hull.find_child(RIG_ROOT,false,false) as Node3D
    if root==null:
        return false
    var current: int=occupants(model)
    # Starting a new explicitly requested sequence resets the guard. Calling
    # the same end frame repeatedly CANNOT insert/remove extra passengers.
    if time<=0.0:
        model.set_meta(ACTIVE,kind)
        model.set_meta(INITIAL,current)
        model.set_meta(FINISHED,false)
    if str(model.get_meta(ACTIVE,""))!=kind:
        return false
    var before: int=int(model.get_meta(INITIAL,current))
    if kind=="embark" and before>=CAPACITY:
        return false
    if kind=="disembark" and before<=0:
        return false
    var t: float=clampf(time,0.0,1.0)
    var open: float=(_smooth(t/0.28) if t<0.28 else
        (1.0-_smooth((t-0.78)/0.22) if t>0.78 else 1.0))
    ramp.rotation_degrees.x=lerpf(CLOSED_DEGREES,OPEN_DEGREES,open)
    var step: float=_smooth((t-0.25)/0.50)
    var moving: Node3D=_troop(root,MOVING)
    if moving==null:
        return false
    moving.visible=t<1.0
    moving.position=(START.lerp(INSIDE,step) if kind=="embark"
        else INSIDE.lerp(START,step))
    var gait: float=sin(step*TAU*2.5)*minf(1.0,sinf(PI*step)*3.0)
    moving.position.y+=absf(gait)*0.024
    moving.rotation_degrees.y=0.0 if kind=="embark" else 180.0
    moving.rotation_degrees.z=gait*1.5
    for side in [-1,1]:
        var arm: Node3D=moving.find_child("BrazoArticuladoP06V3_%d" % side,
            false,false) as Node3D
        var leg: Node3D=moving.find_child("PiernaArticuladaP06V3_%d" % side,
            false,false) as Node3D
        if arm!=null:
            arm.rotation_degrees.x=-15.0+float(side)*gait*21.0
        if leg!=null:
            leg.rotation_degrees.x=float(side)*gait*28.0
    var shown: int=before if kind=="embark" else before-1
    _show_seats(root,shown)
    if t>=1.0:
        if not bool(model.get_meta(FINISHED,false)):
            model.set_meta(COUNT,before+(1 if kind=="embark" else -1))
            model.set_meta(FINISHED,true)
        moving.visible=false
        _show_seats(root,occupants(model))
        ramp.rotation_degrees.x=CLOSED_DEGREES
    return true

static func restore(model: Node3D) -> void:
    var hull: Node3D=_apc(model)
    if hull==null:
        return
    var root: Node3D=hull.find_child(RIG_ROOT,false,false) as Node3D
    if root==null:
        return
    var moving: Node3D=_troop(root,MOVING)
    if moving!=null:
        moving.visible=false
    _show_seats(root,occupants(model))
    model.set_meta(ACTIVE,"")
    var ramp: Node3D=_ramp(model)
    if ramp!=null:
        ramp.rotation_degrees.x=OPEN_DEGREES if bool(model.get_meta("tarvoka_apc_ramp_open",false)) else CLOSED_DEGREES
