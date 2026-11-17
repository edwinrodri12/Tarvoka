extends RefCounted
class_name TarvokaCivilianCityGroundFrontV10

# V10 ART ONLY: articulated street-level arcades, recessed entrances,
# contiguous thresholds, stepped civic approach and coherent sidewalk
# connections. These are REAL native 3D meshes, not textures or billboards.
# No city placement, economy, unit production or combat logic.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V8=preload("res://scripts/ui/CivilianCityArchitectureV8.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV10AccesosPlantaBajaYAcera"

const STONE=Color("#c9c4b3")
const MARBLE=Color("#d8d0b9")
const MORTAR=Color("#9f9b8d")
const SAND=Color("#b9ac92")
const BRICK=Color("#9c7464")
const DARK=Color("#32464c")
const GLASS=Color("#547e8b")
const OXIDIZED=Color("#6c746b")
const WOOD=Color("#806853")
const GOLD=Color("#bc985e")
const SHADOW=Color("#29383b")
const RUBBLE=Color("#69645e")
const BROKEN=Color("#46484a")
const TACTILE=Color("#d5bf78")

static func _box(parent: Node3D,n: String,p: Vector3,
        d: Vector3,c: Color,kind: String="stone") -> MeshInstance3D:
    var piece: MeshInstance3D=V1._box(parent,n,p,d,c,kind)
    # Share the physically distinct material palette of V9 without
    # overriding the approved colors of adjacent civilian V1–V9 meshes.
    piece.material_override=V9._finish(
        c,"glass" if kind=="glass" else
        "steel" if kind=="metal" else "stone")
    return piece

static func _pillar(parent: Node3D,n: String,p: Vector3,
        radius: float,height: float,c: Color) -> void:
    var piece: MeshInstance3D=V1._cylinder(
        parent,n,p,radius,height,c,10)
    piece.material_override=V9._finish(c,"stone")

