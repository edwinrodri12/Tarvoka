extends RefCounted
class_name TarvokaNavalBaseBerthsV3

# Additive, native Godot 4.3 geometry. The V3 finishing pass requires the V2
# water and quays and never changes naval production/capture/gameplay rules.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const DetailV2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME: String="AtraqueRampasYAstilleroV3"
const STEEL=Color("#344b56")
const DARK=Color("#253642")
const CONCRETE=Color("#aab9b9")
const METAL=Color("#8b9e9f")
const RUBBER=Color("#202e34")
const SAFETY=Color("#e6ba53")
const RUST=Color("#8e5b4b")
const DECK=Color("#697c81")

static func _box(parent: Node3D,label: String,at: Vector3,
        size: Vector3,color: Color,metal: float=0.18,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,label,at,size,color,metal,rotation)

static func _cylinder(parent: Node3D,label: String,at: Vector3,
        radius: float,length: float,color: Color,
        metal: float=0.35) -> MeshInstance3D:
    return Base._cylinder(parent,label,at,radius,length,color,metal,12)

static func _beam(parent: Node3D,label: String,from: Vector3,
        to: Vector3,radius: float,color: Color) -> void:
    Base._beam(parent,label,from,to,radius,color)

static func _berths(root: Node3D,level: int,damage: int) -> void:
    var berth:=Base._group(root,"EstacionesDeAtraqueV3")
    # Service connections on the hard-standing, facing the water. No
    # decorative objects float in the navigation channel.
    for station in range(4):
        if damage>=3 and station in [2,3]:
            continue
        var z: float=-3.75+float(station)*2.43
        _box(berth,"PosteServicioAtraque_%d" % station,
            Vector3(2.64,0.98,z),Vector3(0.30,0.83,0.31),
            STEEL,0.35)
        _box(berth,"TomaElectricaEstanca_%d" % station,
            Vector3(2.64,1.20,z-0.185),
            Vector3(0.23,0.19,0.065),SAFETY)
        _cylinder(berth,"ArgollaAmarre_%d" % station,
            Vector3(1.70,0.73,z),0.11,0.12,METAL)
        if level>=2:
            _box(berth,"ManifoldAguaCombustible_%d" % station,
                Vector3(2.97,0.76,z),Vector3(0.38,0.32,0.28),
                DARK,0.32)
            _beam(berth,"TuberiaMuelle_%d" % station,
                Vector3(2.92,0.76,z),Vector3(2.92,0.76,z+0.36),
                0.035,METAL)
        if damage>=2 and station==1:
            continue
        # Real wall-climbing ladder: rails and individual treads descend
        # towards the water, rather than being painted on a texture.
        for side in [-1,1]:
            _beam(berth,"LargueroEscala_%d_%s" % [station,side],
                Vector3(1.04,-0.02,z+float(side)*0.16),
                Vector3(1.04,0.65,z+float(side)*0.16),
                0.024,METAL)
        for rung in range(5):
            _box(berth,"PeldañoEscala_%d_%d" % [station,rung],
                Vector3(1.018,0.05+float(rung)*0.13,z),
                Vector3(0.07,0.035,0.32),METAL,0.39)
    for pier in [-1,1]:
        if damage>=3 and pier==1:
            continue
        var z: float=float(pier)*4.85
        # Outer quay safety rails leave gaps at the actual mooring bollards.
        for segment in range(3):
            var x: float=-4.52+float(segment)*2.13
            for xend in [-0.88,0.88]:
                _box(berth,"PieBarandal_%s_%d_%s" % [pier,segment,xend],
                    Vector3(x+xend,0.92,z+float(pier)*0.66),
                    Vector3(0.07,0.60,0.07),STEEL,0.35)
            _beam(berth,"BarandalExterior_%s_%d" % [pier,segment],
                Vector3(x-0.88,1.23,z+float(pier)*0.66),
                Vector3(x+0.88,1.23,z+float(pier)*0.66),
                0.035,METAL)

