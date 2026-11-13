extends RefCounted
class_name TarvokaHeadquarters3D

# Cuartel General: geometria 3D nativa y editable. La infografia original
# del 12-11-2026 es referencia artistica; esto NO convierte su PNG en una malla.
# Las estadisticas, los turnos, el combate y los guardados NO se modifican.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const CONDITIONS := ["operativo", "capturado", "danado", "destruido"]
const BASE := Color("#788693")
const CONCRETE := Color("#b3b9b5")
const WALL := Color("#c4cbc9")
const ROOF := Color("#455765")
const DARK := Color("#26343e")
const GLASS := Color("#396b85")
const GOLD := Color("#d9ad4c")
const LIGHT := Color("#e6e3d7")
const ASPHALT := Color("#3c4549")
const SOOT := Color("#262a2d")
static var _material_cache: Dictionary = {}

static func valid_spec(level: int, faction: int, condition: String) -> bool:
    return level >= 1 and level <= 3 and faction >= 0 and faction < Style.FACTIONS.size() and condition in CONDITIONS

static func _mat(color: Color, metallic: float = 0.12, alpha: bool = false) -> StandardMaterial3D:
    var key: String = "%s/%0.2f/%s" % [color.to_html(true), metallic, str(alpha)]
    if _material_cache.has(key):
        return _material_cache[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = 0.63 if metallic > 0.25 else 0.80
    if alpha:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _material_cache[key] = material
    return material

static func _group(parent: Node3D, label: String, position: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = position
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3,
        tint: Color, metal: float = 0.12, paint: bool = false,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.rotation_degrees = rotation
    item.material_override = _mat(tint, metal)
    if paint:
        item.set_meta("tarvoka_faction_panel", true)
    parent.add_child(item)
    return item

static func _cylinder(parent: Node3D, label: String, pos: Vector3, radius: float,
        height: float, tint: Color, metal: float = 0.25, segments: int = 12,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = maxi(8, segments)
    item.mesh = mesh
    item.position = pos
    item.rotation_degrees = rotation
    item.material_override = _mat(tint, metal)
    parent.add_child(item)
    return item

static func _sphere(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, tint: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 10
    mesh.rings = 6
    item.mesh = mesh
    item.position = pos
    item.scale = size
    item.material_override = _mat(tint, 0.03, tint.a < 0.99)
    parent.add_child(item)
    return item

static func _windows(parent: Node3D, level: int, roof_y: float) -> void:
    # Todas las fachadas tienen volumen: marco, vidrio oscuro y un parteluz.
    for floor_id in range(level):
        var y: float = minf(roof_y - 0.62, 1.26 + float(floor_id) * 1.09)
        for x in [-2.18, -1.32, 1.32, 2.18]:
            _box(parent, "MarcoVentanaF_%d_%.2f" % [floor_id, x],
                Vector3(x,y,-2.355), Vector3(0.73,0.68,0.105), DARK, 0.30)
            _box(parent, "VidrioVentanaF_%d_%.2f" % [floor_id, x],
                Vector3(x,y,-2.417), Vector3(0.60,0.55,0.026), GLASS, 0.38)
            _box(parent, "ParteluzF_%d_%.2f" % [floor_id, x],
                Vector3(x,y,-2.442), Vector3(0.045,0.56,0.034), LIGHT, 0.28)
        for side in [-1,1]:
            var sx: float = float(side) * 2.96
            for z in [-1.25,0.10,1.45]:
                _box(parent, "VentanaL_%d_%s_%.2f" % [floor_id,side,z],
                    Vector3(sx,y,z), Vector3(0.072,0.53,0.69), GLASS, 0.30)

static func _solar(parent: Node3D, count: int, y: float) -> void:
    for i in range(count):
        var x: float = -1.68 + float(i) * 1.10
        _box(parent,"BastidorPanelSolar_%d" % i,
            Vector3(x,y,1.05),Vector3(0.94,0.07,1.22),DARK,0.36, false,
            Vector3(18,0,0))
        _box(parent,"CelulasSolar_%d" % i,
            Vector3(x,y+0.045,1.05),Vector3(0.83,0.028,1.06),
            Color("#295473"),0.34,false,Vector3(18,0,0))
        for k in range(2):
            _box(parent,"DivisionPanel_%d_%d" % [i,k],
                Vector3(x-0.18+float(k)*0.36,y+0.076,1.05),
                Vector3(0.019,0.025,1.02),LIGHT,0.24,false,
                Vector3(18,0,0))

static func _radar(parent: Node3D, roof_y: float, level: int) -> void:
    var radar: Node3D = _group(parent,"RadarParabolico",Vector3(-1.78,roof_y,0.62))
    _cylinder(radar,"PedestalRadar",Vector3(0,0.30,0),0.16,0.60,DARK)
    _box(radar,"BrazoInclinable",Vector3(0,0.71,0),
        Vector3(0.11,0.70,0.13),BASE,0.35, false, Vector3(0,0,25))
    _cylinder(radar,"PlatoExterior",Vector3(0.12,1.07,0.0),
        0.65 if level < 3 else 0.88,0.13,LIGHT,0.25,20,Vector3(0,0,30))
    _cylinder(radar,"CentroParabolica",Vector3(0.12,1.16,0.0),
        0.14,0.18,DARK,0.35,12,Vector3(0,0,30))
    _cylinder(radar,"AlimentadorRadar",Vector3(0.10,1.29,0),
        0.042,0.28,DARK,0.35,10,Vector3(0,0,30))

static func _antenna(parent: Node3D, label: String, base: Vector3, height: float,
        tint: Color = GOLD) -> void:
    _cylinder(parent,label+"Mastil",base+Vector3(0,height*0.5,0),
        0.055,height,BASE,0.45,10)
    for n in range(3):
        var y: float = base.y + height*(0.38 + float(n)*0.23)
        _box(parent,label+"Cruceta_%d" % n,Vector3(base.x,y,base.z),
            Vector3(0.48,0.055,0.052),DARK,0.33)
    _sphere(parent,label+"Baliza",base+Vector3(0,height+0.035,0),
        Vector3(0.13,0.13,0.13),tint)

static func _control_tower(parent: Node3D, color: Color,
        level: int, roof_y: float) -> void:
    if level < 2:
        return
    var tower: Node3D = _group(parent,"TorreDeComunicaciones",
        Vector3(1.54,roof_y,0.67))
    _box(tower,"FusteDeTorre",Vector3(0,0.55,0),
        Vector3(0.91,1.08,0.91),WALL)
    _box(tower,"CabinaRadar",Vector3(0,1.28,0),
        Vector3(1.48,0.44,1.30),GLASS,0.30)
    _box(tower,"CubiertaCabina",Vector3(0,1.53,0),
        Vector3(1.63,0.14,1.48),color,0.18,true)
    for side in [-1,1]:
        var s: float = float(side)
        _box(tower,"SeparadorCabina_%s" % side,
            Vector3(s*0.38,1.28,-0.69),Vector3(0.06,0.45,0.045),LIGHT)
    _antenna(tower,"AntenaSuperior",Vector3(0,1.60,0),
        1.15 if level == 2 else 1.75)

static func _helipad(parent: Node3D, color: Color, level: int) -> void:
    # Helipuerto de la imagen aprobada. Plataforma con H REAL de tres mallas.
    var pad: Node3D = _group(parent,"Helipuerto",Vector3(4.06,0,3.40))
    _box(pad,"PilaresHelipuerto",Vector3(0,1.10,0),
        Vector3(1.00,2.20,1.00),CONCRETE)
    _box(pad,"PlataformaHelipuerto",Vector3(0,2.26,0),
        Vector3(3.12,0.19,3.00),DARK,0.18)
    _box(pad,"BordeNorte",Vector3(0,2.39,-1.35),
        Vector3(2.76,0.055,0.10),color,0.24,true)
    _box(pad,"BordeSur",Vector3(0,2.39,1.35),
        Vector3(2.76,0.055,0.10),color,0.24,true)
    for s in [-1,1]:
        _box(pad,"BordeLateral%s" % s,Vector3(float(s)*1.42,2.39,0),
            Vector3(0.09,0.055,2.78),color,0.24,true)
        _box(pad,"H_Raya_%s" % s,Vector3(float(s)*0.28,2.39,0),
            Vector3(0.115,0.012,0.91),LIGHT,0.04)
    _box(pad,"H_Travesano",Vector3(0,2.39,0),
        Vector3(0.66,0.012,0.115),LIGHT,0.04)
    for sx in [-1,1]:
        for sz in [-1,1]:
            _sphere(pad,"LuzPista_%s_%s" % [sx,sz],
                Vector3(float(sx)*1.20,2.42,float(sz)*1.15),
                Vector3(0.11,0.09,0.11),GOLD)
    if level >= 3:
        _box(pad,"SeccionAccesoElevado",Vector3(-1.72,1.62,0),
            Vector3(0.48,1.43,0.91),CONCRETE)
        _box(pad,"PuenteDeAcceso",Vector3(-1.11,2.25,0),
            Vector3(1.40,0.13,0.90),BASE)

static func _yard(parent: Node3D, color: Color, level: int) -> void:
    var yard: Node3D = _group(parent,"PatioMilitar")
    _box(yard,"BaseDelCuartel",Vector3(0,-0.08,0),
        Vector3(13.60,0.20,12.80),ASPHALT)
    _box(yard,"PlacaCentral",Vector3(0,0.035,-0.20),
        Vector3(8.32,0.10,8.16),Color("#69757b"))
    # Acceso, viales y plazas de estacionamiento.
    _box(yard,"AccesoAsfaltado",Vector3(0,0.037,-4.72),
        Vector3(3.55,0.105,2.38),DARK)
    for s in [-1,1]:
        var sign: float = float(s)
        _box(yard,"LineaVial_%s" % s,Vector3(sign*1.62,0.096,-5.08),
            Vector3(0.07,0.015,1.47),LIGHT)
        _box(yard,"BarreraSeguridad_%s" % s,
            Vector3(sign*2.26,0.42,-5.58),Vector3(0.76,0.77,0.33),CONCRETE)
        _box(yard,"CasetaControl_%s" % s,
            Vector3(sign*5.50,0.67,-4.42),Vector3(1.25,1.26,1.17),WALL)
        _box(yard,"TechoCaseta_%s" % s,
            Vector3(sign*5.50,1.35,-4.42),Vector3(1.46,0.13,1.31),color,0.20,true)
        _box(yard,"CristalCaseta_%s" % s,
            Vector3(sign*5.50,0.83,-5.04),Vector3(0.82,0.38,0.05),GLASS)
    for s in [-1,1]:
        for i in range(4):
            var x: float = -5.64 + float(i)*3.78
            _cylinder(yard,"PosteValla_%s_%d" % [s,i],
                Vector3(x,0.45,float(s)*6.20),0.045,0.90,BASE,0.30,8)
            if i < 3:
                _box(yard,"MallaValla_%s_%d" % [s,i],
                    Vector3(x+1.89,0.42,float(s)*6.20),
                    Vector3(3.66,0.52,0.05),DARK,0.25)
        for i in range(3):
            var z: float = -5.55 + float(i)*5.55
            _cylinder(yard,"PosteLateral_%s_%d" % [s,i],
                Vector3(float(s)*6.42,0.45,z),0.05,0.9,BASE,0.30,8)
            if i < 2:
                _box(yard,"CierreLateral_%s_%d" % [s,i],
                    Vector3(float(s)*6.42,0.44,z+2.78),
                    Vector3(0.05,0.51,5.45),DARK,0.23)
    for i in range(5):
        _box(yard,"ContenedorLogistico_%d" % i,
            Vector3(-5.31 + float(i%2)*0.86,0.31,0.10 + float(int(i/2))*1.03),
            Vector3(0.70,0.62,0.82),
            color.darkened(0.28) if i==0 else Color("#687967"),0.17,i==0)
    for i in range(3):
        _box(yard,"MacetaHormigon_%d" % i,
            Vector3(-5.64+float(i)*0.95,0.19,-1.40),
            Vector3(0.70,0.35,0.55),CONCRETE)
        _sphere(yard,"Arbusto_%d" % i,
            Vector3(-5.64+float(i)*0.95,0.52,-1.40),
            Vector3(0.55,0.58,0.49),Color("#38644d"))
    if level >= 2:
        for i in range(2):
            _box(yard,"ModuloComunicaciones_%d" % i,
                Vector3(4.8,0.54,-1.82+float(i)*1.15),
                Vector3(1.08,0.99,0.91),BASE)
            _box(yard,"IndicadorModulo_%d" % i,
                Vector3(4.8,0.90,-2.31+float(i)*1.15),
                Vector3(0.60,0.12,0.045),color,0.14,true)

static func _building(parent: Node3D, level: int, color: Color) -> void:
    var structure := _group(parent,"EstructuraPrincipal")
    var roof_y: float = 2.87 + float(level-1)*0.91
    _box(structure,"BloqueDeMando",Vector3(0,roof_y*0.5,0.25),
        Vector3(5.82,roof_y,5.12),WALL)
    _box(structure,"FajaHorizontal",Vector3(0,0.36,-2.38),
        Vector3(5.98,0.24,0.20),BASE)
    _box(structure,"CoronamientoDeTecho",Vector3(0,roof_y+0.08,0.25),
        Vector3(6.13,0.21,5.39),ROOF,0.30)
    _box(structure,"FranjaFaccionSuperior",Vector3(0,roof_y-0.19,-2.39),
        Vector3(5.94,0.35,0.12),color,0.26,true)
    _box(structure,"GaleriaLateralIzquierda",Vector3(-4.06,1.10,0.35),
        Vector3(2.30,2.20,4.16),CONCRETE)
    _box(structure,"GaleriaLateralDerecha",Vector3(4.06,1.10,0.35),
        Vector3(2.30,2.20,4.16),CONCRETE)
    for side in [-1,1]:
        var x: float = float(side)*4.06
        _box(structure,"TechoAla%s" % side,Vector3(x,2.28,0.35),
            Vector3(2.52,0.18,4.36),ROOF,0.25)
        _box(structure,"BandaAla%s" % side,Vector3(x,2.10,-1.80),
            Vector3(2.43,0.24,0.10),color,0.22,true)
        for i in range(3):
            _box(structure,"VentanaAla%s_%d" % [side,i],
                Vector3(x-0.78+float(i)*0.77,1.31,-1.83),
                Vector3(0.46,0.56,0.05),GLASS,0.35)
    # Atrio frontal y entrada con profundidad.
    _box(structure,"PorticoAcceso",Vector3(0,1.05,-2.90),
        Vector3(3.18,2.10,1.48),CONCRETE)
    _box(structure,"TechoDelPortico",Vector3(0,2.23,-2.93),
        Vector3(3.62,0.23,1.76),color,0.26,true)
    _box(structure,"PuertaDeSeguridad",Vector3(0,0.94,-3.685),
        Vector3(1.58,1.77,0.07),DARK,0.37)
    _box(structure,"CristalPuerta",Vector3(0,1.14,-3.726),
        Vector3(1.16,0.86,0.027),GLASS,0.30)
    _box(structure,"DintelConIdentidad",Vector3(0,1.96,-3.748),
        Vector3(1.96,0.21,0.11),color,0.20,true)
    for s in [-1,1]:
        _box(structure,"PilarPortico_%s" % s,
            Vector3(float(s)*1.44,1.10,-3.55),
            Vector3(0.22,2.17,0.32),BASE,0.20)
    for i in range(3):
        _box(structure,"EscalonEntrada_%d" % i,
            Vector3(0,0.10+0.13*float(i),-4.36+0.27*float(i)),
            Vector3(2.72,0.13,0.45),LIGHT)
    _windows(structure,level,roof_y)
    # Volumenes tecnicos, rejillas y equipos sobre el techo.
    _box(structure,"SalaDeServidoresEnCubierta",
        Vector3(-0.15,roof_y+0.57,1.55),
        Vector3(1.32,0.96,1.47),BASE)
    _box(structure,"CubiertaServidores",
        Vector3(-0.15,roof_y+1.10,1.55),
        Vector3(1.50,0.12,1.65),ROOF)
    for i in range(5):
        _box(structure,"RejillaVentilacion_%d" % i,
            Vector3(-0.60+float(i)*0.22,roof_y+0.60,0.792),
            Vector3(0.14,0.28,0.033),DARK,0.30)
    _radar(structure,roof_y,level)
    _control_tower(structure,color,level,roof_y)
    _antenna(structure,"AntenaDeMando",Vector3(2.30,roof_y+0.15,1.61),
        1.32+float(level-1)*0.40)
    if level >= 2:
        _solar(structure,2 if level==2 else 3,roof_y+0.23)
    if level == 3:
        _sphere(structure,"RadomoSuperior",Vector3(0.16,roof_y+1.95,0.34),
            Vector3(1.42,1.42,1.42),Color("#dde1dc"))
        _cylinder(structure,"BaseDeRadomo",Vector3(0.16,roof_y+1.18,0.34),
            0.73,0.27,BASE,0.36,16)
        _box(structure,"AlaTecnicaDeNivel3",Vector3(-3.64,2.86,1.52),
            Vector3(1.56,1.30,1.72),BASE)
        _box(structure,"CoronamientoNivel3",Vector3(-3.64,3.55,1.52),
            Vector3(1.77,0.16,1.93),color,0.17,true)
    _helipad(parent,color,level)

static func _damaged(parent: Node3D, level: int) -> void:
    var damage := _group(parent,"DanosVisibles")
    _box(damage,"PanelChamuscadoFrontal",
        Vector3(-2.09,1.35,-2.48),Vector3(1.07,0.84,0.04),SOOT)
    _box(damage,"CristalRoto",
        Vector3(1.30,1.37,-2.49),Vector3(0.50,0.37,0.045),SOOT,
        0.20,false,Vector3(0,0,17))
    _box(damage,"LosaDeTechoCaida",
        Vector3(-3.58,0.22,-4.75),Vector3(1.54,0.18,0.93),CONCRETE,
        0.05,false,Vector3(8,18,15))
    _box(damage,"VigaDesprendida",
        Vector3(3.32,0.37,-4.30),Vector3(0.16,0.18,1.93),DARK,
        0.31,false,Vector3(0,35,22))
    var smoke := Color(0.15,0.19,0.19,0.40)
    _sphere(damage,"HumoDeIncendio1",Vector3(-1.75,2.95 + float(level-1)*0.60,0.38),
        Vector3(0.86,1.10,0.74),smoke)
    _sphere(damage,"HumoDeIncendio2",Vector3(-1.45,3.52 + float(level-1)*0.60,0.52),
        Vector3(0.96,0.81,0.88),smoke)
    for i in range(5):
        _box(damage,"EscombrosFrente_%d" % i,
            Vector3(-2.25+float(i)*0.37,0.17,-4.31),
            Vector3(0.32,0.24,0.42),BASE.darkened(0.26),0.05,
            false,Vector3(float(i)*17.0,float(i)*19.0,float(i)*8.0))

static func _destroyed(parent: Node3D, color: Color) -> void:
    # Ruinas reales que ocupan el mismo patio; NO un edificio sano oscurecido.
    _box(parent,"CimientosDestruidos",Vector3(0,0.04,0),
        Vector3(13.60,0.20,12.80),ASPHALT)
    _box(parent,"PlataformaDerrumbada",Vector3(0,0.20,0),
        Vector3(7.05,0.26,6.65),CONCRETE.darkened(0.22))
    for i in range(28):
        var col: int = i%7
        var row: int = int(i/7)
        var x: float = -3.20+float(col)*0.98
        var z: float = -2.11+float(row)*1.26
        var height: float = 0.16+float((i*11)%7)*0.16
        _box(parent,"Escombro_%02d" % i,
            Vector3(x,0.28+height*0.5,z),
            Vector3(0.72,height,0.72),SOOT if i%5==0 else WALL.darkened(0.12),
            0.03,false,Vector3(float((i*13)%28),float((i*29)%65),float((i*7)%25)))
    for i in range(4):
        var side: float = -1.0 if i%2==0 else 1.0
        _box(parent,"ColumnaFracturada_%d" % i,
            Vector3(side*(1.30+float(int(i/2))*1.11),0.99,0.22),
            Vector3(0.42,1.76,0.43),CONCRETE.darkened(0.35),
            0.06,false,Vector3(float(i)*13.0,0,float(i)*7.0))
    _box(parent,"PlacaIdentidadDesplomada",Vector3(0,0.55,-3.15),
        Vector3(2.12,0.16,0.74),color.darkened(0.40),0.08,true,
        Vector3(18,0,14))
    _sphere(parent,"HumoRuinas1",Vector3(-1.30,1.28,0.20),
        Vector3(1.36,1.44,1.24),Color(0.16,0.18,0.19,0.38))
    _sphere(parent,"HumoRuinas2",Vector3(-1.00,2.08,0.39),
        Vector3(1.19,1.12,1.17),Color(0.15,0.18,0.19,0.24))

static func paintable_count(node: Node) -> int:
    var count: int = 1 if node.has_meta("tarvoka_faction_panel") else 0
    for child in node.get_children():
        count += paintable_count(child)
    return count

static func build(level: int = 1, faction: int = 0,
        condition: String = "operativo", finish_enabled: bool = true) -> Node3D:
    if not valid_spec(level,faction,condition):
        return null
    var model := Node3D.new()
    model.name = "CuartelGeneral3D"
    model.set_meta("tarvoka_building_kind","headquarters")
    model.set_meta("visual_level",level)
    model.set_meta("visual_faction",faction)
    model.set_meta("visual_condition",condition)
    model.set_meta("visual_only",true)
    var accent: Color = Style.faction_color(faction)
    if condition == "destruido":
        _destroyed(model,accent)
    else:
        _yard(model,accent,level)
        _building(model,level,accent)
        if condition == "danado":
            _damaged(model,level)
        if condition == "capturado":
            # La faccion pasada es el propietario NUEVO: evita confundir el
            # acabado de captura con un cambio de reglas de control territorial.
            var marker := _group(model,"MarcaDeCaptura")
            _box(marker,"FranjaCambioDeControl",
                Vector3(0,0.13,-5.89),Vector3(2.30,0.05,0.16),
                accent,0.16,true)
    if finish_enabled:
        Finish.apply(model,level,accent,condition)
    return model
