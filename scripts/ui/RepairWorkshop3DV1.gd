extends RefCounted
class_name TarvokaRepairWorkshop3DV1

# TARVOKA original armored-vehicle workshop: native Godot 4.3 meshes.
# First architectural prototype; never modifies turns, healing,
# construction, capture, save files or combat. Preview only.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="TallerMilitarV1Arquitectura"
const DAMAGE_STAGES=[
    "Operativo · completo",
    "Leve · señalización y cubierta",
    "Medio · portones y techo",
    "Crítico · estructura y elevador",
    "Destruido · cimentación y ruinas"
]
const CONCRETE=Color("#aeb8b6")
const SLAB=Color("#657477")
const STEEL=Color("#344d58")
const STEEL_LIGHT=Color("#81969d")
const DARK=Color("#1c303b")
const ROOF=Color("#465c66")
const GLASS=Color("#45697b")
const SAFETY=Color("#e0b45d")
const RUST=Color("#915f4e")
const CHAR=Color("#292b2d")
const FLOOR=Color("#606967")
static var _mat_cache: Dictionary={}
static var _box_cache: Dictionary={}

static func valid_spec(level: int,faction: int,damage: int) -> bool:
    return level in [1,2,3] and faction>=0 and faction<Style.FACTIONS.size() and damage in [0,1,2,3,4]

static func _mat(color: Color,metallic: float=0.12) -> StandardMaterial3D:
    var key: String="%s/%.2f" % [color.to_html(true),metallic]
    if _mat_cache.has(key):
        return _mat_cache[key] as StandardMaterial3D
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metallic
    material.roughness=0.54 if metallic>0.3 else 0.82
    _mat_cache[key]=material
    return material

static func _group(parent: Node3D,name: String,
        position: Vector3=Vector3.ZERO) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    n.position=position
    parent.add_child(n)
    return n

