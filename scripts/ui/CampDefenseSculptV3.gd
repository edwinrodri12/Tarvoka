extends RefCounted
class_name TarvokaCampDefenseSculptV3

# Native temporary engineer camp. ART ONLY; no combat or placement changes.
const Base = preload("res://scripts/ui/CampDefenseFinishV2.gd")
const Solid = preload("res://scripts/ui/CampSupplySculptV4.gd")
const STEEL := Color("#596C70")
const DARK := Color("#29393E")
const ALLOY := Color("#A5B3B0")
const CANVAS := Color("#B2A583")
const CANVAS_DARK := Color("#998B6A")
const RUBBER := Color("#354247")

static func _mat(tint: Color, metal: float = 0.3, rough: float = 0.65) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = metal
    mat.roughness = rough
    mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    mat.cull_mode = BaseMaterial3D.CULL_BACK
    var kind: String = ""
    if tint in [STEEL, DARK, ALLOY]:
        kind = "metal"
    elif tint in [CANVAS, CANVAS_DARK]:
        kind = "fabric"
    elif tint == RUBBER:
        kind = "rubber"
    if not kind.is_empty():
        mat.albedo_texture = Solid._finish_map(kind)
        mat.uv1_triplanar = true
        mat.uv1_scale = Vector3(3.0, 3.0, 3.0)
    return mat

static func _group(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = at
    parent.add_child(node)
    return node

static func _part(parent: Node3D, label: String, mesh: Mesh, at: Vector3, tint: Color, metal: float = 0.3, rough: float = 0.65) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = at
    node.material_override = _mat(tint, metal, rough)
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, tint: Color, bevel: float = 0.035, metal: float = 0.35) -> MeshInstance3D:
    return _part(parent, label, Solid.beveled(size, bevel), at, tint, metal)

static func _cyl(parent: Node3D, label: String, at: Vector3, radius: float, length: float, axis: Vector3, tint: Color, lod: int) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = 20 if lod == 13 else 10
    var part: MeshInstance3D = _part(parent, label, mesh, at, tint, 0.50)
    part.quaternion = Quaternion(Vector3.UP, axis.normalized())
    return part

static func _replace(parent: Node3D, label: String, bevel: float, tint: Color, metal: float = 0.35) -> bool:
    var node: MeshInstance3D = parent.get_node_or_null(label) as MeshInstance3D
    if node == null or not node.mesh is BoxMesh:
        return false
    node.mesh = Solid.beveled((node.mesh as BoxMesh).size, bevel)
    node.material_override = _mat(tint, metal)
    return true

# Pillow-like filled bag: sealed rounded rings with flattened load-bearing
# top/bottom, end taper and a slight asymmetric bulge. Not a box or billboard.
static func _bag_mesh(width: float, lod: int, seed: int) -> ArrayMesh:
    var rings: Array = []
    var sides: int = 16 if lod == 13 else 8
    var profile := [Vector2(-0.275, 0.66), Vector2(-0.205, 0.92),
        Vector2(0.0, 1.0), Vector2(0.205, 0.92), Vector2(0.275, 0.66)]
    for sample in profile:
        var ring: Array[Vector3] = []
        for j in range(sides):
            var angle: float = TAU * float(j) / float(sides)
            var c: float = cos(angle)
            var sn: float = sin(angle)
            var x: float = signf(c) * pow(absf(c), 0.65) * width * 0.5 * sample.y
            var yy: float = signf(sn) * pow(absf(sn), 0.70) * 0.178 * sample.y
            var offset: float = sin(float(seed) * 1.7 + sample.x * 8.0) * 0.012
            ring.append(Vector3(x + offset, yy, sample.x))
        rings.append(ring)
    return Solid._loft(rings)

static func _bag(bag: Node3D, width: float, lod: int, seed: int) -> void:
    var old: MeshInstance3D = bag.get_node("LonaArenaSellada") as MeshInstance3D
    old.mesh = _bag_mesh(width, lod, seed)
    old.material_override = _mat(CANVAS if seed % 3 != 0 else CANVAS_DARK, 0.0, 0.89)
    var seam: MeshInstance3D = bag.get_node("CosturaCierre") as MeshInstance3D
    seam.mesh = Solid.beveled(Vector3(width * 0.68, 0.035, 0.09), 0.009)
    seam.position.y = 0.174
    seam.material_override = _mat(CANVAS_DARK, 0.0, 0.90)
    var original: Node3D = bag.get_node_or_null("RefuerzoCostura") as Node3D
    if original != null:
        original.visible = false
    if lod == 13:
        for side in [-1, 1]:
            _box(bag, "V3_BagFold_%d" % side, Vector3(float(side) * width * 0.36, 0.035, -0.255),
                Vector3(0.065, 0.19, 0.036), CANVAS_DARK, 0.012, 0.0).rotation_degrees.z = float(side) * 13.0

