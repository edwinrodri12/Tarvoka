extends RefCounted
class_name TarvokaCampaignMission

# Standalone, opt-in narrative objective layer for Chapter 01.
# The default skirmish state/SaveStore is left untouched.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const SAVE_VERSION := 1
const CHAPTER_ID := "C01"
const BEACONS := [[4,2],[5,5]]
const INFANTRY_ROLES := ["line","scout","piercer","assault","engineer"]
const STATUS := ["active","holding","completed","failed"]
const EVENTS := {
    "C01_START": [
        {"speaker":"alianza_norte","text":"Preferiria demostrar que no necesitamos volver a combatir."},
        {"speaker":"pacto_escarlata","text":"Entonces sera el ejercicio mas valioso que hemos organizado."}
    ],
    "C01_FIRST_CAPTURE": [
        {"speaker":"control","text":"Baliza asegurada. Transmision confirmada."},
        {"speaker":"control","text":"Un paquete de Nudo Siete llego fuera de secuencia."}
    ],
    "C01_FIRST_ATTACK": [
        {"speaker":"alianza_norte","text":"Una posicion ganada tambien hay que sostenerla."},
        {"speaker":"control","text":"Perdidas simuladas. Sin bajas reales."}
    ],
    "C01_SUCCESS": [
        {"speaker":"pacto_escarlata","text":"Espero que nunca necesitemos probar esto en otra clase de campo."},
        {"speaker":"alianza_norte","text":"Entonces mantengamos abiertas estas lineas."}
    ]
}

static func start_c01() -> Dictionary:
    var units: Array = [
        Roles.make_unit("C01_N1",0,Vector2i(1,2),"line"),
        Roles.make_unit("C01_N2",0,Vector2i(1,4),"line"),
        Roles.make_unit("C01_N3",0,Vector2i(2,6),"line"),
        Roles.make_unit("C01_R1",1,Vector2i(7,2),"line"),
        Roles.make_unit("C01_R2",1,Vector2i(8,5),"line")
    ]
    var terrain: Array = Scenarios.terrain(1)
    if not Rules.valid_terrain(terrain) or units.any(func(u): return u.is_empty()):
        return {}
    var battle: Dictionary = Session.start(units, terrain)
    if int(battle.get("winner",-2)) != -1:
        return {}
    return {
        "version": SAVE_VERSION,
        "id": CHAPTER_ID,
        "title": "Escudo compartido",
        "battle": battle,
        "status": "active",
        "beacons": BEACONS.duplicate(true),
        "hold_pending": false,
        "last_completed_side": -1,
        "phase_count": 0,
        "events_seen": [],
        "campaign_flags": []
    }

# Objective requires infantry alive on BOTH markers at end of Blue phase,
# then surviving the Red response. Killing Red is not a shortcut to victory.
static func after_phase(mission: Dictionary, battle: Dictionary, completed_side: int) -> Dictionary:
    var next: Dictionary = mission.duplicate(true)
    if not valid_meta(mission) or completed_side not in [0,1]:
        return next
    if str(mission["status"]) in ["completed","failed"]:
        return next
    if int(mission["last_completed_side"]) == completed_side:
        return next
    if completed_side == 1 and int(mission["last_completed_side"]) != 0:
        return next
    if not _compatible_battle(battle):
        return next
    next["battle"] = battle.duplicate(true)
    next["last_completed_side"] = completed_side
    next["phase_count"] = int(next["phase_count"]) + 1
    if int(battle.get("winner",-1)) != -1:
        return resolve_terminal(next, battle)
    if not _has_active_capturer(battle):
        next["status"] = "failed"
        next["hold_pending"] = false
        return next
    if completed_side == 0:
        next["hold_pending"] = _both_beacons_occupied(battle)
        next["status"] = "holding" if next["hold_pending"] else "active"
    else:
        if bool(mission["hold_pending"]) and _both_beacons_occupied(battle):
            next = _complete(next)
        else:
            next["hold_pending"] = false
            next["status"] = "active"
    return next

