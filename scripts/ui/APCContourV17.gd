extends RefCounted
class_name TarvokaAPCContourV17

# Bastion P06 V17: sealed, faceted 360-degree production contour.
# All real 3D volumes are mounted to the existing V1 hull, traversing
# weapon station and actual lower-hinged troop ramp. Art only.
# The original V15 drive train and V16 welds remain untouched.
const V16 = preload("res://scripts/ui/APCJointFinishV16.gd")
const FLAG := "tarvoka_apc_contour_v17"
const BODY := "P06V17_CierresBlindaje360"
const STATION := "P06V17_CollarTorretaSegmentado"
const DOOR := "P06V17_CierresRampaMovil"
const SHOW := "tarvoka_apc_v17_visible"
const STAGE := "tarvoka_apc_v17_stage"
const MID_COVER := "P06V17_TapaDerechaMedia"
const FRONT_COVER := "P06V17_RebordeArcoFrontalIzquierdo"
const RIGHT_LATCH := "P06V17_CierreRampa_1"
const PAD_COUNT := 8
const AXLE_Z := [-1.04,0.0,1.07]

static func _group(parent: Node3D, label: String) -> Node3D:
    var group := Node3D.new()
    group.name = label
    parent.add_child(group)
    return group

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _box(parent: Node3D, label: String, at: Vector3,
        dimensions: Vector3, material: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var cube := BoxMesh.new()
    cube.size = dimensions
    var piece := MeshInstance3D.new()
    piece.name = label
    piece.mesh = cube
    piece.position = at
    piece.rotation_degrees = angles
    piece.material_override = material
    parent.add_child(piece)
    return piece

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        surface.add_vertex(vertex)

static func _sealed_plate(parent: Node3D, label: String,
        corners: Array[Vector3], thickness: Vector3,
        material: Material) -> MeshInstance3D:
    # Twelve actual triangles form a CLOSED, six-faced solid.
    # Both surfaces and all four bevel returns exist in model space:
    # the rear and underside cannot reveal open one-sided geometry.
    var underside: Array[Vector3] = []
    for vertex in corners:
        underside.append(vertex + thickness)
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    _quad(surface,corners[0],corners[1],corners[2],corners[3])
    _quad(surface,underside[3],underside[2],underside[1],underside[0])
    for edge in range(4):
        var following: int = (edge+1)%4
        _quad(surface,corners[edge],underside[edge],
            underside[following],corners[following])
    surface.generate_normals()
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = surface.commit()
    part.material_override = material
    parent.add_child(part)
    return part

static func _body(hull: Node3D, color: Material,
        brushed: Material, gasket: Material) -> void:
    var finish := _group(hull,BODY)
    for side in [-1,1]:
        var s: float = float(side)
        # Replaces the visual gap between pointed glacis and sloping
        # shoulder with a sealed narrow bevel; keeps driver optics clear.
        _sealed_plate(finish,"P06V17_PiezaTransicionProa_%d" % side,
            [
                Vector3(s*0.686,1.112,-1.239),
                Vector3(s*0.819,1.293,-0.646),
                Vector3(s*0.837,1.227,-0.638),
                Vector3(s*0.704,1.045,-1.243)
            ],Vector3(s*0.018,0.008,0.002),color)
        # A full enclosed rear quarter rather than a single round weld
        # between the roof shoulder and the V10 troop door surround.
        # Inner edge stops outside the 0.49m opening and its lamps.
        _sealed_plate(finish,"P06V17_CuartonTrasero_%d" % side,
            [
                Vector3(s*0.807,1.299,1.154),
                Vector3(s*0.611,1.159,1.401),
                Vector3(s*0.584,1.046,1.402),
                Vector3(s*0.790,1.132,1.150)
            ],Vector3(s*0.026,0.006,0.010),color)
        _box(finish,"P06V17_RefuerzoCierreFijo_%d" % side,
            Vector3(s*0.546,1.101,1.426),
            Vector3(0.078,0.105,0.043),brushed,
            Vector3(0,0,s*4.0))
        # The wheel-opening return remains small and deliberately does not
        # obstruct V14 knuckles, rubber or moving tire body.
        for axle in range(3):
            var z: float = float(AXLE_Z[axle])
            var label: String = FRONT_COVER if side==-1 and axle==0 else (
                "P06V17_RebordeArco_%d_%d" % [side,axle])
            _sealed_plate(finish,label,[
                Vector3(s*0.851,0.955,z-0.208),
                Vector3(s*0.936,0.852,z-0.176),
                Vector3(s*0.945,0.824,z-0.176),
                Vector3(s*0.865,0.918,z-0.208)
            ],Vector3(s*0.012,0.002,0.0),brushed)
    # The corresponding V11 right-middle armor plate tears off at
    # moderate damage, so its newly fitted service lid must tear away too.
    _sealed_plate(finish,MID_COVER,[
        Vector3(0.867,1.212,-0.509),
        Vector3(0.867,1.212,-0.284),
        Vector3(0.891,1.100,-0.284),
        Vector3(0.891,1.100,-0.509)
    ],Vector3(0.011,0,0),gasket)

static func _station(turret: Node3D, paint: Material,
        metal: Material) -> void:
    var collar := _group(turret,STATION)
    # Eight individual swept *solid* sectors surround V12's original
    # bearing. Each segment overlaps the V16 gasket's outer lip slightly;
    # the original rotating 3D station remains the only animation pivot.
    for sector in range(PAD_COUNT):
        var start: float = TAU*float(sector)/float(PAD_COUNT)+0.055
        var finish: float = TAU*float(sector+1)/float(PAD_COUNT)-0.055
        var inner: float = 0.339
        var outer: float = 0.396
        var y: float = 0.053
        _sealed_plate(collar,"P06V17_SegmentoAnillo_%d" % sector,[
            Vector3(inner*cos(start),y,inner*sin(start)),
            Vector3(outer*cos(start),y,outer*sin(start)),
            Vector3(outer*cos(finish),y,outer*sin(finish)),
            Vector3(inner*cos(finish),y,inner*sin(finish))
        ],Vector3(0,-0.027,0),paint)
        var angle: float = 0.5*(start+finish)
        var bolt := CylinderMesh.new()
        bolt.top_radius = 0.012
        bolt.bottom_radius = 0.012
        bolt.height = 0.012
        bolt.radial_segments = 6
        var fastener := MeshInstance3D.new()
        fastener.name = "P06V17_PernoCollar_%d" % sector
        fastener.mesh = bolt
        fastener.position = Vector3(0.375*cos(angle),0.064,
            0.375*sin(angle))
        fastener.material_override = metal
        collar.add_child(fastener)

static func _ramp(hinge: Node3D, armor: Material,
        metal: Material, gasket: Material) -> void:
    var door := _group(hinge,DOOR)
    # Full top seal and two real locking catches rotate with the moving
    # V10 door. No static hatch detail floats during 8°..78° movement.
    _box(door,"P06V17_JuntaSuperiorRampa",
        Vector3(0,0.704,-0.052),
        Vector3(0.931,0.018,0.030),gasket)
    for side in [-1,1]:
        var s: float = float(side)
        _box(door,"P06V17_CantoneraSuperior_%d" % side,
            Vector3(s*0.439,0.697,-0.065),
            Vector3(0.071,0.050,0.048),armor)
        _box(door,"P06V17_CierreRampa_%d" % side,
            Vector3(s*0.390,0.672,-0.092),
            Vector3(0.079,0.065,0.047),metal)
        _box(door,"P06V17_PasadorCierre_%d" % side,
            Vector3(s*0.385,0.672,-0.121),
            Vector3(0.035,0.018,0.019),gasket)

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V16.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D = model.find_child("APC_P06_V1_Blindado6x6",true,false) as Node3D
    var turret: Node3D = model.find_child("EstacionRemotaP06",true,false) as Node3D
    var hinge: Node3D = model.find_child("BisagraRampaP06",true,false) as Node3D
    if hull==null or turret==null or hinge==null:
        return false
    var paint := _mat(Color("#58676a").lerp(faction_color,0.57),0.36,0.79)
    var steel := _mat(Color("#818c90"),0.64,0.63)
    var gasket := _mat(Color("#273034"),0.12,0.95)
    _body(hull,paint,steel,gasket)
    _station(turret,paint,steel)
    _ramp(hinge,paint,steel,gasket)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return true

static func set_stage(model: Node3D, value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int = clampi(value,0,4)
    var enabled: bool = bool(model.get_meta(SHOW,true))
    for name in [BODY,STATION,DOOR]:
        var group: Node3D = model.find_child(name,true,false) as Node3D
        if group!=null:
            group.visible=enabled and stage<4
    var right: Node3D = model.find_child(MID_COVER,true,false) as Node3D
    if right!=null:
        right.visible=enabled and stage<2
    var front: Node3D = model.find_child(FRONT_COVER,true,false) as Node3D
    if front!=null:
        front.visible=enabled and stage<3
    var latch: Node3D = model.find_child(RIGHT_LATCH,true,false) as Node3D
    if latch!=null:
        latch.visible=enabled and stage<3
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D, enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
