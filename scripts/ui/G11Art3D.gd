extends RefCounted
class_name TarvokaG11Art3D

# G11 Lanzador V1. Sculpted native 3D for the TARVOKA inspection studio.
# Presentation only: no combat numbers, ammunition or turn rules change.
const STAGES := ["Intacto", "Daño leve", "Daño moderado", "Daño crítico", "Destruido"]
const META := "tarvoka_g11_damage_stage"
const ROOT := "G11_CascoRaiz"
const TURRET := "G11_GiroPlataforma"
const ELEVATION := "G11_ElevacionLanzador"
const TUBE_COUNT := 12
const FinishV2 = preload("res://scripts/ui/G11FinishV2.gd")
const SurfaceV3 = preload("res://scripts/ui/G11SurfaceV3.gd")
const GeometryV4 = preload("res://scripts/ui/G11GeometryV4.gd")
const MechanicsV5 = preload("res://scripts/ui/G11MechanicsV5.gd")
const DamageV6 = preload("res://scripts/ui/G11DamageSculptV6.gd")
const AtmosphereV7 = preload("res://scripts/ui/G11DamageAtmosphereV7.gd")
const SalvoV8 = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const ExhaustV9 = preload("res://scripts/ui/G11ExhaustV9.gd")
const CooldownV10 = preload("res://scripts/ui/G11CooldownV10.gd")
const FinishV11 = preload("res://scripts/ui/G11ArmorFinishV11.gd")
const CabinV12 = preload("res://scripts/ui/G11CabChassisV12.gd")
const TracksFactionV13 = preload("res://scripts/ui/G11TracksFactionV13.gd")
const DetailV14 = preload("res://scripts/ui/G11MechanicalDetailV14.gd")
const AftFinishV15 = preload("res://scripts/ui/G11AftPodFinishV15.gd")
const FrontFinishV16 = preload("res://scripts/ui/G11FrontFrameV16.gd")
const WeatherV17 = preload("res://scripts/ui/G11SurfaceWeatherV17.gd")
const TracksV18 = preload("res://scripts/ui/G11TrackAssemblyV18.gd")
const TreadsV19 = preload("res://scripts/ui/G11TrackFinishV19.gd")
const WheelV20 = preload("res://scripts/ui/G11WheelSuspensionV20.gd")
const ShockV21 = preload("res://scripts/ui/G11ShockMountFinishV21.gd")
const JointsV22 = preload("res://scripts/ui/G11SuspensionJointsV22.gd")
const JointsV23 = preload("res://scripts/ui/G11JointFinishV23.gd")
const RearV30 = preload("res://scripts/ui/G11RearUndercarriageV30.gd")

