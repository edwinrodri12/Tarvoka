extends RefCounted
class_name TarvokaAttackHelicopterSilhouetteV8

# A01 V8: original physically joined 3D faction recognition panels sized
# for genuine 320x180 tactical camera projection. Detailed Studio art only.
# Do not modify old rotors, V4 engine solids, attack stats or Android battle LOD.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V7=preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
const ROOT := "A01V8_PanelesIdentidadDistancia"
const FLAG := "tarvoka_a01_silhouette_v8"
const ENABLED := "tarvoka_a01_silhouette_v8_enabled"
const WING := "A01V8_AlaInsignia_"
const ENGINE := "A01V8_CarenadoSuperior_"
const FIN := "A01V8_AletaColaIdentidad_"

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false)!=null)

static func _node(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _material(color: Color) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=0.17
    mat.roughness=0.59
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _mesh(parent: Node3D,name: String,
        geometry: Mesh,color: Color,
        offset: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var m:=MeshInstance3D.new()
    m.name=name
    m.mesh=geometry
    m.position=offset
    m.material_override=_material(color)
    parent.add_child(m)
    return m

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _station(z: float) -> Vector4:
    # Exact physically sculpted V4 engine stations (Z,Y,X radius,Y radius).
    var points: Array[Vector4]=[
        Vector4(0.40,1.625,0.252,0.216),
        Vector4(0.76,1.640,0.274,0.224),
        Vector4(1.03,1.625,0.244,0.194)
    ]
    var first: Vector4=points[0]
    var second: Vector4=points[1]
    if z>=0.76:
        first=points[1]
        second=points[2]
    var t: float=clampf((z-first.x)/(second.x-first.x),0.0,1.0)
    return first.lerp(second,t)

static func _engine_skin(z: float,offset: float) -> float:
    var sec: Vector4=_station(z)
    var fraction: float=clampf(offset/sec.z,0.0,0.98)
    return sec.y+sec.w*sqrt(1.0-fraction*fraction)

static func _nacelle_enamel(side: int) -> ArrayMesh:
    # A shallow physically closed 3D band following the precise sloped
    # nacelle shoulder. Top and bottom surfaces share ALL mesh edges.
    var sign: float=float(side)
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings: Array[PackedVector3Array]=[]
    var surface: Array[PackedVector3Array]=[]
    var z_sections: Array[float]=[0.47,0.58,0.70,0.82,0.94]
    # Two parallel shoulder rails, neither touches existing turbine vents.
    for z in z_sections:
        var row:=PackedVector3Array()
        var base:=PackedVector3Array()
        for t in range(3):
            var u: float=float(t)/2.0
            var offset: float=lerpf(0.078,0.190,u)
            var yy: float=_engine_skin(z,offset)
            row.append(Vector3(sign*(0.335+offset),yy+0.010,z))
            base.append(Vector3(sign*(0.335+offset),yy-0.004,z))
        rings.append(row)
        surface.append(base)
    for i in range(rings.size()-1):
        for j in range(2):
            var a: Vector3=rings[i][j]
            var b: Vector3=rings[i][j+1]
            var c: Vector3=rings[i+1][j+1]
            var d: Vector3=rings[i+1][j]
            _tri(tool,a,b,c)
            _tri(tool,a,c,d)
            var e: Vector3=surface[i][j]
            var f: Vector3=surface[i][j+1]
            var g: Vector3=surface[i+1][j+1]
            var h: Vector3=surface[i+1][j]
            _tri(tool,e,g,f)
            _tri(tool,e,h,g)
    for i in range(z_sections.size()-1):
        for j in [0,2]:
            var k: int=0 if j==0 else 1
            _tri(tool,rings[i][j],surface[i][j],surface[i+1][j])
            _tri(tool,rings[i][j],surface[i+1][j],rings[i+1][j])
    for i in [0,z_sections.size()-1]:
        for j in range(2):
            _tri(tool,rings[i][j],rings[i][j+1],surface[i][j+1])
            _tri(tool,rings[i][j],surface[i][j+1],surface[i][j])
    tool.generate_normals()
    return tool.commit()

static func _create_wings(layer: Node3D,side: int,color: Color) -> void:
    var sign: float=float(side)
    # Solid inserts lie 6 mm above the 10cm thick wing V3.
    # Full-band faction paint would turn the whole aircraft into a billboard;
    # these measured panels cover only the outer 30% of each real wing.
    var outline: Array[Vector2]=[
        Vector2(sign*1.12,-0.180),
        Vector2(sign*1.35,-0.146),
        Vector2(sign*1.486,-0.121),
        Vector2(sign*1.486,0.087),
        Vector2(sign*1.35,0.150),
        Vector2(sign*1.12,0.216)
    ]
    _mesh(layer,WING+str(side),
        V3._closed_profile(outline,0.014),
        color,Vector3(0,0.866,0))
    var trim: Array[Vector2]=[
        Vector2(sign*1.42,-0.128),
        Vector2(sign*1.485,-0.116),
        Vector2(sign*1.485,0.078),
        Vector2(sign*1.42,0.11)
    ]
    _mesh(layer,"A01V8_BordePuntaAla_"+str(side),
        V3._closed_profile(trim,0.008),
        Color("#a5b2b7"),Vector3(0,0.877,0))

static func _create_fin(model: Node3D,side: int,color: Color) -> void:
    var fin: Node3D=_node(model,"A01_AletaVertical")
    if fin==null:
        return
    var sign: float=float(side)
    # The original fin is x=0.10 thick, y=0.82, z=0.36 rotated -12°.
    # Parent panels directly to its exact 3D transform so no world-space
    # approximation can cause a floating patch at another viewing angle.
    var shape: Array[Vector2]=[
        Vector2(0.105,-0.115),
        Vector2(0.306,-0.110),
        Vector2(0.322,0.099),
        Vector2(0.132,0.120)
    ]
    _mesh(fin,FIN+str(side),
        V4._panel_solid(shape,0.018),
        color,Vector3(sign*0.056,0,0))

static func _old_wing_stripes(model: Node3D,show: bool) -> bool:
    for side in [-1,1]:
        var stripe: Node3D=_node(model,"A01V3_FranjaFaccion_%d" % side)
        if stripe==null:
            return false
        stripe.visible=show
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    if not _old_wing_stripes(model,not enabled):
        return false
    var new: Node3D=_node(model,ROOT)
    new.visible=enabled
    for side in [-1,1]:
        var fin: Node3D=_node(model,FIN+str(side))
        if fin!=null:
            fin.visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,color: Color) -> bool:
    if not V7.has_model(model) or not V3.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_node(model,V1.ROOT)
    if body==null or _node(model,"A01_AletaVertical")==null:
        return false
    for side in [-1,1]:
        if _node(model,"A01V3_FranjaFaccion_%d" % side)==null:
            return false
    var layer:=_group(body,ROOT)
    for side in [-1,1]:
        _create_wings(layer,side,color)
        _mesh(layer,ENGINE+str(side),_nacelle_enamel(side),color)
        _create_fin(model,side,color)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
