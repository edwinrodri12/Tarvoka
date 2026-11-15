extends RefCounted
class_name TarvokaG11DamageAtmosphereV7

# Hero V7: real volumetric-looking tapered meshes, rather than solid spheres
# masquerading as fire and smoke. Fixes damage-layer occlusion from V6.
# Visual-only and fully reversible, no HP or unit rules changed.
const FLAG := "tarvoka_g11_atmosphere_v7"
const ROOT := "G11_CascoRaiz"
const TURRET := "G11_GiroPlataforma"
const MEDIUM := "G11_Dano2"
const CRITICAL := "G11_Dano3"
const WRECK := "G11_Dano4"
const FADE_NODES := [
    "G11_HumoMotor","G11_FuegoMotor","G11_HumoNegro",
    "G11_IncendioInterior","G11_HumoColumna"
]
const RIGHT_COVERS := [
    "G11V2_ProteccionLateral_1","G11V2_BandaFaccion_1",
    "G11_PanelLateral_1_0","G11_PanelLateral_1_1",
    "G11_PanelLateral_1_2","G11_PinturaLateral_1_0",
    "G11_PinturaLateral_1_1","G11_PinturaLateral_1_2",
    "G11V2_JuntaCostado_1_0","G11V2_JuntaCostado_1_1",
    "G11V2_JuntaCostado_1_2"
]
const LEFT_COVERS := [
    "G11V2_ProteccionLateral_-1","G11V2_BandaFaccion_-1",
    "G11_PanelLateral_-1_0","G11_PanelLateral_-1_1",
    "G11_PanelLateral_-1_2","G11_PinturaLateral_-1_0",
    "G11_PinturaLateral_-1_1","G11_PinturaLateral_-1_2",
    "G11V2_JuntaCostado_-1_0","G11V2_JuntaCostado_-1_1",
    "G11V2_JuntaCostado_-1_2"
]
const FIRE_PREFIX := "G11V7_Flama_"
const SMOKE_PREFIX := "G11V7_Penacho_"
const SMOKE_COUNT := 10
const FLAME_COUNT := 8

static func _material(fire: bool) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.vertex_color_use_as_albedo = true
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    if fire:
        m.emission_enabled = true
        m.emission = Color("#e96927")
        m.emission_energy_multiplier = 0.8
    return m

static func _vertex(st: SurfaceTool, p: Vector3, color: Color) -> void:
    st.set_color(color)
    st.add_vertex(p)

static func _triangle(st: SurfaceTool, a: Vector3, ca: Color,
        b: Vector3, cb: Color, c: Vector3, cc: Color) -> void:
    _vertex(st,a,ca)
    _vertex(st,b,cb)
    _vertex(st,c,cc)

static func _plume(fire: bool, height: float,
        width: float, seed: int) -> ArrayMesh:
    # A softly bent, tapered 3D surface with irregular lobes and graded alpha.
    # Each tongue is actual geometry, with zero spherical impostor meshes.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings: int = 8
    var sides: int = 9
    for j in range(rings):
        var t0: float = float(j)/float(rings)
        var t1: float = float(j+1)/float(rings)
        var h0: float = t0*height
        var h1: float = t1*height
        var r0: float = width*(0.30+0.70*sin(PI*(0.14+0.75*t0)))
        var r1: float = width*(0.30+0.70*sin(PI*(0.14+0.75*t1)))
        if fire:
            r0 *= pow(1.0-t0,0.58)
            r1 *= pow(1.0-t1,0.58)
        else:
            r0 *= 0.65+0.75*t0
            r1 *= 0.65+0.75*t1
        for i in range(sides):
            var a: float = TAU*float(i)/float(sides)
            var b: float = TAU*float(i+1)/float(sides)
            var wobble: float = float(seed)*0.64
            var bend0 := Vector2(sin(wobble+t0*5.4),cos(wobble+t0*4.2))*(0.14*t0)
            var bend1 := Vector2(sin(wobble+t1*5.4),cos(wobble+t1*4.2))*(0.14*t1)
            var p00 := Vector3(cos(a)*r0+bend0.x,h0,sin(a)*r0+bend0.y)
            var p01 := Vector3(cos(b)*r0+bend0.x,h0,sin(b)*r0+bend0.y)
            var p11 := Vector3(cos(b)*r1+bend1.x,h1,sin(b)*r1+bend1.y)
            var p10 := Vector3(cos(a)*r1+bend1.x,h1,sin(a)*r1+bend1.y)
            var c0: Color
            var c1: Color
            if fire:
                c0 = Color("#ffd17a").lerp(Color("#df4925"),t0)
                c1 = Color("#ffd17a").lerp(Color("#df4925"),t1)
                c0.a = 0.76*(1.0-t0*t0)
                c1.a = 0.76*(1.0-t1*t1)
            else:
                c0 = Color("#424a47").lerp(Color("#7c817a"),t0)
                c1 = Color("#424a47").lerp(Color("#7c817a"),t1)
                c0.a = 0.25*(1.0-t0)*minf(1.0,0.30+t0*5.0)
                c1.a = 0.25*(1.0-t1)*minf(1.0,0.30+t1*5.0)
            _triangle(st,p00,c0,p01,c0,p11,c1)
            _triangle(st,p00,c0,p11,c1,p10,c1)
    st.generate_normals()
    st.set_material(_material(fire))
    return st.commit()

