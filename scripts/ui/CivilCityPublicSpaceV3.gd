extends RefCounted
class_name TarvokaCivilCityPublicSpaceV3

# TARVOKA civil-city V3: additive, native Godot 4.3 meshes.
# Attach to the existing city V2 root when available. No economy, capture,
# unit-production, faction-ownership, fog, pathfinding or turn changes.
# The city faces negative Z; the 16 x 16 m tactical footprint stays fixed.
const STAGE_NAME := "CiudadCivilV3EspaciosPublicos"
const PAVING := Color("#89918a")
const EDGE := Color("#bbc1b8")
const PLANTER := Color("#67766b")
const LEAVES := Color("#587666")
const TRUNK := Color("#776b58")
const WATER := Color("#508a9a")
const LAMP := Color("#d9c6a0")
const IRON := Color("#435259")
const STRIPE := Color("#cec2a2")
static var _material_cache: Dictionary = {}
static var _mesh_cache: Dictionary = {}

static func _material(color: Color) -> StandardMaterial3D:
    var key := color.to_html(true)
    if _material_cache.has(key):
        return _material_cache[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.88
    _material_cache[key] = mat
    return mat

static func _box(parent: Node3D, name: String, center: Vector3,
        size: Vector3, tint: Color) -> void:
    var key := str(size)
    if not _mesh_cache.has(key):
        var mesh := BoxMesh.new()
        mesh.size = size
        _mesh_cache[key] = mesh
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = _mesh_cache[key]
    part.material_override = _material(tint)
    part.position = center
    parent.add_child(part)

static func _cylinder(parent: Node3D, name: String, center: Vector3,
        radius: float, height: float, tint: Color, sides: int = 8) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = sides
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = mesh
    part.position = center
    part.material_override = _material(tint)
    parent.add_child(part)

static func _tree(parent: Node3D, index: int, x: float, z: float) -> void:
    _cylinder(parent, "ArbolTronco_%d" % index,
        Vector3(x, 0.68, z), 0.12, 1.3, TRUNK)
    _cylinder(parent, "ArbolCopa_%d" % index,
        Vector3(x, 1.73, z), 0.69, 1.0, LEAVES, 7)

static func add_details(city_root: Node3D, city_scale: int = 2,
        damaged: bool = false) -> Node3D:
    # Scale: 1 villa, 2 city, 3 metropolis. Stable deterministic detail.
    # Do not install on a root without a valid V2 city below it.
    if city_root.has_node("EspaciosPublicosV3"):
        return city_root.get_node("EspaciosPublicosV3") as Node3D
    var public_space := Node3D.new()
    public_space.name = "EspaciosPublicosV3"
    city_root.add_child(public_space)
    var level: int = clampi(city_scale, 1, 3)
    # Paved entrance plaza and access ramp, below building frontage.
    _box(public_space, "PlazaCivicaPavimento",
        Vector3(0, 0.035, -5.55), Vector3(10.8, 0.07, 3.65), PAVING)
    _box(public_space, "AccesoPrincipalContinuo",
        Vector3(0, 0.075, -7.18), Vector3(2.55, 0.05, 1.45), EDGE)
    for side in [-1, 1]:
        var x: float = float(side) * 3.57
        _box(public_space, "JardinElevado_%d" % side,
            Vector3(x, 0.22, -5.4), Vector3(2.35, 0.40, 0.82), PLANTER)
        _box(public_space, "Vegetacion_%d" % side,
            Vector3(x, 0.48, -5.4), Vector3(2.10, 0.16, 0.62), LEAVES)
        _box(public_space, "Banca_%d" % side,
            Vector3(x, 0.34, -6.35), Vector3(1.45, 0.14, 0.42), TRUNK)
        _box(public_space, "LuminariaPoste_%d" % side,
            Vector3(float(side)*5.02, 1.13, -6.55),
            Vector3(0.13, 2.15, 0.13), IRON)
        _box(public_space, "LuminariaCabezal_%d" % side,
            Vector3(float(side)*5.02, 2.25, -6.55),
            Vector3(0.43, 0.20, 0.43), LAMP)
    # Portal and crosswalk remain legible at overhead tactical zoom.
    for i in range(4):
        _box(public_space, "PasoPeatonal_%d" % i,
            Vector3(-1.17 + float(i)*0.78, 0.105, -7.75),
            Vector3(0.43, 0.018, 0.33), STRIPE)
    if level >= 2:
        for i in range(2):
            var x: float = -5.68 if i == 0 else 5.68
            _tree(public_space, i, x, -4.85)
        _cylinder(public_space, "MonumentoPlazaPedestal",
            Vector3(0, 0.29, -5.35), 0.63, 0.5, EDGE, 10)
        _cylinder(public_space, "MonumentoPlazaColumna",
            Vector3(0, 0.81, -5.35), 0.19, 0.70, IRON, 8)
    if level == 3:
        for side in [-1, 1]:
            _box(public_space, "QuioscoComercial_%d" % side,
                Vector3(float(side)*5.55, 0.90, -1.65),
                Vector3(1.45, 1.70, 1.35), EDGE)
            _box(public_space, "QuioscoToldo_%d" % side,
                Vector3(float(side)*5.55, 1.80, -1.7),
                Vector3(1.82, 0.17, 1.66), IRON)
    if damaged:
        # Cosmetic only: no collision/blocking and no altered resource yield.
        _box(public_space, "PavimentoDeteriorado",
            Vector3(2.55, 0.082, -5.67),
            Vector3(1.62, 0.016, 0.12), IRON)
    return public_space

static func inspect_detail_names(city_root: Node3D) -> PackedStringArray:
    var names := PackedStringArray()
    if not city_root.has_node("EspaciosPublicosV3"):
        return names
    for detail in city_root.get_node("EspaciosPublicosV3").get_children():
        names.append(detail.name)
    return names
