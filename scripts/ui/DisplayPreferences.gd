extends RefCounted
class_name TarvokaDisplayPreferences

const FILE_PATH := "user://tarvoka_display_preferences_v1.cfg"
const VERSION := 1
const FIELDS := ["isometric","battery_saver","minimap_enabled"]

# These settings are deliberately separate from SaveStore and SaveCodec;
# changing a visual preference cannot affect AI, fog, economy or battle saves.
static func defaults(mobile: bool = false) -> Dictionary:
    return {"isometric":mobile,"battery_saver":false,"minimap_enabled":mobile}

static func load_config(mobile: bool = false, path: String = FILE_PATH) -> Dictionary:
    var values: Dictionary = defaults(mobile)
    if not path.begins_with("user://") or not FileAccess.file_exists(path):
        return values
    var config := ConfigFile.new()
    if config.load(path) != OK:
        return values
    if int(config.get_value("display","version",-1)) != VERSION:
        return values
    for key in FIELDS:
        if not config.has_section_key("display",key):
            continue
        var content: Variant = config.get_value("display",key)
        if content is bool:
            values[key] = content
    return values

static func save_config(values: Dictionary, path: String = FILE_PATH) -> bool:
    if not path.begins_with("user://"):
        return false
    for key in FIELDS:
        if not values.has(key) or not values[key] is bool:
            return false
    var config := ConfigFile.new()
    config.set_value("display","version",VERSION)
    for key in FIELDS:
        config.set_value("display",key,values[key])
    return config.save(path) == OK
