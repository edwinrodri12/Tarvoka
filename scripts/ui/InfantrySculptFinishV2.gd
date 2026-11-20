extends RefCounted
class_name TarvokaInfantrySculptFinishV2

# Sculpt pass on the EXISTING InfantryFamilyV1 rig: actual sealed, nontransparent
# Godot 4.3 3D surfaces. No tactical roles, stats, saves, or economy.
const FLAG := "tarvoka_infantry_sculpt_finish_v2"
const ROOT := "AcabadoInfanteriaV2"
const SLEEVE := Color("#53655b")
const FABRIC := Color("#637265")
const DARK_FABRIC := Color("#36483e")
const ARMOR := Color("#85938f")
const RIM := Color("#29383c")
const RUBBER := Color("#202a2c")
const METAL := Color("#a7b5b5")
const SKIN := Color("#bd9178")
const GLASS := Color("#204c63")

static func _coat(color: Color, metal: float = 0.0, rough: float = 0.66,
        clear: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(color.r,color.g,color.b,1.0)
    m.metallic = metal
    m.roughness = rough
    m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    if clear:
        m.clearcoat_enabled = true
        m.clearcoat = 0.92
        m.clearcoat_roughness = 0.1
    return m

static func _mesh(parent: Node3D, label: String, mesh: Mesh, coat: StandardMaterial3D,
        pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.material_override = coat
    node.position = pos
    node.rotation_degrees = rot
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, pos: Vector3, dims: Vector3,
        mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var b := BoxMesh.new()
    b.size = dims
    return _mesh(parent,label,b,mat,pos,rot)

static func _sphere(parent: Node3D, label: String, pos: Vector3, dims: Vector3,
        mat: StandardMaterial3D) -> MeshInstance3D:
    var s := SphereMesh.new()
    s.radius = 0.5
    s.height = 1.0
    s.radial_segments = 16
    s.rings = 8
    var n := _mesh(parent,label,s,mat,pos)
    n.scale = dims
    return n

static func _ring_pt(radius: Vector3, segment: int, total: int) -> Vector3:
    var angle: float = TAU*float(segment)/float(total)
    return Vector3(cos(angle)*radius.x,radius.y,sin(angle)*radius.z)

# Every segment is physically capped at each end: no floating cylinders,
# open-sided planes, cut-off legs, backpack shells or faceless proxy surfaces.
static func _organic(parent: Node3D, label: String, pos: Vector3,
        rings: Array[Vector3], material: StandardMaterial3D,
        sides: int = 12) -> MeshInstance3D:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int = maxi(8,sides)
    for row in range(rings.size()-1):
        for i in range(count):
            var a: Vector3 = _ring_pt(rings[row],i,count)
            var b: Vector3 = _ring_pt(rings[row],(i+1)%count,count)
            var c: Vector3 = _ring_pt(rings[row+1],i,count)
            var d: Vector3 = _ring_pt(rings[row+1],(i+1)%count,count)
            # Ring vertices progress from bottom -> top and outward-facing.
            for v in [a,c,b,b,c,d]:
                tool.add_vertex(v)
    var low: Vector3 = Vector3(0,rings[0].y,0)
    var top: Vector3 = Vector3(0,rings[-1].y,0)
    for i in range(count):
        var lower: Vector3 = _ring_pt(rings[0],i,count)
        var lower_next: Vector3 = _ring_pt(rings[0],(i+1)%count,count)
        for v in [low,lower,lower_next]:
            tool.add_vertex(v)
        var upper: Vector3 = _ring_pt(rings[-1],i,count)
        var upper_next: Vector3 = _ring_pt(rings[-1],(i+1)%count,count)
        for v in [top,upper_next,upper]:
            tool.add_vertex(v)
    tool.generate_normals()
    var sculpt: ArrayMesh = tool.commit()
    return _mesh(parent,label,sculpt,material,pos)

# Eight-point rounded ballistic plate, a closed bevelled ArrayMesh, instead
# of a flat square attached to the soldier's torso.
static func _plate(parent: Node3D, name: String, center: Vector3,
        w: float, h: float, depth: float, mat: StandardMaterial3D) -> MeshInstance3D:
    var shape := [
        Vector2(-0.25,0.50),Vector2(0.25,0.50),
        Vector2(0.47,0.34),Vector2(0.45,-0.33),
        Vector2(0.19,-0.50),Vector2(-0.19,-0.50),
        Vector2(-0.45,-0.33),Vector2(-0.47,0.34)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var layers: Array[Vector2] = [
        Vector2(1.0,depth*0.5),
        Vector2(1.0,-depth*0.5+0.025),
        Vector2(0.89,-depth*0.5)
    ]
    for k in range(layers.size()-1):
        for i in range(shape.size()):
            var j: int=(i+1)%shape.size()
            var v0 := Vector3(shape[i].x*w*layers[k].x,
                shape[i].y*h*layers[k].x,layers[k].y)
            var v1 := Vector3(shape[j].x*w*layers[k].x,
                shape[j].y*h*layers[k].x,layers[k].y)
            var v2 := Vector3(shape[i].x*w*layers[k+1].x,
                shape[i].y*h*layers[k+1].x,layers[k+1].y)
            var v3 := Vector3(shape[j].x*w*layers[k+1].x,
                shape[j].y*h*layers[k+1].x,layers[k+1].y)
            for vertex in [v0,v1,v2,v1,v3,v2]:
                st.add_vertex(vertex)
    # Both caps cover the full silhouette and seal every side wall.
    for i in range(shape.size()):
        var j: int=(i+1)%shape.size()
        var a: Vector2=shape[i]
        var b: Vector2=shape[j]
        for v in [
            Vector3(0,0,depth*0.5),
            Vector3(b.x*w,b.y*h,depth*0.5),
            Vector3(a.x*w,a.y*h,depth*0.5),
            Vector3(0,0,-depth*0.5),
            Vector3(a.x*w*0.89,a.y*h*0.89,-depth*0.5),
            Vector3(b.x*w*0.89,b.y*h*0.89,-depth*0.5)
        ]:
            st.add_vertex(v)
    st.generate_normals()
    return _mesh(parent,name,st.commit(),mat,center)

static func _find(root: Node3D, part: String) -> Node3D:
    return root.find_child(part,true,false) as Node3D

static func _hide(root: Node3D, part: String) -> void:
    var target: Node3D=_find(root,part)
    if target != null:
        target.visible=false

static func _child(parent: Node3D, label: String) -> Node3D:
    var n := Node3D.new()
    n.name=label
    parent.add_child(n)
    return n

static func apply(model: Node3D, faction_paint: Color, hero: bool) -> bool:
    if model == null or not bool(model.get_meta("tarvoka_infantry_family_v1",false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return false
    var soldier: Node3D=_find(model,"Infanteria_3D")
    var upper: Node3D=_find(model,"TorsoRig")
    var head: Node3D=_find(model,"CabezaRig")
    if soldier==null or upper==null or head==null:
        return false
    var paint: Color=Color(faction_paint.r,faction_paint.g,faction_paint.b,1.0)
    var fabric: StandardMaterial3D=_coat(FABRIC,0.02,0.87)
    var dark: StandardMaterial3D=_coat(DARK_FABRIC,0.0,0.91)
    var seam: StandardMaterial3D=_coat(SLEEVE,0.05,0.79)
    var armor: StandardMaterial3D=_coat(ARMOR,0.24,0.42)
    var rubber: StandardMaterial3D=_coat(RUBBER,0.01,0.88)
    var metal: StandardMaterial3D=_coat(METAL,0.56,0.31)
    var glass: StandardMaterial3D=_coat(GLASS,0.19,0.085,true)
    var faction: StandardMaterial3D=_coat(paint,0.13,0.43)
    var skin: StandardMaterial3D=_coat(SKIN,0.0,0.92)
    var core: Node3D=_child(soldier,ROOT)
    # Bevelled closed armor replaces the two flat rectangular panels.
    _hide(model,"CorazaFrontal")
    _hide(model,"FaccionPecho")
    _hide(model,"MochilaRigida")
    _hide(model,"CascoSolido")
    _hide(model,"ViseraBlindada")
    _hide(model,"VisorSellado")
    _plate(upper,"V2_CorazaPectoralHermetica",Vector3(0,0.03,-0.28),
        0.68,0.55,0.13,armor)
    _plate(upper,"V2_FaccionPechoArticulada",Vector3(0,0.215,-0.366),
        0.40,0.09,0.034,faction)
    for side in [-1,1]:
        _plate(upper,"V2_CostillaArmadura_%d"%side,
            Vector3(float(side)*0.33,-0.11,-0.08),0.15,0.27,0.07,armor)
        _box(upper,"V2_CinchaPortaequipo_%d"%side,
            Vector3(float(side)*0.23,0.01,0.285),
            Vector3(0.075,0.61,0.05),dark,Vector3(0,0,float(side)*-9))
        _box(upper,"V2_FaccionCincha_%d"%side,
            Vector3(float(side)*0.27,0.24,0.321),
            Vector3(0.058,0.12,0.018),faction)
    # A real softened sealed rucksack: visible rear straps, pouches and
    # faction paint. The old giant cube had obscured the entire upper body.
    _organic(upper,"V2_MochilaOrganica",Vector3(0,0.00,0.32),[
        Vector3(0.17,-0.35,0.08),Vector3(0.26,-0.27,0.155),
        Vector3(0.29,0.06,0.18),Vector3(0.25,0.31,0.13),
        Vector3(0.13,0.35,0.075)
    ],fabric,14 if hero else 10)
    _plate(upper,"V2_FaccionMochilaDorsal",Vector3(0,0.145,0.509),
        0.38,0.135,0.035,faction)
    _box(upper,"V2_CierreMochila",Vector3(0,-0.135,0.513),
        Vector3(0.18,0.09,0.027),rubber)
    if hero:
        for side in [-1,1]:
            _organic(upper,"V2_BolsilloCurvo_%d"%side,
                Vector3(float(side)*0.22,-0.205,0.46),[
                Vector3(0.11,-0.115,0.065),Vector3(0.13,-0.04,0.088),
                Vector3(0.115,0.09,0.073),Vector3(0.095,0.14,0.05)
            ],dark,9)
        for row in range(3):
            _box(upper,"V2_PespunteHorizontal_%02d"%row,
                Vector3(0,0.11-float(row)*0.11,-0.366),
                Vector3(0.48,0.018,0.021),dark)
        for x in [-1,1]:
            _box(upper,"V2_BolsilloPeitoral_%d"%x,
                Vector3(float(x)*0.195,-0.07,-0.392),
                Vector3(0.14,0.16,0.055),dark)

    # Organic closed helmet with real brow, shell, cheek protection and opaque
    # optically glossy visor. No holes or transparent glass on the rear view.
    _organic(head,"V2_CascoEsferoideCerrado",Vector3(0,0,0.02),[
        Vector3(0.22,0.16,0.21),Vector3(0.29,0.26,0.28),
        Vector3(0.29,0.42,0.30),Vector3(0.23,0.56,0.24),
        Vector3(0.08,0.635,0.09)
    ],armor,16 if hero else 10)
    _box(head,"V2_BordeFrontalCasco",Vector3(0,0.37,-0.29),
        Vector3(0.50,0.09,0.13),rubber)
    _box(head,"V2_VisorOpacoPBR",Vector3(0,0.235,-0.247),
        Vector3(0.37,0.15,0.091),glass)
    _box(head,"V2_ReflejoCristalFisico",Vector3(-0.10,0.271,-0.295),
        Vector3(0.11,0.014,0.010),metal,Vector3(0,0,-17))
    _plate(head,"V2_FaccionCasco",Vector3(0,0.58,-0.065),
        0.36,0.085,0.052,faction)
    var scar: MeshInstance3D=_box(head,"V2_CicatrizCasco",
        Vector3(0.18,0.36,-0.286),Vector3(0.10,0.024,0.035),
        _coat(Color("#342e2c"),0.07,0.82),Vector3(0,0,-38))
    scar.visible=false
    _sphere(head,"V2_ProteccionBarbilla",Vector3(0,0.054,-0.205),
        Vector3(0.28,0.12,0.13),seam)
    for side in [-1,1]:
        _sphere(head,"V2_Mejilla_%d"%side,
            Vector3(float(side)*0.145,0.115,-0.178),
            Vector3(0.14,0.16,0.14),skin)
        _sphere(head,"V2_OrejeraMoldeada_%d"%side,
            Vector3(float(side)*0.284,0.275,0),
            Vector3(0.105,0.255,0.255),rubber)
        if hero:
            _box(head,"V2_OrejerasFijacion_%d"%side,
                Vector3(float(side)*0.334,0.25,0),
                Vector3(0.018,0.105,0.13),metal)
    # Human taper and cloth folds replace the original boxed legs and arms.
    for side in [-1,1]:
        var leg: Node3D=_find(model,"PiernaRig_%d"%side)
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        if leg==null or arm==null:
            return false
        for old_part in ["Muslo_%d"%side,"Espinillera_%d"%side,"Bota_%d"%side]:
            _hide(leg,old_part)
        for old_part in ["Manga_%d"%side,"Antebrazo_%d"%side,"Guante_%d"%side]:
            _hide(arm,old_part)
        _organic(leg,"V2_MusloTaper_%d"%side,Vector3(0,0,0.02),[
            Vector3(0.13,-0.50,0.135),Vector3(0.145,-0.42,0.165),
            Vector3(0.16,-0.18,0.18),Vector3(0.15,0.01,0.17)
        ],fabric,14 if hero else 9)
        _organic(leg,"V2_PantorrillaTaper_%d"%side,Vector3(0,0,-0.03),[
            Vector3(0.115,-0.87,0.125),Vector3(0.125,-0.75,0.135),
            Vector3(0.14,-0.57,0.155),Vector3(0.125,-0.46,0.145)
        ],seam,12 if hero else 9)
        _box(leg,"V2_Suela_%d"%side,Vector3(0,-0.93,-0.128),
            Vector3(0.25,0.075,0.45),rubber)
        _organic(leg,"V2_BotaMoldeada_%d"%side,Vector3(0,0,-0.14),[
            Vector3(0.115,-0.895,0.16),Vector3(0.12,-0.81,0.19),
            Vector3(0.11,-0.68,0.14)
        ],dark,12 if hero else 9)
        _sphere(leg,"V2_PunteraProtegida_%d"%side,
            Vector3(0,-0.85,-0.31),Vector3(0.24,0.13,0.19),rubber)
        _organic(arm,"V2_MangaCerrada_%d"%side,Vector3(0,0,0.005),[
            Vector3(0.105,-0.52,0.115),Vector3(0.14,-0.34,0.145),
            Vector3(0.16,-0.10,0.16),Vector3(0.17,0.055,0.15)
        ],fabric,12 if hero else 9)
        _organic(arm,"V2_AntebrazoCerrado_%d"%side,Vector3(0,0,-0.085),[
            Vector3(0.104,-0.72,0.115),Vector3(0.115,-0.59,0.115),
            Vector3(0.12,-0.46,0.125)
        ],seam,12 if hero else 9)
        _sphere(arm,"V2_PalmaGuante_%d"%side,
            Vector3(0,-0.772,-0.135),Vector3(0.215,0.20,0.19),rubber)
        _box(arm,"V2_FaccionParcheManga_%d"%side,
            Vector3(float(side)*0.151,-0.18,-0.025),
            Vector3(0.023,0.20,0.17),faction)
        if hero:
            for finger in range(4):
                _organic(arm,"V2_DedoGuante_%d_%d"%[side,finger],
                    Vector3(-0.080+float(finger)*0.054,-0.90,-0.20),[
                    Vector3(0.019,-0.06,0.023),
                    Vector3(0.023,0.01,0.027),
                    Vector3(0.017,0.07,0.02)
                ],rubber,8)
            for row in range(3):
                _box(leg,"V2_PlisePantalon_%d_%d"%[side,row],
                    Vector3(0,-0.24-float(row)*0.11,-0.15),
                    Vector3(0.23,0.014,0.025),dark,
                    Vector3(0,0,float(side)*(8+row*3)))
                _box(arm,"V2_PliseManga_%d_%d"%[side,row],
                    Vector3(0,-0.25-float(row)*0.095,-0.147),
                    Vector3(0.21,0.012,0.02),dark)

    # The V1 gun looked like a side-pointing floating rod. V2 adds hand grips,
    # controls and mechanical detail and aims down -Z at a natural angle.
    var weapon: Node3D=_find(model,"ArmamentoRig")
    if weapon==null:
        return false
    var role: String=str(model.get_meta("tarvoka_infantry_role","line"))
    if role!="infantry_antitank":
        _box(weapon,"V2_GuardamanosFusil",Vector3(0.36,0,0),
            Vector3(0.31,0.18,0.20),rubber)
        _box(weapon,"V2_RielSuperior",Vector3(0.18,0.119,-0.008),
            Vector3(0.41,0.032,0.15),metal)
        _box(weapon,"V2_Empunadura",Vector3(0.025,-0.18,0),
            Vector3(0.083,0.30,0.093),dark,Vector3(0,0,-12))
        _box(weapon,"V2_FaccionCargador",Vector3(0,-0.23,-0.079),
            Vector3(0.10,0.13,0.02),faction)
        if hero:
            for cut in range(4):
                _box(weapon,"V2_RanuraGuardamanos_%02d"%cut,
                    Vector3(0.25+float(cut)*0.085,0.09,-0.104),
                    Vector3(0.033,0.025,0.014),metal)
    else:
        _box(weapon,"V2_ProteccionOpticaAT",Vector3(-0.12,0.28,0),
            Vector3(0.33,0.095,0.17),rubber)
        _box(weapon,"V2_FaccionCarcasaAT",Vector3(-0.12,0.334,-0.005),
            Vector3(0.21,0.024,0.14),faction)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_infantry_v2_hero",hero)
    model.set_meta("tarvoka_infantry_v2_opaque",true)
    return pose(model,"idle",0.0)

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func pose(model: Node3D, kind: String, t: float) -> bool:
    if not has_model(model):
        return false
    var role: String=str(model.get_meta("tarvoka_infantry_role","line"))
    var rifle: Node3D=_find(model,"ArmamentoRig")
    if rifle==null:
        return false
    var phase: float=clampf(t,0.0,1.0)
    # Rifle points forward, not horizontally across the preview screenshot.
    rifle.rotation_degrees=Vector3(-6,67,0) if role!="infantry_antitank" else Vector3(-9,64,-12)
    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        if arm==null:
            return false
        arm.rotation_degrees.x=49.0 if role!="infantry_antitank" else 56.0
        arm.rotation_degrees.z=float(side)*-8.0
        if kind=="move":
            arm.rotation_degrees.x+=5.0*sin(phase*TAU*2.0+float(side)*PI*0.5)
        elif kind in ["attack","aim"]:
            arm.rotation_degrees.x+=4.0
        elif kind in ["work","repair","capture"]:
            arm.rotation_degrees.x=37.0+12.0*sin(phase*PI)
    if kind=="attack":
        rifle.rotation_degrees.x-=4.0*sin(phase*PI)
    if role=="infantry_antitank":
        rifle.rotation_degrees.y=64.0
    # Damage remains owned by V1 and survives pose changes. Never amend HP.
    var stage: int=int(model.get_meta("tarvoka_infantry_damage",0))
    var scar: Node3D=_find(model,"V2_CicatrizCasco")
    if scar!=null:
        scar.visible=stage>=3
    return true

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    pose(model,"idle",0.0)
