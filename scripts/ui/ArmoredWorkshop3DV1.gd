extends RefCounted
class_name TarvokaArmoredWorkshop3DV1

# TARVOKA: fixed armored-vehicle maintenance and production facility.
# Editable Godot 4.3 geometry, NOT a deployable logistics/supply camp.
# Pure visual prototype. No change to costs, units, supply, production,
# fog, repairs, capture, energy, or the user's mobile support camps.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const TITLE="Taller de Blindados"
const STAGE="TallerBlindadosV1ModeloNativo"
const LEVEL_NAMES=["Taller blindado compacto","Taller mecanizado","Complejo de blindados"]
const DAMAGE_NAMES=["Intacto","Desgaste leve","Daño moderado","Daño crítico","Destruido"]
const NEUTRAL=Color("#71858D")
const CONCRETE=Color("#919a99")
const CONCRETE_DARK=Color("#535f64")
const STEEL=Color("#93a5ad")
const STEEL_DARK=Color("#35454d")
const ZINC=Color("#b5c1c2")
const METAL_DECK=Color("#5e7179")
const GLASS=Color("#557f91")
const SKY_GLASS=Color("#6c919a")
const RUBBER=Color("#252e33")
const RUST=Color("#855d4f")
const HAZARD=Color("#c6a04e")
const OIL=Color("#273e43")
const CHAR=Color("#34383a")
const RUBBLE=Color("#716c69")
static var _materials:Dictionary={}
static var _meshes:Dictionary={}

static func valid(level:int,faction:int,damage:int) -> bool:
    return level>=1 and level<=3 and faction>=-1 and faction<Style.FACTIONS.size() and damage>=0 and damage<=4

static func _mat(tint:Color,metal:float=0.0,rough:float=0.76) -> StandardMaterial3D:
    var key:String="%s/%0.2f/%0.2f" % [tint.to_html(true),metal,rough]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var material:=StandardMaterial3D.new()
    material.albedo_color=tint
    material.metallic=metal
    material.roughness=rough
    _materials[key]=material
    return material

static func _group(parent:Node3D,name:String) -> Node3D:
    var g:=Node3D.new()
    g.name=name
    parent.add_child(g)
    return g

static func _box(parent:Node3D,label:String,at:Vector3,size:Vector3,
        tint:Color,metal:float=0.0,rough:float=0.78,
        angle:Vector3=Vector3.ZERO) -> MeshInstance3D:
    var key:String=str(size)
    var mesh:BoxMesh
    if _meshes.has(key):
        mesh=_meshes[key] as BoxMesh
    else:
        mesh=BoxMesh.new()
        mesh.size=size
        _meshes[key]=mesh
    var piece:=MeshInstance3D.new()
    piece.name=label
    piece.position=at
    piece.rotation_degrees=angle
    piece.mesh=mesh
    piece.material_override=_mat(tint,metal,rough)
    parent.add_child(piece)
    return piece

static func _cylinder(parent:Node3D,label:String,at:Vector3,
        radius:float,length:float,tint:Color,metal:float=0.5,
        rough:float=0.62,angle:Vector3=Vector3.ZERO) -> MeshInstance3D:
    var m:=CylinderMesh.new()
    m.top_radius=radius
    m.bottom_radius=radius
    m.height=length
    m.radial_segments=12
    var piece:=MeshInstance3D.new()
    piece.name=label
    piece.position=at
    piece.rotation_degrees=angle
    piece.mesh=m
    piece.material_override=_mat(tint,metal,rough)
    parent.add_child(piece)
    return piece

