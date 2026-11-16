extends RefCounted
class_name TarvokaInfantryBarracks3DV1

# TARVOKA — Cuartel de Infanteria. Native Godot 4.3 geometry, NOT an image.
# Three fundamentally different massings on identical 16x13m site:
# L1: one-floor compact barracks; L2: two-floor L + watchtower;
# L3: three-floor U-shaped garrison with two wings and twin towers.
# Purely visual: NEVER alter captures, production, turns or balance.
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CuartelInfanteriaV1TresArquitecturas"
const DAMAGE_STAGES=["Operativo","Leve · cubierta y señalización",
    "Medio · paneles y fachada","Crítico · derrumbe parcial",
    "Destruido · cimientos y ruinas"]
const CONCRETE=Color("#a7b1ac")
const PALE=Color("#c0c9c4")
const DARK=Color("#283d45")
const STEEL=Color("#50666b")
const ROOF=Color("#455863")
const TRIM=Color("#789099")
const GLASS=Color("#3f6878")
const PAVEMENT=Color("#6a7470")
const SAFETY=Color("#cbb060")
const TRAINING=Color("#78866c")
const CHAR=Color("#34373a")
const RUST=Color("#916453")
const BASE=Color("#66746f")
static var _materials: Dictionary={}
static var _box_meshes: Dictionary={}

static func valid_spec(level: int,faction: int,damage: int) -> bool:
    return level in [1,2,3] and faction>=0 and faction<Style.FACTIONS.size() and damage in [0,1,2,3,4]

static func _material(c: Color,metal: float=0.12) -> StandardMaterial3D:
    var key: String="%s/%.2f" % [c.to_html(true),metal]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metal
    m.roughness=0.62 if metal>0.30 else 0.83
    _materials[key]=m
    return m

static func _group(parent: Node3D,label: String) -> Node3D:
    var n:=Node3D.new()
    n.name=label
    parent.add_child(n)
    return n

