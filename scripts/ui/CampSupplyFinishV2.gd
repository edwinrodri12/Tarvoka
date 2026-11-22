extends RefCounted
class_name TarvokaCampSupplyFinishV2

# Sealed native Godot 4.3 hard-surface overlay for the pre-existing
# deployable SUMINISTROS camp. ART ONLY: cannot refill units or mint credits.
# The four specialist camps and the G16 armoured logistics unit are unchanged.
const CORE = "SupplyV2_PremiumRig"
const STEEL = Color("#536871")
const DARK = Color("#24343A")
const BLACK = Color("#1B292E")
const METAL = Color("#B9C7C9")
const MATT = Color("#75847C")
const RUBBER = Color("#292F30")
const FUEL = Color("#AC8550")
const CAUTION = Color("#EAB34F")
const GLASS = Color("#658F9D")

static func _material(tint: Color, metal: float = 0.0,
        roughness: float = 0.6) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = metal
    mat.roughness = roughness
    mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    mat.cull_mode = BaseMaterial3D.CULL_BACK
    return mat

static func _node(parent: Node3D, name: String,
        position: Vector3 = Vector3.ZERO) -> Node3D:
    var group := Node3D.new()
    group.name = name
    group.position = position
    parent.add_child(group)
    return group

static func _box(parent: Node3D, name: String, position: Vector3,
        dimensions: Vector3, tint: Color, metal: float = 0.0,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geo := BoxMesh.new()
    geo.size = dimensions
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = geo
    part.material_override = _material(tint, metal)
    part.position = position
    part.rotation_degrees = angles
    parent.add_child(part)
    return part

static func _cylinder(parent: Node3D, name: String, position: Vector3,
        radius: float, length: float, tint: Color,
        lod: int, angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geo := CylinderMesh.new()
    geo.top_radius = radius
    geo.bottom_radius = radius
    geo.height = length
    geo.radial_segments = 16 if lod == 13 else 8
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = geo
    part.material_override = _material(tint, 0.52)
    part.position = position
    part.rotation_degrees = angles
    parent.add_child(part)
    return part

static func _bar(parent: Node3D, name: String, a: Vector3,
        b: Vector3, radius: float, tint: Color, lod: int) -> void:
    var delta: Vector3 = b - a
    if delta.length_squared() <= 0.00001:
        return
    var part := _cylinder(parent, name, (a + b) * 0.5,
        radius, delta.length(), tint, lod)
    part.quaternion = Quaternion(Vector3.UP, delta.normalized())

static func _roof(assembly: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    for side in [-1, 1]:
        if damage >= 2 and side == 1:
            continue
        var suffix: String = str(side)
        var pivot: Node3D = _node(assembly,
            "V2_ArticulacionCubierta_" + suffix,
            Vector3(float(side) * 1.92, 2.17, 1.33))
        _box(pivot, "CubiertaAceroContinua_" + suffix,
            Vector3(-float(side) * 1.10, 0, 0),
            Vector3(2.37, 0.13, 3.55), MATT, 0.21)
        _box(pivot, "AletaPinturaFaccion_" + suffix,
            Vector3(-float(side) * 1.05, 0.095, -1.57),
            Vector3(2.04, 0.045, 0.30), accent, 0.34)
        _box(pivot, "PerfilSelladoBorde_" + suffix,
            Vector3(-float(side) * 1.05, 0.08, 1.70),
            Vector3(2.08, 0.12, 0.10), DARK, 0.4)
        _cylinder(pivot, "BisagraHermetica_" + suffix,
            Vector3(0, 0, 0), 0.15, 3.35,
            STEEL, lod, Vector3(90, 0, 0))
        if lod == 13:
            for i in range(4):
                _box(pivot, "NervaduraTecho_%s_%d" % [suffix, i],
                    Vector3(-float(side) * 1.04, 0.105,
                        -1.16 + float(i) * 0.81),
                    Vector3(2.02, 0.075, 0.075), STEEL, 0.65)
            _box(pivot, "PlacaTactica_%s" % suffix,
                Vector3(-float(side) * 0.80, 0.13, 0.15),
                Vector3(0.75, 0.03, 0.52), accent, 0.30)
    _box(assembly, "DintelReforzadoFrontal",
        Vector3(0, 2.17, -0.15), Vector3(4.02, 0.21, 0.32),
        STEEL, 0.55)
    _box(assembly, "IdentidadCampamentoFrontal",
        Vector3(0, 2.19, -0.335), Vector3(3.10, 0.28, 0.07),
        accent, 0.26)

static func _tank(assembly: Node3D, index: int, lod: int,
        damage: int, accent: Color) -> void:
    var base_z: float = -0.45 + float(index) * 1.65
    var group: Node3D = _node(assembly,
        "V2_DepositoCombustibleSellado_" + str(index),
        Vector3(2.67, 0.78, base_z))
    if damage >= 2 and index == 1:
        group.rotation_degrees.z = -24.0
        group.position.y = 0.52
    for side in [-1, 1]:
        _box(group, "SoporteCuna_%d" % side,
            Vector3(0, -0.48, float(side) * 0.44),
            Vector3(1.00, 0.20, 0.18), BLACK, 0.62)
    _cylinder(group, "DepositoMacizo",
        Vector3.ZERO, 0.43, 1.35, STEEL, lod, Vector3(90, 0, 0))
    for side in [-1, 1]:
        _cylinder(group, "TapaEstanca_%d" % side,
            Vector3(0, 0, float(side) * 0.70),
            0.45, 0.10, DARK, lod, Vector3(90, 0, 0))
        if lod == 13:
            _cylinder(group, "CierreTapa_%d" % side,
                Vector3(0, 0, float(side) * 0.76),
                0.12, 0.12, METAL, lod, Vector3(90, 0, 0))
    for z in [-0.38, 0.38]:
        _box(group, "CinchaAcero_%d" % int(z * 100),
            Vector3(0, 0.43, z), Vector3(0.85, 0.12, 0.15),
            accent, 0.4)
    _cylinder(group, "ValvulaSuperior",
        Vector3(0, 0.55, -0.18), 0.12, 0.28,
        METAL, lod)
    _box(group, "ProtectorValvula",
        Vector3(0, 0.72, -0.18),
        Vector3(0.4, 0.12, 0.45), DARK, 0.4)
    if lod == 13:
        for z in [-0.4, 0, 0.4]:
            _box(group, "RibeteTanque_%d" % int(z * 100),
                Vector3(-0.32, 0.25, z), Vector3(0.12, 0.12, 0.24),
                METAL, 0.64)

static func _pump(assembly: Node3D, accent: Color, lod: int,
        damage: int) -> void:
    var group: Node3D = _node(assembly, "V2_EstacionBombeo",
        Vector3(-2.68, 0.0, -1.43))
    _box(group, "BancadaAcero", Vector3(0, 0.12, 0),
        Vector3(1.20, 0.24, 1.08), DARK, 0.65)
    _box(group, "ArmarioCerrado", Vector3(0, 1.01, 0),
        Vector3(1.05, 1.55, 0.84), STEEL, 0.56)
    _box(group, "PuertaYMarco", Vector3(0, 1.06, -0.43),
        Vector3(0.90, 1.35, 0.09), DARK, 0.48)
    _box(group, "PanelFaccionAmplio", Vector3(0, 1.42, -0.49),
        Vector3(0.71, 0.38, 0.08), accent, 0.34)
    _box(group, "PantallaControlOpaca", Vector3(-0.12, 1.03, -0.51),
        Vector3(0.37, 0.24, 0.065), GLASS, 0.38)
    _cylinder(group, "ConectorSuministro", Vector3(0.46, 0.76, -0.12),
        0.18, 0.26, METAL, lod, Vector3(0, 0, 90))
    if damage < 2:
        _box(group, "PantallaSuperiorFaccion", Vector3(0, 1.89, -0.06),
            Vector3(1.01, 0.14, 0.9), accent, 0.4)
    for i in range(3 if lod == 13 else 1):
        _box(group, "PanelLuces_%d" % i,
            Vector3(0.21 - float(i) * 0.16, 0.76, -0.53),
            Vector3(0.10, 0.10, 0.06), CAUTION, 0.16)
    # Separate supply hose rig: real fully enclosed cylinders, not floating lines.
    var hose: Node3D = _node(assembly, "V2_MangueraArticulada",
        Vector3(-2.16, 0.99, -1.38))
    var path: Array[Vector3] = [
        Vector3(0, 0, 0),
        Vector3(0.22, -0.19, -0.11),
        Vector3(0.44, -0.31, -0.27),
        Vector3(0.63, -0.37, -0.54),
        Vector3(0.72, -0.22, -0.77),
        Vector3(0.72, 0.02, -0.84)
    ]
    for i in range(3 if lod == 8 else path.size() - 1):
        var index: int = i * 2 if lod == 8 and i < 2 else i
        var next_index: int = min(index + (2 if lod == 8 else 1),
            path.size() - 1)
        _bar(hose, "TramoMangueraCaucho_%d" % i,
            path[index], path[next_index], 0.085, RUBBER, lod)
        if lod == 13 and i > 0:
            _cylinder(hose, "AcopleManguera_%d" % i,
                path[index], 0.105, 0.12, METAL, lod)
    _box(hose, "BoquillaFinal", path[path.size() - 1],
        Vector3(0.23, 0.14, 0.34), METAL, 0.71)

static func _ammo(assembly: Node3D, accent: Color, lod: int) -> void:
    _box(assembly, "PlataformaMunicion", Vector3(-2.75, 0.17, 1.30),
        Vector3(1.34, 0.22, 2.3), BLACK, 0.53)
    for i in range(2 if lod == 8 else 4):
        var x: float = -3.00 + float(i % 2) * 0.60
        var z: float = 0.53 + float(i / 2) * 0.75
        var group: Node3D = _node(assembly,
            "V2_CajaMunicionEstanca_" + str(i), Vector3(x, 0.52, z))
        _box(group, "CuerpoMonolitico", Vector3.ZERO,
            Vector3(0.57, 0.51, 0.63), STEEL, 0.55)
        _box(group, "TapaHermetica", Vector3(0, 0.30, 0),
            Vector3(0.62, 0.105, 0.67), DARK, 0.6)
        _box(group, "FranjaIdentificadora", Vector3(0, 0.04, -0.34),
            Vector3(0.47, 0.23, 0.05), accent, 0.31)
        if lod == 13:
            for side in [-1, 1]:
                _box(group, "CierreIndustrial_%d" % side,
                    Vector3(float(side) * 0.20, 0.30, -0.30),
                    Vector3(0.07, 0.18, 0.09), METAL, 0.75)
    for side in [-1, 1]:
        _box(assembly, "ContencionMunicion_%d" % side,
            Vector3(-2.75 + float(side) * 0.64, 0.55, 1.30),
            Vector3(0.12, 0.78, 2.3), DARK, 0.63)

static func _warning(assembly: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    # Striping is genuine solid raised geometry, not a texture billboard.
    for i in range(3 if lod == 8 else 7):
        var x: float = -1.43 + float(i) * (0.95 if lod == 8 else 0.47)
        _box(assembly, "GuiaPeligro_%d" % i,
            Vector3(x, 0.085, -2.88),
            Vector3(0.29, 0.065, 0.47), CAUTION, 0.1,
            Vector3(0, -35, 0))
    _box(assembly, "BandaIdentidadLateral",
        Vector3(3.42, 0.63, 0.72), Vector3(0.12, 0.25, 2.32),
        accent, 0.42)
    for side in [-1, 1]:
        _bar(assembly, "RiostraExterior_%d" % side,
            Vector3(float(side) * 2.12, 0.12, -0.22),
            Vector3(float(side) * 2.12, 2.06, 0.23),
            0.068, STEEL, lod)
    if damage >= 1:
        _box(assembly, "PlacaAbolladaV2",
            Vector3(2.3, 0.10, -2.53),
            Vector3(1.03, 0.21, 0.44),
            DARK, 0.51, Vector3(0, 15, 12))

static func apply(root: Node3D, accent: Color, lod: int,
        damage: int) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "suministros":
        return false
    if lod not in [8, 13] or damage < 0 or damage > 3:
        return false
    if root.get_node_or_null("EquipamientoDesplegable/" + CORE) != null:
        return true
    if damage >= 3:
        root.set_meta("suministros_art_v2", 2)
        return true  # A destroyed camp has no standing pumps or intact tent.
    var deployable: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable") as Node3D
    if deployable == null:
        return false
    var core: Node3D = _node(deployable, CORE)
    # Hide only V1 prototype roof and dispenser; keep V1 walls intact.
    for child in deployable.get_children():
        if child == core:
            continue
        if child.name.begins_with("RefugioLogistico_TechoInclinado_"):
            child.visible = false
        if child.name in ["DispensadorCombustible", "PantallaDispensador",
                "MarcaCombustible", "MangueraSoporte"]:
            child.visible = false
    _roof(core, accent, lod, damage)
    _pump(core, accent, lod, damage)
    _tank(core, 0, lod, damage, accent)
    _tank(core, 1, lod, damage, accent)
    _ammo(core, accent, lod)
    _warning(core, accent, lod, damage)
    root.set_meta("suministros_art_v2", 2)
    root.set_meta("suministros_v2_solid_mesh", true)
    root.set_meta("suministros_no_gameplay_changes_v2", true)
    pose(root, 1.0)
    return true

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "suministros":
        return false
    var core: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable/" + CORE) as Node3D
    if core == null:
        return int(root.get_meta("visual_damage", 0)) == 3
    var t: float = clampf(progress, 0.0, 1.0)
    for side in [-1, 1]:
        var leaf: Node3D = core.get_node_or_null(
            "V2_ArticulacionCubierta_" + str(side)) as Node3D
        if leaf != null:
            leaf.rotation_degrees.z = lerpf(float(side) * 70.0,
                float(-side) * 25.0, t)
    var hose: Node3D = core.get_node_or_null("V2_MangueraArticulada") as Node3D
    if hose != null:
        hose.rotation_degrees.y = lerpf(90.0, 0.0, t)
        hose.rotation_degrees.z = lerpf(-22.0, 0.0, t)
    root.set_meta("suministros_v2_deploy", t)
    return true
