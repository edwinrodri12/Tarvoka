extends RefCounted
class_name TarvokaHeadquartersSilhouetteV12

# HQ V12. Native Godot 3D tactical-scale roof profile with physical support.
# The official faction crests remain unmodified and uncovered.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const V11 = preload("res://scripts/ui/HeadquartersRefinementV11.gd")
const GLASS := Color("#3c718a")
const CONCRETE := Color("#8eaaa8")
const RECESSED := Color("#1e323f")
const GASKET := Color("#1b2830")
const STEEL := Color("#a6b8c4")
const WARM := Color("#e4c9a2")
const SOOT := Color("#554747")
const OXIDE := Color("#84614b")

static func _group(parent: Node3D,label: String) -> Node3D:
    return Finish._group(parent,label)

static func _box(parent: Node3D,label: String,at: Vector3,
        size: Vector3,tint: Color,style: String = "brushed_alloy",
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return V11._box(parent,label,at,size,tint,style,rotation)

static func _beam(parent: Node3D,label: String,a: Vector3,b: Vector3,
        thickness: float,tint: Color,
        style: String = "brushed_alloy") -> MeshInstance3D:
    return V11._beam(parent,label,a,b,thickness,tint,style)

static func _curve(parent: Node3D,label: String,start_x: float,
        end_x: float,y: float,z: float,rise: float,depth: float,
        tint: Color,style: String = "brushed_alloy",
        faction: bool = false) -> MeshInstance3D:
    return V11._curve(parent,label,start_x,end_x,y,z,rise,depth,
        tint,style,faction)

static func _wing_profiles(model: Node3D,tint: Color) -> void:
    var roof := _group(model,"CubiertasArquitectonicasPerfilTacticoV12")
    # Pairs of continuous roof arches: these have >0.5m real rise and
    # 0.65m extrusion, designed to remain recognisable at 0.7x studio zoom.
    # Their leading edges occupy the two wings only (x >= 2.9 or <= -2.9).
    for side in [-1,1]:
        var sx: float = float(side)
        var x: float = sx*4.03
        _curve(roof,"PetoCurvoDeAlaV12_%s" % side,
            x-1.24,x+1.24,3.01,-2.88,0.57,0.68,
            RECESSED,"industrial_roof")
        _curve(roof,"CoronaHormigonAlaV12_%s" % side,
            x-1.21,x+1.21,3.12,-2.953,0.53,0.34,
            CONCRETE,"blast_concrete")
        # Distinct broad faction crest on the wing crown, unlike tiny V11
        # rivets invisible at tactical zoom. Original emblems still separate.
        _curve(roof,"BandaFaccionDeArcoV12_%s" % side,
            x-1.12,x+1.12,3.31,-3.017,0.46,0.12,
            tint.darkened(0.17),"brushed_alloy",true)
        _curve(roof,"SombraContinuaBajoArcoV12_%s" % side,
            x-1.10,x+1.10,2.88,-3.055,0.22,0.16,
            GASKET,"industrial_roof")
        # Strong contrast: paired recessed observatory windows sit beneath
        # the arch, in front of outer wing panels but below roof crest.
        for k in [-1,1]:
            var win_x: float = x+float(k)*0.57
            _box(roof,"RecesoMiradorAla_%s_%s" % [side,k],
                Vector3(win_x,2.54,-3.085),
                Vector3(0.47,0.34,0.05),RECESSED,"industrial_roof")
            _box(roof,"VidrioMiradorAla_%s_%s" % [side,k],
                Vector3(win_x,2.56,-3.117),
                Vector3(0.35,0.23,0.036),GLASS,"laminated_glass")
            _box(roof,"RemateMiradorAla_%s_%s" % [side,k],
                Vector3(win_x,2.76,-3.124),
                Vector3(0.46,0.046,0.046),STEEL)
        for rib in [-1,0,1]:
            var offset: float = float(rib)*0.76
            var high: float = 3.14+0.57*sqrt(maxf(0.0,
                1.0-pow(offset/1.24,2.0)))
            _beam(roof,"CerchaArquitectonicaTejado_%s_%s" % [side,rib],
                Vector3(x+offset,high-0.04,-2.30),
                Vector3(x+offset,2.92,-0.89),
                0.075,STEEL)
        _box(roof,"VierteaguasSobreAla_%s" % side,
            Vector3(x,2.89,-3.12),
            Vector3(2.39,0.062,0.11),CONCRETE,"blast_concrete")
        # Explicit supports prevent the overhang from looking detached.
        for k in [-1,1]:
            _beam(roof,"ApoyoCornisaDeAla_%s_%s" % [side,k],
                Vector3(x+float(k)*0.99,2.36,-2.96),
                Vector3(x+float(k)*1.02,3.07,-2.52),
                0.12,RECESSED,"industrial_roof")

static func _command_roof(model: Node3D,level: int,tint: Color) -> void:
    var roof := _group(model,"CoronacionDeMandoDeLejosV12")
    var y: float = 2.87+0.91*float(level-1)
    # A pronounced scalloped ridge, deliberately BEHIND the approved crest
    # and ABOVE the command glazing; central front insignia is never covered.
    _curve(roof,"ArcoCoronaMandoV12",-1.91,1.91,
        y+2.34,-2.68,0.51,0.82,
        RECESSED,"industrial_roof")
    _curve(roof,"CoronamientoAluminioMandoV12",-1.83,1.83,
        y+2.45,-2.744,0.49,0.22,
        CONCRETE,"blast_concrete")
    _curve(roof,"VivoCrestaDeFaccionMandoV12",-1.72,1.72,
        y+2.59,-2.786,0.40,0.095,
        tint.darkened(0.12),"brushed_alloy",true)
    # Large, continuous metallic diagonal structural reads at battle scale.
    for side in [-1,1]:
        var sx: float = float(side)
        _beam(roof,"ContrafuerteDeCoronaMandoV12_%s" % side,
            Vector3(sx*1.63,y+1.72,-2.47),
            Vector3(sx*1.49,y+2.61,-2.01),0.105,STEEL)
        _box(roof,"VentanaAltaMandoTactico_%s" % side,
            Vector3(sx*1.26,y+2.06,-2.75),
            Vector3(0.31,0.42,0.055),GASKET,"industrial_roof")
        _box(roof,"VidrioVentanaAltaMando_%s" % side,
            Vector3(sx*1.26,y+2.075,-2.783),
            Vector3(0.23,0.31,0.027),GLASS,"laminated_glass")

static func _night_accents(model: Node3D) -> void:
    # Visible fixture meshes; actual illumination is supplied by studio
    # light nodes, not by adding unbounded lights to every tactical HQ.
    var fixtures := _group(model,"BalizamientoArquitectonicoV12")
    for side in [-1,1]:
        var sx: float = float(side)
        _box(fixtures,"LuminariaBajoCornisa_%s" % side,
            Vector3(sx*4.03,2.77,-3.18),
            Vector3(0.72,0.055,0.06),WARM)
        _box(fixtures,"ApantallamientoFoco_%s" % side,
            Vector3(sx*4.03,2.835,-3.17),
            Vector3(0.88,0.075,0.10),GASKET,"industrial_roof")
        _box(fixtures,"BalizaAccesoExterior_%s" % side,
            Vector3(sx*2.02,0.59,-4.98),
            Vector3(0.21,0.12,0.13),WARM)
    _box(fixtures,"MarcadorAccesoSuperiorV12",
        Vector3(0,2.58,-4.36),
        Vector3(0.71,0.063,0.075),WARM)

static func _fracture(model: Node3D) -> void:
    # The damaged wing does not retain an intact arch under a stain.
    for label in ["PetoCurvoDeAlaV12_-1",
            "CoronaHormigonAlaV12_-1",
            "BandaFaccionDeArcoV12_-1",
            "SombraContinuaBajoArcoV12_-1"]:
        var healthy: MeshInstance3D = model.find_child(
            label,true,false) as MeshInstance3D
        if healthy != null:
            healthy.visible = false
    var broken := _group(model,"ArcoDeAlaV12Quebrado")
    _curve(broken,"PetoDeAlaRotoExtremoV12",
        -5.24,-4.49,2.92,-2.88,0.19,0.56,
        CONCRETE.darkened(0.22),"blast_concrete")
    _curve(broken,"PetoDeAlaRotoInteriorV12",
        -3.69,-2.81,2.84,-2.88,0.27,0.43,
        CONCRETE.darkened(0.17),"blast_concrete")
    _beam(broken,"RefuerzoAceroFrenteAbiertoV12",
        Vector3(-4.43,3.18,-2.95),
        Vector3(-3.94,2.86,-2.86),0.08,OXIDE,"heat_oxidation")
    _box(broken,"CubiertaDerribadaJuntoAEntradaV12",
        Vector3(-2.92,0.25,-4.13),
        Vector3(1.16,0.13,0.57),SOOT,"heat_oxidation",
        Vector3(12,16,23))

static func _rubble(model: Node3D,tint: Color) -> void:
    var remains := _group(model,"RestosCurvaturaTacticaV12")
    _curve(remains,"PerfilDeTejadoCaidoV12",
        -3.76,-1.84,0.37,-3.97,0.21,0.31,
        tint.darkened(0.44),"heat_oxidation")
    _box(remains,"CostillaMandoRotaV12",
        Vector3(1.42,0.38,-3.21),
        Vector3(0.24,0.68,0.89),SOOT,"heat_oxidation",
        Vector3(28,-13,27))

static func apply(model: Node3D,level: int,tint: Color,condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_visual_v12",false):
        return
    if not model.get_meta("tarvoka_hq_visual_v11",false):
        return
    model.set_meta("tarvoka_hq_visual_v12",true)
    model.set_meta("tarvoka_hq_v12_visual_only",true)
    if condition == "destruido":
        _rubble(model,tint)
        return
    _wing_profiles(model,tint)
    _command_roof(model,level,tint)
    _night_accents(model)
    if condition == "danado":
        _fracture(model)