static func _gangway(root: Node3D,damage: int) -> void:
    var gang:=Base._group(root,"PasarelaEmbarqueAbatibleV3")
    if damage>=3:
        _box(gang,"AnclajePasarelaArrancada",
            Vector3(2.60,0.67,1.36),Vector3(0.51,0.29,1.25),
            RUST,0.17,Vector3(0,0,17))
        return
    # x=2.65 is the landside hinge; x=0.30 is the lower ship berth.
    # A real inclined assembly, not an unbroken pier drawn over the water.
    var tilt: float=10.0 if damage<=1 else 27.0
    _box(gang,"TableroAntideslizantePasarela",
        Vector3(1.46,0.66,1.36),Vector3(2.42,0.13,1.18),
        DECK if damage<=1 else RUST,0.37,Vector3(0,0,tilt))
    _cylinder(gang,"BisagraPrincipalPasarela",
        Vector3(2.67,0.86,1.36),0.17,1.25,STEEL)
    for side in [-1,1]:
        var z: float=1.36+float(side)*0.51
        _beam(gang,"VigaInferiorRampa_%s" % side,
            Vector3(0.28,0.35,z),Vector3(2.62,0.78,z),
            0.055,STEEL)
        if damage<=1:
            for t in [0,1,2]:
                var x: float=0.42+float(t)*1.05
                var y: float=0.43+float(t)*0.20
                _beam(gang,"MontanteRampa_%s_%d" % [side,t],
                    Vector3(x,y,z),Vector3(x,y+0.48,z),0.027,METAL)
            _beam(gang,"PasamanosRampa_%s" % side,
                Vector3(0.42,0.91,z),Vector3(2.52,1.32,z),
                0.033,SAFETY)
    for tread in range(7):
        if damage==2 and tread in [3,4]:
            continue
        var x: float=0.39+float(tread)*0.35
        _box(gang,"RejillaAntideslizante_%d" % tread,
            Vector3(x,0.47+float(tread)*0.067,1.36),
            Vector3(0.09,0.028,1.06),METAL,0.41,
            Vector3(0,0,tilt))
    if damage==2:
        _box(gang,"CilindroHidraulicoRoto",
            Vector3(2.15,0.61,1.36),
            Vector3(0.09,0.12,0.95),RUST,0.33,Vector3(0,0,-29))
    else:
        for side in [-1,1]:
            var z: float=1.36+float(side)*0.38
            _beam(gang,"PistonHidraulico_%s" % side,
                Vector3(2.43,0.69,z),Vector3(1.48,0.43,z),
                0.06,METAL)
    gang.set_meta("naval_v3_real_inclined_gangway",true)

static func _launch_ramp(root: Node3D,damage: int) -> void:
    var slip:=Base._group(root,"RampaVaradaEmbarcacionesV3")
    if damage==4:
        _box(slip,"EscombrosRampaDeVarada",
            Vector3(-3.10,0.28,-4.12),
            Vector3(1.60,0.20,0.85),RUST,0.16,Vector3(18,9,4))
        return
    # Fixed marine launch rails extend from the south pier into water.
    # The ramp starts where the jetty ends (z=-4.25), slopes down to
    # z=-2.2 and does not cover an intact roof or replace seawall slabs.
    var intact: bool=damage<=2
    _box(slip,"LosetaRampaVarada" if intact else "LosetaRampaPartida",
        Vector3(-3.17,0.38,-3.30 if intact else -3.86),
        Vector3(1.62,0.15,2.26 if intact else 1.02),
        DECK if intact else RUST,0.22,
        Vector3(14,0,0) if intact else Vector3(20,0,8))
    if not intact:
        _beam(slip,"RielVaradaCaido",
            Vector3(-3.78,0.52,-4.14),Vector3(-3.32,0.08,-2.95),
            0.07,RUST)
        return
    for side in [-1,1]:
        var x: float=-3.17+float(side)*0.58
        _beam(slip,"RielBotadura_%s" % side,
            Vector3(x,0.70,-4.42),Vector3(x,0.10,-2.21),
            0.065,METAL)
        for index in range(4):
            var z: float=-4.16+float(index)*0.56
            _cylinder(slip,"RodilloVarada_%s_%d" % [side,index],
                Vector3(x,0.58-float(index)*0.13,z),
                0.105,0.27,STEEL)
    for index in range(7):
        var z: float=-4.13+float(index)*0.30
        _box(slip,"RanuraEscurrimiento_%02d" % index,
            Vector3(-3.17,0.55-float(index)*0.070,z),
            Vector3(1.39,0.018,0.045),DARK,0.26,
            Vector3(14,0,0))
    _box(slip,"CabrestanteDeVarada",
        Vector3(-3.17,1.00,-4.88),
        Vector3(0.62,0.53,0.40),STEEL,0.42)
    _cylinder(slip,"TamborCabrestanteDeVarada",
        Vector3(-3.17,1.29,-4.88),0.22,0.55,METAL)
    slip.set_meta("naval_v3_launch_rails",true)

