extends RefCounted
class_name TarvokaG11ExhaustV9

# V9 hero-only procedural 3D rocket exhaust: no static particles, 2D cards or
# primitive spherical launch smoke. Keeps the twelve V8 fire times unchanged.
# All meshes are children of the real launcher and travel with its elevation.
const FLAG := "tarvoka_g11_exhaust_v9"
const V8 = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const COUNT := 12
const EXHAUST_LIFETIME := 0.132
const RESIDUAL_LIFETIME := 0.195
const _BORE := "G11_ElevacionLanzador"
const _REST := "tarvoka_g11_v9_active"
const _CORE := "G11V9_Nucleo_"
const _TRAIL := "G11V9_Estela_"
const _PRESSURE := "G11V9_GasesBoca_"
const _RESIDUAL := "G11V9_HumoResidual_"
const _FLASH := "G11V9_FlashEsculpido_"
static var _core_mesh: ArrayMesh
static var _trail_mesh: ArrayMesh
static var _smoke_mesh: ArrayMesh
static var _flash_mesh: ArrayMesh

static func _material(glowing: bool) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    if glowing:
        material.emission_enabled = true
        material.emission = Color("#ee9238")
        material.emission_energy_multiplier = 0.72
    return material

static func _vertex(st: SurfaceTool, point: Vector3, tint: Color) -> void:
    st.set_color(tint)
    st.add_vertex(point)

static func _triangle(st: SurfaceTool, a: Vector3, ca: Color,
        b: Vector3, cb: Color, c: Vector3, cc: Color) -> void:
    _vertex(st,a,ca)
    _vertex(st,b,cb)
    _vertex(st,c,cc)

static func _funnel(kind: int) -> ArrayMesh:
    # 3D curved cone with 8 axial bands; gradients taper into transparency.
    # Positive Z points backwards: the launcher and projectile fly towards -Z.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bands: int = 8
    var sides: int = 11
    for band in range(bands):
        var t0: float = float(band)/float(bands)
        var t1: float = float(band+1)/float(bands)
        for i in range(sides):
            var a: float = TAU*float(i)/float(sides)
            var b: float = TAU*float(i+1)/float(sides)
            var p00 := _profile(kind,t0,a)
            var p01 := _profile(kind,t0,b)
            var p10 := _profile(kind,t1,a)
            var p11 := _profile(kind,t1,b)
            var c0 := _color(kind,t0)
            var c1 := _color(kind,t1)
            _triangle(st,p00,c0,p01,c0,p11,c1)
            _triangle(st,p00,c0,p11,c1,p10,c1)
    st.generate_normals()
    st.set_material(_material(kind != 2))
    return st.commit()

static func _profile(kind: int, t: float, angle: float) -> Vector3:
    var r: float
    if kind == 0:
        r = 0.030+0.026*sin(t*PI)-0.023*t
    elif kind == 1:
        r = 0.045+0.060*t+0.007*sin(t*PI*3.0)
    else:
        r = 0.042+0.055*t+0.008*sin(t*PI*3.0)
    var curl: float = 0.045*t*t
    var bend := Vector2(sin(t*7.0)*curl,cos(t*6.0)*curl)
    return Vector3(r*cos(angle)+bend.x,r*sin(angle)+bend.y,t)

static func _color(kind: int, t: float) -> Color:
    var tint: Color
    if kind == 0:
        tint = Color("#fff4b4").lerp(Color("#e8752b"),t)
        tint.a = 0.93*(1.0-t*t)
    elif kind == 1:
        tint = Color("#efb36a").lerp(Color("#696b68"),t)
        tint.a = 0.33*pow(1.0-t,1.45)
    else:
        tint = Color("#6b6b65").lerp(Color("#9da39e"),t)
        tint.a = 0.13*pow(1.0-t,1.55)
    return tint

