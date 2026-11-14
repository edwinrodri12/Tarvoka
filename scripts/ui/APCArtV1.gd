extends RefCounted
class_name TarvokaAPCArtV1

# TARVOKA APC P06 "Bastión" — original 6x6 personnel carrier.
# First authored high-detail 3D pass for the NEXT unit after G09.
# Distinct wedge nose, V-shaped belly, rear troop ramp, three mobile axles,
# remote optical station and eight authentic TARVOKA faction palettes.
# Art-only: never modifies movement, passenger capacity, weapons or combat.
const ROOT := "APC_P06_V1_Blindado6x6"
const PAINT_META := "tarvoka_apc_paint_zone"
const WHEEL_RADIUS := 0.35
const WHEEL_Z := [-1.04,0.00,1.07]
const WHEEL_X := 0.82
const MAX_SEPARATE_SURFACES := 160
static var _weathered_albedo: ImageTexture

static func _coating() -> ImageTexture:
    if _weathered_albedo!=null:
        return _weathered_albedo
    var image:=Image.create(96,96,false,Image.FORMAT_RGBA8)
    for y in range(96):
        for x in range(96):
            var f: float = float(x*37+y*71)
            var grain: float = 0.91+0.075*sin(f*0.21)*cos(f*0.47)
            var scratches: float = 0.08 if (x%29==0 and y%11<5) else 0.0
            var v: float = clampf(grain-scratches,0.74,1.0)
            image.set_pixel(x,y,Color(v,v*0.995,v*0.982,1.0))
    image.generate_mipmaps()
    _weathered_albedo=ImageTexture.create_from_image(image)
    return _weathered_albedo

static func _mat(color: Color,metal: float=0.23,
        rough: float=0.79) -> StandardMaterial3D:
    var result:=StandardMaterial3D.new()
    result.albedo_color=color
    result.metallic=metal
    result.roughness=rough
    return result

static func _paint_material(color: Color) -> StandardMaterial3D:
    var result: StandardMaterial3D=_mat(color,0.29,0.80)
    result.albedo_texture=_coating()
    result.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    return result

