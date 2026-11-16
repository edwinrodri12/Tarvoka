extends RefCounted
class_name TarvokaNavalBase3DV1

# TARVOKA's first ORIGINAL naval base architecture in actual Godot 4.3.
# Harbour basin and U-shaped quays, slipway, command tower, naval hangar,
# crane, storage. Visual review only: no production, battle or capture rules.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Emblems=preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const STAGE_NAME: String="BaseNavalArquitecturaOriginalV1"
const DAMAGE_STAGES=["Intacta","Leve · antena y defensas",
    "Medio · grúa y cubierta","Crítico · torre y dique",
    "Destruida · ruinas navales"]
const WATER=Color("#194963")
const WATER_LIGHT=Color("#3e768a")
const QUAY=Color("#7e8c90")
const CONCRETE=Color("#b2bec0")
const STEEL=Color("#364f5d")
const ROOF=Color("#4c6675")
const IRON=Color("#253642")
const GLASS=Color("#396c81")
const GOLD=Color("#e7b753")
const RUST=Color("#7e6056")
static var _mesh_cache: Dictionary={}
static var _material_cache: Dictionary={}

static func valid_spec(level: int,faction: int,damage: int) -> bool:
    return level in [1,2,3] and faction>=0 and faction<Style.FACTIONS.size() and damage in [0,1,2,3,4]

