extends RefCounted
class_name TarvokaNavalMarineFinishV4

# Additive, original, real Godot 4.3 marine surface finishing for V3.
# Only the 3D studio model changes: never economics, tactics or map collision.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const SURFACE=preload("res://assets/shaders/naval_marine_weathering_v4.gdshader")
const STAGE_NAME: String="DesgasteMaritimoYTransicionCosteraV4"
const CONCRETE=Color("#a6b4b7")
const LIMESTONE=Color("#c5c5b1")
const DARK=Color("#394a51")
const RUST=Color("#916553")
const ALGAE=Color("#526a62")
const FOAM=Color("#98b7b2")
const ROCKS=[
    Color("#6e7776"),Color("#84918a"),Color("#677d80"),
    Color("#727b73"),Color("#a2a59a")]
static var _weather_material_cache: Dictionary={}

static func _box(parent: Node3D,label: String,at: Vector3,
        size: Vector3,color: Color,metal: float=0.11,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,label,at,size,color,metal,rotation)

static func _weather_material(color: Color,patina: Color,
        metal: float,rough: float,damage: int) -> ShaderMaterial:
    var key: String="%s/%s/%0.2f/%0.2f/%d" % [
        color.to_html(),patina.to_html(),metal,rough,damage]
    if _weather_material_cache.has(key):
        return _weather_material_cache[key] as ShaderMaterial
    var material:=ShaderMaterial.new()
    material.shader=SURFACE
    material.set_shader_parameter("base_color",color)
    material.set_shader_parameter("weather_color",patina)
    material.set_shader_parameter("wet_color",Color("#253d47"))
    material.set_shader_parameter("surface_metallic",metal)
    material.set_shader_parameter("surface_roughness",rough)
    material.set_shader_parameter("marine_wear",minf(0.74,
        0.25+float(damage)*0.13))
    material.set_shader_parameter("salt_level",minf(0.84,
        0.42+float(damage)*0.07))
    material.set_shader_parameter("tide_height",0.21)
    _weather_material_cache[key]=material
    return material

static func _coat(model: Node3D,name: String,color: Color,
        patina: Color,metal: float,rough: float,
        damage: int) -> bool:
    var mesh:=model.find_child(name,true,false) as MeshInstance3D
    if mesh==null:
        return false
    mesh.material_override=_weather_material(
        color,patina,metal,rough,damage)
    mesh.set_meta("tarvoka_naval_v4_weathered",true)
    return true

static func _material_finishing(model: Node3D,damage: int) -> int:
    # Preserve official 8-faction stripes and shields: neither is in the
    # selection. Missing roof panels and demolished quay remain missing.
    var stone: Array[String]=[
        "MuelleEsteDeCarga","CoronacionMuelleEste","ZocaloMuelleEste",
        "ParedPosteriorHangar","FusteHormigonControl",
        "BancadaReparacionNaval","LosetaRampaVarada"]
    var metal_parts: Array[String]=[
        "ColumnaGrua","PlataformaGrua","TableroAntideslizantePasarela",
        "CabrestanteDeVarada","ArmarioHerramientasAstillero"]
    var touched: int=0
    for name in stone:
        if _coat(model,name,Color("#93a6a6"),ALGAE,
                0.08,0.81,damage):
            touched+=1
    for name in metal_parts:
        if _coat(model,name,Color("#71868e"),RUST,
                0.62,0.52,damage):
            touched+=1
    for side in [-1,1]:
        if _coat(model,"CoronacionEspigon_%s" % side,
                CONCRETE,ALGAE,0.06,0.78,damage):
            touched+=1
        if _coat(model,"RielBotadura_%s" % side,
                Color("#8c9fa4"),RUST,0.74,0.48,damage):
            touched+=1
        if _coat(model,"CarrilVagonTransferencia_%s" % side,
                Color("#7e9094"),RUST,0.70,0.52,damage):
            touched+=1
    return touched

static func _seawall_grime(stage: Node3D,damage: int) -> void:
    var grime:=Base._group(stage,"MarcasMareaOxidoYSalV4")
    # Below the quay coping, real narrow deposits cling to seawalls.
    # Weathering is not a flat undifferentiated rectangle on the harbor.
    for i in range(11):
        var z: float=-4.35+float(i)*0.84
        var position_y: float=0.20+float(i%3)*0.05
        _box(grime,"LimoMareaMuelleEste_%02d" % i,
            Vector3(1.095,position_y,z),
            Vector3(0.026,0.16+float(i%4)*0.047,0.15),
            ALGAE if i%2==0 else Color("#6a7773"))
        if i%3==0:
            _box(grime,"EscorrentiaOxidoMuelle_%02d" % i,
                Vector3(1.070,0.38,z+0.16),
                Vector3(0.029,0.21,0.064),
                RUST)
        _box(grime,"EspumaLineaContacto_%02d" % i,
            Vector3(1.015,0.075,z),
            Vector3(0.16,0.008,0.24),
            FOAM,0.06)
    for side in [-1,1]:
        # V1/V2 omit the positive half of the pier at critical damage.
        if damage>=3 and side==1:
            continue
        var z: float=float(side)*5.405
        for i in range(7):
            var x: float=-5.22+float(i)*0.94
            _box(grime,"DepositoSalEspigon_%s_%02d" % [side,i],
                Vector3(x,0.26,z),
                Vector3(0.24,0.14,0.021),
                LIMESTONE if i%2==0 else ALGAE)
            if i%3==0:
                _box(grime,"OxidoJuntaEspigon_%s_%02d" % [side,i],
                    Vector3(x+0.20,0.39,z),
                    Vector3(0.07,0.21,0.023),RUST)
    grime.set_meta("naval_v4_no_phantom_pier",true)

