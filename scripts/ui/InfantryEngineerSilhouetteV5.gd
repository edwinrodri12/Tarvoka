extends RefCounted
class_name TarvokaInfantryEngineerSilhouetteV5

# ART ONLY — Engineer's unmistakable folded defensive barrier and construction
# harness. No camp deployment, armor, repair or movement effects.
# Applied AFTER the sealed Infantry V2 sculpt, never to Guardia or archived kits.
const FLAG := "tarvoka_infantry_engineer_silhouette_v5"
const ROLE := "infantry_engineer"
const BARRIER := "V5_BarreraPlegadaIngeniero"
const FACTION_PANEL := "V5_FaccionBarreraIngeniero"

static func _material(tint: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(tint.r,tint.g,tint.b,1.0)
    m.metallic = metal
    m.roughness = rough
    m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    return m

static func _plate(parent: Node3D, label: String, where: Vector3,
        size: Vector3, material: StandardMaterial3D,
        angle: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = where
    node.rotation_degrees = angle
    node.material_override = material
    parent.add_child(node)
    return node

static func _pin(parent: Node3D, label: String, where: Vector3,
        height: float, radius: float, material: StandardMaterial3D) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.height = height
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.radial_segments = 8
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = where
    node.material_override = material
    parent.add_child(node)
    return node

static func apply(model: Node3D, role: String, faction_paint: Color, hero: bool) -> bool:
    if model == null or role != ROLE:
        return false
    if str(model.get_meta("tarvoka_infantry_role","")) != ROLE:
        return false
    if not bool(model.get_meta("tarvoka_infantry_sculpt_finish_v2",false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return false
    var chest := model.find_child("TorsoRig",true,false) as Node3D
    var head := model.find_child("CabezaRig",true,false) as Node3D
    if chest == null or head == null:
        return false
    var faction := _material(faction_paint,0.13,0.47)
    var carbon := _material(Color("#293537"),0.15,0.70)
    var alloy := _material(Color("#7d9496"),0.46,0.40)
    var canvas := _material(Color("#4f625b"),0.04,0.82)

    # Clearly wider than Guardia's soft backpack. The barrier is folded on
    # the back, NOT deployed; no collision, combat cover or tactical effect.
    _plate(chest,BARRIER,Vector3(0,0.065,0.685),
        Vector3(1.12,0.70,0.115),alloy)
    _plate(chest,FACTION_PANEL,Vector3(0,0.16,0.754),
        Vector3(0.81,0.19,0.035),faction)
    for side in [-1,1]:
        _plate(chest,"V5_AlaBarreraIngeniero_%d"%side,
            Vector3(float(side)*0.60,0.04,0.61),
            Vector3(0.22,0.68,0.09),carbon,Vector3(0,float(side)*-19,0))
        _plate(chest,"V5_SujecionBarreraIngeniero_%d"%side,
            Vector3(float(side)*0.37,-0.13,0.766),
            Vector3(0.11,0.28,0.045),canvas)

    # Visible *from the front* at Android tactical zoom: diagonal construction
    # harness plus a broad helmet brow distinct from Guardia's clean helmet.
    _plate(chest,"V5_ArnesDiagonalIngeniero",
        Vector3(0.07,0.01,-0.438),Vector3(0.13,0.64,0.047),
        faction,Vector3(0,0,-31))
    _plate(head,"V5_ViseraObraIngeniero",
        Vector3(0,0.46,-0.345),Vector3(0.59,0.15,0.16),carbon)
    _plate(head,"V5_InsigniaCascoIngeniero",
        Vector3(0,0.47,-0.435),Vector3(0.37,0.075,0.026),faction)

    if hero:
        # Real mechanical fittings only at inspection LOD13.
        for side in [-1,1]:
            _pin(chest,"V5_BisagraIngeniero_%d"%side,
                Vector3(float(side)*0.48,0.38,0.728),
                0.21,0.055,carbon)
            _plate(chest,"V5_FundaHerramientasIngeniero_%d"%side,
                Vector3(float(side)*0.40,-0.38,0.35),
                Vector3(0.18,0.29,0.22),canvas)
        _plate(chest,"V5_CierreObraIngeniero",
            Vector3(0,-0.24,0.756),Vector3(0.39,0.085,0.04),carbon)

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_infantry_engineer_v5_hero",hero)
    model.set_meta("tarvoka_infantry_engineer_visual_only",true)
    return true

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG,false)) and \
        str(model.get_meta("tarvoka_infantry_role","")) == ROLE
