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
static func _organic_mesh(rings: Array[Vector3], sides: int=12,
        offsets: PackedFloat32Array=PackedFloat32Array(), shape: float=1.0) -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int = maxi(8,sides)
    var points: Array[PackedVector3Array] = []
    for row in range(rings.size()):
        var ring := PackedVector3Array()
        var shift: float = offsets[row] if offsets.size()==rings.size() else 0.0
        for i in range(count):
            var pt: Vector3 = _ring_pt(rings[row],i,count)
            if shape!=1.0:
                var angle: float = TAU*float(i)/float(count)
                pt.x = signf(cos(angle))*pow(absf(cos(angle)),shape)*rings[row].x
                pt.z = signf(sin(angle))*pow(absf(sin(angle)),shape)*rings[row].z
            pt.z += shift
            ring.append(pt)
        points.append(ring)
    for row in range(rings.size()-1):
        for i in range(count):
            var a: Vector3 = points[row][i]
            var b: Vector3 = points[row][(i+1)%count]
            var c: Vector3 = points[row+1][i]
            var d: Vector3 = points[row+1][(i+1)%count]
            # Godot front faces use clockwise winding viewed from outside.
            for v in [a,b,c,b,d,c]:
                tool.add_vertex(v)
    var low: Vector3 = Vector3(0,rings[0].y,offsets[0] if offsets.size()==rings.size() else 0.0)
    var top: Vector3 = Vector3(0,rings[-1].y,offsets[-1] if offsets.size()==rings.size() else 0.0)
    for i in range(count):
        var lower: Vector3 = points[0][i]
        var lower_next: Vector3 = points[0][(i+1)%count]
        for v in [low,lower_next,lower]:
            tool.add_vertex(v)
        var upper: Vector3 = points[-1][i]
        var upper_next: Vector3 = points[-1][(i+1)%count]
        for v in [top,upper,upper_next]:
            tool.add_vertex(v)
    tool.generate_normals()
    return tool.commit()

static func _organic(parent: Node3D, label: String, pos: Vector3,
        rings: Array[Vector3], material: StandardMaterial3D,
        sides: int = 12) -> MeshInstance3D:
    return _mesh(parent,label,_organic_mesh(rings,sides),material,pos)

# Refine only the five remaining official infantry identities. Keep G05
# and the legacy studies untouched; keep all rig pivots and node names.
const FAMILY_ANATOMY_V5 := "tarvoka_infantry_family_anatomy_v5"
const FAMILY_ANATOMY_ROLES := ["line","infantry_commando","infantry_sniper","infantry_logistic","infantry_medic"]

static func _resculpt(model: Node3D, label: String, profile: Array[Vector3],
        pos: Vector3, sides: int, offsets: PackedFloat32Array=PackedFloat32Array(),
        shape: float=1.0) -> bool:
    var part: MeshInstance3D = _find(model,label) as MeshInstance3D
    if part==null:
        return false
    part.mesh = _organic_mesh(profile,sides,offsets,shape)
    part.position = pos
    part.scale = Vector3.ONE
    part.set_meta(FAMILY_ANATOMY_V5,true)
    return true

