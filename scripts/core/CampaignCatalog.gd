extends RefCounted
class_name TarvokaCampaignCatalog

# Campaign metadata for narrative planning/validation; this file does NOT
# activate C02-C50 in the Android menu and does not alter battle mechanics.
# Keep a separate pure-data record so no feature gets lost from story planning.
const FACTIONS = ["alianza_norte","pacto_escarlata","union_verde","confederacion_solar","sindicato_violeta","legion_ambar","dominio_turquesa","orden_onix"]
const MAP_SIZES = {"10x8":Vector2i(10,8),"24x18":Vector2i(24,18),"40x30":Vector2i(40,30)}
# All chapter UIs inherit these existing battle features; the story screen
# must wire them later without bypassing fog, movement or confirmed orders.
const UNIVERSAL_PRESENTATION = ["isometric_camera","pinch_zoom","pan","minimap","battle_vfx","tactical_overlay","enemy_inspect","save_resume","battle_report","faction_colors"]
const ENGINE_FEATURES = ["ai","air","ammo","attack","capture","city_income","counterfire","doctrine","domains","drone_consumable","enemy_inspect","flank","fog","fog_contacts","fuel","height","initiative","large_map","minimap","movement","naval","opening","production","range","relays","resupply","seeded_map","tactical_overlay","terrain","truck"]
const MISSING_CAPABILITIES = ["mission_hud","story_dialogue_ui","campaign_progress_save","repair_action","transport_cargo","sonar_detection","ew_action","naval_supply_action","multifaction_alliance","level_upgrade_tree","veterancy_xp"]
const OPTIONAL_UNLOCKS = ["M09"]
# Each record: id|title|story faction|objective|planned map size|new
# family|profile/tech|existing core feature tags|missing story hooks.
const DATA = [
    "C01|Escudo compartido|alianza_norte|hold_two_beacons|10x8|G01|-|movement,attack,counterfire,capture,terrain,tactical_overlay,ai|campaign_screen,mission_turn_bridge",
    "C02|Dos minutos de silencio|orden_onix|recon_extract|10x8|G03|-|movement,fog,fog_contacts,enemy_inspect,ai|recon_objective,extraction_action,campaign_screen",
    "C03|Nudo Siete|sindicato_violeta|repair_grid|10x8|G05|-|movement,capture,city_income,terrain|repair_action,multiobjective,campaign_screen",
    "C04|Convoy perdido|pacto_escarlata|recover_convoy|10x8|G04|-|movement,attack,counterfire,doctrine,terrain|escort_objective,inspection_action",
    "C05|Los primeros evacuados|union_verde|evacuate|10x8|-|G01/urbano|movement,capture,height,terrain|evacuation_objective,civilian_markers",
    "C06|Informe incompleto|confederacion_solar|deliver_supply|10x8|G16|-|movement,fuel,ammo,resupply,truck|delivery_action,mission_supply_stock",
    "C07|Un puerto cerrado|dominio_turquesa|inspect_port|10x8|M01|-|movement,naval,domains,fog|inspection_action,neutral_naval_contacts",
    "C08|La orden|legion_ambar|hold_pass|10x8|G06|-|movement,attack,counterfire,height,flank,terrain|hold_objective,choice_flags",
    "C09|Setenta y dos horas|alianza_norte|defend_depot|10x8|G11|-|movement,attack,range,ammo,tactical_overlay,terrain|defend_objective,choice_flags",
    "C10|El primer disparo oficial|pacto_escarlata|capture_crossing|24x18|-|-|movement,capture,initiative,attack,counterfire,terrain|capture_objective,choice_flags",
    "C11|Un puente para nadie|alianza_norte|take_bridge|24x18|G07|-|movement,capture,terrain,height,city_income|bridge_damage,objective_override",
    "C12|Las reservas del valle|union_verde|protect_reservoir|24x18|-|G07/VCI|movement,capture,city_income,terrain,fog|defend_objective",
    "C13|Suelo de ceniza|confederacion_solar|hold_refinery|24x18|-|G06/tanque|movement,fuel,ammo,attack,resupply,doctrine|refinery_objective",
    "C14|Turno de noche|sindicato_violeta|defend_factory|24x18|-|G11/autopropulsada|movement,capture,production,city_income,ammo|production_goal",
    "C15|Mar de separación|dominio_turquesa|land_troops|24x18|M07|-|movement,naval,domains,capture,attack|transport_cargo,landing_action",
    "C16|Posiciones imposibles|legion_ambar|hold_mountains|40x30|-|G11/cohetes|movement,height,flank,range,seeded_map,terrain|hold_objective",
    "C17|Las voces del apagón|orden_onix|restore_relay|24x18|A01|-|movement,fog,fog_contacts,relays,ai|relay_intel_objective",
    "C18|No cruzar la línea|pacto_escarlata|capture_city|24x18|G13|-|movement,air,domains,counterfire,terrain,capture|urban_objective",
    "C19|El invierno en ruta|union_verde|escort_food|24x18|-|-|movement,truck,fuel,resupply,ammo|escort_objective",
    "C20|El estrecho vacío|dominio_turquesa|control_strait|40x30|M03|M01/misiles|naval,domains,attack,counterfire,large_map,minimap,production|strait_objective",
    "C21|Una guerra rentable|sindicato_violeta|secure_industry|24x18|G15|-|movement,production,city_income,truck,fuel|ew_action,mission_economy_story",
    "C22|La ciudad que se negó|pacto_escarlata|negotiate_siege|24x18|A02|-|movement,capture,terrain,drone_consumable|surrender_objective",
    "C23|Agua por combustible|union_verde|protect_dam|24x18|A06|-|movement,fuel,resupply,truck,air|air_transport_cargo,evacuation_objective",
    "C24|El relevo no llegó|alianza_norte|tactical_retreat|24x18|-|G13/SAM|movement,terrain,range,ammo,flank|withdrawal_objective",
    "C25|Alas sobre las cenizas|confederacion_solar|air_corridor|24x18|A05|-|air,domains,ammo,fuel,range,counterfire|air_defense_objective",
    "C26|Los que no tienen bandera|orden_onix|humanitarian_route|24x18|-|A02/merodeadora|movement,fog,drone_consumable,enemy_inspect|humanitarian_objective",
    "C27|Silencio en cubierta|dominio_turquesa|find_missing_fleet|40x30|M09|-|naval,domains,fog,fog_contacts,resupply,large_map|naval_supply_action,escort_objective",
    "C28|Dos órdenes contrarias|legion_ambar|split_orders|24x18|-|-|movement,height,terrain,opening|split_order_choice",
    "C29|Las cifras del enemigo|sindicato_violeta|extract_evidence|40x30|A04|-|movement,fog,fog_contacts,drone_consumable|evidence_objective",
    "C30|La victoria que nos separó|alianza_norte|alliance_fracture|40x30|-|-|movement,attack,counterfire,large_map,minimap,terrain|consequence_flags",
    "C31|Nueve minutos|orden_onix|trace_signal|24x18|-|-|fog,relays,enemy_inspect,fog_contacts|timeline_reconstruction",
    "C32|El proyectil ausente|alianza_norte|retrieve_archive|24x18|A07|-|movement,air,domains,ammo,fuel,enemy_inspect|archive_objective",
    "C33|Piezas de otro origen|pacto_escarlata|recover_wreck|40x30|M06|-|naval,domains,fog,enemy_inspect|sonar_detection,wreck_recovery",
    "C34|Certificados|confederacion_solar|hold_maintenance_logs|24x18|-|-|movement,terrain,production,city_income|maintenance_log_objective,repair_action",
    "C35|Una grabación auténtica|sindicato_violeta|recover_broadcast|24x18|-|-|movement,fog,fog_contacts,enemy_inspect|broadcast_capture",
    "C36|La ruta de los testigos|union_verde|escort_witnesses|24x18|-|-|movement,fog,air,domains|witness_escort",
    "C37|Puertos para una tregua|dominio_turquesa|open_aid_port|40x30|-|M03/fragata|naval,domains,fog,relays,ai|aid_route_objective,sonar_detection",
    "C38|El enemigo al lado|alianza_norte|coalition_defense|40x30|A08|-|air,domains,attack,counterfire,range,flank|temporary_alliance",
    "C39|Consecuencias de la verdad|legion_ambar|prevent_mutiny|40x30|M05|-|naval,domains,attack,counterfire,large_map|mutiny_objective,coalition_naval_support",
    "C40|El expediente completo|orden_onix|publish_evidence|40x30|M08|-|naval,domains,fog,relays,enemy_inspect|evidence_broadcast",
    "C41|Nadie da el primer paso|union_verde|separate_armies|24x18|-|-|movement,terrain,capture,opening|negotiation_standoff",
    "C42|Cuentas pendientes|sindicato_violeta|feed_city|24x18|-|-|movement,production,city_income,fuel,resupply,truck|food_distribution",
    "C43|La marcha del regreso|legion_ambar|withdrawal|24x18|-|-|movement,fuel,truck,terrain|extraction_objective,transport_cargo",
    "C44|Los últimos barcos|dominio_turquesa|escort_medical_fleet|40x30|-|-|naval,domains,ammo,fuel,resupply|medical_convoy_escort",
    "C45|La fortaleza vacía|pacto_escarlata|cede_base|24x18|-|-|movement,capture,terrain,city_income|ceding_base_choice",
    "C46|El mapa de los ausentes|confederacion_solar|power_two_fronts|24x18|-|-|movement,air,domains,fuel,drone_consumable|power_distribution",
    "C47|La última orden|alianza_norte|stop_offensive|24x18|-|-|movement,range,attack,counterfire,height,flank|stop_friendly_offensive",
    "C48|Siete puentes|orden_onix|secure_seven_bridges|40x30|-|-|movement,capture,relays,terrain,fog|bridge_network_objectives",
    "C49|Meridian resiste|coalicion|joint_battle|40x30|-|-|movement,naval,air,domains,ammo,fuel,production,resupply,ai,large_map,minimap,opening|coalition_scenario,multiobjective",
    "C50|El precio de la paz|coalicion|branch_finale|40x30|-|-|movement,naval,air,domains,capture,city_income,relays,ai,large_map|branch_finale,ending_resolution"
]

