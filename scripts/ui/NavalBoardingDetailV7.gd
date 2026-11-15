extends RefCounted
class_name TarvokaNavalBoardingDetailV7

# Original additive Godot 4.3 geometry: close/long-range landing details,
# authentic land-to-gangway/launchway joins and restrained night markers.
# All geometry is child of a V7 stage. V1-V6 remain unchanged.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const STAGE_NAME: String="UnionesEmbarqueYRampasNavalesV7"
const STEEL=Color("#435861")
const CONCRETE=Color("#849499")
const DARK=Color("#253741")
const STEEL_EDGE=Color("#8eaaa9")
const YELLOW=Color("#e0be65")
const RUST=Color("#956b56")
const RUBBER=Color("#202d35")
const SIGN=Color("#d4e5dd")
static var _night_material: StandardMaterial3D

static func _box(parent: Node3D,name: String,p: Vector3,
        size: Vector3,color: Color,metal: float=0.2,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,name,p,size,color,metal,rot)

static func _cylinder(parent: Node3D,name: String,p: Vector3,
        radius: float,length: float,color: Color) -> MeshInstance3D:
    return Base._cylinder(parent,name,p,radius,length,color,0.40,12)

static func _beam(parent: Node3D,name: String,
        start: Vector3,finish: Vector3,r: float,color: Color) -> void:
    Base._beam(parent,name,start,finish,r,color)

static func _glow_material() -> StandardMaterial3D:
    if _night_material==null:
        _night_material=StandardMaterial3D.new()
        _night_material.albedo_color=SIGN
        _night_material.roughness=0.63
        _night_material.emission_enabled=true
        _night_material.emission=SIGN
        _night_material.emission_energy_multiplier=0.33
    return _night_material

static func _boardwalk(stage: Node3D,damage: int) -> void:
    var near: Node3D=stage.get_node("MecanicaCercanaV7")
    var far: Node3D=stage.get_node("SiluetaLejanaV7")
    var night: Node3D=stage.get_node("ReflectantesNocturnosV7")
    # The genuine V3 ramp lands on the east apron at x=2.67, z=1.36.
    # Critical damage has an anchor torn out: NEVER create intact plates.
    if damage==4:
        _box(near,"TornilloPasarelaEntreEscombros",
            Vector3(2.53,0.70,1.20),Vector3(0.20,0.06,0.14),
            RUST,0.2,Vector3(0,0,23))
        return
    if damage==3:
        _box(near,"PernoBisagraRotaEmbarqueV7",
            Vector3(2.65,0.78,1.36),
            Vector3(0.35,0.12,0.60),RUST,0.23,
            Vector3(0,0,16))
        _box(far,"RematePasarelaRotaEnLitoralV7",
            Vector3(2.61,0.80,1.36),
            Vector3(0.34,0.20,0.72),RUST,0.21,
            Vector3(0,0,17))
        return
    _box(near,"ZapataAnclajePasarelaV7",
        Vector3(2.62,0.705,1.36),
        Vector3(0.57,0.13,1.32),CONCRETE,0.17)
    for side in [-1,1]:
        var z: float=1.36+float(side)*0.47
        _box(near,"PlacaBisagraPasarela_%s" % side,
            Vector3(2.57,0.84,z),
            Vector3(0.35,0.19,0.14),STEEL,0.41)
        _cylinder(near,"PernoBisagraPasarela_%s" % side,
            Vector3(2.67,0.87,z),0.09,0.19,STEEL_EDGE)
        # Real shear plates on landward and vessel ends.
        _box(near,"PlacaRepartoCarga_%s" % side,
            Vector3(2.77,0.76,z),
            Vector3(0.34,0.09,0.26),DARK,0.35)
        if damage<=1:
            _beam(near,"ConectorHidraulicoPasarela_%s" % side,
                Vector3(2.35,0.70,z),Vector3(1.85,0.54,z),
                0.038,STEEL_EDGE)
        else:
            _box(near,"ConexionHidraulicaDoblada_%s" % side,
                Vector3(2.25,0.63,z),
                Vector3(0.38,0.09,0.08),RUST,0.16,
                Vector3(0,0,16))
    # Marine end face; dark rubber prevents the tread from floating.
    _box(near,"ZapatoFlotanteEmbarqueV7",
        Vector3(0.33,0.42,1.36),
        Vector3(0.27,0.16,1.05),RUBBER,0.04,
        Vector3(0,0,10 if damage<=1 else 27))
    for i in range(5):
        if damage==2 and i in [2,3]:
            continue
        _box(near,"CabezaTornilloAntideslizante_%02d" % i,
            Vector3(0.69+float(i)*0.35,
                0.53+float(i)*0.062,1.36),
            Vector3(0.050,0.022,0.72),STEEL_EDGE,0.37,
            Vector3(0,0,10 if damage<=1 else 27))
    # Simplified single steel profile for tactical camera:
    # no minuscule floating plates at zoom-out.
    _box(far,"PerfilPasarelaLejanaV7",
        Vector3(1.43,0.76,1.36),
        Vector3(2.37,0.19,1.05),
        DARK if damage==2 else STEEL,0.28,
        Vector3(0,0,27 if damage==2 else 10))
    if damage<=1:
        _box(far,"GuiaPasarelaFaccionLejanaV7",
            Vector3(1.42,0.873,1.36),
            Vector3(1.78,0.025,0.08),YELLOW,0.24,
            Vector3(0,0,10))
    else:
        _box(far,"PasarelaDeformadaLejanaV7",
            Vector3(1.46,0.88,1.36),
            Vector3(0.96,0.04,0.11),RUST,0.10,
            Vector3(0,0,27))
    if damage<=1:
        for side in [-1,1]:
            var z: float=1.36+float(side)*0.48
            var marker:=_box(night,"MarcaReflexivaPasarela_%s" % side,
                Vector3(2.40,0.99,z),
                Vector3(0.17,0.09,0.036),SIGN,0.08)
            marker.material_override=_glow_material()

