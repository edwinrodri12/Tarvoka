extends RefCounted
class_name TarvokaSaveStore

const Codec = preload("res://scripts/core/SaveCodec.gd")
const DEFAULT_PATH := "user://tarvoka_battle_v1.json"
const MAX_BYTES := 262144

# The caller owns state. Saving uses a temporary file and a rollback copy.
static func save(state: Dictionary, path: String = DEFAULT_PATH) -> bool:
    if not path.begins_with("user://") or not path.ends_with(".json"):
        return false
    var raw: String = Codec.encode(state)
    if raw.is_empty() or raw.to_utf8_buffer().size() > MAX_BYTES:
        return false
    var tmp := path + ".tmp"
    var backup := path + ".bak"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(raw)
    f.flush()
    var write_error := f.get_error()
    f.close()
    if write_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
        return false
    var tmp_abs := ProjectSettings.globalize_path(tmp)
    var path_abs := ProjectSettings.globalize_path(path)
    var backup_abs := ProjectSettings.globalize_path(backup)
    var had_old := FileAccess.file_exists(path)
    if had_old:
        if FileAccess.file_exists(backup):
            DirAccess.remove_absolute(backup_abs)
        if DirAccess.rename_absolute(path_abs, backup_abs) != OK:
            DirAccess.remove_absolute(tmp_abs)
            return false
    if DirAccess.rename_absolute(tmp_abs, path_abs) != OK:
        if had_old:
            DirAccess.rename_absolute(backup_abs, path_abs)
        DirAccess.remove_absolute(tmp_abs)
        return false
    if had_old:
        DirAccess.remove_absolute(backup_abs)
    return true

static func load(path: String = DEFAULT_PATH) -> Dictionary:
    if not path.begins_with("user://") or not path.ends_with(".json"):
        return {}
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return {}
    if f.get_length() > MAX_BYTES:
        f.close()
        return {}
    var raw := f.get_as_text()
    f.close()
    return Codec.decode(raw)
