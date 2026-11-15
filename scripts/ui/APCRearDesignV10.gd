extends RefCounted
class_name TarvokaAPCRearDesignV10

# TARVOKA P06 V10 - production-detail rear troop compartment.
# Physically attached reinforcement, optical rear lamps, seats and two real
# telescopic ramp cylinders. Rendered as Godot 4.3 3D meshes, not a decal.
# All mechanics are cosmetic; crew, HP, supply and rules are untouched.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V6 = preload("res://scripts/ui/APCFinishV6.gd")
const V7 = preload("res://scripts/ui/APCDamageV7.gd")
const FLAG := "tarvoka_apc_rear_design_v10"
const ROOT := "P06V10_TraseraReal"
const RAMP_ROOT := "P06V10_RampaConBisagras"
const INTERIOR := "P06V10_CabinaPasajeros"
const REAR_SHELL := "P06V10_MarcoTrasero"
const HYDRAULICS := "P06V10_DosCilindrosHidraulicos"
const REST := "tarvoka_apc_rear_v10_links"
const STAGE := "tarvoka_apc_rear_v10_stage"
const SHOW := "tarvoka_apc_rear_v10_visible"
const HINGE := "BisagraRampaP06"

static func _group(parent: Node3D,label: String) -> Node3D:
    var n:=Node3D.new()
    n.name=label
    parent.add_child(n)
    return n

static func _steel(color: Color,metal: float=0.43,
        rough: float=0.71,lit: bool=false) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    if lit:
        m.emission_enabled=true
        m.emission=color
        m.emission_energy_multiplier=0.35
    return m

