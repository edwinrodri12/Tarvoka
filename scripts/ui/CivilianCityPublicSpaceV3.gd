extends RefCounted
class_name TarvokaCivilianCityPublicSpaceV3

# Visual-only Godot 4.3 layer on CivilianCity V1 + Facade V2.
# Civilian income, site placement, infantry capture and ownership semantics
# are unchanged. Every object stays within the original city footprint.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV3PlazaAccesosYMovilidad"
const LIMESTONE=Color("#c4b8a1")
const TACTILE=Color("#d6b96a")
const CROSSWALK=Color("#e1dac7")
const DARK=Color("#33474c")
const METAL=Color("#71888b")
const PAVEMENT=Color("#9caba3")
const BRICK=Color("#997b6a")
const WATER=Color("#4b8793")
const GREEN=Color("#60896c")
const FLOWERS=Color("#c7a56c")
const RUST=Color("#916557")
const RUBBLE=Color("#615e58")

static func _box(root: Node3D, label: String, at: Vector3,
        size: Vector3, tint: Color, kind: String="stone") -> void:
    V1._box(root,label,at,size,tint,kind)

static func _cylinder(root: Node3D,label: String,at: Vector3,
        radius: float,height: float,tint: Color) -> void:
    V1._cylinder(root,label,at,radius,height,tint,8)

static func _street(model: Node3D,damage: int) -> void:
    var stage:=V1._group(model,"PasoPeatonalV3")
    if damage>=3:
        # A war-torn road remains war-torn; it is not repainted intact.
        _box(stage,"GrietaAvenidaV3",
            Vector3(-0.2,0.053,0.0),Vector3(1.35,0.014,0.12),RUBBLE)
        _box(stage,"AsfaltoDesplazadoV3",
            Vector3(0.84,0.065,-0.52),
            Vector3(0.91,0.08,0.58),RUST)
        return
    # East-west avenue crosses the north-south civic walkway: the zebra
    # stripes lie on the existing asphalt, never above the sidewalk.
    for i in range(6):
        var x: float=-1.15+float(i)*0.46
        if damage==2 and i in [2,5]:
            continue
        _box(stage,"FranjaPasoCebraV3_%d" % i,
            Vector3(x,0.045,0.0),
            Vector3(0.30,0.014,1.52),
            CROSSWALK if damage<=1 else RUST)
    for side in [-1,1]:
        var z: float=float(side)*1.15
        _box(stage,"PavimentoTactilV3_%d" % side,
            Vector3(0.0,0.105,z),
            Vector3(1.65,0.052,0.38),
            TACTILE if damage<2 else BRICK)
        # Short metal bollards mark the pedestrian crossing edges.
        if damage==0:
            for xside in [-1,1]:
                _cylinder(stage,
                    "BolardoPeatonalV3_%d_%d" % [side,xside],
                    Vector3(float(xside)*1.08,0.39,z),
                    0.085,0.56,DARK)

