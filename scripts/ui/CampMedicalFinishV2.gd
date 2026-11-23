extends RefCounted
class_name TarvokaCampMedicalFinishV2

# TARVOKA: modular battlefield medical camp art, built exclusively by
# infantry_medic. This is ONLY a native visual sculpture: no health points,
# healing cost, resource production, collision, game-state or AI logic.
# Fictional turquoise field-aid emblem; never use the protected red cross.
const CORE := "MedicalV2_FieldHospital"
const STEEL := Color("#667B7D")
const DARK := Color("#283B40")
const DEEP := Color("#1C3037")
const CANVAS := Color("#9EADA1")
const CANVAS_DARK := Color("#718A81")
const WHITE := Color("#E6ECE6")
const BED := Color("#C2D6D1")
const TEAL := Color("#26B9AD")
const AMBER := Color("#E8B85D")
const GLASS := Color("#67A5AB")

static func _material(tint: Color, metal: float = 0.0,
        rough: float = 0.67) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = tint
    result.metallic = metal
    result.roughness = rough
    result.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    result.cull_mode = BaseMaterial3D.CULL_BACK
    return result

static func _node(parent: Node3D, label: String,
        pos: Vector3 = Vector3.ZERO) -> Node3D:
    var result := Node3D.new()
    result.name = label
    result.position = pos
    parent.add_child(result)
    return result

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, tint: Color, metal: float = 0.0,
        rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size = size
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = shape
    part.position = pos
    part.rotation_degrees = rot
    part.material_override = _material(tint, metal)
    parent.add_child(part)
    return part