static func _refine_core(model: Node3D, hero: bool) -> bool:
    var sides: int = 16 if hero else 10
    if not _resculpt(model,"PetoBase",[
            Vector3(0.20,-0.46,0.15),Vector3(0.27,-0.37,0.20),
            Vector3(0.32,-0.18,0.235),Vector3(0.365,0.075,0.27),
            Vector3(0.345,0.26,0.235),Vector3(0.19,0.41,0.15)],
            Vector3.ZERO,sides):
        return false
    if not _resculpt(model,"CinturaEquipo",[
            Vector3(0.19,-0.17,0.115),Vector3(0.27,-0.115,0.175),
            Vector3(0.30,0.015,0.195),Vector3(0.26,0.12,0.17),
            Vector3(0.18,0.16,0.11)],Vector3.ZERO,sides):
        return false
    for side in [-1,1]:
        var suffix: String = "_%d"%side
        if not _resculpt(model,"Hombrera"+suffix,[
                Vector3(0.113,-0.145,0.118),Vector3(0.156,-0.10,0.147),
                Vector3(0.164,-0.025,0.158),Vector3(0.138,0.065,0.137),
                Vector3(0.075,0.101,0.08)],Vector3(0,0,-0.04),sides):
            return false
        if not _resculpt(model,"V2_MangaCerrada"+suffix,[
                Vector3(0.102,-0.52,0.112),Vector3(0.123,-0.37,0.132),
                Vector3(0.142,-0.16,0.145),Vector3(0.142,-0.03,0.139),
                Vector3(0.117,0.06,0.119)],Vector3(0,0,0.005),sides):
            return false
        if not _resculpt(model,"V2_AntebrazoCerrado"+suffix,[
                Vector3(0.087,-0.755,0.096),Vector3(0.106,-0.66,0.119),
                Vector3(0.123,-0.55,0.131),Vector3(0.116,-0.46,0.122),
                Vector3(0.103,-0.42,0.111)],Vector3(0,0,-0.060),sides):
            return false
        if not _resculpt(model,"Rodillera"+suffix,[
                Vector3(0.077,-0.085,0.034),Vector3(0.109,-0.052,0.056),
                Vector3(0.111,0.042,0.058),Vector3(0.078,0.082,0.036)],
                Vector3(0,-0.48,-0.15),sides,PackedFloat32Array(),0.72):
            return false
        if not _resculpt(model,"V2_BotaMoldeada"+suffix,[
                Vector3(0.112,-0.925,0.196),Vector3(0.126,-0.875,0.204),
                Vector3(0.121,-0.815,0.181),Vector3(0.114,-0.74,0.15),
                Vector3(0.103,-0.655,0.126)],Vector3(0,0,-0.14),sides,
                PackedFloat32Array([0.0,0.0,0.025,0.065,0.10]),0.78):
            return false
        if not _resculpt(model,"V2_Suela"+suffix,[
                Vector3(0.108,-0.9675,0.206),Vector3(0.127,-0.954,0.225),
                Vector3(0.127,-0.91,0.225),Vector3(0.114,-0.8925,0.21)],
                Vector3(0,0,-0.128),sides,PackedFloat32Array(),0.62):
            return false
        _hide(model,"V2_PunteraProtegida"+suffix)
        var badge: MeshInstance3D = _find(model,"FaccionHombro"+suffix) as MeshInstance3D
        if badge!=null:
            badge.position.x=float(side)*0.151
            badge.scale=Vector3(1,0.68,0.76)
        var patch: MeshInstance3D = _find(model,"V2_FaccionParcheManga"+suffix) as MeshInstance3D
        if patch!=null:
            patch.position.x=float(side)*0.132
        for row in range(3):
            _hide(model,"V2_PliseManga_%d_%d"%[side,row])
    model.set_meta(FAMILY_ANATOMY_V5,true)
    return _attach_family_grips(model,hero)

const FAMILY_GRIPS_V5 := "tarvoka_infantry_grip_contacts_v5"

static func family_grip_point(side: int) -> Vector3:
    return Vector3(-0.04,-0.225,-0.052) if side>0 else Vector3(0.44,-0.155,-0.065)

# Reuse the existing gloves, fingers and forearms. No new draw calls.
# The forearm becomes a tapered link with its origin/length solved in
# the original arm frame; the palm is a child of the actual weapon rig.
static func _attach_family_grips(model: Node3D, hero: bool) -> bool:
    var gun: Node3D = _find(model,"ArmamentoRig")
    if gun==null:
        return false
    for side in [-1,1]:
        if _find(model,"BrazoRig_%d"%side)==null or _find(model,"V2_PalmaGuante_%d"%side)==null or _find(model,"V2_AntebrazoCerrado_%d"%side)==null:
            return false
    for side in [-1,1]:
        var arm: Node3D = _find(model,"BrazoRig_%d"%side)
        var palm: MeshInstance3D = _find(model,"V2_PalmaGuante_%d"%side) as MeshInstance3D
        var link: MeshInstance3D = _find(model,"V2_AntebrazoCerrado_%d"%side) as MeshInstance3D
        if palm.get_parent()!=arm or link.get_parent()!=arm:
            return false
        arm.remove_child(palm)
        gun.add_child(palm)
        palm.position=family_grip_point(side)
        palm.rotation_degrees=Vector3.ZERO
        palm.scale=Vector3(0.165,0.18,0.185)
        for finger in range(4):
            var digit: Node3D = _find(model,"V2_DedoGuante_%d_%d"%[side,finger])
            if digit==null:
                continue
            arm.remove_child(digit)
            gun.add_child(digit)
            digit.position=family_grip_point(side)+Vector3((float(finger)-1.5)*0.041,-0.071,-0.046)
            digit.rotation_degrees=Vector3(12,0,0)
            digit.scale=Vector3(0.85,0.76,0.85)
        link.mesh=_organic_mesh([
            Vector3(0.095,-0.5,0.108),Vector3(0.118,-0.31,0.126),
            Vector3(0.112,-0.05,0.118),Vector3(0.091,0.24,0.096),
            Vector3(0.066,0.5,0.072)],16 if hero else 10)
    model.set_meta(FAMILY_GRIPS_V5,true)
    return _sync_family_grips(model)

