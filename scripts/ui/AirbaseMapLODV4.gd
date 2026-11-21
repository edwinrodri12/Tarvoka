extends RefCounted
class_name TarvokaAirbaseMapLODV4

# True one-MeshInstance tactical proxy; *not* an invisible full V3 model.
# 4 surface materials, shared per variant, eight official faction palettes.
const Style = preload("res://scripts/ui/VisualStyle.gd")
# Tactical V4 geometry is independent from the large Studio V16 art tree.
# Real campaign maps must not load hundreds of preview-only art meshes.
const HANGAR_CENTER_X:float=-1.95
const PROFILE_DISTANT:int=0
const PROFILE_CLOSE:int=1
const NEUTRAL_ACCENT:Color=Color("#8e9da5")
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
    # Glass is intentionally not in COLORS: that palette contains only
    # opaque concrete, steel and marking finishes. Resolve separately to
    # avoid reading a missing Dictionary key on real close-range models.
    if name=="faction":
        material.albedo_color=(NEUTRAL_ACCENT if faction==-1
            else Style.faction_color(faction))
    elif name=="glass":
        material.albedo_color=Color(0.29,0.56,0.66,0.68)
    else:
        material.albedo_color=COLORS[name]
    material.metallic = 0.18 if name=="steel" else 0.05
    material.roughness = 0.78
    if name=="glass":
        # V16-inspired window material: thin colored panes, no opaque glass blocks.
        material.albedo_color=Color(0.29,0.56,0.66,0.68)
        material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        material.roughness=0.24
        material.metallic=0.02
        material.cull_mode=BaseMaterial3D.CULL_DISABLED
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


# Detail is baked into the SAME procedural surface groups. Close profile
# borrows the finished V16's actual design language (hangar frame, doors,
# trussed roof, corner glazing, helipad and operational marking) without
# loading the huge multi-mesh Art Studio into every mobile battle.
static func _detail_close(tools:Dictionary,level:int,stage:int,
        height:float,tower_height:float) -> void:
    var conc:SurfaceTool=tools["concrete"]
    var metal:SurfaceTool=tools["steel"]
    var trim:SurfaceTool=tools["faction"]
    var mark:SurfaceTool=tools["mark"]
    if stage==4:
        # Wrecked hangar: no ghost doors, intact windows or rebuilt roof.
        for i in range(13):
            var x:float=-4.98+float((i*7)%13)*0.67
            var z:float=-3.13+float((i*5)%11)*0.52
            _box(metal,Vector3(x,0.28+float(i%3)*0.09,z),
                Vector3(0.56+float(i%3)*0.16,0.13,0.36))
        for i in range(4):
            _box(conc,Vector3(3.2+float(i%2)*0.45,
                0.22+float(i)*0.13,-2.3+float(i%3)*0.28),
                Vector3(0.41,0.22,0.39))
        return
    # V16 hangar geometry adapted to one compact existing map tile.
    # Frames sit just OUTSIDE the V4 gate to remain visible at tactical zoom.
    for i in range(5):
        var z:float=-3.17+float(i)*1.22
        for side in [-1,1]:
            var sx:float=-1.95+float(side)*3.72
            _box(metal,Vector3(sx,1.46,z),
                Vector3(0.12,2.68,0.12))
            if stage<=1:
                _box(trim,Vector3(sx+float(side)*0.075,1.93,z),
                    Vector3(0.034,0.52,0.21))
    if stage<=2:
        for bay in range(4):
            var x:float=-4.40+float(bay)*1.63
            _box(metal,Vector3(x,1.32,-4.115),
                Vector3(0.072,2.28,0.085))
        # Door stays on the original hangar face and never obstructs taxiway.
        for panel in range(4):
            var cx:float=-4.38+float(panel)*1.62
            _box(conc,Vector3(cx,1.16,-4.095),
                Vector3(1.49,1.94,0.052))
            for line in range(3):
                _box(metal,Vector3(cx,0.50+float(line)*0.55,-4.131),
                    Vector3(1.45,0.044,0.028))
        for i in range(8):
            var x:float=-5.35+float(i)*0.97
            _box(metal,Vector3(x,height-0.11,-0.71),
                Vector3(0.05,0.11,6.40))
        # Thin roof supports are omitted at destroyed stages.
        if stage<2:
            for i in range(6):
                _box(conc,Vector3(-4.80+float(i)*1.10,
                    height+0.05,1.46),
                    Vector3(0.35,0.07,0.80))
    else:
        # Stage D3: a visible broken gate and exposed ribs, not a fresh door.
        for i in range(3):
            _box(metal,Vector3(-4.8+float(i)*2.25,
                1.14,-4.14),Vector3(0.13,2.10,0.12))
        for i in range(5):
            _box(metal,Vector3(-4.65+float(i)*1.25,
                height+0.11,1.12),
                Vector3(0.08,0.13,4.62))
    # Controller cabin: angled corners read like V16 glass, rather
    # than an opaque cube on a blank tower. No glass after D3.
    _box(metal,Vector3(4.17,tower_height+0.86,-2.17),
        Vector3(2.35,0.10,2.10))
    if stage<3:
        var glass:SurfaceTool=tools["glass"]
        _box(glass,Vector3(4.17,tower_height+0.46,-3.223),
            Vector3(1.85,0.60,0.033))
        _box(glass,Vector3(4.17,tower_height+0.46,-1.118),
            Vector3(1.85,0.60,0.033))
        for side in [-1,1]:
            _box(glass,Vector3(4.17+float(side)*1.16,
                tower_height+0.46,-2.17),
                Vector3(0.033,0.60,1.81))
            for i in range(2):
                _box(metal,Vector3(4.17+float(side)*0.41,
                    tower_height+0.46,
                    -3.253+float(i)*2.16),
                    Vector3(0.058,0.68,0.052))
        # Radar, navigation beacon, operations sign: faction readable.
        _box(metal,Vector3(4.17,tower_height+1.42,-2.17),
            Vector3(0.12,0.95,0.12))
        _box(trim,Vector3(4.17,tower_height+1.88,-2.17),
            Vector3(0.55,0.17,0.55))
    # Finishing paint is unmistakable for any of the 8 approved factions.
    _box(trim,Vector3(-1.95,height-0.09,-4.19),
        Vector3(5.95,0.17,0.06))
    for side in [-1,1]:
        _box(trim,Vector3(-1.95+float(side)*3.83,1.12,-2.47),
            Vector3(0.052,0.35,1.57))
    # Airfield lane, blue/white navigation bars and H pad remain exposed.
    for i in range(5):
        _box(mark,Vector3(HANGAR_CENTER_X,0.135,-5.90+float(i)*0.42),
            Vector3(0.11,0.018,0.23))
    for side in [-1,1]:
        _box(mark,Vector3(HANGAR_CENTER_X+float(side)*3.0,
            0.145,-5.05),Vector3(0.09,0.02,2.3))
    for side in [-1,1]:
        _box(trim,Vector3(3.63+float(side)*1.60,0.201,2.74),
            Vector3(0.085,0.018,3.28))
    _box(mark,Vector3(3.63,0.21,2.74),
        Vector3(0.66,0.015,0.14))

