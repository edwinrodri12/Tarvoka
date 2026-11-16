extends RefCounted
class_name TarvokaNavalNightReadabilityV6

# Visual-only native Godot 4.3 finishing. Three controllable concerns:
# readable sea/yard silhouettes, believable restrained night accents,
# and reversible near/far geometric detail for the 3D Studio.
# Does not change game rules, collisions, production or turn logic.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME: String="LecturaNocturnaAstilleroYLODNavalV6"
const STEEL=Color("#334851")
const TRIM=Color("#9db1b3")
const WEATHER=Color("#7e8887")
const LAMP=Color("#ffdc9d")
const SIGNAL=Color("#d6e5dc")
const SAFETY=Color("#e7bf63")
static var _glow_cache: Dictionary={}

static func _box(parent: Node3D,name: String,
        at: Vector3,size: Vector3,color: Color,
        metallic: float=0.20,rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,name,at,size,color,metallic,rotation)

static func _beam(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> void:
    Base._beam(parent,name,a,b,radius,color)

static func _emissive(color: Color,energy: float) -> StandardMaterial3D:
    var key: String="%s/%0.2f" % [color.to_html(),energy]
    if _glow_cache.has(key):
        return _glow_cache[key] as StandardMaterial3D
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.55
    m.metallic=0.09
    m.emission_enabled=true
    m.emission=color
    m.emission_energy_multiplier=energy
    _glow_cache[key]=m
    return m

static func _berth_readability(stage: Node3D,
        damage: int,accent: Color) -> void:
    var close:=Base._group(stage,"DetallesCercanosNavalesV6")
    var far:=Base._group(stage,"SiluetasDeLecturaTacticaV6")
    # Avoid the demolished +1 pier, and avoid putting intact placards
    # on either pier once the entire base is destroyed.
    if damage<4:
        for side in [-1,1]:
            if damage>=3 and side==1:
                continue
            var z: float=float(side)*4.85
            # Fine stepped slip-resistant edging: near camera only.
            for i in range(6):
                var x: float=-5.05+float(i)*1.08
                _box(close,"EstriaPavimentoMuelle_%s_%02d" % [side,i],
                    Vector3(x,0.663,z-float(side)*0.26),
                    Vector3(0.37,0.012,0.035),WEATHER,0.08)
            # At tactical distance, a single high-contrast head marker
            # replaces the micro-stripes but never hides the jetty itself.
            _box(far,"CabeceraLegibleMuelle_%s" % side,
                Vector3(-5.39,0.70,z),
                Vector3(0.76,0.115,0.76),STEEL,0.28)
            _box(far,"BandaCabeceraFaccion_%s" % side,
                Vector3(-5.39,0.762,z),
                Vector3(0.64,0.021,0.64),accent,0.24)
    # Main apron edge remains readable with a single strip at far zoom.
    if damage<=3:
        for i in range(5):
            var z: float=-3.70+float(i)*1.82
            _box(close,"JuntaAntideslizantePatio_%02d" % i,
                Vector3(2.11,0.636,z),
                Vector3(0.21,0.011,0.42),TRIM,0.10)
        _box(far,"FranjaOrientacionPuerto",
            Vector3(2.10,0.654,0),
            Vector3(0.21,0.024,8.55),SAFETY,0.17)

static func _yard_structure(stage: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var detail: Node3D=stage.get_node("DetallesCercanosNavalesV6")
    var far: Node3D=stage.get_node("SiluetasDeLecturaTacticaV6")
    if damage==4:
        _box(far,"MasaAstilleroColapsada",
            Vector3(3.52,0.82,0.14),
            Vector3(1.55,0.18,0.37),WEATHER,0.15,
            Vector3(0,8,11))
        return
    # Structural components are aligned to the actual V3 yard bed:
    # x=[2.49,4.45], z=[-0.77,1.06]; V5 legs remain untouched.
    for side in [-1,1]:
        var z: float=0.20+float(side)*0.54
        if damage<=2:
            _beam(detail,"DiagonalNervaduraBancada_%s" % side,
                Vector3(2.64,0.74,z),Vector3(3.25,0.43,z),
                0.025,TRIM)
            _box(detail,"JuntaSoldaduraBancada_%s" % side,
                Vector3(4.22,0.82,z),
                Vector3(0.11,0.035,0.11),SAFETY,0.26)
    # A silhouette band with real faction material survives zoom-out:
    # no exaggerated new building and no duplicated intact roofs.
    if damage<=2:
        _box(far,"PerfilLejanoAstillero",
            Vector3(3.46,0.77,0.20),
            Vector3(1.94,0.16,1.36),STEEL,0.30)
        _box(far,"BandaFaccionLejanaAstillero",
            Vector3(3.46,0.863,0.20),
            Vector3(1.77,0.025,1.12),accent,0.27)
    else:
        _box(far,"PerfilLejanoAstilleroDañado",
            Vector3(3.46,0.71,0.16),
            Vector3(1.35,0.13,0.78),WEATHER,0.14,
            Vector3(0,8,10))
    if level==3 and damage<=1:
        for side in [-1,1]:
            var z: float=0.14+float(side)*0.81
            _beam(detail,"CartelaMicroPuenteGrua_%s" % side,
                Vector3(4.45,2.77,z),Vector3(3.94,3.15,z),
                0.027,TRIM)
        _box(far,"TravesañoLegiblePuenteGrua",
            Vector3(3.49,3.29,0.14),
            Vector3(0.35,0.12,1.72),accent,0.32)

static func _night_marks(stage: Node3D,
        damage: int) -> void:
    var marks:=Base._group(stage,"IndicadoresNocturnosV6")
    if damage>=4:
        return
    # Low-power reflective labels, not high-intensity strobing.
    for i in range(2):
        if damage>=3 and i==1:
            continue
        var z: float=-3.92+float(i)*7.88
        var plate:=_box(marks,"ReflectorMuelles_%d" % i,
            Vector3(1.53,0.76,z),
            Vector3(0.16,0.095,0.40),SIGNAL,0.14)
        plate.material_override=_emissive(SIGNAL,0.34)
    if damage<=2:
        # Small command tower guide light only when the cabin exists.
        var top:=_box(marks,"IndicadorTorreMarinaV6",
            Vector3(5.54,4.63,3.37),
            Vector3(0.18,0.09,0.18),LAMP,0.11)
        top.material_override=_emissive(LAMP,0.39)
        if damage<=1:
            var guide:=OmniLight3D.new()
            guide.name="LuzGuiaTorreReguladaV6"
            guide.position=Vector3(5.54,4.46,3.37)
            guide.light_color=LAMP
            guide.light_energy=0.22
            guide.omni_range=2.55
            guide.shadow_enabled=false
            marks.add_child(guide)
    marks.set_meta("naval_v6_low_emission_night",true)

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var stage: Node3D=model.get_node(STAGE_NAME)
    (stage.get_node("DetallesCercanosNavalesV6") as Node3D).visible=near_view
    (stage.get_node("SiluetasDeLecturaTacticaV6") as Node3D).visible=not near_view
    stage.set_meta("naval_v6_near_view",near_view)
    return true

static func set_night(model: Node3D,enabled: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var stage: Node3D=model.get_node(STAGE_NAME)
    (stage.get_node("IndicadoresNocturnosV6") as Node3D).visible=enabled
    # Existing V5 lights and emissive lens are view-driven now; don't
    # add new shadow maps, and don't light a demolished tower or dock.
    var v5: Node3D=model.get_node_or_null(V5.STAGE_NAME)
    if v5!=null:
        var spots: Node3D=v5.get_node_or_null("IluminacionDeServicioReguladaV5")
        if spots!=null:
            for item in spots.get_children():
                if item is SpotLight3D:
                    (item as SpotLight3D).visible=enabled
    stage.set_meta("naval_v6_night_enabled",enabled)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V2.STAGE_NAME) or not model.has_node(V3.STAGE_NAME):
        return false
    if not model.has_node(V4.STAGE_NAME) or not model.has_node(V5.STAGE_NAME):
        return false
    if model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    _berth_readability(stage,damage,Style.faction_color(faction))
    _yard_structure(stage,level,damage,Style.faction_color(faction))
    _night_marks(stage,damage)
    stage.set_meta("naval_v6_level",level)
    stage.set_meta("naval_v6_faction",faction)
    stage.set_meta("naval_v6_damage",damage)
    stage.set_meta("naval_v6_distinct_silhouette",true)
    set_detail(model,true)
    set_night(model,false)
    return true
