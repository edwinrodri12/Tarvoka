extends RefCounted
class_name TarvokaInfantryEngineerSmoothV13

# V13: true smoothed, sealed geometry ON the approved animated Engineer.
# Refines the existing mesh instances rather than stacking fake transparent
# shells or creating a second viewer. LOD8 remains compact for Android.
const V9=preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const V11=preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const FLAG: String="tarvoka_engineer_smooth_v13"
const ROLE: String="infantry_engineer"

static func _emit(st: SurfaceTool, p: Vector3, n: Vector3) -> void:
    st.set_normal(n)
    st.add_vertex(p)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3,
        na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
    _emit(st,a,na)
    _emit(st,b,nb)
    _emit(st,c,nc)
    _emit(st,a,na)
    _emit(st,c,nc)
    _emit(st,d,nd)

# A watertight rounded rectangle with continuously shaded bevel and real
# thickness. Outer edges keep the engineer shield's approved width/height,
# while corner arcs replace the former 8 hard silhouette cuts.
# Local exterior is -Z, as on the original V11 press. V12's existing
# Y=180° transform makes the outside face the rear-facing +Z surface.
static func _rounded_press(w: float, h: float, thick: float,
        corner: float, bulge: float, hero: bool) -> ArrayMesh:
    var radius: float=minf(corner,minf(w,h)*0.28)
    var cx: float=w*0.5-radius
    var cy: float=h*0.5-radius
    var steps: int=6 if hero else 3
    var rim: Array[Vector2]=[]
    for q in range(4):
        var center: Vector2=Vector2(
            cx if q<2 else -cx,
            -cy if q==0 or q==3 else cy)
        for step in range(steps+1):
            var angle: float=(float(q)-1.0)*PI*0.5+(
                float(step)/float(steps))*PI*0.5
            rim.append(center+Vector2(cos(angle),sin(angle))*radius)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var front_rim: float=-thick*0.5
    var inner_z: float=front_rim-maxf(0.003,bulge*0.34)
    var front_center: float=front_rim-maxf(0.004,bulge)
    var rear_z: float=thick*0.5
    for i in range(rim.size()):
        var j: int=(i+1)%rim.size()
        var p: Vector2=rim[i]
        var q: Vector2=rim[j]
        var prev: Vector2=rim[(i+rim.size()-1)%rim.size()]
        var after: Vector2=rim[(j+1)%rim.size()]
        var ni: Vector2=Vector2(p.y-prev.y,prev.x-p.x)+(
            Vector2(q.y-p.y,p.x-q.x))
        var nj: Vector2=Vector2(q.y-p.y,p.x-q.x)+(
            Vector2(after.y-q.y,q.x-after.x))
        # Convert CCW contour's tangent into a smooth outward 2D normal.
        ni=ni.normalized()
        nj=nj.normalized()
        var inner_a:=Vector3(p.x*0.87,p.y*0.87,inner_z)
        var inner_b:=Vector3(q.x*0.87,q.y*0.87,inner_z)
        var outer_a:=Vector3(p.x,p.y,front_rim)
        var outer_b:=Vector3(q.x,q.y,front_rim)
        var rear_a:=Vector3(p.x,p.y,rear_z)
        var rear_b:=Vector3(q.x,q.y,rear_z)
        var inner_na:=Vector3(ni.x*0.27,ni.y*0.27,-0.96).normalized()
        var inner_nb:=Vector3(nj.x*0.27,nj.y*0.27,-0.96).normalized()
        var outer_na:=Vector3(ni.x*0.79,ni.y*0.79,-0.61).normalized()
        var outer_nb:=Vector3(nj.x*0.79,nj.y*0.79,-0.61).normalized()
        var side_na:=Vector3(ni.x,ni.y,0)
        var side_nb:=Vector3(nj.x,nj.y,0)
        # From inside to perimeter, continuously smoothed bevel.
        _quad(st,inner_a,inner_b,outer_b,outer_a,
            inner_na,inner_nb,outer_nb,outer_na)
        # Full, single-sided outward sidewall.
        _quad(st,outer_a,outer_b,rear_b,rear_a,
            outer_na,outer_nb,side_nb,side_na)
        # Physical closed front and rear caps.
        for vertex in [Vector3(0,0,front_center),inner_b,inner_a]:
            _emit(st,vertex,Vector3(0,0,-1))
        for vertex in [Vector3(0,0,rear_z),rear_a,rear_b]:
            _emit(st,vertex,Vector3(0,0,1))
    return st.commit()

