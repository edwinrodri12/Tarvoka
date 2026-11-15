extends RefCounted
class_name TarvokaG11SequentialSalvoV8

# V8 visual salvo for the G11 studio hero: 12 genuinely separate rockets
# exit 12 real hollow V4 tubes, each with its own flame, muzzle pressure ring,
# smoke and trailing exhaust. Independent of game ammo/combat rules.
const FLAG := "tarvoka_g11_salvo_v8"
const ELEVATION := "G11_ElevacionLanzador"
const ROCKET_COUNT := 12
const SLOT_ORDER := [0,5,10,3,8,1,6,11,4,9,2,7]
const FIRST_SHOT := 0.275
const SHOT_INTERVAL := 0.0515
const ROCKET_VISIBLE_FOR := 0.125
const MUZZLE_VISIBLE_FOR := 0.036
const SMOKE_VISIBLE_FOR := 0.115
const MUZZLE_Z := -0.764
const ROCKET_START_Z := -0.60
const ROCKET_TRAVEL := 2.58
const SLOT_PREFIX := "G11V8_Slot_"
const ROCKET_PREFIX := "G11V8_Cohete_"
const MUZZLE_PREFIX := "G11V8_Boca_"
const SMOKE_PREFIX := "G11V8_Humo_"
const _REST := "tarvoka_g11_salvo_v8_pose"

static var _body: CylinderMesh
static var _nose: CylinderMesh
static var _fin: BoxMesh
static var _ring: TorusMesh
static var _jet: CylinderMesh
static var _smoke: SphereMesh
static var _body_mat: StandardMaterial3D
static var _nose_mat: StandardMaterial3D
static var _fin_mat: StandardMaterial3D
static var _glow_mat: StandardMaterial3D
static var _jet_mat: StandardMaterial3D
static var _smoke_mat: StandardMaterial3D