static func _shipyard(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var ship:=Base._group(root,"EquipamientoAstilleroV3")
    if damage==4:
        _box(ship,"BancadaAstilleroDestruida",
            Vector3(3.30,0.62,-0.30),
            Vector3(1.84,0.24,1.25),RUST,0.13,Vector3(0,15,17))
        return
    # External dockside repair/work station, not a second fantasy building.
    _box(ship,"BancadaReparacionNaval",
        Vector3(3.46,0.65,0.20),
        Vector3(1.94,0.15,1.48),STEEL,0.34)
    for side in [-1,1]:
        var z: float=0.20+float(side)*0.55
        _box(ship,"CunaSoporteCasco_%s" % side,
            Vector3(3.46,0.89,z),
            Vector3(1.75,0.36,0.18),
            RUST if damage>=2 else CONCRETE)
        _box(ship,"CarrilVagonTransferencia_%s" % side,
            Vector3(3.46,0.58,z),
            Vector3(2.23,0.07,0.07),METAL,0.42)
    for i in range(3):
        var x: float=2.77+float(i)*0.69
        _box(ship,"TacoCalzadoCasco_%d" % i,
            Vector3(x,1.03,0.20),Vector3(0.17,0.18,0.73),
            DARK,0.25)
    _box(ship,"ArmarioHerramientasAstillero",
        Vector3(4.94,0.88,0.27),Vector3(0.63,0.83,0.51),
        STEEL if damage<3 else RUST,0.23)
    for i in range(4):
        _box(ship,"CajonEquipo_%d" % i,
            Vector3(4.94,0.65+float(i)*0.16,-0.02),
            Vector3(0.49,0.10,0.027),METAL,0.28)
    if level>=2 and damage<=2:
        # Hoses and reel form the visible maintenance service connection.
        _cylinder(ship,"CarreteMangueraNaval",
            Vector3(3.09,1.29,-0.82),0.36,0.34,DARK)
        _beam(ship,"MangueraServiciosNavales",
            Vector3(3.08,1.12,-0.82),Vector3(3.48,0.69,-0.28),
            0.046,RUBBER)
    if level==3 and damage<=1:
        # Advanced-only overhead transfer-frame and hoist.
        for x in [2.49,4.45]:
            for z in [-0.77,1.06]:
                _box(ship,"PilarPuenteGrua_%s_%s" % [x,z],
                    Vector3(x,1.90,z),Vector3(0.14,2.46,0.14),
                    STEEL,0.36)
        for z in [-0.77,1.06]:
            _beam(ship,"CarrilPuenteGrua_%s" % z,
                Vector3(2.49,3.18,z),Vector3(4.45,3.18,z),
                0.055,METAL)
        _box(ship,"TraviesaPuenteGruaAstillero",
            Vector3(3.49,3.21,0.14),Vector3(0.27,0.22,1.94),
            STEEL,0.42)
        _beam(ship,"CablePolipastoAstillero",
            Vector3(3.49,3.03,0.14),Vector3(3.49,1.60,0.14),
            0.025,DARK)
        _box(ship,"BloqueGanchoAstillero",
            Vector3(3.49,1.54,0.14),
            Vector3(0.22,0.27,0.21),SAFETY,0.34)
        _box(ship,"IdentificacionFaccionAstillero",
            Vector3(4.94,1.33,-0.03),Vector3(0.53,0.08,0.04),
            accent,0.20)
    ship.set_meta("naval_v3_shipyard_station",true)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(DetailV2.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    _berths(stage,level,damage)
    _gangway(stage,damage)
    _launch_ramp(stage,damage)
    _shipyard(stage,level,damage,Style.faction_color(faction))
    stage.set_meta("naval_v3_details_applied",true)
    stage.set_meta("naval_v3_damage",damage)
    stage.set_meta("naval_v3_level",level)
    return true
