extends RefCounted
class_name TarvokaPowerPlant3DV1

# TARVOKA: CENTRAL ELECTRICA -- editable native Godot 4.3 meshes.
# V1 design ONLY: three architectural tiers, eight faction palettes,
# and five separately sculpted damage states D0-D4.
# Not a repair workshop, no gameplay energy/income, production, capture,
# buffs, collision, AI, navigation or balance modifications.
const TITLE="Central eléctrica"
const STAGE="CentralElectricaV1ArteNativo"
const LEVEL_NAMES=["Puesto energético","Subestación regional","Central industrial"]
const DAMAGE_NAMES=["Intacta","Daños leves","Daños moderados","Daños críticos","Destruida"]
const FACTION_PALETTE=[
    "#d2a25e","#7aa6ba","#ac7da5","#86a978",
    "#c86e65","#d3bb6e","#788bb8","#9aaca9"
]
const CONCRETE=Color("#7d8585")
const DARK_CONCRETE=Color("#515b60")
const STEEL=Color("#aab8bc")
const GUNMETAL=Color("#34434a")
const COOLING=Color("#80989d")
const GLASS=Color("#527c8e")
const COPPER=Color("#aa7554")
const HAZARD=Color("#d5af5c")
const CHAR=Color("#353434")
static var _materials: Dictionary={}

