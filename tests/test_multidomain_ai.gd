extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _unit(id: String, faction: int, pos: Vector2i, domain: String, targets: Array, hp: int = 10) -> Dictionary:
    var unit: Dictionary = Roles.make_unit(id, faction, pos, "line")
    unit["domain"] = domain
    unit["target_domains"] = targets.duplicate()
    unit["hp"] = hp
    return unit

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(2)
    var flier: Dictionary = _unit("A",0,Vector2i(3,3),"air",["ground"])
    var soldier: Dictionary = _unit("X",1,Vector2i(6,3),"ground",["ground"])
    var in_air: Dictionary = Session.start([flier,soldier],terrain)
    var air_observation: Dictionary = Visibility.observed_state(in_air,0)
    assert(AI._blocked_for(air_observation,flier).is_empty())
    var old: Dictionary = in_air.duplicate(true)
    var advance: Dictionary = AI.step(in_air)
    assert(advance["valid"] and advance["action"] == "move")
    assert(advance["unit_id"] == "A")
    assert(Rules.movement_cost_for(str(terrain[advance["destination"].y][advance["destination"].x]),"air") >= 0)
    assert(int(advance["state"]["units"][0]["faction"]) == 0)
    assert(advance["state"]["units"][0]["moved"])
    assert(in_air == old)
    assert(Codec.decode(Codec.encode(advance["state"])) == advance["state"])
    assert(Domains.can_attack(flier,soldier))
    var followup: Dictionary = AI.step(advance["state"])
    assert(followup["valid"] and followup["action"] == "attack")
    assert(followup["state"]["units"][1]["hp"] < soldier["hp"])

    # Air may be directly above a soldier: enemy path planning must not
    # treat the different vertical layer as a blocked air tile.
    var ground_friend: Dictionary = _unit("G",0,Vector2i(3,3),"ground",["ground"])
    var shared: Dictionary = Session.start([ground_friend,flier,soldier],terrain)
    var air_blockers: Array[Vector2i] = AI._blocked_for(Visibility.observed_state(shared,0),flier)
    assert(not Vector2i(3,3) in air_blockers)
    assert(Codec.decode(Codec.encode(shared)) == shared)
    var movement: Dictionary = AI.step(shared)
    assert(movement.get("valid",false))
    assert(movement.get("unit_id","") in ["A","G"])
    assert(not Codec.encode(movement["state"]).is_empty())

    # Ships navigate only water lanes. Before this update the AI used
    # ground movement costs and could never pursue targets in open water.
    var boat: Dictionary = _unit("S",0,Vector2i(4,3),"naval",["naval"])
    var hostile: Dictionary = _unit("Z",1,Vector2i(5,4),"naval",["naval"])
    var sea: Dictionary = Session.start([boat,hostile],terrain)
    assert(AI._blocked_for(Visibility.observed_state(sea,0),boat) == [Vector2i(5,4)])
    var sea_action: Dictionary = AI.step(sea)
    assert(sea_action["valid"] and sea_action["action"] == "move")
    assert(sea_action["unit_id"] == "S")
    var sea_pos: Vector2i = sea_action["destination"]
    assert(terrain[sea_pos.y][sea_pos.x] == "water")
    assert(sea_action["state"]["units"][0]["pos"] == sea_pos)
    assert(Codec.decode(Codec.encode(sea_action["state"])) == sea_action["state"])
    var naval_strike: Dictionary = AI.step(sea_action["state"])
    assert(naval_strike["valid"] and naval_strike["action"] == "attack")
    assert(naval_strike["state"]["units"][1]["hp"] < hostile["hp"])

    # Aerial recon and naval troops cannot walk to a relay as if infantry,
    # irrespective of their target_domains or how many tiles they can fly.
    var relay_air: Dictionary = _unit("F",0,Vector2i(4,2),"air",["ground"])
    var remote: Dictionary = _unit("X",1,Vector2i(8,6),"ground",["ground"])
    var relay_state: Dictionary = Session.start([relay_air,remote],Scenarios.terrain(0),0,false,true)
    var info: Dictionary = Visibility.observed_state(relay_state,0)
    assert(not AI._advance_relay(relay_state,info,[relay_air],[relay_air["pos"],remote["pos"]])["valid"])
    var ended: Dictionary = Session.end_turn(relay_state)
    assert(ended["state"]["control"]["nodes"][0]["owner"] == -1)

    # Fog changes to unseen enemy positions and HP cannot alter observed
    # search decisions even for mobile aircraft.
    var hidden_enemy: Dictionary = soldier.duplicate(true)
    hidden_enemy["pos"] = Vector2i(8,3) # Beyond vision radius 3.
    var fog_air: Dictionary = Session.start([flier,hidden_enemy],terrain,0,true)
    var shifted: Dictionary = fog_air.duplicate(true)
    shifted["units"][1]["pos"] = Vector2i(8,4)
    shifted["units"][1]["hp"] = 2
    shifted = Visibility.update_exploration(shifted)
    assert(not Visibility.is_unit_visible(fog_air,0,"X"))
    assert(not Visibility.is_unit_visible(shifted,0,"X"))
    var fog_plan: Dictionary = AI.step(fog_air)
    var fog_plan_shifted: Dictionary = AI.step(shifted)
    assert(fog_plan.get("valid",false) == fog_plan_shifted.get("valid",false))
    assert(fog_plan.get("action","none") == fog_plan_shifted.get("action","none"))
    assert(fog_plan.get("destination",Vector2i(-1,-1)) == fog_plan_shifted.get("destination",Vector2i(-1,-1)))

    # Ground-only legacy movement/retreat and targeting remain unchanged.
    var classic: Dictionary = Session.start(Roles.experimental_armies(true),Scenarios.terrain(0))
    assert(not Codec.encode(classic).contains("domain"))
    assert(Codec.decode(Codec.encode(classic)) == classic)
    print("PASS multidomain AI: legal air/sea pursuit, no cross-layer blockers, relay integrity and fog fairness")
    quit(0)
