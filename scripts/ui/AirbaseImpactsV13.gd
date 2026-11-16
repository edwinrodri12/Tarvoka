extends Node3D
class_name TarvokaAirbaseImpactsV13

# Surface-aware, event-driven Godot 4.3 impact art. Visual only.
# Three distinct attack classes: bullet / missile / bombardment.
# Three physical targets: gate steel / control-tower concrete / intact roof.
# Static pools: 2 MultiMeshes, 3 flashes, 3 rings, 3 smoke volumes,
# 3 approach streaks and 3 surface marks. No OmniLights or new particles.
const V1 = preload("res://scripts/ui/Airbase3DV1.gd")
const V10 = preload("res://scripts/ui/AirbaseStructureV10.gd")
const SOFT_SMOKE = preload("res://assets/shaders/airbase_soft_smoke_v4.gdshader")
const STAGE_NAME := "ImpactosBalasMisilesBombardeosSuperficiesV13"
const KINDS := ["bullet","missile","bombardment"]
const TARGETS := ["gate_metal","tower_concrete","hangar_roof"]
const SPARK_COUNT := 12
const CHIP_COUNT := 15
const BLASTS := 3
const BULLET_DURATION := 0.65
const MISSILE_DURATION := 1.65
const BOMBARD_DURATION := 2.40

var damage_stage: int = 0
var _sparks: MultiMeshInstance3D
var _chips: MultiMeshInstance3D
var _smoke_material: ShaderMaterial
var _flashes: Array[MeshInstance3D] = []
var _waves: Array[MeshInstance3D] = []
var _smokes: Array[MeshInstance3D] = []
var _streaks: Array[MeshInstance3D] = []
var _marks: Array[MeshInstance3D] = []
var _kind := ""
var _target := ""
var _impact := Vector3.ZERO
var _elapsed := 0.0
var _duration := 0.0
var _running := false
var _event_count := 0

static func valid_attack(kind: String, surface: String, stage: int) -> bool:
    if kind not in KINDS or surface not in TARGETS or stage<0 or stage>3:
        return false
    # Stage 3 preserves the shaft but not the control cab: hit its shaft.
    return true

static func surface_position(surface: String) -> Vector3:
    match surface:
        "gate_metal":
            # Left-hand surviving gate panel: V1 stage 3 omits the
            # two center sections, so no impact may float in that gap.
            return Vector3(V1.HANGAR_CENTER_X-2.28,1.60,-4.12)
        "tower_concrete":
            # Aim between the concrete-shaft's metal mullions (local
            # x=-0.49,0,+0.49) rather than directly at the center rail.
            # The V1 concrete face is z=-2.86 world, not z=-2.95.
            return Vector3(3.92,1.91,-2.864)
        "hangar_roof":
            # This is section 12, intact even at stage 3. Avoid
            # placing a surface response over a removed roof panel.
            return Vector3(V1.HANGAR_CENTER_X+2.80,
                V10._roof_y(2.80)+0.052,-1.80)
    return Vector3.ZERO

static func _tone(surface: String) -> Color:
    match surface:
        "gate_metal":
            return Color("#edc17c")
        "tower_concrete":
            return Color("#c0ced1")
        "hangar_roof":
            return Color("#b7c9d1")
    return Color.WHITE

static func _material(color: Color, glow: float=0.0,
        alpha: bool=false) -> StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=0.76
    material.metallic=0.17
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    if glow>0.0:
        material.emission_enabled=true
        material.emission=color
        material.emission_energy_multiplier=glow
    if alpha:
        material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

static func _batch(label: String,count: int,tint: Color,
        glow: float=0.0) -> MultiMeshInstance3D:
    var node:=MultiMeshInstance3D.new()
    node.name=label
    var cube:=BoxMesh.new()
    cube.size=Vector3.ONE
    var mesh:=MultiMesh.new()
    mesh.transform_format=MultiMesh.TRANSFORM_3D
    mesh.use_colors=true
    mesh.mesh=cube
    mesh.instance_count=count
    for index in range(count):
        mesh.set_instance_transform(index,Transform3D(
            Basis().scaled(Vector3(0.001,0.001,0.001)),Vector3.ZERO))
        mesh.set_instance_color(index,Color.WHITE)
    node.multimesh=mesh
    node.material_override=_material(tint,glow)
    node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.visible=false
    return node

static func _mesh_instance(label: String,shape: Mesh,
        mat: Material) -> MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.material_override=mat
    node.visible=false
    node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return node