static func _muzzle_flash() -> ArrayMesh:
    # Compact heated gas cone in place of V8 square bars and hard torus.
    # Real 3D geometry, four tapering bands, softly graded alpha.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sides: int = 12
    var rings: int = 4
    for j in range(rings):
        var t0: float = float(j)/float(rings)
        var t1: float = float(j+1)/float(rings)
        var r0: float = 0.040+0.036*sin(t0*PI)-0.036*t0
        var r1: float = 0.040+0.036*sin(t1*PI)-0.036*t1
        var c0 := Color("#fff3c2").lerp(Color("#e4772e"),t0)
        var c1 := Color("#fff3c2").lerp(Color("#e4772e"),t1)
        c0.a = 0.78*(1.0-t0)
        c1.a = 0.78*(1.0-t1)
        for i in range(sides):
            var a: float = TAU*float(i)/float(sides)
            var b: float = TAU*float(i+1)/float(sides)
            var p00 := Vector3(r0*cos(a),r0*sin(a),-0.17*t0)
            var p01 := Vector3(r0*cos(b),r0*sin(b),-0.17*t0)
            var p10 := Vector3(r1*cos(a),r1*sin(a),-0.17*t1)
            var p11 := Vector3(r1*cos(b),r1*sin(b),-0.17*t1)
            _triangle(st,p00,c0,p01,c0,p11,c1)
            _triangle(st,p00,c0,p11,c1,p10,c1)
    st.generate_normals()
    st.set_material(_material(true))
    return st.commit()

static func _build_meshes() -> void:
    if _core_mesh != null:
        return
    _core_mesh = _funnel(0)
    _trail_mesh = _funnel(1)
    _smoke_mesh = _funnel(2)
    _flash_mesh = _muzzle_flash()

static func _add(parent: Node3D, name: String,
        geometry: ArrayMesh, pos: Vector3) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = geometry
    part.position = pos
    part.visible = false
    parent.add_child(part)
    return part

static func _parts(model: Node3D) -> Node3D:
    return model.find_child(_BORE,true,false) as Node3D

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta(V8.FLAG,false)):
        return false
    var launcher := _parts(model)
    if launcher == null:
        return false
    _build_meshes()
    for i in range(COUNT):
        var rocket := launcher.find_child("G11V8_Cohete_%02d" % i,
            true,false) as Node3D
        var slot := launcher.find_child("G11V8_Slot_%02d" % i,
            true,false) as Node3D
        var smoke := launcher.find_child("G11V8_Humo_%02d" % i,
            true,false) as Node3D
        if rocket == null or slot == null or smoke == null:
            return false
        var flash := launcher.find_child("G11V8_Boca_%02d" % i,
            true,false) as Node3D
        if flash == null:
            return false
        var sculpted_flash := _add(flash,_FLASH+"%02d" % i,
            _flash_mesh,Vector3.ZERO)
        sculpted_flash.visible = true
        # V8s thick orange rectangular halo dominated the mouth in actual
        # Godot screenshots; replace it with this short conical ignition.
        for j in range(4):
            var old_bar := flash.find_child(
                "G11V8_Destello_%02d_%d" % [i,j],true,false) as Node3D
            if old_bar != null:
                old_bar.visible = false
        var old_ring := flash.find_child("G11V8_AnilloPresion_%02d" % i,
            true,false) as Node3D
        if old_ring != null:
            old_ring.visible = false
        _add(rocket,_CORE+"%02d" % i,_core_mesh,Vector3(0,0,0.20))
        _add(rocket,_TRAIL+"%02d" % i,_trail_mesh,Vector3(0,0,0.22))
        _add(slot,_PRESSURE+"%02d" % i,_smoke_mesh,
            Vector3(0,0,V8.MUZZLE_Z-0.034))
        _add(slot,_RESIDUAL+"%02d" % i,_smoke_mesh,
            Vector3(0,0,V8.MUZZLE_Z-0.15))
        # The previous V8 spherical smoke and generic conical engine cone
        # cannot remain visible underneath the new volume geometry.
        var jet := rocket.find_child("G11V8_ChorroMotor_%02d" % i,
            true,false) as Node3D
        if jet != null:
            jet.visible = false
        for cloud_id in range(3):
            var legacy := smoke.find_child(
                "G11V8_Presion_%02d_%d" % [i,cloud_id],
                true,false) as Node3D
            if legacy != null:
                legacy.visible = false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v9_contrails",COUNT)
    model.set_meta("tarvoka_g11_v9_residual_smoke",COUNT)
    return reset(model)

