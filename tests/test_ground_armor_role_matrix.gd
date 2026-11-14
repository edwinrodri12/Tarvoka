extends SceneTree

# Inspectable cross-role battle evidence. The test deliberately runs genuine
# Godot BattleSession.attack and preview_exchange instead of a spreadsheet
# damage formula. No cargo/transport bonuses are assumed or invented.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const ROLES := ["apc","ifv","piercer","tank"]
const GROUNDS := ["plain","road","forest","mountain","city","high_ground"]
const CLIMATES := ["clear","rain","snow"]

static func _state_for(attacker_role: String, defender_role: String,
        ground: String, climate: String, side: int) -> Dictionary:
    var terrain: Array = Scenarios.terrain(0)
    var home := Vector2i(2,2) if side == 0 else Vector2i(7,2)
    var enemy := Vector2i(3,2) if side == 0 else Vector2i(6,2)
    if ground == "city":
        home = Vector2i(2,4) if side == 0 else Vector2i(7,4)
        enemy = Vector2i(3,4) if side == 0 else Vector2i(6,4)
    elif ground == "high_ground":
        terrain[home.y][home.x] = "mountain"
    elif ground != "plain":
        terrain[enemy.y][enemy.x] = ground
    return Session.start([
        Roles.make_unit("A",side,home,attacker_role),
        Roles.make_unit("D",1-side,enemy,defender_role)
    ],terrain,side,false,false,true,true,false,climate)

static func _mobility_map() -> Array:
    var terrain: Array = Scenarios.terrain(0)
    for x in range(10):
        terrain[3][x] = "road"
        if x >= 2 and x <= 7:
            terrain[2][x] = "forest"
    for x in range(3,7):
        terrain[4][x] = "mountain"
    return terrain

