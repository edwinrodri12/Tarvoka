extends SceneTree

const Atlas = preload("res://scripts/ui/UnitSpriteAtlas.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")

# Run: godot --headless --path . --script res://tools/export_unit_atlas.gd
# No viewport capture, graphics device, Python dependencies or external assets.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var raster: Image = Atlas.image_copy()
    if raster == null or raster.is_empty() or raster.get_size() != Atlas.dimension():
        push_error("Cannot produce atlas; SVG rasterization failed")
        quit(1)
        return
    var dir_path := ProjectSettings.globalize_path("res://assets/generated")
    if DirAccess.make_dir_recursive_absolute(dir_path) != OK:
        push_error("Cannot create generated sprite directory")
        quit(1)
        return
    var png_path := ProjectSettings.globalize_path(Atlas.PREBUILT)
    if raster.save_png(png_path) != OK:
        push_error("Cannot write sprite PNG")
        quit(1)
        return
    var manifest: Dictionary = {
        "schema": 1,
        "size": [Atlas.dimension().x,Atlas.dimension().y],
        "cell_px": Atlas.CELL,
        "columns": Atlas.COLUMNS,
        "poses": Atlas.POSES,
        "palette": "neutral grayscale; tinted using VisualStyle.faction_color()",
        "atlas": "tarvoka_units_32x4.png",
        "frames": {}
    }
    var roles: Array = Roles.ORDER + Arsenal.ORDER
    for role in roles:
        for pose in Atlas.POSES:
            var rect: Rect2i = Atlas.region(str(role),str(pose))
            manifest["frames"]["%s/%s" % [role,pose]] = [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
    var file_path := dir_path.path_join("tarvoka_units_32x4.json")
    var file: FileAccess = FileAccess.open(file_path,FileAccess.WRITE)
    if file == null:
        push_error("Cannot write sprite manifest")
        quit(1)
        return
    file.store_string(JSON.stringify(manifest,"  ")+"\n")
    file.close()
    print("PASS TARVOKA atlas 32 x 4 = 128 real raster frames at %s; sha256 %s" %
        [str(Atlas.dimension()),FileAccess.get_sha256(png_path)])
    quit(0)
