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
const V13=preload("res://scripts/ui/CivilianCityCohesionV13.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V15=preload("res://scripts/ui/CivilianCityIdentityV15.gd")
const V16=preload("res://scripts/ui/CivilianCityMaterialJointsV16.gd")
const V17=preload("res://scripts/ui/CivilianCityRearFinishV17.gd")
const V18=preload("res://scripts/ui/CivilianCitySideJointsV18.gd")
const V19=preload("res://scripts/ui/CivilianCityUrbanCohesionV19.gd")
const V20=preload("res://scripts/ui/CivilianCityExteriorFinishV20.gd")
const V21=preload("res://scripts/ui/CivilianCityArchitecturalDetailV21.gd")
const V22=preload("res://scripts/ui/CivilianCityCohesionV22.gd")
const V23=preload("res://scripts/ui/CivilianCitySilhouetteV23.gd")
const V24=preload("res://scripts/ui/CivilianCityStructuralContactsV24.gd")
const V25=preload("res://scripts/ui/CivilianCitySurfaceContinuityV25.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const V27=preload("res://scripts/ui/CivilianCityStreetInterfaceV27.gd")
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
        "CasquilloCivicoV12_",
        # V13: retain structural contacts but omit close-range rebar
        # and single pavement shards when the camera pulls back.
        "NervioConectorV13_","ArmaduraTejadoRotaV13_",
        "JuntaAdoquinConFisuraV13_","AdoquinTejadoLeveV13_",
        "EncuentroEscombroV13_","AnclajeTechoAytoV13_",
        "MamposteriaCivilSueloV13_",
        "BordilloDesmoronadoV13_",
        # V14 close-range roof, material and broken-edge details.
        "JuntaMitraEsquinaV14_","PiezaMitreDesgastadaV14_",
        "RoturaCostado360V14_","BarraArrancadaCostadoV14_",
        "ApoyoCoronaMunicipalV14_","SoporteRelojMunicipalV14",
        "VigaPisoAisladaV14_",
        # V15: small trim, intact facade bands and individual rebar
        # disappear at medium distance. Keep massing and tile identity.
        "CabioGableteV15_","MaderaInclinadaVillaV15_",
        "PiezaMitreDesgastadaV14_","ZocaloRusticoVillaV15_",
        "HileraMamposteriaV15_","PilastraEsquinaCiudadV15_",
        "NervaduraAluminioAltaV15_","CintaVidrioTacticaV15_",
        "AceroArmaduraMetroV15_","BarraArrancadaCostadoV14_",
        "RelievePiedraAyuntamientoVillaV15",
        # V16 narrow joinery and individual material fragments.
        "AlfajiaEnMaderaVillaV16_",
        "PiezaEsquinaPiedraVillaV16_",
        "JuntaMorteroErosionadaVillaV16_",
        "JuntaMorteroCornisaV16_",
        "SillarEsquinaCornisaV16_",
        "CantoneraAluminioMetroV16_",
        "TravesanoMetalMetroV16_",
        "RibeteVidrioTacticoMetroV16_",
        "DetalleColorMetroV16_",
        "DespieceArquitecturaCivilV16_",
        # V17/V18: preserve large roof seams and elevation mass; remove
        # individual windows, sill trims, drainage pins at tactical zoom.
        "CristalVentanaTraseraV17_","AlfeizarTraseroV17_",
        "V18_CristalCostado_","V18_AlfeizarCostado_",
        "V18_DrenajeUmbral_","V18_FasciaAlero_",
        # V19 close-up facade joints and civic identity microstrips.
        "V19_AnclajeEsquinaMamposteria_",
        "V19_TablonRemateVilla_","V19_DintelLadrilloUrbano_",
        "V19_PerfilAluminioUrbano_","V19_CintaCristalUrbana_",
        "V19_PuntoIdentidadBarrio_","V19_LosaHundidaPasaje_",
        # V20 microfinish appears only at close architectural zoom.
        "V20_TejaBorde360Villa_","V20_JuntaMorteroCiudad_",
        "V20_RejillaAzoteaMetro_","V20_CantoneraInferior_",
        "V20_EncuentroCuatroFachadas_","V20_PicadoRevestimiento_",
        "V20_RemateBordillo_","V20_JuntaMetalPasaje_",
        # V21 close-only hardware; reduce glass and fastener drawcalls.
        "V21_Tirador3DPuerta_","V21_TravesañoMadera_",
        "V21_MontanteVentana_","V21_ImpostaVentana_",
        "V21_VidrioOscurecido_","V21_CristalAstillado_",
        "V21_JuntaMorteroCiudad_","V21_Respiradero_",
        "V21_BocaBajante_","V21_CanalonArrancado_",
        # V22 close sculpt: floor friezes, narrow mortar/glass facets.
        "V22_VillaMaderaResalte_","V22_CiudadFrisoPiso_",
        "V22_MetroVidrioCantonera_",
        "V22_MetroIdentidadDiscreta_",
        # V23 low-priority close-up stamps; preserve large silhouettes.
        "V23_MetroMarcaSilueta_","V23_SombraJuntaFractura_",
        # V24 micro joints have no tactical silhouette value.
        "V24_CierreCornisa_","V24_EscuadraMadera_",
        "V24_ClaveMortero_","V24_AnclajeAluminio_",
        "V24_AcaboDespostillado_","V24_ArmaduraDesdeForjado_",
        "V24_VidrioEnForjadoCaido_",
        # V25: facade grout, welds and tiny cut-fiber microdetails LOD0.
        "V25_JuntaCeramica_","V25_CabezaMadera_",
        "V25_JuntaMortero_","V25_RematePiedra_",
        "V25_SoldaduraMetal_","V25_PiezaAnclaje_",
        "V25_SombraBordeRoto_","V25_MorteroAbierto_",
        "V25_AceroCortado_","V25_FibraMaderaRota_",
        "V25_CristalSueltoCimentacion_",
        # V26 small weathered chips are visible only at close zoom.
        "V26_DesgasteRemate_","V26_SustratoCantoRoto_",
        # V27 sidewalk expansion joints and surface chips close only.
        "V27_JuntaDilatacionUmbral_","V27_UnionLosetaAcera_",
        "V27_EncuentroAdoquinPasaje_","V27_LosetaCierrePlaza_",
        "V27_JuntaRampaMunicipal_","V27_AdoquinDesportillado_",
        "V27_MordidaZocalo_"]:
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
        "VigaCivicaVolcadaV12",
        # V13: preserve broken roof outline and civic ruin identity.
        "MensulaTejadoFracturadoV13_","CornisaMordidaV13_",
        "PiedraCimentacionPartidaV13_",
        "DintelAytoTorsionadoV13_",
        "MensulaTechoMunicipalV13_",
        "FrontonMunicipalTruncadoV13",
        "PilarTruncadoMunicipalV13_",
        "EscaleraCivicaInterrumpidaV12",
        "UmbralColapsadoV13_",
        "AleroRetorcidoV13_",
        # V14 all-round outline: retain real damage and iconic hall
        # ruins at tactical zoom; do not keep individual fine joints.
        "LaminaRotaVoladizoV14_","PerfilCornisaSeparadaV14_",
        "PieMuroSerradoV14_","DienteMuroCostadoV14_",
        "PisoAbiertoDienteV14_","CrestaEscombros360V14_",
        "VigaCoronaMunicipalAbiertaV14_",
        "MuroMunicipal360V14_",
        "CostadoMunicipalColapsadoV14_",
        "FrisoMunicipalSuelo360V14",
        "FragmentoRelojEscombroV14",
        # V15: keep an unmistakable identity for each city size even
        # if every building is destroyed (D4).
        "TejaCaballeraV15_","AleroMaderaVillaV15_",
        "TejaSueltaFracturadaVillaV15_",
        "VigaVernacularCaidaV15_",
        "TejaDerruidaVillaV15_",
        "MuroVillaEntramadoV15_",
        "BandaParapetoPiedraV15_",
        "BandaLadrilloRemateV15_",
        "CornisaDesgajadaCiudadV15_",
        "PilastraMamposteriaTruncadaV15_",
        "BloquesMamposteriaCiudadV15_",
        "CornisaMamposteriaBajaV15_",
        "CoronaEscalonadaMetroV15_",
        "LuzFranjaCivicaMetroV15_",
        "PerfilCoronaMetropoliRotoV15_",
        "PilarMetropoliAbiertoV15_",
        "LosaMiradorTorcidaMetroV15_",
        "VidrioRestosMetroV15_",
        "RemateInstitucionalNivelV15_",
        "EscalonCornisaAytoCiudadV15_",
        "AleroMetalicoAytoMetropoliV15",
        "MolduraVillaCivicaCaidaV15",
        "LadrilloCornisaCiudadCaidoV15_",
        "VigaAceroAytoDestruidaV15",
        # V16 architectural signatures preserve material joints at
        # strategic distance even in total-ruin stages.
        "TejaRemateCeramicoVillaV16_",
        "TejaDelaminadaVillaV16_",
        "PerfilTejaCaidaVillaV16_",
        "BocelCornisaPiedraCiudadV16_",
        "CornisaRotaMaterialCiudadV16_",
        "SillarSeparadoCiudadV16_",
        "TapajuntaCoronaMetroV16_",
        "PerfilRetorcidoMetroV16_",
        "CristalDesprendidoMetroV16_",
        "CornisaCivicaTransicionV16_",
        # V18 essentials survive zoom out without costly micro geometry.
        "V18_AleroLateral_","V18_EncuentroTejadoFachada_",
        "V18_RestoCubiertaCaida_","V18_EscombroCostado_",
        # V19 far-LOD keeps the visual roof rhythm and pedestrian structure.
        "V19_DerrumbeMaterial_","V19_RibeteCubierta_",
        "V19_PasajePeatonal_","V19_PasajeInterrumpido_",
        "V19_BordePlazaDerruido_",
        # V20: distance silhouette retains meaningful roof caps and
        # material-specific 360-degree wreckage without tiny facade trim.
        "V20_CoronacionPiedraCiudad_","V20_PerfilTapajuntasMetro_",
        "V20_LosaFracturada360_","V20_PerfilDerrumbe360_",
        "V20_CascoteIdentidadTotal_",
        # V21 skyline finishes and grounded debris survive the far zoom;
        # doors/glazing/individual fittings remain LOD0/LOD1 only.
        "V21_CumbreraCeramica_","V21_CubremuroPiedra_",
        "V21_TejadoHundido_","V21_DintelCaido_",
        "V21_MarcoCaido_","V21_CristalYTabiquesRotos_",
        # V22 silhouette family remains distinguishable at mobile zoom.
        "V22_VillaCeramicaPedestal_","V22_CiudadPilastraEsquina_",
        "V22_MetroNervioVertical_","V22_FragmentoReconocible_",
        # V23 polygonal roof profile and jagged fragments remain
        # readable from all four cardinals at tactical zoom.
        "V23_VillaRematePerfil_","V23_CiudadPerfilEscalonado_",
        "V23_MetroPerfilCorona_","V23_BordeTejadoPartido_",
        "V23_CosturaFachadaRota_","V23_RetornoCascaron_",
        "V23_ForjadoArrancado_","V23_CrestaRuinaBaja_",
        "V23_RemateMunicipal360_","V23_RestanteMunicipalSuelo_",
        # V24 keep only material contacts large enough to read at LOD2.
        "V24_PuntalDescentrado_","V24_FracturaApoyada_",
        "V24_FiloForjadoInterrumpido_","V24_PiezaTabiqueAbierta_",
        "V24_ZapataCortada_","V24_VigaEntreCascotes_",
        "V24_ApoyoAccesoMunicipalRoto",
        "V24_VigaAccesoMunicipalBaja",
        "V24_PiedrasPlacaMunicipalCaida",
        # V25 large-enough broken edges remain visible at game zoom.
        "V25_SeccionTejaPartida_","V25_CantoForjadoVisible_",
        "V25_AnclajeCimientoDestruido_",
        "V25_FrisoMunicipalAgrietado",
        "V25_PiezaPortalMunicipalRota",
        "V25_RestoPlacaMunicipal",
        # V26 large enough weathered broken profile remains visible
        # at battle distance; tiny erosion strips are omitted.
        "V26_TejaExpuestaRota_",
        "V26_CantoPisoDescascarado_",
        "V26_DesgasteRestosBajos_",
        # V27 large damaged street edges, not fine sidewalk grout.
        "V27_EmpalmeAccesoColapsado_",
        "V27_JuntaPasajeColapsado_",
        "V27_BordePlazaQuebrado_",
        "V27_AristaAccesoMunicipalRota_"]:
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
                and not bool(mesh.get_meta("city_v22_superseded",false))
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
    if not V13.apply(model,level,faction,damage):
        return false
    if not V14.apply(model,level,faction,damage):
        return false
    if not V15.apply(model,level,faction,damage):
        return false
    if not V16.apply(model,level,faction,damage):
        return false
    if not V17.apply(model,level,faction,damage):
        return false
    if not V18.apply(model,level,faction,damage):
        return false
    if not V19.apply(model,level,faction,damage):
        return false
    if not V20.apply(model,level,faction,damage):
        return false
    if not V21.apply(model,level,faction,damage):
        return false
    if not V22.apply(model,level,faction,damage):
        return false
    if not V23.apply(model,level,faction,damage):
        return false
    if not V24.apply(model,level,faction,damage):
        return false
    if not V25.apply(model,level,faction,damage):
        return false
    if not V26.apply(model,level,faction,damage):
        return false
    if not V27.apply(model,level,faction,damage):
        return false
    model.set_meta("city_art_work_in_progress",27)
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
                    or bool(current.get_meta("city_v22_superseded",false))
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