static func _rear(rear: Node3D, accent: Color, lod: int, damage: int) -> void:
    var seed: int = 0
    for child in rear.get_children():
        if str(child.name).begins_with("V2_SacoPosterior_"):
            var bag: Node3D = child as Node3D
            var course: int = int(str(bag.name).get_slice("_", 2))
            var index: int = int(str(bag.name).get_slice("_", 3))
            var last: int = 6 if lod == 8 else 8
            var width: float = 0.86 if lod == 8 else 0.69
            # Offset alternate courses, with smaller end bags rather than
            # protruding past the retaining posts. Deterministic slight variation.
            if course % 2 == 1:
                bag.position.x += 0.17 if index < last else 0.08
                if index == last:
                    width -= 0.12
            bag.rotation_degrees.y += float(seed % 3 - 1) * 2.0
            _bag(bag, width, lod, seed)
            seed += 1
    for side in [-1, 1]:
        _replace(rear, "V2_ColumnaFinal_%d" % side, 0.055, DARK, 0.55)
        _replace(rear, "V2_BandaTraseraFaccion_%d" % side, 0.015, accent)
        _box(rear, "V3_EndFoot_%d" % side, Vector3(float(side) * 3.11, 0.12, 2.56),
            Vector3(0.48, 0.19, 0.73), STEEL, 0.045)
        _box(rear, "V3_RetainingPost_%d" % side, Vector3(float(side) * 1.45, 0.61, 2.89),
            Vector3(0.14, 1.12, 0.18), DARK, 0.024)
        _box(rear, "V3_PostFoot_%d" % side, Vector3(float(side) * 1.45, 0.095, 2.89),
            Vector3(0.32, 0.17, 0.36), STEEL, 0.04)
    # The fascia is carried by the retaining frame in both LODs; no floating strip.
    var fascia: MeshInstance3D = rear.get_node("V2_FranjaSuperiorDeFaccion") as MeshInstance3D
    _replace(rear, "V2_FranjaSuperiorDeFaccion", 0.028, accent)
    fascia.position = Vector3(0, 1.11, 2.89)
    _box(rear, "V3_FasciaBeam", Vector3(0, 1.03, 2.91),
        Vector3(3.07, 0.17, 0.18), DARK, 0.03)
    _box(rear, "V3_RearLowerTie", Vector3(0, 0.16, 2.93),
        Vector3(5.95, 0.16, 0.15), DARK, 0.028)
    if damage >= 2:
        fascia.rotation_degrees.z = -4.0

# V3.1: two-stage support links follow the moving attachment without
# scaling the rigid armor. Links use a telescopic sleeve and captive shaft.
static func _brace(core: Node3D, wall: Node3D, side: int, z: float, lod: int) -> void:
    var suffix: String = "%d_%d" % [side, int(z * 100)]
    var fixed: Vector3 = wall.position + Vector3(-float(side) * 0.55, -0.15, z + signf(z) * 0.40)
    var moving := Vector3(-float(side) * 0.19, 0.80, z)
    _box(core, "V31_BraceBase_" + suffix, fixed - Vector3(0, 0.055, 0),
        Vector3(0.34, 0.17, 0.36), DARK, 0.045)
    _cyl(core, "V31_BraceBasePin_" + suffix, fixed, 0.09, 0.30, Vector3.BACK, ALLOY, lod)
    _box(wall, "V31_BraceLug_" + str(int(z * 100)), moving,
        Vector3(0.24, 0.24, 0.24), DARK, 0.035)
    _cyl(wall, "V31_BraceWallPin_" + str(int(z * 100)), moving, 0.08, 0.29, Vector3.BACK, ALLOY, lod)
    var rig: Node3D = _group(core, "V31_Brace_" + suffix, fixed)
    rig.set_meta("wall_side", side)
    rig.set_meta("wall_anchor", moving)
    rig.set_meta("base_anchor", fixed)
    _cyl(rig, "Sleeve", Vector3.ZERO, 0.083, 0.40, Vector3.UP, STEEL, lod)
    _cyl(rig, "Middle", Vector3.ZERO, 0.065, 0.42, Vector3.UP, STEEL, lod)
    _cyl(rig, "Shaft", Vector3.ZERO, 0.047, 0.42, Vector3.UP, ALLOY, lod)
    _cyl(rig, "Seal", Vector3.ZERO, 0.095, 0.055, Vector3.UP, RUBBER, lod)

static func _brace_pose(core: Node3D) -> void:
    for child in core.get_children():
        if not str(child.name).begins_with("V31_Brace_"):
            continue
        var rig: Node3D = child as Node3D
        var side: int = int(rig.get_meta("wall_side"))
        var wall: Node3D = core.get_node("V2_BarreraArticulada_%d" % side) as Node3D
        var start: Vector3 = rig.get_meta("base_anchor")
        var end: Vector3 = wall.transform * Vector3(rig.get_meta("wall_anchor"))
        var diff: Vector3 = end - start
        var length: float = diff.length()
        rig.position = start
        rig.quaternion = Quaternion(Vector3.UP, diff.normalized())
        var sleeve: Node3D = rig.get_node("Sleeve") as Node3D
        var middle: Node3D = rig.get_node("Middle") as Node3D
        var shaft: Node3D = rig.get_node("Shaft") as Node3D
        var seal: Node3D = rig.get_node("Seal") as Node3D
        # Physical rigid lengths. At compact poses the shaft is nested
        # inside the sleeve; neither endpoint detaches.
        sleeve.position.y = 0.20
        middle.position.y = length * 0.5
        shaft.position.y = length - 0.21
        seal.position.y = 0.40
        rig.set_meta("span", length)
        rig.set_meta("tip", end)

