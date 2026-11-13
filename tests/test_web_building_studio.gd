extends SceneTree

# Executes the exact scene that is packaged for browser deployment.
const Combined = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1280,800)
    var web_scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(web_scene != null)
    var studio: Control = web_scene.instantiate()
    assert(studio.get_script() == Combined)
    root.add_child(studio)
    for frame in range(5):
        await process_frame
    assert(studio.model_root != null)
    assert(studio._role == "tank")
    assert(studio.category_picker.item_count == 2)
    assert(not studio.building_controls.visible)

    studio._switch_category(1)
    for frame in range(5):
        await process_frame
    assert(studio.category_picker.selected == 1)
    assert(studio._role == "headquarters")
    assert(studio.building_controls.visible)
    assert(not studio.role_picker.visible)
    assert(studio.faction_picker.visible)
    assert(studio.model_root.get_meta("tarvoka_building_kind") == "headquarters")
    assert(Headquarters.paintable_count(studio.model_root) >= 8)
    assert(studio.model_root.find_child("Helipuerto",true,false) != null)
    assert(studio.model_root.find_child("RadarParabolico",true,false) != null)
    var base_zoom: float = studio.camera.size
    assert(base_zoom > 14.0)
    studio._change_zoom(1)
    assert(studio.camera.size < base_zoom)
    var yaw_before: float = studio.model_root.rotation_degrees.y
    studio._rotate(45.0)
    assert(not is_equal_approx(yaw_before,studio.model_root.rotation_degrees.y))

    # Read what the user actually sees in the shared WebGL viewport.
    var base_image: Image = studio.preview.get_texture().get_image()
    assert(base_image != null and not base_image.is_empty())
    studio.level_picker.select(3-1)
    studio._change_building_variant(2)
    assert(int(studio.model_root.get_meta("visual_level")) == 3)
    assert(studio.model_root.find_child("RadomoSuperior",true,false) != null)

    studio._on_faction(2)
    studio._refresh_building_faction(2)
    assert(int(studio.model_root.get_meta("visual_faction")) == 2)
    var paint: MeshInstance3D = studio.model_root.find_child("FranjaFaccionSuperior",true,false) as MeshInstance3D
    assert(paint != null)
    assert((paint.material_override as StandardMaterial3D).albedo_color == Style.faction_color(2))

    studio.building_state_picker.select(2)
    studio._change_building_variant(2)
    assert(studio.model_root.get_meta("visual_condition") == "danado")
    assert(studio.model_root.find_child("DanosVisibles",true,false) != null)
    studio.building_state_picker.select(3)
    studio._change_building_variant(3)
    assert(studio.model_root.get_meta("visual_condition") == "destruido")
    assert(studio.model_root.find_child("BloqueDeMando",true,false) == null)
    assert(studio.model_root.find_child("PlataformaDerrumbada",true,false) != null)

    studio.level_picker.select(0)
    studio.building_state_picker.select(0)
    studio._change_building_variant(0)
    studio._reset_camera()
    for frame in range(6):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(image.save_png("res://artifacts/tarvoka_headquarters_web_studio.png") == OK)

    studio._switch_category(0)
    assert(studio.category_picker.selected == 0)
    assert(studio._role == "tank")
    assert(not studio.building_controls.visible)
    assert(studio.role_picker.visible)
    assert(studio.model_root != null)
    assert(studio.model_root.get_meta("tarvoka_mbt_hero_v7",false))
    studio.queue_free()
    print("PASS unified web studio: browser units and headquarters, 3 levels, 8 factions, 4 visual conditions")
    quit(0)