static func _slipway(stage: Node3D,damage: int) -> void:
    var near: Node3D=stage.get_node("MecanicaCercanaV7")
    var far: Node3D=stage.get_node("SiluetaLejanaV7")
    # The V3 slipway lies at x=-3.17 and runs z=-4.42 to -2.21.
    # This precision pass creates endplates and real track anchors only
    # while the slipway survives, without replacing fractured material.
    if damage>=4:
        _box(far,"MasaEscombrosBotaduraV7",
            Vector3(-3.18,0.40,-4.14),
            Vector3(0.87,0.18,0.64),RUST,0.10,
            Vector3(8,5,14))
        return
    if damage==3:
        _box(near,"PlacaRielPartidoBotaduraV7",
            Vector3(-3.52,0.42,-4.04),
            Vector3(0.22,0.12,0.56),RUST,0.20,
            Vector3(18,12,8))
        _box(far,"InicioRampaPartidaLejanaV7",
            Vector3(-3.18,0.43,-3.86),
            Vector3(1.25,0.14,0.87),RUST,0.20,
            Vector3(20,0,8))
        return
    for side in [-1,1]:
        var x: float=-3.17+float(side)*0.58
        _box(near,"BaseTornilleriaRiel_%s" % side,
            Vector3(x,0.64,-4.42),
            Vector3(0.27,0.08,0.32),STEEL,0.43,
            Vector3(14,0,0))
        for i in range(4):
            var z: float=-4.17+float(i)*0.57
            var y: float=0.60-float(i)*0.13
            _box(near,"GrapaRielBotadura_%s_%02d" % [side,i],
                Vector3(x,y,z),
                Vector3(0.20,0.06,0.08),
                STEEL_EDGE if damage<=1 else RUST,0.35,
                Vector3(14,0,0))
        # A tapered dark rubbing rail along the two surviving tracks.
        _beam(near,"BandaPatinRampa_%s" % side,
            Vector3(x,0.64,-4.35),
            Vector3(x,0.09,-2.25),0.033,RUBBER)
    # Hoist remains on landward end only if ramp is structurally present.
    _box(near,"BancadaCabrestanteBotaduraV7",
        Vector3(-3.17,0.69,-4.91),
        Vector3(0.82,0.11,0.61),DARK,0.35)
    _box(far,"RielesRampaLejanosV7",
        Vector3(-3.17,0.42,-3.31),
        Vector3(1.42,0.15,2.10),
        STEEL if damage<=1 else RUST,0.32,
        Vector3(14,0,0))

static func _seawall_ladders(stage: Node3D,damage: int) -> void:
    var near: Node3D=stage.get_node("MecanicaCercanaV7")
    var night: Node3D=stage.get_node("ReflectantesNocturnosV7")
    if damage==4:
        return
    for station in range(4):
        if damage>=3 and station in [2,3]:
            continue
        if damage>=2 and station==1:
            continue
        var z: float=-3.75+float(station)*2.43
        # Actual fixed 3D V3 ladder at x=1.04: handhold is anchored
        # on the coping at y=0.7, not suspended in front of the seawall.
        for side in [-1,1]:
            var zz: float=z+float(side)*0.16
            _beam(near,"BarraSalidaEscala_%d_%s" % [station,side],
                Vector3(1.045,0.54,zz),
                Vector3(1.30,0.86,zz),0.027,STEEL_EDGE)
            _box(near,"PletinaAnclajeEscala_%d_%s" % [station,side],
                Vector3(1.28,0.69,zz),
                Vector3(0.21,0.06,0.08),STEEL,0.32)
        if damage<=1:
            var marker:=_box(night,"FaroEscalaMuelles_%d" % station,
                Vector3(1.36,0.77,z),
                Vector3(0.15,0.02,0.11),SIGN,0.10)
            marker.material_override=_glow_material()

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var root: Node3D=model.get_node(STAGE_NAME)
    (root.get_node("MecanicaCercanaV7") as Node3D).visible=near_view
    (root.get_node("SiluetaLejanaV7") as Node3D).visible=not near_view
    root.set_meta("naval_v7_close_mode",near_view)
    return true

static func set_night(model: Node3D,enabled: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var root: Node3D=model.get_node(STAGE_NAME)
    (root.get_node("ReflectantesNocturnosV7") as Node3D).visible=enabled
    root.set_meta("naval_v7_night",enabled)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    for stage in [V2.STAGE_NAME,V3.STAGE_NAME,V4.STAGE_NAME,
            V5.STAGE_NAME,V6.STAGE_NAME]:
        if not model.has_node(stage):
            return false
    if model.has_node(STAGE_NAME):
        return false
    var root:=Base._group(model,STAGE_NAME)
    Base._group(root,"MecanicaCercanaV7")
    Base._group(root,"SiluetaLejanaV7")
    Base._group(root,"ReflectantesNocturnosV7")
    _boardwalk(root,damage)
    _slipway(root,damage)
    _seawall_ladders(root,damage)
    root.set_meta("naval_v7_level",level)
    root.set_meta("naval_v7_faction",faction)
    root.set_meta("naval_v7_damage",damage)
    root.set_meta("naval_v7_no_intact_on_destroyed",true)
    set_detail(model,true)
    set_night(model,false)
    return true
