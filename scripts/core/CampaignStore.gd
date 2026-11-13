extends RefCounted
class_name TarvokaCampaignStore

const Mission = preload("res://scripts/core/CampaignMission.gd")
const DEFAULT_PATH := "user://tarvoka_campaign_c01_v1.json"
const MAX_BYTES := 262144

# Never write to the skirmish autosave or normal manual-battle checkpoint.
static func _valid_path(path: String) -> bool:
    return path.begins_with("user://tarvoka_campaign_") and path.ends_with(".json")

static func save(mission: Dictionary, path: String = DEFAULT_PATH, retain_previous: bool = true) -> bool:
    if not _valid_path(path):
        return false
    var payload: String = Mission.encode(mission)
    if payload.is_empty() or payload.to_utf8_buffer().size() > MAX_BYTES:
        return false
    var temp: String = path + ".tmp"
    var backup: String = path + ".bak"
    var file := FileAccess.open(temp,FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(payload)
    file.flush()
    var write_error: Error = file.get_error()
    file.close()
    var temp_abs: String = ProjectSettings.globalize_path(temp)
    var main_abs: String = ProjectSettings.globalize_path(path)
    var backup_abs: String = ProjectSettings.globalize_path(backup)
    if write_error != OK or _read(temp).is_empty():
        DirAccess.remove_absolute(temp_abs)
        return false
    var existing: bool = FileAccess.file_exists(path)
    var prior_valid: bool = existing and not _read(path).is_empty()
    if prior_valid:
        if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup_abs) != OK:
            DirAccess.remove_absolute(temp_abs)
            return false
        if DirAccess.rename_absolute(main_abs,backup_abs) != OK:
            DirAccess.remove_absolute(temp_abs)
            return false
    elif existing and DirAccess.remove_absolute(main_abs) != OK:
        DirAccess.remove_absolute(temp_abs)
        return false
    if DirAccess.rename_absolute(temp_abs,main_abs) != OK:
        if prior_valid:
            DirAccess.rename_absolute(backup_abs,main_abs)
        DirAccess.remove_absolute(temp_abs)
        return false
    if not retain_previous and FileAccess.file_exists(backup):
        DirAccess.remove_absolute(backup_abs)
    return true

static func load_report(path: String = DEFAULT_PATH) -> Dictionary:
    if not _valid_path(path):
        return {"state":{},"recovered":false}
    var state: Dictionary = _read(path)
    if not state.is_empty():
        return {"state":state,"recovered":false}
    var backup: Dictionary = _read(path + ".bak")
    return {"state":backup,"recovered":not backup.is_empty()}

static func load(path: String = DEFAULT_PATH) -> Dictionary:
    return load_report(path)["state"]

static func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path,FileAccess.READ)
    if file == null:
        return {}
    if file.get_length() > MAX_BYTES:
        file.close()
        return {}
    var payload: String = file.get_as_text()
    file.close()
    return Mission.decode(payload)
