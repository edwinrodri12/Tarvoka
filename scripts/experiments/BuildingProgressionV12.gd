extends RefCounted
class_name TarvokaBuildingProgressionV12

# BALANCE LAB ONLY. Progress is intentionally external to BattleSession
# and SaveCodec. This is not a production progression system.
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Specialist = preload("res://scripts/experiments/RoleSpecializationV08.gd")

# Candidate costs in credits, NEVER approved values.
const UPGRADE_COSTS := {
    "factory":{2:400,3:750},
    "armor_plant":{2:650,3:1050},
    "artillery_depot":{2:550,3:950},
    "drone_center":{2:400}, # LIII intentionally blocked: no actual benefit yet.
    "airbase":{2:750,3:1400},
    "shipyard":{2:800,3:1500}
}
const TECH_COSTS := {"antiarmor_v1":450,"field_workshop":250}
const TECH_PRODUCERS := {"antiarmor_v1":"armor_plant","field_workshop":"factory"}

# Explicit, reviewed producer->role assignments. No invented classes.
# Roles with incomplete special actions remain labelled incomplete.
const ROLE_LEVELS := {
    "line":1,"scout":1,"assault":2,"engineer":2,"logistics":2,
    "apc":1,"piercer":1,"bulwark":1,"ifv":2,"tank":2,
    "artillery":1,"mobile_aa":1,"spg":2,"sam":2,"mlrs":3,"ew":3,
    "uav_recon":1,"fpv":1,"loitering":2,
    "attack_heli":1,"transport_heli":1,"ucav":2,"fighter":2,"bomber":3,
    "patrol":1,"usv":1,"missile_boat":2,"corvette":2,"landing_ship":2,
    "frigate":3,"destroyer":3,"submarine":3
}

static func _tag(site: Dictionary) -> String:
    var cell: Vector2i = site["pos"]
    return "%s:%d:%d" % [str(site["kind"]),cell.x,cell.y]

static func _record(site: Dictionary, progress: Dictionary) -> Dictionary:
    var key: String = _tag(site)
    var owner: int = int(site.get("owner",-1))
    if progress.get("facilities",{}) is Dictionary:
        var record: Dictionary = progress.get("facilities",{}).get(key,{})
        if int(record.get("owner",-99)) == owner and owner in [0,1]:
            return record
    return {"owner":owner,"level":1}

static func _active(state: Dictionary, progress: Dictionary) -> bool:
    return state.get("economy",null) is Dictionary and \
        bool(state.get("economy",{}).get("modern",false)) and \
        state.get("units",null) is Array and \
        int(state.get("faction",-1)) in [0,1] and \
        int(state.get("winner",-1)) == -1 and \
        Economy.valid(state["economy"],state.get("terrain",[])) and \
        Opening.can_order(state) and progress is Dictionary

static func level_for(state: Dictionary, progress: Dictionary, cell: Vector2i) -> int:
    if not state.has("economy"):
        return 0
    var site: Dictionary = Economy.site_at(state["economy"],cell)
    if site.is_empty() or str(site["kind"]) not in UPGRADE_COSTS:
        return 0
    if int(site.get("owner",-1)) not in [0,1]:
        return 0
    return int(_record(site,progress).get("level",1))

static func required_level(role: String) -> int:
    return int(ROLE_LEVELS.get(role,0))

static func can_recruit(state: Dictionary, progress: Dictionary,
        cell: Vector2i, role: String) -> bool:
    if not _active(state,progress) or not ROLE_LEVELS.has(role):
        return false
    var facility: Dictionary = Economy.site_at(state["economy"],cell)
    return not facility.is_empty() and \
        int(facility.get("owner",-1)) == int(state["faction"]) and \
        Economy.producer_for(role,true) == str(facility.get("kind","")) and \
        int(_record(facility,progress).get("level",1)) >= required_level(role) and \
        Economy.can_purchase(state,cell,role)

static func recruit(state: Dictionary, progress: Dictionary,
        cell: Vector2i, role: String) -> Dictionary:
    var denied := {"valid":false,"state":state.duplicate(true),
        "progress":progress.duplicate(true)}
    if not can_recruit(state,progress,cell,role):
        return denied
    var action: Dictionary = Session.purchase(state,cell,role)
    if not bool(action.get("valid",false)):
        return denied
    action["progress"] = progress.duplicate(true)
    action["reason"] = "experimental_tier_recruitment"
    return action

static func can_upgrade(state: Dictionary, progress: Dictionary,
        cell: Vector2i) -> bool:
    if not _active(state,progress):
        return false
    var site: Dictionary = Economy.site_at(state["economy"],cell)
    if site.is_empty() or str(site.get("kind","")) not in UPGRADE_COSTS:
        return false
    var side: int = int(state["faction"])
    if int(site.get("owner",-1)) != side or int(site.get("produced_turn",-1)) == int(state["economy"]["turn"]):
        return false
    var next_level: int = int(_record(site,progress)["level"])+1
    var costs: Dictionary = UPGRADE_COSTS[str(site["kind"])]
    return costs.has(next_level) and int(state["economy"]["credits"][side]) >= int(costs[next_level])

