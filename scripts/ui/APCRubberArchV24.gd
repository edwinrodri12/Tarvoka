extends RefCounted
class_name TarvokaAPCRubberArchV24

# Bastion P06 V24 -- real close-up rubber sculpting after V23.
# Rolled shoulders and sidewall micro-grooves rotate with the six tire pivots;
# recessed arch lips remain on the STATIC hull outside the tire envelope.
# No tire replacement, wheel transform edits, damage stats or FPS tuning.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V18=preload("res://scripts/ui/APCWheelwellV18.gd")
const V19=preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const V23=preload("res://scripts/ui/APCTireFinishV23.gd")
const FLAG := "tarvoka_apc_rubber_arch_v24"
const ROOT := "P06V24_RematesNeumaticosYGuardabarros"
const WHEEL_PART := "P06V24_HombrosYMicroSurcos"
const SHOULDERS := "P06V24_HombrosEnlazados"
const GROOVES := "P06V24_MicroSurcosFlancos"
const ARCHES := "P06V24_SellosArcosEstaticos"
const LINER := "P06V24_ArcoInteriorCaucho"
const GASKET := "P06V24_UnionContinuaGuardabarros"
const WET := "P06V24_RastroHumedadEnArcos"
const SNOW := "P06V24_EscarchaEnLabios"
const SHOW := "tarvoka_apc_v24_visible"
const STAGE := "tarvoka_apc_v24_stage"
const WEATHER := "tarvoka_apc_v24_weather"
const SEGMENTS := 48
const GROOVES_PER_SIDE := 24
const INNER_ARCH := 0.418
const OUTER_ARCH := 0.444
const MAX_TIRE_ENVELOPE := 0.363
const RADIAL_CLEARANCE := INNER_ARCH - MAX_TIRE_ENVELOPE

static func _group(parent: Node3D,label: String) -> Node3D:
    var node:=Node3D.new()
    node.name=label
    parent.add_child(node)
    return node

