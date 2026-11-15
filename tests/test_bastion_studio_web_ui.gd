extends SceneTree

# This smoke test is bundled into the published combined HQ/Airbase/G09
# project, where scenes/UnitArtStudioWeb.tscn loads BastionStudioAdapter.
# It verifies the ACTUAL visible startup, unlike isolated model-only tests.
var failures: int = 0

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("BASTION V5 WEB UI: " + message)

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
        _check(bool(model.get_meta("tarvoka_apc_detail_v5",false)) or
            model.find_child("P06V5_TapasTechoEnrasadas",true,false) != null,
            "V5 visible geometry loaded")
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
    studio.call("_set_damage",0)
    studio.call("_on_faction",3)
    model = studio.get("model_root") as Node3D
    _check(model != null and model.get_meta("tarvoka_apc_finish_v3",false),
        "faction change keeps full geometry")
    studio.call("_play","attack")
    studio.call("_process",0.45)
    studio.call("_stop_animation")
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
    print("PASS BASTION V5 LIVE WEB STUDIO: full startup, factions, damage, animation, boarding ramp")
    quit(0)
