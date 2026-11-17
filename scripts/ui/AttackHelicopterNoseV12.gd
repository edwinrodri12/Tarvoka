extends RefCounted
class_name TarvokaAttackHelicopterNoseV12

# A01 V12: actual 3D front armour and articulated cannon cradle.
# Hero Studio geometry only (art_level >= 13); no unit rules or battle LOD.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V11=preload("res://scripts/ui/AttackHelicopterTailV11.gd")
const FLAG := "tarvoka_a01_nose_gun_v12"
const ENABLED := "tarvoka_a01_nose_gun_v12_enabled"
const ROOT := "A01V12_BlindajeFrontalArticulado"
const GUN_ROOT := "A01V12_CunaCanonMovil"
const LEFT_CHEEK := "A01V12_MejillaBlindada_-1"
const RIGHT_CHEEK := "A01V12_MejillaBlindada_1"
const GIMBAL := "A01V12_CarenadoCardan"
const OPTIC_RING := "A01V12_BiselOptica"
const TRUNNION := "A01V12_MunonCanon_"

static func _part(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _part(model,ROOT)!=null and _part(model,GUN_ROOT)!=null
        and _part(model,LEFT_CHEEK)!=null and _part(model,RIGHT_CHEEK)!=null)

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _material(color: Color,metal: float=0.38,
        rough: float=0.43) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        color: Color,pos: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.material_override=_material(color)
    n.position=pos
    parent.add_child(n)
    return n

static func _rod(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,color: Color) -> MeshInstance3D:
    var axis: Vector3=b-a
    var shape:=CylinderMesh.new()
    shape.height=axis.length()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.radial_segments=12
    var m:=_mesh(parent,name,shape,color,(a+b)*0.5)
    m.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return m

static func _ring(parent: Node3D,name: String,pos: Vector3,
        inner: float,outer: float,color: Color,
        axis: String="z") -> MeshInstance3D:
    var t:=TorusMesh.new()
    t.inner_radius=inner
    t.outer_radius=outer
    t.rings=12
    t.ring_segments=28
    var m:=_mesh(parent,name,t,color,pos)
    m.rotation_degrees.x=90.0 if axis=="z" else 0.0
    return m

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _cheek_mesh(side: int) -> ArrayMesh:
    # Four closed cross-sections on the ACTUAL V2 hull, nose z is negative.
    # Each section is a four-point bevel rather than a flat painted triangle.
    var sections: Array[Vector4]=[
        Vector4(-1.55,0.970,0.224,0.087),
        Vector4(-1.38,0.995,0.335,0.136),
        Vector4(-1.11,1.033,0.473,0.176),
        Vector4(-0.82,1.065,0.572,0.172)]
    var s: float=float(side)
    var points: Array=[]
    for section in sections:
        var z: float=section.x
        var y: float=section.y
        var r: float=section.z
        var h: float=section.w
        points.append([
            Vector3(s*r,y+h,z),
            Vector3(s*r,y-h,z),
            Vector3(s*(r-0.067),y-h+0.024,z),
            Vector3(s*(r-0.067),y+h-0.024,z)])
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(points.size()-1):
        for j in range(4):
            _quad(st,points[i][j],points[i][(j+1)%4],
                points[i+1][(j+1)%4],points[i+1][j])
    # Close the two ends with two non-degenerate triangles each.
    for j in range(1,3):
        st.add_vertex(points[0][0])
        st.add_vertex(points[0][j+1])
        st.add_vertex(points[0][j])
        st.add_vertex(points[points.size()-1][0])
        st.add_vertex(points[points.size()-1][j])
        st.add_vertex(points[points.size()-1][j+1])
    st.generate_normals()
    return st.commit()