static func _catmull(a: float, b: float, c: float,
        d: float, t: float) -> float:
    # Interpolate radii only; preserve original ring heights and end points.
    return 0.5*((2.0*b)+(-a+c)*t+
        (2.0*a-5.0*b+4.0*c-d)*t*t+
        (-a+3.0*b-3.0*c+d)*t*t*t)

static func _lathe(rings: Array, hero: bool,
        z_shift: float=0.0) -> ArrayMesh:
    var sections: int=3 if hero else 2
    var slices: int=24 if hero else 14
    var smooth: Array[Vector3]=[]
    for i in range(rings.size()-1):
        for k in range(sections):
            var t: float=float(k)/float(sections)
            var before: Vector3=rings[maxi(0,i-1)]
            var here: Vector3=rings[i]
            var next: Vector3=rings[i+1]
            var after: Vector3=rings[mini(rings.size()-1,i+2)]
            smooth.append(Vector3(
                maxf(0.012,_catmull(before.x,here.x,next.x,after.x,t)),
                lerpf(here.y,next.y,t),
                maxf(0.012,_catmull(before.z,here.z,next.z,after.z,t))))
    smooth.append(rings[-1])
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(smooth.size()-1):
        for k in range(slices):
            var a: float=TAU*float(k)/float(slices)
            var b: float=TAU*float(k+1)/float(slices)
            var p0: Vector3=_lathe_point(smooth[i],a,z_shift)
            var p1: Vector3=_lathe_point(smooth[i],b,z_shift)
            var q0: Vector3=_lathe_point(smooth[i+1],a,z_shift)
            var q1: Vector3=_lathe_point(smooth[i+1],b,z_shift)
            var np0: Vector3=_lathe_normal(smooth,i,a)
            var np1: Vector3=_lathe_normal(smooth,i,b)
            var nq0: Vector3=_lathe_normal(smooth,i+1,a)
            var nq1: Vector3=_lathe_normal(smooth,i+1,b)
            # Counterclockwise viewed from outside, no missing side faces.
            _emit(st,p0,np0)
            _emit(st,q0,nq0)
            _emit(st,p1,np1)
            _emit(st,p1,np1)
            _emit(st,q0,nq0)
            _emit(st,q1,nq1)
    var low_y: float=smooth[0].y
    var top_y: float=smooth[-1].y
    for k in range(slices):
        var a: float=TAU*float(k)/float(slices)
        var b: float=TAU*float(k+1)/float(slices)
        for point in [Vector3(0,low_y,z_shift),
                _lathe_point(smooth[0],a,z_shift),
                _lathe_point(smooth[0],b,z_shift)]:
            _emit(st,point,Vector3.DOWN)
        for point in [Vector3(0,top_y,z_shift),
                _lathe_point(smooth[-1],b,z_shift),
                _lathe_point(smooth[-1],a,z_shift)]:
            _emit(st,point,Vector3.UP)
    return st.commit()

static func _lathe_point(ring: Vector3, angle: float,
        z_shift: float) -> Vector3:
    return Vector3(ring.x*cos(angle),ring.y,ring.z*sin(angle)+z_shift)

static func _lathe_normal(rings: Array[Vector3], i: int,
        angle: float) -> Vector3:
    var prev: Vector3=rings[maxi(0,i-1)]
    var next: Vector3=rings[mini(rings.size()-1,i+1)]
    var p: Vector3=rings[i]
    var rise:=Vector3(
        (next.x-prev.x)*cos(angle),
        maxf(0.0001,next.y-prev.y),
        (next.z-prev.z)*sin(angle))
    var sweep:=Vector3(-p.x*sin(angle),0,p.z*cos(angle))
    return rise.cross(sweep).normalized()