static func _material(color: Color,metallic: float=0.1,
        transparent: bool=false) -> StandardMaterial3D:
    var key: String="%s/%0.2f/%s" % [
        color.to_html(true),metallic,str(transparent)]
    if _material_cache.has(key):
        return _material_cache[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metallic
    mat.roughness=0.79 if metallic<0.30 else 0.53
    if transparent:
        mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
    _material_cache[key]=mat
    return mat

static func _group(parent: Node3D,label: String,
        position: Vector3=Vector3.ZERO) -> Node3D:
    var node:=Node3D.new()
    node.name=label
    node.position=position
    parent.add_child(node)
    return node

static func _box(parent: Node3D,label: String,
        position: Vector3,size: Vector3,color: Color,
        metal: float=0.12,rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var key: String="box/%0.3f/%0.3f/%0.3f" % [size.x,size.y,size.z]
    if not _mesh_cache.has(key):
        var mesh:=BoxMesh.new()
        mesh.size=size
        _mesh_cache[key]=mesh
    var instance:=MeshInstance3D.new()
    instance.name=label
    instance.mesh=_mesh_cache[key] as Mesh
    instance.material_override=_material(color,metal)
    instance.position=position
    instance.rotation_degrees=rotation
    instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    parent.add_child(instance)
    return instance

static func _cylinder(parent: Node3D,label: String,
        at: Vector3,radius: float,length: float,color: Color,
        metal: float=0.22,segments: int=16,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var key: String="cyl/%0.3f/%0.3f/%d" % [radius,length,segments]
    if not _mesh_cache.has(key):
        var mesh:=CylinderMesh.new()
        mesh.top_radius=radius
        mesh.bottom_radius=radius
        mesh.height=length
        mesh.radial_segments=segments
        _mesh_cache[key]=mesh
    var instance:=MeshInstance3D.new()
    instance.name=label
    instance.mesh=_mesh_cache[key] as Mesh
    instance.position=at
    instance.rotation_degrees=rotation
    instance.material_override=_material(color,metal)
    parent.add_child(instance)
    return instance

static func _beam(parent: Node3D,label: String,
        start: Vector3,end: Vector3,radius: float,
        color: Color,metal: float=0.36) -> void:
    var delta: Vector3=end-start
    if delta.length()<0.001:
        return
    var shaft:=_cylinder(parent,label,(start+end)*0.5,
        radius,delta.length(),color,metal,10)
    shaft.basis=Basis(Quaternion(Vector3.UP,delta.normalized()))

static func _sea_and_piers(root: Node3D,accent: Color,damage: int) -> void:
    var harbour:=_group(root,"PuertoYEscollera")
    _box(harbour,"CimentacionIsometrica",
        Vector3(0,-0.35,0),Vector3(15.2,0.48,13.8),
        Color("#45545b"))
    _box(harbour,"AguaDarsenaConectadaAlMar",
        Vector3(-2.86,0.005,0),Vector3(8.55,0.055,10.7),
        WATER,0.19)
    for i in range(7):
        _box(harbour,"ReflejoOlas_%02d" % i,
            Vector3(-6.20+float(i)*0.88,0.041,-2.85+float(i%3)*2.74),
            Vector3(0.61,0.009,0.055),WATER_LIGHT,0.14)
    # Main eastern terminal apron, and two quays form a readable U-shaped
    # port silhouette. This is a real seawall, not a flat harbour picture.
    _box(harbour,"PatioLogisticoEnTierra",Vector3(4.77,0.17,0),
        Vector3(5.30,0.70,13.0),Color("#657378"))
    _box(harbour,"MuelleEsteDeCarga",Vector3(1.75,0.19,0),
        Vector3(0.88,0.76,10.65),QUAY)
    for sign in [-1,1]:
        if damage>=3 and sign==1:
            # Destroyed outer finger is visibly severed halfway along.
            _box(harbour,"MuellePartido_%s" % sign,
                Vector3(-0.34,0.17,4.85),
                Vector3(3.90,0.66,1.11),RUST)
            continue
        _box(harbour,"EspigonDeAtraque_%s" % sign,
            Vector3(-2.04,0.19,float(sign)*4.85),
            Vector3(7.55,0.75,1.10),QUAY)
        for i in range(4):
            var x: float=-5.05+float(i)*1.86
            _cylinder(harbour,"Bolardo_%s_%d" % [sign,i],
                Vector3(x,0.71,float(sign)*4.85),
                0.12,0.32,IRON,0.36,12)
        _box(harbour,"LuzSeguridadMuelle_%s" % sign,
            Vector3(-5.49,0.61,float(sign)*4.85),
            Vector3(0.16,0.12,0.16),
            Color("#e4c568") if sign==1 else Color("#5bc5cd"))
    for i in range(7):
        if damage>=3 and i in [2,3]:
            continue
        _box(harbour,"DefensaDeGomaMuelles_%02d" % i,
            Vector3(1.20,0.15,-4.10+float(i)*1.35),
            Vector3(0.23,0.38,0.50),IRON,0.1)
    _box(harbour,"LineaSeguridadMuelleEste",
        Vector3(1.82,0.592,0),
        Vector3(0.11,0.014,9.48),GOLD)
    _box(harbour,"FranjaFaccionPuerto",
        Vector3(6.97,0.54,0),
        Vector3(0.18,0.045,9.80),accent,0.18)

static func _naval_hangar(root: Node3D,accent: Color,
        level: int,damage: int) -> void:
    if damage==4:
        return
    var hangar:=_group(root,"HangarNavalTallerDeBuques",
        Vector3(4.56,0,-2.05))
    _box(hangar,"SoleraInteriorAstillero",Vector3(0,0.56,0),
        Vector3(3.95,0.12,4.50),Color("#596970"))
    for sign in [-1,1]:
        var x: float=float(sign)*1.76
        _box(hangar,"MuroLateralHangar_%s" % sign,
            Vector3(x,1.87,0),Vector3(0.18,2.70,4.58),CONCRETE)
    _box(hangar,"ParedPosteriorHangar",
        Vector3(0,1.80,2.23),Vector3(3.73,2.60,0.20),
        CONCRETE)
    _box(hangar,"DintelFrontalHangar",
        Vector3(0,3.16,-2.23),Vector3(3.81,0.25,0.23),STEEL,0.4)
    _box(hangar,"FranjaDeFaccionHangar",
        Vector3(0,3.34,-2.31),Vector3(3.72,0.14,0.10),
        accent,0.22)
    # Broken roof is represented by missing real panels, not smoke over
    # the intact building. A pitched two-sided covering with segmented bays.
    for i in range(10):
        if damage==2 and i in [4,5]:
            continue
        if damage==3 and i in [1,2,3,4,5,6]:
            continue
        var z: float=-2.10+float(i)*0.466
        for sign in [-1,1]:
            var x: float=float(sign)*0.90
            _box(hangar,"ChapaTejado_%d_%s" % [i,sign],
                Vector3(x,3.25,z),Vector3(2.05,0.14,0.51),
                ROOF if i%3!=0 else Color("#617582"),0.4,
                Vector3(0,0,float(sign)*-12))
    _box(hangar,"CaballeteRoof",Vector3(0,3.51,0),
        Vector3(0.22,0.20,4.60),STEEL,0.45)
    if damage<=1:
        for i in range(3):
            _box(hangar,"CompuertaTaller_%d" % i,
                Vector3(-1.22+float(i)*1.22,1.64,-2.36),
                Vector3(1.18,2.40,0.09),IRON,0.35)
            _box(hangar,"PerfilCompuertaTaller_%d" % i,
                Vector3(-1.22+float(i)*1.22,1.63,-2.41),
                Vector3(1.09,0.055,0.05),accent,0.26)
    elif damage==2:
        _box(hangar,"CompuertaTallerAbollada",
            Vector3(-1.15,1.62,-2.38),
            Vector3(1.20,2.42,0.12),STEEL,0.3,Vector3(0,0,11))
    else:
        _beam(hangar,"VigaPartidaSobreEntrada",
            Vector3(-1.62,2.56,-2.45),Vector3(0.85,1.45,-2.45),
            0.11,RUST)
    for side in [-1,1]:
        _box(hangar,"PilarFrente_%s" % side,
            Vector3(float(side)*1.81,1.93,-2.32),
            Vector3(0.21,2.81,0.21),STEEL,0.38)
    if level>=2:
        _box(hangar,"PanelTecnicoSolar",
            Vector3(-0.96,3.47,1.04),
            Vector3(1.02,0.04,0.67),Color("#284e65"),0.52)

static func _command_tower(root: Node3D,accent: Color,
        level: int,damage: int) -> void:
    if damage==4:
        return
    var tower:=_group(root,"TorreControlMaritimo",
        Vector3(5.54,0,3.37))
    var height: float=3.10+float(level-1)*0.35
    _box(tower,"FusteHormigonControl",
        Vector3(0,0.54+height*0.5,0),
        Vector3(1.36,height,1.42),CONCRETE,0.10)
    for i in [-1,1]:
        _box(tower,"NervioTorre_%s" % i,
            Vector3(float(i)*0.52,1.70,-0.75),
            Vector3(0.095,2.2,0.09),STEEL,0.39)
    if damage<3:
        _box(tower,"CabinaCristalControl",
            Vector3(0,height+0.90,0),
            Vector3(2.0,0.89,1.92),GLASS,0.35)
        _box(tower,"TechoCabinaControl",
            Vector3(0,height+1.43,0),
            Vector3(2.26,0.16,2.14),STEEL,0.39)
        _box(tower,"BandaFaccionCabina",
            Vector3(0,height+1.37,-1.09),
            Vector3(2.07,0.115,0.12),accent,0.2)
        _cylinder(tower,"MastilRadarMaritimo",
            Vector3(0,height+2.05,0),0.055,1.19,
            STEEL,0.47,10,
            Vector3(0,0,20) if damage==1 else Vector3.ZERO)
        if damage!=1:
            _box(tower,"AntenaRadarHorizontal",
                Vector3(0,height+2.68,0),
                Vector3(1.12,0.10,0.14),Color("#d7d9d3"),0.38)
        else:
            _box(tower,"AntenaRadarDoblada",
                Vector3(0.58,height+1.75,-0.37),
                Vector3(0.81,0.08,0.13),RUST,0.30,Vector3(0,0,29))
    else:
        _box(tower,"CabinaRotaControl",
            Vector3(0,height+0.55,0),
            Vector3(1.51,0.19,1.65),RUST,0.13,Vector3(0,0,13))
    if level>=2 and damage<=2:
        _box(tower,"BalizaDeNavegacionRoja",
            Vector3(0,height+2.91,0),
            Vector3(0.16,0.10,0.16),Color("#e55c4b"))

static func _crane(root: Node3D,damage: int) -> void:
    if damage>=4:
        return
    var crane:=_group(root,"GruaPortuariaDeCarga",
        Vector3(1.90,0,-2.50))
    _box(crane,"PlataformaGrua",Vector3(0,0.69,0),
        Vector3(1.38,0.23,1.35),IRON,0.31)
    _box(crane,"ColumnaGrua",Vector3(0,2.22,0),
        Vector3(0.29,2.91,0.33),STEEL,0.47)
    if damage>=2:
        _beam(crane,"PlumaDeGruaCaida",
            Vector3(0,3.22,0),Vector3(-2.12,1.42,-0.27),
            0.10,RUST)
        return
    _box(crane,"CabinaGrua",
        Vector3(0.26,3.67,0.31),
        Vector3(0.79,0.66,0.68),GLASS,0.26)
    _beam(crane,"PlumaGruaSobreDarsena",
        Vector3(0,4.03,0),Vector3(-4.35,4.61,0),
        0.105,STEEL)
    _beam(crane,"TensorGrua",Vector3(0,4.64,0),
        Vector3(-3.40,4.48,0),0.045,Color("#9caeae"))
    _beam(crane,"CableIzado",
        Vector3(-3.25,4.47,0),Vector3(-3.25,1.50,0),
        0.025,IRON)
    _box(crane,"GanchoGrua",Vector3(-3.25,1.44,0),
        Vector3(0.23,0.28,0.20),GOLD,0.23)

static func _naval_services(root: Node3D,accent: Color,
        level: int,damage: int) -> void:
    var services:=_group(root,"ServiciosYLogisticaNaval")
    _box(services,"CarrilAccesoInstalacion",
        Vector3(5.85,0.55,-0.25),
        Vector3(1.40,0.08,10.60),STEEL,0.10)
    for i in range(7):
        _box(services,"MarcaVialPuerto_%d" % i,
            Vector3(5.85,0.600,-4.71+float(i)*1.30),
            Vector3(0.085,0.013,0.38),GOLD)
    if damage>=4:
        _box(services,"CascotesHangarDestruido",
            Vector3(4.30,0.48,-2.25),
            Vector3(2.8,0.33,3.0),RUST,0.08,Vector3(0,7,13))
        _box(services,"TorreDerruida",
            Vector3(5.31,0.60,3.19),
            Vector3(2.1,0.36,1.38),STEEL,0.12,Vector3(0,0,17))
        _beam(services,"GruaArrancada",
            Vector3(1.84,0.60,-2.22),Vector3(-1.68,0.40,-3.19),
            0.17,RUST)
        return
    if level>=2:
        for i in range(2):
            _cylinder(services,"DepositoCombustibleNaval_%d" % i,
                Vector3(3.08+float(i)*1.16,1.21,4.95),
                0.43,1.26,CONCRETE,0.15,20)
            _box(services,"ValvulaDeposito_%d" % i,
                Vector3(3.08+float(i)*1.16,1.94,4.95),
                Vector3(0.31,0.12,0.31),IRON,0.35)
    if level==3:
        _box(services,"CentroLogisticoAvanzado",
            Vector3(3.46,1.12,1.68),
            Vector3(2.06,1.25,1.67),STEEL,0.18)
        _box(services,"FranjaCentroLogistico",
            Vector3(3.46,1.78,0.81),
            Vector3(1.87,0.12,0.10),accent,0.25)
    # Official approved shield on the hangar front: never redraw logo.
    if damage<4:
        var emblem_parent:=_group(services,"LetreroOficialEnFachada",
            Vector3(4.56,3.02,-4.50))
        _box(emblem_parent,"EscudoDeFaccionModular",
            Vector3.ZERO,Vector3(1.09,1.19,0.16),IRON,0.22)

static func build(level: int,faction: int,damage: int) -> Node3D:
    if not valid_spec(level,faction,damage):
        return null
    var base:=Node3D.new()
    base.name=STAGE_NAME
    base.set_meta("tarvoka_naval_base_v1",true)
    base.set_meta("tarvoka_building_kind","naval_base")
    base.set_meta("visual_level",level)
    base.set_meta("visual_faction",faction)
    base.set_meta("visual_damage_stage",damage)
    var accent: Color=Style.faction_color(faction)
    _sea_and_piers(base,accent,damage)
    _naval_hangar(base,accent,level,damage)
    _command_tower(base,accent,level,damage)
    _crane(base,damage)
    _naval_services(base,accent,level,damage)
    if damage<4:
        Emblems.apply(base,faction)
    return base

static func count_meshes(root: Node) -> int:
    if root==null:
        return 0
    var count: int=1 if root is MeshInstance3D else 0
    for child in root.get_children():
        count+=count_meshes(child)
    return count
