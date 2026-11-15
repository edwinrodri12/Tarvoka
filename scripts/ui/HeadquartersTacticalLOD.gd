extends RefCounted
class_name TarvokaHeadquartersTacticalLOD

# Visual-only, opt-in budget for distant headquarters in large battles.
# The actual authored mesh, faction plates, door, roof, damage silhouettes,
# geometry, gameplay state and transforms are NEVER replaced or deleted.
const CACHE: String="tarvoka_hq_tactical_lod_candidates"
const ACTIVE: String="tarvoka_hq_tactical_lod_active"
const PREFIXES: Array[String]=[
    # V1 micro glazing, perimeter hardware and roof fittings
    "MarcoVentanaF_","VidrioVentanaF_","ParteluzF_","VentanaL_",
    "BastidorPanelSolar_","CelulasSolar_","DivisionPanel_",
    "SeparadorCabina_","H_Raya_","H_Travesano","LuzPista_",
    "LineaVial_","PosteValla_","MallaValla_","PosteLateral_",
    "CierreLateral_","MacetaHormigon_","Arbusto_",
    "IndicadorModulo_","RejillaVentilacion_","EscalonEntrada_",
    "VentanaAla",
    # V2 minor architectural panels, bolts, drainage and helipad
    "TapaJunta_","CostillasVisera_","RecesoVentana_",
    "TramaCristal_","VoladizoVentana_","Alfeizar_",
    "DivisionVidrio_","MarcoAla_","VidrioAla_",
    "LaminaSuperiorAla_","AroPerimetral_","ArmazonParabolica_",
    "RielRoof_","LamaClimatizacion_","BajadaPluvial_",
    "BarandalHelipuerto_","Antideslizante_","Peldaño_",
    "TopeEstacionamiento_","CableSensorPerimetral_",
    "PictogramaGrupo_","GuiaEntrada_",
    # V3 micro finish (retain primary building mass and faction paint)
    "JuntaHorizontal_","DivisionVisor_","VientoNuevo_",
    "MarcacionBarra_","FarolaIngreso_","MarcaDeBodega_",
    "PilaDeEquipos_","PlacaDeServicio_","PataAngular_"
]

static func _matches(name_text: String) -> bool:
    for prefix in PREFIXES:
        if name_text.begins_with(prefix):
            return true
    return false

static func set_reduced(hq: Node3D,reduced: bool) -> int:
    if hq==null or hq.get_meta("tarvoka_building_kind","")!="headquarters":
        return 0
    if bool(hq.get_meta(ACTIVE,false))==reduced:
        return 0
    var candidates: Array=hq.get_meta(CACHE,[])
    if not hq.has_meta(CACHE):
        for part_node in hq.find_children("*","MeshInstance3D",true,false):
            var part: MeshInstance3D=part_node as MeshInstance3D
            if part!=null and _matches(str(part.name)):
                # Preserve initial authored visibility; inactive state must
                # NOT accidentally reveal existing hidden/destruction parts.
                candidates.append([part,part.visible])
        hq.set_meta(CACHE,candidates)
    var changed: int=0
    for pair in candidates:
        var part: MeshInstance3D=pair[0] as MeshInstance3D
        if part==null or not is_instance_valid(part):
            continue
        var natural: bool=bool(pair[1])
        part.visible=natural and not reduced
        if natural:
            changed+=1
    hq.set_meta(ACTIVE,reduced)
    hq.set_meta("tarvoka_hq_tactical_hidden_count",changed if reduced else 0)
    return changed