static func _townhall_entrance(model: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var group:=V1._group(model,"AccesoPublicoAyuntamientoV3")
    if damage>=3:
        # Broken entrance step only; no intact city hall doorway.
        _box(group,"EscaleraMunicipalRotaV3",
            Vector3(0.18,0.11,-1.84),
            Vector3(1.22,0.21,0.49),RUBBLE)
        return
    # The V1 hall front faces north (z=-5.12), away from the main street.
    # V3 gives the south wall (z=-2.38) its own legible PUBLIC entrance.
    _box(group,"PortonSurAyuntamientoV3",
        Vector3(0.0,0.99,-2.322),
        Vector3(1.08,1.82,0.11),DARK,"metal")
    _box(group,"DintelPuertaMunicipalV3",
        Vector3(0.0,1.98,-2.257),
        Vector3(1.48,0.16,0.31),LIMESTONE)
    _box(group,"PlacaCivicaMunicipalV3",
        Vector3(0.0,2.27,-2.24),
        Vector3(1.72,0.30,0.12),
        accent if damage==0 else RUST,"metal")
    for edge in [-1,1]:
        _box(group,"JambaMunicipalV3_%d" % edge,
            Vector3(float(edge)*0.59,1.04,-2.265),
            Vector3(0.15,1.98,0.16),LIMESTONE)
    _box(group,"VestibuloExteriorV3",
        Vector3(0.0,0.13,-1.99),
        Vector3(1.77,0.17,0.76),PAVEMENT)
    for i in range(2):
        var z: float=-1.53+float(i)*0.21
        _box(group,"GradaAccesoV3_%d" % i,
            Vector3(0.0,0.081+float(1-i)*0.042,z),
            Vector3(1.59,0.12,0.28),LIMESTONE)
    if level>=2 and damage<=1:
        # Taller city halls have a modest civic canopy instead of a
        # militarized defensive entrance or a new production building.
        _box(group,"CubiertaPorticoCiudadanoV3",
            Vector3(0.0,2.40,-1.93),
            Vector3(1.95,0.18,0.87),LIMESTONE)
        _box(group,"FranjaIdentidadCivicaV3",
            Vector3(0.0,2.33,-1.48),
            Vector3(1.34,0.11,0.10),accent,"metal")
        for side in [-1,1]:
            _box(group,"ColumnaPorticoSurV3_%d" % side,
                Vector3(float(side)*0.86,1.29,-1.64),
                Vector3(0.11,2.28,0.12),METAL,"metal")
    if damage==2:
        _box(group,"PuertaDesencajadaV3",
            Vector3(0.19,0.84,-2.10),
            Vector3(0.34,1.18,0.08),RUST,"metal")

static func _plaza(model: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var plaza:=V1._group(model,"PlazaPeatonalV3")
    if damage>=3:
        # The approved V1 monument is already collapsed; add a few cracks.
        for i in range(3):
            _box(plaza,"LosetaQuebradaPlazaV3_%d" % i,
                Vector3(-0.77+float(i)*0.76,0.11,2.43),
                Vector3(0.45,0.10,0.27),RUBBLE)
        return
    # Keep the V1 civic statue visible; surround it with shallow stone
    # edging, rather than replacing the sculpture with another building.
    for side in [-1,1]:
        var edge: float=float(side)
        _box(plaza,"BordeFuenteLateralV3_%d" % side,
            Vector3(edge*0.75,0.205,2.05),
            Vector3(0.12,0.20,1.42),LIMESTONE)
        _box(plaza,"BordeFuenteFrontalV3_%d" % side,
            Vector3(0.0,0.205,2.05+edge*0.69),
            Vector3(1.55,0.20,0.12),LIMESTONE)
    if level==1:
        # Village: planted square rather than an expensive water fountain.
        for side in [-1,1]:
            _box(plaza,"MacizoFloresVillaV3_%d" % side,
                Vector3(float(side)*1.48,0.17,2.60),
                Vector3(0.40,0.15,0.65),
                GREEN if damage==0 else RUST)
            _box(plaza,"FloresVillaV3_%d" % side,
                Vector3(float(side)*1.48,0.265,2.60),
                Vector3(0.30,0.04,0.50),FLOWERS)
    elif damage<=1:
        for side in [-1,1]:
            _box(plaza,"AguaAnilloFuenteV3_%d" % side,
                Vector3(float(side)*0.48,0.112,2.05),
                Vector3(0.34,0.027,1.16),
                WATER if damage==0 else METAL,"glass")
        if level==3 and damage==0:
            for side in [-1,1]:
                _box(plaza,"IluminacionPlazaV3_%d" % side,
                    Vector3(float(side)*1.66,0.20,1.17),
                    Vector3(0.26,0.20,0.25),accent,"metal")
    if damage<=1:
        # Wayfinding is visible to the tactical camera without large text
        # textures. Do not show a faction when an actual city is neutral.
        _box(plaza,"DirectorioCivicoV3",
            Vector3(2.83,0.75,1.84),
            Vector3(0.79,1.18,0.13),DARK,"metal")
        _box(plaza,"EtiquetaDistritoV3",
            Vector3(2.83,1.02,1.765),
            Vector3(0.61,0.16,0.055),accent,"metal")
        _box(plaza,"BaseDirectorioV3",
            Vector3(2.83,0.19,1.84),
            Vector3(0.88,0.20,0.39),LIMESTONE)

static func _district_life(model: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=2:
        return
    var root:=V1._group(model,"ComercioYTransporteV3")
    if level==1:
        # Small village: bike rails by the municipal square.
        for i in range(3):
            _box(root,"AparcabicicletasVillaV3_%d" % i,
                Vector3(-3.06+float(i)*0.23,0.41,1.91),
                Vector3(0.055,0.73,0.44),DARK,"metal")
        return
    for side in [-1,1]:
        var x: float=float(side)*5.72
        _box(root,"ParadaUrbanaSueloV3_%d" % side,
            Vector3(x,0.105,1.60),
            Vector3(1.44,0.13,0.72),PAVEMENT)
        _box(root,"BancoParadaV3_%d" % side,
            Vector3(x,0.48,1.67),
            Vector3(1.03,0.15,0.26),BRICK)
        if damage==1 and side==1:
            continue
        for dx in [-1,1]:
            _box(root,"PilarParadaV3_%d_%d" % [side,dx],
                Vector3(x+float(dx)*0.57,1.27,1.80),
                Vector3(0.083,2.10,0.083),METAL,"metal")
        _box(root,"MarquesinaParadaV3_%d" % side,
            Vector3(x,2.37,1.64),
            Vector3(1.54,0.13,0.87),DARK,"metal")
        _box(root,"BandaParadaFacV3_%d" % side,
            Vector3(x,2.31,1.20),
            Vector3(1.09,0.11,0.085),accent,"metal")
    if level==3:
        # Recognizable metropolitan infrastructure above street level.
        for side in [-1,1]:
            var x: float=float(side)*3.65
            _box(root,"PilarSenalDistritoV3_%d" % side,
                Vector3(x,1.37,-1.38),
                Vector3(0.09,2.58,0.09),DARK,"metal")
            _box(root,"SenalDireccionV3_%d" % side,
                Vector3(x,2.43,-1.40),
                Vector3(0.76,0.34,0.11),
                accent if damage==0 else RUST,"metal")
            _box(root,"FranjaSenalV3_%d" % side,
                Vector3(x,2.40,-1.47),
                Vector3(0.53,0.075,0.05),LIMESTONE)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("visual_city_v1",false)):
        return false
    if not model.has_node(V1.STAGE_NAME):
        return false
    if not model.has_node(V2.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-2))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=Style.faction_color(faction) if faction>=0 else V1.NEUTRAL_ACCENT
    _street(stage,damage)
    _townhall_entrance(stage,level,damage,accent)
    _plaza(stage,level,damage,accent)
    _district_life(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("detail_version",3)
    stage.set_meta("level",level)
    stage.set_meta("damage",damage)
    stage.set_meta("faction",faction)
    stage.set_meta("tactical_silhouette","plaza-and-townhall-entrance")
    return true