static func reset(model: Node3D) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var launcher := _parts(model)
    if launcher == null:
        return false
    for i in range(COUNT):
        for prefix in [_CORE,_TRAIL,_PRESSURE,_RESIDUAL]:
            var part := launcher.find_child(prefix+"%02d" % i,
                true,false) as MeshInstance3D
            if part == null:
                return false
            part.visible = false
            part.scale = Vector3.ONE
            part.rotation_degrees = Vector3.ZERO
        var pressure := launcher.find_child(_PRESSURE+"%02d" % i,
            true,false) as MeshInstance3D
        var residual := launcher.find_child(_RESIDUAL+"%02d" % i,
            true,false) as MeshInstance3D
        pressure.position = Vector3(0,0,V8.MUZZLE_Z-0.034)
        residual.position = Vector3(0,0,V8.MUZZLE_Z-0.15)
    model.set_meta(_REST,0)
    return true

static func pose(model: Node3D, progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var launcher := _parts(model)
    if launcher == null:
        return false
    var t: float = clampf(progress,0.0,1.0)
    var wakes: int = 0
    for sequence in range(COUNT):
        var slot_id: int = int(V8.SLOT_ORDER[sequence])
        var elapsed: float = t-(V8.FIRST_SHOT
            +float(sequence)*V8.SHOT_INTERVAL)
        var core := launcher.find_child(_CORE+"%02d" % slot_id,
            true,false) as MeshInstance3D
        var tail := launcher.find_child(_TRAIL+"%02d" % slot_id,
            true,false) as MeshInstance3D
        var pressure := launcher.find_child(_PRESSURE+"%02d" % slot_id,
            true,false) as MeshInstance3D
        var residual := launcher.find_child(_RESIDUAL+"%02d" % slot_id,
            true,false) as MeshInstance3D
        if core == null or tail == null or pressure == null or residual == null:
            return false
        var in_flight: bool = elapsed >= 0.0 and elapsed < V8.ROCKET_VISIBLE_FOR
        var in_smoke: bool = elapsed >= 0.0 and elapsed < RESIDUAL_LIFETIME
        core.visible = in_flight
        tail.visible = in_flight
        pressure.visible = in_smoke
        residual.visible = in_smoke
        if in_flight:
            wakes += 1
            var flight: float = elapsed/V8.ROCKET_VISIBLE_FOR
            # Length increases smoothly with acceleration, no sudden popping.
            var wake_length: float = 0.11+1.20*(flight*flight*(3.0-2.0*flight))
            core.scale = Vector3(1.0,1.0,wake_length*0.78)
            tail.scale = Vector3(1.0+0.18*flight,
                1.0+0.18*flight,wake_length)
        if in_smoke:
            var age: float = elapsed/RESIDUAL_LIFETIME
            # Ignition produces a small pressure pulse; smoke then expands
            # and drifts after the projectile leaves the launcher.
            var pressure_age: float = minf(1.0,age*2.1)
            var spread: float = 0.36+0.72*pressure_age
            pressure.scale = Vector3(spread,spread,0.12+0.32*pressure_age)
            pressure.position = Vector3(0.028*sin(age*TAU+float(slot_id)),
                0.040*age,V8.MUZZLE_Z-0.034-0.27*pressure_age)
            residual.scale = Vector3(0.32+0.75*age,
                0.32+0.75*age,0.18+0.39*age)
            residual.position = Vector3(
                0.05*sin(age*TAU*0.8+float(slot_id)),
                0.055*age,V8.MUZZLE_Z-0.15-0.25*age)
            # Late smoke dwindles instead of remaining full strength.
            if age > 0.81:
                var tailoff: float = maxf(0.03,(1.0-age)/0.19)
                pressure.scale.x *= tailoff
                pressure.scale.y *= tailoff
                residual.scale.x *= tailoff
                residual.scale.y *= tailoff
    model.set_meta(_REST,wakes)
    return true