static func _chassis(parent:Node3D,width:float,depth:float,
        level:int,damage:int) -> void:
    var civil:=_group(parent,"PlataformaYAccesos")
    _box(civil,"LosaPrincipal",Vector3(0,-0.22,0),
        Vector3(width+2.4,0.42,depth+4.0),CONCRETE_DARK,0.02,0.94)
    _box(civil,"PavimentoPatio",Vector3(0,0.025,-depth*0.5-1.02),
        Vector3(width+1.7,0.07,1.78),CONCRETE,0.01,0.87)
    _box(civil,"PisoTaller",Vector3(0,0.04,0),
        Vector3(width-0.45,0.06,depth-0.35),CONCRETE,0.01,0.83)
    for side in [-1,1]:
        var x:float=float(side)*(width*0.5-0.10)
        _box(civil,"BordeProtector_%d" % side,
            Vector3(x,0.18,-depth*0.5-0.38),
            Vector3(0.32,0.32,2.60),STEEL_DARK,0.51,0.61)
        _box(civil,"GuiaPatio_%d" % side,
            Vector3(float(side)*(width*0.50-1.08),0.073,
                -depth*0.5-0.97),Vector3(0.075,0.012,1.55),
            HAZARD if damage<3 else RUBBLE,0.02,0.93)
    if level>=2 and damage<4:
        for i in range(3):
            _box(civil,"DrenajeIndustrial_%d" % i,
                Vector3(-width*0.26+float(i)*width*0.26,0.085,
                    -depth*0.5-0.58),
                Vector3(0.60,0.026,0.12),STEEL_DARK,0.44,0.61)

static func _shell(parent:Node3D,width:float,depth:float,height:float,
        bays:int,damage:int,accent:Color) -> void:
    if damage==4:
        for side in [-1,1]:
            _box(parent,"RestosCimentacion_%d" % side,
                Vector3(float(side)*(width*0.5-0.10),0.44,0),
                Vector3(0.65,0.75,depth*0.76),RUBBLE,0.0,0.97,
                Vector3(0,float(side)*7,0))
        return
    var broken:bool=damage>=3
    var front:float=-depth*0.5
    var rear:float=depth*0.5
    # Open-front concrete-and-steel garage, not a closed unbroken box.
    # Interior repair bays stay visible from the principal inspection angle.
    for side in [-1,1]:
        var x:float=float(side)*width*0.5
        var rise:float=height*0.56 if broken else height
        _box(parent,"ZocaloLateral_%d" % side,
            Vector3(x,0.86,0),Vector3(0.42,1.70,depth),
            CONCRETE_DARK,0.02,0.90)
        _box(parent,"DintelLateral_%d" % side,
            Vector3(x,rise-0.44,0),Vector3(0.42,0.88,depth),
            METAL_DECK if damage<=2 else CHAR,0.36,0.65)
        for i in range(4):
            var z:float=-depth*0.37+float(i)*depth*0.245
            var column_height:float=height*(0.62 if broken and i==2 else 1.0)
            _box(parent,"PilarLateral_%d_%d" % [side,i],
                Vector3(x,column_height*0.5,z),
                Vector3(0.50,column_height,0.52),
                STEEL_DARK if damage==3 and i==2 else STEEL,
                0.56,0.59,Vector3(0,0,10 if broken and i==2 else 0))
            if damage<=2 and i<3:
                _box(parent,"VentanalLateral_%d_%d" % [side,i],
                    Vector3(x+float(side)*0.24,2.32,z+depth*0.10),
                    Vector3(0.055,0.91,depth*0.135),
                    GLASS if damage<=1 or i%2==0 else CHAR,0.06,0.23)
        _box(parent,"RefuerzoFrontal_%d" % side,
            Vector3(x-0.16*float(side),rise*0.54,front),
            Vector3(0.50,rise*0.92,0.50),STEEL,0.64,0.56)
    # Recessed back wall, split into large industrial panels.
    for i in range(bays+1):
        var sw:float=width/float(bays+1)
        var x:float=-width*0.5+sw*(float(i)+0.5)
        _box(parent,"MuroPosterior_%d" % i,
            Vector3(x,1.63,rear-0.12),
            Vector3(sw-0.13,3.19,0.33),
            CONCRETE_DARK if i%2==0 else CONCRETE,0.04,0.91)
        if not broken and damage<2:
            _box(parent,"VentanaAltaTrasera_%d" % i,
                Vector3(x,height-1.04,rear-0.32),
                Vector3(sw*0.62,0.66,0.05),SKY_GLASS,0.06,0.25)
    if not broken:
        for bay in range(bays):
            var bw:float=width/float(bays)
            var cx:float=-width*0.5+bw*(float(bay)+0.5)
            _box(parent,"VigaSuperiorFrente_%d" % bay,
                Vector3(cx,height-0.23,front-0.10),
                Vector3(bw-0.03,0.50,0.42),STEEL_DARK,0.66,0.54)
            # Sectional doors remain visibly rolled UP: no wall obstructing
            # tank-size service aperture; collapsed door when damaged.
            if damage<=1:
                _box(parent,"PersianaLevantada_%d" % bay,
                    Vector3(cx,height-0.60,front-0.43),
                    Vector3(bw-0.30,0.54,0.18),METAL_DECK,0.66,0.50)
            else:
                _box(parent,"PersianaGolpeada_%d" % bay,
                    Vector3(cx,height-1.20,front-0.43),
                    Vector3(bw-0.40,0.40,0.22),RUST,0.47,0.83,
                    Vector3(0,0,-13.0 if bay%2==0 else 11.0))
            _box(parent,"FajaFaccion_%d" % bay,
                Vector3(cx,height-0.17,front-0.38),
                Vector3(bw*0.77,0.16,0.09),accent,0.30,0.46)
    else:
        _box(parent,"VigaFrontalDesprendida",
            Vector3(0,height*0.46,front-0.22),
            Vector3(width*0.64,0.32,0.32),RUST,0.61,0.79,
            Vector3(0,0,14.0))

