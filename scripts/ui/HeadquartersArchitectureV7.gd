extends RefCounted
class_name TarvokaHeadquartersArchitectureV7

# Cuartel General V7: close-to-final architectural pass, not gameplay.
# Adds meaningful geometry over V4: curved canopy, deep glazed portal,
# reinforced command bridge, serviced roofs, believable radar mechanics,
# controlled helipad edge and condition-specific physical damage.
# Reuses approved proportions, faction identity, textures and 3D shield.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const INK := Color("#233743")
const TITANIUM := Color("#71828d")
const EDGE := Color("#d5dce0")
const GLAZING := Color("#214e68")
const SHADOW := Color("#263239")
const LIGHT := Color("#f2c26a")
const PAVEMENT := Color("#596c75")

static func _group(parent: Node3D, name: String) -> Node3D:
    return Finish._group(parent,name)

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, color: Color, material: String = "steel",
        faction_panel: bool = false,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return Finish._box(parent,name,pos,size,color,material,faction_panel,rotation)

static func _shell(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, bevel: float, color: Color,
        material: String = "steel", faction_panel: bool = false) -> MeshInstance3D:
    return Finish._chamfer(parent,name,pos,size,bevel,color,material,faction_panel)

static func _beam(parent: Node3D, name: String, a: Vector3,
        b: Vector3, radius: float, color: Color) -> MeshInstance3D:
    return Finish._beam(parent,name,a,b,radius,color)