static func _box(parent: Node3D,label: String,at: Vector3,
        dimensions: Vector3,color: Color,metal: float=0.12,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var key: String="%.3f/%.3f/%.3f" % [
        dimensions.x,dimensions.y,dimensions.z]
    if not _box_meshes.has(key):
        var source:=BoxMesh.new()
        source.size=dimensions
        _box_meshes[key]=source
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=_box_meshes[key] as BoxMesh
    part.position=at
    part.rotation_degrees=rotation
    part.material_override=_material(color,metal)
    parent.add_child(part)
    return part

static func _cylinder(parent: Node3D,label: String,at: Vector3,
        radius: float,height: float,color: Color) -> MeshInstance3D:
    var source:=CylinderMesh.new()
    source.top_radius=radius
    source.bottom_radius=radius
    source.height=height
    source.radial_segments=12
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=source
    part.position=at
    part.material_override=_material(color,0.36)
    parent.add_child(part)
    return part

static func _ground(root: Node3D,level: int,damage: int,accent: Color) -> void:
    var yard:=_group(root,"TerrenoComunitarioCuartel")
    _box(yard,"CimentacionGeneral",
        Vector3(0,-0.30,0),Vector3(16.2,0.54,13.0),BASE)
    _box(yard,"PatioFormacion",
        Vector3(0,0.006,-3.40),Vector3(11.1,0.055,5.15),
        CHAR if damage==4 else PAVEMENT)
    if damage==4:
        for i in range(12):
            _box(yard,"FragmentoRuina_%02d" % i,
                Vector3(-6.6+float(i%6)*2.55,0.15,
                    -2.5+float(i/6)*5.9),
                Vector3(0.54+float(i%3)*0.15,0.22,0.56),
                CHAR if i%2==0 else RUST,0.15,
                Vector3(7*float(i%3),16*float(i),9))
        return
    for i in range(4):
        _box(yard,"LineaFormacion_%d" % i,
            Vector3(-3.90+float(i)*2.58,0.047,-3.85),
            Vector3(0.09,0.012,2.65),PALE)
    _box(yard,"LineaComienzo",
        Vector3(0,0.048,-5.19),Vector3(10.0,0.011,0.09),
        RUST if damage>=3 else SAFETY)
    _box(yard,"FranjaFaccionPatio",
        Vector3(5.15,0.052,-3.45),
        Vector3(0.12,0.012,4.32),accent)

static func _building(parent: Node3D,label: String,cx: float,cz: float,
        width: float,depth: float,height: float,floors: int,
        damage: int,accent: Color,primary: bool=false) -> void:
    var b:=_group(parent,label)
    var front: float=cz-depth*0.5
    var back: float=cz+depth*0.5
    _box(b,"Piso_"+label,Vector3(cx,0.15,cz),
        Vector3(width+0.07,0.28,depth+0.07),CONCRETE)
    var h: float=height if damage<=2 else minf(2.23,height)
    var wall: Color=CONCRETE if damage<=1 else PALE if damage==2 else RUST
    _box(b,"ParedPosterior_"+label,
        Vector3(cx,h*0.5,back),Vector3(width,h,0.24),wall)
    _box(b,"ParedIzquierda_"+label,
        Vector3(cx-width*0.5,h*0.5,cz),
        Vector3(0.25,h,depth),wall)
    if damage<=2:
        _box(b,"ParedDerecha_"+label,
            Vector3(cx+width*0.5,h*0.5,cz),
            Vector3(0.25,h,depth),wall)
    else:
        _box(b,"ParedDerechaFracturada_"+label,
            Vector3(cx+width*0.5,0.62,cz+0.42),
            Vector3(0.25,1.18,depth*0.66),RUST,0.14,
            Vector3(0,0,8))
    var door: float=1.70 if primary else 1.30
    var segment: float=(width-door)*0.5
    for side in [-1,1]:
        var x: float=cx+float(side)*(door*0.5+segment*0.5)
        _box(b,"FachadaLateral_%d" % side,
            Vector3(x,h*0.5,front),Vector3(segment,h,0.26),wall)
    if damage>=3:
        _box(b,"DintelFracturado_"+label,
            Vector3(cx-0.35,2.27,front),
            Vector3(width*0.46,0.22,0.31),RUST,0.20,
            Vector3(0,0,-8))
        return
    if h>2.55:
        _box(b,"DintelIngreso",
            Vector3(cx,h-0.24,front),
            Vector3(door,0.44,0.28),STEEL,0.36)
    _box(b,"PuertaAcceso",
        Vector3(cx,1.01,front+0.04),
        Vector3(door*0.86,1.92,0.08),DARK,0.35)
    _box(b,"IdentidadFaccionAcceso",
        Vector3(cx,2.44,front-0.155),
        Vector3(door*0.90,0.18,0.03),accent)
    _box(b,"MarquesinaIngreso",
        Vector3(cx,2.60,front-0.45),
        Vector3(door+0.68,0.14,0.82),
        STEEL if damage==0 else RUST,0.33)
    for floor_id in range(floors):
        var y: float=0.70+float(floor_id)*2.22
        if y+0.90>=height:
            continue
        for side in [-1,1]:
            var xpos: float=cx+float(side)*(door*0.5+segment*0.54)
            _box(b,"MarcoVentana_%d_%d" % [floor_id,side],
                Vector3(xpos,y+0.48,front-0.17),
                Vector3(minf(1.10,segment*0.55),0.91,0.10),
                DARK,0.31)
            _box(b,"CristalVentana_%d_%d" % [floor_id,side],
                Vector3(xpos,y+0.48,front-0.227),
                Vector3(minf(1.0,segment*0.48),0.78,0.03),
                GLASS if damage<=1 else CHAR,0.22)
        if floor_id>0:
            _box(b,"ForjadoVisible_%d" % floor_id,
                Vector3(cx,0.07+float(floor_id)*2.22,front-0.16),
                Vector3(width,0.18,0.20),TRIM,0.23)
    for panel in range(4):
        if damage==1 and panel==1:
            continue
        if damage==2 and panel in [0,2]:
            continue
        _box(b,"PanelTecho_%d" % panel,
            Vector3(cx-width*0.5+width*(float(panel)+0.5)*0.25,
                height+0.13,cz),
            Vector3(width*0.25-0.065,0.23,depth+0.32),
            ROOF if damage<=1 else RUST,0.29)
    if damage<=1:
        _box(b,"RemateCubierta",
            Vector3(cx,height+0.26,front),
            Vector3(width,0.11,0.24),TRIM,0.40)
    if floors>=2 and damage==0:
        _box(b,"FranjaSuperiorFaccion",
            Vector3(cx,height+0.26,front-0.11),
            Vector3(width*0.53,0.06,0.055),accent)

static func _training(root: Node3D,level: int,damage: int) -> void:
    var zone:=_group(root,"CampoEntrenamientoInfanteria")
    # N3 correction: V1 used x=-6, where the larger west wing occupies
    # part of the obstacle course. The expanded garrison instead has
    # a narrow clear training corridor WEST of its two-storey wing.
    # Wing west face x=-6.085. New field east edge x=-6.275.
    # West tower starts z=2.84; the lane ends at z=2.51.
    var advanced: bool=level==3
    var center_x: float=-7.04 if advanced else -6.0
    var center_z: float=-0.67 if advanced else -3.47
    _box(zone,"SueloPista",
        Vector3(center_x,0.054,center_z),
        Vector3(1.53 if advanced else 2.68,0.06,
            6.36 if advanced else 4.33),TRAINING)
    var obstacles: int=2 if level==1 else 4 if level==2 else 6
    for i in range(obstacles):
        var z: float=-3.42+float(i)*0.93 if advanced else -5.1+float(i)*0.70
        var x: float=(-7.29+float(i%2)*0.49) if advanced else             (-6.60+float(i%2)*1.22)
        _box(zone,"BarricadaDePractica_%d" % i,
            Vector3(x,0.27,z),
            Vector3(0.41 if advanced else 0.72,0.51,0.26),
            RUST if damage>=3 else STEEL)
    if level>=2 and damage<=2:
        for i in range(3):
            _cylinder(zone,"PosteEjercicio_%d" % i,
                Vector3(-7.55+float(i)*0.49 if advanced else                     -7.02+float(i)*0.91,
                    1.25,1.86 if advanced else -1.72),
                0.07,2.50,DARK)
        _box(zone,"BarraSuperiorEjercicio",
            Vector3(center_x,2.53,1.86 if advanced else -1.72),
            Vector3(1.15 if advanced else 2.04,0.11,0.15),STEEL,0.42)
    if advanced and damage<=1:
        for i in range(3):
            _box(zone,"MuroEscalada_%d" % i,
                Vector3(-7.49+float(i)*0.45,0.73,0.62),
                Vector3(0.33,1.46,0.27),PALE)
        _box(zone,"TroncoEquilibrio",
            Vector3(center_x,0.51,2.28),
            Vector3(1.23,0.18,0.29),DARK,0.40)

static func _tower(root: Node3D,label: String,x: float,z: float,
        height: float,damage: int,accent: Color) -> void:
    if damage>=3:
        _box(root,"BaseTorreCaida_"+label,
            Vector3(x,0.23,z),Vector3(1.45,0.41,1.45),RUST)
        return
    var t:=_group(root,label)
    _box(t,"BaseTorre",Vector3(x,0.28,z),
        Vector3(1.62,0.52,1.62),CONCRETE)
    for dx in [-1,1]:
        for dz in [-1,1]:
            _box(t,"Poste_%d_%d" % [dx,dz],
                Vector3(x+float(dx)*0.56,height*0.5,
                    z+float(dz)*0.56),
                Vector3(0.13,height,0.13),STEEL,0.41)
    _box(t,"PlataformaElevada",Vector3(x,height+0.08,z),
        Vector3(1.92,0.23,1.92),CONCRETE)
    for side in [-1,1]:
        _box(t,"CristalObservacion_%d" % side,
            Vector3(x+float(side)*0.70,height+0.74,z),
            Vector3(0.07,0.87,1.32),GLASS,0.22)
        _box(t,"ProteccionPasarela_%d" % side,
            Vector3(x,height+0.74,z+float(side)*0.78),
            Vector3(1.76,0.13,0.16),STEEL,0.31)
    if damage<=1:
        _box(t,"CubiertaTorre",Vector3(x,height+1.35,z),
            Vector3(2.15,0.24,2.15),ROOF,0.26)
        _box(t,"FranjaFaccionTorre",
            Vector3(x,height+1.49,z-0.91),
            Vector3(1.56,0.08,0.11),accent)

static func _flag(root: Node3D,level: int,damage: int,accent: Color) -> void:
    if damage>=2:
        return
    var f:=_group(root,"MastilYBanderaFaccion")
    var x: float=5.69 if level<3 else 0.13
    var z: float=-4.95
    _cylinder(f,"Mastil",Vector3(x,2.21,z),
        0.060,4.41,STEEL)
    _box(f,"BanderaTARVOKA",
        Vector3(x+0.68,3.82,z),
        Vector3(1.34,0.68,0.055),accent)
    _box(f,"SimboloAbstractoClaro",
        Vector3(x+0.71,3.81,z-0.046),
        Vector3(0.32,0.32,0.028),PALE)

static func _level_one(root: Node3D,damage: int,accent: Color) -> void:
    var stage:=_group(root,"Nivel1_BarracaUnPisoCompacta")
    _building(stage,"BarracaUnPisoN1",
        -1.70,1.95,7.30,4.28,2.94,1,damage,accent,true)
    if damage<=2:
        _box(stage,"ArmarioEquipoExteriorN1",
            Vector3(4.42,0.79,2.05),
            Vector3(1.20,1.57,1.43),STEEL,0.32)
        _box(stage,"CubiertaArmarioEquipoN1",
            Vector3(4.42,1.60,2.05),
            Vector3(1.43,0.15,1.58),ROOF)
    _training(root,1,damage)
    _flag(root,1,damage,accent)

static func _level_two(root: Node3D,damage: int,accent: Color) -> void:
    var stage:=_group(root,"Nivel2_BarracasL_DosPlantas")
    _building(stage,"BarracaPrincipalDosPisosN2",
        -2.06,2.03,7.56,4.54,4.85,2,damage,accent,true)
    _building(stage,"AlaInstruccionN2",
        3.36,1.40,3.42,5.39,3.09,1,damage,accent)
    if damage<=2:
        _box(stage,"PasarelaConexionN2",
            Vector3(1.54,2.42,2.02),
            Vector3(0.47,0.20,1.93),STEEL,0.41)
    _tower(stage,"TorreSupervisionNivel2",
        5.67,-2.77,3.72,damage,accent)
    _training(root,2,damage)
    _flag(root,2,damage,accent)

static func _level_three(root: Node3D,damage: int,accent: Color) -> void:
    var stage:=_group(root,"Nivel3_ComplejoEnU_TresPlantas")
    _building(stage,"ComandoCentralTresPisosN3",
        0,2.62,8.56,3.48,6.88,3,damage,accent,true)
    _building(stage,"AlaOesteDosPisosN3",
        -4.58,-0.20,3.01,6.21,4.86,2,damage,accent)
    _building(stage,"AlaEsteDosPisosN3",
        4.58,-0.20,3.01,6.21,4.86,2,damage,accent)
    if damage<=2:
        for side in [-1,1]:
            _box(stage,"PasarelaElevadaN3_%d" % side,
                Vector3(float(side)*3.44,3.92,2.08),
                Vector3(1.84,0.20,1.12),STEEL,0.42)
        _box(stage,"PatioCentralU_N3",
            Vector3(0,0.08,-1.94),
            Vector3(5.81,0.08,2.43),CONCRETE)
        for i in range(4):
            _box(stage,"MarcacionDespliegueN3_%d" % i,
                Vector3(-2.29+float(i)*1.52,0.130,-1.95),
                Vector3(0.08,0.015,1.75),SAFETY)
    _tower(stage,"TorreOesteNivel3",
        -6.47,3.65,4.93,damage,accent)
    _tower(stage,"TorreEsteNivel3",
        6.47,3.65,4.93,damage,accent)
    if damage<=1:
        _box(stage,"EscudoMandoFaccionN3",
            Vector3(0,5.95,0.71),
            Vector3(2.48,0.41,0.11),accent,0.21)
    _training(root,3,damage)
    _flag(root,3,damage,accent)

static func build(level: int,faction: int,damage: int) -> Node3D:
    if not valid_spec(level,faction,damage):
        return null
    var result:=Node3D.new()
    result.name=STAGE_NAME
    result.set_meta("tarvoka_infantry_barracks_v1",true)
    result.set_meta("tarvoka_building_kind","infantry_barracks_visual")
    result.set_meta("visual_only",true)
    result.set_meta("visual_level",level)
    result.set_meta("visual_faction",faction)
    result.set_meta("visual_damage_stage",damage)
    result.set_meta("visual_massing",[
        "one_floor_compact","two_floor_L_one_tower",
        "three_floor_U_two_towers"][level-1])
    var accent: Color=Style.faction_color(faction)
    _ground(result,level,damage,accent)
    if damage<4:
        match level:
            1: _level_one(result,damage,accent)
            2: _level_two(result,damage,accent)
            3: _level_three(result,damage,accent)
    return result

static func mesh_count(node: Node) -> int:
    var total: int=1 if node is MeshInstance3D else 0
    for child in node.get_children():
        total+=mesh_count(child)
    return total