static func _material(c: Color,metal: float=0.0,rough: float=0.76) -> StandardMaterial3D:
    var key: String="%s-%s-%s" % [c.to_html(),str(metal),str(rough)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metal
    m.roughness=rough
    _materials[key]=m
    return m

static func _node(parent: Node3D,label: String,at: Vector3=Vector3.ZERO) -> Node3D:
    var n:=Node3D.new()
    n.name=label
    n.position=at
    parent.add_child(n)
    return n

static func _box(parent: Node3D,label: String,at: Vector3,extent: Vector3,
        color: Color,metal: float=0.0,rough: float=0.75,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=BoxMesh.new()
    mesh.size=extent
    n.mesh=mesh
    n.material_override=_material(color,metal,rough)
    n.position=at
    n.rotation_degrees=rotation
    parent.add_child(n)
    return n

static func _cylinder(parent: Node3D,label: String,at: Vector3,
        radius: float,length: float,color: Color,
        metal: float=0.0,rough: float=0.70,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=16
    n.mesh=mesh
    n.material_override=_material(color,metal,rough)
    n.position=at
    n.rotation_degrees=rotation
    parent.add_child(n)
    return n

static func _transformer(parent: Node3D,label: String,at: Vector3,
        scale_factor: float,damage: int,accent: Color) -> void:
    var site:=_node(parent,label,at)
    site.scale=Vector3.ONE*scale_factor
    _box(site,"Pedestal",Vector3(0,0.23,0),
        Vector3(1.48,0.44,1.06),DARK_CONCRETE)
    _box(site,"CubaTransformador",Vector3(0,0.90,0),
        Vector3(1.26,0.89,0.89),
        GUNMETAL if damage>=3 else COOLING,0.47,0.57)
    _box(site,"BandasPinturaFaccion",Vector3(0,1.17,-0.457),
        Vector3(0.68,0.13,0.016),accent,0.22,0.48)
    for fin in range(5):
        _box(site,"Disipador_%d" % fin,
            Vector3(-0.47+0.23*float(fin),0.91,0.49),
            Vector3(0.105,0.68,0.10),
            GUNMETAL if damage>=3 else STEEL,0.57,0.49)
    for coil in [-1,0,1]:
        if damage>=3 and coil==0:
            continue
        var sign: float=float(coil)
        _cylinder(site,"Aislador_%s" % coil,
            Vector3(sign*0.36,1.65,0),
            0.107,0.61,COPPER,0.26,0.64)
        _cylinder(site,"Capuchon_%s" % coil,
            Vector3(sign*0.36,1.99,0),
            0.14,0.055,GUNMETAL,0.45,0.44)

static func _gantry(parent: Node3D,label: String,x: float,z: float,
        elevation: float,damage: int) -> void:
    var g:=_node(parent,label,Vector3(x,0,z))
    for side in [-1,1]:
        var sx: float=float(side)*1.14
        _box(g,"Columna_%s" % side,Vector3(sx,elevation*0.5,0),
            Vector3(0.14,elevation,0.14),
            GUNMETAL if damage>=3 else STEEL,0.67,0.54,
            Vector3(0,0,float(side)*(6.0 if damage==3 else 0.0)))
    if damage<=2:
        _box(g,"VigaSuperior",Vector3(0,elevation,0),
            Vector3(2.54,0.15,0.20),STEEL,0.73,0.48)
        for index in range(3):
            _cylinder(g,"AisladorTrifasico_%d" % index,
                Vector3(-0.70+float(index)*0.70,elevation+0.27,0),
                0.090,0.45,COPPER,0.12,0.69)

static func _ruin(parent: Node3D,damage: int,size: float) -> void:
    var pieces: int=4 if damage==2 else 8 if damage==3 else 15
    for i in range(pieces):
        var angle: float=float(i)*TAU/float(pieces)
        var radius: float=0.9+float((i*7)%11)*0.30
        var fragment: Vector3=Vector3(
            cos(angle)*radius,0.16+float(i%3)*0.09,
            sin(angle)*radius)
        var slab: Vector3=Vector3(
            size*(0.23+float(i%3)*0.08),
            0.18+float(i%4)*0.08,
            size*(0.21+float(i%5)*0.06))
        _box(parent,"EscombroConcreto_%02d" % i,fragment,slab,
            CONCRETE if i%3 else CHAR,0.04,0.96,
            Vector3(0,float(i*39%180),float((i%5)-2)*11.0))
        if i%3==0:
            _box(parent,"PerfilMetalRetorcido_%02d" % i,
                fragment+Vector3(0,0.18,0),Vector3(0.09,0.34,0.88),
                GUNMETAL,0.68,0.69,
                Vector3(25,float(i*31),-15))

static func build(level: int,faction: int=-1,damage: int=0) -> Node3D:
    if level<1 or level>3 or faction< -1 or faction>7 or (
            damage<0 or damage>4):
        return null
    var accent: Color=Color(FACTION_PALETTE[faction]) if faction>=0 else STEEL
    var model:=Node3D.new()
    model.name="CentralElectrica_N%d_F%d_D%d" % [level,faction,damage]
    var root:=_node(model,STAGE)
    var footprint: float=8.0 if level==1 else 11.5 if level==2 else 15.5
    _box(root,"BaseHormigon",Vector3(0,-0.18,0),
        Vector3(footprint,0.36,footprint),DARK_CONCRETE,0.0,0.93)
    _box(root,"PlataformaTecnica",Vector3(0,0.045,0),
        Vector3(footprint-0.8,0.09,footprint-0.8),CONCRETE)
    var chamber_width: float=3.80 if level==1 else 5.80 if level==2 else 8.00
    var chamber_height: float=2.22 if level==1 else 3.10 if level==2 else 4.38
    var chamber_depth: float=2.70 if level==1 else 3.85 if level==2 else 4.80
    var build_height: float=chamber_height*(1.0 if damage<=1 else 0.70 if damage==2 else 0.43 if damage==3 else 0.12)
    if damage<4:
        _box(root,"MamposteriaSalaTecnica",
            Vector3(0,build_height*0.5,-footprint*0.22),
            Vector3(chamber_width,build_height,chamber_depth),
            CONCRETE if damage<=1 else DARK_CONCRETE,0.0,0.82)
        _box(root,"FranjaFaccion",
            Vector3(0,build_height*0.74,-footprint*0.22-chamber_depth*0.5-0.015),
            Vector3(chamber_width*0.58,0.14,0.028),
            accent,0.32,0.49)
        if damage<=1:
            _box(root,"CubiertaSalaMaquinas",
                Vector3(0,chamber_height+0.10,-footprint*0.22),
                Vector3(chamber_width+0.36,0.20,chamber_depth+0.34),
                GUNMETAL,0.57,0.52)
        else:
            for beam in [-1,1]:
                _box(root,"VigaExpuesta_%s" % beam,
                    Vector3(float(beam)*chamber_width*0.30,
                        build_height+0.06,-footprint*0.22),
                    Vector3(0.17,0.14,chamber_depth*0.80),
                    STEEL if damage==2 else CHAR,0.51,0.71,
                    Vector3(0,0,float(beam)*(-18 if damage>=3 else 7)))
        _box(root,"PuertaServicio",Vector3(0,1.04,
            -footprint*0.22-chamber_depth*0.5-0.035),
            Vector3(0.92,2.04,0.050),
            GUNMETAL if damage>=2 else STEEL,0.48,0.56)
        if damage<=2:
            for side in [-1,1]:
                _box(root,"VentilacionBlindada_%s" % side,
                    Vector3(float(side)*chamber_width*0.28,
                        chamber_height*0.58,
                        -footprint*0.22-chamber_depth*0.5-0.04),
                    Vector3(0.68,0.39,0.045),
                    GUNMETAL,0.55,0.61)
    if damage<4:
        var count: int=1 if level==1 else 2 if level==2 else 4
        for idx in range(count):
            if damage==3 and idx%2==1:
                continue
            var sx: float=(-0.65 if idx%2==0 else 0.65)*(
                1.15 if level==1 else 2.02)
            var sz: float=footprint*0.17+(
                0.0 if idx<2 else 1.9)
            _transformer(root,"Transformador_%02d" % idx,
                Vector3(sx,0.02,sz),
                0.89 if level==1 else 1.0 if level==2 else 1.18,
                damage,accent)
        if level>=2:
            _gantry(root,"PorticoConductores01",
                -footprint*0.30,footprint*0.34,
                3.5 if level==2 else 5.6,damage)
        if level==3:
            _gantry(root,"PorticoConductores02",
                footprint*0.31,footprint*0.34,5.6,damage)
            if damage<=2:
                for side in [-1,1]:
                    _cylinder(root,"TorreEnfriamiento_%s" % side,
                        Vector3(float(side)*footprint*0.31,1.67,
                        -footprint*0.20),
                        1.04,3.34,COOLING,0.11,0.82)
                    _cylinder(root,"BordeTorre_%s" % side,
                        Vector3(float(side)*footprint*0.31,3.31,
                        -footprint*0.20),
                        1.10,0.20,GUNMETAL,0.63,0.53)
                for vent in range(5):
                    _box(root,"ParrillaSala_%d" % vent,
                        Vector3(-chamber_width*0.30+float(vent)*0.94,
                            chamber_height*0.43,
                            -footprint*0.22-chamber_depth*0.5-0.055),
                        Vector3(0.14,0.54,0.035),GUNMETAL,0.51,0.55)
    if damage>=1:
        var marks: int=2 if damage==1 else 5 if damage==2 else 9 if damage==3 else 14
        for idx in range(marks):
            var pos: Vector3=Vector3(
                -footprint*0.39+float((idx*5)%11)*footprint*0.072,
                0.075,
                -footprint*0.39+float((idx*7)%13)*footprint*0.060)
            _box(root,"MarcaCarbonizacion_%02d" % idx,pos,
                Vector3(0.34+float(idx%3)*0.16,0.018,0.30),
                CHAR,0.03,0.98,
                Vector3(0,float(idx*41),0))
    if damage>=2:
        _ruin(root,damage,0.70 if level==1 else 1.0 if level==2 else 1.28)
    model.set_meta("tarvoka_powerplant_visual_only",true)
    model.set_meta("tarvoka_powerplant_stage",1)
    model.set_meta("tarvoka_powerplant_level",level)
    model.set_meta("tarvoka_powerplant_damage",damage)
    model.set_meta("tarvoka_powerplant_faction",faction)
    model.set_meta("tarvoka_powerplant_final_approved",false)
    model.set_meta("tarvoka_powerplant_gameplay_changed",false)
    return model

static func mesh_count(model: Node) -> int:
    if model==null:
        return 0
    var n: int=1 if model is MeshInstance3D else 0
    for child in model.get_children():
        n+=mesh_count(child)
    return n
