extends RefCounted
class_name TarvokaAirbaseMaterialsV7

# Original procedural material detail: native 3D PBR maps, no flat replacement
# image, no borrowed textures, no game-stat changes. V6 details are optional.
# WeatherCoating3D is applied AFTER this pass, so rain can duplicate the PBR
# coat while snow covers the real geometry without destroying its materials.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const STAGE_NAME := "MaterialesYDesgasteFisicoBaseAereaV7"
const FAMILIES := ["concrete","steel","roof","asphalt","glass"]
const TEX_SIZE := 64
const MAX_MARK_BATCHES := 2
static var _textures: Dictionary = {}
static var _materials: Dictionary = {}

static func _hash(x: int, y: int, seed: int) -> float:
    var n: int = posmod(x*197+y*373+x*y*17+seed*863,1009)
    return float(n)/1008.0

static func _sample(x: int, y: int, seed: int) -> float:
    # Blend large stains with tiny repeatable grain; no runtime random calls.
    var broad: float = 0.5 + 0.5*sin(float(x)*0.17+float(seed))*cos(
        float(y)*0.19+float(seed)*0.43)
    var fleck: float = _hash(x,y,seed)
    return clampf(broad*0.62+fleck*0.38,0.0,1.0)

static func _texture_set(family: String) -> Dictionary:
    if _textures.has(family):
        return _textures[family]
    var seed: int = FAMILIES.find(family)+1
    var albedo: Image = Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGB8)
    var roughness: Image = Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGB8)
    var normal: Image = Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGB8)
    for y in range(TEX_SIZE):
        for x in range(TEX_SIZE):
            var grain: float = _sample(x,y,seed)
            var cracks: float = _hash(x/6,y/7,seed+9)
            var streak: float = 0.5+0.5*sin(float(x)*0.21+float(seed))
            var tint: float = 0.83+0.15*grain
            match family:
                "concrete":
                    tint -= 0.10 if cracks>0.84 else 0.0
                "steel":
                    tint = 0.82+0.17*grain-0.09*streak
                "roof":
                    tint = 0.80+0.17*grain-0.06*streak
                "asphalt":
                    tint = 0.75+0.23*grain
                "glass":
                    tint = 0.96+0.04*grain
            tint = clampf(tint,0.60,1.0)
            albedo.set_pixel(x,y,Color(tint,tint,tint))
            var surface_roughness: float = clampf(
                0.69+0.25*(1.0-grain),0.3,0.98)
            if family=="glass":
                surface_roughness = 0.24+0.07*grain
            roughness.set_pixel(x,y,Color(
                surface_roughness,surface_roughness,surface_roughness))
            var sx: float = (_sample(x+1,y,seed)-_sample(x-1,y,seed))*0.22
            var sy: float = (_sample(x,y+1,seed)-_sample(x,y-1,seed))*0.22
            var n: Vector3 = Vector3(-sx,-sy,1.0).normalized()
            normal.set_pixel(x,y,Color(
                n.x*0.5+0.5,n.y*0.5+0.5,n.z*0.5+0.5))
    var set := {
        "albedo":ImageTexture.create_from_image(albedo),
        "rough":ImageTexture.create_from_image(roughness),
        "normal":ImageTexture.create_from_image(normal)
    }
    _textures[family]=set
    return set

static func _excluded(mesh: MeshInstance3D) -> bool:
    if mesh.mesh==null or mesh.has_meta("tarvoka_weather_protect") or mesh.has_meta(
            "tarvoka_faction_panel"):
        return true
    var name: String = str(mesh.name).to_lower()
    for word in ["faccion","emblema","escudo","insignia","pantalla",
            "logo","baliza","luminaria","helipuerto_h","raya","flecha",
            "advertencia","indicador","fotovoltaico","marca_bahia",
            "marca_seguridad","franja_identidad","safety","estatus",
            "fuego","humo","ruido","luces","luz_","farol","señal"]:
        if name.contains(word):
            return true
    if mesh.material_override is ShaderMaterial:
        return true
    return false

