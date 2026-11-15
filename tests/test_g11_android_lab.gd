extends SceneTree

# Validate that the isolated on-device touch lab is a real playable 3D scene,
# not just a documentation page or a synthetic benchmark.
var failures: int = 0

func _check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 ANDROID LAB: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/G11AndroidStressLab.tscn") as PackedScene
    _check(packed != null,"benchmark Godot scene imports")
    if packed == null:
        quit(1)
        return
    var lab: Node3D = packed.instantiate() as Node3D
    _check(lab != null,"lab instantiates")
    root.add_child(lab)
    await process_frame
    await process_frame
    var a: Array = lab.get("_models")
    _check(a.size() == 8,"8 real vehicles loaded at startup")
    _check(lab.find_child("G11RendimientoAndroidUI",true,false) != null,
        "touch control panel available")
    lab.call("set_scenario",32,8)
    await process_frame
    var b: Array = lab.get("_models")
    _check(b.size() == 32,"32 real vehicle scene built")
    _check(int(lab.get("_quality")) == 8,"far LOD selected")
    lab.call("set_scenario",64,10)
    await process_frame
    var c: Array = lab.get("_models")
    _check(c.size() == 64,"64 real vehicle scene built")
    _check(int(lab.get("_quality")) == 10,"close LOD selected")
    lab.call("save_report")
    _check(FileAccess.file_exists("user://g11_android_performance.json"),
        "report stored in device user data")
    if failures > 0:
        push_error("G11 Android lab scene failed %d checks" % failures)
        quit(1)
        return
    print("PASS G11 ANDROID LAB: Godot scene, touch UI, 8/32/64 units, near/far controls and JSON export")
    quit(0)
