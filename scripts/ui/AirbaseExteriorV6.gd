extends RefCounted
class_name TarvokaAirbaseExteriorV6

# Native, additive architectural polish for the existing Airbase V1/V2/V4.
# All geometry is visual-only; no HP, economy, flight rules, or new lights.
# Local hangar geometry must remain aligned with the V3 runway/door center.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME := "AcabadoArquitectonicoBaseAereaV6"
const STEEL := Color("#334750")
const BEVEL := Color("#8ea5a9")
const PANEL := Color("#6f858d")
const CONCRETE := Color("#a5b4b4")
const DARK := Color("#202f38")
const GLASS := Color("#335e73")
const SAFETY := Color("#e0b357")
const EMITTER := Color("#b8e5f0")
const RUST := Color("#655651")

static func _box(parent: Node3D, label: String, position: Vector3,
        dimensions: Vector3, color: Color, metallic: float = 0.18,
        emissive: bool = false) -> MeshInstance3D:
    var item: MeshInstance3D = Airbase._box(
        parent,label,position,dimensions,color,metallic)
    if emissive:
        item.material_override = Airbase._mat(color,0.04,true)
    return item

static func _part(parent: Node3D, label: String) -> Node3D:
    var part := Node3D.new()
    part.name = label
    parent.add_child(part)
    return part

static func apply(model: Node3D, level: int, faction: int, damage: int) -> bool:
    if model == null or not Airbase.valid_spec(level,faction,damage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false):
        return false
    if model.get_meta("tarvoka_airbase_v6",false):
        return false
    var finish := _part(model,STAGE_NAME)
    finish.set_meta("tarvoka_visual_only",true)
    finish.set_meta("tarvoka_airbase_exterior_v6",true)
    var accent: Color = Style.faction_color(faction)
    _apron(finish,accent,damage)
    if damage < 4:
        var hangar: Node3D = model.find_child("HangarPrincipalV1",true,false) as Node3D
        var tower: Node3D = model.find_child("TorreControlAereoV1",true,false) as Node3D
        if hangar == null or tower == null:
            model.remove_child(finish)
            finish.free()
            return false
        _hangar_finish(hangar,accent,damage)
        _tower_finish(tower,accent,level,damage)
        _service_finish(finish,accent,damage)
    else:
        _ruins_finish(finish)
    model.set_meta("tarvoka_airbase_v6",true)
    model.set_meta("tarvoka_airbase_v6_level",level)
    model.set_meta("tarvoka_airbase_v6_faction",faction)
    model.set_meta("tarvoka_airbase_v6_damage",damage)
    return true

static func _apron(parent: Node3D, accent: Color, damage: int) -> void:
    var apron := _part(parent,"MarcasAeronauticasYDrainajeV6")
    # Thin markings on the existing level V3 pavement, never a new runway.
    # Keep the EXACT V3 taxiway X alignment; no paint across the door threshold.
    var cx: float = Airbase.TAXIWAY_CENTER_X
    var cz: float = Airbase.TAXIWAY_CENTER_Z
    for side in [-1,1]:
        var x: float = cx+float(side)*2.82
        _box(apron,"BordeRodajeV6_%s" % side,
            Vector3(x,0.125,cz-0.02),Vector3(0.045,0.013,2.09),
            SAFETY,0.01)
    # Direction arrow running along the center line (-Z) from the gate.
    _box(apron,"FlechaRodajeTalloV6",Vector3(cx,0.136,cz-0.34),
        Vector3(0.105,0.010,0.62),CONCRETE,0.02)
    for side in [-1,1]:
        var arrow := _box(apron,"FlechaRodajePuntaV6_%s" % side,
            Vector3(cx+float(side)*0.145,0.136,cz-0.70),
            Vector3(0.085,0.011,0.39),CONCRETE,0.02)
        arrow.rotation_degrees.y = float(side)*33.0
    # Flush drains outside the gate travel path; no raised collision geometry.
    for side in [-1,1]:
        var x: float = cx+float(side)*3.20
        _box(apron,"CanaletaDesagueV6_%s" % side,
            Vector3(x,0.124,-4.93),Vector3(0.18,0.012,1.73),
            DARK,0.32)
        for slot in range(4):
            _box(apron,"RanuraDesagueV6_%s_%d" % [side,slot],
                Vector3(x,0.137,-5.54+float(slot)*0.38),
                Vector3(0.13,0.008,0.055),BEVEL,0.21)
    if damage < 3:
        # Painted safety stop at the fuel service access, off the runway.
        _box(apron,"LimiteServicioTecnicoV6",
            Vector3(4.28,0.132,1.17),Vector3(1.51,0.015,0.10),
            SAFETY,0.03)
    elif damage == 4:
        _box(apron,"HormigonAstilladoV6",
            Vector3(0.18,0.155,3.88),Vector3(1.91,0.04,0.42),
            RUST,0.06)

