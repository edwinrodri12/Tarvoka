extends RefCounted
class_name TarvokaHeadquartersMapLOD3D

# True low-poly 3D proxy for V4, never touches tactical rules or saves.
# Preserves the original V4 scene in a separate invisible subtree.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const MATERIALS := ["concrete", "steel", "glass", "faction", "gold", "mark"]
const PALETTE := {
    "concrete": Color("#aeb7b6"),
    "steel": Color("#344a56"),
    "glass": Color("#27465e"),
    "gold": Color("#e7ba58"),
    "mark": Color("#eff0e8")
}
static var _cache: Dictionary = {}
static var _geometry_cache: Dictionary = {}

static func _mat(key: String, color: Color) -> StandardMaterial3D:
    var tint: Color = color.darkened(0.17) if key == "faction" else PALETTE[key]
    var identity: String = key + tint.to_html()
    if _cache.has(identity):
        return _cache[identity]
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.metallic = 0.08 if key == "concrete" else 0.26
    m.roughness = 0.84 if key == "concrete" else 0.65
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    _cache[identity] = m
    return m

static func _box(st: SurfaceTool, center: Vector3, dimensions: Vector3) -> void:
    var a: Vector3 = center - dimensions * 0.5
    var b: Vector3 = center + dimensions * 0.5
    var p000 := Vector3(a.x,a.y,a.z)
    var p001 := Vector3(a.x,a.y,b.z)
    var p010 := Vector3(a.x,b.y,a.z)
    var p011 := Vector3(a.x,b.y,b.z)
    var p100 := Vector3(b.x,a.y,a.z)
    var p101 := Vector3(b.x,a.y,b.z)
    var p110 := Vector3(b.x,b.y,a.z)
    var p111 := Vector3(b.x,b.y,b.z)
    var faces: Array = [
        [Vector3.FORWARD,[p100,p000,p010,p110]],
        [Vector3.BACK,[p001,p101,p111,p011]],
        [Vector3.LEFT,[p000,p001,p011,p010]],
        [Vector3.RIGHT,[p101,p100,p110,p111]],
        [Vector3.UP,[p010,p011,p111,p110]],
        [Vector3.DOWN,[p100,p101,p001,p000]]
    ]
    var uvs: Array[Vector2] = [Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]
    for face in faces:
        var normal: Vector3 = face[0]
        var points: Array = face[1]
        for index in [0,1,2,0,2,3]:
            st.set_normal(normal)
            st.set_uv(uvs[index])
            st.add_vertex(points[index])

static func _dish(st: SurfaceTool, center: Vector3, radius: float) -> void:
    for i in range(12):
        var a: float = TAU*float(i)/12.0
        var b: float = TAU*float(i+1)/12.0
        for vertex in [center,
                center+Vector3(cos(a)*radius,sin(a)*radius,0),
                center+Vector3(cos(b)*radius,sin(b)*radius,0)]:
            st.set_normal(Vector3.FORWARD)
            st.set_uv(Vector2(vertex.x,vertex.y))
            st.add_vertex(vertex)

