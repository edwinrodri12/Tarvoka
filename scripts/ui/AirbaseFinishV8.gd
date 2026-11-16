extends RefCounted
class_name TarvokaAirbaseFinishV8

# Visual-only, additive final-lighting pass for the real V1/V2/V6/V7 meshes.
# No point lights, particles, CPU animations, health or economy mutations.
# Single glass material per source tint; two batched 3D lighting meshes;
# one batched weathering mesh; never move any original hangar gate parts.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const STAGE_NAME := "CristalesIluminacionYSuciedadBaseAereaV8"
const MAX_LIGHT_BATCHES := 2
const MAX_DIRT_BATCHES := 1
const GLASS_NAME := "BrilloCristalesBiseladosV8"
const LIGHT_NAME := "LuminariasHangarAgrupadasV8"
const POOL_NAME := "IluminacionSueloHangarV8"
const DIRT_NAME := "SuciedadLocalizadaUnLoteV8"

static var _glass_cache: Dictionary = {}

static func _is_glass(name: String) -> bool:
    var lower: String = name.to_lower()
    return lower.contains("cristal") or lower.contains("vidrio") or lower.contains("ventana")

static func _glass_material(source: StandardMaterial3D, stage: int) -> StandardMaterial3D:
    var key: String = "%d/%d" % [source.get_instance_id(),stage]
    if _glass_cache.has(key):
        return _glass_cache[key] as StandardMaterial3D
    var material: StandardMaterial3D = source.duplicate(true) as StandardMaterial3D
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    var glaze: Color = material.albedo_color
    glaze.a = 0.77 if stage<=1 else 0.63
    material.albedo_color = glaze
    material.roughness = 0.16 if stage<=1 else 0.31
    material.metallic = 0.045
    material.metallic_specular = 0.88
    material.clearcoat_enabled = true
    material.clearcoat_roughness = 0.12 if stage<=1 else 0.26
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    _glass_cache[key] = material
    return material

static func _treat_glass(node: Node, stage: int, stats: Dictionary) -> void:
    if node is MeshInstance3D:
        var mesh: MeshInstance3D = node as MeshInstance3D
        if _is_glass(str(mesh.name)) and mesh.mesh!=null:
            var source: Material = mesh.material_override
            if source==null and mesh.mesh.get_surface_count()>0:
                source=mesh.get_active_material(0)
            if source is StandardMaterial3D:
                mesh.material_override=_glass_material(source as StandardMaterial3D,stage)
                # WeatherCoating3D already excludes glass from snow.
                mesh.set_meta("tarvoka_airbase_v8_glass",true)
                stats["glass_panels"]+=1
    for child in node.get_children():
        _treat_glass(child,stage,stats)

static func _quad(tool: SurfaceTool, center: Vector3,
        axis_a: Vector3, axis_b: Vector3,
        middle: Color, outer: Color) -> void:
    var a: Vector3=center-axis_a-axis_b
    var b: Vector3=center+axis_a-axis_b
    var c: Vector3=center+axis_a+axis_b
    var d: Vector3=center-axis_a+axis_b
    var normal: Vector3 = axis_a.cross(axis_b).normalized()
    for tri in [[a,outer],[b,outer],[center,middle],
            [b,outer],[c,outer],[center,middle],
            [c,outer],[d,outer],[center,middle],
            [d,outer],[a,outer],[center,middle]]:
        tool.set_normal(normal)
        tool.set_color(tri[1])
        tool.add_vertex(tri[0])

static func _batch(parent: Node3D, label: String, tool: SurfaceTool,
        glow: bool=false) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name=label
    mesh.mesh=tool.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo=true
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    mat.roughness=0.74
    mat.metallic=0.0
    if glow:
        mat.emission_enabled=true
        mat.emission=Color(0.70,0.88,1.0)
        mat.emission_energy_multiplier=1.45
    mesh.material_override=mat
    mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mesh.set_meta("tarvoka_weather_protect",true)
    mesh.set_meta("tarvoka_airbase_v8_batch",true)
    parent.add_child(mesh)
    return mesh

static func _reflection_sweep(tower: Node3D, level: int,
        stage: int, stats: Dictionary) -> void:
    if stage>=3:
        return
    var height: float = 3.33+float(level-1)*0.62
    var layer:=Node3D.new()
    layer.name=GLASS_NAME
    layer.set_meta("tarvoka_weather_protect",true)
    tower.add_child(layer)
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Small front glazing glints, following the existing control cab.
    for n in range(2):
        var x: float = -0.54+float(n)*0.84
        _quad(tool,Vector3(x,height+0.76,-1.025),
            Vector3(0.065,0,0),Vector3(0,0.27,0),
            Color(0.66,0.89,1.0,0.34),
            Color(0.66,0.89,1.0,0.015))
    _batch(layer,"ReflejosCristaleriaLoteV8",tool)
    stats["glass_glint_batches"]=1