static func build_proxy(level: int, faction: int, stage: int,
        profile:int=PROFILE_DISTANT) -> MeshInstance3D:
    if level not in [1,2,3] or faction<-1 or faction>=Style.FACTIONS.size() or stage<0 or stage>4 or profile not in [PROFILE_DISTANT,PROFILE_CLOSE]:
        return null
    var key: String = "%d/%d/%d/%d" % [level,faction,stage,profile]
    if not _mesh_cache.has(key):
        var tools: Dictionary = {}
        var group_names:Array=["concrete","steel","faction","mark"]
        if profile==PROFILE_CLOSE and stage<3:
            group_names.append("glass")
        for name in group_names:
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
        _box(metal,Vector3(HANGAR_CENTER_X,0.09,-5.0),
            Vector3(6.40,0.06,2.60))
        _box(mark,Vector3(HANGAR_CENTER_X,0.127,-5.05),
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
        if profile==PROFILE_CLOSE:
            _detail_close(tools,level,stage,
                3.25+0.15*float(level-1),
                4.00+float(level-1)*0.58)
        var mesh := ArrayMesh.new()
        for name in group_names:
            (tools[name] as SurfaceTool).commit(mesh)
        _mesh_cache[key]=mesh
    var proxy := MeshInstance3D.new()
    proxy.name = "BaseAereaMapaV4_UnaMalla"
    proxy.mesh = _mesh_cache[key] as Mesh
    proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    proxy.set_meta("tarvoka_airbase_lod_proxy_v4",true)
    proxy.set_meta("airbase_profile",profile)
    proxy.set_meta("airbase_v16_detail_language",profile==PROFILE_CLOSE)
    proxy.set_meta("visual_faction",faction)
    proxy.set_meta("visual_level",level)
    proxy.set_meta("visual_damage_stage",stage)
    return proxy

static func cache_entries() -> int:
    return _mesh_cache.size()

static func surface_budget(proxy: MeshInstance3D) -> int:
    return proxy.mesh.get_surface_count() if proxy!=null and proxy.mesh!=null else 0