static func _family(mesh: MeshInstance3D) -> String:
    var name: String = str(mesh.name).to_lower()
    if name.contains("cristal") or name.contains("vidrio") or name.contains(
            "ventana"):
        return "glass"
    for word in ["rodaje","asfalto","basecompacta","pavimento",
            "discointerior","limite","suelo"]:
        if name.contains(word):
            return "asphalt"
    for word in ["techo","cubierta","canalon","costilla","cornisa",
            "cercha","panel_solar","aleronproteccion"]:
        if name.contains(word):
            return "roof"
    for word in ["hormigon","concreto","muro","pared","pilar",
            "pilastra","losa","fuste","plataforma","hormigón",
            "nicho","base_tecnica","base_tecnic","bloque",
            "ladrillo","cimentacion"]:
        if name.contains(word):
            return "concrete"
    return "steel"

static func _aged(material: StandardMaterial3D, family: String,
        stage: int) -> StandardMaterial3D:
    var key: String = "%d/%s/%d" % [material.get_instance_id(),family,stage]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    # Never alter shared V1/V2/V6 resources: rain/snow can safely restore.
    var copy: StandardMaterial3D = material.duplicate(true) as StandardMaterial3D
    var textures: Dictionary = _texture_set(family)
    if copy.albedo_texture == null:
        copy.albedo_texture = textures["albedo"]
    copy.roughness_texture = textures["rough"]
    if family!="glass":
        copy.normal_enabled = true
        copy.normal_texture = textures["normal"]
        copy.normal_scale = 0.27 if family=="concrete" else 0.18
    copy.uv1_scale = Vector3(2.1,2.1,1.0) if family!="roof" else Vector3(
        1.2,1.2,1.0)
    var dry_rough: float = 0.87
    match family:
        "concrete":
            dry_rough=0.89
            copy.metallic=0.02
        "steel":
            dry_rough=0.55
            copy.metallic=maxf(copy.metallic,0.28)
        "roof":
            dry_rough=0.70
            copy.metallic=maxf(copy.metallic,0.19)
        "asphalt":
            dry_rough=0.93
            copy.metallic=0.02
        "glass":
            dry_rough=0.25
            copy.metallic=0.04
    copy.roughness=dry_rough
    var wear: float = [0.0,0.035,0.10,0.17,0.25][stage]
    if family=="glass":
        wear*=0.35
    copy.albedo_color = copy.albedo_color.lerp(
        Color(0.25,0.22,0.19,copy.albedo_color.a),wear)
    if stage>=2 and family in ["roof","steel"]:
        copy.roughness=minf(1.0,copy.roughness+0.07*float(stage-1))
    copy.resource_local_to_scene=false
    _materials[key]=copy
    return copy

static func _coat(model: Node, stage: int, stats: Dictionary) -> void:
    if model is MeshInstance3D:
        var mesh: MeshInstance3D = model as MeshInstance3D
        if not _excluded(mesh):
            var original: Material = mesh.material_override
            if original == null and mesh.mesh.get_surface_count()>0:
                original=mesh.get_active_material(0)
            if original is StandardMaterial3D:
                var standard: StandardMaterial3D = original as StandardMaterial3D
                # Atlas/emblem source never gets overwritten even if renamed.
                if standard.albedo_texture==null:
                    var family: String = _family(mesh)
                    mesh.material_override=_aged(standard,family,stage)
                    mesh.set_meta("tarvoka_airbase_v7_family",family)
                    stats["coated"]+=1
                    stats[family]+=1
                else:
                    stats["protected"]+=1
            else:
                stats["protected"]+=1
        else:
            stats["protected"]+=1
    for child in model.get_children():
        if not child.has_meta("tarvoka_airbase_v7_marks"):
            _coat(child,stage,stats)

static func _add_quad(tool: SurfaceTool, center: Vector3,
        across: Vector3, along: Vector3, color: Color) -> void:
    # Geometry over real concrete, NOT a screen-aligned pasted sprite.
    var a: Vector3=center-across-along
    var b: Vector3=center+across-along
    var c: Vector3=center+across+along
    var d: Vector3=center-across+along
    var normal: Vector3 = across.cross(along).normalized()
    for point in [a,b,c,a,c,d]:
        tool.set_normal(normal)
        tool.set_color(color)
        tool.add_vertex(point)

