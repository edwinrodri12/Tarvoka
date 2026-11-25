extends RefCounted
class_name TarvokaCampModels3DV1

# Four TEMPORARY specialist-built camps; this module is native 3D ART ONLY.
# No resource production, healing, vision, collision, unit spawning or combat
# effects are implemented here. Game rules belong in scripts/core.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const SupplyFinishV2 = preload("res://scripts/ui/CampSupplyFinishV2.gd")
const SupplyReadabilityV3 = preload("res://scripts/ui/CampSupplyReadabilityV3.gd")
const SupplySculptV4 = preload("res://scripts/ui/CampSupplySculptV4.gd")
const ReconFinishV2 = preload("res://scripts/ui/CampReconFinishV2.gd")
const ReconSculptV3 = preload("res://scripts/ui/CampReconSculptV3.gd")
const DefenseFinishV2 = preload("res://scripts/ui/CampDefenseFinishV2.gd")
const MedicalFinishV2 = preload("res://scripts/ui/CampMedicalFinishV2.gd")
const CAMPS := ["suministros", "reconocimiento", "defensivo", "medico"]
const BUILDERS := {
    "suministros": "infantry_logistic",
    "reconocimiento": "infantry_sniper",
    "defensivo": "infantry_engineer",
    "medico": "infantry_medic"
}
const STEEL := Color("#4E6066")
const DARK := Color("#26363C")
const CANVAS := Color("#78877A")
const CANVAS_LIGHT := Color("#A8B1A3")
const GROUND := Color("#58675E")
const RUBBER := Color("#252D2E")
const LAMP := Color("#F4D8A1")
const SAND := Color("#A79A77")
const ORANGE := Color("#DE9B43")
const WHITE := Color("#E2EBE9")
const MED_TEAL := Color("#30B4A7")

static func _mat(tint: Color, metal: float = 0.0, rough: float = 0.72) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.metallic = metal
    material.roughness = rough
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material

static func _group(parent: Node3D, label: String) -> Node3D:
    var group := Node3D.new()
    group.name = label
    parent.add_child(group)
    return group

static func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3,
        tint: Color, metal: float = 0.0, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.position = pos
    part.rotation_degrees = rot
    part.material_override = _mat(tint, metal)
    parent.add_child(part)
    return part

static func _cyl(parent: Node3D, label: String, pos: Vector3, radius: float,
        length: float, tint: Color, lod: int = 13) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = 16 if lod == 13 else 8
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.position = pos
    part.material_override = _mat(tint, 0.65)
    parent.add_child(part)
    return part

static func _strut(parent: Node3D, label: String, a: Vector3, b: Vector3,
        radius: float, tint: Color, lod: int) -> void:
    var difference: Vector3 = b - a
    if difference.length() < 0.001:
        return
    var part := _cyl(parent, label, (a + b) * 0.5, radius,
        difference.length(), tint, lod)
    part.quaternion = Quaternion(Vector3.UP, difference.normalized())

static func _platform(parent: Node3D, accent: Color, lod: int) -> void:
    _box(parent, "PlataformaDesmontable", Vector3(0, -0.075, 0),
        Vector3(7.2, 0.15, 6.8), GROUND)
    _box(parent, "IdentidadFaccionFrontal", Vector3(0, 0.055, -3.35),
        Vector3(3.5, 0.16, 0.18), accent, 0.35)
    for side in [-1, 1]:
        var x: float = float(side) * 3.48
        _box(parent, "FranjaFaccionLateral_%d" % side,
            Vector3(x, 0.07, 0.0), Vector3(0.16, 0.14, 3.6), accent, 0.3)
        if lod == 13:
            for z in [-2.7, 2.7]:
                _cyl(parent, "Anclaje_%d_%d" % [side, int(z)],
                    Vector3(x, 0.05, z), 0.10, 0.28, DARK, lod)

