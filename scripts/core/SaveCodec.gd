extends RefCounted
class_name TarvokaSaveCodec

const WIDTH := 10
const HEIGHT := 8
const VERSION := 1
const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const MAX_UNITS := 256
const MAX_STAT := 10000

# Portable JSON snapshot; never serialize Godot-specific Vector2i directly.
static func encode(state: Dictionary) -> String:
    if not _valid_state(state):
        return ""
    var units: Array = []
    for unit in state["units"]:
        var copy: Dictionary = unit.duplicate(true)
        var pos: Vector2i = unit["pos"]
        copy["pos"] = [pos.x, pos.y]
        units.append(copy)
    var snapshot: Dictionary = {
        "version": VERSION,
        "faction": state["faction"],
        "winner": state["winner"],
        "terrain": state["terrain"],
        "units": units
    }
    if state.has("map_seed"):
        snapshot["map_seed"] = int(state["map_seed"])
    if state.has("control"):
        var control: Dictionary = state["control"].duplicate(true)
        for node in control["nodes"]:
            var pos: Vector2i = node["pos"]
            node["pos"] = [pos.x, pos.y]
        snapshot["control"] = control
    if state.has("economy"):
        var urban: Dictionary = state["economy"].duplicate(true)
        for site in urban["sites"]:
            var position: Vector2i = site["pos"]
            site["pos"] = [position.x, position.y]
        snapshot["economy"] = urban
    if Visibility.enabled(state):
        snapshot["fog_enabled"] = true
        var explored: Dictionary = {}
        for faction in [0, 1]:
            var cells: Array = []
            for cell in state["explored"][str(faction)]:
                cells.append([cell.x, cell.y])
            explored[str(faction)] = cells
        snapshot["explored"] = explored
        if state.has("contacts"):
            var stored: Dictionary = {}
            for faction in [0, 1]:
                var side: Dictionary = {}
                for enemy_id in state["contacts"][str(faction)]:
                    var cell: Vector2i = state["contacts"][str(faction)][enemy_id]
                    side[str(enemy_id)] = [cell.x, cell.y]
                stored[str(faction)] = side
            snapshot["contacts"] = stored
    return JSON.stringify(snapshot)

