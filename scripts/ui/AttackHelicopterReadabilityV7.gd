extends RefCounted
class_name TarvokaAttackHelicopterReadabilityV7

# A01 V7: enhance the hero sculpt's silhouette in a 320x180 landscape
# preview using REAL native 3D parts (no overlays drawn in post or fake art).
# Studio only; the original Android battle LOD stays unchanged.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V6=preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
const ROOT := "A01V7_IdentidadLegible320"
const FLAG := "tarvoka_a01_readability_v7"
const ENABLED := "tarvoka_a01_readability_v7_enabled"
const BLADE_TIP := "A01V7_ExtremoAspa_"
const TAIL_TIP := "A01V7_ExtremoAspaCola_"
const ENGINE_PLATE := "A01V7_EscudoMotor_"
const MISSILE_PLATE := "A01V7_CodigoLanzador_"
const TAIL_MARK := "A01V7_RotorColaMarcador_"
const GUN_RIM := "A01V7_AnilloBocacha"

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false)!=null)

static func _part(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _layer(parent: Node3D,name: String) -> Node3D:
    var layer:=Node3D.new()
    layer.name=name
    parent.add_child(layer)
    return layer

static func _mat(color: Color,metal: float=0.24,
        rough: float=0.62) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _mesh(parent: Node3D,name: String,
        geom: Mesh,color: Color,
        pos: Vector3=Vector3.ZERO,
        metal: float=0.24,rough: float=0.62) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=geom
    n.position=pos
    n.material_override=_mat(color,metal,rough)
    parent.add_child(n)
    return n

static func _box(parent: Node3D,name: String,
        center: Vector3,size: Vector3,
        color: Color,metal: float=0.24) -> MeshInstance3D:
    var shape:=BoxMesh.new()
    shape.size=size
    return _mesh(parent,name,shape,color,center,metal)

static func _rod(parent: Node3D,name: String,
        a: Vector3,b: Vector3,
        radius: float,color: Color) -> MeshInstance3D:
    var axis: Vector3=b-a
    var tube:=CylinderMesh.new()
    tube.top_radius=radius
    tube.bottom_radius=radius
    tube.height=axis.length()
    tube.radial_segments=10
    var n:=_mesh(parent,name,tube,color,(a+b)*0.5,0.62,0.32)
    n.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return n

static func _rim(parent: Node3D,name: String,
        pos: Vector3,inner: float,outer: float,
        color: Color) -> MeshInstance3D:
    var ring:=TorusMesh.new()
    ring.inner_radius=inner
    ring.outer_radius=outer
    ring.rings=10
    ring.ring_segments=24
    var n:=_mesh(parent,name,ring,color,pos,0.69,0.28)
    n.rotation_degrees.x=90.0
    return n

static func _tri(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    tool.add_vertex(a)
    tool.add_vertex(b)
    tool.add_vertex(c)

static func _engine_skin_x(y: float,z: float,side: int,offset: float=0.0) -> float:
    # Exact V4 physical 16-sided nacelle station dimensions around Z=0.4–0.76.
    # The plate is slightly embedded into the actual faceted skin.
    var t: float=clampf((z-0.40)/(0.76-0.40),0.0,1.0)
    var cy: float=lerpf(1.625,1.640,t)
    var width: float=lerpf(0.252,0.274,t)
    var height: float=lerpf(0.216,0.224,t)
    var vertical: float=clampf((y-cy)/height,-0.98,0.98)
    return float(side)*(0.335+width*sqrt(1.0-vertical*vertical)+offset)

static func _curved_engine_plate(parent: Node3D,name: String,
        outline: Array[Vector2],side: int,
        inside_offset: float,outside_offset: float,
        color: Color,metal: float=0.3,
        rough: float=0.58) -> MeshInstance3D:
    # Physical closed panel sculpt following the curved YZ nacelle, not a
    # flat rectangle suspended centimeters away from its engine surface.
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center:=Vector2.ZERO
    for point in outline:
        center+=point
    center/=float(outline.size())
    for i in range(outline.size()):
        var a: Vector2=outline[i]
        var b: Vector2=outline[(i+1)%outline.size()]
        var front_center:=Vector3(
            _engine_skin_x(center.x,center.y,side,outside_offset),
            center.x,center.y)
        var front_a:=Vector3(
            _engine_skin_x(a.x,a.y,side,outside_offset),a.x,a.y)
        var front_b:=Vector3(
            _engine_skin_x(b.x,b.y,side,outside_offset),b.x,b.y)
        var back_center:=Vector3(
            _engine_skin_x(center.x,center.y,side,inside_offset),
            center.x,center.y)
        var back_a:=Vector3(
            _engine_skin_x(a.x,a.y,side,inside_offset),a.x,a.y)
        var back_b:=Vector3(
            _engine_skin_x(b.x,b.y,side,inside_offset),b.x,b.y)
        _tri(tool,front_center,front_a,front_b)
        _tri(tool,back_center,back_b,back_a)
        _tri(tool,front_a,back_a,back_b)
        _tri(tool,front_a,back_b,front_b)
    tool.generate_normals()
    return _mesh(parent,name,tool.commit(),color,Vector3.ZERO,metal,rough)

static func _blade_tips(model: Node3D,faction: Color) -> bool:
    var bright:=Color("#c9d3d6")
    for i in range(4):
        var pivot: Node3D=_part(model,V3.LEGACY_ROTOR+str(i))
        var tail: Node3D=_part(model,V3.LEGACY_TAIL+str(i))
        if pivot==null or tail==null:
            return false
        # Airfoil is x[-0.07..0.13], y +/-0.0185, z[-2.02..-0.17].
        # The tip is a thin raised strip bonded TO the real spinning V3 blade.
        _box(pivot,BLADE_TIP+str(i),
            Vector3(0.02,0.026,-1.82),
            Vector3(0.139,0.011,0.115),bright,0.46)
        _box(pivot,"A01V7_FranjaAspaFaccion_"+str(i),
            Vector3(0.018,0.034,-1.768),
            Vector3(0.092,0.009,0.020),faction,0.12)
        # Tail rotor solid's outward front-facing side is at local X=+.0125.
        _box(tail,TAIL_TIP+str(i),
            Vector3(0.020,0.0,-0.398),
            Vector3(0.012,0.063,0.092),bright,0.46)
    return true

static func _identity(parent: Node3D,model: Node3D,faction: Color) -> void:
    var silver:=Color("#bdc9ce")
    var graphite:=Color("#24323b")
    for side in [-1,1]:
        var s: float=float(side)
        # A compact 3D badge on the SIDE of the engine, not a giant faction box.
        # Curved physical armor badge bonded to the V4 engine, following
        # real nacelle station widths rather than a flat floating slab.
        var metal_points: Array[Vector2]=[
            Vector2(1.530,0.43),
            Vector2(1.557,0.40),
            Vector2(1.688,0.43),
            Vector2(1.696,0.58),
            Vector2(1.580,0.62),
            Vector2(1.526,0.56)
        ]
        _curved_engine_plate(parent,ENGINE_PLATE+str(side),
            metal_points,side,-0.009,0.013,graphite,0.4,0.52)
        var inset: Array[Vector2]=[
            Vector2(1.559,0.456),
            Vector2(1.575,0.438),
            Vector2(1.661,0.458),
            Vector2(1.668,0.557),
            Vector2(1.589,0.592),
            Vector2(1.559,0.547)
        ]
        _curved_engine_plate(parent,"A01V7_InsigniaMotor_"+str(side),
            inset,side,0.009,0.021,faction,0.12,0.57)
        # On missile cradle's true outside wall X=+/-1.325.
        _box(parent,MISSILE_PLATE+str(side),
            Vector3(s*1.336,0.672,0.065),
            Vector3(0.018,0.105,0.305),graphite,0.40)
        _box(parent,"A01V7_CodigoFaccionLanzador_"+str(side),
            Vector3(s*1.349,0.678,0.025),
            Vector3(0.009,0.038,0.196),faction,0.16)
        # Top-surface maintenance marks only at the most visible skids.
        _box(parent,"A01V7_LetraPatin_"+str(side),
            Vector3(s*0.742,0.207,-0.56),
            Vector3(0.011,0.017,0.075),silver,0.29)
    # Add a 3D retaining ring around the actual V1 muzzle front surface.
    var gun: Node3D=_part(model,V1.GUN)
    if gun!=null:
        _rim(gun,GUN_RIM,Vector3(0,0,-0.808),
            0.090,0.122,silver)

static func _tail_markers(parent: Node3D) -> void:
    # Readable quarter markers on the FIXED V3 rotor guard.
    var center:=Vector3(0.285,1.38,2.62)
    var rim:=Color("#b9c7ca")
    for i in range(4):
        var angle: float=TAU*float(i)/4.0
        var a: float=angle-0.085
        var b: float=angle+0.085
        _rod(parent,TAIL_MARK+str(i),
            center+Vector3(0,0.525*sin(a),0.525*cos(a)),
            center+Vector3(0,0.525*sin(b),0.525*cos(b)),
            0.032,rim)

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    var parts: Array[Node]=model.find_children(
        "A01V7_*","Node3D",true,false)
    for item in parts:
        (item as Node3D).visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,faction: Color) -> bool:
    if not V6.has_model(model) or not V3.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_part(model,V1.ROOT)
    if body==null or _part(model,V1.GUN)==null:
        return false
    for i in range(4):
        if _part(model,V3.LEGACY_ROTOR+str(i))==null or (
                _part(model,V3.LEGACY_TAIL+str(i))==null):
            return false
    var layer:=_layer(body,ROOT)
    if not _blade_tips(model,faction):
        layer.queue_free()
        return false
    _identity(layer,model,faction)
    _tail_markers(layer)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