func _ready() -> void:
    name=STAGE_NAME
    set_meta("tarvoka_visual_only",true)
    _sparks=_batch("ChispasPorMaterialUnLoteV13",
        SPARK_COUNT,Color("#ffe2aa"),1.8)
    _chips=_batch("DesconchonesSuperficieUnLoteV13",
        CHIP_COUNT,Color.WHITE)
    add_child(_sparks)
    add_child(_chips)
    var flash_mesh:=SphereMesh.new()
    flash_mesh.radius=0.34
    flash_mesh.height=0.68
    flash_mesh.radial_segments=11
    flash_mesh.rings=6
    var ring_mesh:=TorusMesh.new()
    ring_mesh.inner_radius=0.69
    ring_mesh.outer_radius=0.755
    ring_mesh.rings=10
    ring_mesh.ring_segments=14
    var smoke_mesh:=SphereMesh.new()
    smoke_mesh.radius=0.42
    smoke_mesh.height=0.84
    smoke_mesh.radial_segments=12
    smoke_mesh.rings=7
    _smoke_material=ShaderMaterial.new()
    _smoke_material.shader=SOFT_SMOKE
    _smoke_material.set_shader_parameter("smoke_tint",
        Color(0.27,0.31,0.34,0.47))
    _smoke_material.set_shader_parameter("drift_speed",0.17)
    _smoke_material.set_shader_parameter("edge_breakup",1.35)
    var streak_mesh:=CylinderMesh.new()
    streak_mesh.height=1.25
    streak_mesh.top_radius=0.025
    streak_mesh.bottom_radius=0.06
    streak_mesh.radial_segments=7
    var scar_mesh:=SphereMesh.new()
    scar_mesh.radius=0.22
    scar_mesh.height=0.44
    scar_mesh.radial_segments=10
    scar_mesh.rings=5
    for index in range(BLASTS):
        var flash:=_mesh_instance("DestelloVolumetricoV13_%d" % index,
            flash_mesh,_material(Color(1.0,0.70,0.37,0.78),2.3,true))
        add_child(flash)
        _flashes.append(flash)
        var ring:=_mesh_instance("OndaPresionV13_%d" % index,
            ring_mesh,_material(Color(0.81,0.82,0.83,0.43),0.40,true))
        add_child(ring)
        _waves.append(ring)
        var smoke:=_mesh_instance("PolvoYHumoV13_%d" % index,
            smoke_mesh,_smoke_material)
        add_child(smoke)
        _smokes.append(smoke)
        var streak:=_mesh_instance("EstelaMisilV13_%d" % index,
            streak_mesh,_material(Color("#ffc87d"),1.9,true))
        streak.rotation_degrees=Vector3(68,0,12)
        add_child(streak)
        _streaks.append(streak)
        var mark:=_mesh_instance("MarcaTemporalSuperficieV13_%d" % index,
            scar_mesh,_material(Color(0.21,0.20,0.18,0.50),0.0,true))
        mark.scale=Vector3(0.80,0.06,0.80)
        add_child(mark)
        _marks.append(mark)
    set_process(false)

func _hide_all() -> void:
    _sparks.visible=false
    _chips.visible=false
    for objects in [_flashes,_waves,_smokes,_streaks,_marks]:
        for item in objects:
            item.visible=false

func stop() -> void:
    _running=false
    _kind=""
    set_process(false)
    _hide_all()

func is_running() -> bool:
    return _running

func last_kind() -> String:
    return _kind

func last_surface() -> String:
    return _target

func event_count() -> int:
    return _event_count

func active_visual_batches() -> int:
    if not _running:
        return 0
    var count:=0
    for node in [_sparks,_chips]:
        if node.visible:
            count+=1
    for objects in [_flashes,_waves,_smokes,_streaks,_marks]:
        for obj in objects:
            if obj.visible:
                count+=1
    return count

func trigger(kind: String,surface: String) -> bool:
    if not valid_attack(kind,surface,damage_stage):
        return false
    _hide_all()
    _kind=kind
    _target=surface
    _impact=surface_position(surface)
    var smoke_tint: Color=Color(0.25,0.28,0.30,0.50)
    if surface=="tower_concrete":
        smoke_tint=Color(0.49,0.49,0.46,0.51)
    elif surface=="hangar_roof":
        smoke_tint=Color(0.31,0.34,0.37,0.47)
    _smoke_material.set_shader_parameter("smoke_tint",smoke_tint)
    _duration=BULLET_DURATION if kind=="bullet" else (
        MISSILE_DURATION if kind=="missile" else BOMBARD_DURATION)
    _elapsed=0.0
    _running=true
    _event_count+=1
    set_process(true)
    _render(0.005)
    return true

func _process(delta: float) -> void:
    if not _running:
        return
    _elapsed+=maxf(delta,0.0)
    if _elapsed>=_duration:
        stop()
        return
    _render(_elapsed)

func _hit(index: int) -> Vector3:
    if _kind!="bombardment":
        return _impact
    # Three separately timed strikes within the selected real facade.
    var drift: float=float(index-1)
    match _target:
        "gate_metal":
            return _impact+Vector3(drift*0.77,0.09*float(index%2),0)
        "tower_concrete":
            return _impact+Vector3(drift*0.30,0.47*float(index%2),0)
        "hangar_roof":
            var x: float=2.80+drift*0.32
            return Vector3(V1.HANGAR_CENTER_X+x,
                V10._roof_y(x)+0.052,-1.80)
    return _impact

