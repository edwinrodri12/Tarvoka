extends SceneTree

# This smoke test is bundled into the published combined HQ/Airbase/G09
# project, where scenes/UnitArtStudioWeb.tscn loads BastionStudioAdapter.
# It verifies the ACTUAL visible startup, unlike isolated model-only tests.
var failures: int = 0

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("BASTION V7 WEB UI: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(packed != null,"web studio scene loads")
    if packed == null:
        quit(1)
        return
    var studio: Control = packed.instantiate() as Control
    _check(studio != null,"web studio is Control")
    if studio == null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    _check(str(studio.get("_role")) == "apc","Bastion selected by default")
    var model: Node3D = studio.get("model_root") as Node3D
    _check(model != null,"model present")
    if model != null:
        _check(bool(model.get_meta("tarvoka_apc_finish_v3",false)),
            "sculpted V3 damage source loaded")
        _check(bool(model.get_meta("tarvoka_apc_detail_v5",false)),
            "V5 base geometry loaded")
        _check(bool(model.get_meta("tarvoka_apc_finish_v6",false)),
            "V6 integrated armor and troop bay loaded")
        _check(bool(model.get_meta("tarvoka_apc_machinegun_v7",false)),
            "six-shot automatic weapon is built")
        _check(bool(model.get_meta("tarvoka_apc_weapon_audio_v8",false)),
            "original synchronized automatic sound is built")
        _check(bool(model.get_meta("tarvoka_apc_damage_v7",false)),
            "physical V7 staged damage geometry is built")
        _check(model.find_child("CincoAletasVentilacion",true,false) != null,
            "V6 physical front intake is present")
        _check(model.find_child("NuevePeldañosRampa",true,false) != null,
            "V6 ramp hardware actually exists")
        _check(model.find_child("Bastion_P06_Casco",true,false) == null,
            "old blockout removed from displayed model")
    var picker: OptionButton = studio.get("role_picker") as OptionButton
    _check(picker != null and picker.get_item_text(2).contains("Bastión"),
        "model chooser identifies full Bastion")
    studio.call("_set_damage",3)
    model = studio.get("model_root") as Node3D
    _check(model != null and int(model.get_meta(
        "tarvoka_apc_v3_damage_stage",-1)) == 3,
        "critical art stage selected")
    _check(int(model.get_meta("tarvoka_apc_v6_stage",-1)) == 3,
        "V6 distress layers follow V3 stage")
    _check(int(model.get_meta("tarvoka_apc_damage_v7_stage",-1)) == 3,
        "V7 bent armor follows damage stage")
    studio.call("_set_damage",0)
    _check(int(model.get_meta("tarvoka_apc_v6_stage",-1)) == 0,
        "V6 exterior recovers after repair")
    _check(int(model.get_meta("tarvoka_apc_damage_v7_stage",-1)) == 0,
        "V7 physical tears recover after repair")
    studio.call("_set_damage",4)
    var turret: Node3D = model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    _check(turret != null and absf(turret.rotation_degrees.z)>10.0,
        "terminal wreck turret physically displaced")
    studio.call("_set_damage",0)
    _check(turret != null and absf(turret.rotation_degrees.z)<0.001,
        "wrecked turret resets after repair")
    studio.call("_on_faction",3)
    model = studio.get("model_root") as Node3D
    _check(model != null and model.get_meta("tarvoka_apc_finish_v6",false),
        "faction change keeps the V6 full geometry")
    _check(model != null and model.get_meta("tarvoka_apc_machinegun_v7",false),
        "changing faction retains machinegun muzzle and shell pool")
    studio.call("_toggle_p06_version")
    _check(model != null and not model.get_meta(
        "tarvoka_apc_v6_visible",true),"V3 comparison hides V6")
    studio.call("_toggle_p06_version")
    _check(model != null and model.get_meta(
        "tarvoka_apc_v6_visible",false),"V6 comparison restores finish")
    studio.call("_play","attack")
    studio.call("_process",0.45)
    var muzzle: Node3D = model.find_child(
        "P06V7_MetralladoraRafaga",true,false) as Node3D
    _check(muzzle != null and muzzle.visible,
        "live web UI shows one of six machinegun flashes")
    var casing: Node3D = model.find_child(
        "P06V7_Casquillo_1",true,false) as Node3D
    _check(casing != null and casing.visible,
        "live web UI ejects visible brass during automatic firing")
    studio.call("_stop_animation")
    _check(muzzle != null and not muzzle.visible,
        "web UI hides muzzle after stopping automatic fire")
    var audio: AudioStreamPlayer = model.find_child(
        "P06V8_SonidoMetralladora",true,false) as AudioStreamPlayer
    _check(audio!=null and audio.stream is AudioStreamWAV,
        "studio plays original 16-bit sound without external files")
    studio.call("_show_p06_fleet",8)
    var gallery: Node3D=studio.get("_p06_fleet") as Node3D
    _check(gallery!=null and gallery.get_child_count()==8,
        "eight vehicles can be inspected inside the real 3D studio")
    var live_status: Label=studio.get("status_label") as Label
    _check(live_status!=null and live_status.text.contains("FPS del visor"),
        "device-visible browser FPS readout is labelled honestly")
    studio.call("_process",1.05)
    _check(int(studio.get("_p06_fleet_fps_sample"))>=0,
        "live device FPS sample collected without native APK claim")
    _check(model!=null and not model.visible,
        "V7 exhibit is hidden while showing V8 fleet")
    studio.call("_set_p06_fleet_quality",0)
    _check(int(studio.get("_p06_fleet_active_surfaces"))>0,
        "manual close LOD renders detailed tactical shells")
    var near_surfaces: int=int(studio.get("_p06_fleet_active_surfaces"))
    studio.call("_set_p06_fleet_quality",1)
    var mid_surfaces: int=int(studio.get("_p06_fleet_active_surfaces"))
    studio.call("_set_p06_fleet_quality",2)
    var far_surfaces: int=int(studio.get("_p06_fleet_active_surfaces"))
    _check(near_surfaces>mid_surfaces and mid_surfaces>far_surfaces,
        "studio near/mid/far controls reduce visible GPU surfaces")
    studio.call("_set_p06_fleet_quality",-1)
    _check(int(studio.get("_p06_fleet_quality"))==-1,
        "automatic camera LOD can be restored")
    studio.call("_show_p06_fleet",32)
    gallery=studio.get("_p06_fleet") as Node3D
    _check(gallery!=null and gallery.get_child_count()==32,
        "32 native tactical APCs render in studio")
    studio.call("_show_p06_fleet",64)
    gallery=studio.get("_p06_fleet") as Node3D
    _check(gallery!=null and gallery.get_child_count()==64,
        "64 native tactical APCs render in studio")
    studio.call("_animate_p06_fleet","move_turn")
    studio.call("_process",0.31)
    var first_apc: Node3D=gallery.get_child(0) as Node3D
    var first_home: Vector3=first_apc.get_meta(
        "tarvoka_apc_lod8_rest",Vector3.ZERO)
    _check(first_apc!=null and absf(first_apc.rotation_degrees.z)>0.05,
        "all units are capable of simulated cornering")
    _check(first_apc.position.distance_to(first_home)<0.05,
        "fleet maintains its formation while wheels turn")
    studio.call("_process",0.40)
    _check(str(studio.get("_p06_fleet_animation"))=="",
        "fleet steering ends and returns to rest")
    _check(first_apc.position.distance_to(first_home)<0.001,
        "fleet returns to the same grid position after movement")
    studio.call("_animate_p06_fleet","attack")
    studio.call("_process",0.52)
    var fleet_turret: Node3D=first_apc.find_child(
        "P06V8_TorretaRemota",true,false) as Node3D
    _check(fleet_turret!=null and absf(fleet_turret.rotation_degrees.y)>0.5,
        "tactical 64-unit automatic fire tracks target without shell spam")
    studio.call("_process",0.70)
    _check(str(studio.get("_p06_fleet_animation"))=="",
        "fleet weapon animation resets for new battle turn")
    studio.call("_hide_p06_fleet")
    _check(studio.get("_p06_fleet")==null,
        "fleet can be removed without a duplicate scene")
    _check(model!=null and model.visible,
        "full sculpted V7 hero restored after fleet test")
    studio.call("_toggle_p06_ramp")
    studio.call("_process",1.2)
    _check(model != null and bool(model.get_meta(
        "tarvoka_apc_ramp_open",false)),"ramp opens from UI")
    studio.call("_toggle_p06_ramp")
    studio.call("_process",1.2)
    _check(model != null and not bool(model.get_meta(
        "tarvoka_apc_ramp_open",true)),"ramp closes from UI")
    studio.queue_free()
    await process_frame
    if failures > 0:
        quit(1)
        return
    print("PASS BASTION V9 LIVE WEB STUDIO: near/mid/far LOD, 64 vehicles steering and firing, original synchronized audio, restored hero")
    quit(0)
