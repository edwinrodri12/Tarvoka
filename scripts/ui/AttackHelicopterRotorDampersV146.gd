extends RefCounted
class_name TarvokaAttackHelicopterRotorDampersV146

# HAT-29 V14.6: high-detail, ART-ONLY transmission isolation and
# blade-root vibration dampers. Original V1 rotor pivots and V3 swashplate,
# V10 crown, V14.5 mounts/bolts are reused and never displaced or replaced.
# No animation clocks, physics simulation, faction enamel or battle LOD work.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const Mount=preload("res://scripts/ui/AttackHelicopterRotorMountV145.gd")
const FLAG="tarvoka_a01_rotor_dampers_v146"
const FIXED="A01V146_AisladoresVibracionMastil"
const SPINNING="A01V146_AmortiguadoresPasoRotor"
const DAMPER="A01V146_AmortiguadorAspa_"
const ELASTOMER=Color("#2a3438")
const ALLOY=Color("#839198")
const PISTON=Color("#b0b9b7")
const HOUSING=Color("#49585f")

static func _part(root: Node3D,name: String) -> Node3D:
    return root.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if _part(model,FIXED)==null or _part(model,SPINNING)==null:
        return false
    for i in range(4):
        if _part(model,DAMPER+str(i))==null:
            return false
    return true

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _material(color: Color,metal: float,rough: float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    return mat

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        at: Vector3,color: Color,metal: float=0.63,
        rough: float=0.48) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.position=at
    n.material_override=_material(color,metal,rough)
    parent.add_child(n)
    return n

static func _box(parent: Node3D,name: String,at: Vector3,
        size: Vector3,color: Color,metal: float=0.55,
        rough: float=0.50) -> MeshInstance3D:
    var box:=BoxMesh.new()
    box.size=size
    return _mesh(parent,name,box,at,color,metal,rough)

static func _cylinder(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,
        color: Color,metal: float=0.70,
        rough: float=0.42) -> MeshInstance3D:
    var axis: Vector3=b-a
    var tube:=CylinderMesh.new()
    tube.top_radius=radius
    tube.bottom_radius=radius
    tube.height=axis.length()
    tube.radial_segments=12
    var mesh:=_mesh(parent,name,tube,(a+b)*0.5,color,metal,rough)
    mesh.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return mesh

static func _eye(parent: Node3D,name: String,
        at: Vector3,color: Color) -> MeshInstance3D:
    var round:=SphereMesh.new()
    round.radius=0.031
    round.height=0.062
    round.radial_segments=12
    round.rings=7
    return _mesh(parent,name,round,at,color,0.62,0.48)

static func _fixed_isolators(body: Node3D) -> void:
    # V14.5 already attaches four diagonal mast braces at X +/- 0.385
    # and Z +/- 0.30; these thin elastomer pads bridge their feet.
    # Body-local coordinates keep them stationary during blade spin.
    var group:=_group(body,FIXED)
    for side in [-1,1]:
        for fore in [-1,1]:
            var sx: float=float(side)
            var sz: float=float(fore)
            var anchor:=Vector3(sx*0.385,1.54,0.08+sz*0.30)
            var name: String="%d_%d" % [side,fore]
            _box(group,"A01V146_BloqueElastomero_"+name,
                anchor+Vector3(0,-0.020,0),
                Vector3(0.105,0.028,0.100),ELASTOMER,0.03,0.91)
            _box(group,"A01V146_PlacaAislante_"+name,
                anchor+Vector3(0,-0.040,0),
                Vector3(0.112,0.012,0.108),ALLOY,0.61,0.48)

static func _rotor_couplings(rotor: Node3D) -> bool:
    # A four-point retaining cage rotating with the V1 original head.
    # The 4 blade-root dampers live INSIDE their original arm pivots;
    # no independent rotor turn or second animated swashplate is created.
    var group:=_group(rotor,SPINNING)
    for i in range(4):
        var pivot: Node3D=_part(rotor,V3.LEGACY_ROTOR+str(i))
        if pivot==null:
            return false
        var damper:=_group(pivot,DAMPER+str(i))
        # Offset laterally from the existing V14.5 central blade pin.
        # Each assembly has a dark hydraulic barrel, polished ram,
        # two eyelets and a rubber dust sleeve visible at macro scale.
        var mount_start:=Vector3(0.116,0.083,-0.188)
        var barrel_end:=Vector3(0.116,0.077,-0.325)
        var piston_end:=Vector3(0.116,0.066,-0.425)
        _cylinder(damper,"A01V146_CuerpoHidraulico_%d" % i,
            mount_start,barrel_end,0.026,HOUSING,0.51,0.57)
        _cylinder(damper,"A01V146_VarillaCromada_%d" % i,
            barrel_end,piston_end,0.011,PISTON,0.76,0.31)
        _cylinder(damper,"A01V146_FuelleGoma_%d" % i,
            Vector3(0.116,0.077,-0.296),
            Vector3(0.116,0.076,-0.347),
            0.030,ELASTOMER,0.02,0.93)
        _eye(damper,"A01V146_OjalInterior_%d" % i,mount_start,ALLOY)
        _eye(damper,"A01V146_OjalExterior_%d" % i,piston_end,ALLOY)
        # Pair of slim blade-hub retaining links adjacent to, not replacing,
        # the articulated lever from V14.5.
        var a: float=TAU*float(i)/4.0
        var outward:=Vector3(sin(a),0,cos(a))
        _cylinder(group,"A01V146_BieletaAntivibracion_%d" % i,
            outward*0.245+Vector3(0,-0.036,0),
            outward*0.345+Vector3(0,-0.075,0),
            0.010,ALLOY,0.67,0.42)
    return true

static func apply(model: Node3D) -> bool:
    if not Mount.has_model(model) or not V3.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_part(model,V1.ROOT)
    var rotor: Node3D=_part(model,V1.MAIN_ROTOR)
    if body==null or rotor==null:
        return false
    for i in range(4):
        if _part(rotor,V3.LEGACY_ROTOR+str(i))==null:
            return false
    _fixed_isolators(body)
    if not _rotor_couplings(rotor):
        return false
    model.set_meta(FLAG,true)
    return true