static func _mat(color: Color, metal: float = 0.16, emissive: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.68
    m.metallic = metal
    if color.a < 0.99:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.cull_mode = BaseMaterial3D.CULL_DISABLED
    if emissive:
        m.emission_enabled = true
        m.emission = color
    return m

static func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3,
        color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var m := BoxMesh.new()
    m.size = size
    n.mesh = m
    n.material_override = _mat(color)
    n.position = pos
    n.rotation_degrees = rot
    parent.add_child(n)
    return n

static func _cyl(parent: Node3D, name: String, pos: Vector3, radius: float,
        height: float, color: Color, rot: Vector3 = Vector3.ZERO,
        sides: int = 12) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var m := CylinderMesh.new()
    m.top_radius = radius
    m.bottom_radius = radius
    m.height = height
    m.radial_segments = sides
    m.rings = 1
    n.mesh = m
    n.material_override = _mat(color,0.26)
    n.position = pos
    n.rotation_degrees = rot
    parent.add_child(n)
    return n

static func _sphere(parent: Node3D, name: String, pos: Vector3,
        scale3: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var m := SphereMesh.new()
    m.radius = 0.5
    m.height = 1.0
    m.radial_segments = 10
    m.rings = 5
    n.mesh = m
    n.material_override = _mat(color,0.0,emissive)
    n.position = pos
    n.scale = scale3
    parent.add_child(n)
    return n

static func _layer(parent: Node3D, name: String) -> Node3D:
    var n := Node3D.new()
    n.name = name
    n.visible = false
    parent.add_child(n)
    return n

static func has_model(model: Node3D) -> bool:
    return model != null and model.find_child(ROOT,true,false) != null \
        and model.find_child(TURRET,true,false) != null \
        and model.find_child(ELEVATION,true,false) != null

static func build(model: Node3D, paint: Color) -> bool:
    if model == null or has_model(model):
        return false
    var steel := Color("#6e7c80")
    var armor := Color("#929c9a")
    var edge := Color("#263438")
    var rubber := Color("#1c2426")
    var glass := Color("#3b6879")
    var silver := Color("#b7bdb6")
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)
    _box(root,"G11_MonocascoCerrado",Vector3(0,0.63,0.04),
        Vector3(1.43,0.67,2.72),steel)
    _box(root,"G11_ProteccionInferior",Vector3(0,0.30,-0.10),
        Vector3(1.29,0.22,2.81),edge)
    _box(root,"G11_GlacisInclinado",Vector3(0,0.80,-1.29),
        Vector3(1.22,0.45,0.23),armor,Vector3(-24,0,0))
    _box(root,"G11_CabinaDelantera",Vector3(0,1.16,-0.85),
        Vector3(1.26,0.70,0.94),armor)
    _box(root,"G11_TechoCabinaSellado",Vector3(0,1.54,-0.83),
        Vector3(1.18,0.10,0.88),steel)
    _box(root,"G11_ParabrisasBlindado",Vector3(0,1.29,-1.327),
        Vector3(0.86,0.24,0.047),glass,Vector3(-8,0,0))
    _box(root,"G11_DivisorParabrisas",Vector3(0,1.29,-1.355),
        Vector3(0.045,0.24,0.055),edge)
    _box(root,"G11_CapotaBlindada",Vector3(0,1.09,-1.39),
        Vector3(1.12,0.18,0.28),steel,Vector3(-12,0,0))
    _box(root,"G11_PlataformaPosterior",Vector3(0,1.00,0.70),
        Vector3(1.36,0.17,1.44),edge)
    _box(root,"G11_RampaPosteriorCerrada",Vector3(0,0.65,1.43),
        Vector3(1.18,0.47,0.13),steel)
    # Two uninterrupted track bands with real tread shoes and recessed wheels.
    for side in [-1,1]:
        var sign: float = float(side)
        var x: float = sign*0.79
        _box(root,"G11_Oruga_%d" % side,Vector3(x,0.34,-0.05),
            Vector3(0.27,0.57,2.78),rubber)
        _box(root,"G11_Faldon_%d" % side,Vector3(x,0.66,-0.05),
            Vector3(0.34,0.22,2.71),steel)
        for axle in range(6):
            var z: float = -0.875+float(axle)*0.35
            var pivot := Node3D.new()
            pivot.name = "G11_RuedaPivot_%d_%d" % [side,axle]
            pivot.position = Vector3(x,0.265,z)
            root.add_child(pivot)
            _cyl(pivot,"G11_Rueda_%d_%d" % [side,axle],
                Vector3(sign*0.135,0,0),0.18,0.08,edge,
                Vector3(0,0,90),14)
            _cyl(pivot,"G11_Buje_%d_%d" % [side,axle],
                Vector3(sign*0.185,0,0),0.105,0.04,silver,
                Vector3(0,0,90),12)
        for shoe in range(14):
            var zt: float = -1.30+float(shoe)*0.195
            _box(root,"G11_Zapata_%d_%02d" % [side,shoe],
                Vector3(sign*0.95,0.15,zt),
                Vector3(0.025,0.11,0.15),steel)
        for panel in range(3):
            var zp: float = -0.75+float(panel)*0.75
            _box(root,"G11_PanelLateral_%d_%d" % [side,panel],
                Vector3(sign*0.75,0.86,zp),
                Vector3(0.13,0.32,0.60),armor)
            _box(root,"G11_PinturaLateral_%d_%d" % [side,panel],
                Vector3(sign*0.825,0.96,zp),
                Vector3(0.024,0.075,0.36),paint)
        _box(root,"G11_Faro_%d" % side,Vector3(sign*0.52,0.86,-1.50),
            Vector3(0.18,0.14,0.05),silver)
        _box(root,"G11_SoporteRetrovisor_%d" % side,
            Vector3(sign*0.70,1.28,-1.26),Vector3(0.19,0.17,0.08),edge)
        _cyl(root,"G11_Antena_%d" % side,
            Vector3(sign*0.51,1.87,-0.52),0.013,0.65,edge,
            Vector3.ZERO,8)
        _box(root,"G11_Estabilizador_%d" % side,
            Vector3(sign*0.56,0.65,1.47),
            Vector3(0.19,0.75,0.18),edge,Vector3(13,0,sign*8))
        _box(root,"G11_ZapataEstabilizador_%d" % side,
            Vector3(sign*0.56,0.25,1.58),
            Vector3(0.38,0.10,0.37),steel)
    _box(root,"G11_EscotillaComandante",Vector3(-0.33,1.61,-0.77),
        Vector3(0.40,0.06,0.39),edge)
    for i in range(6):
        _box(root,"G11_RejillaMotor_%d" % i,
            Vector3(-0.46+float(i)*0.18,1.12,1.14),
            Vector3(0.105,0.026,0.36),rubber)
    # Independently animated rotating platform and elevated missile array.
    var turret := Node3D.new()
    turret.name = TURRET
    turret.position = Vector3(0,1.14,0.46)
    root.add_child(turret)
    _cyl(turret,"G11_CoronaGiro",Vector3(0,0,0),0.53,0.19,edge)
    _box(turret,"G11_BaseGiro",Vector3(0,0.17,0),
        Vector3(1.13,0.24,0.91),steel)
    _box(turret,"G11_PinturaPlataforma",Vector3(0,0.31,0.20),
        Vector3(0.79,0.035,0.17),paint)
    var elevation := Node3D.new()
    elevation.name = ELEVATION
    elevation.position = Vector3(0,0.39,0.08)
    elevation.rotation_degrees.x = 20.0
    turret.add_child(elevation)
    _box(elevation,"G11_ArmazonLanzador",Vector3(0,0,0.10),
        Vector3(1.18,0.82,1.48),steel)
    _box(elevation,"G11_BastidorTrasero",Vector3(0,0,0.81),
        Vector3(1.22,0.91,0.13),edge)
    _box(elevation,"G11_TapaSuperior",Vector3(0,0.47,0.12),
        Vector3(1.08,0.10,1.27),armor)
    for side in [-1,1]:
        _box(elevation,"G11_RielProtector_%d" % side,
            Vector3(float(side)*0.60,0,0.04),
            Vector3(0.09,0.88,1.40),edge)
        _cyl(elevation,"G11_EjeElevacion_%d" % side,
            Vector3(float(side)*0.63,-0.05,0.26),
            0.15,0.14,silver,Vector3(0,0,90),14)
        _box(elevation,"G11_PinturaLanzador_%d" % side,
            Vector3(float(side)*0.655,0.27,0.25),
            Vector3(0.024,0.16,0.69),paint)
    for column in range(4):
        for row in range(3):
            var x: float = -0.42+float(column)*0.28
            var y: float = -0.24+float(row)*0.24
            var id: String = "%d_%d" % [column,row]
            _cyl(elevation,"G11_Tubo_%s" % id,Vector3(x,y,0.02),
                0.103,1.34,edge,Vector3(90,0,0),14)
            _cyl(elevation,"G11_AroBoca_%s" % id,Vector3(x,y,-0.695),
                0.115,0.048,silver,Vector3(90,0,0),14)
            _cyl(elevation,"G11_BocaInterior_%s" % id,Vector3(x,y,-0.731),
                0.081,0.012,rubber,Vector3(90,0,0),14)
            _cyl(elevation,"G11_TapaTrasera_%s" % id,
                Vector3(x,y,0.71),0.094,0.035,steel,
                Vector3(90,0,0),12)
    _box(turret,"G11_OpticaGiro",Vector3(0.52,0.39,-0.17),
        Vector3(0.17,0.20,0.29),edge)
    _sphere(turret,"G11_LenteAzul",Vector3(0.52,0.41,-0.335),
        Vector3(0.11,0.10,0.04),glass)
    _box(root,"G11_PlacaNumeracionFaccion",Vector3(0,1.58,-1.10),
        Vector3(0.31,0.055,0.16),paint)
    var shot := _layer(elevation,"G11_EfectoFogonazo")
    _sphere(shot,"G11_Destello",Vector3(0.14,0.02,-0.90),
        Vector3(0.52,0.51,0.54),Color(1.0,0.57,0.15,0.85),true)
    var smoke := _layer(elevation,"G11_EfectoHumoDisparo")
    _sphere(smoke,"G11_HumoSalva",Vector3(0,0.06,-1.04),
        Vector3(0.90,0.59,0.66),Color(0.49,0.49,0.47,0.36))
    var dust := _layer(root,"G11_EfectoPolvoMarcha")
    _sphere(dust,"G11_PolvoOruga",Vector3(0,0.26,1.40),
        Vector3(1.65,0.32,0.62),Color(0.48,0.45,0.39,0.28))
    var bullet := _layer(root,"G11_ImpactoBalas")
    _sphere(bullet,"G11_ChispaBalistica",Vector3(0.51,1.12,-1.46),
        Vector3(0.26,0.21,0.15),Color(1,0.68,0.22,0.90),true)
    var explosive := _layer(root,"G11_ImpactoExplosivo")
    _sphere(explosive,"G11_DestelloExplosivo",Vector3(-0.68,1.13,0.46),
        Vector3(0.96,0.92,0.73),Color(1,0.36,0.08,0.65),true)
    _sphere(explosive,"G11_HumoExplosivo",Vector3(-0.61,1.44,0.58),
        Vector3(1.06,1.04,0.90),Color(0.17,0.19,0.18,0.38))
    var light := _layer(root,"G11_Dano1")
    _box(light,"G11_ArañazosFrontales",Vector3(0.32,1.37,-1.37),
        Vector3(0.35,0.035,0.035),edge,Vector3(12,16,11))
    var moderate := _layer(root,"G11_Dano2")
    _box(moderate,"G11_BlindajeDoblado",Vector3(0.83,0.93,0.23),
        Vector3(0.18,0.41,0.51),edge,Vector3(0,0,17))
    _sphere(moderate,"G11_HumoMotor",Vector3(0.3,1.67,1.09),
        Vector3(0.56,0.66,0.48),Color(0.24,0.27,0.26,0.33))
    var critical := _layer(root,"G11_Dano3")
    _box(critical,"G11_PlacaDesprendida",Vector3(-0.78,0.49,0.62),
        Vector3(0.43,0.12,0.68),steel,Vector3(24,8,35))
    _sphere(critical,"G11_FuegoMotor",Vector3(-0.22,1.36,1.08),
        Vector3(0.47,0.72,0.48),Color(1,0.27,0.05,0.81),true)
    _sphere(critical,"G11_HumoNegro",Vector3(-0.18,1.91,1.14),
        Vector3(0.74,0.90,0.69),Color(0.10,0.12,0.12,0.48))
    var wreck := _layer(root,"G11_Dano4")
    _box(wreck,"G11_ModuloDesprendido",Vector3(0.53,0.69,0.89),
        Vector3(1.02,0.35,0.66),edge,Vector3(23,34,31))
    _sphere(wreck,"G11_IncendioInterior",Vector3(0,1.14,0.63),
        Vector3(0.87,0.91,0.88),Color(1,0.30,0.04,0.75),true)
    _sphere(wreck,"G11_HumoColumna",Vector3(0,2.02,0.76),
        Vector3(1.12,1.61,0.93),Color(0.11,0.12,0.12,0.46))
    model.set_meta(META,0)
    model.set_meta("tarvoka_g11_sculpt_v1",true)
    # Geometry remains authored as native Godot meshes; not an image proxy.
    if not FinishV2.apply(model,paint):
        push_warning("G11 finish V2 failed; retaining complete V1 fallback")
    elif not SurfaceV3.apply(model):
        push_warning("G11 surface V3 failed; retaining complete V2 finish")
    elif not GeometryV4.apply(model):
        push_warning("G11 physical sculpt V4 failed; retaining V3 finish")
    elif not MechanicsV5.apply(model):
        push_warning("G11 mechanical sculpt V5 failed; retaining V4 sculpt")
    elif not DamageV6.apply(model):
        push_warning("G11 3D damage V6 failed; retaining V5 sculpt")
    elif not AtmosphereV7.apply(model):
        push_warning("G11 damage atmosphere V7 failed; retaining V6 sculpture")
    elif not SalvoV8.apply(model):
        push_warning("G11 sequential rocket salvo V8 failed; retaining V7 sculpture")
    elif not ExhaustV9.apply(model):
        push_warning("G11 procedural exhaust V9 failed; retaining V8 salvo")
    elif not CooldownV10.apply(model):
        push_warning("G11 post-salvo cooling V10 failed; retaining V9 exhaust")
    elif not FinishV11.apply(model):
        push_warning("G11 beveled armor finish V11 failed; retaining V10 sculpture")
    elif not CabinV12.apply(model,paint):
        push_warning("G11 cabin/chassis V12 failed; retaining V11 sculpture")
    elif not TracksFactionV13.apply(model,paint):
        push_warning("G11 V13 physical sprocket and faction color refinement failed")
    elif not DetailV14.apply(model,paint):
        push_warning("G11 V14 live hydraulic/service detail failed; retaining V13 sculpture")
    elif not AftFinishV15.apply(model,paint):
        push_warning("G11 V15 rear armor refinement failed; retaining V14 sculpture")
    elif not FrontFinishV16.apply(model,paint):
        push_warning("G11 V16 frame/roof refinement failed; retaining V15 sculpture")
    elif not WeatherV17.apply(model,paint):
        push_warning("G11 V17 procedural material/weathering failed; retaining V16 sculpture")
    elif not TracksV18.apply(model):
        push_warning("G11 V18 track overlap/clearance refinement failed; retaining V17 sculpture")
    elif not TreadsV19.apply(model):
        push_warning("G11 V19 beveled tread and tapered guard detail failed; retaining V18 sculpture")
    elif not WheelV20.apply(model):
        push_warning("G11 V20 integrated roadwheels and springs failed; retaining V19 sculpture")
    elif not ShockV21.apply(model):
        push_warning("G11 V21 spring seats/shock mounting failed; retaining V20 sculpt")
    elif not JointsV22.apply(model):
        push_warning("G11 V22 mechanical suspension pins failed; retaining V21 sculpt")
    elif not JointsV23.apply(model):
        push_warning("G11 V23 chamfered hinge and retaining collars failed; retaining V22 sculpt")
    elif not RearV30.apply_hero(model):
        push_warning("G11 V30 rear stabilizer/underbelly clearance refinement failed")
    return true

static func stage(model: Node3D) -> int:
    return clampi(int(model.get_meta(META,0)),0,4) if model != null else 0

static func apply_stage(model: Node3D, value: int) -> bool:
    if not has_model(model):
        return false
    var s: int = clampi(value,0,4)
    model.set_meta(META,s)
    for level in range(1,5):
        var layer: Node3D = model.find_child("G11_Dano%d" % level,true,false) as Node3D
        if layer != null:
            layer.visible = s >= level
    var launcher: Node3D = model.find_child(ELEVATION,true,false) as Node3D
    launcher.visible = s < 4
    DamageV6.update_stage(model,s)
    AtmosphereV7.set_stage(model,s)
    CabinV12.set_stage(model,s)
    AftFinishV15.set_stage(model,s)
    FrontFinishV16.set_stage(model,s)
    WeatherV17.set_stage(model,s)
    return true
