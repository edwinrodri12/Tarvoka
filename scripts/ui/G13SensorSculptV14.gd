extends RefCounted
class_name TarvokaG13SensorSculptV14

# G13 V14 - mechanical radar reflector and dual optical tracking sensors.
# Art-only: the original G13_RadarAzimut and G13_TorretaAzimut pivots drive
# all the new geometry. Never introduce targeting, fire control or unit rules.
const FLAG := "tarvoka_g13_sensor_sculpt_v14"
const DISH := "G13_TiltedRadarDish"
const BOWL := "G13_V14_RadarReflector"
const RIM := "G13_V14_RadarRim"
const FEED := "G13_V14_RadarFeedHorn"
const BRACE := "G13_V14_RadarFeedBrace_%d"
const OPTIC := "G13_OpticDirector"
const LENS := "G13_V14_OpticLens_%d"
const BEZEL := "G13_V14_OpticBezel_%d"
const SHROUD := "G13_V14_OpticProtectiveHood"
const COLLAR := "G13_V14_RadarMastCollar"
const SEGMENTS := 20
const RADIUS := 0.294

static func _material(color: Color,metallic: float,roughness: float)->StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3)->void:
    var n: Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _circle(radius: float,y: float,index: int)->Vector3:
    var angle: float=TAU*float(index)/float(SEGMENTS)
    return Vector3(cos(angle)*radius,y,sin(angle)*radius)

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3)->void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _reflector()->ArrayMesh:
    # Actual shallow dished metal, not the previous solid CylinderMesh.
    # The front (+local Y) is a bowl and the back is a closed faceted shell.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var radii: Array[float]=[0.075,0.170,RADIUS]
    var front_y: Array[float]=[-0.020,0.000,0.045]
    var back_y: Array[float]=[-0.065,-0.050,0.020]
    for layer in range(2):
        for i in range(SEGMENTS):
            var j:int=(i+1)%SEGMENTS
            _quad(st,
                _circle(radii[layer],front_y[layer],i),
                _circle(radii[layer],front_y[layer],j),
                _circle(radii[layer+1],front_y[layer+1],j),
                _circle(radii[layer+1],front_y[layer+1],i))
            _quad(st,
                _circle(radii[layer+1],back_y[layer+1],i),
                _circle(radii[layer+1],back_y[layer+1],j),
                _circle(radii[layer],back_y[layer],j),
                _circle(radii[layer],back_y[layer],i))
    for i in range(SEGMENTS):
        var j:int=(i+1)%SEGMENTS
        _tri(st,Vector3(0,-0.024,0),
            _circle(radii[0],front_y[0],j),
            _circle(radii[0],front_y[0],i))
        _tri(st,Vector3(0,-0.073,0),
            _circle(radii[0],back_y[0],i),
            _circle(radii[0],back_y[0],j))
        _quad(st,
            _circle(RADIUS,front_y[2],i),
            _circle(RADIUS,front_y[2],j),
            _circle(RADIUS,back_y[2],j),
            _circle(RADIUS,back_y[2],i))
    return st.commit()

static func _rim_mesh()->ArrayMesh:
    # Narrow metallic rim, as one surface: no 20 individual draw calls.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(SEGMENTS):
        var j:int=(i+1)%SEGMENTS
        _quad(st,
            _circle(0.287,0.050,i),_circle(0.287,0.050,j),
            _circle(0.303,0.050,j),_circle(0.303,0.050,i))
        _quad(st,
            _circle(0.303,0.050,i),_circle(0.303,0.050,j),
            _circle(0.303,0.033,j),_circle(0.303,0.033,i))
        _quad(st,
            _circle(0.303,0.033,i),_circle(0.303,0.033,j),
            _circle(0.287,0.033,j),_circle(0.287,0.033,i))
    return st.commit()

static func _draw(parent: Node3D,label: String,mesh: Mesh,
        pos: Vector3,material: Material,rotation: Vector3=Vector3.ZERO)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=mesh
    part.material_override=material
    part.position=pos
    part.rotation_degrees=rotation
    parent.add_child(part)
    return part