static func _build(level: int, faction: int, condition: String) -> MeshInstance3D:
    var cache_key: String = "%d/%d/%s" % [level,faction,condition]
    if _geometry_cache.has(cache_key):
        var clone := MeshInstance3D.new()
        clone.name = "MallaConsolidadaMapaV5"
        clone.mesh = _geometry_cache[cache_key]
        return clone
    var color: Color = Style.faction_color(faction)
    var surfaces: Dictionary = {}
    for key in MATERIALS:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        surfaces[key] = st
    var concrete: SurfaceTool = surfaces["concrete"]
    var steel: SurfaceTool = surfaces["steel"]
    var glass: SurfaceTool = surfaces["glass"]
    var paint: SurfaceTool = surfaces["faction"]
    var gold: SurfaceTool = surfaces["gold"]
    var mark: SurfaceTool = surfaces["mark"]
    var y: float = 2.87+0.91*float(level-1)
    _box(steel,Vector3(0,-0.1,0),Vector3(13.6,0.20,12.8))
    if condition == "destruido":
        _box(concrete,Vector3(0,0.19,0),Vector3(7.1,0.3,6.6))
        _box(steel,Vector3(-0.85,0.66,-2.5),Vector3(3.2,0.92,1.5))
        for i in range(6):
            _box(concrete,Vector3(-2.65+float(i)*1.02,0.38,
                    -0.89+float(i%2)*1.29),
                Vector3(0.84,0.43+float(i%3)*0.22,0.91))
        _box(paint,Vector3(1.5,0.3,-3.6),Vector3(1.05,0.12,0.64))
        _box(glass,Vector3(-1.1,0.24,-3.2),Vector3(0.50,0.05,0.39))
        _box(gold,Vector3(0.4,0.25,-3.8),Vector3(0.4,0.04,0.09))
        _box(mark,Vector3(-0.4,0.22,-4.3),Vector3(0.67,0.025,0.09))
    else:
        _box(concrete,Vector3(0,y*0.5,0.25),Vector3(5.82,y,5.12))
        _box(steel,Vector3(0,y+0.09,0.25),Vector3(6.15,0.24,5.43))
        for s in [-1,1]:
            var sx: float = float(s)
            _box(concrete,Vector3(sx*4.06,1.10,0.35),Vector3(2.30,2.20,4.16))
            _box(steel,Vector3(sx*4.06,2.42,0.35),Vector3(2.6,0.25,4.48))
            _box(paint,Vector3(sx*4.06,2.54,-1.89),Vector3(2.13,0.17,0.17))
            for w in range(3):
                _box(glass,Vector3(sx*4.06-0.75+float(w)*0.77,
                        1.36,-1.89),Vector3(0.44,0.53,0.09))
        _box(steel,Vector3(0,y+0.69,-2.36),Vector3(3.27,1.60,1.67))
        _box(steel,Vector3(0,y+1.56,-2.38),Vector3(3.73,0.30,1.99))
        _box(paint,Vector3(0,y+0.66,-3.27),Vector3(1.86,1.17,0.17))
        _box(gold,Vector3(0,y+1.61,-3.33),Vector3(2.89,0.13,0.09))
        _box(glass,Vector3(0,y+0.70,-3.37),Vector3(1.20,0.32,0.10))
        _box(steel,Vector3(0,1.27,-3.18),Vector3(3.08,2.50,1.33))
        _box(glass,Vector3(0,1.18,-3.87),Vector3(1.38,1.44,0.10))
        var comm_h: float = 2.48+0.56*float(level-1)
        _box(steel,Vector3(-4.50,2.54+comm_h*0.5,1.38),
            Vector3(0.62,comm_h,0.62))
        _box(glass,Vector3(-4.50,2.54+comm_h+0.13,1.38),
            Vector3(1.51,0.50,1.52))
        _box(paint,Vector3(-4.50,2.54+comm_h+0.47,1.38),
            Vector3(1.80,0.18,1.80))
        _box(paint,Vector3(-5.13,4.92+0.41*float(level-1),0.43),
            Vector3(1.05,0.70,0.07))
        _box(steel,Vector3(-1.86,y+1.04,0.76),Vector3(0.36,2.08,0.36))
        _dish(mark,Vector3(-1.86,y+2.35,0.66),0.96)
        _box(steel,Vector3(4.85,0.16,-4.08),Vector3(3.25,0.26,3.22))
        for x in [4.56,5.14]:
            _box(mark,Vector3(x,0.31,-4.08),Vector3(0.12,0.03,1.06))
        _box(mark,Vector3(4.85,0.31,-4.08),Vector3(0.69,0.03,0.12))
        _box(gold,Vector3(4.85,0.32,-5.56),Vector3(2.68,0.04,0.07))
        if level == 3:
            _box(concrete,Vector3(1.67,y+1.72,1.58),
                Vector3(1.40,1.20,1.33))
        if condition == "danado":
            _box(steel,Vector3(-2.30,1.61,-2.55),Vector3(0.79,0.74,0.14))
        if condition == "capturado":
            _box(paint,Vector3(0,0.12,-5.76),Vector3(2.31,0.04,0.17))
    var mesh := ArrayMesh.new()
    for kind in MATERIALS:
        var st: SurfaceTool = surfaces[kind]
        st.set_material(_mat(kind,color))
        st.commit(mesh)
    var instance := MeshInstance3D.new()
    instance.name = "MallaConsolidadaMapaV5"
    instance.mesh = mesh
    _geometry_cache[cache_key] = mesh
    return instance

static func install(model: Node3D, level: int, faction: int,
        condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_map_lod_v5",false):
        return
    assert(model.get_meta("tarvoka_hq_visual_v4",false))
    var earlier: Array[Node] = model.get_children()
    var full := Node3D.new()
    full.name = "ArquitecturaCompletaV4"
    model.add_child(full)
    for child in earlier:
        if child is Node3D:
            model.remove_child(child)
            full.add_child(child)
    var distant := Node3D.new()
    distant.name = "ArquitecturaDeMapaV5"
    distant.add_child(_build(level,faction,condition))
    distant.visible = false
    model.add_child(distant)
    model.set_meta("tarvoka_hq_map_lod_v5",true)
    model.set_meta("tarvoka_hq_map_distant",false)

static func set_distant(model: Node3D, distant: bool) -> bool:
    if model == null or not model.get_meta("tarvoka_hq_map_lod_v5",false):
        return false
    var near: Node3D = model.get_node_or_null("ArquitecturaCompletaV4") as Node3D
    var far: Node3D = model.get_node_or_null("ArquitecturaDeMapaV5") as Node3D
    if near == null or far == null:
        return false
    near.visible = not distant
    far.visible = distant
    model.set_meta("tarvoka_hq_map_distant",distant)
    return true

# Standalone distance-mode node. Unlike install(), this never constructs V4:
# mobile maps can show dozens of HQs without retaining hidden hero meshes.
static func build_map_only(level: int, faction: int,
        condition: String = "operativo") -> Node3D:
    if level < 1 or level > 3 or faction < 0 or faction >= 8:
        return null
    if not condition in ["operativo","capturado","danado","destruido"]:
        return null
    var node := Node3D.new()
    node.name = "CuartelGeneralMapaV6"
    node.set_meta("tarvoka_building_kind","headquarters")
    node.set_meta("visual_level",level)
    node.set_meta("visual_faction",faction)
    node.set_meta("visual_condition",condition)
    node.set_meta("visual_only",true)
    node.set_meta("tarvoka_hq_map_only_v6",true)
    node.add_child(_build(level,faction,condition))
    return node

static func shared_mesh(level: int, faction: int,
        condition: String = "operativo") -> ArrayMesh:
    if level < 1 or level > 3 or faction < 0 or faction >= 8:
        return null
    if not condition in ["operativo","capturado","danado","destruido"]:
        return null
    var cache_key: String = "%d/%d/%s" % [level,faction,condition]
    if not _geometry_cache.has(cache_key):
        var disposable: MeshInstance3D = _build(level,faction,condition)
        assert(disposable.mesh is ArrayMesh)
        disposable.free()
    return _geometry_cache[cache_key] as ArrayMesh

static func cached_variant_count() -> int:
    return _geometry_cache.size()
