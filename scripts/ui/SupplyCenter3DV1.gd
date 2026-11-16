extends RefCounted
class_name TarvokaSupplyCenter3DV1

# TARVOKA Centro de Suministros: original, native Godot 4.3 3D prototype.
# Strictly VISUAL: existing supply trucks and logistics rules remain untouched.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME: String="CentroDeSuministrosArquitecturaV1"
const DAMAGE_STAGES=[
    "Operativo · depósitos y zona de carga",
    "Leve · cubierta y señalización",
    "Medio · portón y cubierta dañados",
    "Crítico · instalaciones parcialmente colapsadas",
    "Destruido · únicamente ruinas"
]
const CONCRETE=Color("#a9b4b0")
const REINFORCED=Color("#77888c")
const FLOOR=Color("#58656b")
const STEEL=Color("#4f6971")
const GALVANIZED=Color("#9babaa")
const DARK=Color("#263840")
const ROOF=Color("#556a71")
const AMMO=Color("#747961")
const FUEL=Color("#657e80")
const WARNING=Color("#e5b84d")
const OXIDE=Color("#986956")
const CHAR=Color("#35393b")
const GLASS=Color("#4b737d")

static var _mat_cache: Dictionary={}
static var _box_cache: Dictionary={}

static func valid_spec(level: int,faction: int,damage: int) -> bool:
    return level in [1,2,3] and faction>=0 and faction<Style.FACTIONS.size() and damage in [0,1,2,3,4]

static func _mat(color: Color,metallic: float=0.12) -> StandardMaterial3D:
    var key: String="%s:%.2f" % [color.to_html(),metallic]
    if _mat_cache.has(key):
        return _mat_cache[key] as StandardMaterial3D
    var result:=StandardMaterial3D.new()
    result.albedo_color=color
    result.metallic=metallic
    result.roughness=0.55 if metallic>0.3 else 0.85
    _mat_cache[key]=result
    return result

static func _group(parent: Node3D,name: String) -> Node3D:
    var node:=Node3D.new()
    node.name=name
    parent.add_child(node)
    return node