static func _part(parent: Node3D,name: String,mesh: Mesh,
        mat: Material,at: Vector3=Vector3.ZERO,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=mesh
    node.material_override=mat
    node.position=at
    node.rotation_degrees=rot
    parent.add_child(node)
    return node

static func _box(parent: Node3D,name: String,at: Vector3,
        size: Vector3,mat: Material,
        rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    return _part(parent,name,mesh,mat,at,rot)

static func _cylinder(parent: Node3D,name: String,at: Vector3,
        radius: float,height: float,mat: Material,
        segments: int=16,rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    return _part(parent,name,mesh,mat,at,rot)

static func _triangle(st: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
    _triangle(st,a,b,c)
    _triangle(st,a,c,d)

static func _sculpt(parent: Node3D,name: String,
        vertices: Array[Vector3],paint: Material) -> MeshInstance3D:
    assert(vertices.size()%3==0)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for vertex in vertices:
        st.add_vertex(vertex)
    st.generate_normals()
    var mesh: ArrayMesh=st.commit()
    return _part(parent,name,mesh,paint)

static func _hull(parent: Node3D,coating: Material) -> void:
    # Five cross-section rings, pointed prow and expanding rear hull.
    # Unlike the V0 box body, this is a continuous closed, welded 3D shell.
    var rings: Array=[
        [-1.47,0.49,0.49,0.74],
        [-1.27,0.68,0.39,1.03],
        [-0.65,0.77,0.37,1.34],
        [0.82,0.79,0.38,1.40],
        [1.33,0.69,0.41,1.18]
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for section in range(rings.size()-1):
        var a: Array=rings[section]
        var b: Array=rings[section+1]
        var aa: Array[Vector3]=[
            Vector3(-float(a[1]),float(a[2]),float(a[0])),
            Vector3(float(a[1]),float(a[2]),float(a[0])),
            Vector3(float(a[1]),float(a[3]),float(a[0])),
            Vector3(-float(a[1]),float(a[3]),float(a[0]))]
        var bb: Array[Vector3]=[
            Vector3(-float(b[1]),float(b[2]),float(b[0])),
            Vector3(float(b[1]),float(b[2]),float(b[0])),
            Vector3(float(b[1]),float(b[3]),float(b[0])),
            Vector3(-float(b[1]),float(b[3]),float(b[0]))]
        for edge in range(4):
            var next: int=(edge+1)%4
            _quad(st,aa[edge],aa[next],bb[next],bb[edge])
    var first: Array=rings[0]
    var last: Array=rings[rings.size()-1]
    _quad(st,
        Vector3(-float(first[1]),float(first[2]),float(first[0])),
        Vector3(-float(first[1]),float(first[3]),float(first[0])),
        Vector3(float(first[1]),float(first[3]),float(first[0])),
        Vector3(float(first[1]),float(first[2]),float(first[0])))
    _quad(st,
        Vector3(-float(last[1]),float(last[2]),float(last[0])),
        Vector3(float(last[1]),float(last[2]),float(last[0])),
        Vector3(float(last[1]),float(last[3]),float(last[0])),
        Vector3(-float(last[1]),float(last[3]),float(last[0])))
    st.generate_normals()
    var hull: MeshInstance3D=_part(parent,"CascoBlindadoEsculpidoP06",
        st.commit(),coating)
    hull.set_meta("tarvoka_apc_primary_hull",true)

static func _armor_panel(parent: Node3D,name: String,
        points: Array[Vector3],paint: Material) -> MeshInstance3D:
    var node: MeshInstance3D=_sculpt(parent,name,[
        points[0],points[1],points[2],
        points[0],points[2],points[3]
    ],paint)
    node.set_meta(PAINT_META,true)
    return node

static func _running_gear(root: Node3D,
        rubber: Material,rim: Material,hub: Material,steel: Material) -> void:
    var underside:=_box(root,"BajoCascoEnV",
        Vector3(0.0,0.41,0.0),Vector3(1.24,0.22,2.55),steel)
    underside.rotation_degrees.z=0.0
    for side in [-1,1]:
        var sign: float=float(side)
        for i in range(3):
            var z: float=float(WHEEL_Z[i])
            var wheel:=Node3D.new()
            wheel.name="RuedaMotorizadaP06_%d_%d" % [side,i]
            wheel.position=Vector3(sign*WHEEL_X,WHEEL_RADIUS+0.08,z)
            root.add_child(wheel)
            _cylinder(wheel,"NeumaticoTodoTerreno",Vector3.ZERO,
                WHEEL_RADIUS,0.235,rubber,20,Vector3(0,0,90))
            _cylinder(wheel,"AnilloLlanta",
                Vector3(sign*0.118,0,0),0.223,0.024,rim,20,
                Vector3(0,0,90))
            _cylinder(wheel,"BujeCentral",
                Vector3(sign*0.145,0,0),0.099,0.04,hub,16,
                Vector3(0,0,90))
            # Repeated hardware is a single MultiMesh per wheel. No twenty
            # independent lug bolts making draw calls on Android.
            var bolt_ring:=MultiMeshInstance3D.new()
            bolt_ring.name="PernosP06"
            var mm:=MultiMesh.new()
            mm.transform_format=MultiMesh.TRANSFORM_3D
            var bolt:=CylinderMesh.new()
            bolt.top_radius=0.014
            bolt.bottom_radius=0.014
            bolt.height=0.035
            bolt.radial_segments=6
            mm.mesh=bolt
            mm.instance_count=8
            for j in range(8):
                var angle: float=TAU*float(j)/8.0
                mm.set_instance_transform(j,Transform3D(
                    Basis(Vector3.FORWARD,PI*0.5),
                    Vector3(sign*0.161,0.160*cos(angle),0.160*sin(angle))))
            bolt_ring.multimesh=mm
            bolt_ring.material_override=hub
            wheel.add_child(bolt_ring)
            _box(root,"BrazoSuspension_%d_%d" % [side,i],
                Vector3(sign*0.60,0.51,z),
                Vector3(0.43,0.11,0.16),steel,Vector3(0,0,float(side)*-12))
        _box(root,"FaldonProtector_%d" % side,
            Vector3(sign*0.765,0.79,0.01),
            Vector3(0.10,0.19,2.36),steel)
    root.set_meta("tarvoka_apc_wheel_axles",6)

static func _details(root: Node3D,paint: Material,
        base: Material,glass: Material,black: Material,
        steel: Material,signal: Material) -> void:
    # Real windshield facets, no car-sized glass on military armor.
    _box(root,"MarcoFrontalReforzado",
        Vector3(0.0,1.13,-1.02),Vector3(1.04,0.10,0.12),steel,
        Vector3(-28,0,0))
    for side in [-1,1]:
        var sign: float=float(side)
        _armor_panel(root,"BlindajeFlancoFac_%d" % side,[
            Vector3(sign*0.778,1.24,-0.54),
            Vector3(sign*0.786,1.29,0.82),
            Vector3(sign*0.815,0.88,0.83),
            Vector3(sign*0.820,0.89,-0.66)],paint)
        _armor_panel(root,"BlindajeProaFac_%d" % side,[
            Vector3(sign*0.06,0.95,-1.445),
            Vector3(sign*0.48,0.76,-1.45),
            Vector3(sign*0.67,1.02,-1.25),
            Vector3(sign*0.07,1.06,-1.24)],paint)
        _box(root,"BlindajeJuntaDelantera_%d" % side,
            Vector3(sign*0.55,1.03,-0.93),
            Vector3(0.11,0.09,0.56),steel,
            Vector3(0,0,float(side)*-14))
        _box(root,"PuertoOpticoConductor_%d" % side,
            Vector3(sign*0.255,1.226,-0.99),
            Vector3(0.31,0.105,0.075),glass,
            Vector3(-26,0,0))
        _box(root,"MarcoPuertoConductor_%d" % side,
            Vector3(sign*0.255,1.28,-0.995),
            Vector3(0.38,0.032,0.085),black,
            Vector3(-26,0,0))
        for index in range(2):
            _box(root,"CerrojoEscotillaLateral_%d_%d" % [side,index],
                Vector3(sign*0.822,1.01,-0.11+float(index)*0.67),
                Vector3(0.055,0.10,0.18),steel)
        _box(root,"FaroRecessed_%d" % side,
            Vector3(sign*0.47,0.77,-1.47),
            Vector3(0.18,0.10,0.025),signal)
        _box(root,"RejillaRefrigeracion_%d" % side,
            Vector3(sign*0.79,1.02,0.76),
            Vector3(0.035,0.13,0.35),black)
        _box(root,"EscaleraAntideslizante_%d" % side,
            Vector3(sign*0.76,0.54,0.98),
            Vector3(0.12,0.055,0.34),steel)
        _box(root,"SoporteAntena_%d" % side,
            Vector3(sign*0.57,1.46,0.80),
            Vector3(0.15,0.08,0.13),steel)
        _cylinder(root,"AntenaBlindada_%d" % side,
            Vector3(sign*0.57,1.82,0.80),
            0.015,0.63,black,7)
    # Upper roof hatches and commander intake.
    _box(root,"TechoServicioCentral",
        Vector3(0,1.42,0.43),Vector3(1.16,0.075,1.29),base)
    for index in range(2):
        _box(root,"EscotillaTripulacion_%d" % index,
            Vector3(-0.34+0.68*float(index),1.486,0.52),
            Vector3(0.48,0.035,0.44),steel)
        _box(root,"TiradorEscotilla_%d" % index,
            Vector3(-0.34+0.68*float(index),1.52,0.52),
            Vector3(0.10,0.05,0.16),black)
    # Real aft passenger ramp with visible center seam and armored hinges.
    _box(root,"MarcoRampaPosterior",
        Vector3(0.0,0.86,1.33),Vector3(1.22,0.85,0.10),steel,
        Vector3(8,0,0))
    var ramp:=_box(root,"RampaDesembarcoBlindada",
        Vector3(0,0.82,1.40),Vector3(1.00,0.67,0.055),paint,
        Vector3(8,0,0))
    ramp.set_meta(PAINT_META,true)
    for side in [-1,1]:
        _cylinder(root,"BisagraRampa_%d" % side,
            Vector3(float(side)*0.45,1.23,1.41),
            0.04,0.13,black,10,Vector3(0,0,90))
    _box(root,"PeliculaAntideslizanteRampa",
        Vector3(0,0.69,1.45),Vector3(0.76,0.13,0.024),black)
    _box(root,"ParrillaFrontal",
        Vector3(0,0.62,-1.51),Vector3(0.51,0.17,0.046),black)
    _box(root,"GanchoRemolque",
        Vector3(0,0.36,-1.55),Vector3(0.21,0.09,0.16),steel)

static func _remote_turret(root: Node3D,
        armor: Material,steel: Material,glass: Material,
        black: Material) -> Node3D:
    var turret:=Node3D.new()
    turret.name="EstacionRemotaP06"
    turret.position=Vector3(0,1.53,-0.16)
    root.add_child(turret)
    _cylinder(turret,"CoronaEstacion",Vector3.ZERO,0.30,0.075,black,18)
    _box(turret,"TorretaCompacta",
        Vector3(0,0.20,0),Vector3(0.43,0.31,0.50),armor)
    _box(turret,"MejillaSensorDerecha",
        Vector3(0.27,0.22,-0.06),Vector3(0.15,0.22,0.32),steel)
    _box(turret,"BloqueOpticoTierra",
        Vector3(0.26,0.29,-0.25),Vector3(0.18,0.13,0.08),glass)
    var gun:=Node3D.new()
    gun.name="ArmaEstabilizadaP06"
    gun.position=Vector3(-0.02,0.20,-0.27)
    turret.add_child(gun)
    _cylinder(gun,"CanonDefensivoCorto",
        Vector3(0,0,-0.30),0.044,0.53,black,12,Vector3(90,0,0))
    _cylinder(gun,"CamisaCanon",
        Vector3(0,0,-0.14),0.073,0.20,steel,12,Vector3(90,0,0))
    _box(gun,"FrenoBoca",
        Vector3(0,0,-0.61),Vector3(0.14,0.10,0.105),black)
    return turret

static func apply(model: Node3D,color: Color) -> bool:
    if model==null or model.get_meta("tarvoka_apc_sculpt_v1",false):
        return false
    if model.name!="Modelo3D_apc":
        return false
    # Keep legacy V0 prototype in the scene solely for A/B testing; never
    # allow it to poke through the final armored hull.
    for item in model.get_children():
        if item is Node3D:
            (item as Node3D).visible=false
    var root:=Node3D.new()
    root.name=ROOT
    model.add_child(root)
    var armor: StandardMaterial3D=_paint_material(color)
    var lower: StandardMaterial3D=_mat(Color("#48545C"),0.36,0.86)
    var steel: StandardMaterial3D=_mat(Color("#707D82"),0.52,0.67)
    var black: StandardMaterial3D=_mat(Color("#182127"),0.12,0.94)
    var tire: StandardMaterial3D=_mat(Color("#222629"),0.06,0.98)
    var rim: StandardMaterial3D=_mat(Color("#4D5456"),0.60,0.78)
    var glass: StandardMaterial3D=_mat(Color("#60899B"),0.13,0.31)
    var signal: StandardMaterial3D=_mat(Color("#EDD2A1"),0.01,0.42)
    _hull(root,armor)
    _running_gear(root,tire,rim,black,lower)
    _details(root,armor,lower,glass,black,steel,signal)
    _remote_turret(root,armor,steel,glass,black)
    model.set_meta("tarvoka_apc_sculpt_v1",true)
    model.set_meta("tarvoka_apc_paint_color",color)
    model.set_meta("tarvoka_apc_role","apc")
    model.set_meta("tarvoka_apc_wheels",6)
    return true

static func recolor(model: Node3D,color: Color) -> int:
    if model==null or not model.get_meta("tarvoka_apc_sculpt_v1",false):
        return 0
    var root: Node3D=model.find_child(ROOT,true,false) as Node3D
    if root==null:
        return 0
    var updated:=0
    var paint: Material=_paint_material(color)
    for piece in root.find_children("*","MeshInstance3D",true,false):
        if piece.has_meta(PAINT_META) or piece.has_meta("tarvoka_apc_primary_hull"):
            (piece as MeshInstance3D).material_override=paint
            updated+=1
    model.set_meta("tarvoka_apc_paint_color",color)
    return updated