static func _armor_v31(core: Node3D, wall: Node3D, side: int, accent: Color, lod: int) -> void:
    var inside: float = -float(side)
    # Conformal inner armor pads over the flat original face. Tall pads
    # flank, rather than cover, the official faction stripe.
    for z in [-0.93, 0.93]:
        _box(wall, "V31_InnerArmorPad_%d" % int(z * 100),
            Vector3(inside * 0.245, 0.54, z), Vector3(0.12, 0.95, 0.57),
            STEEL, 0.055, 0.46)
        _box(wall, "V31_InnerVerticalRib_%d" % int(z * 100),
            Vector3(inside * 0.30, 0.55, z), Vector3(0.11, 1.00, 0.095),
            DARK, 0.024, 0.55)
        _box(wall, "V31_InnerEndCap_%d" % int(z * 100),
            Vector3(inside * 0.31, 0.96, z), Vector3(0.14, 0.11, 0.44),
            ALLOY, 0.018, 0.50)
    _box(wall, "V31_InnerLowerRail", Vector3(inside * 0.255, 0.16, 0),
        Vector3(0.13, 0.16, 2.51), STEEL, 0.025, 0.53)
    _box(wall, "V31_IdentityBacking", Vector3(inside * 0.266, 0.77, -0.42),
        Vector3(0.09, 0.40, 1.30), DARK, 0.018)
    # The retained faction plate is moved onto its new backing.
    var identity: Node3D = wall.get_node("PlacaFaccionInterior") as Node3D
    identity.position.x = inside * 0.323
    for z in [-1.23, 1.23]:
        _box(wall, "V31_EndCap_%d" % int(z * 100), Vector3(0, 0.57, z),
            Vector3(0.38, 1.07, 0.15), DARK, 0.04, 0.50)
        _box(wall, "V31_UpperLock_%d" % int(z * 100), Vector3(inside * 0.16, 1.10, z),
            Vector3(0.22, 0.20, 0.25), STEEL, 0.04)
        _cyl(wall, "V31_LockPin_%d" % int(z * 100), Vector3(inside * 0.16, 1.10, z),
            0.057, 0.33, Vector3.BACK, ALLOY, lod)
    for z in [-0.64, 0.64]:
        _box(wall, "V31_OuterInset_%d" % int(z * 100),
            Vector3(float(side) * 0.222, 0.39, z), Vector3(0.065, 0.50, 0.64),
            DARK, 0.022, 0.46)
        _box(wall, "V31_OuterInsetEdge_%d" % int(z * 100),
            Vector3(float(side) * 0.26, 0.16, z), Vector3(0.04, 0.07, 0.58),
            accent, 0.009, 0.35)
    for z in ([-0.91, 0.91] if lod == 13 else [0.91]):
        _brace(core, wall, side, z, lod)
    if lod == 13:
        for z in [-1.06, -0.34, 0.34, 1.06]:
            _cyl(wall, "V31_InnerFastener_%d" % int(z * 100),
                Vector3(inside * 0.33, 0.22, z), 0.042, 0.05, Vector3.RIGHT, ALLOY, lod)

static func _wall(core: Node3D, side: int, accent: Color, lod: int) -> void:
    var wall: Node3D = core.get_node_or_null("V2_BarreraArticulada_%d" % side) as Node3D
    if wall == null:
        return
    # Shift pivot to the real hinge center, preserve all existing world
    # positions when deployed. Rotation is now about the longitudinal axle.
    for child in wall.get_children():
        if child is Node3D:
            child.position.y -= 0.30
    wall.position.y = 0.30
    _replace(wall, "PanelBlindajeCerrado", 0.075, STEEL, 0.52)
    _replace(wall, "CaraInteriorMaciza", 0.035, DARK, 0.45)
    _replace(wall, "BarraSuperiorProteccion", 0.035, DARK, 0.54)
    _replace(wall, "FranjaIdentidadExterior", 0.014, accent)
    _replace(wall, "PlacaFaccionInterior", 0.012, accent)
    var old_strut: Node3D = wall.get_node_or_null("RiostraTrasera") as Node3D
    if old_strut != null:
        old_strut.visible = false
    for z in [-1.02, 1.02]:
        _replace(wall, "PerfilAntiImpactos_%d" % int(z * 100), 0.028, DARK, 0.53)
        _box(wall, "V3_ExteriorRib_%d" % int(z * 100), Vector3(float(side) * 0.18, 0.36, z),
            Vector3(0.18, 1.03, 0.17), STEEL, 0.035, 0.49)
    for z in [-1.05, 1.05]:
        var label: String = str(int(z * 100))
        _cyl(wall, "V3_MovingHingeKnuckle_" + label, Vector3(0, 0, z),
            0.17, 0.36, Vector3.BACK, STEEL, lod)
        _cyl(core, "V3_FixedHingeAxle_%d_%s" % [side, label],
            wall.position + Vector3(0, 0, z), 0.105, 0.56, Vector3.BACK, ALLOY, lod)
        for end in [-1, 1]:
            _box(core, "V3_HingeBearing_%d_%s_%d" % [side, label, end],
                wall.position + Vector3(0, -0.045, z + float(end) * 0.245),
                Vector3(0.30, 0.34, 0.13), DARK, 0.035, 0.54)
    for z in [-0.55, 0.55]:
        _box(wall, "V3_ArmorModule_%d" % int(z * 100), Vector3(float(side) * 0.151, 0.34, z),
            Vector3(0.11, 0.76, 0.91), STEEL, 0.045, 0.55)
        _box(wall, "V3_ModuleLowerRim_%d" % int(z * 100), Vector3(float(side) * 0.205, 0.02, z),
            Vector3(0.095, 0.10, 0.87), DARK, 0.018)
    if lod == 13:
        for z in [-1.20, -0.62, 0.62, 1.20]:
            _cyl(wall, "V3_ArmorFastener_%d" % int(z * 100), Vector3(float(side) * 0.225, 0.55, z),
                0.052, 0.055, Vector3.RIGHT, ALLOY, lod)

    _armor_v31(core, wall, side, accent, lod)
    _locks_v33(core, wall, side, accent, lod)

