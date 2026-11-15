extends RefCounted
class_name TarvokaG11FinishV2

# G11 V2: native sculpted bevels, closed-contour tracks and cached PBR materials.
# Decorative-only extension of G11 V1. Does NOT touch combat, HP, fuel or saves.
# One MultiMesh draw per track side, rather than one draw per moving tread.
const FLAG := "tarvoka_g11_finish_v2"
const TRACK_CENTER_Y := 0.35
const TRACK_HALF_LENGTH := 1.04
const TRACK_OUTER_RADIUS := 0.35
const TRACK_INNER_RADIUS := 0.265
const TRACK_CENTER_X := 0.79
const TRACK_LINK_COUNT := 40
const LINK_TRAVEL := 2.15

static func _mat(color: Color, metallic: float, roughness: float,
        double_sided: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    if double_sided:
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3, ua: Vector2, ub: Vector2,
        uc: Vector2, ud: Vector2) -> void:
    for point in [[a,ua],[b,ub],[c,uc],[a,ua],[c,uc],[d,ud]]:
        st.set_uv(point[1])
        st.add_vertex(point[0])

static func _prism(parent: Node3D, label: String, center: Vector3,
        half_width: float, ybottom: float, ytop: float,
        front: float, rear: float, bevel: float,
        material: StandardMaterial3D) -> MeshInstance3D:
    # A closed, octagonal armored prism. Its four long edges are actual
    # chamfered geometry; not an angled decal on top of a rectangle.
    var w: float = half_width
    var b: float = minf(bevel,minf(w*0.4,(ytop-ybottom)*0.40))
    var profile: Array[Vector2] = [
        Vector2(-w+b,ytop),Vector2(w-b,ytop),
        Vector2(w,ytop-b),Vector2(w,ybottom+b),
        Vector2(w-b,ybottom),Vector2(-w+b,ybottom),
        Vector2(-w,ybottom+b),Vector2(-w,ytop-b)
    ]
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for k in range(profile.size()):
        var p0: Vector2 = profile[k]
        var p1: Vector2 = profile[(k+1)%profile.size()]
        var a := Vector3(p0.x,p0.y,front)
        var b0 := Vector3(p1.x,p1.y,front)
        var c := Vector3(p1.x,p1.y,rear)
        var d := Vector3(p0.x,p0.y,rear)
        _quad(st,a,b0,c,d,Vector2(0,0),Vector2(1,0),
            Vector2(1,1),Vector2(0,1))
    # Close both front and rear: no transparent or hollow rear panel.
    for i in range(1,profile.size()-1):
        var a0 := profile[0]
        var b0 := profile[i]
        var c0 := profile[i+1]
        for z in [front,rear]:
            for v in [a0,b0,c0]:
                st.set_uv(Vector2((v.x+w)/(2*w),
                    (v.y-ybottom)/(ytop-ybottom)))
                st.add_vertex(Vector3(v.x,v.y,z))
    st.generate_normals()
    var out := MeshInstance3D.new()
    out.name = label
    out.mesh = st.commit()
    out.material_override = material
    out.position = center
    parent.add_child(out)
    return out

