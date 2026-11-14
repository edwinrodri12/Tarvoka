extends SceneTree

# Real native 3D scene exported from the exact Android-oriented V13 runtime
# LOD, including the approved shield from TARVOKA's existing faction atlas.
const Production = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const TARGET := "res://artifacts/TARVOKA_CuartelGeneral_V13_Nivel3_Tactico_Optimizado.glb"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var source: Node3D = Production.build(3,0,"operativo",
        Production.QUALITY_TACTICAL,false)
    assert(source != null)
    var budget: Dictionary = Production.render_budget(source)
    assert(budget.get("within_tactical_budget",false))
    assert(int(budget.get("meshes",0))==2)
    assert(int(budget.get("surfaces",0))==10)
    root.add_child(source)
    var gltf := GLTFDocument.new()
    var state := GLTFState.new()
    var status: Error = gltf.append_from_scene(source,state,0)
    if status != OK:
        push_error("V13 tactical GLB scene serialization failed: %d" % status)
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    status = gltf.write_to_filesystem(state,ProjectSettings.globalize_path(TARGET))
    if status != OK:
        push_error("V13 tactical GLB file writing failed: %d" % status)
        quit(3)
        return
    var file := FileAccess.open(TARGET,FileAccess.READ)
    assert(file != null and file.get_length()>20000)
    var size: int = file.get_length()
    file.close()
    source.queue_free()
    print("PASS HQ V13 GLB export: 2 meshes, 10 material surfaces, 8 approved shield variants supported, %d bytes" % size)
    quit(0)
