extends RefCounted
class_name TarvokaHeadquartersClimateV17

# The same PUBLIC weather vocabulary as scripts/core/Weather.gd in the
# playable Android game. This is a VISUAL showroom only: no mobility,
# combat, income, fog, pathfinding or save-game modifications.
const WEATHERS := ["clear","rain","snow"]
const WEATHER_NAMES := ["Despejado","Lluvia","Nieve"]
const TERRAINS := ["asphalt","grass","desert","rock"]
const TERRAIN_NAMES := ["Asfalto","Pradera","Desierto","Roca"]
const GROUND_COLORS := [
    Color("#424e56"),Color("#4b6d48"),
    Color("#ae8961"),Color("#777979")]
const MATERIAL_BUDGET := 14
const LIGHT_COLOR := Color("#b9d9f5")
const FROST := Color("#e3edf4")
const RAIN := Color("#82bbec")

static func _material(color: Color, roughness: float = 0.83,
        transparent: bool = false, unshaded: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = 0.05
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    if transparent:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
    if unshaded:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _streaks(snow: bool) -> ArrayMesh:
    # 1 actual 3D GPU mesh, no individual particle nodes or CPU emitters.
    # Spatially distributed in front and behind the building; fixed random
    # seed guarantees reproducible UI captures and perf profiling.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rng := RandomNumberGenerator.new()
    rng.seed = 770120 if snow else 770121
    var count: int = 56 if snow else 78
    for i in range(count):
        var x: float = rng.randf_range(-9.1,9.1)
        var y: float = rng.randf_range(0.55,10.1)
        var z: float = rng.randf_range(-8.5,8.0)
        if snow:
            var size: float = rng.randf_range(0.06,0.14)
            var offset := Vector3(x,y,z)
            _quad(st,offset+Vector3(-size,0,0),
                offset+Vector3(0,size,0),
                offset+Vector3(size,0,0),
                offset+Vector3(0,-size,0))
        else:
            var width: float = rng.randf_range(0.013,0.035)
            var length: float = rng.randf_range(0.44,0.72)
            var offset := Vector3(x,y,z)
            _quad(st,offset,
                offset+Vector3(width,0,0),
                offset+Vector3(-0.21,length*-1.0,0)+Vector3(width,0,0),
                offset+Vector3(-0.21,length*-1.0,0))
    st.generate_normals()
    var mesh := st.commit()
    return mesh

static func _make_weather_mesh(snow: bool) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = "CoposNieveUnLoteV17" if snow else "LluviaUnLoteV17"
    instance.mesh = _streaks(snow)
    instance.material_override = _material(
        Color(0.94,0.98,1.0,0.89) if snow else Color(0.60,0.79,0.96,0.70),
        0.85,true,true)
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instance.visible = false
    instance.set_meta("tarvoka_precipitation_batch",true)
    return instance

static func _make_scatter() -> MultiMeshInstance3D:
    var rubble := MultiMeshInstance3D.new()
    rubble.name = "MicrorrelieveTerreno44InstanciasV17"
    var box := BoxMesh.new()
    box.size = Vector3(0.24,0.045,0.31)
    var material := _material(Color("#8a927e"))
    box.material = material
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = box
    multimesh.instance_count = 44
    var rng := RandomNumberGenerator.new()
    rng.seed = 1771
    for i in range(44):
        var x: float = rng.randf_range(-12.4,12.4)
        var z: float = rng.randf_range(-12.4,12.4)
        if absf(x) < 7.0 and absf(z) < 5.5:
            x += 7.4 if x >= 0.0 else -7.4
            x = clampf(x,-13.8,13.8)
        var transform := Transform3D(
            Basis(Vector3.UP,rng.randf_range(0.0,TAU)),
            Vector3(x,-0.194,z))
        multimesh.set_instance_transform(i,transform)
    rubble.multimesh = multimesh
    rubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return rubble

static func _make_puddle(i: int) -> MeshInstance3D:
    var puddle := MeshInstance3D.new()
    puddle.name = "CharcoFisicoV17_%d" % i
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.75+float(i%3)*0.35
    cylinder.bottom_radius = cylinder.top_radius
    cylinder.height = 0.012
    cylinder.radial_segments = 18
    cylinder.material = _material(Color(0.35,0.53,0.64,0.60),0.11,true)
    puddle.mesh = cylinder
    var positions := [
        Vector3(-8.1,-0.177,2.8),Vector3(7.9,-0.177,3.5),
        Vector3(-5.9,-0.177,-5.2),Vector3(3.8,-0.177,7.6)]
    puddle.position = positions[i]
    puddle.scale = Vector3(1.15,1.0,0.64)
    puddle.visible = false
    puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return puddle

static func _make_snow_cap(i: int) -> MeshInstance3D:
    var cap := MeshInstance3D.new()
    cap.name = "NieveAcumuladaCubiertaV17_%d" % i
    var shape := BoxMesh.new()
    var wing: bool = i != 2
    shape.size = Vector3(2.15,0.065,0.29) if wing else Vector3(2.25,0.085,0.37)
    shape.material = _material(FROST,0.96)
    cap.mesh = shape
    cap.visible = false
    cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return cap

static func build() -> Node3D:
    var stage := Node3D.new()
    stage.name = "EntornoClimaticoComercialHQV17"
    stage.set_meta("tarvoka_hq_visual_only",true)
    stage.set_meta("tarvoka_hq_climate_stage_v17",true)
    var floor := MeshInstance3D.new()
    floor.name = "SueloLocalConMaterialesV17"
    var plane := PlaneMesh.new()
    plane.size = Vector2(29.0,29.0)
    floor.mesh = plane
    floor.material_override = _material(GROUND_COLORS[0])
    floor.position.y = -0.23
    stage.add_child(floor)
    stage.add_child(_make_scatter())
    stage.add_child(_make_weather_mesh(false))
    stage.add_child(_make_weather_mesh(true))
    for i in range(4):
        stage.add_child(_make_puddle(i))
    for i in range(3):
        stage.add_child(_make_snow_cap(i))
    apply(stage,"clear","asphalt",2,"operativo",false)
    return stage

static func valid(weather: String,terrain: String) -> bool:
    return weather in WEATHERS and terrain in TERRAINS

static func apply(stage: Node3D,weather: String,terrain: String,
        level: int = 2,condition: String = "operativo",
        is_sprite: bool = false) -> bool:
    if stage == null or not valid(weather,terrain) or level < 1 or level > 3:
        return false
    var base: Color = GROUND_COLORS[TERRAINS.find(terrain)]
    # The climate palette follows the *same tint weights* as game Weather.gd.
    if weather=="rain":
        base = base.lerp(Color("#27495E"),0.28)
    elif weather=="snow":
        base = base.lerp(Color("#D9E4EA"),0.52)
    var floor: MeshInstance3D = stage.get_node(
        "SueloLocalConMaterialesV17") as MeshInstance3D
    var ground_mat: StandardMaterial3D = floor.material_override as StandardMaterial3D
    ground_mat.albedo_color = base
    ground_mat.roughness = 0.22 if weather=="rain" else 0.96 if weather=="snow" else 0.83
    var scatter: MultiMeshInstance3D = stage.get_node(
        "MicrorrelieveTerreno44InstanciasV17") as MultiMeshInstance3D
    var stone: BoxMesh = scatter.multimesh.mesh as BoxMesh
    var tint: StandardMaterial3D = stone.material as StandardMaterial3D
    tint.albedo_color = base.lightened(0.17) if weather=="snow" else base.darkened(0.20)
    var rain: MeshInstance3D = stage.get_node("LluviaUnLoteV17") as MeshInstance3D
    var snow: MeshInstance3D = stage.get_node("CoposNieveUnLoteV17") as MeshInstance3D
    rain.visible = weather=="rain"
    snow.visible = weather=="snow"
    var pools: bool = weather=="rain"
    for i in range(4):
        var puddle: MeshInstance3D = stage.get_node("CharcoFisicoV17_%d" % i) as MeshInstance3D
        puddle.visible = pools
    var deposits: bool = weather=="snow" and condition!="destruido" and not is_sprite
    for i in range(3):
        var cap: MeshInstance3D = stage.get_node(
            "NieveAcumuladaCubiertaV17_%d" % i) as MeshInstance3D
        cap.visible = deposits
        if i==2:
            cap.position = Vector3(0.0,2.87+0.91*float(level-1)+2.83,-1.9)
        else:
            cap.position = Vector3(-4.03 if i==0 else 4.03,3.65,-1.84)
    stage.set_meta("tarvoka_weather_visual",weather)
    stage.set_meta("tarvoka_terrain_visual",terrain)
    stage.set_meta("tarvoka_precipitation_draws",1 if weather!="clear" else 0)
    return true

static func active_mesh_count(stage: Node3D) -> int:
    if stage==null:
        return 0
    var total: int = 0
    for child in stage.get_children():
        if child is MeshInstance3D or child is MultiMeshInstance3D:
            if (child as VisualInstance3D).visible:
                total+=1
    return total

static func animate(stage: Node3D,elapsed: float) -> void:
    if stage == null or not stage.visible:
        return
    var weather: String = str(stage.get_meta("tarvoka_weather_visual","clear"))
    if weather=="clear":
        return
    var rain: MeshInstance3D = stage.get_node("LluviaUnLoteV17") as MeshInstance3D
    var snow: MeshInstance3D = stage.get_node("CoposNieveUnLoteV17") as MeshInstance3D
    # Tiny deterministic movement, no dynamic mesh regeneration. In-camera
    # sky and precipitation stay put when the user rotates the HQ.
    rain.position.y = -fposmod(elapsed*3.2,0.9) if weather=="rain" else 0.0
    snow.position.y = -fposmod(elapsed*0.8,0.6) if weather=="snow" else 0.0
    snow.position.x = sin(elapsed*0.5)*0.10 if weather=="snow" else 0.0