static func _hangar_finish(hangar: Node3D, accent: Color,
        damage: int) -> void:
    var shell := _part(hangar,"FachadasPanelizadasHangarV6")
    # Wall seams are shallow architectural detailing and are independent
    # from moving door leaf meshes (which V2 animates by name).
    for side in [-1,1]:
        var x: float = float(side)*3.725
        for bay in range(4):
            var z: float = -2.41+float(bay)*1.56
            _box(shell,"JuntaFachadaV6_%s_%d" % [side,bay],
                Vector3(x,1.23,z),Vector3(0.025,2.15,0.065),
                STEEL,0.28)
        _box(shell,"CornisaLateralV6_%s" % side,
            Vector3(x,2.68,0.00),Vector3(0.12,0.09,6.42),
            BEVEL,0.29)
        if damage < 3:
            _box(shell,"PlacaAccesoExteriorV6_%s" % side,
                Vector3(x,1.32,-1.06),Vector3(0.042,0.68,0.92),
                PANEL,0.12)
            _box(shell,"FranjaAccesoExteriorV6_%s" % side,
                Vector3(x+float(side)*0.029,1.59,-1.06),
                Vector3(0.044,0.084,0.79),accent,0.17)
    # Architectural fascia above the gate. No new bars across the gate mouth.
    _box(shell,"DintelCarenadoHangarV6",
        Vector3(0,3.10,-3.49),Vector3(6.89,0.15,0.17),
        STEEL,0.35)
    _box(shell,"FranjaIdentidadFaccionV6",
        Vector3(0,3.205,-3.50),Vector3(6.30,0.065,0.10),
        accent,0.12)

    # Real roof seam strips follow the same original sinusoidal roof arch.
    # Missing V1 roof portions remain missing at stages 2 and 3.
    if damage < 4:
        var top := _part(hangar,"CostillasCubiertaCurvaV6")
        for seam in range(1,14):
            if damage == 2 and seam in [6,7,8]:
                continue
            if damage == 3 and seam in [2,3,4,5,6,7,8]:
                continue
            var x: float = -3.65+float(seam)*7.30/14.0
            var y: float = 2.80+0.73*sin(PI*(x+3.65)/7.30)
            _box(top,"JuntaCurvaV6_%02d" % seam,
                Vector3(x,y+0.018,0.00),Vector3(0.046,0.055,6.49),
                BEVEL,0.30)
        for side in [-1,1]:
            _box(top,"RemateCanalonV6_%s" % side,
                Vector3(float(side)*3.61,2.83,0.00),
                Vector3(0.12,0.09,6.48),STEEL,0.22)
    # Mechanical panel on the front/roof remains visible at tactical zoom.
    if damage <= 1:
        _box(shell,"LetreroAerodromoV6",Vector3(0.0,2.58,-3.537),
            Vector3(1.21,0.20,0.045),DARK,0.05)
        for i in range(3):
            _box(shell,"PilotoEstadoHangarV6_%d" % i,
                Vector3(-0.34+float(i)*0.34,2.58,-3.568),
                Vector3(0.15,0.047,0.026),
                Color("#74d7a7") if i==0 else SAFETY if i==1 else accent,
                0.04,true)

