extends RefCounted
class_name TarvokaCivilianCity3DV1

# TARVOKA civilian city: actual native Godot 4.3 editable 3D geometry.
# NOT the separate military HQ and NOT a player-buildable factory.
# Three distinct district silhouettes are visual prototypes only; the city
# remains a pre-placed, infantry-capturable income source in game rules.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV1BarrioPlazaMunicipio"
const FLOOR=Color("#7c8582")
const PAVEMENT=Color("#adb0a0")
const ROAD=Color("#3c4b4f")
const ROAD_MARK=Color("#ddd0a7")
const WALL=Color("#bdbaad")
const STONE=Color("#d0c5b0")
const BRICK=Color("#a17d72")
const MODERN=Color("#92a9ae")
const DARK=Color("#32454c")
const ROOF=Color("#475d61")
const GLASS=Color("#487a8e")
const TIMBER=Color("#856b55")
const GARDEN=Color("#568466")
const TRUNK=Color("#775f4c")
const RUIN=Color("#686260")
const CHAR=Color("#353d40")
const NEUTRAL_ACCENT=Color("#70838B") # Cool slate; visually distinct from Solar yellow
const LABELS=[
    "Villa · edificios bajos y plaza municipal",
    "Ciudad · manzanas medianas y comercio",
    "Metrópoli · bloques urbanos y centro cívico"
]
const DAMAGE_LABELS=["Intacta","Desgaste leve","Daño moderado",
    "Daño estructural grave","Ruinas"]
static var _materials: Dictionary={}
static var _box_meshes: Dictionary={}

static func valid_spec(level: int,faction: int,damage: int) -> bool:
    return level in [1,2,3] and faction>=-1 and faction<Style.FACTIONS.size() and damage in [0,1,2,3,4]

static func _material(color: Color,kind: String="stone") -> StandardMaterial3D:
    var key: String=color.to_html(true)+"/"+kind
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=0.35 if kind=="metal" else 0.04 if kind=="glass" else 0.01
    mat.roughness=0.22 if kind=="glass" else 0.44 if kind=="metal" else 0.88
    _materials[key]=mat
    return mat

static func _group(parent: Node3D,label: String) -> Node3D:
    var group:=Node3D.new()
    group.name=label
    parent.add_child(group)
    return group

static func _box(parent: Node3D,label: String,pos: Vector3,
        dims: Vector3,color: Color,kind: String="stone") -> MeshInstance3D:
    var key: String=str(dims)
    if not _box_meshes.has(key):
        var new_mesh:=BoxMesh.new()
        new_mesh.size=dims
        _box_meshes[key]=new_mesh
    var mesh:=MeshInstance3D.new()
    mesh.name=label
    mesh.mesh=_box_meshes[key] as BoxMesh
    mesh.position=pos
    mesh.material_override=_material(color,kind)
    parent.add_child(mesh)
    return mesh

static func _cylinder(parent: Node3D,label: String,pos: Vector3,
        radius: float,height: float,color: Color,
        sections: int=8) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=sections
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=mesh
    node.position=pos
    node.material_override=_material(color)
    parent.add_child(node)
    return node

static func _ground(parent: Node3D,level: int,damage: int) -> void:
    var plot:=_group(parent,"ManzanaUrbanaYLotes")
    _box(plot,"BaseUrbana",Vector3(0,-0.24,0),
        Vector3(15.8,0.45,12.6),FLOOR)
    _box(plot,"AvenidaCentral",Vector3(0,0.015,0),
        Vector3(15.35,0.045,1.84),ROAD)
    for side in [-1,1]:
        _box(plot,"Acera_%d" % side,
            Vector3(0,0.045,float(side)*1.13),
            Vector3(15.45,0.09,0.40),PAVEMENT)
    for mark in range(8):
        var x: float=-6.65+float(mark)*1.9
        _box(plot,"RayaCalzada_%d" % mark,Vector3(x,0.045,0),
            Vector3(0.77,0.012,0.075),ROAD_MARK)
    # The civic plaza is behind the main avenue: roads and town hall
    # remain walkable silhouettes within a single tactical city tile.
    _box(plot,"PlazaCivica",Vector3(0,0.042,2.00),
        Vector3(3.45,0.07,2.10),STONE)
    _box(plot,"RibetePlaza",Vector3(0,0.082,1.03),
        Vector3(3.54,0.035,0.15),BRICK)
    if damage<3:
        _cylinder(plot,"MonumentoPlaza",Vector3(0,0.42,2.04),
            0.29,0.70,STONE)
        _box(plot,"PlacaMonumento",Vector3(0,0.82,2.04),
            Vector3(0.68,0.11,0.68),ROOF,"metal")
    elif damage>=3:
        _box(plot,"MonumentoVolcado",Vector3(0,0.135,2.04),
            Vector3(0.85,0.18,0.41),RUIN)
    if level>=2 and damage<3:
        for sx in [-1,1]:
            _box(plot,"Arriate_%d" % sx,
                Vector3(float(sx)*1.47,0.091,2.45),
                Vector3(0.31,0.13,0.76),GARDEN)

