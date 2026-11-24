extends RefCounted
class_name TarvokaCampSupplySculptV4

# Native geometry revision of the same temporary supply camp. V2 hinges,
# V3 layout and faction paint remain. V4 replaces visible primitive bodies
# rather than piling a second camp over the first.
const CORE := "SupplyV4_IndustrialSculpt"
const STEEL := Color("#53646C")
const FRAME := Color("#293840")
const PANEL := Color("#85928E")
const DECK := Color("#65716D")
const GASKET := Color("#303C40")
const ZINC := Color("#B9C5C6")
const CAUTION := Color("#D5AC57")
const WEATHERED := Color("#56605B")
const SCORCH := Color("#323A38")
const EXPOSED := Color("#9FA9A7")
const OXIDE := Color("#81654B")
static var _finish_cache: Dictionary = {}

# Shared deterministic, opaque material maps. No external images, dynamic
# shader dependencies or asynchronous noise generation in the Web export.
# Neutral/faction pigments retain their exact base albedo colors.
static func _finish_map(kind: String) -> ImageTexture:
    if _finish_cache.has(kind):
        return _finish_cache[kind] as ImageTexture
    var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    var noise := FastNoiseLite.new()
    noise.seed = 4172
    noise.frequency = 0.17
    for y in range(64):
        for x in range(64):
            var grain: float = noise.get_noise_2d(float(x), float(y))
            var speck: float = float(posmod(x * 37 + y * 67 + x * y * 13, 97)) / 96.0 - 0.5
            var factor: float = 0.91 + grain * 0.10 + speck * 0.045
            if kind == "metal":
                factor += 0.036 * sin(float(y) * TAU / 8.0) + 0.025 * sin(float(y) * TAU / 3.2)
            elif kind == "fabric":
                factor += 0.036 * cos(float(x) * TAU / 4.0) * cos(float(y) * TAU / 4.0)
            else:
                factor -= 0.025 * absf(sin(float(x + y) * TAU / 8.0))
            factor = clampf(factor, 0.72, 1.0)
            image.set_pixel(x, y, Color(factor, factor, factor, 1.0))
    image.generate_mipmaps()
    var texture := ImageTexture.create_from_image(image)
    _finish_cache[kind] = texture
    return texture