# V3.3 captive safety bolts slide along the hinge axle into a rotating
# sector. Two detents correspond to transport and standing configurations.
static func _locks_v33(core: Node3D, wall: Node3D, side: int, accent: Color, lod: int) -> void:
    for z in [-1.05, 1.05]:
        var label: String = "%d_%d" % [side, int(z * 100)]
        var center: Vector3 = wall.position + Vector3(0, 0, z)
        _cyl(wall, "V33_Sector_" + str(int(z * 100)), Vector3(0, 0, z + 0.22),
            0.23, 0.085, Vector3.BACK, DARK, lod)
        _box(core, "V33_LockHousing_" + label, center + Vector3(0, 0.105, z * 0.0 + 0.40),
            Vector3(0.26, 0.21, 0.23), STEEL, 0.035)
        var bolt: Node3D = _group(core, "V33_CaptiveLock_" + label, center + Vector3(0, 0.105, 0.31))
        bolt.set_meta("home_z", bolt.position.z)
        _cyl(bolt, "Pin", Vector3.ZERO, 0.050, 0.30, Vector3.BACK, ALLOY, lod)
        _cyl(bolt, "Grip", Vector3(0, 0, 0.19), 0.085, 0.10, Vector3.BACK, accent, lod)
        if lod == 13:
            _box(bolt, "GripTab", Vector3(0, 0.078, 0.19),
                Vector3(0.16, 0.055, 0.07), DARK, 0.012)

static func _lock_pose(core: Node3D, release: float) -> void:
    for child in core.get_children():
        if not str(child.name).begins_with("V33_CaptiveLock_"):
            continue
        var bolt: Node3D = child as Node3D
        bolt.position.z = float(bolt.get_meta("home_z")) + 0.16 * clampf(release, 0.0, 1.0)

# Timeline is reversible and deterministic; there is no game-process loop.
# 0-.15: unlock; .15-.85: lift; .85-1: secure.
static func deployment_frame(root: Node3D, timeline: float) -> bool:
    if root == null or root.get_meta("defense_art_v3", 0) != 3 or int(root.get_meta("visual_damage", 0)) >= 2:
        return false
    var t: float = clampf(timeline, 0.0, 1.0)
    var lift: float = smoothstep(0.15, 0.85, t)
    var release: float = minf(smoothstep(0.0, 0.15, t), 1.0 - smoothstep(0.85, 1.0, t))
    if not pose(root, lift):
        return false
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
    _lock_pose(core, release)
    root.set_meta("defense_v33_timeline", t)
    root.set_meta("defense_v33_lock_release", release)
    root.set_meta("visual_deploy_progress", lift)
    return true

static func _deck(core: Node3D, accent: Color, lod: int) -> void:
    _replace(core, "V2_SueloCentralOcupable", 0.012, CANVAS_DARK, 0.05)
    # Low traction deck; no object at infantry standing height.
    for i in range(3):
        var z: float = -0.80 + float(i) * 0.78
        _box(core, "V3_DeckPanel_%d" % i, Vector3(0, 0.109, z),
            Vector3(1.90, 0.025, 0.70), RUBBER, 0.005, 0.05)
        if lod == 13:
            for side in [-1, 1]:
                _box(core, "V3_DeckGrip_%d_%d" % [i, side], Vector3(float(side) * 0.62, 0.13, z),
                    Vector3(0.32, 0.016, 0.56), ALLOY, 0.003)
    for side in [-1, 1]:
        _replace(core, "V2_CimentacionBarrera_%d" % side, 0.065, DARK, 0.55)
        _replace(core, "V2_BalizaEntrada_%d" % side, 0.045, DARK, 0.45)
        _replace(core, "V2_BalizaColor_%d" % side, 0.03, accent)
        _replace(core, "V2_CubiertaCajaMaterial_%d" % side, 0.07, STEEL)
        _replace(core, "V2_CintaMaterialFaccion_%d" % side, 0.018, accent)

# V3.2 rear retention frame and engineering equipment. These are sealed
# decorative objects, not production sites, weapons, or interactive inventory.
static func _rear_v32(rear: Node3D, accent: Color, lod: int, damage: int) -> void:
    var frame: Node3D = _group(rear, "V32_RetentionFrame")
    for side in [-1, 1]:
        for x in [0.76, 2.32]:
            if damage >= 2 and side == 1 and x > 2.0:
                continue
            var xpos: float = float(side) * x
            _box(frame, "V32_Stanchion_%d_%d" % [side, int(x * 100)], Vector3(xpos, 0.55, 2.94),
                Vector3(0.12, 1.00, 0.15), DARK, 0.027)
            _box(frame, "V32_StanchionFoot_%d_%d" % [side, int(x * 100)], Vector3(xpos, 0.10, 2.99),
                Vector3(0.30, 0.16, 0.39), STEEL, 0.033)
            if lod == 13:
                _cyl(frame, "V32_StanchionPin_%d_%d" % [side, int(x * 100)], Vector3(xpos, 0.20, 3.06),
                    0.044, 0.065, Vector3.UP, ALLOY, lod)
        var rail_x: float = float(side) * 1.52
        _box(frame, "V32_UpperRetainer_%d" % side, Vector3(rail_x, 0.79 if lod == 13 else 0.66, 2.99),
            Vector3(2.95, 0.105, 0.13), STEEL, 0.024).rotation_degrees.z = -9.0 if damage >= 2 and side == 1 else 0.0
        _box(frame, "V32_LowerRetainer_%d" % side, Vector3(rail_x, 0.37, 2.99),
            Vector3(2.95, 0.095, 0.13), DARK, 0.018)
    # Tie the former central fascia to the outer frame with end caps.
    for side in [-1, 1]:
        _box(frame, "V32_FasciaEndCap_%d" % side, Vector3(float(side) * 1.44, 1.10, 2.91),
            Vector3(0.16, 0.22, 0.25), DARK, 0.026)
        _box(frame, "V32_IdentityTab_%d" % side, Vector3(float(side) * 2.32, 0.52, 3.08),
            Vector3(0.21, 0.21, 0.05), accent, 0.011)