static func _facade_detail(group: Node3D,tag: String,x: float,z: float,
        width: float,depth: float,height: float,floors: int,
        damage: int,accent: Color) -> void:
    var front_z: float=z-depth*0.5-0.037
    var pane_width: float=minf(0.65,width*0.23)
    for floor in range(floors):
        var y: float=0.86+float(floor)*2.10
        if y+0.49>height:
            continue
        for k in [-1,1]:
            if damage==2 and (floor+k+4)%3==0:
                continue
            var wx: float=x+float(k)*width*0.23
            _box(group,"MarcoVentana_"+tag+"_%d_%d" % [floor,k],
                Vector3(wx,y,front_z-0.026),
                Vector3(pane_width+0.12,0.83,0.10),DARK,"metal")
            _box(group,"Cristal_"+tag+"_%d_%d" % [floor,k],
                Vector3(wx,y,front_z-0.083),
                Vector3(pane_width,0.69,0.028),
                GLASS if damage<=1 else CHAR,"glass")
            _box(group,"Alfeizar_"+tag+"_%d_%d" % [floor,k],
                Vector3(wx,y-0.45,front_z-0.115),
                Vector3(pane_width+0.20,0.078,0.25),STONE)
    _box(group,"Entrada_"+tag,
        Vector3(x,0.85,front_z-0.081),
        Vector3(minf(0.83,width*0.27),1.69,0.10),DARK,"metal")
    _box(group,"Umbral_"+tag,
        Vector3(x,0.075,front_z-0.30),
        Vector3(1.0,0.12,0.54),STONE)
    _box(group,"FranjaCivil_"+tag,
        Vector3(x,height-0.25,front_z-0.073),
        Vector3(width*0.72,0.10,0.09),accent)

static func _building(parent: Node3D,tag: String,x: float,z: float,
        width: float,depth: float,floors: int,
        damage: int,color: Color,accent: Color,
        civic: bool=false) -> void:
    var total: float=float(floors)*2.10+0.21
    var group:=_group(parent,"EdificioCivil_"+tag)
    if damage==4:
        _box(group,"EscombrosBase",Vector3(x,0.23,z),
            Vector3(width*0.92,0.46,depth*0.87),RUIN)
        for r in range(3):
            _box(group,"Fragmento_%d" % r,
                Vector3(x-width*0.26+float(r)*width*0.22,0.45,
                    z-depth*0.21+float(r%2)*depth*0.29),
                Vector3(0.58,0.31+float(r)*0.13,0.50),
                CHAR if r%2==0 else BRICK)
        return
    if damage==3:
        _box(group,"EstructuraArruinada",
            Vector3(x,0.56,z),
            Vector3(width,1.11,depth*0.95),RUIN)
        _box(group,"FachadaCaida",
            Vector3(x+width*0.30,0.25,z-depth*0.55),
            Vector3(width*0.36,0.35,0.68),BRICK)
        return
    _box(group,"VolumenMamposteria",
        Vector3(x,total*0.50,z),
        Vector3(width,total,depth),color)
    _box(group,"Cimiento",Vector3(x,0.18,z),
        Vector3(width+0.20,0.32,depth+0.20),STONE)
    var roof_color: Color=CHAR if damage==2 else ROOF
    _box(group,"Cubierta",Vector3(x,total+0.12,z),
        Vector3(width+0.28,0.22,depth+0.28),roof_color,"metal")
    if civic:
        _box(group,"CornisaMunicipal",Vector3(x,total-0.09,
            z-depth*0.5-0.04),
            Vector3(width+0.46,0.25,0.29),STONE)
        for side in [-1,1]:
            _cylinder(group,"ColumnaPortico_%d" % side,
                Vector3(x+float(side)*width*0.32,0.80,
                    z-depth*0.5-0.36),0.13,1.55,STONE)
        if damage<2 and floors>=3:
            _box(group,"TorreRelojMunicipal",
                Vector3(x,total+0.69,z),
                Vector3(1.14,1.18,1.04),STONE)
            _box(group,"EsferaReloj",Vector3(x,total+0.75,
                z-0.555),Vector3(0.46,0.46,0.065),DARK,"metal")
            _box(group,"TechoReloj",Vector3(x,total+1.34,z),
                Vector3(1.35,0.18,1.23),ROOF,"metal")
    _facade_detail(group,tag,x,z,width,depth,total,
        floors,damage,accent)
    # A side facade uses real volumetric windows rather than a decal.
    if damage<2:
        for floor in range(floors):
            var sy: float=0.85+float(floor)*2.10
            if sy+0.40<total:
                _box(group,"VentanaLateral_%d" % floor,
                    Vector3(x+width*0.5+0.030,sy,z),
                    Vector3(0.09,0.64,0.67),GLASS,"glass")

