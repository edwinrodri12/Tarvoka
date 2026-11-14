extends RefCounted
class_name TarvokaEngineerRepair

const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")

# Narrow competitive prototype: an engineer repairs ONE adjacent allied
# GROUND chassis, never infantry, aircraft, ships, structures or itself.
# Each action restores at most 3 HP, at 35 credits per HP (no free healing).
# Damage, HP ceilings, income and manufacturing costs are NOT modified.
const MAX_HP_PER_ACTION := 3
const CREDITS_PER_HP := 35
const REPAIRABLE_CHASSIS := [
    "bulwark", "apc", "ifv", "tank", "spg", "mlrs",
    "mobile_aa", "sam", "ew", "logistics"
]

static func maximum_hp(role: String) -> int:
    if Roles.PROFILES.has(role):
        return int(Roles.PROFILES[role]["hp"])
    if Arsenal.valid(role):
        return int(Arsenal.profile(role)["hp"])
    return 0

static func quote(state: Dictionary, engineer_id: String, target_id: String) -> Dictionary:
    var invalid: Dictionary = {"valid":false}
    if engineer_id.is_empty() or target_id.is_empty() or engineer_id == target_id:
        return invalid
    if int(state.get("winner",-1)) != -1 or not state.get("units") is Array:
        return invalid
    if not state.get("economy") is Dictionary or not state.get("terrain") is Array:
        return invalid
    if not Economy.valid(state["economy"],state["terrain"]):
        return invalid
    if not bool(state["economy"].get("modern",false)):
        return invalid
    var faction: int = int(state.get("faction",-1))
    if faction not in [0,1]:
        return invalid
    var engineer: Dictionary = {}
    var target: Dictionary = {}
    var seen_ids: Dictionary = {}
    for candidate in state["units"]:
        if not candidate is Dictionary or not candidate.get("id") is String:
            return invalid
        var uid: String = str(candidate["id"])
        if uid.is_empty() or seen_ids.has(uid):
            return invalid
        seen_ids[uid] = true
        if uid == engineer_id:
            engineer = candidate
        elif uid == target_id:
            target = candidate
    if engineer.is_empty() or target.is_empty():
        return invalid
    if str(engineer.get("role","")) != "engineer" or int(engineer.get("hp",0)) <= 0:
        return invalid
    if bool(engineer.get("acted",true)) or int(engineer.get("faction",-1)) != faction:
        return invalid
    if int(target.get("faction",-1)) != faction or int(target.get("hp",0)) <= 0:
        return invalid
    var role: String = str(target.get("role",""))
    if role not in REPAIRABLE_CHASSIS or Domains.domain(target) != Domains.GROUND:
        return invalid
    var maximum: int = maximum_hp(role)
    if maximum <= 0 or int(target["hp"]) >= maximum:
        return invalid
    var from_pos = engineer.get("pos")
    var target_pos = target.get("pos")
    if not from_pos is Vector2i or not target_pos is Vector2i:
        return invalid
    if not Rules.inside(from_pos,state["terrain"]) or not Rules.inside(target_pos,state["terrain"]):
        return invalid
    if absi(from_pos.x-target_pos.x)+absi(from_pos.y-target_pos.y) != 1:
        return invalid
    var credits: int = int(state["economy"]["credits"][faction])
    var affordable: int = int(credits/CREDITS_PER_HP)
    var restored: int = mini(MAX_HP_PER_ACTION,mini(maximum-int(target["hp"]),affordable))
    if restored <= 0:
        return invalid
    return {
        "valid":true,"engineer_id":engineer_id,"target_id":target_id,
        "target_role":role,"restored":restored,"cost":restored*CREDITS_PER_HP,
        "before_hp":int(target["hp"]),"after_hp":int(target["hp"])+restored,
        "maximum_hp":maximum
    }

static func options(state: Dictionary, engineer_id: String) -> Array:
    var result: Array = []
    for unit in state.get("units",[]):
        if not unit is Dictionary:
            continue
        var proposal: Dictionary = quote(state,engineer_id,str(unit.get("id","")))
        if bool(proposal.get("valid",false)):
            result.append(proposal)
    result.sort_custom(func(a,b):
        # Meaningful decision order: bigger actual repairs first; then stable ID.
        return int(a["restored"]) > int(b["restored"]) if
            int(a["restored"]) != int(b["restored"]) else
            str(a["target_id"]) < str(b["target_id"])
    )
    return result

static func apply(state: Dictionary, engineer_id: String, target_id: String) -> Dictionary:
    var denied := {"valid":false,"state":state.duplicate(true)}
    var current: Dictionary = quote(state,engineer_id,target_id)
    if not bool(current.get("valid",false)):
        return denied
    var next: Dictionary = state.duplicate(true)
    var found_actor := false
    var found_target := false
    for unit in next["units"]:
        if str(unit.get("id","")) == engineer_id:
            unit["acted"] = true
            unit["moved"] = true
            found_actor = true
        if str(unit.get("id","")) == target_id:
            unit["hp"] = int(current["after_hp"])
            found_target = true
    if not found_actor or not found_target:
        return denied
    var faction: int = int(next["faction"])
    next["economy"]["credits"][faction] -= int(current["cost"])
    var result: Dictionary = current.duplicate(true)
    result["state"] = next
    return result
