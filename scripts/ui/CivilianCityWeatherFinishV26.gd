extends RefCounted
class_name TarvokaCivilianCityWeatherFinishV26

# TARVOKA V26: native material variation and selectively eroded 3D edges.
# Reuses the approved V1-V25 city geometry; no new gameplay buildings.
# One shared 96x96 NoiseTexture2D per architectural family (small on mobile).
# ART WIP: no collisions, capture, economy, combat, or faction recoloring.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V25=preload("res://scripts/ui/CivilianCitySurfaceContinuityV25.gd")
const STAGE_NAME="CiudadCivilV26PiedraTejaMetalMeteorizados"

const TERRACOTTA=Color("#b47b5d")
const WOOD=Color("#826a55")
const EARTH=Color("#84715d")
const BRICK=Color("#9b7866")
const MORTAR=Color("#a69b8d")
const LIMESTONE=Color("#c1b5a2")
const STEEL=Color("#697d83")
const DARK_STEEL=Color("#4c5f66")
const RUBBLE=Color("#796b62")
const SOOT=Color("#515050")
const RUST=Color("#7e6553")

static var _noise_textures: Dictionary={}
static var _weather_materials: Dictionary={}

static func _surface(level: int) -> String:
    if level==1:
        return "ceramic"
    if level==2:
        return "stone"
    return "steel"

static func _level_color(level: int,damage: int) -> Color:
    if level==1:
        return TERRACOTTA.lerp(EARTH,0.22 if damage>=2 else 0.0)
    if level==2:
        return LIMESTONE.lerp(MORTAR,0.34 if damage>=2 else 0.06)
    return STEEL.lerp(DARK_STEEL,0.20 if damage>=2 else 0.0)

static func _texture(level: int) -> NoiseTexture2D:
    if _noise_textures.has(level):
        return _noise_textures[level] as NoiseTexture2D
    var noise:=FastNoiseLite.new()
    noise.seed=620+level*71
    noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency=0.085 if level==1 else 0.072 if level==2 else 0.048
    noise.fractal_type=FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves=3 if level<3 else 2
    noise.fractal_gain=0.43
    var gradient:=Gradient.new()
    # Subtle, material-specific luminance variation: no black blotches
    # or bright artificial noise. The same texture is reused by all lots.
    var low: float=0.77 if level==1 else 0.81 if level==2 else 0.87
    gradient.set_color(0,Color(low,low,low,1.0))
    gradient.set_color(1,Color(1.0,1.0,1.0,1.0))
    var texture:=NoiseTexture2D.new()
    texture.width=96
    texture.height=96
    texture.noise=noise
    texture.color_ramp=gradient
    _noise_textures[level]=texture
    return texture

static func _material(level: int,damage: int,
        shade: int,color: Color,surface: String) -> StandardMaterial3D:
    # Stable five-tone palette. Does NOT mutate V9's cached materials,
    # preserving everything that the military/unit/other city art uses.
    var key: String="%d/%d/%d/%s/%s" % [
        level,damage,shade,surface,color.to_html(true)]
    if _weather_materials.has(key):
        return _weather_materials[key] as StandardMaterial3D
    var base:=V9._finish(color,surface)
    var result: StandardMaterial3D=base.duplicate() as StandardMaterial3D
    var aging: float=0.04+float(damage)*0.046
    var shift: float=(float(shade)-2.0)*0.032
    # More erosion on D2-D4, while preserving underlying ceramic/stone/
    # metallic appearance. Faction-color markings are never selected.
    var tint: Color=color.lerp(RUBBLE,aging)
    result.albedo_color=tint.lightened(maxf(0.0,shift)
        ).darkened(maxf(0.0,-shift))
    result.albedo_texture=_texture(level)
    result.uv1_scale=Vector3(2.45 if level==1 else
        2.9 if level==2 else 3.4,
        2.45 if level==1 else 2.9 if level==2 else 3.4,1.0)
    result.roughness=clampf(base.roughness+
        (0.08 if damage>=2 else 0.03 if damage==1 else 0.0),
        0.0,1.0)
    if level==3 and damage>=2:
        result.metallic=clampf(base.metallic-0.13,0.0,1.0)
    _weather_materials[key]=result
    return result