static func _fixed_nose(body: Node3D,faction: Color) -> void:
    var root_node:=_group(body,ROOT)
    var paint:=Color("#788892")
    var seam:=Color("#293a43")
    var steel:=Color("#a2b5bd")
    # Flush side geometry bridges the sharp front to the V2 cockpit width.
    for side in [-1,1]:
        var sign: float=float(side)
        _mesh(root_node,"A01V12_MejillaBlindada_%d" % side,
            _cheek_mesh(side),paint)
        _rod(root_node,"A01V12_LineaSeparacion_%d" % side,
            Vector3(sign*0.354,1.129,-1.38),
            Vector3(sign*0.489,1.191,-1.10),0.010,seam)
        _rod(root_node,"A01V12_CosturaIdentidad_%d" % side,
            Vector3(sign*0.480,1.035,-1.095),
            Vector3(sign*0.577,1.055,-0.826),0.015,
            faction.darkened(0.15))
        # Two genuine fixed gimbal mounts; rotating gun remains separate.
        _rod(root_node,"A01V12_BrazoSoporteCanon_%d" % side,
            Vector3(sign*0.205,0.786,-1.137),
            Vector3(sign*0.222,0.580,-1.330),
            0.032,seam)
        var bearing:=CylinderMesh.new()
        bearing.height=0.053
        bearing.top_radius=0.092
        bearing.bottom_radius=0.092
        bearing.radial_segments=16
        var b:=_mesh(root_node,"A01V12_CojineteFijo_%d" % side,
            bearing,steel,Vector3(sign*0.224,0.570,-1.330))
        b.rotation_degrees.z=90.0
        # Exposed, paired cradle side-gussets keep the turret mechanically
        # attached to the V2 belly without intersecting its animated sphere.
        # Minimum x clearance to the existing 0.19m gun housing is 0.076m.
        _rod(root_node,"A01V12_PilarCunaSuperior_%d" % side,
            Vector3(sign*0.300,0.805,-1.240),
            Vector3(sign*0.300,0.641,-1.355),
            0.018,seam)
        _rod(root_node,"A01V12_PilarCunaDelantero_%d" % side,
            Vector3(sign*0.300,0.641,-1.355),
            Vector3(sign*0.302,0.637,-1.468),
            0.016,paint)
        _rod(root_node,"A01V12_RefuerzoDiagonalCuna_%d" % side,
            Vector3(sign*0.300,0.805,-1.240),
            Vector3(sign*0.302,0.637,-1.468),
            0.011,steel)
    # The transverse structure is behind/above the gun elevation envelope,
    # so the authentic 6-degree V1 firing pitch never clips through it.
    _rod(root_node,"A01V12_PuenteTransversalCuna",
        Vector3(-0.300,0.805,-1.240),
        Vector3(0.300,0.805,-1.240),0.020,seam)
    _ring(root_node,OPTIC_RING,Vector3(0,0.650,-1.791),
        0.075,0.115,steel)
    _rod(root_node,"A01V12_ProteccionInferiorMorro",
        Vector3(-0.188,0.738,-1.480),
        Vector3(0.188,0.738,-1.480),0.023,seam)

static func _moving_cannon(weapon: Node3D) -> void:
    # This layer is parented to A01_ArmaMorro, NOT to the fuselage:
    # V1.pose physically pitches the trunnions, gun and barrel together.
    var moving:=_group(weapon,GUN_ROOT)
    var armor:=Color("#657783")
    var steel:=Color("#a5b8c2")
    var seam:=Color("#2b3c46")
    var housing:=CylinderMesh.new()
    housing.top_radius=0.160
    housing.bottom_radius=0.190
    housing.height=0.205
    housing.radial_segments=16
    var cup:=_mesh(moving,GIMBAL,housing,armor,
        Vector3(0,0,-0.042))
    cup.rotation_degrees.x=90.0
    _ring(moving,"A01V12_AnilloCardanTrasero",
        Vector3(0,0,0.105),0.160,0.205,steel)
    _ring(moving,"A01V12_CollarCanonFrontal",
        Vector3(0,0,-0.381),0.080,0.118,seam)
    for side in [-1,1]:
        var s: float=float(side)
        var disc:=CylinderMesh.new()
        disc.height=0.043
        disc.top_radius=0.078
        disc.bottom_radius=0.078
        disc.radial_segments=12
        var moving_disc:=_mesh(moving,TRUNNION+str(side),disc,steel,
            Vector3(s*0.204,0.0,0.0))
        moving_disc.rotation_degrees.z=90.0
        _rod(moving,"A01V12_PernoMunon_%d" % side,
            Vector3(s*0.226,0,0),Vector3(s*0.252,0,0),
            0.024,seam)
    # Parallel physical guide rails share the ORIGINAL A01 gun pivot.
    # They are outside the 0.078m barrel and never touch the muzzle flash.
    for side in [-1,1]:
        var sign: float=float(side)
        _rod(moving,"A01V12_GuiaMovilCanon_%d" % side,
            Vector3(sign*0.143,-0.075,-0.135),
            Vector3(sign*0.143,-0.075,-0.345),
            0.018,armor)
        _rod(moving,"A01V12_BisagraGuiaCanon_%d" % side,
            Vector3(sign*0.143,-0.075,-0.135),
            Vector3(sign*0.143,-0.075,-0.153),
            0.030,steel)
    # Subtle bevel and bore rim are visible at close range, while the
    # original V10 chrome band and V1 muzzle flash are preserved.
    _ring(moving,"A01V12_AroBocaExterior",
        Vector3(0,0,-0.817),0.075,0.113,steel)

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    _part(model,ROOT).visible=enabled
    _part(model,GUN_ROOT).visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,faction: Color) -> bool:
    if not V2.has_model(model) or not V11.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_part(model,V1.ROOT)
    var weapon: Node3D=_part(model,V1.GUN)
    if body==null or weapon==null or _part(model,V2.HULL)==null:
        return false
    _fixed_nose(body,faction)
    _moving_cannon(weapon)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