static func _cyl(parent: Node3D, name: String, pos: Vector3,
        radius: float, height: float, tint: Color, lod: int,
        rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = height
    shape.radial_segments = 16 if lod == 13 else 8
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = shape
    part.position = pos
    part.rotation_degrees = rot
    part.material_override = _material(tint, 0.5)
    parent.add_child(part)
    return part

static func _bar(parent: Node3D, name: String, a: Vector3, b: Vector3,
        radius: float, tint: Color, lod: int) -> void:
    var delta: Vector3 = b - a
    if delta.length_squared() < 0.0001:
        return
    var part := _cyl(parent, name, (a + b) * 0.5, radius,
        delta.length(), tint, lod)
    part.quaternion = Quaternion(Vector3.UP, delta.normalized())

static func _aid_symbol(parent: Node3D, prefix: String,
        center: Vector3, accent: Color, horizontal: bool = false) -> void:
    # Non-red, fictional first aid sign made of raised solid geometry.
    # Framing in faction colour distinguishes camp from faction ownership.
    _box(parent, prefix + "_FondoFaccion", center,
        Vector3(0.94, 1.02, 0.085), accent, 0.26)
    _box(parent, prefix + "_CruzTurquesaVertical",
        center + Vector3(0, 0, -0.061),
        Vector3(0.17, 0.68, 0.05), TEAL)
    _box(parent, prefix + "_CruzTurquesaHorizontal",
        center + Vector3(0, 0, -0.066),
        Vector3(0.63, 0.18, 0.06), TEAL)
    if horizontal:
        _box(parent, prefix + "_EtiquetaSanitaria",
            center + Vector3(0, -0.40, -0.070),
            Vector3(0.72, 0.06, 0.04), WHITE)

static func _tent(core: Node3D, accent: Color, lod: int,
        damage: int) -> void:
    var hospital := _node(core, "V2_CarpaDesmontable")
    _box(hospital, "ParedTraseraMaciza", Vector3(0, 1.13, 2.32),
        Vector3(4.05, 2.08, 0.19), CANVAS_DARK)
    for side in [-1, 1]:
        var x: float = float(side) * 1.98
        _box(hospital, "ParedLateralHermetica_%d" % side,
            Vector3(x, 1.08, 1.13),
            Vector3(0.18, 2.04, 2.65), CANVAS)
        _box(hospital, "MarcoAcceso_%d" % side,
            Vector3(float(side) * 1.54, 1.04, -0.32),
            Vector3(0.27, 2.05, 0.16), STEEL, 0.4)
        _box(hospital, "JuntaLateralFaccion_%d" % side,
            Vector3(float(side) * 2.085, 1.30, 1.16),
            Vector3(0.065, 0.40, 1.70), accent, 0.32)
        if lod == 13:
            _bar(hospital, "TensorCarpa_%d" % side,
                Vector3(float(side) * 2.55, 0.10, -0.90),
                Vector3(float(side) * 1.87, 2.42, 0.65),
                0.035, STEEL, lod)
        if damage >= 2 and side == 1:
            _box(hospital, "FragmentoTechoDaniado",
                Vector3(1.42, 0.23, 1.57),
                Vector3(1.45, 0.20, 2.20), CANVAS_DARK,
                0.0, Vector3(0, -17, 14))
            continue
        # Closed solid wings rotate about their side pivots, never flatten
        # the entire building or expose paper-thin roof surfaces.
        var pivot := _node(hospital,
            "V2_CubiertaArticulada_%d" % side,
            Vector3(float(side) * 1.98, 2.12, 1.07))
        _box(pivot, "PanelLonaRefuerzo",
            Vector3(-float(side) * 1.08, 0, 0),
            Vector3(2.32, 0.18, 3.19), CANVAS, 0.08)
        _box(pivot, "BandaSuperiorFaccion",
            Vector3(-float(side) * 1.04, 0.125, -1.35),
            Vector3(2.05, 0.055, 0.31), accent, 0.26)
        _box(pivot, "BordeSellado",
            Vector3(-float(side) * 1.00, 0.12, 1.53),
            Vector3(2.05, 0.12, 0.11), DARK, 0.4)
        _cyl(pivot, "ArticulacionSellada",
            Vector3(0, 0, 0), 0.14, 3.18,
            STEEL, lod, Vector3(90, 0, 0))
        if lod == 13:
            for i in range(4):
                _box(pivot, "CosturaTecho_%d" % i,
                    Vector3(-float(side) * 1.06, 0.12,
                        -1.06 + float(i) * 0.72),
                    Vector3(2.02, 0.045, 0.06),
                    CANVAS_DARK, 0.05)
    _box(hospital, "DintelSanitario",
        Vector3(0, 2.15, -0.33),
        Vector3(3.68, 0.24, 0.28), accent, 0.38)
    _box(hospital, "UmbralAcceso",
        Vector3(0, 0.10, -0.53),
        Vector3(2.83, 0.16, 0.34), STEEL, 0.48)
    # Identity on the FRONT, not hidden behind a wall.
    _aid_symbol(hospital, "V2_InsigniaSanitaria",
        Vector3(0, 2.75, -0.37), accent)
    for side in [-1, 1]:
        _bar(hospital, "PosteInsignia_%d" % side,
            Vector3(float(side) * 0.34, 2.20, -0.23),
            Vector3(float(side) * 0.34, 2.48, -0.27),
            0.055, STEEL, lod)

static func _bed(core: Node3D, accent: Color, lod: int) -> void:
    # Front-right, fully visible from the four tactical camera quadrants.
    var bed := _node(core, "V2_CamillaClinica",
        Vector3(1.18, 0, 0.67))
    _box(bed, "MarcoCamillaCerrado",
        Vector3(0, 0.67, 0),
        Vector3(1.18, 0.15, 2.06), STEEL, 0.60)
    _box(bed, "ColchonClinico",
        Vector3(0, 0.79, 0),
        Vector3(1.02, 0.16, 1.84), WHITE)
    _box(bed, "RespaldoAjustable",
        Vector3(0, 1.05, 0.60),
        Vector3(1.03, 0.14, 0.79), BED,
        0.0, Vector3(-28, 0, 0))
    _box(bed, "Almohadilla",
        Vector3(0, 1.14, 0.80),
        Vector3(0.81, 0.12, 0.30), WHITE)
    _box(bed, "EtiquetaUnidadFaccion",
        Vector3(0, 0.70, -1.068),
        Vector3(0.89, 0.25, 0.09), accent, 0.32)
    for x in [-0.47, 0.47]:
        for z in [-0.80, 0.80]:
            _box(bed, "PataCamilla_%d_%d" % [int(x*100), int(z*100)],
                Vector3(x, 0.36, z),
                Vector3(0.10, 0.60, 0.10), DARK, 0.57)
    for side in [-1, 1]:
        _box(bed, "BarandaPlegable_%d" % side,
            Vector3(float(side) * 0.58, 0.92, 0.0),
            Vector3(0.065, 0.19, 1.62), STEEL, 0.51)
    if lod == 13:
        for side in [-1, 1]:
            _cyl(bed, "RuedaClinica_%d" % side,
                Vector3(float(side) * 0.50, 0.17, -0.85),
                0.15, 0.12, DARK, lod, Vector3(0, 0, 90))

static func _equipment(core: Node3D, accent: Color, lod: int,
        damage: int) -> void:
    # Two-stage modular medicine supply cabinet, never a production building.
    var cabinet := _node(core, "V2_ModuloMedicamentos",
        Vector3(-2.62, 0, -1.34))
    _box(cabinet, "ModuloBlindado",
        Vector3(0, 0.95, 0),
        Vector3(0.84, 1.76, 0.94), WHITE, 0.24)
    _box(cabinet, "PuertaEstancaFrontal",
        Vector3(0, 1.00, -0.50),
        Vector3(0.73, 1.46, 0.10), DARK, 0.42)
    _box(cabinet, "PuertaFaccion",
        Vector3(0, 1.48, -0.557),
        Vector3(0.61, 0.34, 0.08), accent, 0.32)
    _box(cabinet, "BotiquinTurquesaVertical",
        Vector3(0, 0.89, -0.565),
        Vector3(0.11, 0.43, 0.055), TEAL)
    _box(cabinet, "BotiquinTurquesaHorizontal",
        Vector3(0, 0.89, -0.572),
        Vector3(0.41, 0.12, 0.06), TEAL)
    if lod == 13:
        for i in range(3):
            _box(cabinet, "CajonLateral_%d" % i,
                Vector3(0.0, 0.45 + float(i) * 0.25, -0.57),
                Vector3(0.54, 0.06, 0.06), STEEL, 0.56)
    # IV stand with solid support, bag and hook; purely illustrative.
    var iv := _node(core, "V2_SoporteSueros",
        Vector3(2.72, 0, -0.79))
    _cyl(iv, "BaseAntivuelco", Vector3(0, 0.14, 0),
        0.30, 0.18, DARK, lod)
    _cyl(iv, "MastilSueros", Vector3(0, 1.17, 0),
        0.055, 2.13, STEEL, lod)
    _box(iv, "BrazoSueros",
        Vector3(0, 2.29, 0),
        Vector3(0.68, 0.10, 0.10), STEEL, 0.60)
    if damage < 2:
        for side in [-1, 1]:
            _box(iv, "BolsaSueros_%d" % side,
                Vector3(float(side)*0.27, 1.97, 0),
                Vector3(0.24, 0.42, 0.15), BED, 0.0)
            _box(iv, "ValvulaSueros_%d" % side,
                Vector3(float(side)*0.27, 1.69, 0),
                Vector3(0.10, 0.12, 0.11), DARK, 0.52)
    # Small monitoring unit: screen is fully opaque, no live medical stats.
    var monitor := _node(core, "V2_MonitorPortatil",
        Vector3(-0.85, 0, 1.80))
    _box(monitor, "ArmarioClinico",
        Vector3(0, 0.45, 0),
        Vector3(0.80, 0.81, 0.72), STEEL, 0.50)
    _box(monitor, "PantallaProtegida",
        Vector3(0, 1.04, -0.09),
        Vector3(0.78, 0.49, 0.40), DARK, 0.48)
    _box(monitor, "IndicadorTacticoOpaco",
        Vector3(0, 1.06, -0.302),
        Vector3(0.62, 0.29, 0.055), GLASS, 0.28)
    _box(monitor, "BandaIdentidadFaccion",
        Vector3(0, 0.51, -0.395),
        Vector3(0.56, 0.18, 0.07), accent, 0.35)
    if lod == 13:
        for i in range(3):
            _box(monitor, "LuzEstado_%d" % i,
                Vector3(-0.25 + float(i)*0.25, 0.78, -0.40),
                Vector3(0.085, 0.06, 0.045), AMBER, 0.13)

static func _external(core: Node3D, accent: Color, lod: int,
        damage: int) -> void:
    # High-contrast identity from the map's 4 isometric angles.
    for side in [-1, 1]:
        _box(core, "V2_SeñalFaccionLateral_%d" % side,
            Vector3(float(side)*2.13, 1.03, 1.24),
            Vector3(0.10, 0.46, 1.70), accent, 0.38)
        _box(core, "V2_GuiaLateralEntrada_%d" % side,
            Vector3(float(side)*1.48, 0.08, -1.86),
            Vector3(0.18, 0.13, 1.13), accent, 0.30)
        _box(core, "V2_EstabilizadorExterior_%d" % side,
            Vector3(float(side)*2.44, 0.19, 2.12),
            Vector3(0.48, 0.32, 0.55), DARK, 0.48)
    _box(core, "V2_AccesoSanitarioFaccion",
        Vector3(0, 0.09, -2.80),
        Vector3(2.75, 0.14, 0.50), accent, 0.3)
    _box(core, "V2_PadAcceso",
        Vector3(0, 0.13, -1.69),
        Vector3(1.69, 0.11, 1.79), STEEL, 0.36)
    if damage >= 2:
        _box(core, "V2_PanelDaniadoEnSuelo",
            Vector3(2.37, 0.18, -2.07),
            Vector3(1.14, 0.22, 0.94), CANVAS_DARK,
            0.05, Vector3(0, 21, 10))
    if lod == 13:
        for side in [-1, 1]:
            _box(core, "V2_RemacheUmbral_%d" % side,
                Vector3(float(side)*1.00, 0.17, -2.80),
                Vector3(0.12, 0.035, 0.17), DARK, 0.48)

static func apply(root: Node3D, accent: Color,
        lod: int, damage: int) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "medico":
        return false
    if lod not in [8, 13] or damage not in [0, 1, 2, 3]:
        return false
    var deployable: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable") as Node3D
    if deployable == null:
        return false
    if damage == 3:
        root.set_meta("medical_art_v2", 2)
        root.set_meta("medical_no_gameplay_changes", true)
        return true
    if deployable.has_node(CORE):
        return true
    var core := _node(deployable, CORE)
    _external(core, accent, lod, damage)
    _tent(core, accent, lod, damage)
    _bed(core, accent, lod)
    _equipment(core, accent, lod, damage)
    root.set_meta("medical_art_v2", 2)
    root.set_meta("medical_no_gameplay_changes", true)
    root.set_meta("medical_opaque_closed_mesh", true)
    root.set_meta("medical_fictional_teal_symbol", true)
    pose(root, 1.0)
    return true

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "medico":
        return false
    var t: float = clampf(progress, 0.0, 1.0)
    if int(root.get_meta("visual_damage", 0)) >= 3:
        root.set_meta("medical_v2_deploy_progress", t)
        return true
    var core: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable/" + CORE) as Node3D
    if core == null:
        return false
    var tent: Node3D = core.get_node_or_null(
        "V2_CarpaDesmontable") as Node3D
    if tent == null:
        return false
    for side in [-1, 1]:
        var roof: Node3D = tent.get_node_or_null(
            "V2_CubiertaArticulada_%d" % side) as Node3D
        if roof != null:
            roof.rotation_degrees.z = lerpf(
                float(side)*72.0, float(-side)*23.0, t)
    root.set_meta("medical_v2_deploy_progress", t)
    return true
