extends SceneTree

# Offline importer of the user-approved eight-emblem sheet.
# Run only after placing the EXACT 1536x1024 source at the documented path:
# godot --headless --path . --script res://tools/import_faction_emblems.gd
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const SOURCE := "res://assets/reference/emblemas_ocho_facciones_aprobados_original.png"
const SOURCE_SHA256 := "cf6228746540082c5c9ece7ccb3e043a58ce10300e05e3ea057f88f202294d63"
const CROPS := [
    Rect2i(20, 90, 362, 385),
    Rect2i(399, 90, 365, 385),
    Rect2i(780, 90, 360, 385),
    Rect2i(1157, 90, 360, 385),
    Rect2i(20, 535, 362, 390),
    Rect2i(399, 535, 365, 390),
    Rect2i(780, 535, 360, 390),
    Rect2i(1157, 535, 360, 390)
]

func _initialize() -> void:
    if not FileAccess.file_exists(SOURCE):
        push_error("Missing approved emblem image at " + SOURCE)
        quit(1)
        return
    if FileAccess.get_sha256(SOURCE) != SOURCE_SHA256:
        push_error("Source image differs from the approved original. Refusing to replace icons.")
        quit(1)
        return
    var image: Image = Image.load_from_file(SOURCE)
    if image == null or image.is_empty() or image.get_size() != Vector2i(1536, 1024):
        push_error("Invalid approved emblem source dimensions.")
        quit(1)
        return
    var destination := ProjectSettings.globalize_path("res://assets/factions")
    if DirAccess.make_dir_recursive_absolute(destination) != OK:
        push_error("Cannot create destination assets/factions directory")
        quit(1)
        return
    for index in range(CROPS.size()):
        var crop: Image = image.get_region(CROPS[index])
        if crop == null or crop.is_empty():
            push_error("Cannot crop approved emblem " + str(index))
            quit(1)
            return
        var path := ProjectSettings.globalize_path(VisualStyle.emblem_path(index))
        if crop.save_png(path) != OK:
            push_error("Cannot write PNG " + path)
            quit(1)
            return
    print("PASS: eight approved emblems extracted into assets/factions without resizing")
    quit(0)