static func _cylinder(parent: Node3D, name: String, at: Vector3,
        radius: float, length: float, color: Color, sides: int = 12,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = sides
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.position = at
    instance.rotation_degrees = rotation
    instance.material_override = Finish._mat(color,"steel")
    parent.add_child(instance)
    return instance

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    for point in [a,b,c]:
        st.set_uv(Vector2(point.x*0.20+0.50,point.z*0.24+point.y*0.14))
        st.add_vertex(point)

static func _curved_canopy(parent: Node3D, tint: Color) -> void:
    var shape := SurfaceTool.new()
    shape.begin(Mesh.PRIMITIVE_TRIANGLES)
    # 3D, gently cambered roof (not the previous flat rectangular portico).
    # The front edge and underside are separate faces with real thickness.
    var w: float = 2.05
    var steps: int = 16
    for i in range(steps):
        var x0: float = -w + 2.0*w*float(i)/float(steps)
        var x1: float = -w + 2.0*w*float(i+1)/float(steps)
        var y0: float = 2.38 + 0.22*(1.0-pow(x0/w,2.0))
        var y1: float = 2.38 + 0.22*(1.0-pow(x1/w,2.0))
        var a := Vector3(x0,y0,-4.09)
        var b := Vector3(x0,y0,-3.41)
        var c := Vector3(x1,y1,-3.41)
        var d := Vector3(x1,y1,-4.09)
        var e := a-Vector3(0,0.14,0)
        var f := b-Vector3(0,0.14,0)
        var g := c-Vector3(0,0.14,0)
        var h := d-Vector3(0,0.14,0)
        _tri(shape,a,b,c)
        _tri(shape,a,c,d)
        _tri(shape,f,e,h)
        _tri(shape,f,h,g)
        _tri(shape,a,d,h)
        _tri(shape,a,h,e)
        _tri(shape,c,b,f)
        _tri(shape,c,f,g)
        if i == 0:
            _tri(shape,b,a,e)
            _tri(shape,b,e,f)
        if i == steps-1:
            _tri(shape,d,c,g)
            _tri(shape,d,g,h)
    shape.generate_normals()
    shape.generate_tangents()
    var canopy := MeshInstance3D.new()
    canopy.name = "MarquesinaAerodinamicaCurvaV7"
    canopy.mesh = shape.commit()
    canopy.material_override = Finish._mat(INK,"roof")
    parent.add_child(canopy)
    # The cantilever has a second continuous metal safety edge.
    var edge: Node3D = _group(parent,"BiselPerimetralDeMarquesina")
    for i in range(16):
        var x0: float = -w+2.0*w*float(i)/16.0
        var x1: float = -w+2.0*w*float(i+1)/16.0
        var y0: float = 2.38+0.22*(1.0-pow(x0/w,2.0))
        var y1: float = 2.38+0.22*(1.0-pow(x1/w,2.0))
        _beam(edge,"PerfilCurvoDeAluminio_%02d" % i,
            Vector3(x0,y0-0.08,-4.106),
            Vector3(x1,y1-0.08,-4.106),0.034,TITANIUM)
    _box(edge,"RibeteFaccionEnAleron",
        Vector3(0,2.48,-4.135),Vector3(1.73,0.038,0.027),
        tint.darkened(0.10),"steel",true)

static func _entrance(parent: Node3D, tint: Color) -> void:
    var entrance := _group(parent,"AccesoOperativoEsculpidoV7")
    _curved_canopy(entrance,tint)
    # Deep portal and dark recessed doors, not a painted plane.
    _shell(entrance,"MarcoExteriorDeAcceso",
        Vector3(0,1.13,-3.83),Vector3(2.65,2.13,0.32),
        0.095,TITANIUM,"steel")
    _shell(entrance,"UmbralInteriorRehundido",
        Vector3(0,1.09,-4.025),Vector3(2.19,1.80,0.045),
        0.044,SHADOW,"roof")
    for side in [-1,1]:
        var sx: float = float(side)
        _shell(entrance,"HojaCristalBlindado_%s" % side,
            Vector3(sx*0.49,1.04,-4.076),
            Vector3(0.86,1.52,0.044),0.038,
            GLAZING,"glass")
        _box(entrance,"PulsadorDeEmergencia_%s" % side,
            Vector3(sx*0.17,1.07,-4.115),
            Vector3(0.045,0.17,0.043),EDGE)
        _box(entrance,"TiradorMetálicoVertical_%s" % side,
            Vector3(sx*0.10,1.13,-4.123),
            Vector3(0.032,0.34,0.05),LIGHT)
        _shell(entrance,"CelosiaLateralAcceso_%s" % side,
            Vector3(sx*1.65,1.29,-3.96),
            Vector3(0.37,1.51,0.10),0.045,INK,"roof")
        for k in range(4):
            _box(entrance,"LamaLateral_%s_%d" % [side,k],
                Vector3(sx*1.65,0.82+float(k)*0.25,-4.022),
                Vector3(0.28,0.036,0.025),EDGE,"steel")
        _beam(entrance,"PuntalInclinadoDeMarquesina_%s" % side,
            Vector3(sx*1.75,1.95,-3.72),
            Vector3(sx*1.94,2.40,-4.01),0.065,TITANIUM)
    _shell(entrance,"EscalónDeEntradaReforzado",
        Vector3(0,0.155,-4.29),Vector3(2.89,0.17,0.62),
        0.12,PAVEMENT,"concrete")
    _box(entrance,"HuellaAntideslizante",
        Vector3(0,0.245,-4.48),Vector3(2.52,0.025,0.14),
        SHADOW,"roof")
    for side in [-1,1]:
        _box(entrance,"BandaIluminadaAcceso_%s" % side,
            Vector3(float(side)*1.22,0.250,-4.49),
            Vector3(0.085,0.026,0.19),LIGHT)

static func _command_bridge(parent: Node3D, level: int, tint: Color) -> void:
    var y: float = 2.87+0.91*float(level-1)
    var bridge := _group(parent,"PuenteDeMandoArquitectonicoV7")
    # Panoramic side glazing wraps around the high command volume.
    # Main approved crest at x=0 stays completely unobscured.
    for side in [-1,1]:
        var sx: float = float(side)
        _shell(bridge,"CristalPanoramicoComando_%s" % side,
            Vector3(sx*1.45,y+0.63,-3.283),
            Vector3(0.36,0.72,0.095),0.045,GLAZING,"glass")
        _box(bridge,"ParteluzVerticalTorre_%s" % side,
            Vector3(sx*1.44,y+0.64,-3.346),
            Vector3(0.045,0.75,0.041),TITANIUM)
        _shell(bridge,"ViseraBiseladaDeComando_%s" % side,
            Vector3(sx*1.33,y+1.20,-3.32),
            Vector3(0.67,0.15,0.30),0.07,INK,"roof")
        for k in range(3):
            _beam(bridge,"TiranteDeMando_%s_%d" % [side,k],
                Vector3(sx*(1.50+0.15*float(k)),y+1.63,-3.00),
                Vector3(sx*(1.88+0.10*float(k)),y+1.37,-3.02),
                0.03,TITANIUM)
        _box(bridge,"SeñalizaciónLateralAltura_%s" % side,
            Vector3(sx*1.90,y+1.37,-3.27),
            Vector3(0.08,0.18,0.17),LIGHT)
    _shell(bridge,"DintelEscudoDeMandoCurvo",
        Vector3(0,y+1.82,-3.22),
        Vector3(3.62,0.20,0.49),0.18,TITANIUM,"steel")
    _box(bridge,"GuíaLumínicaSuperiorEscudo",
        Vector3(0,y+1.78,-3.483),
        Vector3(2.94,0.037,0.035),tint.darkened(0.07),"steel",true)
    # Structural roof spines change the upper silhouette at all zoom levels.
    for side in [-1,1]:
        var sx: float = float(side)
        _beam(bridge,"EspinazoSuperiorV7_%s" % side,
            Vector3(sx*1.26,y+1.79,-2.97),
            Vector3(sx*1.47,y+1.81,-1.43),0.066,INK)

static func _roof_equipment(parent: Node3D, level: int,tint: Color) -> void:
    var equipment := _group(parent,"AzoteasTecnicasModularesV7")
    for side in [-1,1]:
        var sx: float = float(side)
        # Service machine on each wing. No floating elements: all bases
        # rest on wing roof y≈2.75, away from the central command tower.
        var x: float = sx*3.92
        _shell(equipment,"BaseHVAC_%s" % side,
            Vector3(x,2.90,0.84),Vector3(1.22,0.26,1.45),
            0.10,INK,"roof")
        _shell(equipment,"CarcasaHVAC_%s" % side,
            Vector3(x,3.22,0.84),Vector3(1.00,0.52,1.20),
            0.08,TITANIUM,"steel")
        for index in range(4):
            _box(equipment,"AletaHVAC_%s_%d" % [side,index],
                Vector3(x-0.38+float(index)*0.245,3.31,0.222),
                Vector3(0.14,0.24,0.047),SHADOW,"roof")
        _cylinder(equipment,"ExtractorAzotea_%s" % side,
            Vector3(x,3.51,0.93),0.32,0.13,INK,16)
        _cylinder(equipment,"TapaExtractorAzotea_%s" % side,
            Vector3(x,3.59,0.93),0.19,0.035,EDGE,16)
        # Sealed cable ducts and warning stripes along outer edge.
        _box(equipment,"CanalizaciónAzotea_%s" % side,
            Vector3(sx*4.91,2.83,0.45),
            Vector3(0.12,0.12,2.77),INK,"roof")
        _box(equipment,"RegistroCanalAzotea_%s" % side,
            Vector3(sx*4.91,2.94,0.23),
            Vector3(0.19,0.038,0.35),LIGHT)
        for k in range(3):
            _box(equipment,"AntideslizanteAlero_%s_%d" % [side,k],
                Vector3(x-0.58+float(k)*0.58,2.778,-1.12),
                Vector3(0.11,0.019,0.31),LIGHT,"steel")
    if level >= 2:
        var y: float = 2.87+float(level-1)*0.91
        _shell(equipment,"GaleriaBlindadaSobreServidor",
            Vector3(0.35,y+0.42,1.55),
            Vector3(1.19,0.45,0.81),0.08,TITANIUM,"roof")
        for index in range(3):
            _box(equipment,"LamaServidor_%d" % index,
                Vector3(-0.045+float(index)*0.36,y+0.42,1.125),
                Vector3(0.25,0.23,0.049),SHADOW)
    if level == 3:
        _beam(equipment,"TensorNivel3Izquierda",
            Vector3(-3.55,3.54,1.45),Vector3(-4.25,3.03,1.05),
            0.042,TITANIUM)
        _beam(equipment,"TensorNivel3Derecha",
            Vector3(-4.18,3.54,1.45),Vector3(-3.41,3.03,1.05),
            0.042,TITANIUM)

static func _radar_mount(parent: Node3D, level: int) -> void:
    var radar := _group(parent,"MecanismoDeRadarArticuladoV7")
    var y: float = 2.87+0.91*float(level-1)
    var x: float = -1.86
    var z: float = 0.76
    # Mechanical gimbal below the existing V4 concave dish.
    _cylinder(radar,"AnilloDeGiroRadar",Vector3(x,y+0.46,z),
        0.42,0.16,INK,16)
    _cylinder(radar,"RodamientoAzimut",Vector3(x,y+0.57,z),
        0.26,0.09,EDGE,16)
    for side in [-1,1]:
        var sx: float = float(side)
        _beam(radar,"HorquillaRadar_%s" % side,
            Vector3(x+sx*0.39,y+0.57,z),
            Vector3(x+sx*0.25,y+1.37,z-0.10),0.076,TITANIUM)
        _beam(radar,"AmortiguadorDeInclinacion_%s" % side,
            Vector3(x+sx*0.41,y+0.57,z+0.35),
            Vector3(x+sx*0.21,y+1.28,z+0.04),0.035,SHADOW)
    _box(radar,"CajaDeAccionamientoRadar",
        Vector3(x+0.59,y+0.38,z),Vector3(0.47,0.37,0.49),
        INK,"roof")
    _box(radar,"RegistroDeMotor",
        Vector3(x+0.60,y+0.60,z),Vector3(0.35,0.03,0.36),
        LIGHT)

static func _helipad_finish(parent: Node3D,tint: Color) -> void:
    var pad := _group(parent,"BalizamientoHelipuertoV7")
    # Original helipad was lowered to sit on the yard at y~0.32 in V4.
    # Avoid tall railings that would obstruct rotor clearance.
    for side in [-1,1]:
        var sx: float = float(side)
        _box(pad,"GuíaPerimetralHelipuertoX_%s" % side,
            Vector3(4.85+sx*1.66,0.31,-4.08),
            Vector3(0.044,0.044,2.85),EDGE)
        _box(pad,"GuíaPerimetralHelipuertoZ_%s" % side,
            Vector3(4.85,0.31,-4.08+sx*1.60),
            Vector3(3.14,0.044,0.044),EDGE)
    for index in range(12):
        var side: int = index/3
        var position := Vector3.ZERO
        var t: float = float(index%3)-1.0
        if side == 0:
            position = Vector3(4.85+t*1.17,0.35,-5.70)
        elif side == 1:
            position = Vector3(4.85+t*1.17,0.35,-2.46)
        elif side == 2:
            position = Vector3(3.17,0.35,-4.08+t*1.17)
        else:
            position = Vector3(6.53,0.35,-4.08+t*1.17)
        _box(pad,"BalizaDeAterrizaje_%02d" % index,
            position,Vector3(0.12,0.12,0.12),
            LIGHT if index%3==1 else tint.darkened(0.1),"steel",index%3!=1)
    _shell(pad,"ArmarioAntincendiosHelipuerto",
        Vector3(6.50,0.36,-2.18),
        Vector3(0.38,0.58,0.37),0.07,SHADOW,"roof")
    _box(pad,"IndicadorAntincendios",
        Vector3(6.50,0.41,-2.385),
        Vector3(0.20,0.18,0.04),LIGHT)

static func _damage(parent: Node3D,level: int) -> void:
    var damaged := _group(parent,"FracturaMaterialArquitectonicaV7")
    var y: float = 2.87+0.91*float(level-1)
    # Broken pane/canopy with visible support and blackened surfaces.
    _box(damaged,"VidrioAstilladoAcceso",
        Vector3(-0.48,1.17,-4.132),
        Vector3(0.63,0.15,0.06),SHADOW,"roof",
        false,Vector3(0,0,18))
    _box(damaged,"MarcaImpactoMarquesina",
        Vector3(-1.05,2.35,-4.16),
        Vector3(0.53,0.10,0.07),SHADOW,"roof",
        false,Vector3(0,0,-13))
    _beam(damaged,"RiostraDobladaRadar",
        Vector3(-2.28,y+0.64,0.76),
        Vector3(-2.15,y+0.18,0.82),0.043,SHADOW)
    _box(damaged,"RegistroHVACDesprendido",
        Vector3(3.83,2.94,0.12),
        Vector3(0.44,0.055,0.31),SHADOW,"roof",
        false,Vector3(17,12,11))

static func _ruins(parent: Node3D, tint: Color) -> void:
    var ruins := _group(parent,"RestosDeFachadaV7")
    _shell(ruins,"MarquesinaArrancada",
        Vector3(-1.65,0.36,-4.13),
        Vector3(2.13,0.19,0.80),0.13,INK,"roof")
    _beam(ruins,"VigaDeAccesoQuebrada",
        Vector3(-2.82,0.21,-4.60),
        Vector3(-0.46,0.72,-3.89),0.12,TITANIUM)
    _shell(ruins,"CajaHVACCaída",
        Vector3(3.31,0.38,0.93),
        Vector3(1.01,0.54,1.13),0.11,SHADOW,"steel")
    for i in range(4):
        _box(ruins,"FragmentoVidrioBlindado_%02d" % i,
            Vector3(-1.10+float(i)*0.45,0.20,-4.46+float(i%2)*0.38),
            Vector3(0.36,0.035,0.24),GLAZING,"glass",
            false,Vector3(0,16.0*float(i),0))
    _box(ruins,"PanelFaccionDesprendido",
        Vector3(2.62,0.28,-3.38),
        Vector3(1.11,0.08,0.68),tint.darkened(0.43),
        "steel",true,Vector3(0,-17,23))

static func set_near_detail(model: Node3D, near: bool) -> void:
    if model == null:
        return
    var fine: Node3D = model.find_child("MicrodetalleConstructivoV7",true,false) as Node3D
    if fine != null:
        fine.visible = near

static func _fine_detail(model: Node3D,level: int) -> void:
    var fine := _group(model,"MicrodetalleConstructivoV7")
    var y: float = 2.87+0.91*float(level-1)
    for side in [-1,1]:
        var sx: float = float(side)
        for i in range(7):
            _box(fine,"TornilloGuíaDeFachada_%s_%02d" % [side,i],
                Vector3(sx*(1.81+0.12*float(i)),y+1.72,-3.47),
                Vector3(0.043,0.043,0.028),EDGE)
        for i in range(4):
            _box(fine,"PernoComunidadAlera_%s_%02d" % [side,i],
                Vector3(sx*(3.34+0.45*float(i)),2.80,-1.65),
                Vector3(0.048,0.022,0.039),LIGHT)
    fine.visible = false

static func apply(model: Node3D,level: int,tint: Color,condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_visual_v7",false):
        return
    if not model.get_meta("tarvoka_hq_visual_v4",false):
        return
    model.set_meta("tarvoka_hq_visual_v7",true)
    if condition == "destruido":
        _ruins(model,tint)
        return
    _entrance(model,tint)
    _command_bridge(model,level,tint)
    _roof_equipment(model,level,tint)
    _radar_mount(model,level)
    _helipad_finish(model,tint)
    _fine_detail(model,level)
    if condition == "danado":
        _damage(model,level)
    set_near_detail(model,false)