static func _case_v32(parent: Node3D, side: int, accent: Color, lod: int, damage: int) -> void:
    var x: float = float(side) * 3.07
    # Existing flank cases are retained and converted to fabricated tool chests.
    var base: Node3D = _group(parent, "V32_ToolChestHardware_%d" % side, Vector3(x, 0, 1.45))
    _box(base, "V32_ChestSkid", Vector3(0, 0.065, 0), Vector3(0.80, 0.12, 0.76), DARK, 0.026)
    _box(base, "V32_ChestLidRim", Vector3(0, 0.61, 0), Vector3(0.81, 0.095, 0.77), DARK, 0.024)
    _box(base, "V32_ChestLid", Vector3(0, 0.68, 0), Vector3(0.76, 0.10, 0.72), accent, 0.026)
    for j in [-1, 1]:
        _box(base, "V32_ChestCorner_%d" % j, Vector3(float(j) * 0.31, 0.35, -0.35),
            Vector3(0.105, 0.49, 0.11), DARK, 0.022)
        _box(base, "V32_ChestLatch_%d" % j, Vector3(float(j) * 0.24, 0.54, -0.40),
            Vector3(0.11, 0.17, 0.065), ALLOY, 0.013)
        _cyl(base, "V32_ChestHinge_%d" % j, Vector3(float(j) * 0.23, 0.60, 0.38),
            0.055, 0.22, Vector3.RIGHT, STEEL, lod)
    _box(base, "V32_ChestHandle", Vector3(0, 0.35, -0.40), Vector3(0.23, 0.085, 0.095), DARK, 0.018)
    if lod == 13:
        for i in range(3):
            _box(base, "V32_ChestPressRib_%d" % i, Vector3(float(side) * 0.38, 0.21 + float(i) * 0.11, 0),
                Vector3(0.05, 0.055, 0.47), STEEL, 0.009)
    if damage >= 2 and side == 1:
        base.rotation_degrees.y = -9.0
        (base.get_node("V32_ChestLid") as Node3D).rotation_degrees.z = -11.0

static func _engineering_v32(core: Node3D, accent: Color, lod: int, damage: int) -> void:
    var gear: Node3D = _group(core, "V32_EngineeringGear")
    for side in [-1, 1]:
        _case_v32(core, side, accent, lod, damage)
        # Work area is a rear alcove entirely beyond the standing center;
        # low equipment is mounted against the sandbag wall, not the hinge.
        var x: float = float(side) * 1.64
        var z: float = 1.73
        var station: Node3D = _group(gear, "V32_EngineeringBay_%d" % side, Vector3(x, 0, z))
        _box(station, "V32_Skid", Vector3(0, 0.073, 0),
            Vector3(1.06, 0.13, 0.65), DARK, 0.033)
        if damage >= 2 and side == 1:
            _box(station, "V32_FallenEquipment", Vector3(0.12, 0.19, 0),
                Vector3(0.70, 0.30, 0.46), STEEL, 0.065).rotation_degrees = Vector3(9, 27, 13)
            continue
        if side == -1:
            # Compact workbench with vice-like clamp and stowed tool case.
            for leg in [-1, 1]:
                _box(station, "V32_BenchLeg_%d" % leg, Vector3(float(leg) * 0.41, 0.36, 0),
                    Vector3(0.13, 0.55, 0.45), STEEL, 0.027)
            _box(station, "V32_BenchTop", Vector3(0, 0.66, 0), Vector3(1.05, 0.15, 0.61), ALLOY, 0.028)
            _box(station, "V32_BenchApron", Vector3(0, 0.55, -0.28),
                Vector3(0.95, 0.16, 0.10), accent, 0.019)
            _box(station, "V32_ClampBase", Vector3(-0.31, 0.78, -0.06),
                Vector3(0.31, 0.13, 0.29), DARK, 0.024)
            for jaw in [-1, 1]:
                _box(station, "V32_ClampJaw_%d" % jaw, Vector3(-0.31 + float(jaw) * 0.095, 0.89, -0.06),
                    Vector3(0.10, 0.18, 0.23), STEEL, 0.022)
            _cyl(station, "V32_ClampScrew", Vector3(-0.31, 0.82, -0.23), 0.038, 0.23, Vector3.RIGHT, ALLOY, lod)
            _box(station, "V32_StowedToolCase", Vector3(0.23, 0.80, 0.04),
                Vector3(0.38, 0.16, 0.33), DARK, 0.033)
        else:
            # Transport rack carrying spare structural profiles, no weapon.
            for leg in [-1, 1]:
                _box(station, "V32_ProfileRackUpright_%d" % leg, Vector3(float(leg) * 0.43, 0.39, 0.02),
                    Vector3(0.12, 0.64, 0.46), DARK, 0.023)
            _box(station, "V32_ProfileRackShelf", Vector3(0, 0.26, 0),
                Vector3(0.96, 0.10, 0.52), STEEL, 0.018)
            for i in range(3 if lod == 13 else 2):
                _box(station, "V32_SpareProfile_%d" % i, Vector3(0, 0.37 + float(i) * 0.115, 0.02),
                    Vector3(0.84, 0.095, 0.31), STEEL, 0.018)
            _box(station, "V32_RackTie", Vector3(0, 0.58, -0.19),
                Vector3(0.91, 0.10, 0.10), accent, 0.018)
    # Edge rails and entry tread carry visual detail without reducing access.
    for side in [-1, 1]:
        for z in [-2.17, -0.55, 1.10]:
            _box(core, "V32_EdgeAnchor_%d_%d" % [side, int(z * 100)],
                Vector3(float(side) * 3.39, 0.095, z), Vector3(0.20, 0.17, 0.27), DARK, 0.035)
        _box(core, "V32_EntryGrip_%d" % side, Vector3(float(side) * 0.85, 0.045, -2.08),
            Vector3(0.48, 0.075, 0.70), RUBBER, 0.012)
        _box(core, "V32_EntryGripEdge_%d" % side, Vector3(float(side) * 1.08, 0.087, -2.08),
            Vector3(0.065, 0.028, 0.63), accent, 0.005)
    for z in [-1.55, 1.32]:
        _box(core, "V32_DeckJoint_%d" % int(z * 100), Vector3(0, 0.035, z),
            Vector3(2.12, 0.052, 0.095), STEEL, 0.011)

