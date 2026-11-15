extends RefCounted
class_name TarvokaAPCJointFinishV16

# P06 V16: physical 360-degree junction and proportion finishing.
# These are Godot 4.3 3D meshes, parented to the genuine V1 hull,
# rotating V12 weapon station and moving V10 ramp hinge.
# Pure presentation: never touches stats, ammo, HP, turn rules or saves.
const V15 = preload("res://scripts/ui/APCUndercarriageV15.gd")
const FLAG := "tarvoka_apc_joint_finish_v16"
const ROOT := "P06V16_UnionesCarroceria360"
const TURRET := "P06V16_JuntaTorretaGiratoria"
const RAMP := "P06V16_JuntasRampaArticulada"
const SHOW := "tarvoka_apc_v16_visible"
const STAGE := "tarvoka_apc_v16_stage"
const SIDE_BREAK := "P06V16_CordonCostadoDerechoMedio"
const FRONT_BREAK := "P06V16_RetornoGuardabarros_-1_0"

static func _group(parent: Node3D, label: String) -> Node3D:
    var group := Node3D.new()
    group.name = label
    parent.add_child(group)
    return group

static func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.name = label
    node.mesh = mesh
    node.material_override = material
    node.position = at
    node.rotation_degrees = rotation
    parent.add_child(node)
    return node

static func _seam(parent: Node3D, label: String,
        start: Vector3, finish: Vector3, radius: float,
        material: Material) -> MeshInstance3D:
    var span: Vector3 = finish - start
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = span.length()
    cylinder.radial_segments = 9
    var line := MeshInstance3D.new()
    line.name = label
    line.mesh = cylinder
    line.material_override = material
    line.position = (start + finish) * 0.5
    line.basis = Basis(Quaternion(Vector3.UP, span.normalized()))
    parent.add_child(line)
    return line

static func _ring(parent: Node3D, label: String, at: Vector3,
        inner: float, outer: float, material: Material) -> MeshInstance3D:
    var torus := TorusMesh.new()
    torus.inner_radius = inner
    torus.outer_radius = outer
    torus.rings = 18
    torus.ring_segments = 12
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = torus
    node.material_override = material
    node.position = at
    parent.add_child(node)
    return node

static func _body(root: Node3D, paint: Material,
        steel: Material, dark: Material) -> void:
    # Join the actual V11 nose corners to the roof/side shoulder.
    # A seam has physical depth but does not cover glazing or the grille.
    for side in [-1, 1]:
        var s: float = float(side)
        _seam(root, "P06V16_TransicionProa_%d" % side,
            Vector3(s*0.696,1.115,-1.252),
            Vector3(s*0.826,1.303,-0.635),0.010,steel)
        _seam(root, "P06V16_BordeTechoCostado_%d" % side,
            Vector3(s*0.829,1.310,-0.625),
            Vector3(s*0.829,1.310,1.177),0.009,paint)
        # The rear quarter now has a real angled welded return connecting
        # the sloping flank to the V10 rectangular troop-door surround.
        _seam(root, "P06V16_UnionCuartoTrasero_%d" % side,
            Vector3(s*0.826,1.305,1.174),
            Vector3(s*0.596,1.149,1.417),0.011,steel)
        _box(root, "P06V16_CartelaTrasera_%d" % side,
            Vector3(s*0.603,1.120,1.402),
            Vector3(0.089,0.041,0.075),paint,
            Vector3(0.0,s*14.0,s*9.0))
        # Three shaped wheel-arch returns continue the V11 sculpting into
        # the side armor. They are small 3D welds, not rectangular fenders.
        for axle in range(3):
            var z: float = float(V15.ROD_POSITIONS[axle])
            _seam(root,"P06V16_RetornoGuardabarros_%d_%d" % [side,axle],
                Vector3(s*0.849,0.961,z-0.211),
                Vector3(s*0.947,0.849,z-0.185),
                0.008,steel)
        # Bottom V15 panels have intentionally narrow mechanism-view gaps.
        # Thin cross-sectional end returns seal exposed plate edges without
        # hiding the genuine three differential housings or steering links.
        for index in range(2):
            var z_joint: float = -0.530 if index==0 else 0.510
            _seam(root,"P06V16_RetornoPanelV_%d_%d" % [side,index],
                Vector3(s*0.180,0.198,z_joint),
                Vector3(s*0.545,0.434,z_joint),
                0.008,steel)
    # The right central V11 plate is detached in stage 2. Its finishing
    # bead must disappear at the same time, or it floats in the empty gap.
    _seam(root,SIDE_BREAK,Vector3(0.874,1.080,-0.592),
        Vector3(0.836,1.293,-0.592),0.010,dark)

static func _moving_parts(turret: Node3D, hinge: Node3D,
        paint: Material, steel: Material, gasket: Material) -> void:
    var tower := _group(turret,TURRET)
    # Sits OUTSIDE the original V12 .271-.321 traversing bearing, but
    # traverses with the station; never fixed to the hull during aiming.
    _ring(tower,"P06V16_SelloAnilloGiro",Vector3(0,0.028,0),
        0.326,0.347,gasket)
    for side in [-1,1]:
        var s: float = float(side)
        _box(tower,"P06V16_SoporteAnillo_%d" % side,
            Vector3(s*0.294,0.053,0.146),
            Vector3(0.054,0.037,0.085),steel,
            Vector3(0,s*17.0,0))
    var door := _group(hinge,RAMP)
    # Local coordinates: these sit on the V10 outer moving ramp plate.
    # Their parent is the true lower hinge, not the world-space rear shell.
    for side in [-1,1]:
        var s: float = float(side)
        _box(door,"P06V16_PestañaBordeRampa_%d" % side,
            Vector3(s*0.470,0.393,-0.055),
            Vector3(0.025,0.578,0.028),paint)
        _box(door,"P06V16_SelloPestañaRampa_%d" % side,
            Vector3(s*0.484,0.393,-0.052),
            Vector3(0.009,0.552,0.021),gasket)
    _box(door,"P06V16_CordonUmbralMovil",Vector3(0,0.098,-0.052),
        Vector3(0.940,0.013,0.022),steel)

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model == null or not bool(model.get_meta(V15.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D = model.find_child("APC_P06_V1_Blindado6x6",true,false) as Node3D
    var turret: Node3D = model.find_child("EstacionRemotaP06",true,false) as Node3D
    var hinge: Node3D = model.find_child("BisagraRampaP06",true,false) as Node3D
    if hull==null or turret==null or hinge==null:
        return false
    var paint := _material(Color("#5c6b70").lerp(faction_color,0.51),0.39,0.77)
    var steel := _material(Color("#7a8588"),0.63,0.67)
    var gasket := _material(Color("#20292d"),0.10,0.95)
    var root := _group(hull,ROOT)
    _body(root,paint,steel,gasket)
    _moving_parts(turret,hinge,paint,steel,gasket)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return true

static func set_stage(model: Node3D, value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int = clampi(value,0,4)
    var enabled: bool = bool(model.get_meta(SHOW,true))
    for label in [ROOT,TURRET,RAMP]:
        var group: Node3D = model.find_child(label,true,false) as Node3D
        if group!=null:
            group.visible = enabled and stage<4
    var central: Node3D = model.find_child(SIDE_BREAK,true,false) as Node3D
    if central!=null:
        central.visible=enabled and stage<2
    var arch: Node3D = model.find_child(FRONT_BREAK,true,false) as Node3D
    if arch!=null:
        arch.visible=enabled and stage<3
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D, enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