static func _roof(parent:Node3D,width:float,depth:float,height:float,
        bays:int,level:int,damage:int) -> void:
    if damage==4:
        return
    var roof:=_group(parent,"CubiertaIndustrial")
    for bay in range(bays):
        if damage>=3 and bay%2==0:
            continue
        var bw:float=width/float(bays)
        var cx:float=-width*0.5+bw*(float(bay)+0.5)
        _box(roof,"CerchaPrincipal_%d" % bay,
            Vector3(cx,height+0.02,0),
            Vector3(bw*0.90,0.20,depth+0.34),STEEL_DARK,0.67,0.58)
        for seg in range(3):
            if damage==2 and seg==1 and bay==0:
                continue
            var z:float=-depth*0.34+float(seg)*depth*0.34
            _box(roof,"TechoPanel_%d_%d" % [bay,seg],
                Vector3(cx,height+0.17,z),
                Vector3(bw-0.27,0.12,depth*0.31),
                METAL_DECK if seg!=1 else SKY_GLASS,0.41 if seg!=1 else 0.04,
                0.57 if seg!=1 else 0.22)
        if level>=2 and damage<=1:
            _box(roof,"LucernarioElevado_%d" % bay,
                Vector3(cx,height+0.34,0),
                Vector3(bw*0.43,0.12,depth*0.15),
                SKY_GLASS,0.09,0.18)
    if damage<3:
        for side in [-1,1]:
            _box(roof,"Canalon_%d" % side,
                Vector3(float(side)*width*0.5,height+0.05,0),
                Vector3(0.23,0.19,depth+0.32),ZINC,0.67,0.54)