static func _cylinder(parent: Node3D,label: String,pos: Vector3,
        radius: float,height: float,material: Material,
        rotation: Vector3=Vector3.ZERO,segments:int=12)->MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    return _draw(parent,label,mesh,pos,material,rotation)

static func _box(parent: Node3D,label: String,pos: Vector3,
        dims: Vector3,material: Material)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=dims
    return _draw(parent,label,mesh,pos,material)

static func _rod(parent: Node3D,label: String,start: Vector3,
        finish: Vector3,radius: float,material: Material)->MeshInstance3D:
    var vec: Vector3=finish-start
    var rod:=_cylinder(parent,label,(start+finish)*0.5,
        radius,vec.length(),material,Vector3.ZERO,8)
    rod.basis=Basis(Quaternion(Vector3.UP,vec.normalized()))
    return rod

static func apply(root: Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta("tarvoka_g13_surface_detail_v13",false))):
        return false
    var radar:=root.find_child("G13_RadarAzimut",true,false) as Node3D
    var turret:=root.find_child("G13_TorretaAzimut",true,false) as Node3D
    var dish:=root.find_child(DISH,true,false) as MeshInstance3D
    var optic:=root.find_child(OPTIC,true,false) as MeshInstance3D
    var mast:=root.find_child("G13_RadarMast",true,false) as MeshInstance3D
    var receiver:=root.find_child("G13_RadarReceiver",true,false) as MeshInstance3D
    if radar==null or turret==null or dish==null or optic==null or (
            mast==null or receiver==null):
        return false
    if not dish.mesh is CylinderMesh or not optic.mesh is BoxMesh:
        return false
    if dish.get_parent()!=radar or optic.get_parent()!=turret:
        return false
    var armor:=_material(Color("#74868a"),0.39,0.67)
    var trim:=_material(Color("#a3b0af"),0.66,0.46)
    var dark:=_material(Color("#29363a"),0.28,0.80)
    var glass:=_material(Color("#346980"),0.18,0.26)

    # Replace only the mesh inside the approved V1 radar dish node.
    # Existing V1 orientation/position and scanning animations are untouched.
    dish.mesh=_reflector()
    dish.material_override=armor
    _draw(dish,RIM,_rim_mesh(),Vector3.ZERO,trim)
    _cylinder(dish,FEED,Vector3(0,0.132,0),
        0.032,0.070,dark)
    _cylinder(dish,"G13_V14_RadarFeedGlass",Vector3(0,0.176,0),
        0.025,0.014,glass)
    for index in range(4):
        var angle:int=index*(SEGMENTS/4)
        _rod(dish,BRACE % index,_circle(0.212,0.018,angle),
            Vector3(0,0.124,0),0.009,trim)

    # Collar and signal conduit rotate with the independent RADAR YAW pivot.
    _cylinder(radar,COLLAR,Vector3(0,0.156,0),
        0.094,0.058,trim)
    _rod(radar,"G13_V14_RadarSignalConduit",
        Vector3(-0.065,0.250,0.015),
        Vector3(-0.125,0.489,-0.090),0.014,dark)
    # Optical tracker stays on the TURRET AZIMUTH pivot, NOT on radar,
    # so it follows attack headings while the radar scans independently.
    _box(turret,SHROUD,Vector3(0.399,0.475,-0.344),
        Vector3(0.253,0.039,0.241),armor)
    _box(turret,"G13_V14_OpticRearBrace",Vector3(0.399,0.285,-0.238),
        Vector3(0.185,0.032,0.130),dark)
    for i in range(2):
        var px: float=0.347 if i==0 else 0.439
        var py: float=0.385 if i==0 else 0.308
        var radius: float=0.036 if i==0 else 0.027
        _cylinder(turret,BEZEL % i,Vector3(px,py,-0.420),
            radius+0.012,0.022,trim,Vector3(90,0,0),16)
        _cylinder(turret,LENS % i,Vector3(px,py,-0.438),
            radius,0.008,glass,Vector3(90,0,0),16)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v14_visual_only",true)
    root.set_meta("tarvoka_g13_v14_sensor_parts",14)
    return true
