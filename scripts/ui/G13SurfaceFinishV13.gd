extends RefCounted
class_name TarvokaG13SurfaceFinishV13

# Native G13 PBR and physical side panel detailing. Hero LOD13 only.
# No changes to combat, eight official faction palettes or low-cost LOD8.
const FLAG := "tarvoka_g13_surface_detail_v13"
const SIDE_PLATE := "G13_V13_BeveledSidePanel_%d"
const SLOTS := "G13_V13_SideVent_%d_%d"
const FASTENERS := "G13_V13_SideFasteners"
static var _roughness_map: Texture2D

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var out := StandardMaterial3D.new()
    out.albedo_color = color
    out.metallic = metal
    out.roughness = rough
    out.cull_mode = BaseMaterial3D.CULL_DISABLED
    return out

static func _noise_map() -> Texture2D:
    if _roughness_map != null:
        return _roughness_map
    # Generated only once for both factions/panels. The noise is subtle,
    # deterministic and uses built-in box UVs, not per-frame shaders.
    var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var seed: int = (x * 337 + y * 619 + x * y * 29) % 101
            var groove: float = 0.06 if (x + 3 * y) % 31 < 2 else 0.0
            var value: float = clampf(0.79 + 0.0014 * float(seed) + groove,
                0.0, 1.0)
            img.set_pixel(x, y, Color(value, value, value, 1.0))
    _roughness_map = ImageTexture.create_from_image(img)
    return _roughness_map

static func _recoat(root: Node3D, name: String,
        metallic: float, roughness: float, use_noise: bool = false) -> bool:
    var piece := root.find_child(name, true, false) as MeshInstance3D
    if piece == null:
        return false
    var original := piece.material_override as StandardMaterial3D
    if original == null:
        return false
    var coat := original.duplicate() as StandardMaterial3D
    # Deliberately preserve albedo_color: all eight faction colors stay intact.
    coat.metallic = metallic
    coat.roughness = roughness
    if use_noise and piece.mesh is BoxMesh:
        coat.roughness_texture = _noise_map()
        coat.uv1_scale = Vector3(1.8, 1.8, 1.0)
    piece.material_override = coat
    return true

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var n: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _plate(side: int) -> ArrayMesh:
    # Closed raised chamfered panel on the mid-body between the wheel arches.
    # Frontal and rear plates are deliberately omitted; old headlamps/tailgate
    # and the G13 V11 rear-deck geometry remain fully visible.
    var s: float = float(side)
    var shape: Array[Vector2] = [
        Vector2(-0.34, 0.760), Vector2(0.34, 0.760),
        Vector2(0.385, 0.795), Vector2(0.385, 0.915),
        Vector2(0.34, 0.958), Vector2(-0.34, 0.958),
        Vector2(-0.385, 0.915), Vector2(-0.385, 0.795)
    ]
    var front: Array[Vector3] = []
    var back: Array[Vector3] = []
    for point in shape:
        front.append(Vector3(s * 0.715, point.y, point.x))
        back.append(Vector3(s * 0.683, point.y, point.x))
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(8):
        var j: int = (i + 1) % 8
        _tri(st, front[i], back[j], front[j])
        _tri(st, front[i], back[i], back[j])
    for i in range(1, 7):
        _tri(st, front[0], front[i], front[i + 1])
        _tri(st, back[0], back[i + 1], back[i])
    return st.commit()