static func _repair_bays(parent:Node3D,width:float,depth:float,height:float,
        bays:int,damage:int) -> void:
    if damage>=4:
        return
    var service:=_group(parent,"BahiasReparacionYElevacion")
    var bw:float=width/float(bays)
    for bay in range(bays):
        var cx:float=-width*0.5+bw*(float(bay)+0.5)
        if damage==3 and bay%2==1:
            continue
        # Floor service pit is an inset dark metal plane with a raised
        # structural lip, not a floating vehicle or a fake painted pit.
        _box(service,"FosaMantenimiento_%d" % bay,
            Vector3(cx,0.084,0.20),
            Vector3(bw*0.64,0.035,depth*0.46),OIL,0.23,0.76)
        for side in [-1,1]:
            var sx:float=cx+float(side)*bw*0.35
            _box(service,"PerfilElevador_%d_%d" % [bay,side],
                Vector3(sx,0.24,0.1),
                Vector3(0.22,0.37,depth*0.45),
                STEEL_DARK if damage>=3 else STEEL,0.61,0.52)
            if damage<3:
                _cylinder(service,"Hidraulico_%d_%d" % [bay,side],
                    Vector3(sx,0.69,depth*0.13),
                    0.11,0.80,ZINC,0.82,0.28)
                _box(service,"BrazoElevador_%d_%d" % [bay,side],
                    Vector3(cx+float(side)*bw*0.21,0.84,depth*0.13),
                    Vector3(bw*0.32,0.13,0.23),STEEL,0.69,0.52)
            _box(service,"PinturaSeguridad_%d_%d" % [bay,side],
                Vector3(cx+float(side)*bw*0.35,0.112,
                    -depth*0.14),
                Vector3(0.105,0.018,depth*0.24),
                HAZARD if damage<=1 else RUST,0.01,0.86)
        if damage<3:
            # Full mechanical over-head crane with running rail and hook.
            for side in [-1,1]:
                _box(service,"CarrilPuente_%d_%d" % [bay,side],
                    Vector3(cx+float(side)*bw*0.41,height-0.70,0),
                    Vector3(0.15,0.22,depth*0.86),STEEL,0.74,0.47)
            _box(service,"PuenteGrua_%d" % bay,
                Vector3(cx,height-0.73,depth*0.12),
                Vector3(bw*0.85,0.26,0.27),HAZARD,0.47,0.58)
            _box(service,"CarroGrua_%d" % bay,
                Vector3(cx,height-0.99,depth*0.12),
                Vector3(0.57,0.23,0.50),STEEL_DARK,0.58,0.48)
            _cylinder(service,"CableGrua_%d" % bay,
                Vector3(cx,height-1.58,depth*0.12),
                0.037,0.88,STEEL,0.77,0.46)
            _box(service,"GanchoGrua_%d" % bay,
                Vector3(cx,height-2.10,depth*0.12),
                Vector3(0.23,0.31,0.13),RUST,0.70,0.46)
    if damage<=2:
        # Machining workbench and compressed-air infrastructure on rear wall.
        for xside in [-1,1]:
            var px:float=float(xside)*(width*0.5-0.89)
            _box(service,"BancoHerramientas_%d" % xside,
                Vector3(px,0.73,depth*0.5-0.84),
                Vector3(1.02,0.17,0.67),STEEL_DARK,0.57,0.56)
            _box(service,"ArmarioHerramientas_%d" % xside,
                Vector3(px,1.29,depth*0.5-0.62),
                Vector3(0.86,0.90,0.34),METAL_DECK,0.42,0.58)
            _cylinder(service,"Compresor_%d" % xside,
                Vector3(px,0.42,depth*0.5-1.65),
                0.28,0.83,STEEL_DARK,0.65,0.55,
                Vector3(90,0,0))

static func _exterior(parent:Node3D,width:float,depth:float,height:float,
        level:int,damage:int,accent:Color) -> void:
    if damage>=3:
        return
    var ext:=_group(parent,"InstalacionesExteriores")
    # Service annex is not a second factory; it is attached to the garage.
    var x:float=width*0.5+0.60
    if level>=2:
        _box(ext,"CuartoCompresores",
            Vector3(x,1.15,depth*0.19),
            Vector3(1.24,2.29,2.68),CONCRETE_DARK,0.06,0.83)
        _box(ext,"CubiertaCuartoCompresores",
            Vector3(x,2.41,depth*0.19),
            Vector3(1.44,0.20,2.95),METAL_DECK,0.53,0.59)
        _box(ext,"PuertaCuartoCompresores",
            Vector3(x,0.87,depth*0.19-1.37),
            Vector3(0.62,1.66,0.065),STEEL,0.45,0.61)
        _box(ext,"IdentidadAnexo",
            Vector3(x,2.02,depth*0.19-1.45),
            Vector3(0.96,0.16,0.08),accent,0.27,0.49)
    if level>=3:
        for i in range(3):
            var sx:float=-width*0.27+float(i)*width*0.27
            _box(ext,"ExtractorCubierta_%d" % i,
                Vector3(sx,height+0.48,depth*0.24),
                Vector3(0.80,0.56,0.82),STEEL_DARK,0.57,0.59)
            _box(ext,"RejillaExtractor_%d" % i,
                Vector3(sx,height+0.78,depth*0.24),
                Vector3(0.87,0.08,0.87),ZINC,0.54,0.55)

