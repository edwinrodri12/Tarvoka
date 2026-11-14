extends RefCounted
class_name TarvokaHeadquartersDamageV22

# Additive structural upgrade over V21's 5 stages. Only the detailed hero
# model may use this: mobile tactical proxies and baked sprites remain stable.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const STAGE_NAME := "DerrumbesAntenasYFracturasHQV22"
const STEEL := Color("#7a8b96")
const SOOT := Color("#272e32")
const CONCRETE := Color("#89999d")
const OXIDE := Color("#8d5840")
const GLASS := Color("#3d6476")

static func _box(root: Node3D,name: String,at: Vector3,dim: Vector3,
        color: Color,rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape: MeshInstance3D = HQ._box(
        root,name,at,dim,color,0.13,false,rotation)
    shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return shape

static func _hide(model: Node3D,label: String) -> bool:
    var mesh: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if mesh == null:
        return false
    mesh.visible = false
    return true

static func _detached_antenna(parent: Node3D,kind: String,
        p: Vector3,length: float,axis: int = 0) -> void:
    # Real 3D tilted masts anchored to the roof, no floating painted decals.
    var tilt := Vector3(0,15,79) if axis == 0 else Vector3(75,0,18)
    _box(parent,"MastilCaido%sV22" % kind,p,
        Vector3(0.12,length,0.12),STEEL,tilt)
    for i in range(2):
        var x: float = p.x+float(i)*0.40-0.22
        var z: float = p.z+float(i)*0.15
        _box(parent,"CrucetaRota%sV22_%d" % [kind,i],
            Vector3(x,p.y+0.075,z),
            Vector3(0.41,0.055,0.075),SOOT,Vector3(10,17,20+float(i)*23))
    _box(parent,"AisladorDesprendido%sV22" % kind,
        p+Vector3(0.61,0.08,0.21),
        Vector3(0.21,0.10,0.19),OXIDE,Vector3(0,0,19))

static func _light(model: Node3D,part: Node3D,level: int) -> void:
    var roof_y: float = 2.87+float(level-1)*0.91
    var broken := Node3D.new()
    broken.name = "AntenasDerribadasPorImpactosLevesV22"
    part.add_child(broken)
    # First antenna falls in ALL three architectural levels.
    var targets := ["AntenaDeMandoMastil","AntenaDeMandoBaliza"]
    for n in range(3):
        targets.append("AntenaDeMandoCruceta_%d" % n)
    for item in targets:
        _hide(model,item)
    _box(broken,"BaseAntenaRasgadaV22",
        Vector3(2.30,roof_y+0.19,1.61),
        Vector3(0.26,0.25,0.24),OXIDE,Vector3(0,0,-18))
    _detached_antenna(broken,"DeMando",
        Vector3(1.93,roof_y+0.27,1.42),
        1.20+float(level-1)*0.16)
    # The parabolic radar is a SECOND conspicuous rooftop aerial, including
    # level 1. Remove its authentic dish/arm (leave damaged pedestal) and
    # lay the actual curved-equivalent thick dish in the roof foreground.
    for item in ["PlatoExterior","CentroParabolica",
            "AlimentadorRadar","BrazoInclinable"]:
        _hide(model,item)
    # The PREMIUM concave dish (V2/V4) is the large antenna visibly
    # towering over the HQ. Hide that entire intact assembly, then
    # reuse its real curved mesh as a fallen, tilted roof fragment.
    var premium: Node3D = model.find_child(
        "RadarPremium3D",true,false) as Node3D
    if premium != null:
        var original_bowl: MeshInstance3D = premium.find_child(
            "PlatoParabolicoConcavo",true,false) as MeshInstance3D
        if original_bowl != null:
            var fallen := MeshInstance3D.new()
            fallen.name = "PlatoParabolicoCaidoV22"
            fallen.mesh = original_bowl.mesh
            fallen.material_override = original_bowl.material_override
            fallen.position = Vector3(-1.10,roof_y+0.33,0.64)
            fallen.rotation_degrees = Vector3(22.0,17.0,31.0)
            fallen.scale = Vector3(1.28,1.28,1.28)
            fallen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            broken.add_child(fallen)
        premium.visible = false
    else:
        # Older low-detail variants still display a physical fallen dish.
        var dish: MeshInstance3D = HQ._cylinder(
            broken,"PlatoRadarCaidoV22",
            Vector3(-1.09,roof_y+0.23,0.64),
            0.66 if level<3 else 0.88,
            0.14,STEEL,0.23,16,Vector3(74,21,27))
        dish.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _box(broken,"SoporteRadarDesprendidoV22",
        Vector3(-1.54,roof_y+0.18,0.81),
        Vector3(0.12,0.83,0.15),OXIDE,Vector3(14,0,77))
    # On levels 2/3 the additional tower mast also falls. The underlying
    # communications TOWER remains undamaged, visible and recognizable.
    if level >= 2:
        targets = ["AntenaSuperiorMastil","AntenaSuperiorBaliza"]
        for n in range(3):
            targets.append("AntenaSuperiorCruceta_%d" % n)
        for item in targets:
            _hide(model,item)
        _box(broken,"BaseAntenaTorreQuebradaV22",
            Vector3(1.54,roof_y+1.64,0.67),
            Vector3(0.27,0.19,0.24),OXIDE,Vector3(9,0,-14))
        _detached_antenna(broken,"DeTorre",
            Vector3(1.54,roof_y+1.75,0.83),
            1.06 if level==2 else 1.45,1)
    # Chips and a small bent roof rail, much less damage than stage 2.
    _box(broken,"BarandillaDobladaV22",
        Vector3(3.10,roof_y+0.15,1.20),
        Vector3(0.92,0.12,0.095),SOOT,Vector3(0,13,21))

static func _moderate(model: Node3D,part: Node3D,level: int) -> void:
    var roof_y: float = 2.87+0.91*float(level-1)
    var moderate := Node3D.new()
    moderate.name = "TechoRotoYVariosPanelesDesprendidosV22"
    part.add_child(moderate)
    # Remove actual intact roof pieces, not simply recolor them gray.
    _hide(model,"CubiertaServidores")
    _hide(model,"TechoAla1")
    _hide(model,"VentanaAla1_2")
    _box(moderate,"LosaServidoresVolcadaV22",
        Vector3(-0.68,roof_y+0.61,1.76),
        Vector3(1.30,0.18,0.82),CONCRETE.darkened(0.21),
        Vector3(0,18,28))
    _box(moderate,"HuecoEnTejadoTecnicoV22",
        Vector3(0.08,roof_y+1.08,1.51),
        Vector3(0.77,0.10,0.72),SOOT,Vector3(0,8,0))
    # The right wing loses its large roof panel, with uneven broken slabs
    # exposing a fractured, dark structural channel underneath.
    _box(moderate,"InteriorTejadoAlaRotoV22",
        Vector3(4.05,2.28,0.43),
        Vector3(2.04,0.13,2.90),SOOT)
    for i in range(4):
        _box(moderate,"PañoTejadoCaidoMedioV22_%d" % i,
            Vector3(3.27+float(i)*0.47,
                2.38-float(i%3)*0.13,
                -0.74+float(i%2)*1.29),
            Vector3(0.72,0.19,1.38),
            CONCRETE.darkened(0.10+float(i)*0.06),
            Vector3(8.0+float(i)*6,8.0+float(i)*14,
                15.0+float(i)*8))
    # Large broken exterior plates, more than the V21 moderate dents.
    for i in range(4):
        _box(moderate,"PanelCaidoEnPatioMedioV22_%d" % i,
            Vector3(2.87+float(i%2)*0.83,0.34,
                -4.10-float(int(i/2))*0.58),
            Vector3(0.91,0.16,0.52),
            STEEL.darkened(float(i)*0.06),
            Vector3(15+float(i)*4,17+float(i)*8,25+float(i)*9))
    for i in range(3):
        _box(moderate,"VigaExpuestaTejadoMedioV22_%d" % i,
            Vector3(3.47+float(i)*0.52,2.38,0.49),
            Vector3(0.10,0.18,2.68),OXIDE,
            Vector3(0,float(i)*8,9.0))
    # Smoke itself comes from a separate animated node built by Studio.
    # Geometry here is persistent, not one-frame damage VFX.

static func _critical(model: Node3D,part: Node3D,level: int) -> void:
    var critical := Node3D.new()
    critical.name = "AlaCompletamenteHundidaAntesDeDestruccionV22"
    part.add_child(critical)
    # At critical damage the LEFT auxiliary wing is genuinely gone.
    # Stage 4 remains completely separate canonical building rubble.
    _hide(model,"GaleriaLateralIzquierda")
    _hide(model,"DintelTraseroAlaV21_-1")
    _hide(model,"ZocaloTraseroAlaV21_-1")
    for i in range(3):
        _hide(model,"VentanaAla-1_%d" % i)
    # Rebuild only irregular partial remnants and visible reinforcement:
    # this is a deliberate breached structure, not the V21 hollow-asset bug.
    _box(critical,"SueloInteriorExpuestoAlaV22",
        Vector3(-4.08,0.18,0.38),
        Vector3(2.41,0.31,4.06),SOOT)
    _box(critical,"MuroRetenidoCortadoAlaV22",
        Vector3(-5.09,0.97,0.48),
        Vector3(0.36,1.88,2.28),CONCRETE.darkened(0.23),
        Vector3(0,0,7))
    for i in range(5):
        _box(critical,"ColumnaEstructuralDesgarradaCriticaV22_%d" % i,
            Vector3(-5.01+float(i)*0.43,
                0.88+float(i%2)*0.22,
                -1.82+float(i%3)*1.34),
            Vector3(0.18,1.38+float(i%3)*0.31,0.18),
            OXIDE,Vector3(0,0,-18+float(i)*12))
    for i in range(7):
        _box(critical,"BloqueDerrumbeMasivoCriticoV22_%d" % i,
            Vector3(-5.25+float(i%4)*0.59,
                0.27+float(i%3)*0.19,
                -4.34+float(int(i/4))*0.65),
            Vector3(0.68+float(i%2)*0.19,
                0.34+float(i%3)*0.19,0.63),
            CONCRETE.darkened(0.13+float(i%3)*0.11),
            Vector3(10+float(i)*6,11+float(i)*13,22+float(i)*7))
    for i in range(3):
        _box(critical,"VigaTorcidaSobreRuinaCriticaV22_%d" % i,
            Vector3(-4.82+float(i)*0.66,1.38,-3.07),
            Vector3(0.16,2.40,0.18),STEEL,
            Vector3(18,9+float(i)*11,38-float(i)*12))
    # Two persistent fire areas (left collapsed wing, right damaged roof)
    # are deliberately delegated to HeadquartersFireV22 so their animation
    # and per-frame GPU budget can be disabled in distant tactical mode.

static func apply(model: Node3D,stage: int,level: int) -> bool:
    if model == null or stage < 0 or stage > 4 or level < 1 or level > 3:
        return false
    if model.has_meta("tarvoka_hq_v22_damage_stage"):
        return false # stages are installed on a fresh building only
    var root := Node3D.new()
    root.name = STAGE_NAME
    root.set_meta("tarvoka_visual_only",true)
    root.set_meta("tarvoka_hq_v22_damage_stage",stage)
    model.add_child(root)
    if stage >= 1 and stage <= 3:
        _light(model,root,level)
    if stage >= 2 and stage <= 3:
        _moderate(model,root,level)
    if stage == 3:
        _critical(model,root,level)
    model.set_meta("tarvoka_hq_v22_damage_stage",stage)
    return true