static func _box(parent: Node3D,label: String,where: Vector3,
        size: Vector3,mat: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=mesh
    node.material_override=mat
    node.position=where
    node.rotation_degrees=rotation
    parent.add_child(node)
    return node

static func _cylinder(parent: Node3D,label: String,at: Vector3,
        radius: float,height: float,mat: Material,
        turn: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=height
    shape.radial_segments=10
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.material_override=mat
    node.position=at
    node.rotation_degrees=turn
    parent.add_child(node)
    return node

static func _joint(parent: Node3D,label: String,
        mat: Material) -> MeshInstance3D:
    var shape:=SphereMesh.new()
    shape.radius=0.052
    shape.height=0.104
    shape.radial_segments=9
    shape.rings=5
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.material_override=mat
    parent.add_child(node)
    return node

static func _rear(exterior: Node3D,paint: Material,steel: Material,
        dark: Material,red: Material,amber: Material) -> void:
    var rear:=_group(exterior,REAR_SHELL)
    # Rectangular welded door surround with a clear central passage.
    # The original hollow troop opening is never sealed by an opaque panel.
    for side in [-1,1]:
        var x: float=float(side)
        _box(rear,"P06V10_MarcoBlindado_%d" % side,
            Vector3(x*0.590,0.82,1.412),
            Vector3(0.082,0.72,0.065),paint)
        _box(rear,"P06V10_BisagraFijaInferior_%d" % side,
            Vector3(x*0.445,0.438,1.439),
            Vector3(0.155,0.092,0.110),steel)
        _cylinder(rear,"P06V10_PasadorBisagra_%d" % side,
            Vector3(x*0.445,0.445,1.510),
            0.048,0.135,dark,Vector3(0,0,90))
        # Recessed two-stage exterior taillamps remain next to the opening.
        var lamps:=_group(rear,"P06V10_PilotoTrasero_%d" % side)
        _box(lamps,"P06V10_MarcoOptico_%d" % side,
            Vector3(x*0.668,1.074,1.449),
            Vector3(0.124,0.285,0.066),dark)
        _box(lamps,"P06V10_FrenoRojo_%d" % side,
            Vector3(x*0.668,1.150,1.491),
            Vector3(0.091,0.099,0.021),red)
        _box(lamps,"P06V10_IntermitenteAmbar_%d" % side,
            Vector3(x*0.668,1.018,1.491),
            Vector3(0.091,0.069,0.021),amber)
        for rail in [-1,1]:
            _box(lamps,"P06V10_ProtectorPiloto_%d_%d" % [side,rail],
                Vector3(x*0.668,1.08+float(rail)*0.111,1.518),
                Vector3(0.12,0.019,0.023),steel)
        _box(rear,"P06V10_SoporteCierre_%d" % side,
            Vector3(x*0.55,1.087,1.462),
            Vector3(0.083,0.112,0.086),dark)
    _box(rear,"P06V10_JuntaSuperiorGoma",
        Vector3(0,1.192,1.432),
        Vector3(1.02,0.028,0.035),dark)
    _box(rear,"P06V10_UmbralAceroEstriado",
        Vector3(0,0.488,1.402),
        Vector3(0.99,0.035,0.142),steel)

static func _cabin(exterior: Node3D,
        cushion: Material,steel: Material,dark: Material,
        signal_mat: Material) -> void:
    var cabin:=_group(exterior,INTERIOR)
    # Segmented seats/backs complement the approved V1/V6 benches, while
    # leaving an unobstructed central aisle for troop embarkation.
    for side in [-1,1]:
        var x: float=float(side)
        for seat in range(3):
            var z: float=0.39+float(seat)*0.295
            _box(cabin,"P06V10_CojinSoldado_%d_%d" % [side,seat],
                Vector3(x*0.367,0.713,z),
                Vector3(0.218,0.062,0.222),cushion)
            _box(cabin,"P06V10_RespaldoMoldeado_%d_%d" % [side,seat],
                Vector3(x*0.466,0.873,z),
                Vector3(0.043,0.306,0.231),cushion)
            _box(cabin,"P06V10_CinturonDiagonal_%d_%d" % [side,seat],
                Vector3(x*0.430,0.918,z),
                Vector3(0.022,0.192,0.031),
                dark,Vector3(0,0,x*17.0))
        _box(cabin,"P06V10_AsideroEnMarco_%d" % side,
            Vector3(x*0.532,1.035,1.210),
            Vector3(0.034,0.270,0.040),steel)
        _box(cabin,"P06V10_EsquinaGomaProteccion_%d" % side,
            Vector3(x*0.519,0.577,1.270),
            Vector3(0.097,0.108,0.071),dark)
    for rib in range(3):
        _box(cabin,"P06V10_NervioTechoInterior_%d" % rib,
            Vector3(0,1.335,0.34+float(rib)*0.392),
            Vector3(0.98,0.036,0.059),steel)
    _box(cabin,"P06V10_LuzDesembarqueInterior",
        Vector3(0,1.300,1.215),
        Vector3(0.24,0.023,0.068),signal_mat)
    for i in range(4):
        _box(cabin,"P06V10_GripUmbral_%d" % i,
            Vector3(0,0.518,1.316+float(i)*0.028),
            Vector3(0.78,0.012,0.013),steel)

static func _ramp(fixed: Node3D,hinge: Node3D,
        enamel: Material,steel: Material,dark: Material) -> void:
    var door:=_group(hinge,RAMP_ROOT)
    # All stripes, hinge braces and upper latches belong to the real moving
    # bottom-hinged ramp. They must never remain floating in world space.
    _box(door,"P06V10_ChapaBlindajeExteriorRampa",
        Vector3(0,0.39,-0.054),
        Vector3(0.91,0.600,0.016),enamel)
    for side in [-1,1]:
        var x: float=float(side)
        _box(door,"P06V10_CostillaRampa_%d" % side,
            Vector3(x*0.420,0.396,0.083),
            Vector3(0.051,0.622,0.052),steel)
        _box(door,"P06V10_PernoCierreMovil_%d" % side,
            Vector3(x*0.395,0.686,0.081),
            Vector3(0.071,0.086,0.071),dark)
        _box(door,"P06V10_BarraSeguridad_%d" % side,
            Vector3(x*0.378,0.173,0.091),
            Vector3(0.040,0.095,0.028),steel)
    for i in range(5):
        _box(door,"P06V10_AntideslizanteBorde_%d" % i,
            Vector3(-0.305+float(i)*0.152,0.100,0.084),
            Vector3(0.105,0.017,0.024),dark)
    # Hydraulic struts are created beneath the fixed rear scaffold, then
    # their actual telescopic length and pivot angles are solved each pose.
    var hydraulics:=_group(fixed,HYDRAULICS)
    var links: Array=[]
    var piston_mat:=_steel(Color("#abb6ba"),0.74,0.35)
    for side in [-1,1]:
        var side_root:=_group(hydraulics,
            "P06V10_Hidraulico_%d" % side)
        var housing:=_cylinder(side_root,
            "P06V10_CamisaCilindro_%d" % side,
            Vector3.ZERO,0.055,1.0,dark)
        var rod:=_cylinder(side_root,
            "P06V10_VastagoCromado_%d" % side,
            Vector3.ZERO,0.024,1.0,piston_mat)
        var body_joint:=_joint(side_root,
            "P06V10_RotulaChasis_%d" % side,steel)
        var door_joint:=_joint(side_root,
            "P06V10_RotulaPorton_%d" % side,steel)
        links.append([housing,rod,body_joint,door_joint,
            float(side)])
    # V10 never touches the hinge's own transform; it follows the V1 rig.
    fixed.set_meta(REST,links)

static func _link(cylinder: Node3D,
        start: Vector3,end: Vector3) -> void:
    var vector: Vector3=end-start
    var length: float=maxf(0.015,vector.length())
    cylinder.position=(start+end)*0.5
    cylinder.basis=Basis(Quaternion(Vector3.UP,vector.normalized()))
    cylinder.scale=Vector3(1.0,length,1.0)

static func pose(model: Node3D) -> bool:
    if model==null or not model.get_meta(FLAG,false):
        return false
    var detail: Node3D=model.find_child(ROOT,true,false) as Node3D
    var hinge: Node3D=model.find_child(HINGE,true,false) as Node3D
    if detail==null or hinge==null:
        return false
    var links: Array=detail.get_meta(REST,[])
    if links.size()!=2:
        return false
    for data in links:
        var housing: Node3D=data[0] as Node3D
        var piston: Node3D=data[1] as Node3D
        var fixed_joint: Node3D=data[2] as Node3D
        var door_joint: Node3D=data[3] as Node3D
        var side: float=float(data[4])
        var anchor:=Vector3(side*0.540,0.977,1.217)
        # The hinge is a direct V1 chassis child: transform coordinates are
        # already expressed in precisely this chassis-local reference frame.
        var end: Vector3=hinge.transform * Vector3(
            side*0.415,0.462,0.043)
        var length: float=anchor.distance_to(end)
        # A hydraulic BARREL must have a fixed metal length; only its
        # chrome piston rod telescopes. Never stretch both cylinders together.
        var bearing: Vector3=anchor+(end-anchor).normalized()*0.265
        _link(housing,anchor,bearing)
        _link(piston,bearing,end)
        fixed_joint.position=anchor
        door_joint.position=end
        if length<0.13:
            return false
    model.set_meta("tarvoka_apc_v10_hydraulic_pose_degrees",
        hinge.rotation_degrees.x)
    return true

static func apply(model: Node3D,faction_color: Color) -> bool:
    if model==null or not model.get_meta(V7.FLAG,false):
        return false
    if model.get_meta(FLAG,false):
        return false
    var hull: Node3D=model.find_child(V6.ROOT,true,false) as Node3D
    var hinge: Node3D=model.find_child(HINGE,true,false) as Node3D
    if hull==null or hinge==null:
        return false
    var root:=_group(hull,ROOT)
    var armor:=_steel(Color("#53646b").lerp(faction_color,0.52))
    var steel:=_steel(Color("#738186"),0.56,0.68)
    var dark:=_steel(Color("#222e32"),0.14,0.93)
    var cushion:=_steel(Color("#3d4d4c"),0.08,0.92)
    var red:=_steel(Color("#a92b2b"),0.12,0.33,true)
    var amber:=_steel(Color("#ce8a2e"),0.10,0.37,true)
    var lamp:=_steel(Color("#dfd5b7"),0.04,0.49,true)
    _rear(root,armor,steel,dark,red,amber)
    _cabin(root,cushion,steel,dark,lamp)
    _ramp(root,hinge,armor,steel,dark)
    # The original V1 pivot decorations were erroneously drawn at the TOP
    # of the door (y=1.23) even though its hinge really is bottom-mounted.
    # V10 provides proper pivot pins at y=0.445. Never show both sets.
    for side in [-1,1]:
        var obsolete: Node3D=model.find_child(
            "BisagraRampa_%d" % side,true,false) as Node3D
        if obsolete!=null:
            obsolete.visible=false
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    if not pose(model):
        root.free()
        model.set_meta(FLAG,false)
        return false
    return true

static func set_stage(model: Node3D,value: int) -> bool:
    if model==null or not model.get_meta(FLAG,false):
        return false
    var level: int=clampi(value,0,4)
    var enabled: bool=bool(model.get_meta(SHOW,true))
    # Lamp lenses, safe boarding hardware and upholstery should not stay
    # pristine when the whole 6x6 is torn open beyond repair.
    for side in [-1,1]:
        var light: Node3D=model.find_child(
            "P06V10_PilotoTrasero_%d" % side,true,false) as Node3D
        if light!=null:
            light.visible=enabled and level<4
    var cabin: Node3D=model.find_child(INTERIOR,true,false) as Node3D
    if cabin!=null:
        cabin.visible=enabled and level<4
    var door: Node3D=model.find_child(RAMP_ROOT,true,false) as Node3D
    if door!=null:
        door.visible=enabled and level<4
    model.set_meta(STAGE,level)
    return true

static func set_enabled(model: Node3D,value: bool) -> bool:
    if model==null or not model.get_meta(FLAG,false):
        return false
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    var door: Node3D=model.find_child(RAMP_ROOT,true,false) as Node3D
    if root!=null:
        root.visible=value
    if door!=null:
        door.visible=value
    # Comparison to old V3 restores its own old hinge art; production V10
    # instead displays only the corrected bottom pivot and moving ram.
    for side in [-1,1]:
        var obsolete: Node3D=model.find_child(
            "BisagraRampa_%d" % side,true,false) as Node3D
        if obsolete!=null:
            obsolete.visible=not value
    model.set_meta(SHOW,value)
    if value:
        set_stage(model,int(model.get_meta(STAGE,0)))
    return true
