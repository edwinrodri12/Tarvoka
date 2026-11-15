extends RefCounted
class_name TarvokaAPCTacticalLOD8

# P06 V8 tactical/mobile mesh: SAME V1 armored 6x6 hull silhouette as hero V7.
# Six real wheels are TWO MultiMesh draws, never six boxes or anonymous discs.
# Separate studio V7 retains the full interior, damage and muzzle VFX.
# This is visual only: gameplay units, fog, movement, ammo and HP do not change.
const Sculpt = preload("res://scripts/ui/APCArtV1.gd")
const FLAG := "tarvoka_apc_tactical_lod_v8"
const ROOT := "P06V8_BastionTactico6x6"
const WHEELS := "P06V8_SeisRuedasInstanciadas"
const HUBS := "P06V8_SeisBujesInstanciados"
const TURRET := "P06V8_TorretaRemota"
const GUN := "P06V8_ArmaEstabilizada"
const RAMP := "P06V8_RampaTropas"
const BASE := "tarvoka_apc_lod8_rest"
const LAST := "tarvoka_apc_lod8_last_pose"
const WHEEL_TURNS := TAU*1.7
const MAX_DRAW_SURFACES := 15
static var _wheel_mesh: CylinderMesh
static var _hub_mesh: CylinderMesh
static var _wheel_mat: StandardMaterial3D
static var _hub_mat: StandardMaterial3D
static var _black_mat: StandardMaterial3D
static var _glass_mat: StandardMaterial3D
static var _cached_armor: Dictionary = {}