static func _civic_access(stage: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var entry:=V1._group(stage,"EntradaMunicipalConectadaV10")
    # Existing V3 south-facing town-hall doorway is at z=-2.322.
    # The avenue footpath is at -1.13; all stairs fit between them.
    var hall_front: float=-2.35
    if damage>=3:
        _box(entry,"UmbralMunicipalHundidoV10",
            Vector3(0.0,0.095,-1.86),
            Vector3(1.91,0.13,0.82),RUBBLE)
        for side in [-1,1]:
            var debris:=_box(entry,"FragmentoAccesoV10_%d" % side,
                Vector3(float(side)*0.64,0.23,-1.58),
                Vector3(0.50,0.23,0.34),BROKEN)
            debris.rotation_degrees.y=float(side)*24.0
        return
    _box(entry,"PlataformaAccesoCivilV10",
        Vector3(0.0,0.092,-1.89),
        Vector3(2.23,0.14,0.75),SAND)
    # Surfaces and step ends touch without creating an elevated floating
    # roadway. The center strip meets the existing street crossing.
    _box(entry,"RampaPeatonalConectadaV10",
        Vector3(0.0,0.059,-1.36),
        Vector3(1.67,0.10,0.55),STONE)
    for side in [-1,1]:
        var x: float=float(side)*1.06
        _box(entry,"BordeRampaMunicipalV10_%d" % side,
            Vector3(x,0.098,-1.61),
            Vector3(0.14,0.18,0.92),MARBLE)
        _box(entry,"ZocaloPorticoMunicipalV10_%d" % side,
            Vector3(x,0.16,-2.09),
            Vector3(0.27,0.29,0.38),MORTAR)
    if damage==2:
        _box(entry,"HuecoPortonMunicipalRotoV10",
            Vector3(0.0,1.03,hall_front+0.11),
            Vector3(0.96,1.78,0.09),SHADOW)
        var fragment:=_box(entry,"HojaPuertaMunicipalTorcidaV10",
            Vector3(0.35,0.83,hall_front+0.28),
            Vector3(0.30,1.37,0.08),OXIDIZED,"metal")
        fragment.rotation_degrees.y=-21.0
        _box(entry,"LosaPorticoDañadaV10",
            Vector3(-0.76,0.18,-1.58),
            Vector3(0.76,0.18,0.52),RUBBLE)
        return
    # The portal is recessed optically through its deep stone jambs and
    # metal-glass leaves. Its planes do NOT intersect the V3 canopy.
    _box(entry,"MarcoInteriorPortalV10",
        Vector3(0.0,1.12,hall_front+0.14),
        Vector3(1.30,2.12,0.18),MARBLE)
    for side in [-1,1]:
        var sx: float=float(side)*0.26
        _box(entry,"HojaVidriadaPortalV10_%d" % side,
            Vector3(sx,1.07,hall_front+0.25),
            Vector3(0.47,1.73,0.07),GLASS,"glass")
        _box(entry,"MontantePortalV10_%d" % side,
            Vector3(sx+float(side)*0.24,1.08,hall_front+0.30),
            Vector3(0.052,1.82,0.09),OXIDIZED,"metal")
        _box(entry,"TiradorPortalV10_%d" % side,
            Vector3(float(side)*0.10,1.10,hall_front+0.35),
            Vector3(0.045,0.29,0.085),GOLD,"metal")
    _box(entry,"ArcoDintelMunicipalV10",
        Vector3(0.0,2.18,hall_front+0.18),
        Vector3(1.65,0.20,0.34),STONE)
    _box(entry,"FrisoAccesoCiudadanoV10",
        Vector3(0.0,2.39,hall_front+0.16),
        Vector3(1.34,0.14,0.18),accent,"metal")
    if level>=2:
        for side in [-1,1]:
            _pillar(entry,"ColumnaAccesoExteriorV10_%d" % side,
                Vector3(float(side)*0.90,1.19,-1.81),
                0.11,2.02,MARBLE)
            _box(entry,"BaseColumnaPublicaV10_%d" % side,
                Vector3(float(side)*0.90,0.20,-1.81),
                Vector3(0.35,0.28,0.39),STONE)
    if level==3:
        for side in [-1,1]:
            _box(entry,"LuminariaPortalMetropoliV10_%d" % side,
                Vector3(float(side)*1.11,2.40,-1.97),
                Vector3(0.20,0.28,0.22),GOLD,"metal")

static func _residential_threshold(stage: Node3D,
        x: float,z: float,w: float,d: float,
        side: int,is_south: bool,level: int,
        damage: int,accent: Color) -> void:
    var tag: String=("Sur" if is_south else "Norte")+"_%d" % side
    var entry:=V1._group(stage,"PortalComercioYViviendaV10_"+tag)
    # Rear of north blocks faces z=-2.38; front of south blocks faces
    # z=2.22. The nearest sidewalks are at +/-1.13.
    var frontage: float=z+d*0.5 if not is_south else z-d*0.5
    var sign: float=1.0 if not is_south else -1.0
    var pavement: float=(-1.37 if not is_south else 1.37)
    var edge: float=frontage+sign*0.12
    if damage>=3:
        _box(entry,"AccesoViviendaDerruidoV10_"+tag,
            Vector3(x+0.19,0.13,edge+sign*0.32),
            Vector3(1.18,0.20,0.56),RUBBLE)
        return
    # The tiled stoop physically connects the volume's threshold toward
    # the existing curb but stops before the avenue.
    var path_depth: float=absf(pavement-frontage)
    var middle: float=(frontage+pavement)*0.50
    _box(entry,"UmbralPavimentadoV10_"+tag,
        Vector3(x,0.096,middle),
        Vector3(1.37,0.13,path_depth+0.05),
        SAND if level==1 else MARBLE)
    for hand in [-1,1]:
        _box(entry,"BordilloEntradaV10_%s_%d" % [tag,hand],
            Vector3(x+float(hand)*0.74,0.105,middle),
            Vector3(0.11,0.16,path_depth+0.05),
            BRICK if level==1 else STONE)
    if damage==2:
        _box(entry,"ZaguánQuebradoV10_"+tag,
            Vector3(x,0.24,edge+sign*0.17),
            Vector3(0.90,0.29,0.44),RUBBLE)
        return
    # Add shop awning side cheeks and a recessed bay; the front V2 and
    # rear V8 façades already own their panes, so this makes depth rather
    # than duplicating large windows over those existing glass surfaces.
    if level>=2:
        for hand in [-1,1]:
            _box(entry,"JambaComercialV10_%s_%d" % [tag,hand],
                Vector3(x+float(hand)*0.51,1.02,edge+sign*0.17),
                Vector3(0.14,1.79,0.36),STONE)
        _box(entry,"DintelTiendaV10_"+tag,
            Vector3(x,2.08,edge+sign*0.19),
            Vector3(1.30,0.19,0.36),OXIDIZED,"metal")
        _box(entry,"CenefaMarcaComercialV10_"+tag,
            Vector3(x,2.16,edge+sign*0.39),
            Vector3(0.94,0.12,0.07),accent,"metal")
        if level==3:
            _box(entry,"MarquesinaEscalonadaV10_"+tag,
                Vector3(x,2.31,edge+sign*0.42),
                Vector3(1.64,0.15,0.84),STONE)
            _box(entry,"FiloMarquesinaV10_"+tag,
                Vector3(x,2.25,edge+sign*0.82),
                Vector3(1.51,0.09,0.12),GOLD,"metal")
    else:
        _box(entry,"PorcheVillaV10_"+tag,
            Vector3(x,1.99,edge+sign*0.44),
            Vector3(1.36,0.17,0.84),WOOD)
        for hand in [-1,1]:
            _box(entry,"PieDerechoVillaV10_%s_%d" % [tag,hand],
                Vector3(x+float(hand)*0.59,1.00,edge+sign*0.60),
                Vector3(0.13,1.89,0.13),WOOD)
    if damage==1:
        _box(entry,"DesgasteEscalonV10_"+tag,
            Vector3(x+0.33,0.16,middle+sign*0.10),
            Vector3(0.33,0.08,0.22),OXIDIZED)

static func _pedestrian_junctions(stage: Node3D,
        level: int,damage: int) -> void:
    if damage>=3:
        return
    var street:=V1._group(stage,"ConexionAcerasYGirosV10")
    # Existing main avenue in V1 crosses z=-0.92..0.92, sidewalks
    # run along +/-1.13. Do not accidentally pave the traffic lane.
    for side in [-1,1]:
        var z: float=float(side)*1.30
        _box(street,"BandaAlcorqueAvenidaV10_%d" % side,
            Vector3(0.0,0.065,z),
            Vector3(14.85,0.075,0.14),
            BRICK if level==1 else MORTAR)
        # End caps create a visible connection to the neighboring tile,
        # without extending beyond the approved urban footprint.
        for edge in [-1,1]:
            _box(street,"EncuentroBordilloV10_%d_%d" % [side,edge],
                Vector3(float(edge)*7.60,0.087,z),
                Vector3(0.28,0.12,0.51),STONE)
    if damage==2:
        _box(street,"AdoquinDesprendidoV10",
            Vector3(-0.92,0.19,-1.28),
            Vector3(0.43,0.22,0.38),RUBBLE)
        return
    _box(street,"BandaTactilAccesoMunicipalV10",
        Vector3(0.0,0.133,-1.24),
        Vector3(1.56,0.032,0.24),TACTILE)
    if level>=2:
        for side in [-1,1]:
            _box(street,"UnionTiendaYAceraV10_%d" % side,
                Vector3(float(side)*4.63,0.087,1.29),
                Vector3(1.46,0.07,0.30),STONE)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V1.STAGE_NAME)
            or not model.has_node(V8.STAGE_NAME)
            or not model.has_node(V9.STAGE_NAME)
            or model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    _civic_access(stage,level,damage,accent)
    for side in [-1,1]:
        var x: float=float(side)*4.63
        _residential_threshold(stage,x,-3.80,2.74,2.84,
            side,false,level,damage,accent)
        _residential_threshold(stage,x,3.62,2.77,2.80,
            side,true,level,damage,accent)
    _pedestrian_junctions(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",10)
    stage.set_meta("design_focus","entrances-storefronts-pavements")
    model.set_meta("city_architecture_progress",10)
    model.set_meta("city_model_approved_final",false)
    return true
