extends RefCounted
class_name TarvokaAttackHelicopterRotorMountV145

# V14.5 HAT-29: structural connection between the fixed fuselage and the
# spinning V1/V3 main rotor, exclusively in the native high-detail hero.
# V10 already contains a hub crown and V3 a swashplate/pitch linkage.
# This layer fills their surrounding mechanical gaps without replacing them.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const FLAG="tarvoka_a01_main_rotor_mount_v145"
const FIXED="A01V145_SoportesFijosMastil"
const SPINNING="A01V145_HerrajesRotorGiratorio"
const ARM_PIN="A01V145_SeguroPasoPala_"
const ARM_LINK="A01V145_RefuerzoPasoPala_"

static func _node(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _node(model,FIXED)!=null and _node(model,SPINNING)!=null)

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _metal(color: Color,metallic: float=0.57,
        roughness: float=0.52) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    return m

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        pos: Vector3,color: Color,metallic: float=0.57,
        roughness: float=0.52) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.position=pos
    n.material_override=_metal(color,metallic,roughness)
    parent.add_child(n)
    return n

static func _bar(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,color: Color) -> MeshInstance3D:
    var axis: Vector3=b-a
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=axis.length()
    cylinder.radial_segments=10
    var piece: MeshInstance3D=_mesh(
        parent,name,cylinder,(a+b)*0.5,color)
    piece.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return piece

static func _ring(parent: Node3D,name: String,
        pos: Vector3,inner: float,outer: float,color: Color) -> MeshInstance3D:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=10
    mesh.ring_segments=28
    return _mesh(parent,name,mesh,pos,color,0.67,0.43)

static func _box(parent: Node3D,name: String,
        pos: Vector3,size: Vector3,color: Color) -> void:
    var mesh:=BoxMesh.new()
    mesh.size=size
    _mesh(parent,name,mesh,pos,color,0.55,0.52)

static func _bolt(parent: Node3D,name: String,
        pos: Vector3,radius: float=0.017) -> void:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=0.025
    mesh.radial_segments=6
    _mesh(parent,name,mesh,pos,Color("#a6b3b7"),0.68,0.40)

static func _fixed_housing(body: Node3D) -> void:
    # These pieces belong to the AIRFRAME, never the spinning rotor node.
    # Mast center is body-local (0,1.75,0.08); V1's original housing is
    # retained untouched. Structural tie bars end beside it, not inside it.
    var mount:=_group(body,FIXED)
    var graphite:=Color("#39474d")
    var steel:=Color("#87979d")
    _ring(mount,"A01V145_AnilloSelloInferior",
        Vector3(0,1.610,0.08),0.202,0.240,graphite)
    for band in range(2):
        _ring(mount,"A01V145_CollarFijo_%d" % band,
            Vector3(0,1.704+float(band)*0.075,0.08),
            0.199,0.221,steel)
    for side in [-1,1]:
        for fore in [-1,1]:
            var sx: float=float(side)
            var sz: float=float(fore)
            var base:=Vector3(sx*0.385,1.54,0.08+sz*0.30)
            var upper:=Vector3(sx*0.205,1.78,0.08+sz*0.125)
            _bar(mount,"A01V145_RiostraMastil_%d_%d" % [side,fore],
                base,upper,0.023,graphite)
            _box(mount,"A01V145_ZapataRiostra_%d_%d" % [side,fore],
                base,Vector3(0.114,0.034,0.114),steel)
            _bolt(mount,"A01V145_PernoZapata_%d_%d" % [side,fore],
                base+Vector3(0,0.031,0),0.019)

static func _rotating_hardware(rotor: Node3D) -> void:
    # Rotor origin is body-local (0,1.97,0.08). Every piece below follows
    # its original pivot while the fixed mast remains stationary.
    var mount:=_group(rotor,SPINNING)
    var steel:=Color("#8a9ca1")
    var graphite:=Color("#34424a")
    _ring(mount,"A01V145_CoronaGiratoriaExterior",
        Vector3(0,0.044,0),0.269,0.308,steel)
    for index in range(4):
        var angle: float=TAU*float(index)/4.0
        var direction:=Vector3(sin(angle),0,cos(angle))
        _bar(mount,"A01V145_BrazoDePaso_%d" % index,
            direction*0.235+Vector3(0,0.067,0),
            direction*0.332+Vector3(0,-0.010,0),0.013,graphite)
        _bolt(mount,"A01V145_PernoCorona_%d" % index,
            direction*0.284+Vector3(0,0.079,0),0.018)

static func _blade_hinges(rotor: Node3D) -> bool:
    # Four V1 blade pivots already rotate with the real V3 head.
    for i in range(4):
        var arm: Node3D=_node(rotor,V3.LEGACY_ROTOR+str(i))
        if arm==null:
            return false
        _bolt(arm,ARM_PIN+str(i),Vector3(0,0.096,-0.198),0.035)
        _bar(arm,ARM_LINK+str(i),
            Vector3(0,0.078,-0.204),
            Vector3(0,0.027,-0.292),0.013,Color("#7f9298"))
    return true

static func apply(model: Node3D) -> bool:
    if not V3.has_model(model) or not V10.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_node(model,V1.ROOT)
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if body==null or rotor==null:
        return false
    for i in range(4):
        if _node(rotor,V3.LEGACY_ROTOR+str(i))==null:
            return false
    _fixed_housing(body)
    _rotating_hardware(rotor)
    if not _blade_hinges(rotor):
        return false
    model.set_meta(FLAG,true)
    return true
