extends RefCounted
class_name TarvokaG11RocketFlightV31

# V31 sculpted tactical rockets, soft evolving smoke. Visual-only resources:
# keeps V30's exact two pooled MultiMeshInstance3D batches (5+5 slots).
# All geometry faces +Z (the actual G11 launch-tube direction).
const FLAG := "tarvoka_g11_v31_sculpted_rocket"
const SEGMENTS: int=12
const ROCKET_LENGTH: float=0.44
const ROCKET_RADIUS: float=0.069
const SMOKE_FADE_TIME: float=0.39
const RECOIL_MAX_M: float=0.022
static var _rocket: ArrayMesh
static var _plume: SphereMesh

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3)->void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func rocket_mesh()->ArrayMesh:
    if _rocket!=null:
        return _rocket
    # Nose tapers to a clear point; the long main body and four rear fins
    # replace V30's spherical "fireball" without adding render instances.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var profile: Array[Vector2]=[
        Vector2(-0.195,0.040),
        Vector2(-0.175,ROCKET_RADIUS),
        Vector2(0.080,ROCKET_RADIUS),
        Vector2(0.154,0.046),
        Vector2(0.245,0.006)
    ]
    for ring in range(profile.size()-1):
        var a: Vector2=profile[ring]
        var b: Vector2=profile[ring+1]
        for radial in range(SEGMENTS):
            var t0: float=TAU*float(radial)/float(SEGMENTS)
            var t1: float=TAU*float(radial+1)/float(SEGMENTS)
            var v0:=Vector3(cos(t0)*a.y,sin(t0)*a.y,a.x)
            var v1:=Vector3(cos(t1)*a.y,sin(t1)*a.y,a.x)
            var v2:=Vector3(cos(t1)*b.y,sin(t1)*b.y,b.x)
            var v3:=Vector3(cos(t0)*b.y,sin(t0)*b.y,b.x)
            _tri(st,v0,v1,v2)
            _tri(st,v0,v2,v3)
    # Conical nose tip and actual closed tail to avoid floating open faces.
    for radial in range(SEGMENTS):
        var a: float=TAU*float(radial)/float(SEGMENTS)
        var b: float=TAU*float(radial+1)/float(SEGMENTS)
        _tri(st,Vector3.ZERO+Vector3(0,0,0.245),
            Vector3(cos(a)*0.006,sin(a)*0.006,0.245),
            Vector3(cos(b)*0.006,sin(b)*0.006,0.245))
        _tri(st,Vector3(0,0,-0.195),
            Vector3(cos(b)*0.040,sin(b)*0.040,-0.195),
            Vector3(cos(a)*0.040,sin(a)*0.040,-0.195))
    # Four thin triangular fins are part of the same mesh/draw batch.
    for n in range(4):
        var angle: float=float(n)*PI*0.5
        var outward:=Vector3(cos(angle),sin(angle),0)
        var tangential:=Vector3(-sin(angle),cos(angle),0)
        var tail:=outward*0.063+Vector3(0,0,-0.160)
        var tip:=outward*0.142+Vector3(0,0,-0.130)
        var forward:=outward*0.062+Vector3(0,0,-0.005)
        var offset:=tangential*0.006
        _tri(st,tail+offset,tip+offset,forward+offset)
        _tri(st,tail-offset,forward-offset,tip-offset)
        _tri(st,tail-offset,tail+offset,tip+offset)
        _tri(st,tail-offset,tip+offset,tip-offset)
    st.generate_normals()
    _rocket=st.commit()
    var finish:=StandardMaterial3D.new()
    finish.albedo_color=Color("#c0c9c5")
    finish.metallic=0.30
    finish.roughness=0.58
    finish.cull_mode=BaseMaterial3D.CULL_DISABLED
    _rocket.surface_set_material(0,finish)
    return _rocket

static func smoke_mesh()->SphereMesh:
    if _plume!=null:
        return _plume
    # No extra individual clouds: one scaled, transparent primitive per
    # active rocket, growing and fading along its already-approved path.
    _plume=SphereMesh.new()
    _plume.radius=0.16
    _plume.height=0.32
    _plume.radial_segments=9
    _plume.rings=4
    var mat:=StandardMaterial3D.new()
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
    mat.albedo_color=Color(0.72,0.75,0.72,1.0)
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    _plume.material=mat
    return _plume

static func smoke_color(age: float)->Color:
    var t: float=clampf(age/SMOKE_FADE_TIME,0.0,1.0)
    return Color(0.67,0.70,0.67,0.235*pow(1.0-t,1.4))

static func smoke_transform(muzzle: Vector3,travel: float,
        age: float,shot: int)->Transform3D:
    var t: float=clampf(age/SMOKE_FADE_TIME,0.0,1.0)
    var length: float=1.35+1.55*t
    var width: float=0.56+0.48*t
    var center: Vector3=muzzle+Vector3(
        0.030*sin(float(shot)*2.1)*t,
        0.18*t,
        maxf(0.13,travel-0.19-0.35*t))
    # Sphere's long axis Y is laid along rocket +Z, while the plume
    # subtly widens in XY and drifts upward as the exhaust dissipates.
    var aligned: Basis=Basis(Vector3.RIGHT,PI*0.5)
    return Transform3D(
        aligned.scaled(Vector3(width,length,width)),center)

static func recoil(relative_time: float,shot_step: float,
        total_shots: int)->float:
    if relative_time<0.0 or relative_time>=float(total_shots)*shot_step:
        return 0.0
    var phase: float=fposmod(relative_time,shot_step)/shot_step
    # Each pulse quickly pushes the rack back a couple of centimeters,
    # then smoothly returns it. Movement is strictly presentation-only.
    return RECOIL_MAX_M*(1.0-phase)*(1.0-phase)