static func _tent(parent: Node3D, prefix: String, accent: Color, lod: int,
        damage: int) -> void:
    # Every wall and sloping roof is a CLOSED solid BoxMesh; door remains open.
    _box(parent, prefix + "_ParedPosterior", Vector3(0, 1.15, 2.66),
        Vector3(4.10, 2.05, 0.16), CANVAS)
    for side in [-1, 1]:
        var x: float = float(side) * 2.0
        _box(parent, prefix + "_ParedLateral_%d" % side,
            Vector3(x, 1.13, 1.35), Vector3(0.15, 2.0, 2.75), CANVAS)
        _box(parent, prefix + "_Jamba_%d" % side,
            Vector3(float(side) * 1.75, 1.08, -0.03),
            Vector3(0.42, 2.1, 0.16), DARK, 0.35)
        if not (damage >= 2 and side == 1):
            _box(parent, prefix + "_TechoInclinado_%d" % side,
                Vector3(float(side) * 1.06, 2.35, 1.36),
                Vector3(2.38, 0.17, 3.36), CANVAS_LIGHT, 0.0,
                Vector3(0, 0, float(-side) * 26.0))
    _box(parent, prefix + "_Dintel", Vector3(0, 2.08, -0.10),
        Vector3(3.9, 0.19, 0.25), accent, 0.3)
    _box(parent, prefix + "_Umbral", Vector3(0, 0.13, -0.27),
        Vector3(2.6, 0.1, 0.25), STEEL, 0.50)
    if lod == 13:
        for side in [-1, 1]:
            _strut(parent, prefix + "_Tensor_%d" % side,
                Vector3(float(side) * 2.35, 0.05, -0.65),
                Vector3(float(side) * 1.90, 2.50, 1.1), 0.03, DARK, lod)

static func _crate(parent: Node3D, label: String, pos: Vector3,
        accent: Color, lod: int) -> void:
    _box(parent, label + "_Cuerpo", pos, Vector3(0.78, 0.54, 0.67), STEEL, 0.35)
    _box(parent, label + "_Tapa", pos + Vector3(0, 0.30, 0),
        Vector3(0.83, 0.09, 0.72), DARK, 0.52)
    _box(parent, label + "_BandaFaccion",
        pos + Vector3(0, 0.06, -0.342),
        Vector3(0.54, 0.18, 0.035), accent, 0.25)
    if lod == 13:
        for x in [-0.29, 0.29]:
            _box(parent, label + "_Cierre_%d" % int(x * 100),
                pos + Vector3(x, 0.30, -0.32),
                Vector3(0.08, 0.14, 0.07), WHITE, 0.65)

static func _supply(parent: Node3D, accent: Color, lod: int, damage: int) -> void:
    _tent(parent, "RefugioLogistico", accent, lod, damage)
    _box(parent, "DispensadorCombustible", Vector3(-2.50, 0.89, -1.25),
        Vector3(0.72, 1.65, 0.75), STEEL, 0.56)
    _box(parent, "PantallaDispensador", Vector3(-2.50, 1.32, -1.64),
        Vector3(0.44, 0.36, 0.05), DARK, 0.50)
    _box(parent, "MarcaCombustible", Vector3(-2.50, 0.86, -1.66),
        Vector3(0.50, 0.20, 0.05), accent, 0.25)
    _strut(parent, "MangueraSoporte", Vector3(-2.18, 0.85, -1.2),
        Vector3(-1.67, 0.47, -1.55), 0.09, RUBBER, lod)
    for i in range(2 if lod == 8 else 4):
        var x: float = 2.12 + float(i % 2) * 0.62
        var z: float = -1.9 + float(i / 2) * 0.72
        _cyl(parent, "BidonCombustible_%d" % i,
            Vector3(x, 0.40, z), 0.24, 0.72, ORANGE, lod)
        _box(parent, "TapaBidon_%d" % i, Vector3(x, 0.77, z),
            Vector3(0.18, 0.07, 0.18), DARK, 0.65)
    for i in range(2 if lod == 8 else 5):
        _crate(parent, "ContenedorMunicion_%d" % i,
            Vector3(-2.60 + float(i % 2) * 0.85,
                0.32, 1.22 + float(i / 2) * 0.75), accent, lod)

static func _recon(parent: Node3D, accent: Color, lod: int, damage: int) -> void:
    _box(parent, "EstacionSensores", Vector3(-1.2, 0.76, 1.75),
        Vector3(2.1, 1.35, 1.28), STEEL, 0.52)
    _box(parent, "ConsolaFrontal", Vector3(-1.2, 0.93, 1.05),
        Vector3(1.46, 0.63, 0.13), DARK, 0.56)
    _box(parent, "PantallaConsola", Vector3(-1.2, 1.02, 0.97),
        Vector3(1.1, 0.37, 0.05), accent, 0.36)
    _box(parent, "AleronObservacionFaccion", Vector3(0.75, 0.19, 2.2),
        Vector3(2.8, 0.27, 0.22), accent, 0.35)
    for side in [-1, 1]:
        _strut(parent, "PataTorre_%d" % side,
            Vector3(1.22 + float(side) * 0.72, 0.10, 1.95),
            Vector3(1.22 + float(side) * 0.23, 3.45, 1.95),
            0.10, STEEL, lod)
    if damage < 2:
        _strut(parent, "MastilTelescopico",
            Vector3(1.22, 0.22, 1.95), Vector3(1.22, 4.2, 1.95),
            0.13, DARK, lod)
        _box(parent, "SensorOpticoCerrado", Vector3(1.22, 4.22, 1.95),
            Vector3(1.12, 0.36, 0.58), STEEL, 0.56)
        _box(parent, "LenteFrontal", Vector3(1.22, 4.22, 1.62),
            Vector3(0.42, 0.22, 0.06), accent, 0.45)
    if lod == 13:
        for x in [-2.4, -1.5, -0.6]:
            _box(parent, "ModuloAntena_%d" % int(x * 10),
                Vector3(x, 1.65, 1.90),
                Vector3(0.13, 0.52, 0.13), DARK, 0.65)

