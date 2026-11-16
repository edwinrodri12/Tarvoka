extends RefCounted
class_name TarvokaAirbaseHangarV2

# Layered native Godot geometry. The approved V1 roof, tower, helipad,
# emblems and stage-specific structural breaks are preserved.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME := "HangarArquitecturaComercialV2"
const WALL := Color("#9daeb3")
const FRAME := Color("#637780")
const STEEL := Color("#2f404a")
const YELLOW := Color("#e6ae48")
const WHITE := Color("#e1e4e1")
const GRILL := Color("#24343d")
const FLOOR := Color("#56666e")
const LIGHT := Color("#b3deed")

static func _box(parent: Node3D,label: String,
        pos: Vector3,size: Vector3,color: Color,
        metal: float = 0.19,rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return Airbase._box(parent,label,pos,size,color,metal,false,rotation)

static func apply(model: Node3D, level: int, faction: int,
        damage_stage: int) -> bool:
    if model == null or not Airbase.valid_spec(level,faction,damage_stage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false):
        return false
    if model.get_meta("tarvoka_airbase_v2",false) or \
            model.find_child(STAGE_NAME,true,false) != null:
        return false
    var hangar: Node3D = model.find_child("HangarPrincipalV1",true,false) as Node3D
    if hangar == null:
        # Stage 4 contains real V1 ruins and no intact V2 construction.
        # Mark this as processed to make accidental double-layering fail.
        if damage_stage != 4:
            return false
        model.set_meta("tarvoka_airbase_v2",true)
        return true
    var layer := Node3D.new()
    layer.name = STAGE_NAME
    hangar.add_child(layer)
    model.set_meta("tarvoka_airbase_v2",true)
    var accent: Color = Style.faction_color(faction)

    var inside := Node3D.new()
    inside.name = "InteriorOperativoHangarV2"
    layer.add_child(inside)
    _box(inside,"PavimentoInterior",
        Vector3(0,0.14,-0.06),Vector3(6.95,0.055,5.94),FLOOR)
    _box(inside,"JuntaTransversalFondo",
        Vector3(0,0.175,1.95),Vector3(6.72,0.015,0.065),STEEL)
    for s in [-1,1]:
        var side: float = float(s)
        _box(inside,"MarcaSeguridadInterior_%s" % s,
            Vector3(side*2.65,0.178,0),Vector3(0.085,0.018,5.48),YELLOW)
        _box(inside,"RevestimientoInteriorLateral_%s" % s,
            Vector3(side*3.37,1.36,0),Vector3(0.09,2.44,5.80),WALL)
        _box(inside,"CanalElectricidadInterior_%s" % s,
            Vector3(side*3.29,2.32,-0.01),Vector3(0.12,0.19,5.84),STEEL,0.33)
        for bay in range(3):
            var z: float = -2.32+float(bay)*2.25
            _box(inside,"PilarInterior_%s_%d" % [s,bay],
                Vector3(side*3.21,1.44,z),Vector3(0.26,2.88,0.25),FRAME,0.42)
            _box(inside,"PlacaPilar_%s_%d" % [s,bay],
                Vector3(side*3.12,0.26,z),Vector3(0.35,0.19,0.40),STEEL,0.39)
    _box(inside,"ParedPosteriorInterior",
        Vector3(0,1.40,2.99),Vector3(6.87,2.72,0.08),WALL)
    _box(inside,"FranjaPosteriorFaccion",
        Vector3(0,2.32,2.91),Vector3(5.42,0.22,0.055),accent,0.28)
    # Interior station details only become visible with open gates.
    for i in range(3):
        var x: float = -2.15+float(i)*2.13
        _box(inside,"BahiaMantenimiento_%d" % i,
            Vector3(x,0.18,1.25),Vector3(1.20,0.052,2.40),STEEL,0.14)
        _box(inside,"MarcaBahia_%d" % i,
            Vector3(x,0.209,0.12),Vector3(0.78,0.016,0.08),WHITE)
        _box(inside,"IndicadorFondo_%d" % i,
            Vector3(x,1.44,2.934),Vector3(0.65,0.41,0.055),
            accent if i==1 else GRILL,0.22)
    # Deep rear service bays remain visually readable when the doors are
    # opened: real layered panels with dark recesses, faction-colored screens
    # and machined frames, not a flat neutral wall texture.
    for bay in range(3):
        var bx: float = -2.24+float(bay)*2.24
        _box(inside,"NichoRecesoMantenimiento_%d" % bay,
            Vector3(bx,1.35,2.80),Vector3(1.62,1.70,0.29),STEEL,0.31)
        _box(inside,"DintelTecnicoBahia_%d" % bay,
            Vector3(bx,2.35,2.62),Vector3(1.76,0.14,0.25),
            accent,0.34)
        for frame_side in [-1,1]:
            _box(inside,"MarcoNicho_%d_%s" % [bay,frame_side],
                Vector3(bx+float(frame_side)*0.77,1.35,2.61),
                Vector3(0.13,1.83,0.21),FRAME,0.42)
        _box(inside,"ArmarioHerramientas_%d" % bay,
            Vector3(bx,0.73,2.55),Vector3(1.12,1.07,0.42),
            GRILL,0.40)
        for row in range(3):
            _box(inside,"RejillaArmario_%d_%d" % [bay,row],
                Vector3(bx,0.44+float(row)*0.23,2.30),
                Vector3(0.93,0.055,0.035),WALL,0.25)
        _box(inside,"PantallaDatosBahia_%d" % bay,
            Vector3(bx,1.76,2.50),Vector3(0.78,0.33,0.04),
            accent if bay==1 else LIGHT,0.12)
        _box(inside,"IndicadorEstadoBahia_%d" % bay,
            Vector3(bx,2.02,2.49),Vector3(0.48,0.05,0.035),
            YELLOW,0.05)
    # Loading lift and concrete guides create perspective cues through
    # the open 5.2 m gate; they never obstruct the sliding door meshes.
    _box(inside,"MesaElevadoraCentral",
        Vector3(0,0.25,0.50),Vector3(2.40,0.23,1.45),
        FRAME,0.37)
    for rail in [-1,1]:
        _box(inside,"GuiaMesaElevadora_%s" % rail,
            Vector3(float(rail)*0.94,0.40,0.50),
            Vector3(0.12,0.12,1.24),YELLOW,0.16)
    _box(inside,"GabineteEnergiaTaller",
        Vector3(2.70,0.68,1.95),
        Vector3(0.72,1.16,0.62),GRILL,0.34)
    _box(inside,"BalizaGabineteEnergia",
        Vector3(2.70,1.20,1.61),
        Vector3(0.42,0.09,0.04),accent,0.20)
    for i in range(4):
        _box(inside,"RielGrua_%d" % i,
            Vector3(-2.82+float(i)*1.86,2.74,-0.16),
            Vector3(0.085,0.12,4.72),STEEL,0.45)
    _box(inside,"PuenteGruaHangar",
        Vector3(0,2.59,0.65),Vector3(5.35,0.15,0.16),YELLOW,0.30)
    _box(inside,"CarroGruaSuspension",
        Vector3(0,2.33,0.65),Vector3(0.48,0.33,0.42),FRAME,0.41)
    # Emissive geometry, no new OmniLights/shadow passes.
    for i in range(4):
        var lamp: MeshInstance3D = _box(inside,"LuminariaInterior_%d" % i,
            Vector3(-2.55+float(i)*1.7,2.73,-1.38),
            Vector3(0.69,0.045,0.12),LIGHT,0.03)
        lamp.material_override = Airbase._mat(LIGHT,0.03,true)

    var structure := Node3D.new()
    structure.name = "CerchasYRefuerzosHangarV2"
    layer.add_child(structure)
    for side in [-1,1]:
        var sx: float = float(side)*3.68
        _box(structure,"ZocaloReforzadoExterior_%s" % side,
            Vector3(sx,0.29,0),Vector3(0.16,0.37,6.28),FRAME,0.29)
        _box(structure,"VigaLongitudinalExterior_%s" % side,
            Vector3(sx,2.54,0),Vector3(0.15,0.15,6.36),FRAME,0.43)
        for j in range(3):
            var z: float = -2.14+float(j)*2.12
            _box(structure,"CartelaRigidezExterior_%s_%d" % [side,j],
                Vector3(sx,1.86,z),Vector3(0.11,0.08,1.14),
                STEEL,0.40,Vector3(37,0,0))
            _box(structure,"VentilacionLateral_%s_%d" % [side,j],
                Vector3(sx+float(side)*0.09,1.53,-1.92+float(j)*1.90),
                Vector3(0.05,0.45,0.94),GRILL,0.34)
    for j in range(3):
        var z: float = -2.68+float(j)*2.68
        for half in [-1,1]:
            var x: float = float(half)*1.66
            var y: float = 2.82+0.73*sin(PI*(x+3.65)/7.30)-0.22
            _box(structure,"RiostraInteriorCubierta_%d_%s" % [j,half],
                Vector3(x,y,z),Vector3(3.27,0.12,0.15),STEEL,0.42,
                Vector3(0,0,-10 if half == -1 else 10))
        _box(structure,"TiranteTransversal_%d" % j,
            Vector3(0,2.68,z),Vector3(6.57,0.085,0.085),FRAME,0.43)

    var facade := Node3D.new()
    facade.name = "GuiasDePortonesAutomatizadosV2"
    layer.add_child(facade)
    _box(facade,"CarrilSuperiorContinuo",
        Vector3(0,2.74,-3.61),Vector3(7.14,0.18,0.14),STEEL,0.46)
    _box(facade,"CarrilInferiorEmpotrado",
        Vector3(0,0.14,-3.62),Vector3(7.08,0.11,0.16),STEEL,0.43)
    for side in [-1,1]:
        var x: float = float(side)*3.37
        _box(facade,"TapaMotorPorton_%s" % side,
            Vector3(x,2.89,-3.68),Vector3(0.60,0.42,0.46),FRAME,0.42)
        _box(facade,"GuiaLateralPorton_%s" % side,
            Vector3(x,1.46,-3.64),Vector3(0.16,2.62,0.19),STEEL,0.46)
        _box(facade,"SenalPorton_%s" % side,
            Vector3(x,2.91,-3.945),Vector3(0.17,0.12,0.025),YELLOW)
    if damage_stage>=2:
        _box(structure,"PerfilLateralRasgado",
            Vector3(3.65,1.83,-1.15),Vector3(0.19,1.31,0.16),
            STEEL,0.46,Vector3(17,0,16))
    if damage_stage>=3:
        for child in facade.get_children():
            if str(child.name).begins_with("CarrilSuperior") or str(child.name).begins_with("TapaMotor"):
                (child as Node3D).visible = false
        _box(structure,"CerchaCaida",
            Vector3(0.24,0.44,-2.30),Vector3(4.58,0.17,0.21),
            FRAME,0.44,Vector3(2,0,-27))
    return true