static func _box(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, material: StandardMaterial3D,
        angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = material
    n.position = pos
    n.rotation_degrees = angle
    parent.add_child(n)
    return n

static func _cylinder(parent: Node3D, label: String, pos: Vector3,
        radius: float, depth: float,
        material: StandardMaterial3D) -> MeshInstance3D:
    var m := CylinderMesh.new()
    m.top_radius = radius
    m.bottom_radius = radius
    m.height = depth
    m.radial_segments = 18
    var n := MeshInstance3D.new()
    n.name = label
    n.mesh = m
    n.material_override = material
    n.position = pos
    n.rotation_degrees.z = 90.0
    parent.add_child(n)
    return n

static func _path(s: float, radius: float) -> Vector2:
    # Return (y,z) at arclength s on the outer racetrack contour.
    # Four smooth phases: lower run, front idler, upper run, rear sprocket.
    var straight: float = TRACK_HALF_LENGTH*2.0
    var arc: float = PI*radius
    var circumference: float = 2.0*straight+2.0*arc
    var p: float = fposmod(s,circumference)
    if p < straight:
        return Vector2(TRACK_CENTER_Y-radius,TRACK_HALF_LENGTH-p)
    if p < straight+arc:
        var theta: float = -PI*0.5+(p-straight)/radius
        return Vector2(TRACK_CENTER_Y+radius*sin(theta),
            -TRACK_HALF_LENGTH-radius*cos(theta))
    if p < 2.0*straight+arc:
        return Vector2(TRACK_CENTER_Y+radius,
            -TRACK_HALF_LENGTH+(p-straight-arc))
    var theta: float = PI*0.5+(p-2.0*straight-arc)/radius
    return Vector2(TRACK_CENTER_Y+radius*sin(theta),
        TRACK_HALF_LENGTH+radius*cos(theta))

static func _circumference(radius: float) -> float:
    return 4.0*TRACK_HALF_LENGTH+TAU*radius

static func _belt_mesh() -> ArrayMesh:
    # Real closed ribbon over inner/outer contours; wheels are visible through
    # the center instead of being concealed behind a large rubber cube.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments := 56
    var length: float = _circumference(TRACK_OUTER_RADIUS)
    for k in range(segments):
        var s0: float = length*float(k)/float(segments)
        var s1: float = length*float(k+1)/float(segments)
        var o0: Vector2 = _path(s0,TRACK_OUTER_RADIUS)
        var o1: Vector2 = _path(s1,TRACK_OUTER_RADIUS)
        # Keep matching phase using the same normalized loop fraction.
        var i0: Vector2 = _path(s0*_circumference(TRACK_INNER_RADIUS)/length,
            TRACK_INNER_RADIUS)
        var i1: Vector2 = _path(s1*_circumference(TRACK_INNER_RADIUS)/length,
            TRACK_INNER_RADIUS)
        for side in [0,1]:
            var x: float = -0.142 if side == 0 else 0.142
            _quad(st,Vector3(x,o0.x,o0.y),Vector3(x,o1.x,o1.y),
                Vector3(x,i1.x,i1.y),Vector3(x,i0.x,i0.y),
                Vector2(0,float(k)/segments),Vector2(1,float(k)/segments),
                Vector2(1,float(k+1)/segments),Vector2(0,float(k+1)/segments))
        # Outer and inner walls complete the belt's thickness.
        for outer in [true,false]:
            var p0: Vector2 = o0 if outer else i0
            var p1: Vector2 = o1 if outer else i1
            _quad(st,Vector3(-0.142,p0.x,p0.y),
                Vector3(-0.142,p1.x,p1.y),
                Vector3(0.142,p1.x,p1.y),
                Vector3(0.142,p0.x,p0.y),
                Vector2(0,float(k)/segments),Vector2(1,float(k)/segments),
                Vector2(1,float(k+1)/segments),Vector2(0,float(k+1)/segments))
    st.generate_normals()
    return st.commit()

static func _update_side(multimesh: MultiMesh, side: int,
        progression: float) -> void:
    var loop_len: float = _circumference(TRACK_OUTER_RADIUS)
    for i in range(TRACK_LINK_COUNT):
        var s: float = loop_len*float(i)/float(TRACK_LINK_COUNT) + progression
        var here: Vector2 = _path(s,TRACK_OUTER_RADIUS+0.011)
        var a: Vector2 = _path(s-0.005,TRACK_OUTER_RADIUS+0.011)
        var b: Vector2 = _path(s+0.005,TRACK_OUTER_RADIUS+0.011)
        var delta: Vector2 = b-a
        # Box local Z follows belt tangent in the YZ plane.
        var angle: float = atan2(-delta.x,delta.y)
        var basis := Basis(Vector3.RIGHT,angle)
        var origin := Vector3(float(side)*TRACK_CENTER_X,here.x,here.y)
        multimesh.set_instance_transform(i,Transform3D(basis,origin))

static func pose_tracks(model: Node3D, normalized_progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var offset: float = normalized_progress*LINK_TRAVEL
    for side in [-1,1]:
        var instance := model.find_child("G11V2_OrugaAnimada_%d" % side,
            true,false) as MultiMeshInstance3D
        if instance == null or instance.multimesh == null:
            return false
        _update_side(instance.multimesh,side,offset)
    return true

static func _remove_old_track(root: Node3D) -> void:
    for side in [-1,1]:
        var slab := root.find_child("G11_Oruga_%d" % side,true,false)
        if slab != null:
            slab.get_parent().remove_child(slab)
            slab.free()
        for i in range(14):
            var shoe := root.find_child("G11_Zapata_%d_%02d" % [side,i],
                true,false)
            if shoe != null:
                shoe.get_parent().remove_child(shoe)
                shoe.free()

static func apply(model: Node3D, faction: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    var root := model.find_child("G11_CascoRaiz",true,false) as Node3D
    if root == null:
        return false
    _remove_old_track(root)
    var steel := _mat(Color("#647277"),0.31,0.63,true)
    var armor := _mat(Color("#89938e"),0.22,0.73,true)
    var dark := _mat(Color("#242c2e"),0.18,0.78,true)
    var rubber := _mat(Color("#202527"),0.03,0.95,true)
    var tread := _mat(Color("#414749"),0.19,0.84,true)
    var silver := _mat(Color("#aeb8b5"),0.66,0.40,true)
    var marking := _mat(faction.darkened(0.12),0.22,0.66,true)
    # Replace V1 blocky superstructures with sealed chamfered 3D geometry.
    for label in ["G11_MonocascoCerrado","G11_CabinaDelantera",
            "G11_TechoCabinaSellado"]:
        var old := root.find_child(label,true,false)
        if old != null:
            old.get_parent().remove_child(old)
            old.free()
    _prism(root,"G11V2_CascoOctogonalCerrado",Vector3.ZERO,0.73,
        0.32,1.02,-1.35,1.40,0.105,steel)
    _prism(root,"G11V2_CabinaBiselada",Vector3.ZERO,0.63,
        0.87,1.54,-1.31,-0.37,0.13,armor)
    _prism(root,"G11V2_NarizBlindada",Vector3.ZERO,0.58,
        0.69,1.05,-1.49,-1.16,0.082,steel)
    for side in [-1,1]:
        var sign: float = float(side)
        # Each belt is one mesh. Tread links are one additional MultiMesh.
        var belt := MeshInstance3D.new()
        belt.name = "G11V2_BandaOruga_%d" % side
        belt.mesh = _belt_mesh()
        belt.material_override = rubber
        belt.position.x = sign*TRACK_CENTER_X
        root.add_child(belt)
        var link_mesh := BoxMesh.new()
        link_mesh.size = Vector3(0.297,0.053,0.129)
        link_mesh.material = tread
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.mesh = link_mesh
        multi.instance_count = TRACK_LINK_COUNT
        var links := MultiMeshInstance3D.new()
        links.name = "G11V2_OrugaAnimada_%d" % side
        links.multimesh = multi
        root.add_child(links)
        _update_side(multi,side,0.0)
        # Idler and rear drive sprocket create visible mechanical differentiation.
        for axle in range(2):
            var z: float = -TRACK_HALF_LENGTH if axle == 0 else TRACK_HALF_LENGTH
            _cylinder(root,"G11V2_RuedaTensor_%d_%d" % [side,axle],
                Vector3(sign*0.80,TRACK_CENTER_Y,z),0.25,0.08,dark)
            _cylinder(root,"G11V2_AroPiñon_%d_%d" % [side,axle],
                Vector3(sign*0.965,TRACK_CENTER_Y,z),0.154,0.035,silver)
        # Side armor has a real bevel, not a giant rectangular slab.
        _prism(root,"G11V2_ProteccionLateral_%d" % side,
            Vector3(sign*0.688,0,0.09),0.06,
            0.78,1.05,-0.72,1.22,0.03,steel)
        _box(root,"G11V2_BandaFaccion_%d" % side,
            Vector3(sign*0.770,0.95,0.54),
            Vector3(0.026,0.072,0.68),marking)
        _box(root,"G11V2_BisagraFaldon_%d" % side,
            Vector3(sign*0.75,0.76,-0.50),
            Vector3(0.05,0.055,0.16),silver)
        # Small panel seams and original weathering make large plates readable.
        for seam in range(3):
            _box(root,"G11V2_JuntaCostado_%d_%d" % [side,seam],
                Vector3(sign*0.765,0.94,-0.39+float(seam)*0.48),
                Vector3(0.029,0.18,0.015),dark)
    # Rear airflow louvers and framed front glass: no floating decals.
    for index in range(5):
        _box(root,"G11V2_VentilacionPosterior_%d" % index,
            Vector3(-0.47+float(index)*0.235,0.89,1.427),
            Vector3(0.115,0.058,0.023),dark)
    for offset in [-1,1]:
        _box(root,"G11V2_ProtectorCristal_%d" % offset,
            Vector3(float(offset)*0.45,1.30,-1.347),
            Vector3(0.052,0.30,0.035),steel)
        _box(root,"G11V2_PernoPorton_%d" % offset,
            Vector3(float(offset)*0.48,0.70,1.491),
            Vector3(0.08,0.12,0.03),silver)
    _box(root,"G11V2_JuntaVentanillaSuperior",Vector3(0,1.453,-1.35),
        Vector3(0.98,0.038,0.045),dark)
    # Bolted mount collar reinforces the separately animated launcher.
    var turret := root.find_child("G11_GiroPlataforma",true,false) as Node3D
    if turret != null:
        _cylinder(turret,"G11V2_CoronaAcero",Vector3(0,0.08,0),
            0.48,0.13,silver)
        for side in [-1,1]:
            _box(turret,"G11V2_RefuerzoBase_%d" % side,
                Vector3(float(side)*0.47,0.26,0.02),
                Vector3(0.12,0.14,0.55),steel)
        var launcher := turret.find_child("G11_ElevacionLanzador",true,false) as Node3D
        if launcher != null:
            for side in [-1,1]:
                _box(launcher,"G11V2_NervioLateral_%d" % side,
                    Vector3(float(side)*0.605,0.06,0.06),
                    Vector3(0.075,0.17,1.28),armor)
                _box(launcher,"G11V2_MarcaFaccionModulo_%d" % side,
                    Vector3(float(side)*0.675,0.24,0.34),
                    Vector3(0.025,0.10,0.46),marking)
    model.set_meta(FLAG,true)
    return true
