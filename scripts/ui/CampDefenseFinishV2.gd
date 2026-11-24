extends RefCounted
class_name TarvokaCampDefenseFinishV2

# ART ONLY: a deployable defensive camp for infantry_engineer.
# No weapon emplacement, automatic fire, damage reduction, collision,
# healing, resources, city income or terrain effects implemented here.
const CORE := "DefenseV2_EngineerOutpost"
const STEEL := Color("#596D72")
const DARK := Color("#29393E")
const BLACK := Color("#202C31")
const SAND := Color("#A79A76")
const SAND_LIGHT := Color("#C0B28D")
const RUBBER := Color("#394448")
const BRIGHT := Color("#CED5CB")
const CAUTION := Color("#E2AA4B")

static func _material(color: Color, metal: float = 0.0,
        rough: float = 0.75) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = metal
    result.roughness = rough
    result.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    result.cull_mode = BaseMaterial3D.CULL_BACK
    return result

static func _group(parent: Node3D, title: String,
        at: Vector3 = Vector3.ZERO) -> Node3D:
    var result := Node3D.new()
    result.name = title
    result.position = at
    parent.add_child(result)
    return result

static func _box(parent: Node3D, title: String, at: Vector3,
        size: Vector3, color: Color, metal: float = 0.0,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geom := BoxMesh.new()
    geom.size = size
    var item := MeshInstance3D.new()
    item.name = title
    item.mesh = geom
    item.position = at
    item.rotation_degrees = angles
    item.material_override = _material(color, metal)
    parent.add_child(item)
    return item

static func _cylinder(parent: Node3D, title: String, at: Vector3,
        radius: float, height: float, color: Color, lod: int,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geom := CylinderMesh.new()
    geom.top_radius = radius
    geom.bottom_radius = radius
    geom.height = height
    geom.radial_segments = 16 if lod == 13 else 8
    var item := MeshInstance3D.new()
    item.name = title
    item.mesh = geom
    item.position = at
    item.rotation_degrees = angles
    item.material_override = _material(color, 0.53)
    parent.add_child(item)
    return item

static func _strut(parent: Node3D, title: String,
        point_a: Vector3, point_b: Vector3, radius: float,
        color: Color, lod: int) -> void:
    var diff: Vector3 = point_b - point_a
    if diff.length_squared() < 0.0001:
        return
    var item := _cylinder(parent, title,
        (point_a + point_b) * 0.5, radius,
        diff.length(), color, lod)
    item.quaternion = Quaternion(Vector3.UP, diff.normalized())

static func _sandbag(parent: Node3D, title: String, at: Vector3,
        lod: int, damaged: bool = false) -> void:
    # Real closed volume, deliberate overlapping/offset courses.
    var bag := _group(parent, title, at)
    if damaged:
        bag.rotation_degrees = Vector3(0, 19, -11)
    _box(bag, "LonaArenaSellada", Vector3.ZERO,
        Vector3(0.78, 0.34, 0.51), SAND)
    _box(bag, "CosturaCierre", Vector3(0, 0.185, 0),
        Vector3(0.57, 0.04, 0.13), SAND_LIGHT)
    if lod == 13:
        _box(bag, "RefuerzoCostura",
            Vector3(0, 0.165, -0.249),
            Vector3(0.62, 0.06, 0.041), DARK, 0.08)

static func _rear_wall(core: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    var rear := _group(core, "V2_MurallaTrasera")
    for course in range(2 if lod == 8 else 3):
        for i in range(7 if lod == 8 else 9):
            var width: float = 0.82 if lod == 8 else 0.64
            var x: float = (float(i) - (3.0 if lod == 8 else 4.0)) * width
            if damage >= 2 and x > 1.2 and course >= 1:
                continue
            var z: float = 2.58 - float(course) * 0.10
            _sandbag(rear, "V2_SacoPosterior_%d_%d" % [course, i],
                Vector3(x, 0.29 + float(course) * 0.33, z),
                lod, damage >= 2 and x > 0.75)
    for side in [-1, 1]:
        _box(rear, "V2_ColumnaFinal_%d" % side,
            Vector3(float(side) * 3.11, 0.59, 2.55),
            Vector3(0.32, 1.05, 0.61), DARK, 0.55)
        _box(rear, "V2_BandaTraseraFaccion_%d" % side,
            Vector3(float(side) * 3.11, 0.93, 2.17),
            Vector3(0.30, 0.26, 0.07), accent, 0.36)
    _box(rear, "V2_FranjaSuperiorDeFaccion",
        Vector3(0, 1.21, 2.61),
        Vector3(2.93, 0.22, 0.18), accent, 0.38)
    if lod == 13:
        for side in [-1, 1]:
            _cylinder(rear, "V2_AnclajePosterior_%d" % side,
                Vector3(float(side) * 3.03, 0.15, 2.02),
                0.16, 0.22, STEEL, lod)

static func _movable_wall(core: Node3D, side: int,
        accent: Color, lod: int, damage: int) -> void:
    var x: float = float(side) * 2.32
    var pivot := _group(core,
        "V2_BarreraArticulada_%d" % side,
        Vector3(x, 0.0, -0.42))
    _box(pivot, "PanelBlindajeCerrado",
        Vector3(0, 0.79, 0),
        Vector3(0.26, 1.42, 2.86), STEEL, 0.55)
    _box(pivot, "CaraInteriorMaciza",
        Vector3(-float(side) * 0.17, 0.84, 0),
        Vector3(0.10, 1.22, 2.61), DARK, 0.46)
    _box(pivot, "BarraSuperiorProteccion",
        Vector3(0, 1.53, 0),
        Vector3(0.37, 0.17, 2.98), DARK, 0.58)
    _box(pivot, "FranjaIdentidadExterior",
        Vector3(float(side) * 0.177, 1.21, -0.12),
        Vector3(0.072, 0.49, 2.47), accent, 0.42)
    _box(pivot, "PlacaFaccionInterior",
        Vector3(-float(side) * 0.232, 1.07, -0.42),
        Vector3(0.064, 0.34, 1.25), accent, 0.36)
    for z in [-1.02, 1.02]:
        _box(pivot, "PerfilAntiImpactos_%d" % int(z * 100),
            Vector3(float(side) * 0.22, 0.81, z),
            Vector3(0.15, 1.28, 0.12), DARK, 0.55)
    if lod == 13:
        for z in [-0.84, -0.28, 0.28, 0.84]:
            _box(pivot, "RemacheBlindaje_%d" % int(z * 100),
                Vector3(float(side) * 0.242, 0.45, z),
                Vector3(0.055, 0.11, 0.13), BRIGHT, 0.55)
    for z in [-1.06, 1.06]:
        _box(pivot, "BisagraInferior_%d" % int(z * 100),
            Vector3(0, 0.19, z),
            Vector3(0.46, 0.32, 0.28), DARK, 0.54)
    # Side/roof/ground visibility stays distinct; nothing blocks the center.
    if lod == 13:
        _strut(pivot, "RiostraTrasera",
            Vector3(0, 0.17, 1.14),
            Vector3(-float(side) * 0.60, 1.39, 0.73),
            0.072, STEEL, lod)

static func _side_walls(core: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    for side in [-1, 1]:
        _box(core, "V2_CimentacionBarrera_%d" % side,
            Vector3(float(side) * 2.32, 0.14, -0.42),
            Vector3(0.58, 0.27, 3.03), DARK, 0.54)
        _box(core, "V2_BisagraBase_%d" % side,
            Vector3(float(side) * 2.32, 0.21, 1.04),
            Vector3(0.70, 0.29, 0.41), STEEL, 0.56)
        if damage >= 2 and side == 1:
            # Broken right barrier is visibly collapsed on the ground.
            _box(core, "V2_SeccionBarreraCaida",
                Vector3(2.57, 0.21, -0.46),
                Vector3(1.40, 0.27, 2.33), STEEL, 0.51,
                Vector3(0, -19, 5))
            _box(core, "V2_FragmentoFaccionCaido",
                Vector3(2.59, 0.39, -0.46),
                Vector3(0.56, 0.09, 1.34), accent, 0.33,
                Vector3(0, -19, 4))
        else:
            _movable_wall(core, side, accent, lod, damage)
        if lod == 13:
            for z in [-1.50, 1.38]:
                _cylinder(core, "V2_PernoZapata_%d_%d" % [side, int(z * 100)],
                    Vector3(float(side) * 2.31, 0.28, z),
                    0.12, 0.24, DARK, lod)

static func _entry(core: Node3D, accent: Color, lod: int) -> void:
    # Center entry is deliberately WIDE and has no invisible collider.
    for side in [-1, 1]:
        _box(core, "V2_GuiaEntrada_%d" % side,
            Vector3(float(side) * 1.48, 0.12, -2.60),
            Vector3(0.12, 0.21, 0.94), accent, 0.35)
        _box(core, "V2_BalizaEntrada_%d" % side,
            Vector3(float(side) * 1.47, 0.46, -3.00),
            Vector3(0.27, 0.74, 0.30), DARK, 0.57)
        _box(core, "V2_BalizaColor_%d" % side,
            Vector3(float(side) * 1.47, 0.74, -3.02),
            Vector3(0.30, 0.17, 0.34), accent, 0.42)
    _box(core, "V2_SueloCentralOcupable",
        Vector3(0, 0.065, 0.02),
        Vector3(2.17, 0.07, 2.52), SAND_LIGHT)
    _box(core, "V2_DelimitacionCentroFaccion",
        Vector3(0, 0.105, -1.19),
        Vector3(1.75, 0.025, 0.13), accent, 0.19)
    _box(core, "V2_PlacaFortificacionExterna",
        Vector3(0, 0.19, -3.12),
        Vector3(2.34, 0.30, 0.15), accent, 0.36)
    if lod == 13:
        for z in [-0.70, 0.04, 0.77]:
            _box(core, "V2_UnionPiso_%d" % int(z * 100),
                Vector3(0, 0.105, z),
                Vector3(1.71, 0.026, 0.065), DARK, 0.40)

static func _secondary_protection(core: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    # Low sandbag courses protect the flanks but never fill the middle.
    for side in [-1, 1]:
        for i in range(2 if lod == 8 else 3):
            var z: float = -1.35 + float(i) * 0.82
            if damage >= 2 and side == 1 and i > 0:
                continue
            _sandbag(core, "V2_SacosFlanco_%d_%d" % [side, i],
                Vector3(float(side) * 3.02, 0.29, z),
                lod, damage >= 2 and side == 1)
    for side in [-1, 1]:
        _box(core, "V2_CubiertaCajaMaterial_%d" % side,
            Vector3(float(side) * 3.07, 0.31, 1.45),
            Vector3(0.74, 0.61, 0.70), STEEL, 0.42)
        _box(core, "V2_CintaMaterialFaccion_%d" % side,
            Vector3(float(side) * 3.08, 0.65, 1.45),
            Vector3(0.72, 0.095, 0.61), accent, 0.31)
        if lod == 13:
            _box(core, "V2_CierreCajaMaterial_%d" % side,
                Vector3(float(side) * 3.07, 0.46, 1.09),
                Vector3(0.22, 0.15, 0.06), BRIGHT, 0.56)
    # No turret, soldier, gun, sensor or weapon: purely defensive cover.

static func apply(root: Node3D, accent: Color, lod: int,
        damage: int) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "defensivo":
        return false
    if lod not in [8, 13] or damage not in [0, 1, 2, 3]:
        return false
    var deployable: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable") as Node3D
    if deployable == null:
        return false
    if damage >= 3:
        root.set_meta("defense_art_v2", 2)
        root.set_meta("defense_no_gameplay_changes", true)
        root.set_meta("defense_center_clear", true)
        return true
    if deployable.has_node(CORE):
        return true
    var core := _group(deployable, CORE)
    _entry(core, accent, lod)
    _rear_wall(core, accent, lod, damage)
    _side_walls(core, accent, lod, damage)
    _secondary_protection(core, accent, lod, damage)
    root.set_meta("defense_art_v2", 2)
    root.set_meta("defense_no_gameplay_changes", true)
    root.set_meta("defense_center_clear", true)
    root.set_meta("defense_not_weapon_emplacement", true)
    pose(root, 1.0)
    return true

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "defensivo":
        return false
    var t: float = clampf(progress, 0.0, 1.0)
    if int(root.get_meta("visual_damage", 0)) >= 3:
        root.set_meta("defense_v2_deploy_progress", t)
        return true
    var core: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable/" + CORE) as Node3D
    if core == null:
        return false
    for side in [-1, 1]:
        var wall: Node3D = core.get_node_or_null(
            "V2_BarreraArticulada_%d" % side) as Node3D
        if wall != null:
            wall.rotation_degrees.y = lerpf(float(side) * 78.0, 0.0, t)
    root.set_meta("defense_v2_deploy_progress", t)
    return true