static func _lighting(hangar: Node3D, stage: int,
        stats: Dictionary) -> void:
    # Lighting may stay on at stage 1; damaged wiring disables it at 3/4.
    if stage>=3:
        return
    var inside: Node3D = hangar.find_child(
        "InteriorOperativoHangarV2",true,false) as Node3D
    if inside==null:
        return
    var layer:=Node3D.new()
    layer.name="IluminacionArquitectonicaInteriorV8"
    layer.set_meta("tarvoka_weather_protect",true)
    inside.add_child(layer)
    var luminous:=SurfaceTool.new()
    luminous.begin(Mesh.PRIMITIVE_TRIANGLES)
    var pools:=SurfaceTool.new()
    pools.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int = 2 if stage==2 else 4
    for i in range(count):
        var x: float = -2.55+float(i)*1.70
        var tone: Color = Color(0.72,0.92,1.0,0.96) if i%2==0 else Color(0.91,0.95,1.0,0.90)
        # Under-roof strip, no OmniLight3D nor additional shadow passes.
        _quad(luminous,Vector3(x,2.685,-1.37),
            Vector3(0.31,0,0),Vector3(0,0,0.049),
            tone,Color(tone.r,tone.g,tone.b,0.37))
        # Fake bounced illumination attached to actual service-bay flooring.
        _quad(pools,Vector3(x,0.189,-1.30),
            Vector3(0.62,0,0),Vector3(0,0,0.89),
            Color(0.45,0.68,0.81,0.20 if stage<=1 else 0.09),
            Color(0.38,0.62,0.80,0.0))
    _batch(layer,LIGHT_NAME,luminous,true)
    _batch(layer,POOL_NAME,pools)
    stats["interior_light_batches"]=2
    stats["interior_lights"]=count

static func _dirt(parent: Node3D, stage: int,
        stats: Dictionary) -> void:
    var batch:=SurfaceTool.new()
    batch.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Service soot and perimeter grime, not an opaque repaint.
    # These planes sit above existing roof/pavement surfaces and preserve
    # the V3 runway centre markings and the four telescopic gate leaves.
    for i in range(6):
        var x: float = -5.72+float(i)*0.51
        var z: float = 2.90+float(i%2)*0.34
        _quad(batch,Vector3(x,0.155,z),
            Vector3(0.21,0,0),Vector3(0,0,0.21),
            Color(0.15,0.18,0.17,0.25+float(stage)*0.05),
            Color(0.23,0.25,0.24,0.0))
    if stage<4:
        for i in range(5):
            var x: float = -4.88+float(i)*1.34
            var z: float = 1.12+float(i%2)*0.78
            var y: float = 2.80+0.73*sin(PI*(x+3.65+1.95)/7.30)
            # Weather only on the existing roof: avoid the missing V1
            # sections at medium and critical damage stages.
            if x<-5.6 or x>1.6 or (stage>=2 and i in [2,3]):
                continue
            _quad(batch,Vector3(x,y+0.022,z),
                Vector3(0.13,0,0),Vector3(0,0,0.31),
                Color(0.14,0.16,0.15,0.21+float(stage)*0.04),
                Color(0.19,0.21,0.19,0.0))
    var layer:=Node3D.new()
    layer.name="DepositosYSuciedadV8"
    layer.set_meta("tarvoka_weather_protect",true)
    parent.add_child(layer)
    _batch(layer,DIRT_NAME,batch)
    stats["dirt_batches"]=1

static func apply(model: Node3D, level: int, faction: int,
        stage: int) -> bool:
    if model==null or not Airbase.valid_spec(level,faction,stage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false):
        return false
    if model.get_meta("tarvoka_airbase_v8",false) or model.has_node(STAGE_NAME):
        return false
    var layer:=Node3D.new()
    layer.name=STAGE_NAME
    layer.set_meta("tarvoka_visual_only",true)
    layer.set_meta("tarvoka_weather_protect",true)
    model.add_child(layer)
    var stats: Dictionary={
        "glass_panels":0,"glass_glint_batches":0,"interior_light_batches":0,
        "interior_lights":0,"dirt_batches":0,"faction":faction,
        "level":level,"stage":stage
    }
    if stage<4:
        _treat_glass(model,stage,stats)
        var tower: Node3D=model.find_child("TorreControlAereoV1",true,false) as Node3D
        var hangar: Node3D=model.find_child("HangarPrincipalV1",true,false) as Node3D
        if tower==null or hangar==null:
            model.remove_child(layer)
            layer.free()
            return false
        _reflection_sweep(tower,level,stage,stats)
        _lighting(hangar,stage,stats)
    _dirt(layer,stage,stats)
    model.set_meta("tarvoka_airbase_v8",true)
    model.set_meta("tarvoka_airbase_v8_stats",stats)
    return true