# V3.4: structural damage is sculpted, not transparent decals.
const SCORCH := Color("#4B4840")
const EXPOSED := Color("#9C9890")
const FX_ROOT := "V34_DefenseDamageFX"

static func _buckled_panel(size: Vector3, bend: float) -> ArrayMesh:
    var rings: Array = []
    for i in range(5):
        var t: float = float(i) / 4.0
        var x: float = size.x * 0.5 * (1.0 - 0.10 * sin(t * PI))
        var y: float = size.y * 0.5
        var z: float = (t - 0.5) * size.z
        var offset: float = bend * sin(t * PI)
        var ring: Array[Vector3] = [
            Vector3(x, y + offset, z), Vector3(-x, y + offset * 0.7, z),
            Vector3(-x, -y + offset * 0.7, z), Vector3(x, -y + offset, z)]
        rings.append(ring)
    return Solid._loft(rings)

static func _damage_v34(core: Node3D, rear: Node3D, accent: Color, lod: int, damage: int) -> void:
    if damage == 0:
        return
    for side in [-1, 1]:
        var wall: Node3D = core.get_node_or_null("V2_BarreraArticulada_%d" % side) as Node3D
        if wall == null:
            continue
        # Local armor scuffs remain on the panel as it folds.
        var scars: Node3D = _group(wall, "V34_ArmorScars")
        for i in range(3 if lod == 13 else 2):
            var z: float = -0.71 + float(i) * 0.63
            var at := Vector3(float(side) * 0.287, 0.41 + float(i % 2) * 0.07, z)
            var mark: MeshInstance3D = _box(scars, "V34_Scorch_%d" % i, at,
                Vector3(0.019, 0.16, 0.21), SCORCH, 0.008, 0.08)
            mark.rotation_degrees.x = 23.0 + float(i) * 19.0
            _box(scars, "V34_ExposedEdge_%d" % i, at + Vector3(float(side) * 0.012, -0.06, 0.02),
                Vector3(0.016, 0.028, 0.12), EXPOSED, 0.004, 0.46).rotation_degrees.x = -15.0
    if damage < 2:
        return
    var fallen: MeshInstance3D = core.get_node("V2_SeccionBarreraCaida") as MeshInstance3D
    fallen.mesh = _buckled_panel(Vector3(1.40, 0.24, 2.33), 0.25)
    fallen.material_override = _mat(STEEL, 0.45, 0.88)
    fallen.set_meta("defense_v34_buckled", true)
    var paint: Node3D = core.get_node("V2_FragmentoFaccionCaido") as Node3D
    paint.position.y += 0.15
    paint.rotation_degrees.x = 8.0
    _box(core, "V34_DetachedArmorRib", Vector3(2.69, 0.22, -1.60),
        Vector3(0.19, 0.20, 1.13), DARK, 0.035).rotation_degrees = Vector3(6.0, 42.0, 12.0)
    var debris: Node3D = _group(core, "V34_BrokenSupport", Vector3(2.10, 0.14, 0.72))
    _cyl(debris, "V34_DetachedSleeve", Vector3(0, 0.08, 0), 0.09, 0.48, Vector3.BACK, DARK, lod)
    _cyl(debris, "V34_ShearedShaft", Vector3(-0.17, 0.02, 0.27), 0.047, 0.36, Vector3(0.65, 0, 0.75), ALLOY, lod)
    _box(debris, "V34_TornMount", Vector3(0.14, 0.02, -0.25),
        Vector3(0.25, 0.12, 0.24), DARK, 0.025).rotation_degrees.y = 26.0
    # Disturb only the damaged rear corner and keep the central standing
    # area free. Existing intact wall and its visual pose remain available.
    for child in rear.get_children():
        if str(child.name).begins_with("V2_SacoPosterior_") and child is Node3D and child.position.x > 0.75:
            var bag: Node3D = child as Node3D
            bag.position.z -= 0.13
            bag.rotation_degrees.y += 11.0
            bag.rotation_degrees.z -= 6.0
    for i in range(3 if lod == 13 else 2):
        var bag: MeshInstance3D = _part(core, "V34_DisplacedSandbag_%d" % i,
            _bag_mesh(0.69, lod, i + 8), Vector3(1.50 + float(i) * 0.40, 0.17, 2.02 - float(i) * 0.20),
            CANVAS_DARK, 0.0, 0.94)
        bag.rotation_degrees = Vector3(6.0, 21.0 + float(i) * 26.0, -8.0)
    _box(rear, "V34_TornRetainer", Vector3(2.42, 0.17, 2.78),
        Vector3(0.17, 0.19, 0.98), DARK, 0.028).rotation_degrees.y = 34.0

