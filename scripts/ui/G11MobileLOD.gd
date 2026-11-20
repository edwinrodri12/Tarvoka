extends RefCounted
class_name TarvokaG11MobileLOD

# G11 tactical presentation: two native Godot LODs with shared geometry.
# Does not change tactical speed, combat ranges, costs, ammunition or HP.
# 12 launcher tubes are a single MultiMesh (not 12 draw calls).
const FLAG := "tarvoka_g11_mobile_lod"
const POD := "CestaLanzacohetesElevada"
const ROTATOR := "G11Mobile_Giro"
const TUBES := 12
const WHEELS := 12
const FAR_LEVEL := 8
const NEAR_LEVEL := 10
# Prototype: fewer radial sides on repeated rocket tubes, preserving 12 mouths.
const TUBE_RADIAL_SEGMENTS := 8
const TacticalV24 = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const PodV25 = preload("res://scripts/ui/G11RocketFaceReadabilityV25.gd")
const PaintV27 = preload("res://scripts/ui/G11TacticalPaintReadabilityV27.gd")
const RearV30 = preload("res://scripts/ui/G11RearUndercarriageV30.gd")
const GearV32 = preload("res://scripts/ui/G11RunningGearV32.gd")
static var _materials: Dictionary = {}

static func recommended_level(distance: float, visible_units: int,
        high_quality: bool = false) -> int:
    # Visual hint for consumer renderers; never changes unit gameplay.
    if not high_quality and (distance > 10.0 or visible_units >= 40):
        return FAR_LEVEL
    return NEAR_LEVEL

