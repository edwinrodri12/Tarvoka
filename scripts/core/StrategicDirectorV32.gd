extends RefCounted
class_name TarvokaStrategicDirectorV32

# Opt-in P0 AI director. Pure, local, deterministic and based EXCLUSIVELY
# on the caller's Visibility.observed_state snapshot. No save fields.
# 12 actual profiles adjust priorities/budgets, NOT units, money or vision.
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Supply = preload("res://scripts/core/SupplyStrategy.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const LEVEL_NAMES := [
    "Recluta","Cadete","Cabo","Sargento",
    "Teniente","Capitán","Mayor","Coronel",
    "General","Estratega","Mariscal","Leyenda"
]
const STYLES := [
    "adaptive","balanced","expansion","fortress","blitz",
    "combined_arms","recon","siege","air_control","naval_control",
    "attrition"
]

# Every producible domain has a strategic use. Effects that are NOT in the
# current rules (cargo, EW, sonar, paid technology) are NOT fabricated.
const PRODUCTION := {
    "balanced":{
        "factory":["scout","assault","engineer","line","logistics"],
        "armor_plant":["ifv","tank","apc","piercer","bulwark"],
        "artillery_depot":["spg","mobile_aa","artillery","sam","mlrs","ew"],
        "drone_center":["uav_recon","fpv","loitering"],
        "airbase":["fighter","attack_heli","ucav","bomber","transport_heli"],
        "shipyard":["patrol","corvette","missile_boat","frigate","submarine","destroyer","usv","landing_ship"]
    },
    "expansion":{
        "factory":["scout","assault","engineer","line","logistics"],
        "armor_plant":["apc","ifv","tank","piercer","bulwark"]
    },
    "fortress":{
        "factory":["line","engineer","assault","scout","logistics"],
        "armor_plant":["bulwark","piercer","tank","ifv","apc"],
        "artillery_depot":["mobile_aa","sam","spg","artillery","mlrs","ew"]
    },
    "blitz":{
        "factory":["assault","scout","line","engineer","logistics"],
        "armor_plant":["ifv","tank","apc","piercer","bulwark"],
        "drone_center":["fpv","loitering","uav_recon"]
    },
    "combined_arms":{
        "factory":["assault","line","scout","engineer","logistics"],
        "armor_plant":["ifv","piercer","tank","apc","bulwark"],
        "artillery_depot":["spg","mobile_aa","artillery","sam","mlrs","ew"],
        "drone_center":["uav_recon","fpv","loitering"]
    },
    "recon":{
        "factory":["scout","assault","line","engineer","logistics"],
        "drone_center":["uav_recon","fpv","loitering"]
    },
    "siege":{
        "factory":["line","assault","engineer","scout","logistics"],
        "artillery_depot":["spg","artillery","mlrs","sam","mobile_aa","ew"],
        "armor_plant":["bulwark","tank","ifv","piercer","apc"]
    },
    "air_control":{
        "factory":["assault","line","scout","logistics","engineer"],
        "airbase":["fighter","attack_heli","ucav","bomber","transport_heli"],
        "artillery_depot":["mobile_aa","sam","spg","artillery","mlrs","ew"]
    },
    "naval_control":{
        "factory":["assault","line","scout","engineer","logistics"],
        "shipyard":["patrol","corvette","missile_boat","frigate","submarine","destroyer","usv","landing_ship"],
        "airbase":["fighter","ucav","attack_heli","bomber","transport_heli"]
    },
    "attrition":{
        "factory":["line","logistics","assault","scout","engineer"],
        "armor_plant":["bulwark","ifv","piercer","tank","apc"],
        "artillery_depot":["spg","artillery","mobile_aa","sam","mlrs","ew"]
    }
}

static func valid_style(style: String) -> bool:
    return style in STYLES