static func _finish_batch(name: String,tool: SurfaceTool,
        parent: Node3D, color: Color) -> MeshInstance3D:
    var surface := MeshInstance3D.new()
    surface.name=name
    surface.mesh=tool.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo=true
    mat.albedo_color=color
    mat.roughness=0.97
    mat.metallic=0.03
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    surface.material_override=mat
    surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    surface.set_meta("tarvoka_weather_protect",true)
    surface.set_meta("tarvoka_airbase_v7_marks",true)
    parent.add_child(surface)
    return surface

static func _ground_wear(parent: Node3D, stage: int) -> void:
    var marks := SurfaceTool.new()
    marks.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Tire scuffs are off the centerline; never obscure V3 dashed markings.
    var cx: float = Airbase.TAXIWAY_CENTER_X
    for side in [-1,1]:
        for i in range(3):
            var z: float = -5.69+float(i)*0.56
            _add_quad(marks,
                Vector3(cx+float(side)*1.16,0.149,z),
                Vector3(0.075,0,0),Vector3(0,0,0.17),
                Color(0.19,0.21,0.22,0.40+0.045*float(i)))
    # Subtle irregular oil/ground stains near service machinery.
    for i in range(7):
        var x: float = 3.55+float(i%3)*0.37
        var z: float = 0.77+float(i/3)*0.32
        _add_quad(marks,Vector3(x,0.146,z),
            Vector3(0.16+float(i%2)*0.07,0,0),
            Vector3(0,0,0.095+float(i%3)*0.025),
            Color(0.19,0.20,0.16,0.28+float(stage)*0.035))
    _finish_batch("DesgastePistaYCombustibleV7",marks,parent,Color.WHITE)

static func _damage_wear(parent: Node3D,stage: int) -> int:
    if stage==0:
        return 0
    var scars := SurfaceTool.new()
    scars.begin(Mesh.PRIMITIVE_TRIANGLES)
    # One small batch of wall oxidation / soot; the roof holes remain open.
    for i in range(2+stage*2):
        var x: float = -5.16+float(i%4)*0.54
        var height: float = 0.82+float(i%3)*0.44
        var z: float = -4.177
        _add_quad(scars,Vector3(x,height,z),
            Vector3(0.10+float(i%2)*0.035,0,0),
            Vector3(0,0.15+float(i%3)*0.05,0),
            Color(0.24,0.22,0.20,0.32+float(stage)*0.09))
    if stage>=2:
        for i in range(4):
            var x: float = -3.12+float(i)*0.69
            _add_quad(scars,Vector3(x,0.20,2.92),
                Vector3(0.18,0,0),
                Vector3(0,0,0.08),
                Color(0.19,0.18,0.16,0.48))
    _finish_batch("OxidoYHollinDeImpactosV7",scars,parent,Color.WHITE)
    return 1

static func apply(model: Node3D, level: int, faction: int,
        stage: int) -> bool:
    if model==null or not Airbase.valid_spec(level,faction,stage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false):
        return false
    if model.get_meta("tarvoka_airbase_v7",false):
        return false
    var layer:=Node3D.new()
    layer.name=STAGE_NAME
    layer.set_meta("tarvoka_airbase_v7_marks",true)
    layer.set_meta("tarvoka_visual_only",true)
    model.add_child(layer)
    var stats: Dictionary = {
        "coated":0,"protected":0,"concrete":0,"steel":0,
        "roof":0,"asphalt":0,"glass":0,"wear_batches":0,
        "stage":stage,"faction":faction,"level":level
    }
    _coat(model,stage,stats)
    _ground_wear(layer,stage)
    stats["wear_batches"]=1+_damage_wear(layer,stage)
    model.set_meta("tarvoka_airbase_v7",true)
    model.set_meta("tarvoka_airbase_v7_stats",stats)
    return int(stats["coated"])>0