static func _material(color: Color,metal: float,rough: float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    mat.uv1_triplanar=true
    mat.uv1_scale=Vector3(7,7,7)
    return mat

static func _mesh(parent: Node3D,label: String,shape: Mesh,
        mat: Material) -> MeshInstance3D:
    var piece:=MeshInstance3D.new()
    piece.name=label
    piece.mesh=shape
    piece.material_override=mat
    parent.add_child(piece)
    return piece

static func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        tool.add_vertex(vertex)

static func _radial(x: float,r: float,a: float) -> Vector3:
    return Vector3(x,r*sin(a),r*cos(a))

static func _shoulder_mesh() -> ArrayMesh:
    # Ring connects tread edge to the round V2/V23 carcass, with no
    # disconnected tread blocks or vanishing sidewall on the inside face.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for sign in [-1,1]:
        var s: float=float(sign)
        var profile: Array[Vector2]=[
            Vector2(s*0.087,0.353),
            Vector2(s*0.098,0.345),
            Vector2(s*0.108,0.332),
            Vector2(s*0.117,0.303)]
        for n in range(SEGMENTS):
            var a: float=TAU*float(n)/float(SEGMENTS)
            var b: float=TAU*float(n+1)/float(SEGMENTS)
            for i in range(profile.size()-1):
                var p: Vector2=profile[i]
                var q: Vector2=profile[i+1]
                _quad(st,_radial(p.x,p.y,a),
                    _radial(p.x,p.y,b),
                    _radial(q.x,q.y,b),
                    _radial(q.x,q.y,a))
                # Thin, closed back face (2mm rubber), not an unlit shell.
                _quad(st,_radial(q.x,q.y-0.002,a),
                    _radial(q.x,q.y-0.002,b),
                    _radial(p.x,p.y-0.002,b),
                    _radial(p.x,p.y-0.002,a))
            for edge in [0,profile.size()-1]:
                var p: Vector2=profile[edge]
                _quad(st,_radial(p.x,p.y,a),
                    _radial(p.x,p.y-0.002,a),
                    _radial(p.x,p.y-0.002,b),
                    _radial(p.x,p.y,b))
    st.generate_normals()
    return st.commit()

static func _groove_mesh() -> ArrayMesh:
    # Two sidewalls, each with 24 tiny closed relief marks between the
    # V23 inner bead and larger 24 reinforced shoulder ribs.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for sign in [-1,1]:
        var s: float=float(sign)
        for n in range(GROOVES_PER_SIDE):
            var a: float=TAU*(float(n)+0.11)/float(GROOVES_PER_SIDE)
            var b: float=a+0.061
            var inner: float=0.267
            var outer: float=0.298
            var x0: float=s*0.120
            var x1: float=s*0.124
            var p: Array[Vector3]=[
                _radial(x0,inner,a),_radial(x0,outer,a),
                _radial(x0,outer,b),_radial(x0,inner,b),
                _radial(x1,inner,a),_radial(x1,outer,a),
                _radial(x1,outer,b),_radial(x1,inner,b)]
            _quad(st,p[4],p[5],p[6],p[7])
            _quad(st,p[3],p[2],p[1],p[0])
            for edge in range(4):
                var next_edge: int=(edge+1)%4
                _quad(st,p[edge],p[next_edge],
                    p[next_edge+4],p[edge+4])
    st.generate_normals()
    return st.commit()

static func _arch_mesh(inner: float,outer: float,
        start: float,end: float,offset: float) -> ArrayMesh:
    # In wheel-center coordinates (0,.430,z): radial strip is fixed to
    # body, never to wheel. Four capped solid faces over 12 sectors.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sections: int=12
    for n in range(sections):
        var a: float=deg_to_rad(lerpf(start,end,float(n)/float(sections)))
        var b: float=deg_to_rad(lerpf(start,end,float(n+1)/float(sections)))
        var x0: float=0.939+offset
        var x1: float=0.946+offset
        var v: Array[Vector3]=[
            _radial(x0,inner,a),_radial(x0,outer,a),
            _radial(x0,outer,b),_radial(x0,inner,b),
            _radial(x1,inner,a),_radial(x1,outer,a),
            _radial(x1,outer,b),_radial(x1,inner,b)]
        _quad(st,v[4],v[5],v[6],v[7])
        _quad(st,v[3],v[2],v[1],v[0])
        for edge in range(4):
            var next_edge: int=(edge+1)%4
            _quad(st,v[edge],v[next_edge],
                v[next_edge+4],v[edge+4])
    st.generate_normals()
    return st.commit()

static func _arch_ring(parent: Node3D,side: int,axle: int,
        shape: ArrayMesh,gasket: ArrayMesh,
        moist: ArrayMesh,snow: ArrayMesh,
        rubber: Material,seal: Material,
        wet_mat: Material,snow_mat: Material) -> void:
    var wheel_z: float=float(V1.WHEEL_Z[axle])
    var ring:=_group(parent,
        "P06V24_ArcoFijo_%d_%d" % [side,axle])
    ring.position=Vector3.ZERO
    ring.set_meta("tarvoka_p06_v24_side",side)
    ring.set_meta("tarvoka_p06_v24_axle",axle)
    # Flip the entire arch along X, not around a tire pivot.
    var side_root:=_group(ring,
        "P06V24_SelloCostado_%d_%d" % [side,axle])
    side_root.scale.x=float(side)
    side_root.position.z=wheel_z
    side_root.position.y=0.430
    _mesh(side_root,LINER,shape,rubber)
    _mesh(side_root,GASKET,gasket,seal)
    var wet: MeshInstance3D=_mesh(side_root,WET,moist,wet_mat)
    wet.visible=false
    var ice: MeshInstance3D=_mesh(side_root,SNOW,snow,snow_mat)
    ice.visible=false

static func apply(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(V23.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if hull==null:
        return false
    var rubber: StandardMaterial3D=_material(
        Color("#25292a"),0.015,0.94)
    var micro: StandardMaterial3D=_material(
        Color("#171c1f"),0.01,0.98)
    var arch_mat: StandardMaterial3D=_material(
        Color("#232a2e"),0.02,0.92)
    var gasket_mat: StandardMaterial3D=_material(
        Color("#30383b"),0.03,0.80)
    var wet_mat: StandardMaterial3D=_material(
        Color("#526575"),0.08,0.30)
    var snow_mat: StandardMaterial3D=_material(
        Color("#cbd7de"),0.0,0.99)
    var shoulder: ArrayMesh=_shoulder_mesh()
    var grooves: ArrayMesh=_groove_mesh()
    var arch: ArrayMesh=_arch_mesh(0.418,0.430,35.0,145.0,0.0)
    var lip: ArrayMesh=_arch_mesh(0.441,0.454,35.0,145.0,0.004)
    var rainy: ArrayMesh=_arch_mesh(0.446,0.448,48.0,132.0,0.006)
    var winter: ArrayMesh=_arch_mesh(0.454,0.456,52.0,128.0,0.007)
    var roots: Array[Node3D]=[]
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],true,false) as Node3D
            if wheel==null or wheel.find_child(V23.ROOT,false,false)==null:
                return false
            var tire_root: Node3D=_group(wheel,WHEEL_PART)
            roots.append(tire_root)
            _mesh(tire_root,SHOULDERS,shoulder,rubber)
            _mesh(tire_root,GROOVES,grooves,micro)
    var fixed: Node3D=_group(hull,ROOT)
    var rims: Node3D=_group(fixed,ARCHES)
    for side in [-1,1]:
        for axle in range(3):
            _arch_ring(rims,side,axle,arch,lip,rainy,winter,
                arch_mat,gasket_mat,wet_mat,snow_mat)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    model.set_meta(WEATHER,"clear")
    model.set_meta("tarvoka_p06_v24_radial_clearance",RADIAL_CLEARANCE)
    set_stage(model,0)
    return true

static func _refresh(model: Node3D) -> void:
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var stage: int=int(model.get_meta(STAGE,0))
    var weather: String=str(model.get_meta(WEATHER,"clear"))
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=model.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],true,false) as Node3D
            if wheel!=null:
                var tire: Node3D=wheel.find_child(
                    WHEEL_PART,false,false) as Node3D
                if tire!=null:
                    tire.visible=enabled
            var ring: Node3D=model.find_child(
                "P06V24_ArcoFijo_%d_%d" % [side,axle],true,false) as Node3D
            if ring==null:
                continue
            # Torn front-left wheel arch is absent only in critical damage,
            # matching V18/V19 factory shell destruction.
            var intact: bool=enabled and stage<4 and not (
                side==-1 and axle==0 and stage>=3)
            ring.visible=intact
            var rain: Node3D=ring.find_child(WET,true,false) as Node3D
            var frost: Node3D=ring.find_child(SNOW,true,false) as Node3D
            if rain!=null:
                rain.visible=weather=="rain" and intact
            if frost!=null:
                frost.visible=weather=="snow" and intact

static func set_stage(model: Node3D,stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(STAGE,clampi(stage,0,4))
    _refresh(model)
    return true

static func set_weather(model: Node3D,weather: String) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)) or not (
            weather in ["clear","rain","snow"]):
        return false
    model.set_meta(WEATHER,weather)
    _refresh(model)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    _refresh(model)
    return true