static func upgrade(state: Dictionary, progress: Dictionary,
        cell: Vector2i) -> Dictionary:
    var denied := {"valid":false,"state":state.duplicate(true),
        "progress":progress.duplicate(true)}
    if not can_upgrade(state,progress,cell):
        return denied
    var result: Dictionary = state.duplicate(true)
    var trail: Dictionary = progress.duplicate(true)
    var site: Dictionary = Economy.site_at(result["economy"],cell)
    var next_level: int = int(_record(site,trail)["level"])+1
    var cost: int = int(UPGRADE_COSTS[str(site["kind"])][next_level])
    var side: int = int(state["faction"])
    result["economy"]["credits"][side] = int(result["economy"]["credits"][side])-cost
    # Upgrading consumes that building's only production opportunity in
    # the present phase, with neither free recruits nor a free upgrade.
    site["produced_turn"] = int(result["economy"]["turn"])
    if not trail.has("facilities"):
        trail["facilities"] = {}
    trail["facilities"][_tag(site)] = {"owner":side,"level":next_level}
    Opening.record(result)
    return {"valid":true,"state":result,"progress":trail,
        "action":"upgrade","level":next_level,"cost":cost,"kind":site["kind"],
        "reason":"experimental_building_level"}

static func has_tech(progress: Dictionary, side: int, tech: String) -> bool:
    if side not in [0,1] or not TECH_COSTS.has(tech):
        return false
    return bool(progress.get("techs",{}).get(str(side),{}).get(tech,false))

static func can_research(state: Dictionary, progress: Dictionary,
        cell: Vector2i, tech: String) -> bool:
    if not _active(state,progress) or not TECH_COSTS.has(tech):
        return false
    var facility: Dictionary = Economy.site_at(state["economy"],cell)
    var side: int = int(state["faction"])
    if facility.is_empty() or int(facility.get("owner",-1)) != side:
        return false
    if str(facility["kind"]) != str(TECH_PRODUCERS[tech]) or \
            int(facility.get("produced_turn",-1)) == int(state["economy"]["turn"]):
        return false
    if int(_record(facility,progress)["level"]) < 3 or has_tech(progress,side,tech):
        return false
    return int(state["economy"]["credits"][side]) >= int(TECH_COSTS[tech])

static func research(state: Dictionary, progress: Dictionary,
        cell: Vector2i, tech: String) -> Dictionary:
    var denied := {"valid":false,"state":state.duplicate(true),
        "progress":progress.duplicate(true)}
    if not can_research(state,progress,cell,tech):
        return denied
    var result: Dictionary = state.duplicate(true)
    var trail: Dictionary = progress.duplicate(true)
    var side: int = int(state["faction"])
    var cost: int = int(TECH_COSTS[tech])
    result["economy"]["credits"][side] = int(result["economy"]["credits"][side])-cost
    var facility: Dictionary = Economy.site_at(result["economy"],cell)
    facility["produced_turn"] = int(result["economy"]["turn"])
    if not trail.has("techs"):
        trail["techs"] = {}
    if not trail["techs"].has(str(side)):
        trail["techs"][str(side)] = {}
    trail["techs"][str(side)][tech] = true
    Opening.record(result)
    return {"valid":true,"state":result,"progress":trail,"action":"research",
        "technology":tech,"cost":cost,"reason":"experimental_global_tech"}

static func attack(state: Dictionary, progress: Dictionary,
        attacker_id: String, defender_id: String) -> Dictionary:
    var side: int = int(state.get("faction",-1))
    if has_tech(progress,side,"antiarmor_v1"):
        return Specialist.attack_antiarmor(state,attacker_id,defender_id,2)
    return Session.attack(state,attacker_id,defender_id)

static func repair(state: Dictionary, progress: Dictionary,
        engineer_id: String, patient_id: String, pack: String) -> Dictionary:
    if pack == "field" and not has_tech(progress,int(state.get("faction",-1)),"field_workshop"):
        return {"valid":false,"state":state.duplicate(true),
            "progress":progress.duplicate(true)}
    var attempt: Dictionary = Specialist.field_repair(state,engineer_id,patient_id,pack)
    if bool(attempt.get("valid",false)):
        attempt["progress"] = progress.duplicate(true)
    return attempt

# Explicit step boundary: avoid transferring an upgraded producer to an
# enemy after capture. The production game will need this in real saves.
static func reconcile(state: Dictionary, progress: Dictionary) -> Dictionary:
    var result: Dictionary = progress.duplicate(true)
    var facilities: Dictionary = result.get("facilities",{})
    if not state.has("economy"):
        return result
    for site in state["economy"].get("sites",[]):
        if not site is Dictionary or str(site.get("kind","")) not in UPGRADE_COSTS:
            continue
        var key: String = _tag(site)
        if facilities.has(key) and int(facilities[key].get("owner",-99)) != int(site.get("owner",-1)):
            facilities.erase(key)
    result["facilities"] = facilities
    return result

static func end_turn(state: Dictionary, progress: Dictionary) -> Dictionary:
    var ended: Dictionary = Session.end_turn(state)
    if not bool(ended.get("valid",false)):
        ended["progress"] = progress.duplicate(true)
        return ended
    ended["progress"] = reconcile(ended["state"],progress)
    return ended

static func missing_catalog_roles() -> Array:
    var missing: Array = []
    for role in Roles.ORDER:
        if not ROLE_LEVELS.has(role):
            missing.append(role)
    for role in Arsenal.ORDER:
        if not ROLE_LEVELS.has(role):
            missing.append(role)
    return missing
