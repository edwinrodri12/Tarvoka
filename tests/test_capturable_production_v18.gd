extends SceneTree

# REAL BattleSession moves, end_turn, purchase and SaveCodec-backed snapshots.
# Extra fixed sites are a sidecar; the core game is kept compatible.
const Lab = preload("res://scripts/experiments/CapturableProductionV18.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

const ROLE_AT := {
    "factory":"line","armor_plant":"apc",
    "artillery_depot":"artillery","drone_center":"uav_recon",
    "airbase":"attack_heli","shipyard":"patrol"
}

func _initialize() -> void:
    var count := 0
    var dock_count := 0
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        for map_id in [0,1,2,3]:
            var generated: Dictionary = Sites.layout(Scenarios.terrain(map_id,dims))
            assert(generated.get("valid",false))
            var unique_types: Dictionary = {}
            for site in generated["sites"]:
                if str(site["kind"]) == "city" or int(site["owner"]) != -1:
                    continue
                var category: String = str(site["kind"])
                if unique_types.has(category):
                    continue
                unique_types[category] = true
                _capture_then_produce(dims,map_id,site)
                if category == "shipyard":
                    dock_count += 1
                count += 1
    assert(count >= 24)
    assert(dock_count >= 4)
    _save_guards()
    print("PASS capturable production v18: 8 maps, %d real-action factory captures and purchases across categories, %d waterfront dock captures, full sidecar save roundtrip" % [count,dock_count])
    quit(0)

static func _find(world: Dictionary, cell: Vector2i) -> Dictionary:
    for site in world["layout"]["sites"]:
        if site["pos"] == cell:
            return site
    return {}

static func _unit(units: Array, name: String) -> Dictionary:
    for u in units:
        if str(u.get("id","")) == name:
            return u
    return {}

static func _starting_army(terrain: Array, facility: Dictionary) -> Array:
    var dims: Vector2i = Rules.map_size(terrain)
    var objective: Vector2i = facility.get("capture_pos",facility["pos"])
    var soldier: Dictionary = Roles.make_unit("CAP",0,objective,"scout")
    var enemy_pos := Vector2i(dims.x-2,Scenarios.scale_y(3,dims))
    if enemy_pos == objective or str(terrain[enemy_pos.y][enemy_pos.x]) == "water":
        enemy_pos = Vector2i(dims.x-2,Scenarios.scale_y(2,dims))
    var enemy: Dictionary = Roles.make_unit("FOE",1,enemy_pos,"line")
    return [soldier,enemy]

static func _escape(terrain: Array, from: Vector2i, other: Vector2i) -> Vector2i:
    for direction in [Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT]:
        var cell: Vector2i = from+direction
        if not Rules.inside(cell,terrain) or cell == other:
            continue
        if Rules.movement_cost(str(terrain[cell.y][cell.x])) < 0:
            continue
        return cell
    return Vector2i(-1,-1)

static func _capture_then_produce(size: Vector2i,map_id: int,site: Dictionary) -> void:
    var terrain: Array = Scenarios.terrain(map_id,size)
    var army: Array = _starting_army(terrain,site)
    var world: Dictionary = Lab.start(map_id,size,0,army)
    assert(world.get("valid",false))
    assert(Economy.valid(world["state"]["economy"],world["state"]["terrain"]))
    var total_before: int = world["layout"]["sites"].size()
    var producer_before: int = int(world["layout"]["producers"])
    var where: Vector2i = site["pos"]
    assert(int(_find(world,where)["owner"]) == -1)
    assert(not Lab.purchase(world,where,str(ROLE_AT[site["kind"]])).get("valid",false))
    var started: Dictionary = world.duplicate(true)
    var progress1: Dictionary = Lab.end_turn(world)
    assert(progress1.get("valid",false))
    world = progress1["world"]
    assert(int(_find(world,where)["owner"]) == -1)
    assert(world["producer_holds"].size() == 1)
    assert(started["state"] != world["state"])
    var income_s1: int = int(world["layout"]["starting_income_each"])
    assert(int(world["state"]["economy"]["credits"][1]) == 2500+income_s1)
    var first_snapshot: String = Lab.encode(world)
    assert(not first_snapshot.is_empty())
    var restored: Dictionary = Lab.decode(first_snapshot)
    assert(restored.get("valid",false))
    assert(restored["producer_holds"] == world["producer_holds"])
    assert(restored["layout"]["sites"] == world["layout"]["sites"])
    world = restored
    var second: Dictionary = Lab.end_turn(world)
    assert(second.get("valid",false))
    world = second["world"]
    assert(int(_find(world,where)["owner"]) == -1)
    assert(world["producer_holds"].size() == 1)
    var third: Dictionary = Lab.end_turn(world)
    assert(third.get("valid",false))
    assert(int(third["captures"]) == 1)
    world = third["world"]
    assert(int(_find(world,where)["owner"]) == 0)
    assert(int(world["captured_bases"]) == 1)
    assert(world["producer_holds"].is_empty())
    assert(int(world["layout"]["producers"]) == producer_before)
    assert(world["layout"]["sites"].size() == total_before)
    var opponent: Dictionary = Lab.purchase(world,where,str(ROLE_AT[site["kind"]]))
    assert(not opponent.get("valid",false))
    var e: Dictionary = Lab.end_turn(world)
    assert(e.get("valid",false))
    world = e["world"]
    assert(int(world["state"]["faction"]) == 0)
    var infantry: Dictionary = _unit(world["state"]["units"],"CAP")
    var initial: Vector2i = infantry["pos"]
    if str(site["kind"]) != "shipyard":
        var next_cell: Vector2i = _escape(terrain,initial,_unit(world["state"]["units"],"FOE")["pos"])
        assert(next_cell.x >= 0)
        var moved: Dictionary = Lab.move(world,"CAP",next_cell)
        assert(moved.get("valid",false))
        world = moved["world"]
        assert(_unit(world["state"]["units"],"CAP")["pos"] == next_cell)
    var amount: int = int(world["state"]["economy"]["credits"][0])
    var requested: String = str(ROLE_AT[site["kind"]])
    var bought: Dictionary = Lab.purchase(world,where,requested)
    assert(bought.get("valid",false))
    world = bought["world"]
    var new_unit: Dictionary = _unit(world["state"]["units"],str(bought["unit_id"]))
    assert(not new_unit.is_empty() and str(new_unit["role"]) == requested)
    assert(int(new_unit["faction"]) == 0 and bool(new_unit["acted"]))
    assert(new_unit["pos"] == where)
    assert(int(bought["cost"]) == Economy.cost(requested))
    assert(int(world["state"]["economy"]["credits"][0]) == amount-int(bought["cost"]))
    assert(int(world["purchase_count"]) == 1)
    assert(int(_find(world,where)["produced_turn"]) == int(world["state"]["economy"]["turn"]))
    assert(not Lab.purchase(world,where,requested).get("valid",false))
    assert(world["layout"]["sites"].size() == total_before)
    assert(Economy.valid(world["state"]["economy"],world["state"]["terrain"]))
    assert(not Save.encode(world["state"]).is_empty())
    var snapshot: String = Lab.encode(world)
    var decoded: Dictionary = Lab.decode(snapshot)
    assert(decoded.get("valid",false))
    assert(decoded["layout"]["sites"] == world["layout"]["sites"])
    assert(decoded["state"] == world["state"])
    assert(decoded["purchase_count"] == 1)
    print("PLAYABLE_PRODUCER size=%s map=%d kind=%s site=%s shore=%s income=%d cost=%d captured_after_two_own_turns=true purchase_real=true old_save_codec_preserved=true" % [
        str(size),map_id,str(site["kind"]),str(where),
        str(site.get("capture_pos",where)),income_s1,int(bought["cost"])
    ])

static func _save_guards() -> void:
    var world: Dictionary = Lab.start(0,Vector2i(24,18))
    assert(world.get("valid",false))
    var raw: String = Lab.encode(world)
    assert(not raw.is_empty())
    var data: Dictionary = JSON.parse_string(raw)
    data["version"] = 100
    assert(Lab.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["sites"].pop_back()
    assert(Lab.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["sites"][0]["owner"] = 5
    assert(Lab.decode(JSON.stringify(data)).is_empty())
    data = JSON.parse_string(raw)
    data["sites"][0]["owner"] = -1
    data["captured_bases"] = -1
    assert(Lab.decode(JSON.stringify(data)).is_empty())
    assert(world == Lab.decode(raw))