static func _wreck_v34(wreck: Node3D, accent: Color, lod: int) -> void:
    # Recognizable remnants of the original rear retaining frame.
    var rear: Node3D = _group(wreck, "V34_CollapsedRearWall", Vector3(0, 0, 2.38))
    _box(rear, "V34_FallenRearRail", Vector3(-0.79, 0.15, 0),
        Vector3(3.55, 0.19, 0.24), DARK, 0.04).rotation_degrees.y = 9.0
    for i in range(6 if lod == 13 else 4):
        var x: float = -2.55 + float(i) * (0.91 if lod == 13 else 1.5)
        var bag: MeshInstance3D = _part(rear, "V34_RubbleBag_%d" % i,
            _bag_mesh(0.72, lod, i + 12), Vector3(x, 0.17, -0.20 - float(i % 2) * 0.48),
            CANVAS_DARK if i % 2 == 0 else CANVAS, 0.0, 0.94)
        bag.rotation_degrees = Vector3(7.0, float(i) * 22.0, -8.0)
    for side in [-1, 1]:
        var panel: MeshInstance3D = _part(wreck, "V34_CrumpledArmor_%d" % side,
            _buckled_panel(Vector3(1.14, 0.18, 1.83), 0.19), Vector3(float(side) * 2.20, 0.18, -0.65),
            STEEL, 0.46, 0.88)
        panel.rotation_degrees = Vector3(7.0, float(side) * 23.0, -8.0)
        _box(wreck, "V34_TornIdentity_%d" % side, Vector3(float(side) * 2.20, 0.40, -0.65),
            Vector3(0.57, 0.08, 1.03), accent, 0.018).rotation_degrees.y = float(side) * 23.0
    _box(wreck, "V34_CrushedToolChest", Vector3(-1.79, 0.19, 1.31),
        Vector3(0.80, 0.28, 0.62), DARK, 0.055).rotation_degrees = Vector3(7.0, -24.0, 11.0)
    _box(wreck, "V34_DetachedChestLid", Vector3(-2.46, 0.12, 1.65),
        Vector3(0.71, 0.13, 0.60), accent, 0.03).rotation_degrees.y = 22.0

static func _fx(root: Node3D) -> Node3D:
    var existing: Node3D = root.get_node_or_null(FX_ROOT) as Node3D
    if existing != null:
        return existing
    var lod: int = int(root.get_meta("visual_lod", 13))
    var rig: Node3D = _group(root, FX_ROOT)
    rig.set_meta("presentation_only", true)
    var smoke: Node3D = _group(rig, "Smoke")
    var fire: Node3D = _group(rig, "Fire")
    var sparks: Node3D = _group(rig, "Sparks")
    var chips: Node3D = _group(rig, "Chips")
    for i in range(8 if lod == 13 else 4):
        Solid._fx_blob(smoke, "Puff_%d" % i, Color("#455054").lerp(Color("#89928F"), float(i % 3) * 0.24), 0.0, lod)
    for i in range(5 if lod == 13 else 3):
        Solid._fx_blob(fire, "Flame_%d" % i, Color("#E37C31") if i % 2 == 0 else Color("#F6C36D"), 0.8, lod)
    for i in range(8 if lod == 13 else 4):
        Solid._fx_blob(sparks, "Spark_%d" % i, Color("#F5D08A"), 0.9, lod)
    for i in range(4 if lod == 13 else 2):
        _box(chips, "Chip_%d" % i, Vector3.ZERO, Vector3(0.12, 0.065, 0.15), DARK, 0.012).visible = false
    Solid._fx_blob(rig, "Flash", Color("#FFE2A6"), 1.2, lod)
    return rig

