extends SceneTree

# Uses the exact engine geometry, scene and controls that the Web export runs.
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1200,740)
    var studio := Studio.new()
    root.add_child(studio)
    for step in range(4):
        await process_frame
    assert(studio.preview != null)
    assert(studio.camera != null)
    assert(studio.model_root != null)
    assert(studio.model_root.get_meta("tarvoka_mbt_production_v4",false))
    assert(studio.role_picker.item_count == Models.ROLES.size())
    assert(studio.faction_picker.item_count == 8)
    assert(studio.damage_picker.item_count == 5)
    var finished_meshes: int = Models.inspect_meshes(studio.model_root)
    assert(finished_meshes > 175)
    for tick in range(3):
        await process_frame
    var finished: Image = studio.preview.get_texture().get_image()
    assert(finished != null and not finished.is_empty())
    # Users reported "no visible change" in 242346.mp4. Preserve a strict
    # same-camera screenshot of BEFORE vs AFTER for actual artistic review.
    studio._toggle_details()
    assert(not studio._final_detail)
    assert(not studio.model_root.get_meta("tarvoka_mbt_production_v4",false))
    assert(Models.inspect_meshes(studio.model_root) < finished_meshes)
    for tick in range(4):
        await process_frame
    var baseline: Image = studio.preview.get_texture().get_image()
    assert(baseline != null and not baseline.is_empty())
    var width: int = 480
    var height: int = 330
    finished.resize(width,height,Image.INTERPOLATE_LANCZOS)
    baseline.resize(width,height,Image.INTERPOLATE_LANCZOS)
    var different_pixels: int = 0
    for py in range(0,height,3):
        for px in range(0,width,3):
            var old: Color = baseline.get_pixel(px,py)
            var refined: Color = finished.get_pixel(px,py)
            if absf(old.r-refined.r)+absf(old.g-refined.g)+absf(old.b-refined.b) > 0.18:
                different_pixels += 1
    assert(different_pixels > 100)
    var sheet: Image = Image.create(width*2,height,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(baseline,Rect2i(0,0,width,height),Vector2i.ZERO)
    sheet.blit_rect(finished,Rect2i(0,0,width,height),Vector2i(width,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sheet.save_png("res://artifacts/tarvoka_mbt_before_after_same_camera.png") == OK)
    studio._toggle_details()
    assert(studio._final_detail)
    assert(studio.model_root.get_meta("tarvoka_mbt_production_v4",false))
    var initial_zoom: float = studio.camera.size
    studio._change_zoom(1)
    assert(studio.camera.size < initial_zoom)
    var initial_yaw: float = studio.model_root.rotation_degrees.y
    studio._rotate(45)
    assert(not is_equal_approx(studio.model_root.rotation_degrees.y,initial_yaw))
    studio._on_faction(2)
    assert(studio._faction == 2)
    assert(Models.paintable_count(studio.model_root) == 14)
    studio._set_damage(3)
    assert(Damage.current_stage(studio.model_root) == 3)
    studio._set_damage(4)
    assert(Damage.current_stage(studio.model_root) == 4)
    studio._set_damage(0)
    assert(Damage.current_stage(studio.model_root) == 0)
    studio._play("attack")
    studio._process(0.15)
    assert(not studio._animation.is_empty())
    studio._stop_animation()
    assert(studio._animation.is_empty())
    studio._on_role(1)
    assert(studio._role == str(Models.ROLES[1]))
    assert(not studio.damage_picker.visible)
    studio._on_role(3)
    assert(studio._role == "tank")
    assert(studio.damage_picker.visible)
    for step in range(3):
        await process_frame
    var rendered: Image = root.get_viewport().get_texture().get_image()
    assert(rendered != null and not rendered.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(rendered.save_png("res://artifacts/tarvoka_web_3d_studio.png") == OK)
    studio.queue_free()
    print("PASS native web studio: exact game meshes, 8 factions, 5 damage states, orbit zoom, recoil and 3D browser scene")
    quit(0)