static func level_profile(level: int) -> Dictionary:
    if level < 1 or level > LEVEL_NAMES.size():
        return {}
    return {
        "level":level,
        "name":str(LEVEL_NAMES[level-1]),
        "tactical_risk_awareness":level >= 4,
        "observed_counterplay":level >= 6,
        "economic_specialization":level >= 3,
        "balanced_composition":level >= 7,
        "multi_objective":level >= 9,
        "terrain_aware":level >= 5,
        "style_adaptation":level >= 6,
        # Each level changes a real policy input, but not the rules.
        "city_weight":300+level*140,
        "base_weight":180+level*85,
        "enemy_threat_weight":20+level*12,
        "recruitment_diversity":1+(level-1)/3,
        "capture_threshold":1+(level+1)/4
    }

static func _role_counts(knowledge: Dictionary, side: int) -> Dictionary:
    var counts: Dictionary = {}
    for unit in knowledge.get("units",[]):
        if int(unit.get("hp",0)) <= 0 or int(unit.get("faction",-1)) != side:
            continue
        var role: String = str(unit.get("role",""))
        counts[role] = int(counts.get(role,0))+1
    return counts

static func choose(knowledge: Dictionary, side: int,
        options: Dictionary = {}) -> Dictionary:
    if side not in [0,1] or not Rules.valid_terrain(knowledge.get("terrain",[])):
        return {"valid":false}
    var level: int = clampi(int(options.get("ai_level",5)),1,12)
    var profile: Dictionary = level_profile(level)
    var requested: String = str(options.get("ai_style","adaptive"))
    if not valid_style(requested):
        return {"valid":false,"reason":"unknown_strategy"}
    var economy: Dictionary = knowledge.get("economy",{})
    var counts: Dictionary = _role_counts(knowledge,side)
    var own_units := 0
    var visible_enemies := 0
    var visible_armor := 0
    var visible_air := 0
    var visible_naval := 0
    var capturers := 0
    var own_cities := 0
    var neutral_cities := 0
    var hostile_near_home := 0
    var own_producers: Dictionary = {}
    var sites: Array = economy.get("sites",[])
    for site in sites:
        if int(site.get("owner",-2)) == side:
            var kind: String = str(site.get("kind",""))
            if kind == "city":
                own_cities += 1
            else:
                own_producers[kind] = int(own_producers.get(kind,0))+1
        elif int(site.get("owner",-2)) == -1 and str(site.get("kind","")) == "city":
            neutral_cities += 1
    for unit in knowledge.get("units",[]):
        if int(unit.get("hp",0)) <= 0:
            continue
        if int(unit.get("faction",-1)) == side:
            own_units += 1
            if Economy.can_capture(unit):
                capturers += 1
        else:
            visible_enemies += 1
            if str(unit.get("role","")) in ["tank","bulwark","ifv","apc"]:
                visible_armor += 1
            if Domains.domain(unit) == Domains.AIR:
                visible_air += 1
            if Domains.domain(unit) == Domains.NAVAL:
                visible_naval += 1
            for s in sites:
                if int(s.get("owner",-2)) == side and \
                        abs(int(s["pos"].x)-int(unit["pos"].x))+ \
                        abs(int(s["pos"].y)-int(unit["pos"].y)) <= 3:
                    hostile_near_home += 1
                    break
    var logistics: Dictionary = Supply.assess(knowledge,side)
    var style: String = requested
    if requested == "adaptive":
        style = "balanced"
        if level >= 6 and hostile_near_home >= 2:
            style = "fortress"
        elif level >= 6 and visible_armor >= 2:
            style = "combined_arms"
        elif level >= 7 and visible_air > 0:
            style = "air_control"
        elif level >= 7 and visible_naval > 0 and own_producers.has("shipyard"):
            style = "naval_control"
        elif level >= 4 and neutral_cities > 0 and capturers < 3:
            style = "expansion"
        elif level >= 9 and neutral_cities == 0 and own_producers.has("artillery_depot"):
            style = "siege"
    # A forced named style is a legitimate personality, not a handicap.
    # When a relevant facility is unavailable, buying priority falls back
    # to actual owned sites and never creates it.
    var rationale: String = "plan_"+style
    return {
        "valid":true,"level":level,"difficulty":profile["name"],
        "style":style,"requested_style":requested,
        "rationale":rationale,"profile":profile,
        "counts":counts,"own_units":own_units,"capturers":capturers,
        "visible_enemies":visible_enemies,"visible_armor":visible_armor,
        "visible_air":visible_air,"visible_naval":visible_naval,
        "hostile_near_home":hostile_near_home,
        "own_cities":own_cities,"neutral_cities":neutral_cities,
        "owned_producers":own_producers,
        "supply_need":bool(logistics.get("need_truck",false)),
        "city_weight":int(profile["city_weight"]),
        "base_weight":int(profile["base_weight"]),
        "style_capture_bonus": 2000 if style == "expansion" else 0,
        # Advisory ONLY: progression is not an authoritative Session action.
        "development_intent":_development_intent(style,own_producers),
        "available_actions":["move","attack","purchase","resupply","end_turn"]
    }