static func _box(parent: Node3D, name: String, position: Vector3,
        dimensions: Vector3, material: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = name
    var box := BoxMesh.new()
    box.size = dimensions
    item.mesh = box
    item.position = position
    item.material_override = material
    parent.add_child(item)
    return item

static func _bolts(hull: Node3D, material: Material) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = 0.012
    mesh.height = 0.008
    mesh.radial_segments = 8
    mesh.rings = 4
    mesh.material = material
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = mesh
    mm.instance_count = 8
    var n: int = 0
    for side in [-1, 1]:
        for z in [-0.315, 0.315]:
            for y in [0.792, 0.928]:
                mm.set_instance_transform(n, Transform3D(
                    Basis.IDENTITY, Vector3(float(side) * 0.720,
                        float(y), float(z))))
                n += 1
    var draw := MultiMeshInstance3D.new()
    draw.name = FASTENERS
    draw.multimesh = mm
    hull.add_child(draw)

static func apply(root: Node3D) -> bool:
    if root == null or bool(root.get_meta(FLAG, false)) or (
            not bool(root.get_meta("tarvoka_g13_mechanical_finish_v12", false))):
        return false
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    if hull == null:
        return false
    # Validate everything before changing the tree so partial builds cannot
    # produce mismatched faction LODs.
    var original_names: Array[String] = [
        "G13_V10_ChamferedCabShell",
        "G13_V10_ChamferedTurretShell",
        "G13_V11_ArmoredRoof",
        "G13_V11_TaperedRearDeck",
        "G13_RearServiceDoor",
        "G13_EngineCover",
        "G13_V2_RoofFaction"
    ]
    for name in original_names:
        if root.find_child(name, true, false) == null:
            return false
    for side in [-1, 1]:
        for name in [
            "G13_V12_TrunnionFixed_%d" % side,
            "G13_V12_TrunnionFollower_%d" % side,
            "G13_V12_RecoilSleeve_%d" % side,
            "G13_V2_FactionFlank_%d" % side,
            "G13_V2_ExhaustGuard_%d" % side
        ]:
            if root.find_child(name, true, false) == null:
                return false
    var finished: int = 0
    for name in [
        "G13_V10_ChamferedCabShell",
        "G13_V11_ArmoredRoof",
        "G13_V11_TaperedRearDeck"
    ]:
        if _recoat(root, name, 0.32, 0.69):
            finished += 1
    if _recoat(root, "G13_V10_ChamferedTurretShell", 0.38, 0.59):
        finished += 1
    if _recoat(root, "G13_EngineCover", 0.38, 0.72, true):
        finished += 1
    if _recoat(root, "G13_RearServiceDoor", 0.35, 0.72, true):
        finished += 1
    if _recoat(root, "G13_V2_RoofFaction", 0.31, 0.58):
        finished += 1
    for side in [-1, 1]:
        if _recoat(root, "G13_V12_TrunnionFixed_%d" % side, 0.31, 0.76):
            finished += 1
        if _recoat(root, "G13_V12_TrunnionFollower_%d" % side, 0.66, 0.47):
            finished += 1
        if _recoat(root, "G13_V12_RecoilSleeve_%d" % side, 0.55, 0.50):
            finished += 1
        if _recoat(root, "G13_V2_FactionFlank_%d" % side, 0.30, 0.61):
            finished += 1
        if _recoat(root, "G13_V2_ExhaustGuard_%d" % side, 0.23, 0.87, true):
            finished += 1
    if finished != 17:
        return false

    var edge := _mat(Color("#657377"), 0.35, 0.68)
    var dark := _mat(Color("#29353c"), 0.19, 0.84)
    var alloy := _mat(Color("#a5b0b0"), 0.52, 0.47)
    for side in [-1, 1]:
        var side_panel := MeshInstance3D.new()
        side_panel.name = SIDE_PLATE % side
        side_panel.mesh = _plate(side)
        side_panel.material_override = edge
        hull.add_child(side_panel)
        # Three *inset* vent slits face the camera on each side. They occupy
        # the center of the plate (away from both wheel arches) and do not
        # overlap the colored upper belt.
        for i in range(3):
            _box(hull, SLOTS % [side, i],
                Vector3(float(side) * 0.719, 0.837,
                    -0.095 + float(i) * 0.095),
                Vector3(0.011, 0.045, 0.056), dark)
    _bolts(hull, alloy)
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v13_visual_only", true)
    root.set_meta("tarvoka_g13_v13_pbr_coats", finished)
    return true