static func _replace(model: Node3D, name: String,
        mesh: ArrayMesh) -> bool:
    var part:=model.find_child(name,true,false) as MeshInstance3D
    if part==null:
        return false
    # The exact original rig, animation, material, transform and node name
    # remain untouched. Replace mesh data in-place, never duplicate solids.
    part.mesh=mesh
    return true

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func apply(model: Node3D, hero: bool) -> bool:
    if model==null or has_model(model) or (
            str(model.get_meta("tarvoka_infantry_role",""))!=ROLE) or (
            not V12.has_seals(model)):
        return false
    var panels: Array=[
        [V12.FRAME,1.210,0.668,0.139,0.016],
        [V12.MAIN,1.155,0.606,0.126,0.033],
        ["V12_BandaFaccionSuperiorTallada",0.842,0.113,0.028,0.012],
        ["V12_CierreCentralMetal",0.222,0.102,0.024,0.008],
        [V11.LOWER,0.500,0.215,0.045,0.036],
        ["V11_CintaColorEnPetoCurvo",0.250,0.046,0.010,0.004]
    ]
    for side in [-1,1]:
        panels.append([V12.OUTER+"_%d"%side,0.420,0.273,0.081,0.018])
        panels.append([V12.ACCENT+"_%d"%side,0.247,0.098,0.032,0.011])
        panels.append([V12.STRUT+"_%d"%side,0.071,0.403,0.020,0.010])
        panels.append([V12.WING_SKIN+"_%d"%side,0.154,0.557,0.046,0.014])
        panels.append(["V12_BandaFaccionAlaMovil_%d"%side,
            0.091,0.170,0.023,0.010])
        panels.append(["V12_TapaEstucheBiselada_%d"%side,
            0.170,0.110,0.035,0.012])
        panels.append([V12.POUCH_ID+"_%d"%side,
            0.162,0.124,0.028,0.010])
        panels.append([V11.LATERAL+"_%d"%side,
            0.105,0.296,0.021,0.024])
    for data in panels:
        var name: String=str(data[0])
        var base: MeshInstance3D=model.find_child(
            name,true,false) as MeshInstance3D
        if base==null:
            return false
        var thick: float=0.035
        if name.begins_with("V11_"):
            # Keep original V11 thickness without changing front orientation.
            thick=0.040 if name==V11.LOWER else 0.030
        var mesh: ArrayMesh=_rounded_press(
            float(data[1]),float(data[2]),thick,
            float(data[3]),float(data[4]),hero)
        if not _replace(model,name,mesh):
            return false
        base.set_meta("tarvoka_v13_rounded",true)

    var profiles: Dictionary={
        V9.HELMET:[
            Vector3(0.17,0.135,0.185),Vector3(0.250,0.190,0.235),
            Vector3(0.282,0.300,0.272),Vector3(0.286,0.415,0.284),
            Vector3(0.252,0.525,0.253),Vector3(0.164,0.605,0.160),
            Vector3(0.060,0.636,0.055)],
        "V2_MochilaOrganica":[
            Vector3(0.17,-0.35,0.08),Vector3(0.26,-0.27,0.155),
            Vector3(0.29,0.06,0.18),Vector3(0.25,0.31,0.13),
            Vector3(0.13,0.35,0.075)]
    }
    for side in [-1,1]:
        profiles["V2_MusloTaper_%d"%side]=[
            Vector3(0.13,-0.50,0.135),Vector3(0.145,-0.42,0.165),
            Vector3(0.16,-0.18,0.18),Vector3(0.15,0.01,0.17)]
        profiles["V2_PantorrillaTaper_%d"%side]=[
            Vector3(0.115,-0.87,0.125),Vector3(0.125,-0.75,0.135),
            Vector3(0.14,-0.57,0.155),Vector3(0.125,-0.46,0.145)]
        profiles["V2_BotaMoldeada_%d"%side]=[
            Vector3(0.115,-0.895,0.16),Vector3(0.12,-0.81,0.19),
            Vector3(0.11,-0.68,0.14)]
        profiles["V2_MangaCerrada_%d"%side]=[
            Vector3(0.105,-0.52,0.115),Vector3(0.14,-0.34,0.145),
            Vector3(0.16,-0.10,0.16),Vector3(0.17,0.055,0.15)]
        profiles["V2_AntebrazoCerrado_%d"%side]=[
            Vector3(0.104,-0.72,0.115),Vector3(0.115,-0.59,0.115),
            Vector3(0.12,-0.46,0.125)]
        profiles[V12.CASE+"_%d"%side]=[
            Vector3(0.062,-0.174,0.074),
            Vector3(0.099,-0.139,0.115),
            Vector3(0.116,-0.032,0.127),
            Vector3(0.106,0.107,0.115),
            Vector3(0.066,0.174,0.078)]
    for name in profiles.keys():
        var z_shift: float=0.006 if name==V9.HELMET else 0.0
        if not _replace(model,str(name),
                _lathe(profiles[name],hero,z_shift)):
            return false

    # Spherical surfaces retain closed built-in topology, now with
    # independently budgeted radial tessellation instead of jagged 10-gons.
    for item in model.find_children("*","MeshInstance3D",true,false):
        var node: MeshInstance3D=item as MeshInstance3D
        if node.mesh is SphereMesh:
            var sphere: SphereMesh=node.mesh as SphereMesh
            sphere.radial_segments=24 if hero else 14
            sphere.rings=14 if hero else 8
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v13_hero",hero)
    return true