static func _development_intent(style: String,
        owned: Dictionary) -> Array:
    var candidates: Array = []
    if style in ["combined_arms","blitz","fortress"] and owned.has("armor_plant"):
        candidates.append("armor_plant_level2")
    if style in ["siege","attrition"] and owned.has("artillery_depot"):
        candidates.append("artillery_depot_level2")
    if style == "air_control" and owned.has("airbase"):
        candidates.append("airbase_level2")
    if style == "naval_control" and owned.has("shipyard"):
        candidates.append("shipyard_level2")
    return candidates

static func _promote(base: Array, role: String) -> Array:
    var result: Array = [role]
    for item in base:
        if str(item) != role:
            result.append(item)
    return result

static func production_priorities(plan: Dictionary,
        logistics: Dictionary, counts: Dictionary) -> Dictionary:
    var style: String = str(plan.get("style","balanced"))
    var current: Dictionary = PRODUCTION.get(style,PRODUCTION["balanced"])
    var complete: Dictionary = {}
    for facility in PRODUCTION["balanced"]:
        complete[facility] = current.get(facility,
            PRODUCTION["balanced"][facility]).duplicate()
    var profile: Dictionary = plan.get("profile",{})
    var level: int = int(profile.get("level",1))
    var capturers: int = int(plan.get("capturers",0))
    var neutral: int = int(plan.get("neutral_cities",0))
    if bool(logistics.get("need_truck",false)):
        complete["factory"] = _promote(complete["factory"],"logistics")
    elif neutral > 0 and capturers < int(profile.get("capture_threshold",2)):
        complete["factory"] = _promote(complete["factory"],"scout")
    if level >= 6 and bool(profile.get("observed_counterplay",false)):
        if int(plan.get("visible_air",0)) > 0:
            complete["artillery_depot"] = _promote(complete["artillery_depot"],"mobile_aa")
            complete["airbase"] = _promote(complete["airbase"],"fighter")
        if int(plan.get("visible_armor",0)) > 0:
            complete["armor_plant"] = _promote(complete["armor_plant"],"piercer")
            complete["drone_center"] = _promote(complete["drone_center"],"fpv")
    if level >= 7 and bool(profile.get("balanced_composition",false)):
        # Prioritize missing capabilities rather than creating a monotone
        # "buy one unit forever" pattern. Existing Economy remains final.
        for facility in complete:
            var fresh: Array = []
            var surplus: Array = []
            for role in complete[facility]:
                if int(counts.get(str(role),0)) >= int(profile.get("recruitment_diversity",2)):
                    surplus.append(role)
                else:
                    fresh.append(role)
            fresh.append_array(surplus)
            complete[facility] = fresh
    # Planned units are REAL roles with REAL corresponding facilities.
    for facility in complete:
        var legal: Array = []
        for role in complete[facility]:
            if Economy.producer_for(str(role),true) == str(facility) and \
                    str(role) not in legal:
                legal.append(str(role))
        complete[facility] = legal
    return complete

static func site_bonus(plan: Dictionary, kind: String) -> int:
    if not bool(plan.get("valid",false)):
        return 0
    var style: String = str(plan.get("style","balanced"))
    if kind == "city":
        return int(plan.get("city_weight",0)) + \
            (5000 if style == "expansion" else 0)
    if style == "siege" or style == "combined_arms":
        return int(plan.get("base_weight",0)) + 4000
    if style == "fortress":
        return int(plan.get("base_weight",0)) + 2500
    return int(plan.get("base_weight",0))
