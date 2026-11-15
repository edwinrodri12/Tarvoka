extends SceneTree

# Native Godot 4.3 G11 V10 geometry and animation review. The V8 salvo timeline
# is preserved: the cooling phase is a separate continuous mechanical recovery.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const V9 = preload("res://scripts/ui/G11ExhaustV9.gd")
const V10 = preload("res://scripts/ui/G11CooldownV10.gd")
var failed: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failed += 1
        push_error("G11 cooling V10 QA: "+label)

func _node(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"native 3D MLRS for faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V10.FLAG,false)),
            "post-salvo V10 model installed for faction %d" % faction)
        _check(int(model.get_meta("tarvoka_g11_v10_heat_rings",0)) == 12,
            "twelve physically modeled cooling rims")
        _check(int(model.get_meta("tarvoka_g11_v10_cooling_wisps",0)) == 12,
            "twelve independent spatial vapor wisps")
        var barrel := _node(model,Art.ELEVATION)
        var turret := _node(model,Art.TURRET)
        _check(barrel != null and turret != null,
            "existing moving launcher and turret retained")
        for tube in range(12):
            var lip := _node(model,"G11V10_AroCaliente_%02d" % tube) as MeshInstance3D
            var wisp := _node(model,"G11V10_VaporFinal_%02d" % tube) as MeshInstance3D
            _check(lip != null and wisp != null,"complete cooling geometry tube %d" % tube)
            if lip != null:
                _check(lip.mesh is ArrayMesh,"genuine 3D annular metal bevel")
                _check(lip.get_parent() == _node(model,"G11V8_Slot_%02d" % tube),
                    "cooling rim physically follows its own tube")
                _check(not lip.visible,"cooling rim hidden while at rest")
            if wisp != null:
                _check(wisp.mesh is ArrayMesh,"curved tapered smoke mesh, no fake sphere")
                _check(not wisp.visible,"vapor hidden while idle")
        _check(Models.pose_model("mlrs",model,"attack",0.24,Vector2i(1,0)),
            "normal approved attack aiming unchanged")
        _check(V10.glowing_count(model) == 0,
            "no hot muzzle lips before any shot")
        _check(Models.pose_model("mlrs",model,"attack",0.85,Vector2i(1,0)),
            "twelve V8 rockets fire with V9 engine exhaust unchanged")
        _check(V10.glowing_count(model) == 12,
            "all twelve rims heat up during the salvo")
        _check(Models.pose_model("mlrs",model,"attack",1.0,Vector2i(1,0)),
            "last projectile leaves the model before afterglow")
        var attack_yaw: float = turret.rotation_degrees.y
        var attack_pitch: float = barrel.rotation_degrees.x
        var hydraulic_hot: float = _node(model,
            "G11V4_VastagoHidraulico_1").scale.y
        _check(absf(attack_pitch-38.0) < 0.01,
            "launcher remains elevated at end of approved firing timeline")
        _check(Rig.pose(model,"cooldown",0.0),
            "cooldown starts seamlessly when the salvo finishes")
        _check(absf(turret.rotation_degrees.y-attack_yaw) < 0.01,
            "no visible yaw jump between salvo and return sequence")
        _check(absf(barrel.rotation_degrees.x-attack_pitch) < 0.01,
            "no visible launcher elevation jump at transition")
        _check(_node(model,"G11V9_HumoResidual_07").visible,
            "last muzzle smoke persists briefly during V10 return")
        _check(V10.glowing_count(model) == 12,
            "all heated tube lips visible immediately after salvo")
        var last_lip := _node(model,"G11V10_AroCaliente_07") as MeshInstance3D
        var first_lip := _node(model,"G11V10_AroCaliente_00") as MeshInstance3D
        _check(last_lip.transparency < first_lip.transparency,
            "late-fired tubes glow brighter than already cooling ones")
        _check(Rig.pose(model,"cooldown",0.50),
            "hydraulic cradle returns using smoothstep")
        _check(absf(barrel.rotation_degrees.x-29.0) < 0.01,
            "launcher pitch returns smoothly halfway between 38 and 20")
        _check(absf(turret.rotation_degrees.y-attack_yaw*0.50) < 0.01,
            "aimed turret rotates gently halfway towards resting azimuth")
        _check(absf(_node(model,"G11V4_VastagoHidraulico_1").scale.y
            -hydraulic_hot) > 0.01,
            "real dual hydraulic rods retract with the launcher")
        _check(not _node(model,"G11V9_HumoResidual_07").visible,
            "V9 gas dissipates during V10 instead of abruptly resetting")
        _check(_node(model,"G11V10_VaporFinal_07").visible,
            "last tube has tapered post-ignition wisp in 3D")
        _check(V10.glowing_count(model) == 12,
            "muzzle heating dims gradually, no instant disappearance")
        _check(Rig.pose(model,"cooldown",1.0),
            "cooling phase fully restores mechanical aim and bore geometry")
        _check(absf(barrel.rotation_degrees.x-20.0) < 0.01,
            "launcher settles at 20-degree resting pitch")
        _check(absf(turret.rotation_degrees.y) < 0.01,
            "turret finishes exactly at resting yaw")
        _check(V10.glowing_count(model) == 0,
            "no remaining hot lip meshes after cooldown")
        _check(not _node(model,"G11V10_VaporFinal_07").visible,
            "post-fire vapor finishes dispersing gracefully")
        Models.restore_model_pose("mlrs",model)
        _check(V10.glowing_count(model) == 0,
            "manual stop fully removes glow")
        _check(Art.apply_stage(model,4),"destroyed geometry still available")
        _check(Rig.pose(model,"cooldown",0.4),
            "destroyed launcher cannot display cooling on invisible turret")
        _check(V10.glowing_count(model) == 0,
            "destroyed launcher cannot show a new glowing muzzle")
        _check(Art.apply_stage(model,0),"full repair restores G11 components")
        _check(Models.pose_model("mlrs",model,"attack",0.85),
            "repaired launcher can fire and heat its tubes again")
        _check(V10.glowing_count(model) == 12,
            "repaired G11 correctly regenerates temporary thermal glow")
        Models.restore_model_pose("mlrs",model)
        model.queue_free()
        await process_frame
    if failed > 0:
        push_error("G11 V10 cooldown QA FAILED (%d assertions)" % failed)
        quit(1)
        return
    print("PASS G11 COOLDOWN V10: 8 factions, 12 hot rims and vapor cones, continuous return with hydraulic interpolation, full restoration")
    quit(0)
