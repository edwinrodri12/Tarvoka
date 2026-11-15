extends RefCounted
class_name TarvokaAirbaseMapLODV4

# True one-MeshInstance tactical proxy; *not* an invisible full V3 model.
# 4 surface materials, shared per variant, eight official faction palettes.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const COLORS := {
    "concrete":Color("#9daeb0"),
    "steel":Color("#364a55"),
    "mark":Color("#e9e8df")
}
static var _mesh_cache: Dictionary = {}
static var _material_cache: Dictionary = {}

static func _mat(name: String,faction: int) -> StandardMaterial3D:
    var key: String = "%s/%d" % [name,faction]
    if _material_cache.has(key):
        return _material_cache[key] as StandardMaterial3D
    var material := StandardMaterial3D.new()
    material.albedo_color = (
        Style.faction_color(faction) if name=="faction" else COLORS[name])
    material.metallic = 0.18 if name=="steel" else 0.05
    material.roughness = 0.78
    _material_cache[key]=material
    return material

static func _box(tool: SurfaceTool,center: Vector3,size: Vector3) -> void:
    var low: Vector3 = center-size*0.5
    var high: Vector3 = center+size*0.5
    var a:=Vector3(low.x,low.y,low.z)
    var b:=Vector3(high.x,low.y,low.z)
    var c:=Vector3(low.x,high.y,low.z)
    var d:=Vector3(high.x,high.y,low.z)
    var e:=Vector3(low.x,low.y,high.z)
    var f:=Vector3(high.x,low.y,high.z)
    var g:=Vector3(low.x,high.y,high.z)
    var h:=Vector3(high.x,high.y,high.z)
    var faces: Array = [
        [Vector3.FORWARD,[b,a,c,d]],
        [Vector3.BACK,[e,f,h,g]],
        [Vector3.LEFT,[a,e,g,c]],
        [Vector3.RIGHT,[f,b,d,h]],
        [Vector3.UP,[c,g,h,d]],
        [Vector3.DOWN,[a,b,f,e]]
    ]
    for face in faces:
        var points: Array = face[1]
        for n in [0,1,2,0,2,3]:
            tool.set_normal(face[0])
            tool.set_uv(Vector2(float(n%2),float(n%3)/2.0))
            tool.add_vertex(points[n])

static func build_proxy(level: int, faction: int, stage: int) -> MeshInstance3D:
    if not Airbase.valid_spec(level,faction,stage):
        return null
    var key: String = "%d/%d/%d" % [level,faction,stage]
    if not _mesh_cache.has(key):
        var tools: Dictionary = {}
        for name in ["concrete","steel","faction","mark"]:
            var tool := SurfaceTool.new()
            tool.begin(Mesh.PRIMITIVE_TRIANGLES)
            tool.set_material(_mat(name,faction))
            tools[name]=tool
        var conc: SurfaceTool = tools["concrete"]
        var metal: SurfaceTool = tools["steel"]
        var trim: SurfaceTool = tools["faction"]
        var mark: SurfaceTool = tools["mark"]
        # The road still shares the V3 hangar centerline.
        _box(metal,Vector3.ZERO+Vector3(0,-0.14,0),Vector3(13.4,0.24,12.8))
        _box(conc,Vector3(-1.95,0.025,-0.76),Vector3(7.55,0.08,7.25))
        _box(metal,Vector3(Airbase.HANGAR_CENTER_X,0.09,-5.0),
            Vector3(6.40,0.06,2.60))
        _box(mark,Vector3(Airbase.HANGAR_CENTER_X,0.127,-5.05),
            Vector3(0.10,0.016,1.71))
        if stage==4:
            _box(conc,Vector3(-1.95,0.47,-0.65),Vector3(6.51,0.75,4.19))
            _box(metal,Vector3(-3.8,0.83,-0.92),Vector3(2.1,0.18,3.9))
            _box(metal,Vector3(3.42,0.34,-2.15),Vector3(2.89,0.62,1.53))
            _box(trim,Vector3(-3.61,0.73,-4.06),Vector3(2.18,0.12,0.15))
        else:
            var height: float = 3.25+0.15*float(level-1)
            _box(conc,Vector3(-1.95,1.35,-0.71),
                Vector3(7.30,2.70,6.37))
            _box(metal,Vector3(-1.95,height-0.37,-0.71),
                Vector3(7.46,0.42,6.60))
            _box(metal,Vector3(-1.95,1.34,-4.02),
                Vector3(6.65,2.35,0.12))
            _box(trim,Vector3(-1.95,height-0.20,-4.17),
                Vector3(6.40,0.21,0.11))
            var tower_height: float = 4.00+float(level-1)*0.58
            _box(conc,Vector3(4.17,tower_height*0.5,-2.17),
                Vector3(1.36,tower_height,1.39))
            if stage<3:
                _box(metal,Vector3(4.17,tower_height+0.41,-2.17),
                    Vector3(2.26,0.76,2.06))
                _box(trim,Vector3(4.17,tower_height+0.85,-2.17),
                    Vector3(2.40,0.16,2.16))
            else:
                _box(metal,Vector3(4.40,tower_height+0.12,-2.17),
                    Vector3(1.66,0.23,1.58))
            # Scalable, legible helipad symbol at aerial map zoom.
            _box(metal,Vector3(3.63,0.10,2.74),Vector3(3.4,0.16,3.4))
            for side in [-1,1]:
                _box(mark,Vector3(3.63+float(side)*0.27,0.193,2.74),
                    Vector3(0.12,0.014,1.05))
            _box(mark,Vector3(3.63,0.193,2.74),
                Vector3(0.60,0.014,0.12))
            if stage>=2:
                _box(metal,Vector3(-2.8,2.67,-0.89),
                    Vector3(2.8,0.27,1.75))
        var mesh := ArrayMesh.new()
        for name in ["concrete","steel","faction","mark"]:
            (tools[name] as SurfaceTool).commit(mesh)
        _mesh_cache[key]=mesh
    var proxy := MeshInstance3D.new()
    proxy.name = "BaseAereaMapaV4_UnaMalla"
    proxy.mesh = _mesh_cache[key] as Mesh
    proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    proxy.set_meta("tarvoka_airbase_lod_proxy_v4",true)
    proxy.set_meta("visual_faction",faction)
    proxy.set_meta("visual_level",level)
    proxy.set_meta("visual_damage_stage",stage)
    return proxy

static func cache_entries() -> int:
    return _mesh_cache.size()

static func surface_budget(proxy: MeshInstance3D) -> int:
    return proxy.mesh.get_surface_count() if proxy!=null and proxy.mesh!=null else 0
