extends RefCounted
class_name TarvokaCampSupplyReadabilityV3

# Presentation-only readability layer for the SAME supply-camp model.
# Do not add any new camp, logistical ability, production, damage or AI rule.
const CORE := "SupplyV3_ReadabilityRig"
const STEEL := Color("#586F77")
const DARK := Color("#26373F")
const BLACK := Color("#202D32")
const BRIGHT := Color("#CED9D4")
const RUBBER := Color("#39454A")
const WARNING := Color("#F3B547")
const OFFWHITE := Color("#D3E1DC")

static func _mat(tint: Color, metal: float = 0.0,
        rough: float = 0.60) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.metallic = metal
    material.roughness = rough
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material

static func _box(parent: Node3D, name: String, pos: Vector3,
        dimensions: Vector3, tint: Color, metal: float = 0.0,
        rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geometry := BoxMesh.new()
    geometry.size = dimensions
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.mesh = geometry
    mesh.material_override = _mat(tint, metal)
    mesh.position = pos
    mesh.rotation_degrees = rot
    parent.add_child(mesh)
    return mesh

static func _cylinder(parent: Node3D, name: String, pos: Vector3,
        radius: float, length: float, tint: Color,
        lod: int, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geometry := CylinderMesh.new()
    geometry.top_radius = radius
    geometry.bottom_radius = radius
    geometry.height = length
    geometry.radial_segments = 12 if lod == 13 else 8
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.mesh = geometry
    mesh.material_override = _mat(tint, 0.60)
    mesh.position = pos
    mesh.rotation_degrees = rot
    parent.add_child(mesh)
    return mesh

static func _relocate_ammunition(v2: Node3D) -> bool:
    # V2 put the ammo behind the tent, invisible from the main battle camera.
    # Move the SAME crates (not duplicates) to a front-left service platform.
    var floor_plate: MeshInstance3D = v2.get_node_or_null(
        "PlataformaMunicion") as MeshInstance3D
    if floor_plate == null:
        return false
    floor_plate.position = Vector3(-1.45, 0.17, -2.06)
    for i in range(4):
        var crate: Node3D = v2.get_node_or_null(
            "V2_CajaMunicionEstanca_" + str(i)) as Node3D
        if crate != null:
            crate.position = Vector3(
                -1.75 + float(i % 2) * 0.60,
                0.52,
                -2.42 + float(int(i / 2)) * 0.75)
    for side in [-1, 1]:
        var wall: MeshInstance3D = v2.get_node_or_null(
            "ContencionMunicion_" + str(side)) as MeshInstance3D
        if wall == null:
            return false
        wall.position = Vector3(-1.45 + float(side) * 0.64,
            0.55, -2.06)
    return true

static func _ammunition_markers(core: Node3D, accent: Color,
        lod: int) -> void:
    # All signs have real thickness, visible in tactical LOD8.
    _box(core, "V3_PlacaMunicionFrontal",
        Vector3(-1.45, 0.70, -3.06),
        Vector3(1.18, 0.25, 0.09), accent, 0.34)
    _box(core, "V3_PictogramaMunicion",
        Vector3(-1.45, 0.73, -3.12),
        Vector3(0.39, 0.13, 0.045), BRIGHT, 0.08)
    for side in [-1, 1]:
        _box(core, "V3_PostesEstante_%d" % side,
            Vector3(-1.45 + float(side) * 0.65,
                0.63, -2.06), Vector3(0.09, 0.99, 0.09),
            STEEL, 0.55)
        _box(core, "V3_CintaEstante_%d" % side,
            Vector3(-1.45 + float(side) * 0.65,
                1.12, -2.06), Vector3(0.14, 0.10, 1.96),
            accent, 0.25)
    if lod == 13:
        for i in range(4):
            _box(core, "V3_CierrePallet_%d" % i,
                Vector3(-1.68 + float(i % 2) * 0.51,
                    0.90, -2.36 + float(int(i / 2)) * 0.70),
                Vector3(0.20, 0.10, 0.09), WARNING, 0.28)

static func _faction_readability(core: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    # Wide raised panels remain legible on the 8-LOD Android battlefield.
    for side in [-1, 1]:
        _box(core, "V3_EscudoLateralFaccion_%d" % side,
            Vector3(float(side) * 2.092, 1.34, 1.28),
            Vector3(0.085, 0.52, 1.90),
            accent, 0.36)
        _box(core, "V3_BordeEscudoLateral_%d" % side,
            Vector3(float(side) * 2.142, 1.34, 1.28),
            Vector3(0.043, 0.13, 1.30),
            BRIGHT, 0.22)
        _box(core, "V3_PlacaCampamentoExterior_%d" % side,
            Vector3(float(side) * 3.54, 0.28, 1.25),
            Vector3(0.13, 0.39, 1.88),
            accent, 0.34)
    _box(core, "V3_MarquesinaIdentidadFrontal",
        Vector3(0, 2.34, -0.29),
        Vector3(3.56, 0.19, 0.20), accent, 0.32)
    _box(core, "V3_PlacaLogisticaSobreAcceso",
        Vector3(0, 2.15, -0.45),
        Vector3(1.00, 0.23, 0.07), BRIGHT, 0.34)
    if damage >= 2:
        _box(core, "V3_LateralDaniado",
            Vector3(2.17, 0.53, 1.40),
            Vector3(0.18, 0.26, 0.92),
            DARK, 0.45, Vector3(15, 0, 12))

static func _interior(core: Node3D, accent: Color, lod: int) -> void:
    # Clear internal service workstation, leaving the center entrance free.
    _box(core, "V3_BancoInterior",
        Vector3(0.50, 0.66, 1.49),
        Vector3(1.38, 0.18, 0.88), STEEL, 0.48)
    for side in [-1, 1]:
        _box(core, "V3_PatasBanco_%d" % side,
            Vector3(0.50 + float(side) * 0.55,
                0.32, 1.49), Vector3(0.12, 0.60, 0.66),
            DARK, 0.49)
    _box(core, "V3_ConsolaInterior",
        Vector3(0.50, 0.91, 1.68),
        Vector3(0.95, 0.41, 0.20), BLACK, 0.50)
    _box(core, "V3_PantallaInteriorOpaca",
        Vector3(0.50, 0.94, 1.558),
        Vector3(0.70, 0.23, 0.05), accent, 0.22)
    _box(core, "V3_ContenedorInterior",
        Vector3(-0.83, 0.32, 1.81),
        Vector3(0.70, 0.60, 0.56),
        STEEL, 0.45)
    _box(core, "V3_TapaContenedorInterior",
        Vector3(-0.83, 0.66, 1.81),
        Vector3(0.75, 0.11, 0.61),
        accent, 0.38)
    if lod == 13:
        for i in range(3):
            _box(core, "V3_IndicadorConsola_%d" % i,
                Vector3(0.26 + float(i) * 0.23,
                    1.05, 1.51),
                Vector3(0.075, 0.095, 0.04),
                WARNING, 0.13)

static func _service_hardware(core: Node3D, accent: Color,
        lod: int) -> void:
    # Keep pump, tanks and articulated V2 hose unchanged; add solid braces.
    for i in range(2):
        var z: float = -0.45 + float(i) * 1.65
        _box(core, "V3_ProteccionExternaTanque_%d" % i,
            Vector3(3.27, 0.72, z),
            Vector3(0.15, 0.86, 1.25), DARK, 0.54)
        _box(core, "V3_PanelFaccionTanque_%d" % i,
            Vector3(3.39, 0.80, z),
            Vector3(0.09, 0.34, 0.94), accent, 0.35)
        _box(core, "V3_TapaMantenimiento_%d" % i,
            Vector3(3.35, 0.34, z),
            Vector3(0.12, 0.16, 0.47), BRIGHT, 0.50)
    _box(core, "V3_BandejaServicioBomba",
        Vector3(-2.68, 0.11, -2.19),
        Vector3(1.09, 0.13, 0.41), BLACK, 0.54)
    _box(core, "V3_GuardiaBoquilla",
        Vector3(-2.67, 0.45, -2.21),
        Vector3(0.81, 0.34, 0.17), STEEL, 0.48)
    _box(core, "V3_FranjaServicioBomba",
        Vector3(-2.67, 0.59, -2.32),
        Vector3(0.60, 0.12, 0.06), accent, 0.30)
    if lod == 13:
        for i in range(4):
            _cylinder(core, "V3_RemacheBomba_%d" % i,
                Vector3(-3.00 + float(i % 2) * 0.68,
                    0.40 + float(int(i / 2)) * 0.25, -2.30),
                0.055, 0.04, BRIGHT, lod,
                Vector3(90, 0, 0))

static func apply(root: Node3D, accent: Color,
        lod: int, damage: int) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "suministros":
        return false
    if lod not in [8, 13] or damage not in [0, 1, 2, 3]:
        return false
    var v2: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable/SupplyV2_PremiumRig") as Node3D
    if damage == 3:
        # D3 is genuinely destroyed, never restore intact materials.
        root.set_meta("suministros_art_v3", 3)
        root.set_meta("suministros_v3_no_gameplay_changes", true)
        return v2 == null
    if v2 == null:
        return false
    if v2.has_node(CORE):
        return true
    if not _relocate_ammunition(v2):
        return false
    var v3 := Node3D.new()
    v3.name = CORE
    v2.add_child(v3)
    _ammunition_markers(v3, accent, lod)
    _faction_readability(v3, accent, lod, damage)
    _interior(v3, accent, lod)
    _service_hardware(v3, accent, lod)
    root.set_meta("suministros_art_v3", 3)
    root.set_meta("suministros_v3_no_gameplay_changes", true)
    root.set_meta("suministros_v3_ammo_visible", true)
    return true
