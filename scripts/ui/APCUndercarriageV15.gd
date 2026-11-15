extends RefCounted
class_name TarvokaAPCUndercarriageV15

# Bastion P06 V15 -- actual underside 3D sculpture, not an illustration.
# Three visible axle differentials, transfer case, three drive shafts with
# Cardan joints, six 3D V-shaped armor wings and a steering rack linked to
# V14 knuckles. Pure art: no effect on movement/supply/attack/HP.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V14=preload("res://scripts/ui/APCWheelV14.gd")
const FLAG := "tarvoka_apc_undercarriage_v15"
const ROOT := "P06V15_BajosProtegidos"
const ARMOR := "P06V15_BlindajeInferiorEnV"
const DRIVE := "P06V15_Transmision6x6"
const AXLES := "P06V15_ConjuntosTresDiferenciales"
const STEERING := "P06V15_BarrasDireccionDelantera"
const DAMAGE := "P06V15_DanosBajos"
const WRECK := "P06V15_TransmisionRota"
const SHOW := "tarvoka_apc_v15_visible"
const STAGE := "tarvoka_apc_v15_stage"
const ROD_POSITIONS := [-1.04,0.0,1.07]
const SHAFT_NAMES := [
    "P06V15_CardanDelantero",
    "P06V15_CardanIntermedio",
    "P06V15_CardanTrasero"]
const PANEL_BROKEN := "P06V15_PanelV_1_1"
const SHAFT_BROKEN := "P06V15_CardanTrasero"
const DRIVE_PHASE := "tarvoka_apc_v1_phase"

static func _group(parent: Node3D,name: String) -> Node3D:
    var node:=Node3D.new()
    node.name=name
    parent.add_child(node)
    return node

static func _mat(color: Color,metal: float=0.45,
        rough: float=0.77) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _box(parent: Node3D,name: String,pos: Vector3,
        dims: Vector3,paint: Material) -> MeshInstance3D:
    var shape:=BoxMesh.new()
    shape.size=dims
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=shape
    node.material_override=paint
    node.position=pos
    parent.add_child(node)
    return node