static func _shore_stones(stage: Node3D,damage: int) -> void:
    var coast:=Base._group(stage,"TransicionCostaEscolleraV4")
    var rock_mesh:=SphereMesh.new()
    rock_mesh.radial_segments=7
    rock_mesh.rings=4
    # Shore sculpt stays OUTSIDE the operating inner channel (z=+-6.1..6.8
    # and x>2.6). No new fictitious island blocks a ship.
    for sign in [-1,1]:
        for i in range(12):
            var rock:=MeshInstance3D.new()
            rock.name="RocaEscollera_%s_%02d" % [sign,i]
            rock.mesh=rock_mesh
            rock.material_override=Base._material(
                ROCKS[(i+2*(sign+1))%ROCKS.size()],0.03)
            var x: float=2.68+float(i%6)*0.75
            var z: float=float(sign)*(
                6.16+float(i/6)*0.36+float((i*7)%3)*0.08)
            rock.position=Vector3(x,0.49+float(i%3)*0.015,z)
            rock.scale=Vector3(0.33+float(i%4)*0.07,
                0.15+float((i+1)%3)*0.045,
                0.25+float(i%3)*0.055)
            rock.rotation_degrees=Vector3(4*i,31*i,3*i)
            coast.add_child(rock)
        # A thin gravel seam visually joins the concrete apron to coast.
        for i in range(7):
            var x: float=2.83+float(i)*0.64
            _box(coast,"GravaTransicion_%s_%02d" % [sign,i],
                Vector3(x,0.536,float(sign)*6.10),
                Vector3(0.45,0.035,0.19),
                ROCKS[(i+1)%ROCKS.size()],0.03,
                Vector3(0,float((i%3)*7),0))
    if damage>=3:
        for i in range(4):
            var at:=Vector3(3.20+float(i)*0.75,
                0.64,6.29+float(i%2)*0.25)
            _box(coast,"PiedraDesplazadaPorImpacto_%d" % i,
                at,Vector3(0.34,0.17,0.22),RUST,0.07,
                Vector3(12,float(i)*17,9))
    coast.set_meta("naval_v4_shore_does_not_block_basin",true)

static func _shipyard_wear(stage: Node3D,level: int,
        damage: int) -> void:
    if damage>=4:
        return
    var yard:=Base._group(stage,"DesgasteSueloAstilleroV4")
    # Floor traces near the existing workshop: no reconstructed roof,
    # new walls or covered destroyed machinery.
    for i in range(6):
        if damage>=3 and i in [2,3]:
            continue
        var x: float=2.73+float(i%3)*0.62
        var z: float=-0.61+float(i/3)*0.72
        _box(yard,"MarcaRodaduraAstillero_%02d" % i,
            Vector3(x,0.739,z),
            Vector3(0.33,0.013,0.14),
            DARK if i%2==0 else RUST,0.12,
            Vector3(0,13*(i%3),0))
    if level>=2 and damage<=2:
        for i in range(4):
            _box(yard,"ManchaFluidoServicios_%02d" % i,
                Vector3(3.06+float(i)*0.33,0.744,-0.38),
                Vector3(0.12+float(i%2)*0.09,0.008,0.12),
                Color("#35474b"),0.13)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V2.STAGE_NAME) or not model.has_node(V3.STAGE_NAME):
        return false
    if model.has_node(STAGE_NAME):
        return false
    # Coating the true underlying 3D meshes is additive on a fresh model.
    # Switching V4 off rebuilds V3 with its original materials.
    var count: int=_material_finishing(model,damage)
    var stage:=Base._group(model,STAGE_NAME)
    _seawall_grime(stage,damage)
    _shore_stones(stage,damage)
    _shipyard_wear(stage,level,damage)
    stage.set_meta("naval_v4_coated_meshes",count)
    stage.set_meta("naval_v4_damage",damage)
    stage.set_meta("naval_v4_level",level)
    stage.set_meta("naval_v4_faction",faction)
    stage.set_meta("naval_v4_original_emblems_preserved",true)
    return true
