extends RefCounted
class_name TarvokaCampTactics

# Battlefield data, independent from the 3D gallery. No default construction
# prices, structural HP or recon radius: those require a final balance table.
# Experimental callers must provide an explicit authoritative profile.
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")

const BUILDERS := {
    "engineer": "defensivo",
    "infantry_engineer": "defensivo",
    "infantry_sniper": "reconocimiento",
    "infantry_logistic": "suministros",
    "infantry_medic": "medico"
}
const KINDS := ["defensivo", "reconocimiento", "suministros", "medico"]
const MAX_PER_SIDE := 3
const DEFENSE_BONUS := 2
const MAX_HP := 10000
const MAX_VISION := 8
const MAX_CREDITS := 100000

static func kind_for(role: String) -> String:
    return str(BUILDERS.get(role, ""))

static func _reserved(state: Dictionary, pos: Vector2i) -> bool:
    for key in ["economy", "control"]:
        var system: Variant = state.get(key, {})
        if not system is Dictionary:
            continue
        var locations: Variant = system.get("sites" if key == "economy" else "nodes", [])
        if not locations is Array:
            continue
        for site in locations:
            if site is Dictionary and site.get("pos", null) == pos:
                return true
    return false

static func valid(state: Dictionary) -> bool:
    if not state.has("camps"):
        return true
    var camps: Variant = state["camps"]
    var terrain: Variant = state.get("terrain", [])
    if not camps is Array or not terrain is Array or not Rules.valid_terrain(terrain):
        return false
    if camps.size() > MAX_PER_SIDE * 2:
        return false
    var cells: Dictionary = {}
    var counts: Array[int] = [0, 0]
    for entry in camps:
        if not entry is Dictionary or entry.size() != 6:
            return false
        if not entry.get("kind") is String or entry["kind"] not in KINDS:
            return false
        if not entry.get("owner") is int or entry["owner"] not in [0, 1]:
            return false
        if not entry.get("pos") is Vector2i:
            return false
        var pos: Vector2i = entry["pos"]
        if not Rules.inside(pos, terrain) or cells.has(pos) or _reserved(state, pos):
            return false
        if Rules.movement_cost_for(str(terrain[pos.y][pos.x]), Domains.GROUND) < 0:
            return false
        if not entry.get("hp") is int or not entry.get("max_hp") is int:
            return false
        if entry["hp"] <= 0 or entry["hp"] > entry["max_hp"] or entry["max_hp"] > MAX_HP:
            return false
        if not entry.get("vision") is int:
            return false
        if entry["kind"] == "reconocimiento":
            if entry["vision"] < 1 or entry["vision"] > MAX_VISION:
                return false
        elif entry["vision"] != 0:
            return false
        cells[pos] = true
        var owner: int = int(entry["owner"])
        counts[owner] += 1
        if counts[owner] > MAX_PER_SIDE:
            return false
    return true

static func _valid_profile(kind: String, profile: Dictionary) -> bool:
    if kind not in KINDS:
        return false
    if not profile.get("cost") is int or not profile.get("hp") is int:
        return false
    if profile["cost"] < 1 or profile["cost"] > MAX_CREDITS or profile["hp"] < 1 or profile["hp"] > MAX_HP:
        return false
    var vision: Variant = profile.get("vision", 0)
    if not vision is int:
        return false
    return vision >= 1 and vision <= MAX_VISION if kind == "reconocimiento" else vision == 0

# Caller supplies a scenario-owned profile, not a UI-provided price.
# Building consumes the active specialist's action and credits, not the
# specialist itself. Placement is exactly its current ground tile.
static func deploy(state: Dictionary, builder_id: String, kind: String,
        profile: Dictionary) -> Dictionary:
    var denied := {"valid": false, "state": state.duplicate(true)}
    if not _valid_profile(kind, profile) or not valid(state):
        return denied
    if not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]):
        return denied
    var side: Variant = state.get("faction", -1)
    if side not in [0, 1] or int(state.get("winner", -1)) != -1 or not state.get("units") is Array:
        return denied
    var economy: Variant = state.get("economy", {})
    if not economy is Dictionary or not economy.get("credits") is Array or economy["credits"].size() != 2:
        return denied
    if not economy["credits"][side] is int or economy["credits"][side] < profile["cost"]:
        return denied
    var builder: Dictionary = {}
    var matching: int = 0
    for unit in state["units"]:
        if unit is Dictionary and unit.get("id", "") == builder_id:
            matching += 1
            builder = unit
    if matching != 1 or builder_id.is_empty() or not Turns.can_act(builder, int(side)):
        return denied
    if kind_for(str(builder.get("role", ""))) != kind or Domains.domain(builder) != Domains.GROUND:
        return denied
    var pos: Variant = builder.get("pos", null)
    if not pos is Vector2i or not Rules.inside(pos, state["terrain"]) or _reserved(state, pos):
        return denied
    var next: Dictionary = state.duplicate(true)
    if not next.has("camps"):
        next["camps"] = []
    next["camps"].append({
        "kind": kind, "owner": int(side), "pos": pos,
        "hp": int(profile["hp"]), "max_hp": int(profile["hp"]),
        "vision": int(profile.get("vision", 0))
    })
    if not valid(next):
        return denied
    next["economy"]["credits"][side] -= int(profile["cost"])
    for unit in next["units"]:
        if unit.get("id", "") == builder_id:
            unit["acted"] = true
            break
    return {"valid": true, "state": next, "camp_pos": pos, "camp_kind": kind}

static func defensive_cover(attacker: Dictionary, defender: Dictionary, camps: Array) -> int:
    if Domains.domain(attacker) != Domains.GROUND or Domains.domain(defender) != Domains.GROUND:
        return 0
    if int(defender.get("hp", 0)) <= 0:
        return 0
    for camp in camps:
        if camp is Dictionary and camp.get("kind", "") == "defensivo" and int(camp.get("hp", 0)) > 0:
            if camp.get("pos") == defender.get("pos") and int(camp.get("owner", -1)) == int(defender.get("faction", -2)):
                return DEFENSE_BONUS
    return 0
