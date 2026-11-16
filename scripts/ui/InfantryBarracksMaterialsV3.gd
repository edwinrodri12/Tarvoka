extends RefCounted
class_name TarvokaInfantryBarracksMaterialsV3

# Native Godot 4.3 PBR material + proportion pass for Infantry Barracks.
# Generated greyscale tile textures in engine (not external concept art).
# Independent V3 overlay; leaves V1/V2 source, economy, units, and saves intact.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV3MaterialesYProporciones"
const SURFACES=["concrete","roof","steel","paving","glass","rubble","field"]
const STEEL=Color("#6b8184")
const DARK=Color("#3c5159")
const DUST=Color("#7d8277")
const EMBER=Color("#936450")
static var _textures: Dictionary={}
static var _materials: Dictionary={}

static func _hash(x: int,y: int,salt: int) -> float:
    var n: int=abs((x*137+y*311+salt*911) ^ ((x*17+y*71+salt*103)*37))
    return float(n%997)/996.0

static func _texture(kind: String) -> Texture2D:
    if _textures.has(kind):
        return _textures[kind] as Texture2D
    var img:=Image.create(48,48,false,Image.FORMAT_RGBA8)
    var seed: int=SURFACES.find(kind)+1
    for y in range(48):
        for x in range(48):
            var grain: float=_hash(x,y,seed)
            var spread: float=0.0
            match kind:
                "concrete":
                    spread=0.84+grain*0.16
                    if grain>0.963:
                        spread*=0.76
                "roof":
                    var seam: bool=x%12==0 or x%12==1
                    spread=(0.81 if seam else 0.91)+grain*0.07
                "steel":
                    spread=0.90+grain*0.07
                    if y%11==0:
                        spread*=0.88
                "paving":
                    spread=0.85+grain*0.13
                    if grain<0.025:
                        spread*=0.78
                "glass":
                    spread=0.97+grain*0.025
                "rubble":
                    spread=0.66+grain*0.29
                "field":
                    spread=0.79+grain*0.16
                _:
                    spread=0.94
            img.set_pixel(x,y,Color(spread,spread,spread,1.0))
    var texture:=ImageTexture.create_from_image(img)
    _textures[kind]=texture
    return texture

static func _is_faction_piece(part: MeshInstance3D,accent: Color) -> bool:
    var name: String=str(part.name).to_lower()
    if name.contains("faccion") or name.contains("bandera") or             name.contains("identidad") or name.contains("simboloabstracto"):
        return true
    var mat: StandardMaterial3D=part.material_override as StandardMaterial3D
    if mat==null:
        return false
    return mat.albedo_color.is_equal_approx(accent)

static func _surface(part: MeshInstance3D,damage: int) -> String:
    var n: String=str(part.name).to_lower()
    if n.contains("cristal") or n.contains("ventana") or             n.contains("pantalla"):
        return "glass"
    if damage>=3 and (n.contains("fractur") or n.contains("ruina") or             n.contains("escombro") or n.contains("dintel") or             n.contains("fragmento")):
        return "rubble"
    if n.contains("paneltecho") or n.contains("cubierta") or             n.contains("coronacion") or n.contains("remate") or             n.contains("canalon") or n.contains("techo"):
        return "roof"
    if n.contains("suelo") and n.contains("pista") or             n.contains("obstaculo") or n.contains("barricada") or             n.contains("practica") or n.contains("trepa"):
        return "field"
    if n.contains("pavimento") or n.contains("patio") or             n.contains("lineaformacion") or n.contains("cimentacion"):
        return "paving"
    if n.contains("muros") or n.contains("pared") or             n.contains("fachada") or n.contains("piso_") or             n.contains("escalon") or n.contains("soporte"):
        return "concrete"
    if n.contains("torre") or n.contains("escalera") or             n.contains("poste") or n.contains("barandal") or             n.contains("pelda") or n.contains("marco") or             n.contains("puerta") or n.contains("jamba") or             n.contains("viga") or n.contains("perfil") or             n.contains("arriostre") or n.contains("forjado"):
        return "steel"
    return "concrete"

static func _finish_material(old: StandardMaterial3D,kind: String) -> StandardMaterial3D:
    var key: String="%s/%s/%.2f/%.2f" % [
        kind,old.albedo_color.to_html(true),old.metallic,old.roughness]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=old.albedo_color
    mat.albedo_texture=_texture(kind)
    mat.roughness=0.92 if kind in ["concrete","paving","rubble","field"] else         0.48 if kind=="roof" else 0.33 if kind=="steel" else 0.18
    mat.metallic=0.62 if kind=="roof" else         0.44 if kind=="steel" else 0.12 if kind=="glass" else 0.02
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _materials[key]=mat
    return mat