static func _material(tint: Color, metal: float, rough: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.metallic = metal
    material.roughness = rough
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_BACK
    # Only known surface materials are textured; official faction accents
    # remain unmodified, including the neutral color supplied by the roster.
    var kind: String = ""
    if tint in [STEEL, FRAME, ZINC, EXPOSED, OXIDE]:
        kind = "metal"
    elif tint in [PANEL, WEATHERED]:
        kind = "fabric"
    elif tint in [DECK, GASKET, SCORCH]:
        kind = "rubber"
    if not kind.is_empty():
        material.albedo_texture = _finish_map(kind)
        material.uv1_triplanar = true
        material.uv1_scale = Vector3(2.4, 2.4, 2.4)
        material.set_meta("supply_v42_finish", kind)
    return material

# Godot front faces use clockwise winding. Use the physical outward normal
# from a right-handed triangle, then emit the reversed winding.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _loft(rings: Array) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sides: int = rings[0].size()
    for r in range(rings.size() - 1):
        for i in range(sides):
            var j: int = (i + 1) % sides
            var a: Vector3 = rings[r][i]
            var b: Vector3 = rings[r][j]
            var c: Vector3 = rings[r + 1][j]
            var d: Vector3 = rings[r + 1][i]
            _tri(st, a, b, c)
            _tri(st, a, c, d)
    for end in [0, rings.size() - 1]:
        var center := Vector3.ZERO
        for vertex in rings[end]:
            center += Vector3(vertex)
        center /= float(sides)
        for i in range(sides):
            var j: int = (i + 1) % sides
            if end == 0:
                _tri(st, center, rings[end][j], rings[end][i])
            else:
                _tri(st, center, rings[end][i], rings[end][j])
    return st.commit()

static func _octagon(x: float, y: float, chamfer: float, z: float) -> Array[Vector3]:
    return [
        Vector3(x - chamfer, y, z), Vector3(-x + chamfer, y, z),
        Vector3(-x, y - chamfer, z), Vector3(-x, -y + chamfer, z),
        Vector3(-x + chamfer, -y, z), Vector3(x - chamfer, -y, z),
        Vector3(x, -y + chamfer, z), Vector3(x, y - chamfer, z)
    ]

# Closed 3D chamfers in all three axes, not a texture or beveled silhouette
# made from disconnected thin planes.
static func beveled(size: Vector3, requested: float) -> ArrayMesh:
    var h: Vector3 = size * 0.5
    var b: float = minf(requested, minf(h.x, minf(h.y, h.z)) * 0.42)
    var c: float = b
    return _loft([
        _octagon(h.x - b, h.y - b, c * 0.60, -h.z),
        _octagon(h.x, h.y, c, -h.z + b),
        _octagon(h.x, h.y, c, h.z - b),
        _octagon(h.x - b, h.y - b, c * 0.60, h.z)
    ])

# Rounded tank heads with continuous circumferential geometry; the end
# plates share the ring vertices, so neither side can appear hollow.
static func _tank_shell(lod: int) -> ArrayMesh:
    var rings: Array = []
    var profile := [Vector2(-0.69, 0.16), Vector2(-0.66, 0.30),
        Vector2(-0.58, 0.40), Vector2(-0.48, 0.43),
        Vector2(0.48, 0.43), Vector2(0.58, 0.40),
        Vector2(0.66, 0.30), Vector2(0.69, 0.16)]
    var sides: int = 32 if lod == 13 else 12
    for sample in profile:
        var ring: Array[Vector3] = []
        for i in range(sides):
            var a: float = TAU * float(i) / float(sides)
            ring.append(Vector3(cos(a) * sample.y, sin(a) * sample.y, sample.x))
        rings.append(ring)
    return _loft(rings)

static func _group(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = at
    parent.add_child(node)
    return node

static func _part(parent: Node3D, label: String, mesh: Mesh, at: Vector3,
        tint: Color, metal: float = 0.3, rough: float = 0.60) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = mesh
    item.material_override = _material(tint, metal, rough)
    item.position = at
    item.set_meta("supply_v4_closed", true)
    parent.add_child(item)
    return item

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3,
        tint: Color, bevel: float = 0.05, metal: float = 0.35) -> MeshInstance3D:
    return _part(parent, label, beveled(size, bevel), at, tint, metal)

static func _replace_box(parent: Node3D, label: String, bevel: float,
        tint: Color, metal: float, rough: float = 0.65) -> bool:
    var part: MeshInstance3D = parent.get_node_or_null(label) as MeshInstance3D
    if part == null or not part.mesh is BoxMesh:
        return false
    var dimensions: Vector3 = (part.mesh as BoxMesh).size
    part.mesh = beveled(dimensions, bevel)
    part.material_override = _material(tint, metal, rough)
    part.set_meta("supply_v4_closed", true)
    return true

static func _hide(parent: Node3D, label: String) -> void:
    var old: Node3D = parent.get_node_or_null(label) as Node3D
    if old != null:
        old.visible = false

static func _gable(parent: Node3D, label: String, at: Vector3,
        accent: Color, damage: int, lod: int) -> void:
    var pivot: Node3D = _group(parent, label, at)
    # Rear gable closes the previous opening; front gable remains above
    # the door lintel. D2 deliberately loses its damaged right half.
    var contour: Array[Vector2] = [Vector2(1.82, 0.025),
        Vector2(0.0, 0.80), Vector2(-1.82, 0.025),
        Vector2(-1.72, -0.025), Vector2(1.72, -0.025)]
    if damage >= 2:
        contour = [Vector2(0.0, 0.025), Vector2(0.0, 0.80),
            Vector2(-1.82, 0.025), Vector2(-1.72, -0.025),
            Vector2(0.0, -0.025)]
    var rings: Array = []
    for z in [-0.075, 0.075]:
        var ring: Array[Vector3] = []
        for p in contour:
            ring.append(Vector3(p.x, p.y, float(z)))
        rings.append(ring)
    _part(pivot, "V4_GableClosedPanel", _loft(rings), Vector3.ZERO, PANEL, 0.25, 0.76)
    _box(pivot, "V4_GableLowerRail", Vector3(-0.90 if damage >= 2 else 0.0, 0.035, -0.09),
        Vector3(1.72 if damage >= 2 else 3.45, 0.11, 0.09), accent, 0.015)
    if lod == 13:
        for i in range(3):
            _box(pivot, "V4_GableVent_%d" % i,
                Vector3(-0.53, 0.23 + float(i) * 0.075, 0.10),
                Vector3(0.39, 0.033, 0.045), FRAME, 0.007, 0.55)

static func _roof(core: Node3D, accent: Color, lod: int, damage: int) -> bool:
    for side in [-1, 1]:
        var suffix: String = str(side)
        var leaf: Node3D = core.get_node_or_null("V2_ArticulacionCubierta_" + suffix) as Node3D
        if leaf == null:
            if damage >= 2 and side == 1:
                continue
            return false
        if not _replace_box(leaf, "CubiertaAceroContinua_" + suffix, 0.04, PANEL, 0.31, 0.74):
            return false
        for child in leaf.get_children():
            if str(child.name).begins_with("NervaduraTecho_") or str(child.name).begins_with("PlacaTactica_"):
                child.visible = false
        # Both roof leaves now meet at the true centerline, instead of
        # overlapping each other beyond the ridge. The flexible ridge cover
        # is attached to one leaf and folds with it.
        var panel: MeshInstance3D = leaf.get_node("CubiertaAceroContinua_" + suffix) as MeshInstance3D
        panel.mesh = beveled(Vector3(2.13, 0.13, 3.55), 0.035)
        panel.position.x = -float(side) * 1.065
        _hide(leaf, "PerfilSelladoBorde_" + suffix)
        if side == -1 and damage < 2:
            var ridge := CylinderMesh.new()
            ridge.top_radius = 0.092
            ridge.bottom_radius = 0.092
            ridge.height = 3.52
            ridge.radial_segments = 16 if lod == 13 else 8
            var cap: MeshInstance3D = _part(leaf, "V4_ContinuousRidgeCap", ridge,
                Vector3(2.11, 0.073, 0.0), STEEL, 0.45, 0.62)
            cap.rotation_degrees.x = 90.0
        # Narrow folded seams instead of ladder-like exposed bars.
        for i in range(5 if lod == 13 else 3):
            var z: float = -1.31 + float(i) * (0.65 if lod == 13 else 1.30)
            _box(leaf, "V4_CubiertaCostura_%d" % i,
                Vector3(-float(side) * 1.10, 0.077, z),
                Vector3(2.12, 0.055, 0.055), STEEL, 0.01, 0.44)
        _box(leaf, "V4_RoofFactionInlay", Vector3(-float(side) * 1.08, 0.084, 0.86),
            Vector3(1.62, 0.032, 0.48), accent, 0.008, 0.30)
        _box(leaf, "V4_RoofEdgeFold", Vector3(-float(side) * 2.08, 0.015, 0),
            Vector3(0.085, 0.14, 3.44), STEEL, 0.020, 0.46)
    return true

static func _rear(deployable: Node3D, core: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if not _replace_box(deployable, "RefugioLogistico_ParedPosterior", 0.055, PANEL, 0.18, 0.81):
        return false
    for side in [-1, 1]:
        if not _replace_box(deployable, "RefugioLogistico_ParedLateral_%d" % side, 0.04, PANEL, 0.16, 0.80):
            return false
        # The old diagonal tension rods penetrated the new roof. Replace
        # with short bracing fixed between the side wall and eave.
        _hide(deployable, "RefugioLogistico_Tensor_%d" % side)
        var outer: float = float(side) * 2.09
        for z in [0.42, 2.32]:
            var rib: MeshInstance3D = _box(core, "V4_WallRib_%d_%d" % [side, int(z * 100)],
                Vector3(outer, 1.08, z), Vector3(0.11, 1.86, 0.14), FRAME, 0.022, 0.42)
            rib.set_meta("supply_v4_wall_reinforcement", true)
        _box(core, "V4_WallLowerRail_%d" % side, Vector3(outer, 0.30, 1.35),
            Vector3(0.10, 0.19, 2.51), STEEL, 0.025, 0.38)
        _box(core, "V4_WallUpperRail_%d" % side, Vector3(outer, 1.99, 1.35),
            Vector3(0.10, 0.16, 2.51), STEEL, 0.025, 0.38)
        if lod == 13:
            for z in [0.64, 0.88, 1.12, 1.36, 1.60, 1.84, 2.08]:
                _box(core, "V4_SideFoldedSeam_%d_%d" % [side, int(z * 100)],
                    Vector3(float(side) * 2.08, 0.79, z),
                    Vector3(0.037, 0.64, 0.025), STEEL, 0.006, 0.22)
        _box(core, "V4_CornerPost_%d" % side, Vector3(float(side) * 1.95, 1.15, 2.71),
            Vector3(0.21, 2.09, 0.23), FRAME, 0.044, 0.55)
    _box(core, "V4_RearAccessHatch", Vector3(0.49, 1.10, 2.78),
        Vector3(1.37, 1.65, 0.13), STEEL, 0.055, 0.39)
    _box(core, "V4_RearHatchInset", Vector3(0.49, 1.11, 2.86),
        Vector3(1.16, 1.38, 0.055), PANEL, 0.018, 0.31)
    _box(core, "V4_RearHandle", Vector3(0.87, 1.06, 2.91),
        Vector3(0.19, 0.075, 0.095), GASKET, 0.022, 0.53)
    _box(core, "V4_RearFactionPanel", Vector3(-0.86, 1.69, 2.79),
        Vector3(1.46, 0.33, 0.11), accent, 0.027)
    _box(core, "V4_RearVentHousing", Vector3(-0.86, 0.87, 2.79),
        Vector3(1.12, 0.68, 0.15), FRAME, 0.048)
    for i in range(6 if lod == 13 else 3):
        _box(core, "V4_RearVentLouver_%d" % i,
            Vector3(-0.86, 0.63 + float(i) * (0.09 if lod == 13 else 0.18), 2.89),
            Vector3(0.91, 0.052, 0.095), ZINC, 0.008, 0.53)
    _gable(core, "V4_RearGablePivot", Vector3(0, 2.15, 2.66), accent, damage, lod)
    _gable(core, "V4_FrontGablePivot", Vector3(0, 2.19, -0.16), accent, damage, lod)
    return true

static func _equipment(core: Node3D, v2: Node3D, accent: Color, lod: int, damage: int) -> bool:
    for i in range(2):
        var tank: Node3D = v2.get_node_or_null("V2_DepositoCombustibleSellado_%d" % i) as Node3D
        if tank == null:
            return false
        _hide(tank, "DepositoMacizo")
        for side in [-1, 1]:
            _hide(tank, "TapaEstanca_%d" % side)
        # New body lives inside the original damage and deployment group.
        _part(tank, "V4_TankPressureShell", _tank_shell(lod), Vector3.ZERO, STEEL, 0.51, 0.46)
        for band in [-1, 1]:
            var geo := CylinderMesh.new()
            geo.top_radius = 0.449
            geo.bottom_radius = 0.449
            geo.height = 0.105
            geo.radial_segments = 32 if lod == 13 else 12
            var belt: MeshInstance3D = _part(tank, "V4_CurvedTankBand_%d" % band,
                geo, Vector3(0, 0, float(band) * 0.36), accent, 0.37, 0.55)
            belt.rotation_degrees.x = 90.0
            _hide(tank, "CinchaAcero_%d" % (band * 38))
        _box(tank, "V4_TankInspectionPlate", Vector3(0, -0.06, -0.70),
            Vector3(0.25, 0.24, 0.08), FRAME, 0.04, 0.55)
        if lod == 13:
            for side in [-1, 1]:
                _box(tank, "V4_TankSaddleFoot_%d" % side, Vector3(float(side) * 0.39, -0.55, 0.42),
                    Vector3(0.23, 0.10, 0.34), ZINC, 0.026, 0.60)
    var pump: Node3D = v2.get_node_or_null("V2_EstacionBombeo") as Node3D
    if pump == null or not _replace_box(pump, "ArmarioCerrado", 0.11, STEEL, 0.40, 0.57):
        return false
    _replace_box(pump, "PuertaYMarco", 0.035, FRAME, 0.50, 0.58)
    _replace_box(pump, "PanelFaccionAmplio", 0.03, accent, 0.30)
    _box(pump, "V4_PumpRecessedLowerPanel", Vector3(0, 0.46, -0.49),
        Vector3(0.78, 0.38, 0.11), STEEL, 0.035, 0.48)
    for i in range(4 if lod == 13 else 2):
        _box(pump, "V4_PumpVent_%d" % i, Vector3(0, 0.32 + float(i) * (0.08 if lod == 13 else 0.16), -0.56),
            Vector3(0.63, 0.037, 0.045), FRAME, 0.006, 0.42)
    _box(pump, "V4_SideServicePanel", Vector3(-0.54, 1.06, 0.01),
        Vector3(0.09, 0.78, 0.56), PANEL, 0.028, 0.44)
    for i in range(4):
        var crate: Node3D = v2.get_node_or_null("V2_CajaMunicionEstanca_%d" % i) as Node3D
        if crate == null:
            continue
        _replace_box(crate, "CuerpoMonolitico", 0.065, STEEL, 0.35, 0.67)
        _replace_box(crate, "TapaHermetica", 0.033, FRAME, 0.44, 0.60)
        for x in [-1, 1]:
            _box(crate, "V4_CrateCorner_%d" % x, Vector3(float(x) * 0.25, 0.05, -0.325),
                Vector3(0.075, 0.40, 0.08), GASKET, 0.015, 0.22)
        if lod == 13:
            _box(crate, "V4_CrateGrip", Vector3(0, 0.17, -0.37),
                Vector3(0.20, 0.075, 0.08), ZINC, 0.015, 0.62)
    # Replace the dark slab barriers with physical frames. The equipment
    # can now be seen at a low angle rather than being buried behind panels.
    var v3: Node3D = v2.get_node_or_null("SupplyV3_ReadabilityRig") as Node3D
    if v3 == null:
        return false
    for i in range(2):
        var guard: MeshInstance3D = v3.get_node_or_null("V3_ProteccionExternaTanque_%d" % i) as MeshInstance3D
        if guard == null:
            return false
        guard.visible = false
        _hide(v3, "V3_PanelFaccionTanque_%d" % i)
        _hide(v3, "V3_TapaMantenimiento_%d" % i)
        var z: float = -0.45 + float(i) * 1.65
        for end in [-1, 1]:
            _box(core, "V4_TankFramePost_%d_%d" % [i, end],
                Vector3(3.25, 0.55, z + float(end) * 0.57),
                Vector3(0.15, 0.91, 0.15), FRAME, 0.027, 0.46)
        _box(core, "V4_TankFrameTop_%d" % i, Vector3(3.25, 0.97, z),
            Vector3(0.17, 0.14, 1.28), accent, 0.032, 0.37)
        _box(core, "V4_TankFrameBase_%d" % i, Vector3(3.25, 0.18, z),
            Vector3(0.17, 0.16, 1.28), FRAME, 0.025, 0.53)
    for side in [-1, 1]:
        _hide(v2, "ContencionMunicion_%d" % side)
        var x: float = -1.45 + float(side) * 0.64
        for z in [-2.99, -1.15]:
            _box(core, "V4_CrateRackPost_%d_%d" % [side, int(z * 100)],
                Vector3(x, 0.52, z), Vector3(0.12, 0.80, 0.13), FRAME, 0.022, 0.46)
        _box(core, "V4_CrateRackLowerRail_%d" % side,
            Vector3(x, 0.34, -2.06), Vector3(0.12, 0.15, 1.96),
            STEEL, 0.022, 0.40)
    # Continuous curved hose in the original moving hose group. Ring plane
    # follows the tangent, so the elbows share vertices instead of gaps.
    var hose: Node3D = v2.get_node_or_null("V2_MangueraArticulada") as Node3D
    if hose == null:
        return false
    for item in hose.get_children():
        if str(item.name).begins_with("TramoMangueraCaucho_") or str(item.name).begins_with("AcopleManguera_"):
            item.visible = false
    var curve := Curve3D.new()
    curve.add_point(Vector3(0, 0, 0), Vector3.ZERO, Vector3(0.14, -0.10, -0.08))
    curve.add_point(Vector3(0.40, -0.30, -0.27), Vector3(-0.13, 0.07, 0.09), Vector3(0.16, -0.08, -0.13))
    curve.add_point(Vector3(0.68, -0.33, -0.65), Vector3(-0.08, -0.03, 0.11), Vector3(0.055, 0.10, -0.09))
    curve.add_point(Vector3(0.72, 0.02, -0.84), Vector3(0, -0.11, 0.03), Vector3.ZERO)
    var rings: Array = []
    var steps: int = 20 if lod == 13 else 9
    var sides: int = 12 if lod == 13 else 8
    var length: float = curve.get_baked_length()
    for i in range(steps + 1):
        var t: float = length * float(i) / float(steps)
        var center: Vector3 = curve.sample_baked(t, true)
        var forward: Vector3 = (curve.sample_baked(minf(length, t + 0.015), true) -
            curve.sample_baked(maxf(0.0, t - 0.015), true)).normalized()
        var u: Vector3 = forward.cross(Vector3.RIGHT).normalized()
        var v: Vector3 = forward.cross(u).normalized()
        var ring: Array[Vector3] = []
        for k in range(sides):
            var a: float = TAU * float(k) / float(sides)
            ring.append(center + 0.085 * (u * cos(a) + v * sin(a)))
        rings.append(ring)
    _part(hose, "V4_ContinuousHose", _loft(rings), Vector3.ZERO, GASKET, 0.04, 0.88)
    return true

# Small closed cylinders, mounted at a physical surface, not floating
# decoration. Used for mechanical fittings, recessed fasteners and gauges.
static func _fitting(parent: Node3D, label: String, at: Vector3, radius: float,
        depth: float, axis: Vector3, tint: Color, lod: int) -> MeshInstance3D:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = depth
    cylinder.radial_segments = 16 if lod == 13 else 8
    var piece: MeshInstance3D = _part(parent, label, cylinder, at, tint, 0.57, 0.49)
    piece.quaternion = Quaternion(Vector3.UP, axis.normalized())
    return piece

static func _finish_hardware(core: Node3D, v2: Node3D, accent: Color, lod: int, damage: int) -> void:
    # The tank fittings live on their original moving/damaged tank groups.
    # This is fictional service hardware and has no operational simulation.
    for i in range(2):
        var tank: Node3D = v2.get_node("V2_DepositoCombustibleSellado_%d" % i) as Node3D
        _fitting(tank, "V42_InspectionFlange", Vector3(0, 0.00, -0.735),
            0.145, 0.075, Vector3.FORWARD, ZINC, lod)
        _fitting(tank, "V42_InspectionCap", Vector3(0, 0.00, -0.79),
            0.095, 0.06, Vector3.FORWARD, FRAME, lod)
        _fitting(tank, "V42_ValveCollar", Vector3(0, 0.46, -0.18),
            0.155, 0.07, Vector3.UP, EXPOSED, lod)
        if lod == 13:
            for side in [-1, 1]:
                for z in [-0.36, 0.36]:
                    _fitting(tank, "V42_BandFastener_%d_%d" % [side, int(z * 100)],
                        Vector3(float(side) * 0.415, 0.15, z),
                        0.045, 0.075, Vector3(float(side), 0, 0), ZINC, lod)
    var pump: Node3D = v2.get_node("V2_EstacionBombeo") as Node3D
    _box(pump, "V42_InstrumentBezel", Vector3(-0.12, 1.03, -0.558),
        Vector3(0.42, 0.30, 0.045), FRAME, 0.012, 0.45)
    var screen: MeshInstance3D = _box(pump, "V42_InstrumentFace", Vector3(-0.12, 1.03, -0.585),
        Vector3(0.33, 0.20, 0.024), Color("#334E50"), 0.005, 0.08)
    var screen_material: StandardMaterial3D = screen.material_override as StandardMaterial3D
    screen_material.roughness = 0.29
    _box(pump, "V42_InstrumentReadout", Vector3(-0.12, 1.045, -0.602),
        Vector3(0.22, 0.044, 0.014), Color("#9CBFA7") if damage == 0 else Color("#52655D"), 0.003, 0.03)
    _fitting(pump, "V42_FrontDial", Vector3(0.28, 0.95, -0.55),
        0.086, 0.055, Vector3.FORWARD, ZINC, lod)
    _fitting(pump, "V42_FrontDialCenter", Vector3(0.28, 0.95, -0.585),
        0.057, 0.024, Vector3.FORWARD, FRAME, lod)
    _box(pump, "V42_DialMark", Vector3(0.28, 0.973, -0.602),
        Vector3(0.015, 0.05, 0.015), CAUTION, 0.003, 0.1)
    for side in [-1, 1]:
        _box(core, "V42_RearHinge_%d" % side, Vector3(-0.19, 1.10 + float(side) * 0.53, 2.865),
            Vector3(0.15, 0.19, 0.11), FRAME, 0.025, 0.48)
        _fitting(core, "V42_RearHingePin_%d" % side,
            Vector3(-0.19, 1.10 + float(side) * 0.53, 2.93),
            0.055, 0.045, Vector3.BACK, ZINC, lod)
        _box(core, "V42_SideAccessTrim_%d" % side,
            Vector3(float(side) * 2.09, 0.62, 1.35),
            Vector3(0.06, 0.55, 0.74), STEEL, 0.018, 0.30)
    if lod == 13:
        for side in [-1, 1]:
            for z in [0.37, 2.30]:
                for y in [0.40, 1.72]:
                    _fitting(core, "V42_WallFastener_%d_%d_%d" % [side, int(z * 100), int(y * 100)],
                        Vector3(float(side) * 2.16, y, z), 0.034, 0.034,
                        Vector3(float(side), 0, 0), ZINC, lod)
        for x in [0.01, 0.40, 0.79]:
            _fitting(core, "V42_DeckAnchor_%d" % int(x * 100),
                Vector3(x, 0.035, -2.83), 0.038, 0.035, Vector3.UP, FRAME, lod)

# Closed, displaced loft replacing an actual roof leaf. Its volume remains
# manifold even after a buckle; it is not an open, paper-thin torn face.
static func _buckled_roof() -> ArrayMesh:
    var rings: Array = []
    for z in [-1.775, -0.80, 0.0, 0.80, 1.775]:
        var ring: Array[Vector3] = _octagon(1.065, 0.065, 0.025, z)
        for i in range(ring.size()):
            var p: Vector3 = ring[i]
            var factor: float = maxf(0.0, 1.0 - absf(z) / 1.775)
            p.y += factor * (0.15 + 0.11 * p.x)
            p.x += factor * 0.065
            ring[i] = p
        rings.append(ring)
    return _loft(rings)

static func _damage_finish(root: Node3D, core: Node3D, v2: Node3D, lod: int, damage: int) -> void:
    if damage <= 0:
        return
    var marks: Node3D = _group(core, "V42_DamageOnly")
    # Visible abrasion volumes with thin closed profiles, not alpha decals.
    for i in range(4 if lod == 13 else 2):
        var scrape: MeshInstance3D = _box(marks, "V42_RearAbrasion_%d" % i,
            Vector3(0.18 + float(i) * 0.15, 0.46 + float(i % 2) * 0.09, 2.897),
            Vector3(0.17, 0.027, 0.015), EXPOSED, 0.004, 0.42)
        scrape.rotation_degrees.z = -18.0 + float(i) * 13.0
    var pump: Node3D = v2.get_node("V2_EstacionBombeo") as Node3D
    _box(pump, "V42_ScuffedFoot", Vector3(-0.28, 0.25, -0.545),
        Vector3(0.29, 0.095, 0.035), WEATHERED, 0.010, 0.14)
    if damage < 2:
        return
    var leaf: Node3D = v2.get_node("V2_ArticulacionCubierta_-1") as Node3D
    var panel: MeshInstance3D = leaf.get_node("CubiertaAceroContinua_-1") as MeshInstance3D
    panel.mesh = _buckled_roof()
    panel.material_override = _material(WEATHERED, 0.22, 0.89)
    panel.set_meta("supply_v42_buckled", true)
    # Hardware on the displaced roof follows the surviving sheet.
    for child in leaf.get_children():
        if child != panel and str(child.name).begins_with("V4_CubiertaCostura_"):
            child.position.y += 0.12
    var patch: MeshInstance3D = _box(leaf, "V42_RoofScorch", Vector3(0.52, 0.19, 0.25),
        Vector3(0.66, 0.035, 0.45), SCORCH, 0.009, 0.08)
    patch.rotation_degrees.y = 12.0
    for i in range(3 if lod == 13 else 1):
        var rubble: MeshInstance3D = _box(marks, "V42_DetachedTrim_%d" % i,
            Vector3(2.22 + float(i) * 0.25, 0.09, -2.48 + float(i) * 0.23),
            Vector3(0.48, 0.10, 0.13), OXIDE if i == 1 else FRAME, 0.02, 0.4)
        rubble.rotation_degrees = Vector3(9.0, 22.0 + float(i) * 19.0, 11.0)
    root.set_meta("suministros_v42_physical_damage", true)

static func apply(root: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if root == null or root.get_meta("camp_kind", "") != "suministros":
        return false
    root.set_meta("suministros_art_v4", 4)
    root.set_meta("suministros_art_revision", "4.2")
    root.set_meta("suministros_v4_no_gameplay_changes", true)
    if not _replace_box(root, "PlataformaDesmontable", 0.045, DECK, 0.08, 0.84):
        return false
    if damage == 3:
        # No new machinery, walls or roofs on the completely destroyed camp.
        for child in root.get_children():
            if str(child.name).begins_with("RestosDesmontables_"):
                _replace_box(root, str(child.name), 0.025, STEEL, 0.45, 0.75)
        return true
    var deployable: Node3D = root.get_node_or_null("EquipamientoDesplegable") as Node3D
    if deployable == null:
        return false
    var v2: Node3D = deployable.get_node_or_null("SupplyV2_PremiumRig") as Node3D
    if v2 == null:
        return false
    var core: Node3D = _group(v2, CORE)
    if not _roof(v2, accent, lod, damage) or not _rear(deployable, core, accent, lod, damage):
        return false
    if not _equipment(core, v2, accent, lod, damage):
        return false
    _finish_hardware(core, v2, accent, lod, damage)
    _damage_finish(root, core, v2, lod, damage)
    # An inset modular non-slip walkway provides scale and a visible
    # access path without creating another permanent platform.
    for i in range(4):
        var z: float = -2.53 + float(i) * 0.67
        _box(core, "V4_WalkwayModule_%d" % i, Vector3(0.40, 0.018, z),
            Vector3(1.45, 0.036, 0.61), Color("#687B7A"), 0.009, 0.13)
        if lod == 13:
            for end in [-1, 1]:
                _box(core, "V4_WalkwayGrip_%d_%d" % [i, end],
                    Vector3(0.40, 0.041, z + float(end) * 0.17),
                    Vector3(1.16, 0.018, 0.033), STEEL, 0.004, 0.22)
    # Low, modular floor joint rails and ground tie-down blocks. The open
    # entrance stays clear and no permanent foundation is added.
    for z in [-0.95, 0.65, 2.17]:
        _box(core, "V4_DeckJoint_%d" % int(z * 100), Vector3(0, 0.025, z),
            Vector3(3.75, 0.036, 0.065), FRAME, 0.008, 0.30)
    for side in [-1, 1]:
        _box(core, "V4_PalletTieDown_%d" % side, Vector3(float(side) * 3.20, 0.10, 2.94),
            Vector3(0.35, 0.17, 0.45), FRAME, 0.04, 0.55)
    return pose(root, 1.0)

static func pose(root: Node3D, progress: float) -> bool:
    if root.get_meta("suministros_art_v4", 0) != 4:
        return true
    if int(root.get_meta("visual_damage", 0)) == 3:
        return true
    var core: Node3D = root.get_node_or_null("EquipamientoDesplegable/SupplyV2_PremiumRig/" + CORE) as Node3D
    if core == null:
        return false
    var rear: Node3D = core.get_node_or_null("V4_RearGablePivot") as Node3D
    var front: Node3D = core.get_node_or_null("V4_FrontGablePivot") as Node3D
    if rear == null or front == null:
        return false
    var t: float = clampf(progress, 0.0, 1.0)
    rear.rotation_degrees.x = lerpf(-88.0, 0.0, t)
    front.rotation_degrees.x = lerpf(88.0, 0.0, t)
    return true