static func decode(raw: String) -> Dictionary:
    var data = JSON.parse_string(raw)
    if not data is Dictionary or data.get("version") != VERSION:
        return {}
    if not data.get("units") is Array:
        return {}
    var state: Dictionary = data.duplicate(true)
    state.erase("version")
    for unit in state["units"]:
        if not unit is Dictionary or not unit.get("pos") is Array:
            return {}
        var pos: Array = unit["pos"]
        if pos.size() != 2 or not _whole(pos[0]) or not _whole(pos[1]):
            return {}
        unit["pos"] = Vector2i(int(pos[0]), int(pos[1]))
        for key in ["faction", "hp", "move_points", "attack", "defense", "cover"]:
            if not _whole(unit.get(key)):
                return {}
            unit[key] = int(unit[key])
        if unit.has("vision"):
            if not _whole(unit["vision"]):
                return {}
            unit["vision"] = int(unit["vision"])
        for key in ["ammo", "fuel", "supply_ammo", "supply_fuel"]:
            if unit.has(key):
                if not _whole(unit[key]):
                    return {}
                unit[key] = int(unit[key])
        for key in ["attack_range", "attack_min_range"]:
            if unit.has(key):
                if not _whole(unit[key]):
                    return {}
                unit[key] = int(unit[key])
    if not _whole(state.get("faction")) or not _whole(state.get("winner")):
        return {}
    state["faction"] = int(state["faction"])
    state["winner"] = int(state["winner"])
    if state.has("map_seed"):
        if not _whole(state["map_seed"]):
            return {}
        state["map_seed"] = int(state["map_seed"])
    if state.has("control"):
        var objective = state["control"]
        if not objective is Dictionary or not objective.get("nodes") is Array:
            return {}
        for node in objective["nodes"]:
            if not node is Dictionary or not node.get("pos") is Array:
                return {}
            var raw_cell: Array = node["pos"]
            if raw_cell.size() != 2 or not _whole(raw_cell[0]) or not _whole(raw_cell[1]) or not _whole(node.get("owner")):
                return {}
            node["pos"] = Vector2i(int(raw_cell[0]), int(raw_cell[1]))
            node["owner"] = int(node["owner"])
        for key in ["target", "turns"]:
            if not _whole(objective.get(key)):
                return {}
            objective[key] = int(objective[key])
        if objective.has("first_faction"):
            if not _whole(objective["first_faction"]):
                return {}
            objective["first_faction"] = int(objective["first_faction"])
        if not objective.get("scores") is Array or objective["scores"].size() != 2:
            return {}
        for i in range(2):
            if not _whole(objective["scores"][i]):
                return {}
            objective["scores"][i] = int(objective["scores"][i])
    if state.has("economy"):
        var urban = state["economy"]
        if not urban is Dictionary or not urban.get("sites") is Array or not urban.get("credits") is Array:
            return {}
        for key in ["turn", "next_unit"]:
            if not _whole(urban.get(key)):
                return {}
            urban[key] = int(urban[key])
        for i in range(urban["credits"].size()):
            if not _whole(urban["credits"][i]):
                return {}
            urban["credits"][i] = int(urban["credits"][i])
        for site in urban["sites"]:
            if not site is Dictionary or not site.get("pos") is Array or site["pos"].size() != 2:
                return {}
            var city_pos: Array = site["pos"]
            if not _whole(city_pos[0]) or not _whole(city_pos[1]) or not _whole(site.get("owner")):
                return {}
            site["pos"] = Vector2i(int(city_pos[0]), int(city_pos[1]))
            site["owner"] = int(site["owner"])
            if site.has("produced_turn"):
                if not _whole(site["produced_turn"]):
                    return {}
                site["produced_turn"] = int(site["produced_turn"])
    if state.has("fog_enabled"):
        if state["fog_enabled"] != true or not state.get("explored") is Dictionary:
            return {}
        var result_explored: Dictionary = {}
        for faction in [0, 1]:
            var cells = state["explored"].get(str(faction), null)
            if not cells is Array or cells.size() > WIDTH * HEIGHT:
                return {}
            var restored: Array[Vector2i] = []
            var unique: Dictionary = {}
            for point in cells:
                if not point is Array or point.size() != 2 or not _whole(point[0]) or not _whole(point[1]):
                    return {}
                var cell := Vector2i(int(point[0]), int(point[1]))
                if not Rules.inside(cell) or unique.has(cell):
                    return {}
                unique[cell] = true
                restored.append(cell)
            result_explored[str(faction)] = restored
        state["explored"] = result_explored
        if state.has("contacts"):
            if not state["contacts"] is Dictionary:
                return {}
            var contacts: Dictionary = {}
            for faction in [0, 1]:
                var old_side = state["contacts"].get(str(faction), null)
                if not old_side is Dictionary or old_side.size() > MAX_UNITS:
                    return {}
                var next_side: Dictionary = {}
                for enemy_id in old_side:
                    if not enemy_id is String or enemy_id.is_empty() or enemy_id.length() > 64:
                        return {}
                    var raw_pos = old_side[enemy_id]
                    if not raw_pos is Array or raw_pos.size() != 2 or not _whole(raw_pos[0]) or not _whole(raw_pos[1]):
                        return {}
                    var position := Vector2i(int(raw_pos[0]), int(raw_pos[1]))
                    if not Rules.inside(position):
                        return {}
                    next_side[enemy_id] = position
                contacts[str(faction)] = next_side
            state["contacts"] = contacts
    if not _valid_state(state):
        return {}
    return state