static func _mat(c: Color, metal: float, rough: float,
        glowing: bool = false, translucent: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    if glowing:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 1.5
    if translucent:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    return m

static func _resources() -> void:
    if _body != null:
        return
    _body_mat = _mat(Color("#6a7778"),0.57,0.55)
    _nose_mat = _mat(Color("#c8bda4"),0.40,0.49)
    _fin_mat = _mat(Color("#303b3b"),0.43,0.72)
    _glow_mat = _mat(Color("#fff1ad"),0.0,0.23,true)
    _jet_mat = _mat(Color("#ff8c32"),0.0,0.28,true)
    _smoke_mat = _mat(Color(0.58,0.57,0.51,0.29),0.0,0.99,false,true)
    _body = CylinderMesh.new()
    _body.top_radius = 0.059
    _body.bottom_radius = 0.059
    _body.height = 0.30
    _body.radial_segments = 14
    _nose = CylinderMesh.new()
    _nose.top_radius = 0.0
    _nose.bottom_radius = 0.061
    _nose.height = 0.15
    _nose.radial_segments = 14
    _fin = BoxMesh.new()
    _fin.size = Vector3(0.091,0.022,0.088)
    _ring = TorusMesh.new()
    _ring.inner_radius = 0.072
    _ring.outer_radius = 0.145
    _ring.rings = 7
    _ring.ring_segments = 18
    _jet = CylinderMesh.new()
    _jet.top_radius = 0.057
    _jet.bottom_radius = 0.003
    _jet.height = 0.42
    _jet.radial_segments = 12
    _smoke = SphereMesh.new()
    _smoke.radius = 0.5
    _smoke.height = 1.0
    _smoke.radial_segments = 10
    _smoke.rings = 5

static func _part(parent: Node3D, label: String, mesh: Mesh,
        mat: Material, pos: Vector3,
        euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.material_override = mat
    node.position = pos
    node.rotation_degrees = euler
    parent.add_child(node)
    return node

static func _slot_position(id: int) -> Vector3:
    var col: int = id/3
    var row: int = id%3
    return Vector3(-0.42+float(col)*0.28,
        -0.24+float(row)*0.24,0)

static func _make_rocket(slot: Node3D, id: int) -> Node3D:
    var rocket := Node3D.new()
    rocket.name = ROCKET_PREFIX+"%02d" % id
    rocket.visible = false
    slot.add_child(rocket)
    # Cylinder long axis points toward -Z; the model is an actual moving
    # projectile, not a detached colored flare.
    _part(rocket,"G11V8_Cuerpo_%02d" % id,_body,
        _body_mat,Vector3.ZERO,Vector3(-90,0,0))
    _part(rocket,"G11V8_Ojiva_%02d" % id,_nose,
        _nose_mat,Vector3(0,0,-0.215),Vector3(-90,0,0))
    for j in range(4):
        var fin := _part(rocket,"G11V8_Aleta_%02d_%d" % [id,j],_fin,
            _fin_mat,Vector3(0,0,0.11))
        fin.rotation_degrees.z = float(j)*90.0
        fin.position.x = 0.047*cos(TAU*float(j)/4.0)
        fin.position.y = 0.047*sin(TAU*float(j)/4.0)
    var plume := _part(rocket,"G11V8_ChorroMotor_%02d" % id,
        _jet,_jet_mat,Vector3(0,0,0.305),Vector3(90,0,0))
    plume.set_meta("g11_v8_engine",true)
    return rocket

static func _make_muzzle(slot: Node3D, id: int) -> Node3D:
    var flash := Node3D.new()
    flash.name = MUZZLE_PREFIX+"%02d" % id
    flash.visible = false
    flash.position.z = MUZZLE_Z
    slot.add_child(flash)
    _part(flash,"G11V8_AnilloPresion_%02d" % id,
        _ring,_glow_mat,Vector3.ZERO,Vector3(90,0,0))
    # Four radiant pressure flashes are aligned around the selected tube.
    var streak := BoxMesh.new()
    streak.size = Vector3(0.022,0.21,0.030)
    for i in range(4):
        var angle := TAU*float(i)/4.0
        var spark := _part(flash,"G11V8_Destello_%02d_%d" % [id,i],
            streak,_jet_mat,Vector3(cos(angle)*0.12,sin(angle)*0.12,-0.024))
        spark.rotation_degrees.z = -rad_to_deg(angle)
    return flash

static func _make_smoke(slot: Node3D, id: int) -> Node3D:
    var puff := Node3D.new()
    puff.name = SMOKE_PREFIX+"%02d" % id
    puff.visible = false
    puff.position.z = MUZZLE_Z-0.07
    slot.add_child(puff)
    for i in range(3):
        var cloud := _part(puff,"G11V8_Presion_%02d_%d" % [id,i],
            _smoke,_smoke_mat,
            Vector3(cos(float(i)*2.09)*0.047,
                sin(float(i)*2.09)*0.054,-float(i)*0.06))
        cloud.scale = Vector3(0.13+float(i)*0.045,
            0.12+float(i)*0.025,0.18+float(i)*0.07)
    return puff

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_atmosphere_v7",false)):
        return false
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if launcher == null:
        return false
    _resources()
    for id in range(ROCKET_COUNT):
        var slot := Node3D.new()
        slot.name = SLOT_PREFIX+"%02d" % id
        slot.position = _slot_position(id)
        launcher.add_child(slot)
        _make_rocket(slot,id)
        _make_muzzle(slot,id)
        _make_smoke(slot,id)
    # Replace the old single spherical discharge; keep the named effect
    # layers for backwards compatibility with existing visual tests.
    for old in ["G11_Destello","G11_HumoSalva"]:
        var old_part := launcher.find_child(old,true,false) as Node3D
        if old_part != null:
            old_part.visible = false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v8_projectiles",ROCKET_COUNT)
    model.set_meta("tarvoka_g11_v8_separate_muzzles",ROCKET_COUNT)
    return reset(model)

static func reset(model: Node3D) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if launcher == null:
        return false
    for id in range(ROCKET_COUNT):
        var rocket := launcher.find_child(
            ROCKET_PREFIX+"%02d" % id,true,false) as Node3D
        var flash := launcher.find_child(
            MUZZLE_PREFIX+"%02d" % id,true,false) as Node3D
        var smoke := launcher.find_child(
            SMOKE_PREFIX+"%02d" % id,true,false) as Node3D
        if rocket == null or flash == null or smoke == null:
            return false
        rocket.visible = false
        rocket.position = Vector3(0,0,ROCKET_START_Z)
        rocket.scale = Vector3.ONE
        flash.visible = false
        flash.scale = Vector3.ONE
        smoke.visible = false
        smoke.scale = Vector3.ONE
        smoke.position.z = MUZZLE_Z-0.07
    model.set_meta(_REST,-1)
    return true

static func launched_count(progress: float) -> int:
    var t: float = clampf(progress,0.0,1.0)
    var count: int = 0
    for i in range(ROCKET_COUNT):
        if t >= FIRST_SHOT+float(i)*SHOT_INTERVAL:
            count += 1
    return count

static func pose(model: Node3D, progress: float) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if launcher == null:
        return false
    var t: float = clampf(progress,0.0,1.0)
    var active: int = 0
    for sequence in range(ROCKET_COUNT):
        var id: int = int(SLOT_ORDER[sequence])
        var rocket := launcher.find_child(
            ROCKET_PREFIX+"%02d" % id,true,false) as Node3D
        var flash := launcher.find_child(
            MUZZLE_PREFIX+"%02d" % id,true,false) as Node3D
        var smoke := launcher.find_child(
            SMOKE_PREFIX+"%02d" % id,true,false) as Node3D
        if rocket == null or flash == null or smoke == null:
            return false
        var elapsed: float = t-(FIRST_SHOT+float(sequence)*SHOT_INTERVAL)
        rocket.visible = elapsed >= 0.0 and elapsed < ROCKET_VISIBLE_FOR
        flash.visible = elapsed >= 0.0 and elapsed < MUZZLE_VISIBLE_FOR
        smoke.visible = elapsed >= 0.0 and elapsed < SMOKE_VISIBLE_FOR
        if rocket.visible:
            active += 1
            var flight: float = elapsed/ROCKET_VISIBLE_FOR
            rocket.position.z = ROCKET_START_Z-ROCKET_TRAVEL*(flight*flight)
            rocket.scale = Vector3.ONE*(1.0-0.12*flight)
            var jet := rocket.find_child(
                "G11V8_ChorroMotor_%02d" % id,true,false) as Node3D
            if jet != null:
                jet.scale = Vector3(1,1,0.72+0.35*sin(flight*TAU*3.0))
        if flash.visible:
            var pulse: float = 1.0-elapsed/MUZZLE_VISIBLE_FOR
            flash.scale = Vector3.ONE*(0.50+0.85*pulse)
        if smoke.visible:
            var haze: float = elapsed/SMOKE_VISIBLE_FOR
            smoke.position.z = MUZZLE_Z-0.07-0.37*haze
            smoke.scale = Vector3.ONE*(0.65+0.95*haze)
    model.set_meta(_REST,active)
    return true

static func active_projectiles(model: Node3D) -> int:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return 0
    var launcher := model.find_child(ELEVATION,true,false) as Node3D
    if launcher == null:
        return 0
    var found: int = 0
    for id in range(ROCKET_COUNT):
        var rocket := launcher.find_child(
            ROCKET_PREFIX+"%02d" % id,true,false) as Node3D
        if rocket != null and rocket.visible:
            found += 1
    return found