static func damage_fx_pose(root: Node3D, kind: String, progress: float) -> bool:
    if root == null or root.get_meta("defense_art_v3", 0) != 3 or kind not in ["idle", "bullet", "blast", "clear"]:
        return false
    var damage: int = int(root.get_meta("visual_damage", 0))
    if damage == 3 and kind in ["bullet", "blast"]:
        return false
    var rig: Node3D = _fx(root)
    var t: float = clampf(progress, 0.0, 1.0)
    for key in ["Smoke", "Fire", "Sparks", "Chips"]:
        for child in rig.get_node(key).get_children():
            child.visible = false
    var flash: Node3D = rig.get_node("Flash") as Node3D
    flash.visible = false
    root.set_meta("defense_v34_fx_kind", kind)
    root.set_meta("defense_v34_fx_phase", t)
    if kind == "clear" or (kind == "idle" and damage == 0):
        return true
    var idle: bool = kind == "idle"
    var blast: bool = kind == "blast"
    if not idle and t >= 1.0:
        return damage_fx_pose(root, "idle", 0.34)
    var origin: Vector3 = Vector3(2.55, 0.48, -0.52) if damage == 2 else Vector3(2.38, 1.36, -0.40)
    if damage == 3:
        origin = Vector3(-1.75, 0.43, 1.35)
    elif damage < 2:
        var wall: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE + "/V2_BarreraArticulada_1") as Node3D
        origin = wall.transform * Vector3(0.29, 0.70 if not blast else 0.45, -0.14)
    if not idle and damage == 2:
        origin = Vector3(2.57, 0.46, -0.46)
    var smoke: Node3D = rig.get_node("Smoke") as Node3D
    for i in range(smoke.get_child_count()):
        var puff: Node3D = smoke.get_child(i) as Node3D
        var p: float = fposmod(t + float(i) / float(smoke.get_child_count()), 1.0) if idle else clampf(t * 1.4 - float(i) * 0.035, 0.0, 1.0)
        var size: float = (0.18 + p * 0.62) * sin(PI * p) * (1.0 if blast or damage >= 2 else 0.48)
        puff.visible = p > 0.04 and p < 0.96 and (idle or t > 0.11) and (blast or damage >= 2 or i < 3)
        puff.position = origin + Vector3(p * 0.46 + sin(float(i) * 2.4) * size * 0.54, p * 1.37, cos(float(i) * 1.8) * size * 0.6)
        puff.scale = Vector3(size * 1.6, size * 1.35, size * 1.55)
    var fire: Node3D = rig.get_node("Fire") as Node3D
    for i in range(fire.get_child_count()):
        var flame: Node3D = fire.get_child(i) as Node3D
        var size: float = (0.65 + 0.22 * sin(t * TAU * 3.0 + float(i))) * (0.88 if idle else maxf(0.0, 1.38 - t * 1.6))
        flame.visible = (idle and damage >= 2) or (blast and t > 0.06 and t < 0.62)
        flame.position = origin + Vector3(sin(float(i) * 2.4) * 0.23, size * 0.35, cos(float(i) * 2.4) * 0.19)
        flame.scale = Vector3(size * 0.47, size * 0.92, size * 0.43)
        flame.rotation_degrees.z = sin(t * TAU + float(i)) * 18.0
    if idle:
        return true
    flash.visible = t > 0.0 and t < (0.18 if blast else 0.12)
    flash.position = origin
    flash.scale = Vector3.ONE * maxf(0.025, (1.18 if blast else 0.34) * sin(PI * clampf(t / (0.18 if blast else 0.12), 0.0, 1.0)))
    var sparks: Node3D = rig.get_node("Sparks") as Node3D
    for i in range(sparks.get_child_count()):
        var spark: Node3D = sparks.get_child(i) as Node3D
        spark.visible = t > 0.02 and t < (0.65 if blast else 0.43)
        spark.position = origin + Vector3(cos(float(i) * 2.4), 0.55, sin(float(i) * 2.4)) * t * (1.7 if blast else 0.65) - Vector3.UP * t * t * 0.48
        spark.scale = Vector3(0.045, 0.15 if blast else 0.09, 0.045) * (1.0 - t * 0.7)
    var chips: Node3D = rig.get_node("Chips") as Node3D
    for i in range(chips.get_child_count()):
        var chip: Node3D = chips.get_child(i) as Node3D
        chip.visible = blast and t > 0.08 and t < 0.82
        chip.position = origin + Vector3(cos(float(i) * 2.1) * t * 1.55, sin(PI * t) * 0.95 - t * 0.58, sin(float(i) * 2.1) * t * 1.3)
        chip.rotation_degrees = Vector3(t * 280.0, float(i) * 37.0 + t * 190.0, t * 210.0)
    return true


static func apply(root: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if root == null or root.get_meta("camp_kind", "") != "defensivo":
        return false
    root.set_meta("defense_art_v3", 3)
    root.set_meta("defense_art_revision", "3.4")
    _replace(root, "PlataformaDesmontable", 0.045, CANVAS_DARK, 0.06)
    if damage == 3:
        var wreck: Node3D = _group(root, "V3_DefenseWreck")
        for i in range(3 if lod == 13 else 2):
            var fragment: MeshInstance3D = _box(wreck, "V3_FallenArmor_%d" % i,
                Vector3(-1.8 + float(i) * 1.65, 0.17, 0.93 - float(i) * 0.52),
                Vector3(0.83, 0.23, 1.36), STEEL, 0.055)
            fragment.rotation_degrees = Vector3(8.0, float(i) * 27.0 + 14.0, -9.0)
        _box(wreck, "V3_WreckFactionPlate", Vector3(-1.8, 0.29, 0.93),
            Vector3(0.49, 0.08, 0.73), accent, 0.016).rotation_degrees.y = 14.0
        _part(wreck, "V3_FallenSandbag", _bag_mesh(0.86, lod, 4), Vector3(2.23, 0.17, 1.88), CANVAS_DARK, 0.0, 0.89)
        _wreck_v34(wreck, accent, lod)
        return damage_fx_pose(root, "idle", 0.34)
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
    var rear: Node3D = core.get_node("V2_MurallaTrasera") as Node3D
    _rear(rear, accent, lod, damage)
    _rear_v32(rear, accent, lod, damage)
    for child in core.get_children():
        if str(child.name).begins_with("V2_SacosFlanco_"):
            _bag(child as Node3D, 0.82, lod, int(str(child.name).get_slice("_", 3)) + 2)
    for side in [-1, 1]:
        _wall(core, side, accent, lod)
    _deck(core, accent, lod)
    _engineering_v32(core, accent, lod, damage)
    if damage >= 2:
        _replace(core, "V2_SeccionBarreraCaida", 0.08, STEEL, 0.50)
        _replace(core, "V2_FragmentoFaccionCaido", 0.018, accent)
    _damage_v34(core, rear, accent, lod, damage)
    if not pose(root, 1.0):
        return false
    if damage > 0:
        damage_fx_pose(root, "idle", 0.34)
    return true

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("defense_art_v3", 0) != 3:
        return true
    var t: float = clampf(progress, 0.0, 1.0)
    if int(root.get_meta("visual_damage", 0)) < 3:
        var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
        for side in [-1, 1]:
            var wall: Node3D = core.get_node_or_null("V2_BarreraArticulada_%d" % side) as Node3D
            if wall != null:
                wall.rotation_degrees = Vector3(0, 0, float(side) * lerpf(78.0, 0.0, t))
        _brace_pose(core)
        var release: float = 1.0 if t > 0.001 and t < 0.999 else 0.0
        _lock_pose(core, release)
        root.set_meta("defense_v33_lock_release", release)
    root.set_meta("defense_v33_timeline", t)
    root.set_meta("defense_v3_deploy_progress", t)
    return true