static func _add_plume(parent: Node3D, name: String, flame: bool,
        height: float, width: float, pos: Vector3, seed: int) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.mesh = _plume(flame,height,width,seed)
    mesh.position = pos
    mesh.set_meta("g11_v7_rest",pos)
    parent.add_child(mesh)

static func _disable_original_damage_spheres(root: Node3D) -> void:
    for name in FADE_NODES:
        var sphere := root.find_child(name,true,false) as Node3D
        if sphere != null:
            sphere.visible = false

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_damage_v6",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    var medium := root.find_child(MEDIUM,true,false) as Node3D
    var severe := root.find_child(CRITICAL,true,false) as Node3D
    var destroyed := root.find_child(WRECK,true,false) as Node3D
    if medium == null or severe == null or destroyed == null:
        return false
    _disable_original_damage_spheres(root)
    # Medium: low wisps emerge FROM the crushed engine rather than floating
    # translucent balls centered above the vehicle.
    for i in range(2):
        _add_plume(medium,SMOKE_PREFIX+"medio_%d" % i,false,
            0.46+float(i)*0.13,0.13+float(i)*0.025,
            Vector3(-0.21+float(i)*0.35,1.15,1.00),i+1)
    # Critical: three individual tapered tongues with curved smoky columns.
    for i in range(3):
        _add_plume(severe,FIRE_PREFIX+"critico_%d" % i,true,
            0.49+float(i%2)*0.18,0.12+float(i)*0.015,
            Vector3(-0.35+float(i)*0.25,1.17,1.04),i+4)
        _add_plume(severe,SMOKE_PREFIX+"critico_%d" % i,false,
            1.12+float(i)*0.21,0.18+float(i%2)*0.045,
            Vector3(-0.28+float(i)*0.24,1.40,1.10),i+9)
    # Destroyed: fire is now inside an exposed wrecked turret ring.
    for i in range(5):
        _add_plume(destroyed,FIRE_PREFIX+"restos_%d" % i,true,
            0.66+0.12*float(i%3),0.17,
            Vector3(-0.46+float(i)*0.22,1.24,
                0.43+float(i%2)*0.29),i+13)
        _add_plume(destroyed,SMOKE_PREFIX+"restos_%d" % i,false,
            1.24+float(i%3)*0.26,0.24,
            Vector3(-0.46+float(i)*0.23,1.42,
                0.50+float(i%2)*0.27),i+20)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v7_smoke",SMOKE_COUNT)
    model.set_meta("tarvoka_g11_v7_flames",FLAME_COUNT)
    return set_stage(model,0)

static func set_stage(model: Node3D, damage: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    var level: int = clampi(damage,0,4)
    # V6's bent shields and exposed conduit bays were being hidden by old
    # overlapping paint panels. Temporarily remove the pristine covers.
    for label in RIGHT_COVERS:
        var right: Node3D = root.find_child(label,true,false) as Node3D
        if right != null:
            right.visible = level < 2
    for label in LEFT_COVERS:
        var left: Node3D = root.find_child(label,true,false) as Node3D
        if left != null:
            left.visible = level < 3
    # When fully destroyed, the old moving intact turret previously covered
    # the new exposed turret cavity. Hide the parent rig at level four only.
    var turret := root.find_child(TURRET,true,false) as Node3D
    if turret != null:
        turret.visible = level < 4
    _disable_original_damage_spheres(root)
    return true

static func animate(model: Node3D, kind: String, progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    var t: float = clampf(progress,0.0,1.0)
    var time: float = t*TAU*2.0
    var count: int = 0
    for layer_name in [MEDIUM,CRITICAL,WRECK]:
        var layer := root.find_child(layer_name,true,false) as Node3D
        if layer == null:
            return false
        for entry in layer.get_children():
            var part := entry as MeshInstance3D
            if part == null:
                continue
            var name: String = part.name
            if not name.begins_with(FIRE_PREFIX) and not name.begins_with(SMOKE_PREFIX):
                continue
            var seed: float = float(count)*1.67
            var smoke: bool = name.begins_with(SMOKE_PREFIX)
            var amount: float = 0.055 if smoke else 0.11
            var rest: Vector3 = part.get_meta("g11_v7_rest",part.position) as Vector3
            part.position = rest+Vector3(
                amount*sin(time+seed),0.018*sin(time*0.9+seed),
                amount*0.6*cos(time+seed))
            part.rotation_degrees = Vector3(0,
                9.0*sin(time*0.5+seed),4.0*sin(time+seed))
            part.scale = Vector3(1.0,1.0+0.13*sin(time+seed),1.0)
            count += 1
    return true