func _initialize() -> void:
    assert(ROLES.size() == 4)
    var sources: Dictionary = {}
    var role_metrics: Dictionary = {}
    for role in ROLES:
        var actor: Dictionary = Roles.make_unit("Q",0,Vector2i(1,3),role)
        assert(not actor.is_empty())
        var max_hp := int(actor["hp"])
        var price := Economy.cost(role)
        var armor := "foot" if role == "piercer" else Weather.traction(actor)
        assert(price > 0 and max_hp > 0)
        role_metrics[role] = {
            "cost":price,"hp":max_hp,"attack":int(actor["attack"]),
            "defense":int(actor["defense"]),"move":int(actor["move_points"]),
            "vision":int(actor["vision"]),
            "ammo":Logistics.ammo_capacity(role),
            "fuel":Logistics.fuel_capacity(role),
            "traction":armor,
            "cost_per_hp":snappedf(float(price)/float(max_hp),0.01),
            "producer":Economy.producer_for(role,true),
            "can_capture":Economy.can_capture(actor)
        }
        assert(Economy.producer_for(role,true) == "armor_plant")
        assert(not Economy.can_capture(actor))
        assert(not actor.has("cargo")) # Loading/unloading is NOT yet a real action.

    var count := 0
    var pair_rows: Array = []
    for attacker_role in ROLES:
        for defender_role in ROLES:
            for ground in GROUNDS:
                for climate in CLIMATES:
                    var signature := "%s:%s:%s:%s" % [
                        attacker_role,defender_role,ground,climate]
                    for side in [0,1]:
                        var state: Dictionary = _state_for(attacker_role,
                            defender_role,ground,climate,side)
                        assert(Economy.valid(state["economy"],state["terrain"]))
                        var input_copy: Dictionary = state.duplicate(true)
                        var attacker: Dictionary = state["units"][0]
                        var defender: Dictionary = state["units"][1]
                        assert(Logistics.valid_unit(attacker) and
                            Logistics.valid_unit(defender))
                        assert(Domains.domain(attacker) == Domains.GROUND and
                            Domains.domain(defender) == Domains.GROUND)
                        var preview: Dictionary = Actions.preview_exchange(
                            attacker,defender,true,state["terrain"],
                            state["economy"],state["units"])
                        assert(preview.get("valid",false))
                        var real: Dictionary = Session.attack(state,"A","D")
                        assert(real.get("valid",false))
                        assert(real["damage"] == preview["damage"])
                        assert(real["counter_damage"] == preview["counter_damage"])
                        assert(int(real["state"]["units"][0]["hp"]) ==
                            int(preview["attacker_hp"]))
                        assert(int(real["state"]["units"][1]["hp"]) ==
                            int(preview["defender_hp"]))
                        assert(int(real["state"]["units"][0]["ammo"]) ==
                            Logistics.ammo_capacity(attacker_role)-1)
                        var expected_return_ammo: int = Logistics.ammo_capacity(
                            defender_role) - (1 if bool(real["counter_spent"]) else 0)
                        assert(int(real["state"]["units"][1]["ammo"]) ==
                            expected_return_ammo)
                        assert(state == input_copy)
                        assert(Codec.decode(Codec.encode(real["state"])) ==
                            real["state"])
                        # Only inspect defensive public HP/role. The "AI fog"
                        # test is separate; no hidden enemy fuel data here.
                        var detail: Dictionary = {
                            "attacker":attacker_role,"defender":defender_role,
                            "ground":ground,"climate":climate,
                            "damage":int(real["damage"]),
                            "counter":int(real["counter_damage"]),
                            "attacker_left":int(real["state"]["units"][0]["hp"]),
                            "defender_left":int(real["state"]["units"][1]["hp"]),
                            "attacker_cost":Economy.cost(attacker_role),
                            "defender_cost":Economy.cost(defender_role),
                            "attack_per_100cr":snappedf(
                                float(real["damage"])*100.0/
                                float(Economy.cost(attacker_role)),0.001),
                            "attacker_survived":int(real["state"]["units"][0]["hp"]) > 0
                        }
                        if sources.has(signature):
                            # Faction-color swap must not change real combat.
                            assert(sources[signature]["damage"] == detail["damage"])
                            assert(sources[signature]["counter"] == detail["counter"])
                            assert(sources[signature]["attacker_left"] ==
                                detail["attacker_left"])
                            assert(sources[signature]["defender_left"] ==
                                detail["defender_left"])
                        else:
                            sources[signature] = detail
                            pair_rows.append(detail)
                        count += 1
    assert(count == 4*4*6*3*2)
    assert(pair_rows.size() == 4*4*6*3)

    var mobility: Array = []
    var travel_map: Array = _mobility_map()
    var origin := Vector2i(1,3)
    var free: Array[Vector2i] = []
    var mapped: Dictionary = {}
    for role in ROLES:
        for weather in CLIMATES:
            var piece: Dictionary = Roles.make_unit(
                "S",0,origin,role)
            Logistics.equip(piece)
            var reachable: Dictionary = Rules.reachable(
                origin,Logistics.movement_budget(piece),travel_map,free,
                Domains.GROUND,Logistics.road_fast(piece),free,weather,
                Weather.traction(piece))
            assert(not reachable.is_empty() and reachable.has(origin))
            var road_distance := 0
            var mountain_cells := 0
            var forest_cells := 0
            for pos in reachable:
                var cell: Vector2i = pos
                if cell.y == origin.y and cell.x > origin.x:
                    road_distance = maxi(road_distance,cell.x-origin.x)
                if travel_map[cell.y][cell.x] == "mountain":
                    mountain_cells += 1
                if travel_map[cell.y][cell.x] == "forest":
                    forest_cells += 1
            var line: Dictionary = {
                "role":role,"weather":weather,
                "reachable_endpoints":reachable.size()-1,
                "max_road_east":road_distance,
                "forest_cells":forest_cells,"mountain_cells":mountain_cells,
                "fuel_capacity":Logistics.fuel_capacity(role)
            }
            mobility.append(line)
            mapped[role+":"+weather] = line
    # APC is a fast, more durable screen in clear weather, but its wheeled
    # traction is intentionally slowed more by snow than IFV tracked armor.
    assert(int(mapped["apc:clear"]["max_road_east"]) >
        int(mapped["piercer:clear"]["max_road_east"]))
    assert(int(mapped["ifv:snow"]["max_road_east"]) >
        int(mapped["apc:snow"]["max_road_east"]))
    assert(int(mapped["apc:clear"]["reachable_endpoints"]) >
        int(mapped["piercer:clear"]["reachable_endpoints"]))
    assert(int(mapped["tank:clear"]["max_road_east"]) >=
        int(mapped["ifv:clear"]["max_road_east"]))

    var plain: Array = []
    for row in pair_rows:
        if row["ground"] == "plain" and row["climate"] == "clear":
            plain.append(row)
    assert(plain.size() == 16)
    var results := {
        "schema":"tarvoka.ground_armor_comparative.v1",
        "simulation_type":"actual_one_exchange_not_full_match_win_rate",
        "counter_status":"G09_piercer_plus_2_from_PR_328",
        "battle_exchanges":count,"paired_measurements":pair_rows.size(),
        "faction_mirror_pairs":int(count/2),
        "roles":role_metrics,"plain_matrix":plain,
        "terrain_weather_matrix":pair_rows,"mobility":mobility,
        "known_limitations":[
            "APC and IFV have no implemented infantry cargo; never count transport utility",
            "One attack exchange is not full-match win rate or production opportunity cost",
            "No faction modifiers or hidden-stat power"
        ]
    }
    print("GROUND_ARMOR_MATRIX_JSON "+JSON.stringify(results))
    print("PASS ground armor role matrix: %d real exchanges, 288 mirrored positions, weather mobility, costs, return fire, ammo and zero cargo claims" % count)
    quit(0)
