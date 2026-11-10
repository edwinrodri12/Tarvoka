extends RefCounted
class_name TarvokaSaveStore

const Codec = preload("res://scripts/core/SaveCodec.gd")
const DEFAULT_PATH := "user://tarvoka_battle_v1.json"
const MAX_BYTES := 262144

# The caller owns state. The previous *valid* snapshot is retained as .bak.
# A deliberate new game can drop the backup only once replacement succeeds.
static func save(state: Dictionary, path: String = DEFAULT_PATH, retain_previous: bool = true) -> bool:
    if not _valid_path(path):
        return false
    var raw: String = Codec.encode(state)
    if raw.is_empty() or raw.to_utf8_buffer().size() > MAX_BYTES:
        return false

    var tmp := path + ".tmp"
    var backup := path + ".bak"
    var temp_file := FileAccess.open(tmp, FileAccess.WRITE)
    if temp_file == null:
        return false
    temp_file.store_string(raw)
    temp_file.flush()
    var write_error := temp_file.get_error()
    temp_file.close()
    var tmp_abs := ProjectSettings.globalize_path(tmp)
    var main_abs := ProjectSettings.globalize_path(path)
    var backup_abs := ProjectSettings.globalize_path(backup)
    if write_error != OK or _load_single(tmp).is_empty():
        DirAccess.remove_absolute(tmp_abs)
        return false

    var existing := FileAccess.file_exists(path)
    var existing_valid := existing and not _load_single(path).is_empty()
    if existing_valid:
        # No old backup should mask a newer valid main file.
        if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup_abs) != OK:
            DirAccess.remove_absolute(tmp_abs)
            return false
        if DirAccess.rename_absolute(main_abs, backup_abs) != OK:
            DirAccess.remove_absolute(tmp_abs)
            return false
    elif existing:
        # A corrupted primary must never replace a valid backup.
        # If promotion fails, load() still falls back to the previous .bak.
        if DirAccess.remove_absolute(main_abs) != OK:
            DirAccess.remove_absolute(tmp_abs)
            return false

    if DirAccess.rename_absolute(tmp_abs, main_abs) != OK:
        if existing_valid:
            DirAccess.rename_absolute(backup_abs, main_abs)
        DirAccess.remove_absolute(tmp_abs)
        return false

    if not retain_previous and FileAccess.file_exists(backup):
        # Intentional New Game cannot resurrect an older campaign if the
        # newly created primary later becomes corrupt.
        DirAccess.remove_absolute(backup_abs)
    return true

static func load(path: String = DEFAULT_PATH) -> Dictionary:
    return load_report(path)["state"]

# Metadata lets UI state when we had to recover the previous valid snapshot.
static func load_report(path: String = DEFAULT_PATH) -> Dictionary:
    if not _valid_path(path):
        return {"state": {}, "recovered": false}
    var current: Dictionary = _load_single(path)
    if not current.is_empty():
        return {"state": current, "recovered": false}
    var backup: Dictionary = _load_single(path + ".bak")
    if not backup.is_empty():
        return {"state": backup, "recovered": true}
    return {"state": {}, "recovered": false}

static func _valid_path(path: String) -> bool:
    return path.begins_with("user://") and path.ends_with(".json")

static func _load_single(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    if file.get_length() > MAX_BYTES:
        file.close()
        return {}
    var raw := file.get_as_text()
    file.close()
    return Codec.decode(raw)
