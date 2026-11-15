extends RefCounted
class_name TarvokaG11CooldownV10

# Original TARVOKA G11 art V10: independently cooling metal muzzle lips and
# small fading vapor wisps. Runs *after* the 12-rocket V8/V9 salvo, as a
# presentation-only timeline. Reusable/resettable and never changes unit data.
const FLAG := "tarvoka_g11_cooldown_v10"
const ELEVATION := "G11_ElevacionLanzador"
const COUNT := 12
const RING_PREFIX := "G11V10_AroCaliente_"
const VAPOR_PREFIX := "G11V10_VaporFinal_"
const LIP_Z := -0.778
const V8 = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
static var _ring_mesh: ArrayMesh
static var _vapor_mesh: ArrayMesh

static func _mat(heat: bool) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.vertex_color_use_as_albedo = true
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    if heat:
        m.metallic = 0.22
        m.roughness = 0.42
        m.emission_enabled = true
        m.emission = Color("#ac612b")
        m.emission_energy_multiplier = 0.30
    else:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
        ca: Color, cb: Color, cc: Color) -> void:
    st.set_color(ca)
    st.add_vertex(a)
    st.set_color(cb)
    st.add_vertex(b)
    st.set_color(cc)
    st.add_vertex(c)

static func _heat_ring() -> ArrayMesh:
    # True beveled annulus on the hot metallic tube rim; never a full opaque
    # disc that closes the actual V4 recessed bore.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n: int = 26
    var inner: float = 0.084
    var outer: float = 0.104
    var base := Color(1.0,0.39,0.13,0.57)
    var edge := Color(0.75,0.31,0.15,0.28)
    for i in range(n):
        var a: float = TAU*float(i)/float(n)
        var b: float = TAU*float(i+1)/float(n)
        var a0 := Vector3(cos(a)*inner,sin(a)*inner,0.005)
        var b0 := Vector3(cos(b)*inner,sin(b)*inner,0.005)
        var a1 := Vector3(cos(a)*outer,sin(a)*outer,-0.006)
        var b1 := Vector3(cos(b)*outer,sin(b)*outer,-0.006)
        _tri(st,a0,b0,b1,base,base,edge)
        _tri(st,a0,b1,a1,base,edge,edge)
    st.generate_normals()
    st.set_material(_mat(true))
    return st.commit()

static func _vapor_wisp() -> ArrayMesh:
    # An open, curved and tapered transparent 3D cone, not smoke spheres.
    # The mesh rises in +Y and moves towards -Z away from its nozzle.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bands: int = 7
    var sides: int = 9
    for j in range(bands):
        var t0: float = float(j)/float(bands)
        var t1: float = float(j+1)/float(bands)
        var r0: float = 0.018+0.034*t0
        var r1: float = 0.018+0.034*t1
        var c0 := Color("#9c9d91").lerp(Color("#d6d1c4"),t0)
        var c1 := Color("#9c9d91").lerp(Color("#d6d1c4"),t1)
        c0.a = 0.15*(1.0-t0)*minf(1.0,0.15+t0*8.0)
        c1.a = 0.15*(1.0-t1)*minf(1.0,0.15+t1*8.0)
        for i in range(sides):
            var a: float = TAU*float(i)/float(sides)
            var b: float = TAU*float(i+1)/float(sides)
            var p00 := Vector3(cos(a)*r0+0.016*sin(t0*4.6),
                t0*0.20,sin(a)*r0-t0*0.23)
            var p01 := Vector3(cos(b)*r0+0.016*sin(t0*4.6),
                t0*0.20,sin(b)*r0-t0*0.23)
            var p10 := Vector3(cos(a)*r1+0.016*sin(t1*4.6),
                t1*0.20,sin(a)*r1-t1*0.23)
            var p11 := Vector3(cos(b)*r1+0.016*sin(t1*4.6),
                t1*0.20,sin(b)*r1-t1*0.23)
            _tri(st,p00,p01,p11,c0,c0,c1)
            _tri(st,p00,p11,p10,c0,c1,c1)
    st.generate_normals()
    st.set_material(_mat(false))
    return st.commit()