static func _box(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,tint: Color,metal: float=0.14,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var key: String="%.3f/%.3f/%.3f" % [size.x,size.y,size.z]
    if not _box_cache.has(key):
        var mesh:=BoxMesh.new()
        mesh.size=size
        _box_cache[key]=mesh
    var m:=MeshInstance3D.new()
    m.name=name
    m.mesh=_box_cache[key] as BoxMesh
    m.position=pos
    m.rotation_degrees=rotation
    m.material_override=_mat(tint,metal)
    parent.add_child(m)
    return m

static func _cylinder(parent: Node3D,name: String,
        pos: Vector3,radius: float,height: float,tint: Color,
        metal: float=0.36,segments: int=12) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    var result:=MeshInstance3D.new()
    result.name=name
    result.mesh=mesh
    result.position=pos
    result.material_override=_mat(tint,metal)
    parent.add_child(result)
    return result

static func _beam(parent: Node3D,name: String,
        start: Vector3,end: Vector3,radius: float,tint: Color) -> void:
    var d: Vector3=end-start
    if d.length()<0.001:
        return
    var part:=_cylinder(parent,name,(start+end)*0.5,
        radius,d.length(),tint)
    part.basis=Basis(Quaternion(Vector3.UP,d.normalized()))

static func _foundation(root: Node3D,damage: int,accent: Color) -> void:
    var base:=_group(root,"PatioYPlataforma")
    _box(base,"CimentacionCompleta",
        Vector3(0,-0.30,0),Vector3(11.2,0.52,10.2),SLAB)
    _box(base,"PavimentoOperativo",
        Vector3(0,0.005,-3.40),Vector3(9.5,0.05,3.12),FLOOR)
    for lane in [-1,1]:
        _box(base,"CarrilServicio_%s" % lane,
            Vector3(float(lane)*1.70,0.048,-3.32),
            Vector3(0.10,0.016,2.85),
            RUST if damage>=3 else SAFETY)
    if damage>=4:
        for i in range(5):
            _box(base,"FragmentoCimiento_%d" % i,
                Vector3(-3.9+float(i)*1.84,0.13,
                    -1.7+float(i%2)*3.0),
                Vector3(0.45+float(i%2)*0.20,0.18,0.62),
                CHAR if i%2==0 else RUST,0.10,
                Vector3(0,16*float(i),9*float(i)))
        return
    _box(base,"LineaSeguridadFrontal",
        Vector3(0,0.046,-3.12),Vector3(8.85,0.008,0.08),
        SAFETY if damage<3 else RUST)
    _box(base,"MarcaFaccionPavimento",
        Vector3(4.42,0.049,-3.33),
        Vector3(0.10,0.012,1.87),accent)

static func _walls(root: Node3D,level: int,damage: int) -> void:
    var walls:=_group(root,"EstructuraParedes")
    var tint: Color=CHAR if damage==3 else CONCRETE
    _box(walls,"ParedLateralIzquierda",
        Vector3(-4.00,1.77,0.27),Vector3(0.38,3.5,6.08),tint)
    if damage<3:
        _box(walls,"ParedLateralDerecha",
            Vector3(4.00,1.77,0.27),Vector3(0.38,3.5,6.08),CONCRETE)
    else:
        _box(walls,"ParedLateralDerechaRota",
            Vector3(4.0,0.78,1.5),Vector3(0.38,1.54,3.56),RUST,
            0.12,Vector3(0,0,-7))
    _box(walls,"ParedPosteriorCerrada",
        Vector3(0,1.77,3.15),Vector3(7.96,3.50,0.38),
        CONCRETE if damage<3 else RUST)
    # Two honest full-width service openings; concrete uprights support
    # the roof instead of a false uninterrupted front wall.
    for i in range(3):
        var x: float=-3.95+float(i)*3.95
        _box(walls,"PilarFachada_%d" % i,
            Vector3(x,1.77,-2.81),Vector3(0.40,3.52,0.45),
            CONCRETE if damage<=2 else RUST)
    if damage<=2:
        _box(walls,"DintelSuperiorFachada",
            Vector3(0,3.47,-2.81),Vector3(7.95,0.46,0.5),
            STEEL,0.42)
    else:
        _box(walls,"DintelFracturado",
            Vector3(-1.75,3.39,-2.81),
            Vector3(3.12,0.41,0.51),RUST,0.25,
            Vector3(0,0,-8))
    if level>=2 and damage<3:
        var offices:=_group(root,"OficinaDeSupervision")
        _box(offices,"OficinaSegundoNivel",
            Vector3(4.90,2.10,1.62),Vector3(1.65,1.90,2.50),STEEL)
        _box(offices,"CristalOficina",
            Vector3(4.04,2.26,1.62),Vector3(0.07,0.89,2.18),GLASS,0.25)
        _box(offices,"TechoOficina",
            Vector3(4.90,3.09,1.62),Vector3(1.88,0.13,2.66),STEEL_LIGHT)

static func _roof(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var roof:=_group(root,"CubiertaIndustrial")
    if damage==4:
        return
    for i in range(5):
        # Actual missing roof panels do NOT reappear in damaged versions.
        if damage==1 and i==1:
            continue
        if damage>=2 and i in [0,1,3]:
            continue
        _box(roof,"PanelTecho_%02d" % i,
            Vector3(-3.32+float(i)*1.66,3.67,0.26),
            Vector3(1.62,0.18,6.33),
            ROOF if damage<=1 else RUST,0.30)
    for i in range(4):
        if damage>=3 and i>=2:
            continue
        _box(roof,"VigaTransversalTecho_%d" % i,
            Vector3(-3.25+float(i)*2.14,3.52,0.26),
            Vector3(0.14,0.22,6.38),STEEL if damage<3 else RUST,0.50)
    if damage<=1:
        _box(roof,"PerfilColorFaccionTecho",
            Vector3(0,3.81,-2.66),Vector3(7.0,0.045,0.14),accent)
    if level>=3 and damage<=2:
        for i in range(2):
            _cylinder(roof,"ExtractorAire_%d" % i,
                Vector3(-1.90+float(i)*3.8,3.91,1.32),
                0.35,0.40,STEEL_LIGHT)
            _box(roof,"ParrillaExtractor_%d" % i,
                Vector3(-1.90+float(i)*3.8,4.13,1.32),
                Vector3(0.62,0.06,0.62),DARK)

static func _service_bays(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    if damage==4:
        return
    var bays:=_group(root,"DosBahiasDeMantenimiento")
    for bay in range(2):
        var x: float=-1.98+float(bay)*3.96
        if damage<=1 or (damage==2 and bay==0):
            # Distinct sectional panels and side rails, NOT solid fake doors.
            for p in range(6):
                _box(bays,"PortonSeccional_%d_%d" % [bay,p],
                    Vector3(x,0.35+float(p)*0.42,-2.575),
                    Vector3(3.23,0.40,0.09),
                    STEEL_LIGHT if damage==0 else Color("#596b71"),0.42)
            for side in [-1,1]:
                _box(bays,"GuiaPorton_%d_%s" % [bay,side],
                    Vector3(x+float(side)*1.68,1.44,-2.57),
                    Vector3(0.08,2.65,0.16),DARK,0.30)
        else:
            # Open, damaged workshop bay: realistic internal void.
            _box(bays,"PortonColapsado_%d" % bay,
                Vector3(x,0.25,-2.39),
                Vector3(2.88,0.31,0.24),RUST,0.22,
                Vector3(0,0,12))
        _box(bays,"BaseElevador_%d" % bay,
            Vector3(x,0.13,0.32),
            Vector3(3.30,0.13,3.75),
            FLOOR if damage<3 else RUST)
        for side in [-1,1]:
            _box(bays,"PlataformaHidraulica_%d_%s" % [bay,side],
                Vector3(x+float(side)*0.95,0.25,0.32),
                Vector3(0.28,0.14,3.04),
                STEEL_LIGHT if damage<3 else RUST,0.48)
        if damage<3:
            for side in [-1,1]:
                _cylinder(bays,"PistonElevador_%d_%s" % [bay,side],
                    Vector3(x+float(side)*1.45,0.54,1.35),
                    0.09,0.98,STEEL_LIGHT)
    if level>=2 and damage<=2:
        _box(bays,"ArmarioHerramientas",
            Vector3(3.47,0.83,1.58),Vector3(0.48,1.52,1.22),
            accent,0.32)
        for i in range(3):
            _box(bays,"CajonHerramientas_%d" % i,
                Vector3(3.19,0.43+float(i)*0.32,1.58),
                Vector3(0.025,0.03,0.98),STEEL_LIGHT,0.35)
    if level>=3 and damage<=1:
        var overhead:=_group(root,"PuenteGruaDeTaller")
        for side in [-1,1]:
            _box(overhead,"RielGrua_%s" % side,
                Vector3(float(side)*3.48,2.84,0.28),
                Vector3(0.15,0.22,5.45),STEEL,0.55)
        _box(overhead,"VigaPuenteGrua",
            Vector3(0,2.80,0.21),Vector3(7.10,0.24,0.30),
            accent,0.47)
        _beam(overhead,"CableGanchoGrua",
            Vector3(0,2.66,0.21),Vector3(0,1.82,0.21),
            0.045,STEEL_LIGHT)
        _box(overhead,"GanchoGrua",
            Vector3(0,1.78,0.21),Vector3(0.32,0.23,0.19),DARK,0.47)

static func _exterior(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    if damage>=4:
        return
    var equipment:=_group(root,"ExteriorYSeguridad")
    _box(equipment,"PlacaFaccionFachada",
        Vector3(0,3.33,-3.11),
        Vector3(1.69,0.24,0.07),
        accent if damage<=1 else RUST)
    if damage<=1:
        for i in range(3):
            _box(equipment,"ReflectorFachada_%d" % i,
                Vector3(-3.40+float(i)*3.40,3.34,-3.22),
                Vector3(0.24,0.15,0.15),SAFETY,0.12)
    if damage>=2:
        _box(equipment,"RestosSeñalización",
            Vector3(0.79,0.21,-3.22),
            Vector3(0.54,0.14,0.38),RUST,0.12,
            Vector3(0,0,16))
    if level>=2 and damage<3:
        _box(equipment,"TanqueAceiteReciclaje",
            Vector3(4.60,0.66,-1.40),
            Vector3(0.88,1.28,0.80),STEEL,0.39)

static func build(level: int,faction: int,damage: int) -> Node3D:
    if not valid_spec(level,faction,damage):
        return null
    var root:=Node3D.new()
    root.name=STAGE_NAME
    root.set_meta("tarvoka_workshop_v1",true)
    root.set_meta("tarvoka_building_kind","repair_workshop")
    root.set_meta("visual_level",level)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("visual_only",true)
    var accent: Color=Style.faction_color(faction)
    _foundation(root,damage,accent)
    if damage<4:
        _walls(root,level,damage)
        _roof(root,level,damage,accent)
        _service_bays(root,level,damage,accent)
        _exterior(root,level,damage,accent)
    return root

static func count_meshes(node: Node) -> int:
    var count: int=1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count+=count_meshes(child)
    return count