static func _defensive(parent: Node3D, accent: Color, lod: int, damage: int) -> void:
    # Protected central position stays open; there is no autonomous weapon.
    for z in [0.95, 1.7, 2.45]:
        for x in [-2.5, -1.70, -0.9, 0.9, 1.7, 2.5]:
            if damage >= 2 and x > 1.0 and z > 1.7:
                continue
            _box(parent, "SacoTerrero_%d_%d" % [int(x * 10), int(z * 10)],
                Vector3(x, 0.23 + (0.14 if z > 1.5 else 0.0), z),
                Vector3(0.80, 0.33, 0.54), SAND)
    for side in [-1, 1]:
        _box(parent, "BarreraLateral_%d" % side,
            Vector3(float(side) * 2.45, 0.64, -0.40),
            Vector3(0.44, 1.0, 2.25), STEEL, 0.50)
        _box(parent, "PanelFaccionBarrera_%d" % side,
            Vector3(float(side) * 2.45, 0.73, -1.58),
            Vector3(0.40, 0.30, 0.10), accent, 0.38)
    _box(parent, "BaseProteccionFrontal", Vector3(0, 0.19, -2.4),
        Vector3(2.40, 0.26, 0.55), DARK, 0.51)
    if lod == 13:
        for side in [-1, 1]:
            _strut(parent, "RiostraDefensa_%d" % side,
                Vector3(float(side) * 2.2, 0.1, -1.45),
                Vector3(float(side) * 2.7, 1.25, 0.25),
                0.065, DARK, lod)

static func _medical(parent: Node3D, accent: Color, lod: int, damage: int) -> void:
    _tent(parent, "CarpaSanitaria", accent, lod, damage)
    _box(parent, "ModuloMedicamentos", Vector3(-2.60, 0.88, -1.36),
        Vector3(0.75, 1.55, 0.70), WHITE, 0.22)
    _box(parent, "BotiquinIdentidad", Vector3(-2.60, 1.13, -1.74),
        Vector3(0.51, 0.48, 0.06), accent, 0.25)
    # Fictional teal first-aid mark, NOT the protected red-cross emblem.
    _box(parent, "SenalSaludVertical", Vector3(2.52, 1.34, -1.63),
        Vector3(0.18, 0.70, 0.09), MED_TEAL)
    _box(parent, "SenalSaludHorizontal", Vector3(2.52, 1.34, -1.63),
        Vector3(0.70, 0.18, 0.10), MED_TEAL)
    _box(parent, "CamillaBase", Vector3(1.25, 0.61, 1.1),
        Vector3(1.02, 0.15, 1.75), STEEL, 0.55)
    _box(parent, "ColchonCamilla", Vector3(1.25, 0.73, 1.1),
        Vector3(0.88, 0.14, 1.55), WHITE)
    for x in [0.85, 1.65]:
        for z in [0.44, 1.75]:
            _box(parent, "PataCamilla_%d_%d" % [int(x * 100), int(z * 100)],
                Vector3(x, 0.35, z), Vector3(0.08, 0.57, 0.08), DARK, 0.5)
    if lod == 13:
        for i in range(3):
            _box(parent, "GabetaSanitaria_%d" % i,
                Vector3(-2.57, 0.47 + i * 0.30, -1.75),
                Vector3(0.51, 0.19, 0.04), CANVAS_LIGHT, 0.2)