static func _valid_state(state: Dictionary) -> bool:
    if not state.get("terrain") is Array or state["terrain"].size() != HEIGHT:
        return false
    for row in state["terrain"]:
        if not row is Array or row.size() != WIDTH:
            return false
        for tile in row:
            if not tile is String or not Rules.TERRAIN_COST.has(tile):
                return false
    # A seeded map stores its own terrain exactly as before; this
    # optional integer is a reproducibility checksum, not an untrusted
    # instruction to rewrite terrain when the save loads.
    if state.has("map_seed"):
        if not state["map_seed"] is int or not Scenarios.valid_seed(int(state["map_seed"])):
            return false
        if state["terrain"] != Scenarios.seeded_terrain(int(state["map_seed"])):
            return false
    if not state.get("units") is Array or state["units"].size() > MAX_UNITS:
        return false
    if not state.get("faction") is int or state["faction"] not in [0, 1]:
        return false
    if not state.get("winner") is int or state["winner"] not in [-1, 0, 1]:
        return false
    var ids: Dictionary = {}
    var positions: Dictionary = {}
    for unit in state["units"]:
        if not unit is Dictionary:
            return false
        if not unit.get("id") is String or unit["id"].is_empty() or unit["id"].length() > 64 or ids.has(unit["id"]):
            return false
        ids[unit["id"]] = true
        if not unit.get("pos") is Vector2i:
            return false
        var pos: Vector2i = unit["pos"]
        if pos.x < 0 or pos.x >= WIDTH or pos.y < 0 or pos.y >= HEIGHT:
            return false
        if not unit.get("faction") is int or unit["faction"] not in [0, 1]:
            return false
        if not unit.get("hp") is int or unit["hp"] < 0 or unit["hp"] > MAX_STAT:
            return false
        if not unit.get("acted") is bool:
            return false
        if unit.has("moved") and not unit["moved"] is bool:
            return false
        if unit.has("role") and (not unit["role"] is String or not Roles.valid(unit["role"])):
            return false
        if unit.has("domain") and not Domains.valid_domain(unit["domain"]):
            return false
        if unit.has("target_domains") and not Domains.valid_targets(unit["target_domains"]):
            return false
        if not Logistics.valid_unit(unit):
            return false
        if Arsenal.valid(str(unit.get("role", ""))):
            var spec: Dictionary = Arsenal.profile(str(unit["role"]))
            if unit.get("domain") != spec["domain"] or unit.get("target_domains") != spec["target_domains"]:
                return false
        # Optional fields retain compatibility with every v1 save: missing
        # values mean infantry-style melee range 1..1 and unused movement.
        if unit.has("attack_range") and (not unit["attack_range"] is int or unit["attack_range"] < 1 or unit["attack_range"] > 8):
            return false
        if unit.has("attack_min_range") and (not unit["attack_min_range"] is int or unit["attack_min_range"] < 1 or unit["attack_min_range"] > int(unit.get("attack_range", 1))):
            return false
        for key in ["move_points", "attack", "defense", "cover"]:
            if not unit.get(key) is int or unit[key] < 0 or unit[key] > MAX_STAT:
                return false
        if unit.has("vision") and (not unit["vision"] is int or unit["vision"] < 1 or unit["vision"] > Visibility.MAX_VISION):
            return false
        if unit["hp"] > 0:
            var plane: int = 1 if Domains.layer(unit) == Domains.AIR else 0
            var occupied_key := Vector3i(pos.x, pos.y, plane)
            if positions.has(occupied_key):
                return false
            if Rules.movement_cost_for(str(state["terrain"][pos.y][pos.x]), Domains.domain(unit)) < 0:
                return false
            positions[occupied_key] = true
    if state.has("economy"):
        if not state["economy"] is Dictionary or not Economy.valid(state["economy"], state["terrain"]):
            return false
    # Fog saves must include coherent, bounded exploration for both factions.
    if state.has("fog_enabled"):
        if state["fog_enabled"] != true or not state.get("explored") is Dictionary:
            return false
        for faction in [0, 1]:
            var cells = state["explored"].get(str(faction), null)
            if not cells is Array or cells.size() > WIDTH * HEIGHT:
                return false
            var unique: Dictionary = {}
            for cell in cells:
                if not cell is Vector2i or not Rules.inside(cell) or unique.has(cell):
                    return false
                unique[cell] = true
            for currently_visible in Visibility.visible_cells(state, faction):
                if not unique.has(currently_visible):
                    return false
        if state.has("contacts"):
            if not state["contacts"] is Dictionary:
                return false
            for faction in [0, 1]:
                var side = state["contacts"].get(str(faction), null)
                if not side is Dictionary or side.size() > MAX_UNITS:
                    return false
                var explored: Dictionary = Visibility.explored_cells(state, faction)
                for enemy_id in side:
                    if not enemy_id is String or enemy_id.is_empty() or enemy_id.length() > 64:
                        return false
                    var old_cell = side[enemy_id]
                    if not old_cell is Vector2i or not Rules.inside(old_cell) or not explored.has(old_cell):
                        return false
                    var has_enemy := false
                    for enemy in state["units"]:
                        if str(enemy.get("id", "")) == enemy_id:
                            if int(enemy.get("faction", -1)) == faction:
                                return false
                            has_enemy = true
                            break
                    if not has_enemy:
                        return false
    elif state.has("explored") or state.has("contacts"):
        return false
    # Relay victories may end a match with living armies; they are valid
    # only when a real scoreboard meets its documented target.
    var expected_winner: int = Turns.winner(state["units"])
    if state.has("control"):
        if not state["control"] is Dictionary or not Relays.valid(state["control"], state["terrain"]):
            return false
        var scoreboard: Dictionary = state["control"]
        # Legacy relays could not both finish at target because the first
        # threshold crossing immediately ended the match. Modern fair rounds
        # deliberately allow 2:2 ties (and continued over-target scoring).
        if not bool(scoreboard.get("fair_round",false)) and scoreboard["scores"][0] >= scoreboard["target"] and scoreboard["scores"][1] >= scoreboard["target"]:
            return false
        if expected_winner == -1:
            expected_winner = Relays.score_winner(scoreboard)
    if state["winner"] != expected_winner:
        return false
    return true

# Godot JSON parser can represent integral JSON numbers as float.
static func _whole(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(int(value)) == float(value)