static func _urban_furniture(parent: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var street:=_group(parent,"MobiliarioUrbano")
    for side in [-1,1]:
        var sx: float=float(side)*6.8
        _cylinder(street,"Tronco_%d" % side,
            Vector3(sx,0.52,2.72),0.12,0.95,TRUNK)
        _cylinder(street,"Copa_%d" % side,
            Vector3(sx,1.41,2.72),0.57,0.84,GARDEN)
    for side in [-1,1]:
        var bx: float=float(side)*2.55
        _box(street,"Banco_%d" % side,
            Vector3(bx,0.30,2.98),Vector3(0.86,0.12,0.25),TIMBER)
        _box(street,"PataBanco_%d" % side,
            Vector3(bx,0.16,2.98),Vector3(0.70,0.25,0.13),DARK)
    if level>=2:
        for side in [-1,1]:
            var x: float=float(side)*6.98
            _cylinder(street,"Farola_%d" % side,
                Vector3(x,1.38,-1.36),0.05,2.65,DARK)
            _box(street,"Luminaria_%d" % side,
                Vector3(x,2.74,-1.36),
                Vector3(0.46,0.20,0.31),STONE,"metal")
        # The market stalls share the civic look, NOT a military factory.
        for side in [-1,1]:
            var x: float=float(side)*1.85
            _box(street,"PuestoMercado_%d" % side,
                Vector3(x,0.43,4.65),
                Vector3(1.34,0.76,0.74),TIMBER)
            _box(street,"ToldoMercado_%d" % side,
                Vector3(x,1.21,4.65),
                Vector3(1.49,0.13,0.90),accent)
            for edge in [-1,1]:
                _box(street,"PosteMercado_%d_%d" % [side,edge],
                    Vector3(x+float(edge)*0.59,0.86,4.65),
                    Vector3(0.07,0.75,0.07),DARK,"metal")

static func _district(parent: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var root:=_group(parent,"DistritoCiudadanoNivel%d" % level)
    var rear_floors: int=1 if level==1 else 2 if level==2 else 4
    var front_floors: int=1 if level==1 else 3 if level==2 else 5
    var civic_floors: int=2 if level==1 else 3 if level==2 else 4
    for side in [-1,1]:
        var x: float=float(side)*4.63
        _building(root,"ResidencialNorte_%d" % side,
            x,-3.80,2.74,2.84,rear_floors,
            damage,BRICK if side<0 else WALL,accent)
        _building(root,"ResidencialSur_%d" % side,
            x,3.62,2.77,2.80,front_floors,
            damage,MODERN if level==3 else WALL,accent)
    _building(root,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        civic_floors,damage,STONE,accent,true)
    if level==3 and damage<3:
        # Extra setbacks/terraces make a metropolis distinctly different
        # from the smaller civic center, with the same footprint.
        for side in [-1,1]:
            var x: float=float(side)*4.63
            _box(root,"AzoteaEscalonada_%d" % side,
                Vector3(x,front_floors*2.10+0.77,3.62),
                Vector3(1.33,1.25,1.38),ROOF,"metal")
            _box(root,"TerrazaVerde_%d" % side,
                Vector3(x,front_floors*2.10+1.42,3.62),
                Vector3(1.14,0.11,1.15),GARDEN)
    _urban_furniture(root,level,damage,accent)

static func build(level: int=1,faction: int=-1,
        damage: int=0) -> Node3D:
    if not valid_spec(level,faction,damage):
        return null
    var model:=Node3D.new()
    model.name="CiudadCivilV1_N%d_F%d_D%d" % [level,faction,damage]
    var accent: Color=Style.faction_color(faction) if faction>=0 else NEUTRAL_ACCENT
    var root:=_group(model,STAGE_NAME)
    _ground(root,level,damage)
    _district(root,level,damage,accent)
    model.set_meta("visual_city_v1",true)
    model.set_meta("visual_only",true)
    model.set_meta("no_gameplay_changes",true)
    model.set_meta("visual_level",level)
    model.set_meta("visual_faction",faction)
    model.set_meta("visual_damage_stage",damage)
    model.set_meta("city_kind","civilian_income")
    model.set_meta("not_headquarters",true)
    model.set_meta("not_buildable",true)
    model.set_meta("city_version",1)
    return model

static func count_meshes(parent: Node) -> int:
    var total: int=1 if parent is MeshInstance3D else 0
    for child in parent.get_children():
        total+=count_meshes(child)
    return total