static func _tower_finish(tower: Node3D, accent: Color,
        level: int, damage: int) -> void:
    var tower_detail := _part(tower,"TorreAeroNavegacionV6")
    var height: float = 3.33+float(level-1)*0.62
    for side in [-1,1]:
        _box(tower_detail,"NervioEstructuralTorreV6_%s" % side,
            Vector3(float(side)*0.615,height*0.51,-0.709),
            Vector3(0.065,height*0.84,0.09),STEEL,0.31)
    if damage < 3:
        _box(tower_detail,"AleronProteccionSolarV6",
            Vector3(0,height+1.39,0.0),Vector3(2.65,0.07,2.48),
            STEEL,0.31)
        # Thin lightbox below the rim: emissive material, NO new point lights.
        _box(tower_detail,"BalizaControlV6",
            Vector3(0,height+1.32,-1.16),Vector3(1.16,0.065,0.045),
            EMITTER,0.04,true)
        for side in [-1,1]:
            _box(tower_detail,"MarcoFrontalCristalV6_%s" % side,
                Vector3(float(side)*0.50,height+0.71,-0.997),
                Vector3(0.052,0.73,0.065),BEVEL,0.34)
        _box(tower_detail,"CristalFajaV6",
            Vector3(0,height+0.77,-1.013),Vector3(0.95,0.22,0.025),
            GLASS,0.08)
        _box(tower_detail,"LineaSeguridadTorreV6",
            Vector3(0,height+0.17,-1.12),Vector3(1.57,0.08,0.06),
            accent,0.10)
    else:
        _box(tower_detail,"CableCortadoDanoCriticoV6",
            Vector3(0.68,height-0.20,-0.85),Vector3(0.09,0.70,0.08),
            RUST,0.12)

static func _service_finish(parent: Node3D, accent: Color,
        damage: int) -> void:
    var yard := _part(parent,"PatioMantenimientoAeronauticoV6")
    # Exterior equipment hugs the far side of the existing apron.
    _box(yard,"BaseTecnicaEquiposV6",Vector3(-5.12,0.15,5.13),
        Vector3(2.19,0.09,1.14),STEEL,0.17)
    for i in range(2):
        _box(yard,"CajaServicioV6_%d" % i,
            Vector3(-5.65+float(i)*0.85,0.51,5.17),
            Vector3(0.70,0.64,0.67),PANEL,0.14)
        _box(yard,"IndicadorServicioV6_%d" % i,
            Vector3(-5.65+float(i)*0.85,0.72,4.817),
            Vector3(0.39,0.06,0.025),accent,0.05,true)
    for side in [-1,1]:
        var x: float = 3.51+float(side)*0.76
        _box(yard,"PernoAnclajeDepositoV6_%s" % side,
            Vector3(x,0.17,-0.94),Vector3(0.23,0.09,0.23),
            STEEL,0.22)
    if damage <= 1:
        _box(yard,"FranjaPeligroDepositoV6",
            Vector3(4.37,0.12,-1.22),Vector3(1.55,0.013,0.085),
            SAFETY,0.03)
    elif damage >= 2:
        _box(yard,"PlacaDesprendidaDepositoV6",
            Vector3(4.36,0.21,-1.22),Vector3(1.35,0.10,0.25),
            RUST,0.18)

static func _ruins_finish(parent: Node3D) -> void:
    var ruins := _part(parent,"RestosEstructuralesBaseAereaV6")
    # Do not recreate any intact roof/wall/tower above destroyed V1 ruins.
    for i in range(5):
        var segment := _box(ruins,"VigaRuinaMetalicaV6_%d" % i,
            Vector3(-5.25+float(i)*1.36,0.31,1.85+float(i%2)*0.63),
            Vector3(0.86,0.10,0.19),STEEL,0.24)
        segment.rotation_degrees = Vector3(4,float(i)*17,17 if i%2==0 else -21)
    _box(ruins,"PlanchaBaseQuemadaV6",
        Vector3(-1.94,0.20,-2.95),Vector3(2.22,0.065,0.79),
        RUST,0.10)
