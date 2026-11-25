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
            _bag(child as Node3D, 0.86 if lod == 8 else 0.69, lod, seed)
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

static func apply(root: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if root == null or root.get_meta("camp_kind", "") != "defensivo":
        return false
    root.set_meta("defense_art_v3", 3)
    root.set_meta("defense_art_revision", "3.1")
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
        return true
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
    var rear: Node3D = core.get_node("V2_MurallaTrasera") as Node3D
    _rear(rear, accent, lod, damage)
    for child in core.get_children():
        if str(child.name).begins_with("V2_SacosFlanco_"):
            _bag(child as Node3D, 0.82, lod, int(str(child.name).get_slice("_", 3)) + 2)
    for side in [-1, 1]:
        _wall(core, side, accent, lod)
    _deck(core, accent, lod)
    if damage >= 2:
        _replace(core, "V2_SeccionBarreraCaida", 0.08, STEEL, 0.50)
        _replace(core, "V2_FragmentoFaccionCaido", 0.018, accent)
    return pose(root, 1.0)

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
    root.set_meta("defense_v3_deploy_progress", t)
    return true