static func _color(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _resources() -> void:
    if _wheel_mesh!=null:
        return
    _wheel_mesh=CylinderMesh.new()
    _wheel_mesh.top_radius=Sculpt.WHEEL_RADIUS
    _wheel_mesh.bottom_radius=Sculpt.WHEEL_RADIUS
    _wheel_mesh.height=0.235
    _wheel_mesh.radial_segments=14
    _hub_mesh=CylinderMesh.new()
    _hub_mesh.top_radius=0.218
    _hub_mesh.bottom_radius=0.218
    _hub_mesh.height=0.018
    _hub_mesh.radial_segments=12
    _wheel_mat=_color(Color("#252a2c"),0.05,0.95)
    _hub_mat=_color(Color("#566168"),0.55,0.73)
    _black_mat=_color(Color("#1d282e"),0.16,0.86)
    _glass_mat=_color(Color("#406c81"),0.08,0.26)

static func _armor_material(faction_color: Color) -> StandardMaterial3D:
    # Official faction paint is isolated per faction; tires and hubs are
    # shared across models but never recolored or mutated in place.
    var key: String=faction_color.to_html()
    if not _cached_armor.has(key):
        _cached_armor[key]=_color(
            Color("#526166").lerp(faction_color,0.52),0.31,0.83)
    return _cached_armor[key] as StandardMaterial3D

static func _box(parent: Node3D,label: String,pos: Vector3,
        size: Vector3,material: Material) -> MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=label
    var cube:=BoxMesh.new()
    cube.size=size
    part.mesh=cube
    part.material_override=material
    part.position=pos
    parent.add_child(part)
    return part

static func _wheels(parent: Node3D,label: String,mesh: Mesh,
        mat: Material,hub_offset: float=0.0) -> MultiMeshInstance3D:
    var renderer:=MultiMeshInstance3D.new()
    renderer.name=label
    var instances:=MultiMesh.new()
    instances.transform_format=MultiMesh.TRANSFORM_3D
    instances.mesh=mesh
    instances.instance_count=6
    for side_index in range(2):
        var side: float=-1.0 if side_index==0 else 1.0
        for axle in range(3):
            var i: int=side_index*3+axle
            var pos:=Vector3(side*(Sculpt.WHEEL_X+hub_offset),
                Sculpt.WHEEL_RADIUS+0.08,float(Sculpt.WHEEL_Z[axle]))
            instances.set_instance_transform(i,Transform3D(
                Basis(Vector3.FORWARD,PI/2.0),pos))
    renderer.multimesh=instances
    renderer.material_override=mat
    parent.add_child(renderer)
    return renderer

static func build(model: Node3D, faction_color: Color) -> bool:
    if model==null or bool(model.get_meta(FLAG,false)):
        return false
    _resources()
    var root:=Node3D.new()
    root.name=ROOT
    model.add_child(root)
    var armor: Material=_armor_material(faction_color)
    # Identical five-cross-section welded nose, roof and rear cross section
    # used by the highly detailed version, not a generic APC cuboid.
    Sculpt._hull(root,armor)
    var tires: MultiMeshInstance3D=_wheels(root,WHEELS,_wheel_mesh,_wheel_mat)
    _wheels(root,HUBS,_hub_mesh,_hub_mat,0.145)
    for side in [-1,1]:
        var x: float=float(side)
        _box(root,"P06V8_FaldonLateral_%d" % side,
            Vector3(x*0.755,0.99,0.04),Vector3(0.083,0.13,2.10),
            armor)
        _box(root,"P06V8_VisorConductor_%d" % side,
            Vector3(x*0.255,1.235,-1.035),Vector3(0.27,0.074,0.040),
            _glass_mat)
    _box(root,RAMP,Vector3(0,0.82,1.39),
        Vector3(0.95,0.61,0.068),armor)
    var remote:=Node3D.new()
    remote.name=TURRET
    remote.position=Vector3(0,1.53,-0.16)
    root.add_child(remote)
    var base_cylinder:=CylinderMesh.new()
    base_cylinder.top_radius=0.28
    base_cylinder.bottom_radius=0.28
    base_cylinder.height=0.073
    base_cylinder.radial_segments=12
    Sculpt._part(remote,"P06V8_AnilloTorreta",base_cylinder,
        _black_mat)
    _box(remote,"P06V8_CorazaTorreta",Vector3(0,0.205,0),
        Vector3(0.44,0.31,0.50),armor)
    _box(remote,"P06V8_OpticaTorreta",
        Vector3(0.27,0.27,-0.235),Vector3(0.12,0.10,0.06),
        _glass_mat)
    var gun:=Node3D.new()
    gun.name=GUN
    gun.position=Vector3(-0.02,0.20,-0.27)
    remote.add_child(gun)
    var barrel:=CylinderMesh.new()
    barrel.top_radius=0.048
    barrel.bottom_radius=0.048
    barrel.height=0.53
    barrel.radial_segments=10
    Sculpt._part(gun,"P06V8_CanonCorto",
        barrel,_black_mat,Vector3(0,0,-0.30),Vector3(90,0,0))
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_apc_lod8_wheel_count",6)
    model.set_meta("tarvoka_apc_lod8_faction_color",faction_color)
    model.set_meta("tarvoka_apc_lod8_render_surfaces",draw_surfaces(model))
    model.set_meta(BASE,model.position)
    return tires.multimesh.instance_count==6

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func draw_surfaces(model: Node3D) -> int:
    if model==null:
        return 0
    var count: int=0
    for node in model.find_children("*","MeshInstance3D",true,false):
        count+=1
    for node in model.find_children("*","MultiMeshInstance3D",true,false):
        count+=1
    return count

static func pose(model: Node3D,kind: String,progress: float,
        heading: Vector2i=Vector2i(0,-1)) -> bool:
    if not has_model(model):
        return false
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    if root==null:
        return false
    var t: float=clampf(progress,0.0,1.0)
    var base_pos: Vector3=model.get_meta(BASE,model.position)
    model.position=base_pos
    var remote: Node3D=root.find_child(TURRET,false,false) as Node3D
    var tires: MultiMeshInstance3D=root.find_child(
        WHEELS,false,false) as MultiMeshInstance3D
    var gun: Node3D=root.find_child(GUN,true,false) as Node3D
    if remote==null or tires==null or gun==null:
        return false
    remote.rotation_degrees.y=0.0
    gun.rotation_degrees.x=0.0
    if kind=="move":
        # Six transforms are changed IN PLACE, no mesh allocations per frame.
        for i in range(6):
            var side: float=-1.0 if i<3 else 1.0
            var axle: int=i%3
            var at:=Vector3(side*Sculpt.WHEEL_X,Sculpt.WHEEL_RADIUS+0.08,
                float(Sculpt.WHEEL_Z[axle]))
            tires.multimesh.set_instance_transform(i,Transform3D(
                Basis(Vector3.FORWARD,PI/2.0) *
                Basis(Vector3.UP,WHEEL_TURNS*t),at))
        model.position.y=base_pos.y+0.014*sin(TAU*t*3.0)
    elif kind=="attack":
        # Distanced shots retain six short separate weapon kicks, no
        # glowing V7 muzzle particles or individual shell actors.
        var shot: float=-1.0
        for i in range(6):
            var age: float=t-(0.25+float(i)*0.108)
            if age>=0.0 and age<0.08:
                shot=maxf(shot,1.0-age/0.08)
        remote.rotation_degrees.y=rad_to_deg(
            atan2(float(heading.x),-float(heading.y)))*0.37
        gun.rotation_degrees.x= -0.80*maxf(0.0,shot)
    elif kind=="idle":
        pass
    elif kind in ["hit_bullet","hit_explosive"]:
        model.position.y=base_pos.y+0.014*sin(PI*t*4.0)*(1.0-t)
    model.set_meta(LAST,kind)
    return true

static func restore(model: Node3D) -> void:
    if has_model(model):
        pose(model,"idle",1.0)
