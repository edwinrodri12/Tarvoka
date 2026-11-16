extends RefCounted
class_name TarvokaAttackHelicopterCabinV2

# A01 V2: replace the first-pass shell/canopy with actual enclosed native meshes.
# All work is on the >=13 studio model. Never alter the mobile battle LOD,
# unit costs, collision, damage, gameplay or the A01 V1 animation pivots.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const FLAG := "tarvoka_a01_cabin_hull_v2"
const SHOW := "tarvoka_a01_v2_enabled"
const ROOT := "A01_V2_CabinaYCascoEsculpidos"
const HULL := "A01_V2_Casco12CarasCerrado"
const GLASS := "A01_V2_CupulaTandemCristal3D"
const OLD := [
    "A01_MonocascoFacetado","A01_CarenadoCristalTandem",
    "A01_MarcoCristalMedio","A01_MarcoCristalFrontal"
]
const SIDES := 12

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false)!=null)

static func _group(parent: Node3D,name: String) -> Node3D:
    var node:=Node3D.new()
    node.name=name
    parent.add_child(node)
    return node

static func _material(color: Color, metal: float=0.2,
        rough: float=0.6, transparency: bool=false) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    if transparency:
        mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
    return mat

static func _mesh(parent: Node3D,name: String,geometry: Mesh,
        color: Color,metal: float=0.2,rough: float=0.6,
        transparency: bool=false) -> MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=name
    item.mesh=geometry
    item.material_override=_material(color,metal,rough,transparency)
    parent.add_child(item)
    return item

