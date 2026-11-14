extends SceneTree

# Headless import/entrypoint contract. Geometry rendering is separately
# exercised in the GPU-backed Web Studio and native terrain workflows.
const MainScreen = preload("res://scripts/ui/Main.gd")
const Home = preload("res://scripts/ui/HomeMenu.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const HQProduction = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Battle3D = preload("res://scripts/ui/Battle3DView.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main_scene: PackedScene = load("res://scenes/Main.tscn")
    var studio_scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(main_scene != null and studio_scene != null)
    assert(main_scene.get_state().get_node_count() > 0)
    assert(studio_scene.get_state().get_node_count() > 0)
    var menu: Control = Home.new()
    assert(menu.has_signal("studio_requested"))
    menu.free()
    assert(MainScreen != null and Studio != null)
    assert(Models.supports("tank") and Models.supports("scout"))
    assert(HQProduction.valid(1,0,"operativo",HQProduction.QUALITY_TACTICAL))
    assert(HQProduction.valid(3,7,"destruido",HQProduction.QUALITY_HERO))
    assert(Battle3D != null)
    assert(load("res://scripts/ui/Battle3DAssetLayer.gd") != null)
    var board_script: Script = load("res://scripts/ui/TouchBoard.gd")
    assert(board_script != null)
    var api := {}
    for item in board_script.get_script_method_list():
        api[str(item.get("name",""))] = true
    assert(api.has("set_3d_view"))
    assert(api.has("get_3d_performance_snapshot"))
    assert(api.has("set_3d_art_quality"))
    print("PASS combined art Android studio integration: scenes, 3D renderer, HQ/units, entry and native battle APIs")
    quit()