static func _cyl(parent: Node3D,name: String,pos: Vector3,
        radius: float,height: float,paint: Material,
        axis: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=height
    shape.radial_segments=12
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=shape
    node.material_override=paint
    node.position=pos
    node.rotation_degrees=axis
    parent.add_child(node)
    return node

static func _ring(parent: Node3D,name: String,pos: Vector3,
        inner: float,outer: float,paint: Material,
        axis: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var torus:=TorusMesh.new()
    torus.inner_radius=inner
    torus.outer_radius=outer
    torus.rings=12
    torus.ring_segments=14
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=torus
    node.material_override=paint
    node.position=pos
    node.rotation_degrees=axis
    parent.add_child(node)
    return node

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for v in [a,b,c,a,c,d]:
        st.add_vertex(v)

static func _plate(parent: Node3D,name: String,
        vertices: Array[Vector3],paint: Material) -> MeshInstance3D:
    # A closed six-face welded volume, not a flat decal/texture hiding the
    # existing V1 blast belly. Mechanism inspection gap remains open at x=0.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var elevated: Array[Vector3]=[]
    for p in vertices:
        elevated.append(p+Vector3(0,0.020,0))
    _quad(st,vertices[0],vertices[1],vertices[2],vertices[3])
    _quad(st,elevated[3],elevated[2],elevated[1],elevated[0])
    for i in range(4):
        var next: int=(i+1)%4
        _quad(st,vertices[i],elevated[i],elevated[next],
            vertices[next])
    st.generate_normals()
    var result:=MeshInstance3D.new()
    result.name=name
    result.mesh=st.commit()
    result.material_override=paint
    parent.add_child(result)
    return result

static func _link(part: Node3D,origin: Vector3,
        ending: Vector3) -> bool:
    if part==null:
        return false
    var span: Vector3=ending-origin
    if span.length()<0.012:
        return false
    part.position=(origin+ending)*0.5
    part.basis=Basis(Quaternion(Vector3.UP,span.normalized()))
    part.scale=Vector3(1.0,span.length(),1.0)
    return true

static func _belly(root: Node3D,armor: Material,
        steel: Material,rubber: Material) -> void:
    var belly:=_group(root,ARMOR)
    # Three sections on each side. Their angled X/Y cross-section follows
    # V1's blast-protected underside; narrow center channel exposes the
    # real 6x6 drivetrain when viewed from below.
    var spans: Array[Vector2]=[
        Vector2(-1.32,-0.56),Vector2(-0.50,0.48),
        Vector2(0.54,1.30)]
    for side in [-1,1]:
        var s: float=float(side)
        for i in range(spans.size()):
            var z0: float=spans[i].x
            var z1: float=spans[i].y
            var quad: Array[Vector3]=[
                Vector3(s*0.177,0.188,z0),
                Vector3(s*0.550,0.424,z0),
                Vector3(s*0.550,0.424,z1),
                Vector3(s*0.177,0.188,z1)]
            _plate(belly,"P06V15_PanelV_%d_%d" % [side,i],
                quad,armor)
            _box(belly,"P06V15_RibeteBorde_%d_%d" % [side,i],
                Vector3(s*0.547,0.424,(z0+z1)*0.5),
                Vector3(0.033,0.028,z1-z0),steel)
        # Skid rails protect the underside without forming a second
        # solid plate that would hide the shaft and differential housings.
        _box(belly,"P06V15_PatinBlindado_%d" % side,
            Vector3(s*0.613,0.410,-0.015),
            Vector3(0.057,0.075,2.56),armor)
        for j in range(3):
            var z: float=float(ROD_POSITIONS[j])
            _box(belly,"P06V15_ProtectorTuboFreno_%d_%d" % [side,j],
                Vector3(s*0.587,0.455,z),
                Vector3(0.037,0.045,0.144),rubber)
    # Access windows in the belly channel: no painted fake holes.
    for z in [-0.51,0.50]:
        _box(belly,"P06V15_TravesanoReal_%d" % int(z*1000.0),
            Vector3(0.0,0.296,z),
            Vector3(0.991,0.073,0.077),steel)
    _box(belly,"P06V15_ProtectorCajaTransferencia",
        Vector3(0,0.169,-0.314),
        Vector3(0.315,0.031,0.250),armor)
    for side in [-1,1]:
        _box(belly,"P06V15_PuntoServicioInferior_%d" % side,
            Vector3(float(side)*0.319,0.317,0.982),
            Vector3(0.088,0.032,0.093),steel)

static func _differentials(root: Node3D,case_mat: Material,
        steel: Material,dark: Material) -> void:
    var group:=_group(root,AXLES)
    for axle in range(3):
        var z: float=float(ROD_POSITIONS[axle])
        var case:=SphereMesh.new()
        case.radius=0.111
        case.height=0.206
        case.radial_segments=16
        case.rings=8
        var n:=MeshInstance3D.new()
        n.name="P06V15_Diferencial_%d" % axle
        n.mesh=case
        n.position=Vector3(0,0.253,z)
        n.material_override=case_mat
        group.add_child(n)
        _cyl(group,"P06V15_TapaRegistroDiferencial_%d" % axle,
            Vector3(0,0.163,z),
            0.066,0.026,steel)
        # The inner stub axles meet the existing V14 half-shafts at x=.39.
        for side in [-1,1]:
            var s: float=float(side)
            _cyl(group,"P06V15_ArbolSalida_%d_%d" % [side,axle],
                Vector3(s*0.252,0.270,z),
                0.034,0.303,dark,Vector3(0,0,90))
            _ring(group,"P06V15_RetenSalida_%d_%d" % [side,axle],
                Vector3(s*0.391,0.270,z),
                0.038,0.061,steel,Vector3(0,0,90))
            for j in range(2):
                _ring(group,"P06V15_GuardaJunta_%d_%d_%d" % [side,axle,j],
                    Vector3(s*(0.329+float(j)*0.038),0.270,z),
                    0.038,0.057,dark,Vector3(0,0,90))
        # Locking ribs reinforce the differential casing near the belly.
        for side in [-1,1]:
            _box(group,"P06V15_CartelaSoporteDiferencial_%d_%d" %
                [side,axle],Vector3(float(side)*0.109,0.338,z),
                Vector3(0.048,0.074,0.092),steel)

static func _cardan(root: Node3D,name: String,
        from: Vector3,to: Vector3,
        steel: Material,dark: Material) -> void:
    var parent:=_group(root,name)
    var shaft:=_cyl(parent,"P06V15_TuboTransmision",
        Vector3.ZERO,0.042,1.0,dark)
    _link(shaft,from,to)
    for i in range(2):
        var t: float=0.17 if i==0 else 0.83
        var where: Vector3=from.lerp(to,t)
        _cyl(parent,"P06V15_ManguitoDeslizante_%d" % i,
            where,0.058,0.091,steel,
            Vector3(90,0,0))
    var origin:=_group(parent,"P06V15_CrucetaCardan")
    origin.position=to
    # Two nonparallel arms make shaft rotation visually legible; only the
    # joint rotates around Z, while the main propeller tube remains fixed.
    _box(origin,"P06V15_BrazoCruceta_X",Vector3.ZERO,
        Vector3(0.157,0.031,0.031),steel)
    _box(origin,"P06V15_BrazoCruceta_Y",Vector3.ZERO,
        Vector3(0.031,0.157,0.031),steel)
    _ring(parent,"P06V15_CoronaCardan",
        to,0.061,0.083,steel,Vector3(90,0,0))

static func _transfer(root: Node3D,case_mat: Material,
        steel: Material,dark: Material) -> void:
    var drivetrain:=_group(root,DRIVE)
    _box(drivetrain,"P06V15_CajaTransferencia6x6",
        Vector3(0,0.248,-0.316),
        Vector3(0.261,0.154,0.222),case_mat)
    _box(drivetrain,"P06V15_CarterBajoTransferencia",
        Vector3(0,0.173,-0.318),
        Vector3(0.188,0.025,0.178),steel)
    _cyl(drivetrain,"P06V15_CollarTransferencia",
        Vector3(0,0.250,-0.433),0.087,0.055,steel,
        Vector3(90,0,0))
    _cardan(drivetrain,SHAFT_NAMES[0],
        Vector3(0,0.250,-0.435),
        Vector3(0,0.250,-0.930),steel,dark)
    _cardan(drivetrain,SHAFT_NAMES[1],
        Vector3(0,0.250,-0.189),
        Vector3(0,0.250,-0.102),steel,dark)
    _cardan(drivetrain,SHAFT_NAMES[2],
        Vector3(0,0.250,0.123),
        Vector3(0,0.250,0.969),steel,dark)
    for z in [-0.610,0.407,0.766]:
        _box(drivetrain,"P06V15_AbrazaderaRetencion_%d" % int(z*1000.0),
            Vector3(0,0.321,z),Vector3(0.151,0.044,0.055),case_mat)

static func _steer(root: Node3D,steel: Material,
        dark: Material) -> void:
    var steering:=_group(root,STEERING)
    _box(steering,"P06V15_CajaCremalleraDireccion",
        Vector3(0,0.492,-1.178),
        Vector3(0.803,0.067,0.105),dark)
    for side in [-1,1]:
        var s: float=float(side)
        _cyl(steering,"P06V15_TiranteDireccion_%d" % side,
            Vector3.ZERO,0.026,1.0,steel)
        _ring(steering,"P06V15_GuardapolvoCremallera_%d" % side,
            Vector3(s*0.401,0.476,-1.178),
            0.027,0.049,dark,Vector3(0,0,90))

static func _pose_steering(model: Node3D) -> bool:
    var steering: Node3D=model.find_child(STEERING,true,false) as Node3D
    if steering==null:
        return false
    for side in [-1,1]:
        var s: float=float(side)
        var wheel: Node3D=model.find_child(
            "RuedaMotorizadaP06_%d_0" % side,true,false) as Node3D
        var rod: Node3D=steering.find_child(
            "P06V15_TiranteDireccion_%d" % side,false,false) as Node3D
        if wheel==null or rod==null:
            return false
        # Tie rod touches the non-spinning knuckle. The Z endpoint tracks
        # steering yaw, not the wheel's tire rotation around its own axle.
        var steer: float=deg_to_rad(wheel.rotation_degrees.y)
        var from:=Vector3(s*0.399,0.476,-1.178)
        var ending:=Vector3(s*0.796,wheel.position.y+0.028,
            -1.104+0.074*sin(steer))
        if not _link(rod,from,ending):
            return false
    return true

static func pose(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not _pose_steering(model):
        return false
    var phase: float=float(model.get_meta(DRIVE_PHASE,0.0))
    for idx in range(SHAFT_NAMES.size()):
        var shaft: Node3D=model.find_child(
            SHAFT_NAMES[idx],true,false) as Node3D
        var cross: Node3D=null
        if shaft!=null:
            cross=shaft.find_child(
                "P06V15_CrucetaCardan",false,false) as Node3D
        if cross==null:
            return false
        cross.rotation_degrees.z=phase*720.0
    return true

static func _damage_groups(root: Node3D,steel: Material,
        scorch: Material) -> void:
    var damaged:=_group(root,DAMAGE)
    var scrape:=_group(damaged,"P06V15_RozadurasChasis")
    _box(scrape,"P06V15_RasponPatin",
        Vector3(-0.611,0.359,-0.648),
        Vector3(0.072,0.020,0.211),steel)
    var bent:=_group(damaged,"P06V15_PlanchaVDesgarrada")
    _box(bent,"P06V15_PlacaSueloDeformada",
        Vector3(0.389,0.301,0.018),
        Vector3(0.241,0.029,0.388),steel)
    (bent.get_child(0) as Node3D).rotation_degrees.z=17.0
    _box(bent,"P06V15_CosturaAbierta",
        Vector3(0.504,0.278,-0.019),
        Vector3(0.050,0.047,0.290),scorch)
    var ruined:=_group(damaged,"P06V15_CardanQuebrado")
    _cyl(ruined,"P06V15_TuboCardanRotoA",
        Vector3(-0.061,0.190,0.676),
        0.039,0.401,steel,Vector3(110,18,0))
    _cyl(ruined,"P06V15_TuboCardanRotoB",
        Vector3(0.087,0.173,0.953),
        0.035,0.204,scorch,Vector3(120,0,24))
    for child in damaged.get_children():
        (child as Node3D).visible=false

static func _wreck(root: Node3D,steel: Material,
        char: Material) -> void:
    var debris:=_group(root,WRECK)
    debris.visible=false
    _box(debris,"P06V15_DiferencialRoto",
        Vector3(0.075,0.178,0.945),
        Vector3(0.219,0.172,0.206),char)
    _cyl(debris,"P06V15_EjeTraseroPartido",
        Vector3(-0.320,0.273,1.054),
        0.038,0.523,steel,Vector3(0,0,72))
    _box(debris,"P06V15_PatinFracturado",
        Vector3(-0.568,0.310,0.839),
        Vector3(0.078,0.083,0.405),char)
    (debris.get_child(2) as Node3D).rotation_degrees.z=-21.0

static func apply(model: Node3D,faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V14.FLAG,false)):
        return false
    if model.get_meta(FLAG,false):
        return true
    var hull: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if hull==null:
        return false
    var root:=_group(hull,ROOT)
    var armor:=_mat(Color("#435158").lerp(faction_color,0.36),0.30,0.87)
    var steel:=_mat(Color("#7b878b"),0.66,0.64)
    var deep:=_mat(Color("#293238"),0.38,0.93)
    var rubber:=_mat(Color("#22292d"),0.08,0.96)
    var char:=_mat(Color("#202627"),0.13,0.98)
    _belly(root,armor,steel,rubber)
    _differentials(root,deep,steel,rubber)
    _transfer(root,deep,steel,rubber)
    _steer(root,steel,rubber)
    _damage_groups(root,steel,char)
    _wreck(hull,steel,char)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    model.set_meta("tarvoka_apc_v15_differentials",3)
    model.set_meta("tarvoka_apc_v15_drive_shafts",3)
    if not pose(model):
        model.set_meta(FLAG,false)
        root.queue_free()
        var wreck: Node3D=hull.find_child(
            WRECK,false,false) as Node3D
        if wreck!=null:
            wreck.queue_free()
        return false
    return true

static func set_stage(model: Node3D,value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int=clampi(value,0,4)
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    var wreck: Node3D=model.find_child(WRECK,true,false) as Node3D
    var damaged: Node3D=model.find_child(DAMAGE,true,false) as Node3D
    if root!=null:
        root.visible=enabled and stage<4
    if wreck!=null:
        wreck.visible=enabled and stage==4
    if damaged!=null:
        for group in damaged.get_children():
            var level: int=1
            if group.name=="P06V15_PlanchaVDesgarrada":
                level=2
            elif group.name=="P06V15_CardanQuebrado":
                level=3
            (group as Node3D).visible=enabled and stage>=level and stage<4
    var panel: Node3D=model.find_child(
        PANEL_BROKEN,true,false) as Node3D
    if panel!=null:
        panel.visible=enabled and stage<2
    var shaft: Node3D=model.find_child(
        SHAFT_BROKEN,true,false) as Node3D
    if shaft!=null:
        shaft.visible=enabled and stage<3
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