static func _box(parent: Node3D,name: String,
        position: Vector3,size: Vector3,color: Color,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var geometry:=BoxMesh.new()
    geometry.size=size
    var item:=_mesh(parent,name,geometry,color)
    item.position=position
    item.rotation_degrees=rotation
    return item

static func _sphere(parent: Node3D,name: String,
        position: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
    var geometry:=SphereMesh.new()
    geometry.radius=0.5
    geometry.height=1.0
    geometry.radial_segments=16
    geometry.rings=8
    var item:=_mesh(parent,name,geometry,color)
    item.position=position
    item.scale=size
    return item

static func _point(s: Vector4, i: int) -> Vector3:
    var a: float=TAU*float(i%SIDES)/float(SIDES)
    return Vector3(cos(a)*s.z,s.y+sin(a)*s.w,s.x)

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _closed_hull(stations: Array[Vector4]) -> ArrayMesh:
    # Every edge has a twin triangle; both longitudinal ends are capped.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(stations.size()-1):
        for j in range(SIDES):
            var a: Vector3=_point(stations[i],j)
            var b: Vector3=_point(stations[i],j+1)
            var c: Vector3=_point(stations[i+1],j+1)
            var d: Vector3=_point(stations[i+1],j)
            _tri(st,a,b,c)
            _tri(st,a,c,d)
    var first: Vector4=stations[0]
    var last: Vector4=stations[stations.size()-1]
    for j in range(SIDES):
        _tri(st,Vector3(0,first.y,first.x),
            _point(first,j+1),_point(first,j))
        _tri(st,Vector3(0,last.y,last.x),
            _point(last,j),_point(last,j+1))
    st.generate_normals()
    return st.commit()

static func _strut(parent: Node3D,name: String,
        a: Vector3,b: Vector3,r: float,color: Color) -> MeshInstance3D:
    var direction: Vector3=b-a
    var tube:=CylinderMesh.new()
    tube.top_radius=r
    tube.bottom_radius=r
    tube.height=direction.length()
    tube.radial_segments=8
    var item:=_mesh(parent,name,tube,color,0.4,0.48)
    item.position=(a+b)*0.5
    item.quaternion=Quaternion(Vector3.UP,direction.normalized())
    return item

static func _cabin(model_root: Node3D, paint: Color) -> void:
    var grey:=Color("#77858a")
    var dark:=Color("#1f2a30")
    var steel:=Color("#9aa6a9")
    var interior:=Color("#344249")
    var glass_tint:=Color("#397c98")
    glass_tint.a=0.68
    # Twelve-faced sculpt is a real replacement for the coarse V1 octagonal
    # hull, with a faceted nose, wider cockpit bay and smooth tail transition.
    var shell: Array[Vector4]=[
        Vector4(-1.70,0.95,0.085,0.115),
        Vector4(-1.44,0.99,0.300,0.260),
        Vector4(-1.08,1.045,0.480,0.370),
        Vector4(-0.72,1.07,0.565,0.420),
        Vector4(-0.13,1.07,0.635,0.450),
        Vector4(0.42,1.07,0.595,0.420),
        Vector4(0.85,1.06,0.450,0.340),
        Vector4(1.17,1.06,0.238,0.185)]
    _mesh(model_root,HULL,_closed_hull(shell),grey)
    # The canopy is also closed mesh geometry, not a painted window overlay.
    var canopy: Array[Vector4]=[
        Vector4(-1.47,1.40,0.105,0.075),
        Vector4(-1.18,1.47,0.265,0.208),
        Vector4(-0.87,1.52,0.368,0.275),
        Vector4(-0.48,1.53,0.405,0.320),
        Vector4(-0.08,1.53,0.370,0.260),
        Vector4(0.10,1.49,0.156,0.105)]
    _mesh(model_root,GLASS,_closed_hull(canopy),glass_tint,0.035,0.17,true)
    # Steel windshield uprights and side roof rails follow the exact
    # curved glass coordinates. No disconnected straight decorative bars.
    for station in [1,3,4]:
        for j in range(SIDES):
            var a: Vector3=_point(canopy[station],j)
            var b: Vector3=_point(canopy[station],j+1)
            # Limit to visible upper-side/roof ribs; do not build a cage
            # over the lower canopy buried in the hull.
            if a.y>=1.46 or b.y>=1.46:
                _strut(model_root,"A01_V2_Costilla_%d_%d" % [station,j],
                    a,b,0.012,dark)
    for rail in [2,3,4,5]:
        for i in range(canopy.size()-1):
            _strut(model_root,"A01_V2_MarcoLong_%d_%d" % [rail,i],
                _point(canopy[i],rail),_point(canopy[i+1],rail),0.011,dark)
    for rail in [7,8,9,10]:
        for i in range(canopy.size()-1):
            _strut(model_root,"A01_V2_MarcoOp_%d_%d" % [rail,i],
                _point(canopy[i],rail),_point(canopy[i+1],rail),0.011,dark)
    # Raised rear cockpit and a lower forward seat are actually inside
    # the transparent shell. Keep them above the armored lower hull.
    for seat in range(2):
        var z: float=-0.93 if seat==0 else -0.30
        var bottom_y: float=1.42 if seat==0 else 1.50
        _box(model_root,"A01_V2_Asiento_%d" % seat,
            Vector3(0,bottom_y,z),
            Vector3(0.34,0.115,0.30),dark)
        _box(model_root,"A01_V2_Respaldo_%d" % seat,
            Vector3(0,bottom_y+0.12,z+0.13),
            Vector3(0.32,0.36,0.10),interior,Vector3(-10,0,0))
        _box(model_root,"A01_V2_Pantalla_%d" % seat,
            Vector3(0,bottom_y+0.12,z-0.24),
            Vector3(0.32,0.14,0.07),glass_tint.darkened(0.20))
    # Door armor, recessed sill, hinges and canopy release handles.
    for side in [-1,1]:
        var s: float=float(side)
        _box(model_root,"A01_V2_PuertaCabina_%d" % side,
            Vector3(s*0.575,1.07,-0.52),
            Vector3(0.034,0.34,0.47),grey.darkened(0.12))
        _box(model_root,"A01_V2_ManijaPuerta_%d" % side,
            Vector3(s*0.603,1.14,-0.50),
            Vector3(0.035,0.040,0.120),steel)
        _box(model_root,"A01_V2_EstriboAntideslizante_%d" % side,
            Vector3(s*0.594,0.83,-0.52),
            Vector3(0.12,0.033,0.49),dark)
        for rivet in range(4):
            _sphere(model_root,"A01_V2_RemachePuerta_%d_%d" % [side,rivet],
                Vector3(s*0.604,0.94+float(rivet)*0.082,-0.72),
                Vector3(0.025,0.025,0.025),steel)
        _box(model_root,"A01_V2_ProteccionHombro_%d" % side,
            Vector3(s*0.61,1.30,0.24),
            Vector3(0.05,0.15,0.72),paint.darkened(0.10))
        _box(model_root,"A01_V2_TapaMantenimiento_%d" % side,
            Vector3(s*0.54,1.38,0.80),
            Vector3(0.055,0.18,0.42),grey.darkened(0.20))
        for slot in range(3):
            _box(model_root,"A01_V2_RejillaMotor_%d_%d" % [side,slot],
                Vector3(s*0.579,1.41,0.65+float(slot)*0.10),
                Vector3(0.025,0.045,0.066),dark)
    _box(model_root,"A01_V2_TapaSuperiorTransmision",
        Vector3(0,1.565,0.48),Vector3(0.56,0.055,0.68),grey)
    _box(model_root,"A01_V2_JuntaTapaSuperior",
        Vector3(0,1.596,0.48),Vector3(0.49,0.011,0.59),dark)
    _box(model_root,"A01_V2_BandaIdentificacionSuperior",
        Vector3(0,1.604,0.48),Vector3(0.15,0.014,0.49),paint)

static func apply(model: Node3D,faction: Color) -> bool:
    if model==null or not V1.has_model(model):
        return false
    if has_model(model):
        return true
    for name in OLD:
        if model.find_child(name,true,false)==null:
            return false
    var root_node: Node3D=_group(model,ROOT)
    _cabin(root_node,faction)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    _refresh(model)
    return true

static func _refresh(model: Node3D) -> void:
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var current: Node3D=model.find_child(ROOT,true,false) as Node3D
    if current!=null:
        current.visible=enabled
    for label in OLD:
        var legacy: Node3D=model.find_child(label,true,false) as Node3D
        if legacy!=null:
            legacy.visible=not enabled

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    model.set_meta(SHOW,enabled)
    _refresh(model)
    return true
