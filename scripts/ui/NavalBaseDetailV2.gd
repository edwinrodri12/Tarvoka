extends RefCounted
class_name TarvokaNavalBaseDetailV2

# Additive architecture for Naval Base V1: physically layered pier edges,
# service gangways, roof drainage, marine crane lattice and animated water.
# 3D art ONLY; no new health, unit production, collision or gameplay rules.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const WATER_SHADER=preload("res://assets/shaders/naval_port_water_v2.gdshader")
const STAGE_NAME: String="AcabadosNauticosRealesV2"
const EDGE=Color("#c7d1cf")
const CAP=Color("#a5b4b7")
const DARK=Color("#304854")
const IRON=Color("#253642")
const RUST=Color("#7a6357")
const SAFETY=Color("#e7b953")
const MARINE=Color("#5e8190")

static func _box(parent: Node3D,label: String,
        at: Vector3,size: Vector3,color: Color,metal: float=0.1,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,label,at,size,color,metal,rotation)

static func _cylinder(parent: Node3D,label: String,at: Vector3,
        radius: float,length: float,color: Color,metal: float=0.25,
        sides: int=12,rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._cylinder(parent,label,at,radius,length,color,metal,sides,rotation)

static func _beam(parent: Node3D,label: String,
        start: Vector3,finish: Vector3,radius: float,
        color: Color,metal: float=0.27) -> void:
    Base._beam(parent,label,start,finish,radius,color,metal)

static func _water(root: Node3D) -> void:
    var node:=Base._group(root,"AguaPortuariaConOlasV2")
    var plane:=PlaneMesh.new()
    plane.size=Vector2(8.42,10.52)
    plane.subdivide_width=3
    plane.subdivide_depth=3
    var material:=ShaderMaterial.new()
    material.shader=WATER_SHADER
    var water:=MeshInstance3D.new()
    water.name="SuperficieAguaShaderMaritimoV2"
    water.mesh=plane
    water.material_override=material
    water.position=Vector3(-2.86,0.046,0.0)
    water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.add_child(water)
    # Reflection limits are deliberate: this is a tactical-readable surface,
    # not expensive true planar reflection or tessellated fluid simulation.
    node.set_meta("naval_v2_water_shader",true)

static func _quay_edges(root: Node3D,level: int,
        damage: int) -> void:
    var group:=Base._group(root,"MuellesHormigonEsculpidosV2")
    # Two-layer coping stones and realistic dark vertical seawall edges,
    # respecting the actually missing eastern pier in critical damage.
    _box(group,"CoronacionMuelleEste",
        Vector3(1.75,0.592,0.0),Vector3(0.95,0.071,10.65),EDGE)
    _box(group,"ZocaloMuelleEste",
        Vector3(1.20,0.065,0),Vector3(0.15,0.57,10.60),DARK)
    for side in [-1,1]:
        if side==1 and damage>=3:
            _box(group,"RemateMuelleRotoV2",
                Vector3(-0.38,0.535,4.85),
                Vector3(3.89,0.085,1.10),RUST)
            continue
        var z: float=float(side)*4.85
        _box(group,"CoronacionEspigon_%s" % side,
            Vector3(-2.04,0.594,z),Vector3(7.56,0.075,1.16),CAP)
        _box(group,"BandaDefensaExterna_%s" % side,
            Vector3(-2.04,0.10,z+float(side)*0.60),
            Vector3(7.30,0.45,0.10),DARK,0.30)
        for i in range(6):
            var x: float=-5.40+float(i)*1.36
            _box(group,"UnionLosasEspigon_%s_%d" % [side,i],
                Vector3(x,0.636,z),Vector3(0.025,0.010,1.09),
                Color("#667d82"))
            if i%2==0:
                _box(group,"DefensaModularEspigon_%s_%d" % [side,i],
                    Vector3(x,0.24,z-float(side)*0.62),
                    Vector3(0.28,0.47,0.16),DARK,0.23)
                _box(group,"ReflectorSeguridadEspigon_%s_%d" % [side,i],
                    Vector3(x,0.647,z),
                    Vector3(0.22,0.019,0.095),SAFETY,0.17)
    for i in range(7):
        if damage>=3 and i in [2,3]:
            continue
        var z: float=-4.12+float(i)*1.35
        _box(group,"GomaVerticalMuelle_%02d" % i,
            Vector3(1.155,0.24,z),
            Vector3(0.18,0.53,0.27),DARK,0.05)
        _box(group,"ChapaAceroDefensa_%02d" % i,
            Vector3(1.055,0.15,z),
            Vector3(0.05,0.23,0.24),Color("#89999b"),0.4)
        _box(group,"JuntaPavimentoMuelle_%02d" % i,
            Vector3(1.75,0.633,z+0.24),
            Vector3(0.86,0.012,0.028),Color("#5c7379"))
    # Hull-friendly mooring cleats and anti-slip safety grid:
    for i in range(4):
        var z: float=-3.82+float(i)*2.35
        _box(group,"PuntoAmarre_%02d" % i,
            Vector3(1.68,0.71,z),Vector3(0.33,0.14,0.17),DARK,0.4)
        _box(group,"BandaAntideslizante_%02d" % i,
            Vector3(2.25,0.594,z),
            Vector3(0.14,0.010,0.78),Color("#d0bc77"),0.12)
    if level>=2:
        # Dockside fuel/power manifold, with pipes and deck-connected poles.
        for i in range(3):
            var z: float=-3.45+float(i)*3.26
            _box(group,"CajaSuministroMuelle_%d" % i,
                Vector3(2.63,0.84,z),
                Vector3(0.59,0.50,0.39),DARK,0.32)
            _box(group,"FrenteCajaSuministro_%d" % i,
                Vector3(2.63,0.90,z-0.215),
                Vector3(0.44,0.18,0.028),SAFETY)
            _cylinder(group,"BolardoSuministro_%d" % i,
                Vector3(2.06,0.83,z),0.075,0.42,CAP,0.22)

static func _hangar_finish(root: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=4:
        return
    var group:=Base._group(root,"AstilleroTerminacionesV2",
        Vector3(4.56,0,-2.05))
    for side in [-1,1]:
        var x: float=float(side)*1.78
        _box(group,"ZocaloLateralesAstillero_%s" % side,
            Vector3(x,0.69,0),Vector3(0.22,0.35,4.62),DARK)
        _box(group,"VigaFachadaAlero_%s" % side,
            Vector3(x,3.20,0),Vector3(0.18,0.14,4.70),EDGE,0.29)
        for rib in range(5):
            var z: float=-1.94+float(rib)*0.96
            _box(group,"PilastraExterior_%s_%d" % [side,rib],
                Vector3(x+float(side)*0.15,1.93,z),
                Vector3(0.12,2.56,0.13),CAP,0.31)
            if rib in [1,3]:
                _box(group,"VentilacionLateral_%s_%d" % [side,rib],
                    Vector3(x+float(side)*0.16,2.15,z+0.16),
                    Vector3(0.09,0.37,0.46),IRON,0.20)
    _box(group,"VigaSoporteFrontal",
        Vector3(0,3.36,-2.27),Vector3(3.70,0.15,0.16),CAP,0.38)
    _box(group,"CanalDrenajeTrasero",
        Vector3(0,3.13,2.28),Vector3(3.75,0.16,0.16),DARK,0.34)
    # Roof battening follows only strips that really survive that damage.
    for strip in range(10):
        if damage==2 and strip in [4,5]:
            continue
        if damage==3 and strip in [1,2,3,4,5,6]:
            continue
        var z: float=-2.10+float(strip)*0.466
        for side in [-1,1]:
            var x: float=float(side)*0.91
            _box(group,"NervioRealDeTecho_%d_%s" % [strip,side],
                Vector3(x,3.347,z+0.18),
                Vector3(1.91,0.04,0.040),CAP,0.39,
                Vector3(0,0,float(side)*-12))
    if damage<=1:
        for i in range(3):
            var x: float=-1.22+float(i)*1.22
            for t in range(2):
                _box(group,"RefuerzoComPuerta_%d_%d" % [i,t],
                    Vector3(x,0.88+float(t)*1.09,-2.445),
                    Vector3(1.10,0.07,0.075),CAP,0.33)
            _box(group,"VisorDePuerta_%d" % i,
                Vector3(x,2.31,-2.453),
                Vector3(0.72,0.26,0.05),Color("#4b8496"),0.28)
        for index in range(2):
            var pos_x: float=-1.12+float(index)*2.24
            _box(group,"LamparaServicioExterior_%d" % index,
                Vector3(pos_x,3.02,-2.50),
                Vector3(0.21,0.10,0.17),Color("#f2d796"),0.1)
    if level>=2 and damage<=2:
        _box(group,"CubiertaDeServicioAntideslizante",
            Vector3(0,0.625,-0.92),Vector3(3.22,0.018,1.16),
            Color("#647a7f"),0.22)
        for i in range(3):
            _box(group,"DrenajeDePiso_%d" % i,
                Vector3(-1.17+float(i)*1.17,0.643,-1.04),
                Vector3(0.46,0.016,0.045),IRON,0.28)
    group.set_meta("naval_v2_roof_respects_damage",true)

static func _crane_finish(root: Node3D,damage: int) -> void:
    if damage>=4:
        return
    var rig:=Base._group(root,"GruaCelosiaYPolipastoV2",
        Vector3(1.90,0,-2.50))
    if damage>=2:
        # No magically intact boom in stage 2/3.
        for i in range(3):
            var factor: float=float(i)*0.55
            _beam(rig,"RefuerzoVigaDesplomada_%d" % i,
                Vector3(-0.41-factor,2.94-factor*0.72,-0.22),
                Vector3(-0.84-factor,2.41-factor*0.72,0.21),
                0.045,RUST)
        rig.set_meta("naval_v2_crane_collapsed",true)
        return
    for side in [-1,1]:
        var z: float=float(side)*0.21
        _beam(rig,"CordónSuperiorGrua_%s" % side,
            Vector3(-0.11,4.13,z),Vector3(-4.33,4.70,z),
            0.052,CAP)
        _beam(rig,"CordónInferiorGrua_%s" % side,
            Vector3(-0.11,3.75,z),Vector3(-4.31,4.33,z),
            0.049,DARK)
        for section in range(4):
            var t0: float=float(section)/4.0
            var t1: float=float(section+1)/4.0
            var x0: float=-0.20-3.91*t0
            var x1: float=-0.20-3.91*t1
            var y0: float=3.82+0.58*t0
            var y1: float=3.82+0.58*t1
            _beam(rig,"DiagonalCelosia_%s_%d" % [side,section],
                Vector3(x0,y0,z),Vector3(x1,y1+0.38,z),
                0.029,Color("#9badad"))
    _box(rig,"RuedaPolipastoCabezal",
        Vector3(-3.28,4.53,0),
        Vector3(0.34,0.28,0.54),DARK,0.34)
    _cylinder(rig,"PoleaPrincipal",
        Vector3(-3.29,4.50,0.0),
        0.27,0.48,SAFETY,0.37,16,Vector3(90,0,0))
    _box(rig,"SeguroGancho",
        Vector3(-3.25,1.30,0),
        Vector3(0.34,0.13,0.26),DARK,0.33)
    for rung in range(8):
        _box(rig,"EscalonEscaleraGrua_%02d" % rung,
            Vector3(0.21,1.06+float(rung)*0.37,-0.20),
            Vector3(0.47,0.04,0.06),CAP,0.24)
    rig.set_meta("naval_v2_crane_lattice",true)

static func _navigation_details(root: Node3D,
        damage: int) -> void:
    if damage>=4:
        return
    var node:=Base._group(root,"BalizasYControlMaritimoV2")
    _box(node,"BandaLuminosaTorre",
        Vector3(5.54,3.10,2.58),
        Vector3(1.12,0.09,0.12),SAFETY,0.12)
    for i in range(8):
        _box(node,"PeldañoTorre_%02d" % i,
            Vector3(5.54,0.95+float(i)*0.32,2.56),
            Vector3(0.43,0.045,0.055),CAP,0.32)
    for side in [-1,1]:
        var z: float=float(side)*4.85
        if side==1 and damage>=3:
            continue
        _box(node,"CabezaBaliza_%s" % side,
            Vector3(-5.50,1.02,z),
            Vector3(0.22,0.22,0.24),
            Color("#e6aa5f") if side==1 else Color("#73c8d3"))
        _box(node,"MastilBaliza_%s" % side,
            Vector3(-5.50,0.78,z),Vector3(0.07,0.36,0.07),
            DARK,0.29)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    var color: Color=Style.faction_color(faction)
    _water(stage)
    _quay_edges(stage,level,damage)
    _hangar_finish(stage,level,damage,color)
    _crane_finish(stage,damage)
    _navigation_details(stage,damage)
    stage.set_meta("naval_v2_details_applied",true)
    stage.set_meta("naval_v2_level",level)
    stage.set_meta("naval_v2_damage",damage)
    return true