# Call this after an attack ends the underlying battle, without inventing
# extra turns. Losing all infantry fails; winning by elimination without
# protecting the markers also concludes this drill as failed objective.
static func resolve_terminal(mission: Dictionary, battle: Dictionary) -> Dictionary:
    var next: Dictionary = mission.duplicate(true)
    if not valid_meta(mission) or not _compatible_battle(battle):
        return next
    if str(mission["status"]) in ["completed","failed"]:
        return next
    next["battle"] = battle.duplicate(true)
    var winner: int = int(battle.get("winner",-1))
    if winner == -1:
        if not _has_active_capturer(battle):
            next["status"] = "failed"
            next["hold_pending"] = false
    elif winner == 0 and _both_beacons_occupied(battle):
        next = _complete(next)
    else:
        next["status"] = "failed"
        next["hold_pending"] = false
    return next

# Explicit dialogue acknowledgement is idempotent. The UI may show/skip
# dialogue without changing tactical rules or inventing combat rewards.
static func acknowledge_event(mission: Dictionary, event_id: String, event_context: Dictionary = {}) -> Dictionary:
    var next: Dictionary = mission.duplicate(true)
    if not valid_meta(mission) or not EVENTS.has(event_id) or event_id in mission["events_seen"]:
        return {"valid":false,"state":next,"dialogue":[]}
    if event_id == "C01_SUCCESS" and str(mission["status"]) != "completed":
        return {"valid":false,"state":next,"dialogue":[]}
    if event_id == "C01_FIRST_CAPTURE" and not _any_beacon_occupied(mission["battle"]):
        return {"valid":false,"state":next,"dialogue":[]}
    if event_id == "C01_FIRST_ATTACK" and (not bool(event_context.get("valid",false)) or not event_context.has("attacker_id")):
        return {"valid":false,"state":next,"dialogue":[]}
    (next["events_seen"] as Array).append(event_id)
    return {"valid":true,"state":next,"dialogue":(EVENTS[event_id] as Array).duplicate(true)}

static func available_unlocks(mission: Dictionary) -> Array:
    if valid_meta(mission) and str(mission["status"]) == "completed":
        return ["G01"]
    return []

# Self-contained story checkpoint. Never overwrite the normal skirmish file.
# Produces a JSON document that can be saved at a *separate* campaign path.
static func encode(mission: Dictionary) -> String:
    if not valid_meta(mission) or not _compatible_battle(mission.get("battle",{})):
        return ""
    var battle_text: String = Codec.encode(mission["battle"])
    if battle_text.is_empty():
        return ""
    var metadata: Dictionary = mission.duplicate(true)
    metadata.erase("battle")
    return JSON.stringify({"campaign":metadata,"battle":JSON.parse_string(battle_text)})

static func decode(raw_text: String) -> Dictionary:
    if raw_text.is_empty() or raw_text.length() > 262144:
        return {}
    var raw: Variant = JSON.parse_string(raw_text)
    if not (raw is Dictionary):
        return {}
    if not (raw.get("campaign") is Dictionary) or not (raw.get("battle") is Dictionary):
        return {}
    var battle: Dictionary = Codec.decode(JSON.stringify(raw["battle"]))
    if battle.is_empty() or not _compatible_battle(battle):
        return {}
    var mission: Dictionary = (raw["campaign"] as Dictionary).duplicate(true)
    # Godot JSON decodes all numeric literals as float. Rehydrate the three
    # bounded integer metadata fields without accepting fractional or text.
    for key in ["version","last_completed_side","phase_count"]:
        var value: Variant = mission.get(key)
        if not (value is float or value is int) or float(value) != float(int(value)):
            return {}
        mission[key] = int(value)
    # Check beacon coordinates numerically before replacing the JSON array
    # with canonical integer coordinates. Godot can parse JSON numbers as
    # floating point, which makes raw nested Array equality unreliable.
    var stored_beacons: Variant = mission.get("beacons")
    if not (stored_beacons is Array) or stored_beacons.size() != BEACONS.size():
        return {}
    for i in range(BEACONS.size()):
        var pair: Variant = stored_beacons[i]
        if not (pair is Array) or pair.size() != 2:
            return {}
        for axis in range(2):
            var n: Variant = pair[axis]
            if not (n is float or n is int) or float(n) != float(int(n)) or int(n) != int(BEACONS[i][axis]):
                return {}
    mission["beacons"] = BEACONS.duplicate(true)
    mission["battle"] = battle
    return mission if valid_meta(mission) else {}

