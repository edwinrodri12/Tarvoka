extends RefCounted
class_name TarvokaTankDamage3D

# Five persistent, visually distinct MBT condition states for model QA:
# intact, marked, damaged, critical and destroyed. No combat state, saved HP,
# rules or destructive changes to the source geometry.
const STAGES := ["Intacto","Impactos leves","Daño moderado","Daño crítico","Destruido"]

# Cosmetic bridge from authoritative HP to the five art-only MBT damage layers.
# Does not alter stats, damage or save schema. A defeated unit is shown only
# in the inspector; the tactical engine removes it as before.
static func stage_for_hp(hp: int, maximum_hp: int) -> int:
    if hp <= 0:
        return 4
    if maximum_hp <= 0:
        return 0
    var fraction: float = clampf(float(hp) / float(maximum_hp),0.0,1.0)
    if fraction >= 0.90:
        return 0
    if fraction >= 0.65:
        return 1
    if fraction >= 0.40:
        return 2
    return 3
const ROOT := "EtapasDestruccion3D"
const TURRET := "TorretaGiratoria"
const GUN := "ElevacionCanon"
const STAGE_META := "tarvoka_visual_damage_stage"
const ACCENT := Color("#E8A34F")

static func _material(color: Color, emissive: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.93
    material.metallic = 0.04
    if color.a < 1.0:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    if emissive:
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.emission_enabled = true
        material.emission = color.lightened(0.20)
        material.emission_energy_multiplier = 2.0
    return material

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3,
        color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.name = label
    var shape := BoxMesh.new()
    shape.size = size
    piece.mesh = shape
    piece.material_override = _material(color)
    piece.position = at
    piece.rotation_degrees = rotation
    parent.add_child(piece)
    return piece

static func _cloud(parent: Node3D, label: String, at: Vector3,
        dimensions: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.name = label
    var shape := SphereMesh.new()
    shape.radius = 0.5
    shape.height = 1.0
    shape.radial_segments = 12
    shape.rings = 6
    piece.mesh = shape
    piece.material_override = _material(color,glow)
    piece.position = at
    piece.scale = dimensions
    parent.add_child(piece)
    return piece

# Angled, light-emitting flame tongues instead of a fire effect made
# entirely of round spheres. Kept under 8 segments for Android OpenGL.
static func _flame(parent: Node3D, label: String, at: Vector3,
        height: float, radius: float, color: Color, tilt: Vector3) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var shape := CylinderMesh.new()
    shape.top_radius = 0.012
    shape.bottom_radius = radius
    shape.height = height
    shape.radial_segments = 7
    item.mesh = shape
    item.material_override = _material(color,true)
    item.position = at
    item.rotation_degrees = tilt
    parent.add_child(item)
    return item

static func _stage_node(root: Node3D, stage: int) -> Node3D:
    var layer := Node3D.new()
    layer.name = "DesgasteEtapa%d" % stage
    root.add_child(layer)
    layer.visible = false
    return layer

static func prepare(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    var turret: Node3D = model.find_child(TURRET,true,false) as Node3D
    var gun: Node3D = model.find_child(GUN,true,false) as Node3D
    if turret == null or gun == null:
        return false
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)

    # Stage 1: shell scars and exposed paint on front glacis and turret cheek.
    var light := _stage_node(root,1)
    _box(light,"CicatrizImpactoFrontal",Vector3(0.31,0.92,-1.12),
        Vector3(0.31,0.035,0.19),Color("#2F3436"),Vector3(-32,0,-15))
    _box(light,"MetalDesnudoImpacto",Vector3(0.31,0.955,-1.132),
        Vector3(0.12,0.039,0.07),Color("#5F5950"),Vector3(-32,0,-15))
    _box(light,"RozaduraFaldon",Vector3(1.224,0.72,-0.52),
        Vector3(0.039,0.12,0.26),Color("#302D2C"),Vector3(0,8,0))
    _box(light,"ImpactoSuperiorGlacis",Vector3(-0.23,1.13,-0.82),
        Vector3(0.28,0.045,0.22),Color("#2A2C2D"),Vector3(0,-18,9))
    _box(light,"MetalExpuestoGlacis",Vector3(-0.24,1.165,-0.85),
        Vector3(0.10,0.02,0.11),Color("#B19C7B"),Vector3(0,-18,9))
    var on_turret_1 := Node3D.new()
    on_turret_1.name = "MarcasEnTorre"
    turret.add_child(on_turret_1)
    _box(on_turret_1,"MarcaReboteTorre",Vector3(-0.46,0.31,-0.73),
        Vector3(0.25,0.15,0.040),Color("#38342E"),Vector3(-12,14,0))
    on_turret_1.visible = false

    # Stage 2: damaged bolt-on armor, missing right skirt module, hot
    # engine exhaust and visible embedded fragments.
    var medium := _stage_node(root,2)
    _box(medium,"BlindajeCompuestoAbierto",Vector3(1.21,0.68,-0.01),
        Vector3(0.09,0.31,0.39),Color("#4D4943"),Vector3(0,0,13))
    _box(medium,"PlacaDesprendida",Vector3(1.38,0.39,0.46),
        Vector3(0.09,0.29,0.48),Color("#5B6468"),Vector3(13,25,27))
    _cloud(medium,"HumoGrisMotor",Vector3(-0.09,1.37,1.01),
        Vector3(0.54,0.77,0.55),Color(0.25,0.28,0.29,0.43))
    _cloud(medium,"VahoMotor",Vector3(0.12,1.71,1.16),
        Vector3(0.67,0.76,0.59),Color(0.35,0.36,0.35,0.22))

    # Stage 3: broken right tread, fractured applique armor and dense
    # smoke on the turret/engine, with real separated track segment shapes.
    var critical := _stage_node(root,3)
    _box(critical,"OrugaCortadaColgante",Vector3(1.37,0.22,-0.65),
        Vector3(0.15,0.27,0.87),Color("#202529"),Vector3(0,0,-21))
    for i in range(5):
        _box(critical,"EslabonArrancado%d" % i,
            Vector3(1.49+float(i%2)*0.07,0.20+float(i%3)*0.10,
                -1.15+float(i)*0.20),
            Vector3(0.15,0.09,0.14),Color("#303538"),
            Vector3(i*10,i*17,i*23))
    _box(critical,"FragmentoBlindaje",Vector3(0.85,0.56,-1.21),
        Vector3(0.40,0.15,0.48),Color("#4C5456"),Vector3(19,25,27))
    _cloud(critical,"HumoNegroCritico",Vector3(0.07,1.79,0.74),
        Vector3(0.78,1.11,0.75),Color(0.09,0.10,0.12,0.62))
    _cloud(critical,"HumoElevado",Vector3(-0.12,2.38,0.75),
        Vector3(0.78,0.92,0.79),Color(0.12,0.14,0.16,0.47))

    # Stage 4: broken gun and slumped turret, flame/fire glow and wreck
    # debris. The neutral chassis remains to make faction/vehicle identity
    # still recognizable, but the model is clearly out of combat.
    var destroyed := _stage_node(root,4)
    _box(destroyed,"FragmentoCanonDoblado",Vector3(-0.28,0.29,-1.95),
        Vector3(0.17,0.12,0.82),Color("#23272A"),Vector3(0,-24,22))
    _box(destroyed,"PlacaFrontalArrancada",Vector3(-0.72,0.26,-1.49),
        Vector3(0.67,0.11,0.62),Color("#3B4447"),Vector3(17,23,34))
    _box(destroyed,"RestosOruga",Vector3(-1.31,0.16,0.95),
        Vector3(0.32,0.19,0.96),Color("#22272B"),Vector3(-11,-17,18))
    for i in range(4):
        _box(destroyed,"EscombroMetal%d" % i,
            Vector3(-0.87+float(i)*0.47,0.10,-1.69+float(i%2)*0.34),
            Vector3(0.28,0.11,0.37),Color("#343B3F"),Vector3(15*i,21*i,13*i))
    _cloud(destroyed,"FuegoBase",Vector3(0.22,1.24,-0.04),
        Vector3(0.65,0.93,0.61),Color(1.0,0.42,0.10,0.70),true)
    _cloud(destroyed,"FuegoNucleo",Vector3(0.17,1.26,-0.05),
        Vector3(0.34,0.68,0.35),Color(1.0,0.81,0.25,0.82),true)
    _cloud(destroyed,"ColumnaHumo",Vector3(0.28,2.13,-0.02),
        Vector3(1.04,1.45,0.92),Color(0.08,0.09,0.11,0.59))
    _cloud(destroyed,"HumoSuperior",Vector3(0.36,2.91,-0.04),
        Vector3(1.23,1.03,1.04),Color(0.13,0.14,0.17,0.38))
    # Broken hardware remains visible even when flame/smoke fades.
    _box(destroyed,"BastidorTorrePartido",Vector3(-0.83,1.04,0.68),
        Vector3(0.09,0.57,0.71),Color("#22282B"),Vector3(16,-26,42))
    _box(destroyed,"OpticaArrancada",Vector3(0.82,0.28,-0.62),
        Vector3(0.31,0.16,0.19),Color("#2C3A3D"),Vector3(25,21,-15))
    _box(destroyed,"BlindajeSeparadoProa",Vector3(0.63,0.19,-1.74),
        Vector3(0.51,0.13,0.47),Color("#4B5557"),Vector3(-8,20,27))
    _box(destroyed,"MotorCarbonizado",Vector3(0.0,1.076,0.94),
        Vector3(1.17,0.035,0.48),Color("#22272B"))
    _flame(destroyed,"LenguaFuegoIzquierda",Vector3(-0.13,1.47,0.09),
        0.87,0.19,Color(1.00,0.43,0.08,0.81),Vector3(0,0,-18))
    _flame(destroyed,"LenguaFuegoCentro",Vector3(0.17,1.58,-0.02),
        1.05,0.25,Color(1.00,0.69,0.12,0.84),Vector3(9,0,12))
    _flame(destroyed,"LenguaFuegoAlta",Vector3(0.41,1.77,0.22),
        0.90,0.14,Color(0.95,0.30,0.04,0.67),Vector3(-12,0,23))
    model.set_meta(STAGE_META,0)
    return true

static func current_stage(model: Node3D) -> int:
    return int(model.get_meta(STAGE_META,0)) if model != null else 0

static func apply_stage(model: Node3D, stage: int) -> bool:
    if model == null or stage < 0 or stage >= STAGES.size():
        return false
    var root: Node3D = model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    model.set_meta(STAGE_META,stage)
    for index in range(1,STAGES.size()):
        var layer: Node3D = root.find_child("DesgasteEtapa%d" % index,false,false) as Node3D
        if layer != null:
            layer.visible = stage >= index
    var cheek: Node3D = model.find_child("MarcasEnTorre",true,false) as Node3D
    if cheek != null:
        cheek.visible = stage >= 1
    # Use mesh visibility rather than deleting/copying meshes. The original
    # unit stays reusable and is restored 100% when returning to "Intacto".
    for part_name in ["FaccionFaldon1_02","FaccionFaldon1_03"]:
        var plate: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if plate != null:
            plate.visible = stage < 2
    # The final state physically loses its original cannon instead of
    # simply coloring it black. Broken barrel debris is already in stage 4.
    for weapon_name in ["Canon120mm","ManguitoTermico","ExtractorGases","BocaCanon"]:
        var barrel: MeshInstance3D = model.find_child(weapon_name,true,false) as MeshInstance3D
        if barrel != null:
            barrel.visible = stage < 4
    for part_name in ["CintaSuperiorOruga1","EslabonTreadSuperior1_07",
            "EslabonTreadSuperior1_08","EslabonTreadSuperior1_09"]:
        var tread: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if tread != null:
            tread.visible = stage < 3
    # Finishing pieces become physically broken, not just hidden by smoke.
    # Every change is reversible by returning the viewer to stage 0.
    for part_name in ["MejillaCeramicaBiselada1","GuardiaOpticaLateral1",
            "LenteSensorLateral1","BlindajeRuedaExtremo1_-1"]:
        var finish_piece: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if finish_piece != null:
            finish_piece.visible = stage < 3
    for part_name in ["CristalPanoramicoFrontal","ModuloVisionPanoramica",
            "CristalPanoramicoLateral","BastidorTrasero-1"]:
        var upper_piece: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if upper_piece != null:
            upper_piece.visible = stage < 4
    var turret: Node3D = model.find_child(TURRET,true,false) as Node3D
    var gun: Node3D = model.find_child(GUN,true,false) as Node3D
    if turret != null:
        turret.rotation_degrees.z = 0.0 if stage < 3 else (6.0 if stage == 3 else 22.0)
        turret.position.y = 1.11 if stage < 4 else 0.93
    if gun != null:
        gun.rotation_degrees.x = -18.0 if stage >= 4 else (5.0 if stage == 3 else 0.0)
    return true