static func _mat(color: Color, metallic: float = 0.18,
        roughness: float = 0.73) -> StandardMaterial3D:
    # Cache by palette/material properties to avoid a new PBR resource
    # for every vehicle in an eight-player match.
    var key: String = "%s_%s_%s" % [color.to_html(),str(metallic),str(roughness)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    _materials[key] = m
    return m

static func _box(parent: Node3D, title: String, center: Vector3,
        size: Vector3, material: Material) -> MeshInstance3D:
    var out := MeshInstance3D.new()
    out.name = title
    var primitive := BoxMesh.new()
    primitive.size = size
    out.mesh = primitive
    out.material_override = material
    out.position = center
    parent.add_child(out)
    return out

static func _multi_cylinder(parent: Node3D, title: String,
        count: int, radius: float, height: float,
        material: Material, radial_segments: int) -> MultiMesh:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = radial_segments
    mesh.material = material
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = mesh
    multi.instance_count = count
    var inst := MultiMeshInstance3D.new()
    inst.name = title
    inst.multimesh = multi
    parent.add_child(inst)
    return multi

static func build(model: Node3D, faction_color: Color,
        detail: int = NEAR_LEVEL) -> bool:
    if model == null or model.has_meta(FLAG):
        return false
    var close: bool = detail >= NEAR_LEVEL
    var steel: StandardMaterial3D = _mat(Color("#697a7b"),0.34,0.69)
    var armor: StandardMaterial3D = _mat(Color("#8b9894"),0.23,0.75)
    var rubber: StandardMaterial3D = _mat(Color("#242b2e"),0.03,0.93)
    var metal: StandardMaterial3D = _mat(Color("#a5afad"),0.59,0.45)
    var glass: StandardMaterial3D = _mat(Color("#3a687d"),0.07,0.31)
    var paint: StandardMaterial3D = _mat(faction_color,0.20,0.74)
    var dark: StandardMaterial3D = _mat(Color("#1e292b"),0.19,0.78)
    # Full chassis, independently sealed from the launcher module.
    _box(model,"ChasisLanzacohetes",Vector3(0,0.68,0.02),
        Vector3(1.45,0.62,2.67),steel)
    _box(model,"G11Mobile_CabinaCerrada",Vector3(0,1.14,-0.83),
        Vector3(1.23,0.69,0.94),armor)
    _box(model,"G11Mobile_Parabrisas",Vector3(0,1.34,-1.319),
        Vector3(0.90,0.27,0.027),glass)
    _box(model,"G11Mobile_Techo",Vector3(0,1.54,-0.84),
        Vector3(1.22,0.07,0.89),steel)
    _box(model,"G11Mobile_Plataforma",Vector3(0,1.04,0.66),
        Vector3(1.30,0.14,1.28),dark)
    _box(model,"G11Mobile_InsigniaFrontal",Vector3(0,1.59,-0.95),
        Vector3(0.34,0.028,0.19),paint)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(model,"G11Mobile_Oruga_%d" % side,
            Vector3(sign*0.77,0.34,-0.06),
            Vector3(0.31,0.57,2.55),rubber)
        _box(model,"G11Mobile_Faldon_%d" % side,
            Vector3(sign*0.77,0.64,0),
            Vector3(0.35,0.19,2.45),steel)
        _box(model,"G11Mobile_PinturaCostado_%d" % side,
            Vector3(sign*0.959,0.68,0.22),
            Vector3(0.015,0.075,0.74),paint)
    # All twelve roadwheels rendered in one GPU MultiMesh batch.
    if close:
        var wheels: MultiMesh = _multi_cylinder(model,
            "G11Mobile_Lote12Ruedas",WHEELS,0.16,0.075,metal,10)
        var index: int = 0
        for side in [-1,1]:
            for axle in range(6):
                wheels.set_instance_transform(index,
                    Transform3D(Basis(Vector3.FORWARD,PI*0.5),
                        Vector3(float(side)*0.959,0.25,-1.12+float(axle)*0.435)))
                index += 1
    var rotator := Node3D.new()
    rotator.name = ROTATOR
    rotator.position = Vector3(0,1.25,0.43)
    model.add_child(rotator)
    _box(rotator,"G11Mobile_BaseGiro",Vector3(0,0.10,0),
        Vector3(1.04,0.25,0.82),steel)
    var pod := Node3D.new()
    pod.name = POD
    # V25: rear-facing rocket mouths must elevate toward an overhead camera.
    # Positive X tipped the +Z muzzles down into the body; use -25 degrees.
    pod.rotation_degrees.x = -25.0
    pod.position = Vector3(0,0.32,0.04)
    rotator.add_child(pod)
    _box(pod,"BloqueLanzador",Vector3(0,0,0.10),
        Vector3(1.16,0.86,1.32),dark)
    _box(pod,"G11Mobile_MarcaModulo",Vector3(0,0.48,0.10),
        Vector3(0.85,0.055,0.94),paint)
    var tube_multimesh: MultiMesh = _multi_cylinder(pod,
        "G11Mobile_Lote12Tubos",TUBES,0.097,0.18,rubber,TUBE_RADIAL_SEGMENTS)
    var rims: MultiMesh = null
    if close:
        rims = _multi_cylinder(pod,"G11Mobile_Lote12Bordes",
            TUBES,0.110,0.025,metal,TUBE_RADIAL_SEGMENTS)
    var tube_basis := Basis(Vector3.RIGHT,PI*0.5)
    for column in range(4):
        for row in range(3):
            var index: int = column*3+row
            var x: float = -0.42+float(column)*0.28
            var y: float = -0.26+float(row)*0.25
            tube_multimesh.set_instance_transform(index,
                Transform3D(tube_basis,Vector3(x,y,-0.61)))
            if rims != null:
                rims.set_instance_transform(index,
                    Transform3D(tube_basis,Vector3(x,y,-0.714)))
    model.set_meta(FLAG,detail)
    model.set_meta("tarvoka_g11_mobile_tubes",TUBES)
    if not TacticalV24.apply(model,close):
        push_warning("G11 V24 tactical track visual refinement could not be applied")
    elif not PodV25.apply(model):
        push_warning("G11 V25 recognizable 12-mouth tactical pod failed; retaining V24 tubes")
    elif not PaintV27.apply(model):
        push_warning("G11 V27 faction enamel could not fit original tactical guard geometry")
    elif not RearV30.apply_mobile(model):
        push_warning("G11 V30 underbody failed to clear original mobile tracks")
    return true

static func has_model(model: Node3D) -> bool:
    return model != null and model.has_meta(FLAG) and model.find_child(
        POD,true,false) != null

static func pose(model: Node3D, kind: String, progress: float,
        target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_model(model):
        return false
    var rotator: Node3D = model.find_child(ROTATOR,true,false) as Node3D
    var pod: Node3D = model.find_child(POD,true,false) as Node3D
    var t: float = clampf(progress,0.0,1.0)
    match kind:
        "attack", "fire":
            var desired_yaw: float = rad_to_deg(
                atan2(-float(target_heading.x),-float(target_heading.y)))
            rotator.rotation_degrees.y = desired_yaw*t
            pod.rotation_degrees.x = -25.0-12.0*t
        "move":
            pod.rotation_degrees.x = -25.0+sin(t*TAU*2.0)*0.5
            if not GearV32.pose_mobile(model,t,target_heading,
                    float(model.get_meta(GearV32.SLOPE,0.0))):
                return false
        "idle":
            rotator.rotation_degrees = Vector3.ZERO
            pod.rotation_degrees = Vector3(-25,0,0)
            if model.has_meta(GearV32.REST_ANGLE):
                GearV32.restore_mobile(model)
        _:
            return false
    return true

static func restore(model: Node3D) -> void:
    if has_model(model):
        pose(model,"idle",1.0)