static func valid_meta(mission: Dictionary) -> bool:
    if str(mission.get("id","")) != CHAPTER_ID or int(mission.get("version",-1)) != SAVE_VERSION:
        return false
    if str(mission.get("title","")) != "Escudo compartido":
        return false
    if str(mission.get("status","")) not in STATUS:
        return false
    if not (mission.get("beacons") is Array) or mission["beacons"] != BEACONS:
        return false
    if not (mission.get("hold_pending") is bool):
        return false
    if not (mission.get("last_completed_side") is int) or mission["last_completed_side"] not in [-1,0,1]:
        return false
    if not (mission.get("phase_count") is int) or int(mission["phase_count"]) < 0 or int(mission["phase_count"]) > 10000:
        return false
    if not (mission.get("events_seen") is Array) or not (mission.get("campaign_flags") is Array):
        return false
    var seen: Dictionary = {}
    for event_id in mission["events_seen"]:
        if not (event_id is String) or not EVENTS.has(event_id) or seen.has(event_id):
            return false
        seen[event_id] = true
    var flags: Array = mission["campaign_flags"]
    if flags.size() > 2 or flags.size() != flags.duplicate().size():
        return false
    for flag in flags:
        if flag not in ["c01_ejercicio_aprobado","c01_paquete_fuera_secuencia"]:
            return false
    if str(mission["status"]) == "completed" and not ("c01_ejercicio_aprobado" in flags):
        return false
    if str(mission["status"]) != "completed" and not flags.is_empty():
        return false
    if not (mission.get("battle") is Dictionary):
        return false
    return true

static func _compatible_battle(battle: Dictionary) -> bool:
    return battle.get("units") is Array and battle.get("terrain") is Array and Rules.map_size(battle["terrain"]) == Vector2i(10,8) and Rules.valid_terrain(battle["terrain"]) and battle.get("faction") in [0,1] and battle.get("winner") in [-1,0,1]

static func _complete(mission: Dictionary) -> Dictionary:
    mission["status"] = "completed"
    mission["hold_pending"] = false
    mission["campaign_flags"] = ["c01_ejercicio_aprobado","c01_paquete_fuera_secuencia"]
    return mission

static func _has_active_capturer(battle: Dictionary) -> bool:
    for u in battle.get("units",[]):
        if u is Dictionary and int(u.get("faction",-1)) == 0 and int(u.get("hp",0)) > 0 and str(u.get("role","")) in INFANTRY_ROLES:
            return true
    return false

static func _any_beacon_occupied(battle: Dictionary) -> bool:
    for point in BEACONS:
        if _occupied_by_blue_infantry(battle, Vector2i(point[0],point[1])):
            return true
    return false

static func _both_beacons_occupied(battle: Dictionary) -> bool:
    for point in BEACONS:
        if not _occupied_by_blue_infantry(battle,Vector2i(point[0],point[1])):
            return false
    return true

static func _occupied_by_blue_infantry(battle: Dictionary, cell: Vector2i) -> bool:
    for u in battle.get("units",[]):
        if u is Dictionary and int(u.get("faction",-1)) == 0 and int(u.get("hp",0)) > 0 and u.get("pos") == cell and str(u.get("role","")) in INFANTRY_ROLES:
            return true
    return false
