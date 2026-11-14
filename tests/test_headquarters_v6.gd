extends SceneTree

# Real Godot 4.3 GPU test: approved emblem atlases, shared mesh memory,
# 49 live instances and map-scale snapshot of the actual web viewer.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const MapLOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const Batches = preload("res://scripts/ui/HeadquartersCityBatch3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(ResourceLoader.exists("res://assets/factions/official_first_four_atlas.webp"))
    assert(ResourceLoader.exists("res://assets/factions/official_last_four_atlas.webp"))
    for faction in range(8):
        var tex: Texture2D = Emblems.emblem_texture(faction)
        assert(tex != null and tex.get_width() == 160 and tex.get_height() == 160)
        assert(Emblems.emblem_texture(faction) == tex)
        var hq: Node3D = HQ.build(1,faction,"operativo")
        assert(hq != null and hq.get_meta("tarvoka_hq_official_emblem",false))
        var emblem: MeshInstance3D = hq.find_child(
            "EscudoOficialFaccion3D",true,false) as MeshInstance3D
        assert(emblem != null and emblem.mesh is ArrayMesh)
        assert(emblem.get_meta("tarvoka_official_emblem_index") == faction)
        var material: StandardMaterial3D = emblem.material_override as StandardMaterial3D
        assert(material != null and material.albedo_texture == tex)
        assert(hq.find_child("EscudoDeFaccionModular",true,false) != null)
        hq.free()
    var ruins: Node3D = HQ.build(2,7,"destruido")
    assert(ruins.find_child("EscudoOficialFaccion3D",true,false) != null)
    ruins.free()

    var first: ArrayMesh = MapLOD.shared_mesh(1,0,"operativo")
    assert(first != null)
    for i in range(25):
        var mini: Node3D = MapLOD.build_map_only(1,0,"operativo")
        assert(mini != null and mini.get_child_count() == 1)
        assert(mini.get_meta("tarvoka_hq_map_only_v6",false))
        assert((mini.get_child(0) as MeshInstance3D).mesh == first)
        mini.free()
    var mixed: Node3D = MapLOD.build_map_only(3,6,"danado")
    assert(mixed != null)
    assert((mixed.get_child(0) as MeshInstance3D).mesh != first)
    mixed.free()
    assert(MapLOD.build_map_only(4,0,"operativo") == null)

    var grid: Node3D = Batches.build_grid(7,7,15.5)
    assert(grid != null)
    assert(grid.get_meta("tarvoka_studio_building_count") == 49)
    var batches: int = int(grid.get_meta("tarvoka_studio_batch_count",0))
    assert(batches > 4 and batches < 49)
    assert(grid.get_child_count() == batches)
    var sum_instances: int = 0
    for group in grid.get_children():
        assert(group is MultiMeshInstance3D)
        var multimesh: MultiMesh = (group as MultiMeshInstance3D).multimesh
        assert(multimesh != null and multimesh.mesh is ArrayMesh)
        assert(multimesh.mesh.get_surface_count() == 6)
        sum_instances += multimesh.instance_count
    assert(sum_instances == 49)
    grid.free()

    root.content_scale_size = Vector2i(1200,740)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = packed.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(7):
        await process_frame
    studio._switch_category(1)
    for i in range(8):
        await process_frame
    assert(studio.model_root.find_child("EscudoOficialFaccion3D",true,false) != null)
    var hero: Image = studio.preview.get_texture().get_image()
    assert(hero != null and not hero.is_empty())
    studio.hq_batch_toggle.set_pressed_no_signal(true)
    studio._change_building_batch(true)
    assert(studio.model_root.get_meta("tarvoka_studio_building_count") == 49)
    assert(studio.hq_fps_label.visible)
    assert(studio.camera.size > 100.0)
    for i in range(12):
        await process_frame
    var city: Image = studio.preview.get_texture().get_image()
    assert(city != null and not city.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(city.save_png("res://artifacts/tarvoka_hq_v6_49_buildings_map_scale.png") == OK)
    assert(hero.save_png("res://artifacts/tarvoka_hq_v6_official_shield.png") == OK)
    studio.hq_batch_toggle.set_pressed_no_signal(false)
    studio._change_building_batch(false)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v4",false))
    studio._switch_category(0)
    assert(studio._role == "tank" and studio.model_root != null)
    studio.queue_free()
    print("PASS HQ V6: eight official atlases, shared map memory, 49 batched buildings, GPU map-scale capture, tank isolation")
    quit(0)