static func all() -> Array:
    var chapters: Array = []
    for record in DATA:
        var fields: PackedStringArray = str(record).split("|",true)
        if fields.size() != 9:
            return []
        chapters.append({
            "id":str(fields[0]),"title":str(fields[1]),
            "faction":str(fields[2]),"objective":str(fields[3]),
            "map_size":str(fields[4]),"unlock":str(fields[5]),
            "tech_profile":str(fields[6]),
            "engine_features":Array(fields[7].split(",",false)),
            "pending_hooks":Array(fields[8].split(",",false)),
            "status":"engine_core_only" if fields[0] == "C01" else "design_only"
        })
    return chapters

static func chapter(chapter_id: String) -> Dictionary:
    for entry in all():
        if str(entry["id"]) == chapter_id:
            return (entry as Dictionary).duplicate(true)
    return {}

static func features_used() -> Array:
    var found: Dictionary = {}
    for chapter_data in all():
        for name in chapter_data["engine_features"]:
            found[str(name)] = true
    return found.keys()

static func validate() -> bool:
    var entries: Array = all()
    if entries.size() != 50 or FACTIONS.size() != 8 or MAP_SIZES.size() != 3:
        return false
    var known: Dictionary = {}
    var seen: Dictionary = {}
    for feature in ENGINE_FEATURES:
        known[feature] = true
    var unlocked: Dictionary = {}
    var factions: Dictionary = {}
    var cumulative: Array = []
    for i in range(entries.size()):
        var c: Dictionary = entries[i]
        if str(c.get("id","")) != "C%02d" % [i+1] or not str(c.get("faction","")) in FACTIONS + ["coalicion"]:
            return false
        if str(c.get("title","")).is_empty() or not MAP_SIZES.has(str(c.get("map_size",""))):
            return false
        if str(c.get("objective","")).is_empty() or (c.get("engine_features",[]) as Array).is_empty():
            return false
        factions[str(c["faction"])] = true
        for feature in c["engine_features"]:
            if not known.has(str(feature)):
                return false
            seen[str(feature)] = true
        var unit: String = str(c.get("unlock","-"))
        if unit != "-":
            if unlocked.has(unit):
                return false
            unlocked[unit] = true
        if (i+1) in [10,20,30,40,50]:
            cumulative.append(unlocked.size())
    if factions.size() != 9 or unlocked.size() != 24 or cumulative != [8,13,19,24,24]:
        return false
    for feature in ENGINE_FEATURES:
        if not seen.has(feature):
            return false
    if str(chapter("C01").get("objective","")) != "hold_two_beacons":
        return false
    if str(chapter("C01").get("status","")) != "engine_core_only":
        return false
    return true

static func required_ui() -> Array:
    return UNIVERSAL_PRESENTATION.duplicate()