static func _wreckage(parent:Node3D,width:float,depth:float,damage:int,
        accent:Color) -> void:
    if damage==0:
        return
    var stage:=_group(parent,"DanosFisicosYEscombros")
    var pieces:int=2 if damage==1 else 7 if damage==2 else 16 if damage==3 else 27
    for i in range(pieces):
        var seed:float=float(i)
        var x:float=-width*0.40+float((i*7)%19)*width*0.043
        var z:float=-depth*0.33+float((i*11)%17)*depth*0.039
        var size:Vector3=Vector3(
            0.36+float(i%4)*0.18,0.13+float(i%3)*0.12,
            0.26+float(i%5)*0.16)
        _box(stage,"RestosIndustriales_%02d" % i,
            Vector3(x,0.19+float(i%2)*0.11,z),size,
            CHAR if i%3==0 else RUBBLE if i%2==0 else RUST,
            0.42 if i%3==0 else 0.03,0.92,
            Vector3(float((i%3)-1)*18.0,seed*29.0,float((i%4)-2)*9.0))
    if damage>=3:
        for i in range(4):
            _box(stage,"VigaHundida_%d" % i,
                Vector3(-width*0.30+float(i)*width*0.20,0.62,
                    -depth*0.14+float(i%2)*depth*0.19),
                Vector3(0.20,0.18,depth*0.39),STEEL_DARK,0.72,0.72,
                Vector3(-24,float(i*33),18.0))
    if damage==4:
        _box(stage,"EmblemaFaccionCaido",
            Vector3(-width*0.14,0.16,-depth*0.35),
            Vector3(0.98,0.13,0.48),accent.darkened(0.32),
            0.27,0.81,Vector3(0,28,19))

static func build(level:int=1,faction:int=-1,
        damage:int=0) -> Node3D:
    if not valid(level,faction,damage):
        return null
    var width:float=9.5 if level==1 else 15.0 if level==2 else 20.5
    var depth:float=12.0 if level==1 else 15.0 if level==2 else 18.0
    var height:float=4.90 if level==1 else 6.10 if level==2 else 7.20
    var bays:int=1 if level==1 else 2 if level==2 else 3
    var accent:Color=Style.faction_color(faction) if faction>=0 else NEUTRAL
    var model:=Node3D.new()
    model.name="TallerBlindados_N%d_F%d_D%d" % [level,faction,damage]
    var root:=_group(model,STAGE)
    _chassis(root,width,depth,level,damage)
    _shell(root,width,depth,height,bays,damage,accent)
    _roof(root,width,depth,height,bays,level,damage)
    _repair_bays(root,width,depth,height,bays,damage)
    _exterior(root,width,depth,height,level,damage,accent)
    _wreckage(root,width,depth,damage,accent)
    model.set_meta("visual_only",true)
    model.set_meta("no_gameplay_changes",true)
    model.set_meta("is_fixed_building",true)
    model.set_meta("is_mobile_camp",false)
    model.set_meta("is_supply_depot",false)
    model.set_meta("workshop_art_version",1)
    model.set_meta("workshop_level",level)
    model.set_meta("workshop_faction",faction)
    model.set_meta("workshop_damage",damage)
    model.set_meta("workshop_bays",bays)
    model.set_meta("workshop_approved",false)
    return model

static func mesh_count(node:Node) -> int:
    var count:int=1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count+=mesh_count(child)
    return count