func _set_scatter(batch: MultiMeshInstance3D,
        count: int,time: float,at: Vector3,
        radius: float,gravity: float) -> void:
    var tone: Color=_tone(_target)
    for i in range(count):
        var angle: float=TAU*float(i)/float(count)
        var reach: float=radius*(0.68+float(i%4)*0.12)
        var t: float=minf(time,1.3)
        var tangent:=Vector3(cos(angle),sin(angle),0.0)
        if _target=="hangar_roof":
            tangent=Vector3(cos(angle),0.1,sin(angle))
        var place:=at+tangent*reach*t+Vector3(
            0,0.35*t-gravity*t*t,-0.11*t)
        var fade: float=maxf(0.10,1.0-t/maxf(_duration,0.1))
        var size:=Vector3(0.047,0.065,0.045)*fade
        batch.multimesh.set_instance_transform(i,
            Transform3D(Basis(Vector3.UP,t*(1.0+float(i%5))).scaled(size),
                place))
        batch.multimesh.set_instance_color(i,tone)
    batch.visible=true

func _render(time: float) -> void:
    _hide_all()
    if _kind=="bullet":
        # Fast narrow flashes against steel; chalk spall against concrete;
        # scraping and short ricochet against corrugated roof sheet.
        var pct: float=clampf(time/BULLET_DURATION,0.0,1.0)
        _set_scatter(_sparks,SPARK_COUNT,pct,
            _hit(0),0.64 if _target=="gate_metal" else 0.45,0.20)
        if _target=="tower_concrete":
            _set_scatter(_chips,CHIP_COUNT,pct,
                _hit(0),0.25,0.65)
        var scar: MeshInstance3D=_marks[0]
        scar.visible=time<0.54
        scar.position=_hit(0)
        scar.scale=Vector3(0.39,0.035,0.39)
        scar.rotation_degrees=Vector3(
            90,0,0) if _target!="hangar_roof" else Vector3.ZERO
        scar.transparency=clampf(0.2+pct*0.65,0,1)
        return

    var blasts: int=1 if _kind=="missile" else BLASTS
    var delay: float=0.0 if _kind=="missile" else 0.34
    for index in range(blasts):
        var local: float=time-float(index)*delay
        if local<0.0:
            continue
        var target: Vector3=_hit(index)
        var streak: MeshInstance3D=_streaks[index]
        streak.visible=local<0.23
        if streak.visible:
            streak.position=target+Vector3(
                -0.25,1.48*(1.0-local/0.23),-0.82*(1.0-local/0.23))
            streak.transparency=clampf(local/0.23,0.0,0.9)
        var after: float=local-0.20
        if after<0:
            continue
        var blast_time: float=0.20 if _kind=="missile" else 0.25
        var flash: MeshInstance3D=_flashes[index]
        var strength: float=clampf(1.0-after/blast_time,0.0,1.0)
        flash.visible=strength>0.025
        flash.position=target+Vector3(0,0.09,0)
        flash.scale=Vector3.ONE*(0.42+1.45*(1.0-strength))
        flash.transparency=1.0-strength
        var ring: MeshInstance3D=_waves[index]
        var wave: float=clampf(after/0.56,0.0,1.0)
        ring.visible=wave<0.97
        ring.position=target
        ring.rotation_degrees=Vector3(
            90,0,0) if _target!="hangar_roof" else Vector3.ZERO
        ring.scale=Vector3.ONE*(0.20+2.12*wave)
        ring.transparency=wave
        var smoke: MeshInstance3D=_smokes[index]
        smoke.visible=after<1.12
        smoke.position=target+Vector3(0,0.14+after*0.73,0)
        smoke.scale=Vector3.ONE*(0.23+after*1.22)
        smoke.transparency=clampf(0.15+after*0.71,0.0,1.0)
        var mark: MeshInstance3D=_marks[index]
        mark.visible=after<1.23
        mark.position=target
        mark.scale=Vector3(0.95,0.06,0.95)
        mark.rotation_degrees=Vector3(
            90,0,0) if _target!="hangar_roof" else Vector3.ZERO
        mark.transparency=clampf(0.16+after*0.65,0.0,1.0)

    # A missile is one directed strike; bombardment distributes a second
    # chip stream among all three staggered impacts.
    var after_first: float=time-0.20
    if after_first>=0.0 and after_first<1.33:
        var spread: float=1.15 if _kind=="missile" else 1.48
        _set_scatter(_chips,CHIP_COUNT,after_first,_hit(
            0 if _kind=="missile" else 1),spread,1.65)
        _set_scatter(_sparks,SPARK_COUNT,after_first,_hit(0),
            0.95,0.55)
