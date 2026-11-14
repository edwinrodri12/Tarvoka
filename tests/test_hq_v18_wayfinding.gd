extends SceneTree

# Native Godot V18 art QA: real batched meshes, faction color, visibility
# at each lighting preset and preservation of Android's V13/V15 budgets.
const Wayfinding = preload("res://scripts/ui/HeadquartersWayfindingV18.gd")
const Production = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int = 7) -> void:
    for _i in range(n):
        await process_frame

func _shot(name: String) -> void:
    var img: Image = root.get_texture().get_image()
    assert(img != null and img.get_width() >= 900 and img.get_height() >= 540)
    assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts")) == OK)
    assert(img.save_png("res://artifacts/" + name) == OK)

func _run() -> void:
    var standalone: Node3D = Wayfinding.build()
    assert(standalone.get_meta("tarvoka_visual_only",false))
    assert(Wayfinding.instances(standalone)==Wayfinding.INSTANCE_TOTAL)
    assert(Wayfinding.INSTANCE_TOTAL==14)
    assert(Wayfinding.batches(standalone)==0)
    assert(Wayfinding.apply(standalone,0,2,"operativo",2,"clear"))
    assert(Wayfinding.batches(standalone)==Wayfinding.MAX_DRAW_BATCHES)
    assert(Wayfinding.batches(standalone)==3)
    var original: Array = []
    for child in standalone.get_children():
        assert(child is MultiMeshInstance3D)
        original.append((child as MultiMeshInstance3D).multimesh)
        assert((child as MultiMeshInstance3D).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
    assert(Wayfinding.apply(standalone,1,3,"capturado",2,"rain"))
    assert(standalone.get_meta("tarvoka_hq_v18_faction",-1)==1)
    assert(standalone.get_meta("tarvoka_hq_v18_weather_visual","")=="rain")
    assert(Wayfinding.instances(standalone)==14)
    for i in range(3):
        assert((standalone.get_child(i) as MultiMeshInstance3D).multimesh==original[i])
    assert(Wayfinding.apply(standalone,7,1,"danado",1,"snow"))
    assert(Wayfinding.batches(standalone)==3)
    assert(Wayfinding.apply(standalone,7,1,"destruido",2,"rain"))
    assert(Wayfinding.batches(standalone)==0)
    assert(Wayfinding.apply(standalone,0,2,"operativo",2,"rain",true,true))
    assert(Wayfinding.batches(standalone)==0)
    assert(Wayfinding.apply(standalone,0,2,"operativo",0,"rain"))
    assert(Wayfinding.batches(standalone)==0)
    assert(not Wayfinding.apply(standalone,8,2,"operativo",2,"clear"))
    assert(not Wayfinding.apply(standalone,0,4,"operativo",2,"clear"))
    assert(not Wayfinding.apply(standalone,0,2,"operativo",2,"storm"))
    standalone.free()

    root.content_scale_size = Vector2i(1200,740)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    await _frames()
    studio._switch_category(1)
    await _frames()
    assert(studio.hq_wayfinding_toggle != null)
    assert(studio.hq_wayfinding_toggle.button_pressed)
    var stage: Node3D = studio.model_root.get_node_or_null(Wayfinding.STAGE_NAME)
    assert(stage != null and Wayfinding.instances(stage)==14)
    assert(Wayfinding.batches(stage)==0)
    studio._change_hq_lighting(2)
    await _frames()
    assert(Wayfinding.batches(stage)==3)
    _shot("tarvoka_hq_v18_night_wayfinding_3d.png")
    studio._change_hq_weather_v17(1)
    await _frames()
    assert(stage.get_meta("tarvoka_hq_v18_weather_visual")=="rain")
    assert(Wayfinding.batches(stage)==3)
    _shot("tarvoka_hq_v18_rain_night_faction_glow.png")
    studio._change_hq_lighting(1)
    await _frames()
    assert(Wayfinding.batches(stage)==3)
    _shot("tarvoka_hq_v18_dusk_3d.png")
    studio.hq_wayfinding_toggle.button_pressed = false
    assert(Wayfinding.batches(stage)==0)
    studio.hq_wayfinding_toggle.button_pressed = true
    assert(Wayfinding.batches(stage)==3)
    studio._set_hq_map_lod(true)
    assert(Wayfinding.batches(stage)==0)
    studio._set_hq_map_lod(false)
    assert(Wayfinding.batches(stage)==3)
    studio._change_hq_v15_mode(2)
    await _frames()
    assert(studio.model_root.get_node_or_null(Wayfinding.STAGE_NAME)==null)
    studio._change_hq_v15_mode(0)
    await _frames()
    assert(studio.model_root.get_node_or_null(Wayfinding.STAGE_NAME)!=null)
    studio.hq_production_toggle.button_pressed = true
    await _frames()
    assert(studio.model_root.get_node_or_null(Wayfinding.STAGE_NAME)==null)
    var budget: Dictionary = Production.render_budget(studio.model_root)
    assert(budget.get("within_tactical_budget",false))
    assert(int(budget.get("meshes",-1))<=Production.MESH_BUDGET)
    studio.queue_free()
    await _frames(3)
    print("PASS HQ V18: 14 instancias / 3 lotes, 8 facciones, clima, noche, LOD, sprite V15 y V13 intactos")
    quit(0)