static func _box(parent: Node3D,name: String,
        at: Vector3,size: Vector3,color: Color,
        metallic: float=0.10,rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var key: String="%.3f-%.3f-%.3f" % [size.x,size.y,size.z]
    if not _box_cache.has(key):
        var mesh:=BoxMesh.new()
        mesh.size=size
        _box_cache[key]=mesh
    var model:=MeshInstance3D.new()
    model.name=name
    model.mesh=_box_cache[key] as BoxMesh
    model.position=at
    model.rotation_degrees=rotation
    model.material_override=_mat(color,metallic)
    parent.add_child(model)
    return model

static func _cylinder(parent: Node3D,name: String,
        at: Vector3,radius: float,height: float,color: Color,
        metallic: float=0.36) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=18
    var model:=MeshInstance3D.new()
    model.name=name
    model.mesh=mesh
    model.position=at
    model.material_override=_mat(color,metallic)
    parent.add_child(model)
    return model

static func _beam(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> void:
    var axis: Vector3=b-a
    if axis.length()<0.002:
        return
    var mesh:=_cylinder(parent,name,(a+b)*0.5,
        radius,axis.length(),color,0.42)
    mesh.basis=Basis(Quaternion(Vector3.UP,axis.normalized()))

static func _foundation(root: Node3D,damage: int,accent: Color) -> void:
    var ground:=_group(root,"PatioDeLogisticaYConcreto")
    _box(ground,"PlataformaBaseSuministros",
        Vector3(0,-0.28,0),Vector3(16.2,0.50,11.4),REINFORCED)
    _box(ground,"CalzadaCamionesLogisticos",
        Vector3(-0.10,0.004,-3.65),Vector3(8.9,0.055,3.12),FLOOR)
    for lane in [-1,1]:
        _box(ground,"CarrilCarga_%s" % lane,
            Vector3(float(lane)*1.78,0.040,-3.55),
            Vector3(0.095,0.018,2.75),
            OXIDE if damage>=3 else WARNING)
    if damage==4:
        for i in range(7):
            _box(ground,"EscombrosDeposito_%02d" % i,
                Vector3(-6.15+float(i)*1.95,0.12,
                    -1.36+float(i%3)*1.74),
                Vector3(0.34+float(i%2)*0.25,0.16,0.50),
                CHAR if i%2==0 else OXIDE,0.12,
                Vector3(9,13*float(i),8*float(i)))
        return
    _box(ground,"MuelleCargaIzquierdo",
        Vector3(-1.74,0.21,-2.29),
        Vector3(3.18,0.39,1.48),CONCRETE)
    _box(ground,"MuelleCargaDerecho",
        Vector3(1.74,0.21,-2.29),
        Vector3(3.18,0.39,1.48),CONCRETE)
    _box(ground,"MarcaFaccionPatio",
        Vector3(3.93,0.048,-3.62),
        Vector3(0.10,0.012,1.72),accent,0.18)

static func _warehouse(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var walls:=_group(root,"AlmacenCentralProtegido")
    _box(walls,"MuroPosteriorCerrado",
        Vector3(0,1.94,3.02),Vector3(7.60,3.84,0.32),
        CONCRETE if damage<=2 else OXIDE)
    _box(walls,"MuroLateralIzquierdo",
        Vector3(-3.76,1.94,0.45),
        Vector3(0.34,3.83,5.55),
        CONCRETE if damage<=2 else OXIDE)
    if damage<=2:
        _box(walls,"MuroLateralDerecho",
            Vector3(3.76,1.94,0.45),
            Vector3(0.34,3.83,5.55),CONCRETE)
    else:
        _box(walls,"MuroDerechoFragmentado",
            Vector3(3.76,0.83,1.57),
            Vector3(0.36,1.62,3.10),OXIDE,0.10,
            Vector3(0,0,7))
    for index in range(3):
        var x: float=-3.70+float(index)*3.70
        _box(walls,"ColumnaFachadaCarga_%d" % index,
            Vector3(x,1.87,-2.30),Vector3(0.39,3.72,0.46),
            CONCRETE if damage<=2 else OXIDE)
    if damage<=2:
        _box(walls,"DintelFachadaCarga",
            Vector3(0,3.74,-2.30),
            Vector3(7.48,0.32,0.53),STEEL,0.45)
    else:
        _box(walls,"DintelFachadaPartido",
            Vector3(-1.61,3.53,-2.30),
            Vector3(3.50,0.32,0.48),OXIDE,0.27,
            Vector3(0,0,-9))
    var roof:=_group(root,"CubiertaAlmacenCentral")
    for i in range(5):
        if damage==1 and i==1:
            continue
        if damage==2 and i in [1,3]:
            continue
        if damage==3 and i in [0,1,2,4]:
            continue
        _box(roof,"PanelTechoDeposito_%02d" % i,
            Vector3(-2.96+float(i)*1.48,4.07,0.37),
            Vector3(1.44,0.16,5.62),
            ROOF if damage<=1 else OXIDE,0.34)
    for index in range(4):
        if damage>=3 and index>=2:
            continue
        _box(roof,"VigaCubiertaDeposito_%d" % index,
            Vector3(-2.76+float(index)*1.84,3.92,0.39),
            Vector3(0.13,0.22,5.66),
            STEEL if damage<=2 else OXIDE,0.50)
    if damage<=1:
        _box(walls,"LetreroIdentidadFaccion",
            Vector3(0,3.51,-2.63),
            Vector3(2.50,0.23,0.06),accent)
    if level>=2 and damage<=2:
        _box(walls,"OficinaControlLogistico",
            Vector3(-3.97,2.38,2.16),
            Vector3(0.87,1.56,1.55),STEEL,0.28)
        _box(walls,"CristalControlLogistico",
            Vector3(-3.48,2.45,2.16),
            Vector3(0.055,0.70,1.37),GLASS,0.19)
    if level==3 and damage<=1:
        for i in range(2):
            _cylinder(roof,"ExtractorSuperior_%d" % i,
                Vector3(-1.65+float(i)*3.3,4.37,1.22),
                0.33,0.48,GALVANIZED)
            _box(roof,"TapaExtractor_%d" % i,
                Vector3(-1.65+float(i)*3.3,4.64,1.22),
                Vector3(0.58,0.06,0.58),DARK)

static func _loading_bays(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var bays:=_group(root,"DosAndenesCargaCamiones")
    for bay in range(2):
        var x: float=-1.84+float(bay)*3.68
        if damage<2 or (damage==2 and bay==0):
            for part in range(6):
                _box(bays,"PortonEnrolladoCarga_%d_%d" % [bay,part],
                    Vector3(x,0.45+float(part)*0.45,-2.22),
                    Vector3(3.19,0.42,0.09),
                    GALVANIZED if damage==0 else REINFORCED,0.34)
            for side in [-1,1]:
                _box(bays,"GuiaVerticalPorton_%d_%s" % [bay,side],
                    Vector3(x+float(side)*1.66,1.65,-2.22),
                    Vector3(0.10,3.06,0.15),DARK,0.26)
        else:
            _box(bays,"PortonEnrolladoCaido_%d" % bay,
                Vector3(x,0.25,-2.04),
                Vector3(3.08,0.29,0.26),OXIDE,0.19,
                Vector3(0,0,10))
        if damage<3:
            _box(bays,"PlataformaCargaInterior_%d" % bay,
                Vector3(x,0.18,0.12),
                Vector3(3.15,0.29,3.25),FLOOR,0.12)
            _box(bays,"BandaDeSeguridad_%d" % bay,
                Vector3(x,0.335,-1.55),
                Vector3(3.08,0.021,0.13),WARNING,0.15)
    if level>=2 and damage<=1:
        _box(bays,"MaquinaLecturaCargamentos",
            Vector3(3.25,0.94,1.69),
            Vector3(0.45,1.70,0.62),STEEL,0.45)
        _box(bays,"PantallaControlCarga",
            Vector3(2.99,1.23,1.69),
            Vector3(0.030,0.38,0.43),GLASS,0.26)
    if level==3 and damage<=1:
        for side in [-1,1]:
            _box(bays,"RielPuenteCarga_%s" % side,
                Vector3(float(side)*3.28,3.36,0.37),
                Vector3(0.13,0.20,5.11),STEEL,0.45)
        _box(bays,"PuenteGruaDistribucion",
            Vector3(0,3.30,0.39),
            Vector3(6.80,0.24,0.31),accent,0.43)
        _beam(bays,"CableIzadoMercancias",
            Vector3(0,3.13,0.39),Vector3(0,2.22,0.39),
            0.035,STEEL)
        _box(bays,"GanchoCarga",
            Vector3(0,2.17,0.39),
            Vector3(0.23,0.18,0.17),DARK,0.37)

static func _fuel_yard(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var yard:=_group(root,"PatioCombustibleYConducciones")
    if damage==4:
        _box(yard,"CilindroDepositoRoto",
            Vector3(5.05,0.22,-1.40),
            Vector3(1.19,0.35,1.10),OXIDE,0.22,
            Vector3(8,20,25))
        return
    for i in range(2):
        if damage==3 and i==1:
            _box(yard,"RestosTanqueCombustible_1",
                Vector3(5.65,0.38,1.63),
                Vector3(1.61,0.36,1.62),OXIDE,0.16,
                Vector3(10,12,22))
            continue
        var z: float=-1.55+float(i)*3.12
        _cylinder(yard,"TanqueVerticalCombustible_%d" % i,
            Vector3(5.52,1.31,z),
            1.00,2.50,
            FUEL if damage<=1 else OXIDE)
        if damage<=2:
            _cylinder(yard,"AnilloTanqueCombustible_%d" % i,
                Vector3(5.52,2.57,z),
                1.035,0.090,GALVANIZED,0.48)
            if damage<=1:
                _box(yard,"BandaFaccionTanque_%d" % i,
                    Vector3(5.52,1.63,z-1.015),
                    Vector3(1.64,0.14,0.043),accent,0.10)
        _cylinder(yard,"BancadaTanque_%d" % i,
            Vector3(5.52,0.035,z),
            1.14,0.10,STEEL,0.42)
    if damage<=2:
        _beam(yard,"TuberiaDistribucionPrincipal",
            Vector3(4.38,0.35,-1.63),
            Vector3(4.38,0.35,1.58),
            0.09,STEEL)
        for i in range(2):
            _beam(yard,"TuberiaACombustible_%d" % i,
                Vector3(4.38,0.35,-1.55+float(i)*3.12),
                Vector3(5.12,0.35,-1.55+float(i)*3.12),
                0.068,STEEL)
    for i in range(4):
        if damage>=3 and i>=2:
            continue
        _box(yard,"PosteProteccionTanques_%d" % i,
            Vector3(4.05+float(i%2)*3.08,0.46,
                -2.70+float(i/2)*5.50),
            Vector3(0.13,0.92,0.13),
            WARNING if damage<=1 else OXIDE)
    if level>=3 and damage<=1:
        _box(yard,"PasarelaMantenimientoDepositos",
            Vector3(5.58,2.93,0.01),
            Vector3(2.78,0.13,1.07),STEEL,0.42)

static func _ammo_bunker(root: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var bunker:=_group(root,"BunkerMunicionesSegregado")
    if damage==4:
        _box(bunker,"EscombrosBunkerMuniciones",
            Vector3(-5.67,0.22,1.56),
            Vector3(1.65,0.35,1.21),CHAR,0.10,
            Vector3(0,13,16))
        return
    _box(bunker,"CimentacionBunker",
        Vector3(-5.54,0.23,1.21),
        Vector3(2.59,0.45,3.10),REINFORCED)
    if damage>=3:
        _box(bunker,"MuroBunkerRoto",
            Vector3(-6.34,0.80,1.50),
            Vector3(0.25,1.34,2.13),OXIDE,0.10,
            Vector3(0,0,-7))
        return
    _box(bunker,"MuroLateralBunker",
        Vector3(-6.76,1.35,1.30),
        Vector3(0.27,2.36,2.68),CONCRETE)
    _box(bunker,"MuroTraseroBunker",
        Vector3(-5.54,1.35,2.65),
        Vector3(2.48,2.36,0.28),CONCRETE)
    _box(bunker,"MuroFrontalBunker",
        Vector3(-5.54,1.34,-0.08),
        Vector3(2.48,2.33,0.25),CONCRETE)
    _box(bunker,"TechoReforzadoBunker",
        Vector3(-5.54,2.67,1.28),
        Vector3(2.68,0.33,2.95),
        AMMO if damage<=1 else OXIDE,0.16)
    _box(bunker,"PortonBlindadoBunker",
        Vector3(-4.33,1.32,0.92),
        Vector3(0.11,1.73,1.29),
        STEEL if damage<=1 else OXIDE,0.42)
    if level>=2 and damage<=1:
        _box(bunker,"VentanillaBlindadaControl",
            Vector3(-4.25,2.15,1.70),
            Vector3(0.045,0.32,0.37),GLASS,0.27)
    if damage<=1:
        _box(bunker,"MarcaIdentidadBunker",
            Vector3(-5.55,2.86,1.38),
            Vector3(1.31,0.032,0.40),accent,0.10)

static func build(level: int,faction: int,damage: int) -> Node3D:
    if not valid_spec(level,faction,damage):
        return null
    var root:=Node3D.new()
    root.name=STAGE_NAME
    root.set_meta("tarvoka_supply_center_v1",true)
    root.set_meta("tarvoka_building_kind","supply_center_visual")
    root.set_meta("visual_level",level)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("visual_only",true)
    var accent: Color=Style.faction_color(faction)
    _foundation(root,damage,accent)
    if damage<4:
        _warehouse(root,level,damage,accent)
        _loading_bays(root,level,damage,accent)
        _fuel_yard(root,level,damage,accent)
        _ammo_bunker(root,level,damage,accent)
    else:
        # Destroyed level has debris ONLY: no full tanks, doors or warehouse.
        _fuel_yard(root,level,damage,accent)
        _ammo_bunker(root,level,damage,accent)
    return root

static func count_meshes(node: Node) -> int:
    var count: int=1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count+=count_meshes(child)
    return count
