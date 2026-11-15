extends RefCounted
class_name TarvokaBastionDamage3D

# P06 Bastion: reversible cosmetic damage and transient impact poses.
# No HP mutation, saving, combat authority or extra draw work at full health.
const STAGES := ["Intacto","Impactos leves","Daño moderado","Daño crítico","Destruido"]
const ROOT := "BastionP06_DanioVisual"
const META := "tarvoka_bastion_damage_stage"
const REST := "tarvoka_bastion_rest_position"

static func stage_for_hp(hp: int, maximum_hp: int) -> int:
    if hp <= 0:
        return 4
    if maximum_hp <= 0:
        return 0
    var ratio: float = clampf(float(hp)/float(maximum_hp),0.0,1.0)
    if ratio >= 0.90:
        return 0
    if ratio >= 0.65:
        return 1
    if ratio >= 0.40:
        return 2
    return 3

static func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.84
    mat.metallic = 0.12
    if color.a < 1.0:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if glow:
        mat.emission_enabled = true
        mat.emission = Color("#ff9b36")
    return mat

static func _box(parent: Node3D, label: String, position: Vector3,
        size: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> void:
    var part := MeshInstance3D.new()
    part.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = position
    part.rotation_degrees = rot
    part.material_override = _material(color)
    parent.add_child(part)

static func _cloud(parent: Node3D, label: String, position: Vector3,
        size: float, color: Color, glow: bool = false) -> void:
    var part := MeshInstance3D.new()
    part.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 8
    mesh.rings = 4
    part.mesh = mesh
    part.position = position
    part.scale = Vector3(size,size*1.3,size*0.82)
    part.material_override = _material(color,glow)
    parent.add_child(part)

static func _layer(root: Node3D, name: String) -> Node3D:
    var layer := Node3D.new()
    layer.name = name
    layer.visible = false
    root.add_child(layer)
    return layer

static func prepare(model: Node3D) -> void:
    if model == null or model.find_child(ROOT,true,false) != null:
        return
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)
    # Camera-facing front/right and rear details remain visible in orbit views.
    var light := _layer(root,"DanoP06_1")
    _box(light,"ImpactoBalisticoFrontal",Vector3(0.36,1.03,-1.36),
        Vector3(0.17,0.095,0.025),Color("#252c31"),Vector3(-25,0,15))
    _box(light,"RasponBlindajeDerecho",Vector3(0.858,1.28,-0.35),
        Vector3(0.022,0.055,0.40),Color("#343d42"))
    _box(light,"MarcaMetalExpuesto",Vector3(0.862,1.27,-0.27),
        Vector3(0.025,0.024,0.24),Color("#7f8582"))
    var moderate := _layer(root,"DanoP06_2")
    _box(moderate,"PanelDeformado",Vector3(0.84,1.08,0.25),
        Vector3(0.12,0.26,0.43),Color("#4f5658"),Vector3(0,0,-16))
    _box(moderate,"CristalAstillado",Vector3(0.36,1.23,-1.255),
        Vector3(0.19,0.022,0.035),Color("#b8c7ca"),Vector3(-18,0,25))
    _cloud(moderate,"VahoMotor",Vector3(0.35,1.75,0.93),
        0.37,Color(0.29,0.32,0.33,0.32))
    var critical := _layer(root,"DanoP06_3")
    _box(critical,"BlindajeArrancado",Vector3(0.99,0.80,0.32),
        Vector3(0.33,0.09,0.39),Color("#424a4e"),Vector3(24,13,44))
    _box(critical,"ChapaDoblada",Vector3(0.73,1.45,0.26),
        Vector3(0.32,0.09,0.45),Color("#353a3b"),Vector3(0,-14,29))
    _cloud(critical,"HumoOscuro",Vector3(0.39,1.96,0.73),
        0.59,Color(0.13,0.14,0.14,0.43))
    _cloud(critical,"FuegoMotor",Vector3(0.28,1.67,0.78),
        0.26,Color(1.0,0.33,0.07,0.74),true)
    var wreck := _layer(root,"DanoP06_4")
    _box(wreck,"TorretaCaida",Vector3(0.57,0.81,-0.28),
        Vector3(0.50,0.29,0.47),Color("#333c3d"),Vector3(0,38,28))
    _box(wreck,"FragmentoDeRampa",Vector3(-0.41,0.47,1.61),
        Vector3(0.45,0.08,0.53),Color("#596266"),Vector3(26,-8,29))
    _cloud(wreck,"LlamaInterior",Vector3(-0.09,1.30,0.78),
        0.49,Color(1,0.25,0.02,0.74),true)
    _cloud(wreck,"ColumnaHumo",Vector3(0.06,2.23,0.68),
        0.88,Color(0.10,0.11,0.11,0.53))
    var bullet := _layer(root,"ImpactoP06_Balas")
    _box(bullet,"ChispaBalistica",Vector3(0.38,1.06,-1.48),
        Vector3(0.21,0.025,0.10),Color("#ffb04c"),Vector3(15,0,25))
    _cloud(bullet,"PolvoBalistico",Vector3(0.39,1.10,-1.53),
        0.19,Color(0.65,0.64,0.57,0.41))
    var explosive := _layer(root,"ImpactoP06_Explosivo")
    _cloud(explosive,"DestelloExplosion",Vector3(0.52,1.20,0.02),
        0.81,Color(1.0,0.48,0.09,0.65),true)
    _cloud(explosive,"HumoExplosion",Vector3(0.43,1.41,0.05),
        0.95,Color(0.18,0.19,0.19,0.47))
    model.set_meta(META,0)

static func current_stage(model: Node3D) -> int:
    return int(model.get_meta(META,0)) if model != null else 0

static func apply_stage(model: Node3D, stage: int) -> bool:
    if model == null:
        return false
    prepare(model)
    var value: int = clampi(stage,0,4)
    model.set_meta(META,value)
    for index in range(1,5):
        var layer: Node3D = model.find_child("DanoP06_%d" % index,true,false) as Node3D
        if layer != null:
            layer.visible = value >= index
    # Detached components are hidden instead of destroyed, so repairs restore
    # the exact same geometry and faction-specific materials.
    for name in ["BlindajeLateral1_1","FaccionAPCPanel1_1"]:
        var plate: Node3D = model.find_child(name,true,false) as Node3D
        if plate != null:
            plate.visible = value < 3
    for name in ["TorretaRemotaP06","PortonTraseroBlindado","PanelCentralRampa"]:
        var piece: Node3D = model.find_child(name,true,false) as Node3D
        if piece != null:
            piece.visible = value < 4
    return true

static func pose_impact(model: Node3D, kind: String, progress: float) -> bool:
    if model == null:
        return false
    prepare(model)
    var t: float = clampf(progress,0.0,1.0)
    if not model.has_meta(REST):
        model.set_meta(REST,model.position)
    model.position = model.get_meta(REST) as Vector3
    model.rotation_degrees.z = 0.0
    var bullet: Node3D = model.find_child("ImpactoP06_Balas",true,false) as Node3D
    var explosive: Node3D = model.find_child("ImpactoP06_Explosivo",true,false) as Node3D
    bullet.visible = kind == "bullet" and t < 0.52
    explosive.visible = kind == "explosive" and t < 0.85
    if kind == "bullet":
        model.rotation_degrees.z = sin(t*PI)*0.65
    elif kind == "explosive":
        model.rotation_degrees.z = sin(t*PI)*2.5
        model.position.y += sin(t*PI)*0.055
    return kind in ["bullet","explosive","idle"]

static func restore(model: Node3D) -> void:
    if model != null:
        pose_impact(model,"idle",1.0)