static func _weather_existing(model: Node3D,level: int,
        damage: int) -> int:
    # Operate on controlled architectural families only: avoid windows,
    # street, plaza, identity-color stripes, signs and other gameplay art.
    var names: Array[String]=[
        "V23_VillaRematePerfil_","V23_CiudadPerfilEscalonado_",
        "V23_MetroPerfilCorona_","V23_BordeTejadoPartido_",
        "V23_ForjadoArrancado_","V23_CrestaRuinaBaja_",
        "V24_CierreCornisa_","V24_ZapataApoyoRoto_",
        "V24_FracturaApoyada_","V24_FiloForjadoInterrumpido_",
        "V24_ZapataCortada_","V24_VigaEntreCascotes_",
        "V25_JuntaCeramica_","V25_JuntaMortero_",
        "V25_RematePiedra_","V25_SoldaduraMetal_",
        "V25_SeccionTejaPartida_","V25_CantoForjadoVisible_",
        "V25_AnclajeCimientoDestruido_"
    ]
    var touched: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh:=node as MeshInstance3D
        var n: String=str(mesh.name)
        var selected: bool=false
        for prefix in names:
            if n.begins_with(prefix):
                selected=true
                break
        if not selected:
            continue
        if bool(mesh.get_meta("city_v22_superseded",false)):
            continue
        var before:=mesh.material_override as StandardMaterial3D
        if before==null:
            continue
        var finish: String="ceramic" if n.contains("Teja") or n.contains("Ceramica") else (
            "steel" if n.contains("Metro") or n.contains("Metal")
            or n.contains("Soldadura") else _surface(level))
        var palette_index: int=posmod(n.hash(),5)
        mesh.material_override=_material(level,damage,palette_index,
            before.albedo_color,finish)
        mesh.set_meta("city_v26_weathered",true)
        touched+=1
    return touched

static func _part(parent: Node3D,n: String,where: Vector3,
        size: Vector3,color: Color,level: int) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,n,where,size,color)
    mesh.material_override=_material(level,2,posmod(n.hash(),5),
        color,_surface(level))
    return mesh

static func _low_patch(parent: Node3D,n: String,where: Vector3,
        width: float,depth: float,level: int,damage: int,
        slant: float) -> void:
    var tint: Color=_level_color(level,damage)
    var piece:=V14._sloped_slab(parent,n,where,
        width,depth,0.018,slant,tint)
    piece.rotation_degrees.y=float(posmod(n.hash(),17))-8.0
    piece.material_override=_material(level,damage,
        posmod(n.hash(),5),tint,_surface(level))

static func _local_wear(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    var group:=V1._group(stage,"DesgasteLocalV26_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage==0:
        # Intact city: geometry stays exactly the same. The shared
        # material grain is sufficient; do not damage pristine roofs.
        return
    if damage==1:
        # Few physically raised worn spots, OUTSIDE V1 windows/doors.
        # Small, isolated edge chips never become giant facade decals.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.405
            var zz: float=z-d*0.5-0.165
            _low_patch(group,
                "V26_DesgasteRemate_%s_%d" % [tag,side],
                Vector3(xx,h+0.215,zz),0.21,0.18,level,damage,
                0.075 if side==-1 else 0.038)
        return
    if damage==2:
        # Exposed substrate on V23/V24's broken roof rim, without
        # bridging the existing open center or the missing SE corner.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.365
            var zz: float=z-d*0.385
            _low_patch(group,
                "V26_TejaExpuestaRota_%s_%d" % [tag,side],
                Vector3(xx,h+0.12,zz),
                0.24,0.15,level,damage,0.09)
            if side==-1:
                _part(group,"V26_SustratoCantoRoto_"+tag,
                    Vector3(xx,h-0.025,zz-0.10),
                    Vector3(0.22,0.065,0.11),
                    EARTH if level==1 else MORTAR if level==2 else
                    DARK_STEEL,level)
        return
    if damage==3:
        # Edge spall near the V11 interior floor. Every part stays
        # below 1m, leaving jagged D3 wall geometry unobstructed.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.29
            _low_patch(group,
                "V26_CantoPisoDescascarado_%s_%d" % [tag,side],
                Vector3(xx,0.795,z+d*0.225),
                0.22,0.14,level,damage,
                0.05 if side==-1 else 0.085)
        return
    # Total destruction: weathered fallen fragments only, ground level.
    # No replacement walls, full roof boxes or fake intact floors.
    for side in [-1,1]:
        var xx: float=x+float(side)*w*0.34
        var zz: float=z-d*0.225
        _low_patch(group,
            "V26_DesgasteRestosBajos_%s_%d" % [tag,side],
            Vector3(xx,0.12,zz),0.25,0.20,level,damage,0.065)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V25.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var weathered: int=_weather_existing(model,level,damage)
    var stage:=V1._group(model,STAGE_NAME)
    var north: int=1 if level==1 else 2 if level==2 else 4
    var south: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for is_south in [false,true]:
            var tag: String=("Sur_" if is_south else "Norte_")+str(side)
            _local_wear(stage,tag,x,
                3.62 if is_south else -3.80,
                2.77 if is_south else 2.74,
                2.80 if is_south else 2.84,
                south if is_south else north,level,damage)
    _local_wear(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        2 if level==1 else 3 if level==2 else 4,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",26)
    stage.set_meta("weathered_existing_pieces",weathered)
    stage.set_meta("material_texture_resolution",96)
    stage.set_meta("design_focus","muted-ceramic-mortar-oxidized-metal-and-low-weathered-fractures")
    model.set_meta("city_v26_weathered_pieces",weathered)
    model.set_meta("city_art_work_in_progress",26)
    model.set_meta("city_model_approved_final",false)
    return true