static func _weather_damage(parent: Node3D, stage: int, lod: int) -> void:
    if stage <= 0:
        return
    _box(parent, "RasponSuperficie", Vector3(1.8, 0.10, -2.62),
        Vector3(0.96, 0.07, 0.20), RUBBER, 0.0, Vector3(0, 21, 0))
    if stage >= 2:
        _box(parent, "FragmentoPanelDesprendido",
            Vector3(2.0, 0.14, -2.25),
            Vector3(1.33, 0.20, 0.80), DARK, 0.42, Vector3(0, 16, 7))
        _cyl(parent, "BidonVolcado", Vector3(-1.9, 0.28, -2.65),
            0.24, 0.70, ORANGE, lod).rotation_degrees.z = 86.0
    if stage >= 3:
        for i in range(6 if lod == 13 else 3):
            var x: float = -2.9 + float(i) * 1.04
            _box(parent, "RestosDesmontables_%d" % i,
                Vector3(x, 0.13, 1.8 + 0.14 * float(i % 2)),
                Vector3(0.78, 0.18, 0.34), STEEL, 0.55,
                Vector3(0, float(i * 19), 8 if i % 2 == 0 else -8))

static func build(kind: String, faction: int, lod: int = 13,
        damage: int = 0, supply_v4: bool = true, recon_v3: bool = true) -> Node3D:
    if not kind in CAMPS or faction < -1 or faction >= Style.FACTIONS.size():
        return null
    if lod not in [8, 13] or damage < 0 or damage > 3:
        return null
    var accent: Color = Style.faction_color(faction) if faction >= 0 else STEEL
    var root := Node3D.new()
    root.name = "Campamento_" + kind
    root.set_meta("camp_kind", kind)
    root.set_meta("builder_role", BUILDERS[kind])
    root.set_meta("visual_faction", faction)
    root.set_meta("visual_lod", lod)
    root.set_meta("visual_damage", damage)
    root.set_meta("temporary_structure", true)
    root.set_meta("art_only", true)
    root.set_meta("no_gameplay_effects", true)
    root.set_meta("no_unit_or_credit_production", true)
    _platform(root, accent, lod)
    var deployable: Node3D = _group(root, "EquipamientoDesplegable")
    if damage != 3:
        match kind:
            "suministros":
                _supply(deployable, accent, lod, damage)
            "reconocimiento":
                pass  # Recon V2 now builds one complete sculpt, no ghost V1 meshes.
            "defensivo":
                pass  # No V1 overlapping meshes: V2 is complete physical sculpture.
            "medico":
                pass  # Medical V2 fully replaces V1; no ghost/transparent shells.
    _weather_damage(root, damage, lod)
    if kind == "suministros":
        if not SupplyFinishV2.apply(root, accent, lod, damage):
            root.free()
            return null
        if not SupplyReadabilityV3.apply(root, accent, lod, damage):
            root.free()
            return null
        if supply_v4 and not SupplySculptV4.apply(root, accent, lod, damage):
            root.free()
            return null
    elif kind == "reconocimiento":
        if not ReconFinishV2.apply(root, accent, lod, damage):
            root.free()
            return null
        if recon_v3 and not ReconSculptV3.apply(root, accent, lod, damage):
            root.free()
            return null
    elif kind == "defensivo":
        if not DefenseFinishV2.apply(root, accent, lod, damage):
            root.free()
            return null
    elif kind == "medico":
        if not MedicalFinishV2.apply(root, accent, lod, damage):
            root.free()
            return null
    return root

static func pose_deploy(root: Node3D, progress: float) -> bool:
    if root == null or not root.has_meta("camp_kind"):
        return false
    var deployable: Node3D = root.get_node_or_null("EquipamientoDesplegable") as Node3D
    if deployable == null:
        return false
    var t: float = clampf(progress, 0.0, 1.0)
    # Supply V2 articulates real roof hinges and hose instead of flattening
    # the whole physical camp. Existing other three camps keep their V1 pose.
    if str(root.get_meta("camp_kind", "")) == "suministros" and \
            int(root.get_meta("visual_damage", 0)) < 3:
        deployable.visible = true
        deployable.scale = Vector3.ONE
        if not SupplyFinishV2.pose(root, t) or not SupplySculptV4.pose(root, t):
            return false
    elif str(root.get_meta("camp_kind", "")) == "reconocimiento":
        deployable.visible = true
        deployable.scale = Vector3.ONE
        if not ReconFinishV2.pose(root, t) or not ReconSculptV3.pose(root, t):
            return false
    elif str(root.get_meta("camp_kind", "")) == "defensivo":
        deployable.visible = true
        deployable.scale = Vector3.ONE
        if not DefenseFinishV2.pose(root, t):
            return false
    elif str(root.get_meta("camp_kind", "")) == "medico":
        deployable.visible = true
        deployable.scale = Vector3.ONE
        if not MedicalFinishV2.pose(root, t):
            return false
    else:
        deployable.visible = t > 0.01
        deployable.scale = Vector3(1.0, maxf(t, 0.01), 1.0)
    root.set_meta("visual_deploy_progress", t)
    return true