static func _sync_family_grips(model: Node3D) -> bool:
    if not bool(model.get_meta(FAMILY_GRIPS_V5,false)):
        return false
    var gun: Node3D = _find(model,"ArmamentoRig")
    if gun==null:
        return false
    for side in [-1,1]:
        var arm: Node3D = _find(model,"BrazoRig_%d"%side)
        var link: MeshInstance3D = _find(model,"V2_AntebrazoCerrado_%d"%side) as MeshInstance3D
        if arm==null or link==null:
            return false
        # Both arm and weapon are children of TorsoRig. Local transforms
        # work even in native QA before the model enters a SceneTree.
        var target: Vector3 = arm.transform.affine_inverse()*(gun.transform*family_grip_point(side))
        var elbow := Vector3(0,-0.47,-0.035)
        var delta: Vector3 = target-elbow
        var length: float = delta.length()
        if length<0.0001:
            return false
        link.position=elbow+delta*0.5
        link.quaternion=Quaternion(Vector3.UP,delta/length)
        link.scale=Vector3(1,length,1)
    return true

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
        Vector2(1.0,-depth*0.5+minf(0.025,depth*0.38)),
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
            for vertex in [v0,v2,v1,v1,v2,v3]:
                st.add_vertex(vertex)
    # Both caps cover the full silhouette and seal every side wall.
    for i in range(shape.size()):
        var j: int=(i+1)%shape.size()
        var a: Vector2=shape[i]
        var b: Vector2=shape[j]
        for v in [
            Vector3(0,0,depth*0.5),
            Vector3(a.x*w,a.y*h,depth*0.5),
            Vector3(b.x*w,b.y*h,depth*0.5),
            Vector3(0,0,-depth*0.5),
            Vector3(b.x*w*0.89,b.y*h*0.89,-depth*0.5),
            Vector3(a.x*w*0.89,a.y*h*0.89,-depth*0.5)
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
    _hide(model,"FaccionMochila")
    _hide(model,"FaccionCasco")
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

    # Tactical color pass V3: bold REAL 3D faction paint on the existing
    # Android LOD8 model. At distant camera zoom the V2 thin stripes vanish.
    # Keep hero-grade details unchanged and preserve the exact official
    # faction palette: no extra tactical roles, billboards, or fake overlays.
    if not hero:
        _plate(upper,"V3_IdentidadPechoMapa",Vector3(0,0.165,-0.412),
            0.53,0.17,0.045,faction)
        _plate(upper,"V3_IdentidadMochilaMapa",Vector3(0,0.15,0.53),
            0.43,0.18,0.045,faction)
        _box(head,"V3_IdentidadFrenteCascoMapa",
            Vector3(0,0.466,-0.296),Vector3(0.35,0.085,0.025),faction)
        for side in [-1,1]:
            var sleeve: Node3D=_find(model,"BrazoRig_%d"%side)
            var shin: Node3D=_find(model,"PiernaRig_%d"%side)
            if sleeve==null or shin==null:
                return false
            _box(sleeve,"V3_IdentidadMangaMapa_%d"%side,
                Vector3(float(side)*0.170,-0.17,-0.043),
                Vector3(0.052,0.28,0.22),faction)
            _box(shin,"V3_IdentidadRodillaMapa_%d"%side,
                Vector3(0,-0.485,-0.207),Vector3(0.235,0.115,0.035),faction)
        model.set_meta("tarvoka_infantry_v3_tactical_identity",true)

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
    # Native 3D attack feedback shares the same rifle rig, never a sprite.
    # Rifle lengths are already defined by InfantryFamilyV1; position the
    # flash on each actual muzzle, not in the character's torso.
    var short_rifle: bool=role in ["scout","infantry_urban","infantry_engineer"]
    var muzzle_x: float=0.91 if role=="infantry_antitank" else (
        0.81 if short_rifle else 1.04)
    var flame: StandardMaterial3D=_coat(Color("#ffc562"),0.0,0.25)
    flame.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    flame.emission_enabled=true
    flame.emission=Color("#ffad32")
    flame.emission_energy_multiplier=1.6
    var flash: MeshInstance3D=_sphere(weapon,"V2_DestelloDisparo3D",
        Vector3(muzzle_x,0.025,0),
        Vector3(0.18,0.11,0.11),flame)
    flash.visible=false
    if hero and role!="infantry_antitank":
        var brass: MeshInstance3D=_box(weapon,"V2_CasquilloFisico",
            Vector3(0.09,0.10,0.21),Vector3(0.10,0.035,0.039),
            _coat(Color("#b69a54"),0.77,0.29),Vector3(0,18,25))
        brass.visible=false

    # Variant-specific V2 outlines retain their original tactical identity
    # without turning them into extra buildable units.
    if role=="infantry_urban":
        _hide(model,"EscudoUrbanoPlegado")
        _hide(model,"FaccionEscudoUrbano")
        _plate(upper,"V2_EscudoUrbanoFacetado",Vector3(-0.36,-0.17,-0.42),
            0.47,0.70,0.10,armor)
        _plate(upper,"V2_FaccionEscudoUrbano",Vector3(-0.36,0.055,-0.483),
            0.29,0.135,0.035,faction)
    elif role=="infantry_defense":
        _hide(model,"ProteccionTorno")
        _hide(model,"FaccionBlindajeDefensivo")
        _plate(upper,"V2_CorazaDefensivaAdicional",Vector3(0,-0.09,-0.38),
            0.70,0.40,0.12,armor)
        _plate(upper,"V2_FaccionDefensiva",Vector3(0,-0.055,-0.463),
            0.47,0.09,0.029,faction)
        for side in [-1,1]:
            _plate(upper,"V2_HombreraDefensiva_%d"%side,
                Vector3(float(side)*0.47,0.275,-0.06),
                0.25,0.28,0.075,armor)
    elif role=="scout":
        _box(upper,"V2_SensorPasivoMochila",Vector3(0.16,0.26,0.48),
            Vector3(0.11,0.14,0.09),metal)
        _box(upper,"V2_FaccionSensor",Vector3(0.16,0.335,0.48),
            Vector3(0.085,0.018,0.072),faction)
    elif role=="infantry_antitank":
        _box(upper,"V2_CargaRepuestoLateral",Vector3(-0.33,-0.28,0.37),
            Vector3(0.20,0.47,0.19),rubber)
        _box(upper,"V2_FaccionCargaAT",Vector3(-0.33,-0.05,0.48),
            Vector3(0.15,0.09,0.018),faction)
    elif role=="infantry_engineer":
        _box(upper,"V2_SujecionHerramienta",Vector3(0.36,-0.22,0.375),
            Vector3(0.13,0.24,0.04),rubber)
        _plate(upper,"V2_FaccionHerramientas",Vector3(-0.34,-0.13,0.51),
            0.20,0.095,0.026,faction)
    if role in FAMILY_ANATOMY_ROLES and not _refine_core(model,hero):
        return false
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
    var pulse: float=sin(phase*PI)
    var walk: float=sin(phase*TAU*2.0)
    # Rifle points forward, not horizontally across the preview screenshot.
    rifle.rotation_degrees=Vector3(-6,67,0) if role!="infantry_antitank" else Vector3(-9,64,-12)
    for side in [-1,1]:
        var arm: Node3D=_find(model,"BrazoRig_%d"%side)
        if arm==null:
            return false
        # In V1 the hands hang far outside the weapon. Opposing shoulder
        # yaw now converges the two covered palms around the real grips.
        arm.rotation_degrees.x=49.0 if role!="infantry_antitank" else 56.0
        arm.rotation_degrees.z=34.0 if side<0 else -24.0
        arm.rotation_degrees.y=6.0 if side<0 else -4.0
        if kind=="move":
            arm.rotation_degrees.x+=3.5*sin(phase*TAU*2.0+float(side)*PI*0.5)
            arm.rotation_degrees.z+=3.0*walk*float(side)
        elif kind in ["attack","aim"]:
            arm.rotation_degrees.x+=5.0
            arm.rotation_degrees.z+=(-3.0 if side<0 else 2.0)*pulse
        elif kind in ["work","repair","capture"]:
            arm.rotation_degrees.x=38.0+14.0*pulse
            arm.rotation_degrees.z=18.0 if side<0 else -14.0
    if kind=="attack":
        rifle.rotation_degrees.x-=6.5*pulse
        rifle.position.z-=0.045*pulse
    elif kind=="aim":
        rifle.rotation_degrees.x-=1.8*pulse
    if role=="infantry_antitank":
        rifle.rotation_degrees.y=64.0
    var head: Node3D=_find(model,"CabezaRig")
    if head!=null:
        head.rotation_degrees.x=2.0+2.5*walk if kind=="move" else (
            -3.5*pulse if kind in ["attack","aim"] else 0.0)
        head.rotation_degrees.y=-4.0*walk if kind=="move" else 0.0
    var flash: Node3D=_find(model,"V2_DestelloDisparo3D")
    if flash!=null:
        flash.visible=kind=="attack" and phase>0.13 and phase<0.53
    var case_mesh: Node3D=_find(model,"V2_CasquilloFisico")
    if case_mesh!=null:
        case_mesh.visible=kind=="attack" and phase>0.26 and phase<0.74
        case_mesh.position=Vector3(0.09,0.10+0.09*pulse,0.21+0.13*pulse)
    # Damage remains owned by V1 and survives pose changes. Never amend HP.
    var stage: int=int(model.get_meta("tarvoka_infantry_damage",0))
    var scar: Node3D=_find(model,"V2_CicatrizCasco")
    if scar!=null:
        scar.visible=stage>=3
    if bool(model.get_meta(FAMILY_GRIPS_V5,false)):
        return _sync_family_grips(model)
    return true

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    pose(model,"idle",0.0)
