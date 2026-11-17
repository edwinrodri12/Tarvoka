extends RefCounted
class_name TarvokaCivilianCityTacticalLOD4

# Fourth native Godot 4.3 civilian-city art stage: recognizable civic
# silhouette at mobile/turn-based map zoom and reversible real mesh LOD.
# 0=close full model, 1=tactical medium, 2=far/mobile silhouette.
# Changing LOD never changes sites, income, capture or game rules.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const V3=preload("res://scripts/ui/CivilianCityPublicSpaceV3.gd")
const V8=preload("res://scripts/ui/CivilianCityArchitectureV8.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V10=preload("res://scripts/ui/CivilianCityGroundFrontV10.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const V12=preload("res://scripts/ui/CivilianCityDamageFinishV12.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV4SiluetaTacticaLOD"
const LEVELS=["Cercano · detalle completo",
    "Táctico · detalles reducidos",
    "Móvil · silueta esencial"]
const DARK=Color("#29424c")
const LIGHT=Color("#c6bca4")
const NEUTRAL=Color("#c9a657")
const DAMAGE=Color("#655e57")

static func _part(root: Node3D,label: String,
        pos: Vector3,dimensions: Vector3,color: Color) -> void:
    V1._box(root,label,pos,dimensions,color,"metal")

static func _civic_sign(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=3:
        # A demolished municipal hall cannot display an intact rooftop sign.
        _part(stage,"PlacaMunicipalDerribadaV4",
            Vector3(0.32,0.20,-2.55),
            Vector3(0.85,0.16,0.48),DAMAGE)
        return
    var floors: int=2 if level==1 else 3 if level==2 else 4
    var roof_y: float=float(floors)*2.10+0.21
    # Large horizontal civic accent remains legible even at 320p. It is
    # placed on the existing south-facing parapet of the town hall.
    _part(stage,"FranjaMunicipalVisibleV4",
        Vector3(0.0,roof_y-0.36,-2.24),
        Vector3(2.47,0.28,0.16),
        accent if damage==0 else DAMAGE)
    if damage==2:
        _part(stage,"LetreroMunicipalRotoV4",
            Vector3(0.40,roof_y-0.11,-2.22),
            Vector3(0.65,0.25,0.16),DAMAGE)
        return
    if level==1:
        # Village silhouette: shallow clockless sign, not a military mast.
        _part(stage,"RemateVillaV4",
            Vector3(0.0,roof_y+0.24,-2.20),
            Vector3(0.90,0.38,0.19),LIGHT)
        _part(stage,"CentroRemateVillaV4",
            Vector3(0.0,roof_y+0.26,-2.302),
            Vector3(0.52,0.18,0.055),accent)
    elif level==2:
        # Mid-tier distinct civic plaque beneath the existing clock tower.
        _part(stage,"MarcoMunicipalCiudadV4",
            Vector3(0.0,roof_y-0.07,-2.22),
            Vector3(1.56,0.55,0.19),DARK)
        _part(stage,"PlacaMunicipalCiudadV4",
            Vector3(0.0,roof_y-0.07,-2.33),
            Vector3(1.22,0.31,0.055),accent)
    else:
        # Metropolis: two slender symmetrical crown fins on civic roof.
        for side in [-1,1]:
            _part(stage,"AletaCoronaMetropoliV4_%d" % side,
                Vector3(float(side)*1.22,roof_y+0.26,-2.16),
                Vector3(0.18,0.70,0.20),DARK)
            _part(stage,"LuzCoronaMetropoliV4_%d" % side,
                Vector3(float(side)*1.22,roof_y+0.66,-2.19),
                Vector3(0.22,0.10,0.23),accent)

static func _plaza_landmark(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=3:
        return
    # A single larger frame makes the central civil plaza instantly
    # recognizable from the same perspective used for the tactical map.
    for side in [-1,1]:
        _part(stage,"AcentoPlazaTacticaV4_%d" % side,
            Vector3(float(side)*1.76,0.112,2.20),
            Vector3(0.18,0.09,1.96),
            accent if damage==0 else DAMAGE)
    if level>=2 and damage==0:
        _part(stage,"SenalPrincipalPlazaV4",
            Vector3(0.0,0.16,3.07),
            Vector3(1.50,0.12,0.14),accent)

# Filter only rendering meshes; never hide/delete parent nodes, selection
# volumes, site metadata or visual stages used by the shared editor.
static func _keep_medium(name: String) -> bool:
    for prefix in [
        "FloresVillaV3_","PataBanco_","PosteMercado_",
        "PilarParadaV3_","BolardoPeatonalV3_",
        "PavimentoTactilV3_","FranjaSenalV3_",
        "PersianaVillaV2_","PosteBalconV2_",
        "Boquilla","Alfeizar_","CristalEscaparateV2_",
        "PlacaMonumento","CanalonPluvialV2",
        # V8: close-up window mullions, residential metalwork and individual
        # rooftop fittings disappear at mid-range but the façades stay.
        "CristalPosteriorV8_","MontantePosteriorV8_",
        "TravesanoPosteriorV8_","AlfeizarPosteriorV8_",
        "CristalCostadoV8_","AlfeizarCostadoV8_",
        "ContraventanaVillaV8_","MarcoBuhardillaV8_",
        "BastidorSolarV8_","BarandaEvacuacionV8_",
        "EscaleraEvacuacionV8_","SoporteDepositoV8_",
        "ParteluzComercioV8_","DovelaCivicaV8_",
        # V9: model the material joints in full only near the camera.
        "AbrazaderaCanalonV9_","GrapaBajanteV9_","BocaPluvialV9_",
        "HiladaEsquinaV9_","BaberoBuhardillaV9_",
        "TapajuntaMarquesinaV9_","FajaEntrePisosV9_",
        "CostillaPanelSolarV9_","PerfilAluminioV9_",
        "FiloCoronaMetropolitanaV9_","JambaTorreRelojV9_",
        "PilastraMunicipalDelanteraV9_","PilastraMunicipalTraseraV9_",
        # V10: only close-up doorway hardware and walkway joints.
        "TiradorPortalV10_","MontantePortalV10_",
        "BordilloEntradaV10_","CenefaMarcaComercialV10_",
        "FiloMarquesinaV10_","BandaTactilAccesoMunicipalV10",
        "BordeRampaMunicipalV10_","DesgasteEscalonV10_",
        # V11: retain shape-changing structural walls, cull tiny rebar.
        "VarillaForjadoExpuestaV11_","PiedraRematePosteriorV11_",
        "BasePilastraTraseraAytoV11_","CornisaComercialV11_",
        "CantoLosaExpuestoV11_","LadrilloSaltadoDintelV11_",
        # V12 only: microscopic cracks, rebar and individual debris details.
        "GrietaLateralVolumetricaV12_",
        "PiedraDesconchadaCostadoV12_",
        "AceroCostadoVisibleV12_",
        "ApoyoVigaV12_","EscalonInteriorRotoV12_",
        "ArmaduraPilarInteriorV12_",
        "CascoteCostadoV12_","PiedraDesgastadaMunicipalV12",
        "CasquilloCivicoV12_"]:
        if name.begins_with(prefix):
            return false
    return true

static func _keep_far(name: String) -> bool:
    # Keep geometry essential for silhouette, urban base and faction cue.
    # Deliberately no thousands of windows, benches, shrubs or railings.
    for prefix in [
        "BaseUrbana","AvenidaCentral","Acera_","PlazaCivica",
        "RibetePlaza","MonumentoPlaza","MonumentoVolcado",
        "VolumenMamposteria","Cimiento","Cubierta",
        "EstructuraArruinada","FachadaCaida","EscombrosBase",
        "Fragmento_","CornisaMunicipal","TorreRelojMunicipal",
        "TechoReloj","EsferaReloj","AzoteaEscalonada_",
        "TerrazaVerde_","FrontonTriangularV2_Ayuntamiento",
        "CoronacionAyuntamientoV2","TejaInclinadaV2_",
        "CaballeteTejadoV2","ParapetoPosteriorV2",
        "ParapetoLateralV2_","MaquinaClimaV2",
        "FranjaMunicipalVisibleV4","LetreroMunicipalRotoV4",
        "PlacaMunicipalDerribadaV4","RemateVillaV4",
        "CentroRemateVillaV4","MarcoMunicipalCiudadV4",
        "PlacaMunicipalCiudadV4","AletaCoronaMetropoliV4_",
        "LuzCoronaMetropoliV4_","AcentoPlazaTacticaV4_",
        "SenalPrincipalPlazaV4",
        # V8 silhouette-only roof and damage parts remain at tactical scale.
        "BuhardillaVillaV8_","TejadilloBuhardillaV8_",
        "AleroPuertaVillaV8_","MarquesinaContinuaV8_",
        "CasetaAccesoAzoteaV8_","CubiertaCasetaV8_",
        "DepositoAguaV8_","TapaDepositoV8_",
        "RemateEscalonadoV8_","FranjaRemateMetropolitanoV8_",
        "RemateTorreCivicaV8",
        "EntablamentoMunicipalPosteriorV8",
        "CornisaMunicipalQuebradaV8",
        "MamposteriaFracturadaV8_","RestosCoronaMetropoliV8",
        # V9: preserve only the material joins that affect the outline.
        "RemateTejaBordeVillaV9_","VigaCoronaMetropolitanaV9_",
        "VigaCoronaPosteriorV9_","VigaCoronaFrontalV9_",
        "JuntaCubiertaAyuntamientoV9","ClaveMunicipalDerribadaV9",
        "RemateParapetoRotoV9_","PanelCoronaDobladoV9",
        # V10: major entry proportions survive from a distance.
        "PlataformaAccesoCivilV10","RampaPeatonalConectadaV10",
        "UmbralMunicipalHundidoV10",
        "ArcoDintelMunicipalV10","MarquesinaEscalonadaV10_",
        "PorcheVillaV10_","AccesoViviendaDerruidoV10_",
        # V11 shape-defining damage: actual polygon wall silhouette
        # instead of the previous schematic solid ruin rectangles.
        "FachadaNorteQuebradaV11_","FachadaSurQuebradaV11_",
        "MuroCostadoRotoV11_","DerrumbeMamposteriaV11_",
        "ForjadoColapsadoV11_","PisoInterrumpidoV11_",
        "PortalCivilArrancadoV11","LosaTechoDesplazadaV11_",
        "AberturaCubiertaQuemadaV11_",
        "ClaveMunicipalDerribadaV9",
        # V12 silhouette: only rubble heaps and major room supports.
        "DintelDerribadoV12_","FragmentoContinuoV12_",
        "VigaTransversalExpuestaV12_",
        "VigaCaidaSueloV12_","ZapataCimentacionAbiertaV12_",
        "EscaleraCivicaInterrumpidaV12",
        "VigaCivicaVolcadaV12"]:
        if name.begins_with(prefix):
            return true
    return false

static func _keep(name: String,lod: int) -> bool:
    return true if lod==0 else _keep_medium(name) if lod==1 else _keep_far(name)

static func drawable_count(root: Node,visible_only: bool=true) -> int:
    var total: int=0
    var pending: Array[Node]=[root]
    while not pending.is_empty():
        var current: Node=pending.pop_back()
        if current is MeshInstance3D:
            var mesh:=current as MeshInstance3D
            if not visible_only or mesh.visible:
                total+=1
        for child in current.get_children():
            pending.append(child)
    return total

static func set_detail(model: Node3D,lod: int) -> bool:
    if model==null or not model.has_node(STAGE_NAME) or lod<0 or lod>2:
        return false
    var pending: Array[Node]=[model]
    var shown: int=0
    var total: int=0
    while not pending.is_empty():
        var current: Node=pending.pop_back()
        if current is MeshInstance3D:
            var mesh:=current as MeshInstance3D
            # V11 keeps approved V1 proxy geometry editable but hides
            # superseded cube ruins at ALL zoom tiers, not just LOD0.
            mesh.visible=(not bool(mesh.get_meta(
                "v11_schematic_replaced",false))
                and _keep(str(mesh.name),lod))
            total+=1
            if mesh.visible:
                shown+=1
        for child in current.get_children():
            pending.append(child)
    model.set_meta("city_lod",lod)
    model.set_meta("city_drawable_count",shown)
    model.set_meta("city_mesh_count",total)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V1.STAGE_NAME) or
            not model.has_node(V2.STAGE_NAME) or
            not model.has_node(V3.STAGE_NAME) or
            model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-2))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=Style.faction_color(faction) if faction>=0 else NEUTRAL
    _civic_sign(stage,level,damage,accent)
    _plaza_landmark(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("detail_version",4)
    stage.set_meta("tactical_landmark","municipal-roof-and-plaza")
    stage.set_meta("damage",damage)
    # V8 is ADDITIVE sculpture. The shared studio and real battlefield both
    # use this single build path; previous V1-V4 meshes remain unchanged.
    if not V8.apply(model,level,faction,damage):
        return false
    # V9 is modeled, not artistically locked or final-approved yet.
    if not V9.apply(model,level,faction,damage):
        return false
    if not V10.apply(model,level,faction,damage):
        return false
    if not V11.apply(model,level,faction,damage):
        return false
    if not V12.apply(model,level,faction,damage):
        return false
    model.set_meta("city_art_work_in_progress",12)
    return set_detail(model,0)

# Native runtime option for dense city maps, reducing BOTH visible drawcalls
# and retained MeshInstance3D nodes; do not use on interactive editor models.
static func build_tactical(level: int,faction: int,
        damage: int,lod: int=2) -> Node3D:
    if not V1.valid_spec(level,faction,damage) or lod<0 or lod>2:
        return null
    var model:=V1.build(level,faction,damage)
    if model==null:
        return null
    if (not V2.apply(model,level,faction,damage) or
            not V3.apply(model,level,faction,damage) or
            not apply(model,level,faction,damage)):
        model.free()
        return null
    if lod==0:
        return model
    var remove: Array[Node]=[]
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var current: Node=pending.pop_back()
        if current is MeshInstance3D:
            if (bool(current.get_meta("v11_schematic_replaced",false))
                    or not _keep(str(current.name),lod)):
                remove.append(current)
        for child in current.get_children():
            pending.append(child)
    for item in remove:
        item.free()
    set_detail(model,0)
    model.set_meta("city_lod",lod)
    model.set_meta("city_drawable_count",drawable_count(model))
    model.set_meta("city_mesh_count",drawable_count(model))
    model.set_meta("tactical_compact",true)
    model.set_meta("removed_render_meshes",remove.size())
    return model