static func _paint_recursive(parent: Node,damage: int,
        accent: Color,counters: Dictionary) -> void:
    if parent is MeshInstance3D:
        var part: MeshInstance3D=parent as MeshInstance3D
        if _is_faction_piece(part,accent):
            counters["faction_preserved"]=int(counters.get("faction_preserved",0))+1
        else:
            var old: StandardMaterial3D=part.material_override as StandardMaterial3D
            if old!=null:
                var surface: String=_surface(part,damage)
                part.material_override=_finish_material(old,surface)
                counters[surface]=int(counters.get(surface,0))+1
    for child in parent.get_children():
        _paint_recursive(child,damage,accent,counters)

static func _roof_and_ground(stage: Node3D,level: int,
        damage: int) -> void:
    if damage>=3:
        return
    for module in V2._modules(level):
        var tag: String=str(module["tag"])
        var cx: float=float(module["x"])
        var cz: float=float(module["z"])
        var w: float=float(module["w"])
        var d: float=float(module["d"])
        var h: float=float(module["h"])
        var roof:=Base._group(stage,"CubiertaEstriadaV3_"+tag)
        for panel in range(4):
            if damage==1 and panel==1:
                continue
            if damage==2 and panel in [0,2]:
                continue
            var start: float=cx-w*0.5+w*float(panel)*0.25
            for line in range(2):
                var x: float=start+w*(0.25/3.0)*float(line+1)
                Base._box(roof,"CostillaPanel_%d_%d" % [panel,line],
                    Vector3(x,h+0.271,cz),
                    Vector3(0.046,0.045,d+0.19),STEEL,0.53)
        if damage<=1:
            # Back-edge drip trim, no artificial flat plate over missing roof.
            Base._box(roof,"GoteronPosterior",
                Vector3(cx,h+0.21,cz+d*0.5+0.12),
                Vector3(w,0.08,0.11),DARK,0.36)
        # Real concrete-ground contact line. Slim instead of an overlapping
        # oversized foundation that would interfere with N3 side wings.
        Base._box(stage,"ZocaloPosterior_"+tag,
            Vector3(cx,0.17,cz+d*0.5+0.146),
            Vector3(w+0.08,0.30,0.09),DUST,0.08)
        if damage==0 and level>=2:
            var units: int=1 if level==2 else 2
            for index in range(units):
                var offset_x: float=cx-w*0.25+float(index)*(w*0.50)
                # Back wall ventilation fins at eye-readable height.
                var back:=Base._group(stage,
                    "VentilacionPosteriorV3_"+tag+"_%d" % index)
                Base._box(back,"RejillaVentilacion",
                    Vector3(offset_x,h-0.81,cz+d*0.5+0.168),
                    Vector3(0.86,0.43,0.09),DARK,0.38)
                for slat in range(3):
                    Base._box(back,"LamaVentilacion_%d" % slat,
                        Vector3(offset_x,h-0.96+float(slat)*0.13,
                            cz+d*0.5+0.221),
                        Vector3(0.73,0.043,0.028),STEEL,0.47)

static func _stains(stage: Node3D,level: int,damage: int) -> void:
    if damage==0 or damage==4:
        return
    # Modest localized damage: NO new intact facade/walls/roofs.
    for i in range(2 if damage==1 else 4 if damage==2 else 5):
        var xpos: float=-3.9+float(i)*1.46
        var zpos: float=-0.72+float(i%2)*0.76
        Base._box(stage,"HuellaDesgasteV3_%02d" % i,
            Vector3(xpos,0.076,zpos),
            Vector3(0.28+float(i%2)*0.13,0.013,0.38),
            EMBER if damage>=2 else DUST,0.04)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V2.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level or             int(model.get_meta("visual_faction",-1))!=faction or             int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    _roof_and_ground(stage,level,damage)
    _stains(stage,level,damage)
    var counts: Dictionary={}
    _paint_recursive(model,damage,Style.faction_color(faction),counts)
    stage.set_meta("surface_counts",counts.duplicate(true))
    stage.set_meta("preserves_infantry_three_masses",true)
    stage.set_meta("material_finish_version",3)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    stage.set_meta("visual_only",true)
    return true

static func texture_count() -> int:
    return _textures.size()