static func _find(model: Node3D, label: String) -> MeshInstance3D:
    return model.find_child(label,true,false) as MeshInstance3D

static func _part(parent: Node3D, label: String, mesh: ArrayMesh) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.visible = false
    parent.add_child(part)
    return part

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_exhaust_v9",false)):
        return false
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if launcher == null:
        return false
    if _ring_mesh == null:
        _ring_mesh = _heat_ring()
        _vapor_mesh = _vapor_wisp()
    for i in range(COUNT):
        var slot := launcher.find_child("G11V8_Slot_%02d" % i,
            true,false) as Node3D
        if slot == null:
            return false
        var ring := _part(slot,RING_PREFIX+"%02d" % i,_ring_mesh)
        ring.position = Vector3(0,0,LIP_Z)
        var vapor := _part(slot,VAPOR_PREFIX+"%02d" % i,_vapor_mesh)
        vapor.position = Vector3(0,0,LIP_Z-0.03)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v10_heat_rings",COUNT)
    model.set_meta("tarvoka_g11_v10_cooling_wisps",COUNT)
    return reset(model)

static func reset(model: Node3D) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    for i in range(COUNT):
        var ring := _find(model,RING_PREFIX+"%02d" % i)
        var vapor := _find(model,VAPOR_PREFIX+"%02d" % i)
        if ring == null or vapor == null:
            return false
        ring.visible = false
        ring.transparency = 0.0
        ring.scale = Vector3.ONE
        vapor.visible = false
        vapor.transparency = 0.0
        vapor.position = Vector3(0,0,LIP_Z-0.03)
        vapor.scale = Vector3.ONE
    return true

static func pose_launch(model: Node3D, progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var t: float = clampf(progress,0.0,1.0)
    for sequence in range(COUNT):
        var tube: int = int(V8.SLOT_ORDER[sequence])
        var fired_at: float = V8.FIRST_SHOT+float(sequence)*V8.SHOT_INTERVAL
        var age: float = t-fired_at
        var ring := _find(model,RING_PREFIX+"%02d" % tube)
        var vapor := _find(model,VAPOR_PREFIX+"%02d" % tube)
        if ring == null or vapor == null:
            return false
        ring.visible = age >= 0.0
        if ring.visible:
            ring.transparency = clampf(age/0.60,0.0,0.78)
        vapor.visible = false # V9 controls rocket exhaust until salvo ends.
    return true

static func pose_cooldown(model: Node3D, progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var t: float = clampf(progress,0.0,1.0)
    # Smoothstep avoids visible popping at the end of a full barrage.
    var fade: float = t*t*(3.0-2.0*t)
    for sequence in range(COUNT):
        var tube: int = int(V8.SLOT_ORDER[sequence])
        var ring := _find(model,RING_PREFIX+"%02d" % tube)
        var vapor := _find(model,VAPOR_PREFIX+"%02d" % tube)
        if ring == null or vapor == null:
            return false
        # Early fired tubes have already cooled more than the last-fired ones.
        var late: float = float(sequence)/float(COUNT-1)
        var heat: float = (0.23+0.64*late)*(1.0-fade)
        ring.visible = heat > 0.015 and t < 1.0
        ring.transparency = 1.0-clampf(heat,0.0,0.90)
        var wisp: float = sin(PI*clampf(t*1.17,0.0,1.0))
        vapor.visible = t < 0.78 and (late > 0.30) and wisp > 0.01
        vapor.scale = Vector3(0.58+0.35*t,0.60+0.75*t,0.64+0.32*t)
        vapor.position = Vector3(
            0.010*sin(t*TAU+float(tube)),
            0.035*t,LIP_Z-0.03-0.17*t)
        vapor.transparency = clampf(0.18+0.84*t,0.0,1.0)
    return true

static func glowing_count(model: Node3D) -> int:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return 0
    var result: int = 0
    for i in range(COUNT):
        var ring := _find(model,RING_PREFIX+"%02d" % i)
        if ring != null and ring.visible:
            result += 1
    return result
