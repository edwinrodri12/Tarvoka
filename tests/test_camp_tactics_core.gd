extends SceneTree
const Session = preload("res://scripts/core/BattleSession.gd")
const Camps = preload("res://scripts/core/CampTactics.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        row.resize(10)
        row.fill("plain")
        map.append(row)
    var eng: Dictionary = Roles.make_unit("eng", 0, Vector2i(3, 2), "engineer")
    var foe: Dictionary = Roles.make_unit("foe", 1, Vector2i(4, 2), "tank")
    var guard: Dictionary = Roles.make_unit("guard", 0, Vector2i(1, 6), "line")
    var state: Dictionary = Session.start([eng, foe, guard], map, 0, true, false, true, true)
    var old: Dictionary = state.duplicate(true)
    # These are explicit QA fixture values ONLY; no production prices/HP
    # or recon radius have been approved for standard skirmish.
    var profile := {"cost": 80, "hp": 5}
    assert(not Session.deploy_camp(state, "eng", "medico", profile)["valid"])
    assert(not Session.deploy_camp(state, "guard", "defensivo", profile)["valid"])
    assert(not Session.deploy_camp(state, "eng", "defensivo", {})["valid"])
    assert(not Session.deploy_camp(state, "eng", "defensivo", {"cost": 99999, "hp": 5})["valid"])
    assert(state == old and not state.has("camps"))
    var deployed: Dictionary = Session.deploy_camp(state, "eng", "defensivo", profile)
    assert(deployed["valid"])
    var next: Dictionary = deployed["state"]
    assert(next["camps"].size() == 1 and Camps.valid(next))
    assert(next["units"][0]["acted"] and next["units"][0]["hp"] == eng["hp"])
    assert(next["economy"]["credits"][0] == state["economy"]["credits"][0] - 80)
    assert(next["economy"]["sites"] == state["economy"]["sites"])
    assert(Economy.income_for(next["economy"], 0) == Economy.income_for(state["economy"], 0))
    assert(not Session.deploy_camp(next, "eng", "defensivo", profile)["valid"])
    assert(not Session.move(next, "eng", Vector2i(3, 3))["valid"])
    assert(state == old)
    assert(Codec.decode(Codec.encode(next)) == next)
    var bad: Dictionary = next.duplicate(true)
    bad["camps"].append(bad["camps"][0].duplicate(true))
    assert(not Camps.valid(bad) and Codec.encode(bad).is_empty())
    bad = next.duplicate(true)
    bad["camps"][0]["hp"] = 99
    assert(Codec.encode(bad).is_empty())
    assert(Codec.decode(Codec.encode(state)) == state)
    # Occupancy and ownership are decisive; no bonus from nearby camps.
    assert(Camps.defensive_cover(foe, eng, next["camps"]) == 2)
    var off: Dictionary = eng.duplicate(true)
    off["pos"] = Vector2i(3, 3)
    assert(Camps.defensive_cover(foe, off, next["camps"]) == 0)
    off = eng.duplicate(true)
    off["faction"] = 1
    assert(Camps.defensive_cover(foe, off, next["camps"]) == 0)
    var air: Dictionary = foe.duplicate(true)
    air["domain"] = "air"
    assert(Camps.defensive_cover(air, eng, next["camps"]) == 0)
    var reply: Dictionary = Session.end_turn(next)["state"]
    var attack: Dictionary = Session.attack(reply, "foe", "eng")
    assert(attack["valid"] and attack["terrain_defense_cover"] == 2)
    var bare: Dictionary = reply.duplicate(true)
    bare.erase("camps")
    var normal: Dictionary = Session.attack(bare, "foe", "eng")
    assert(normal["valid"] and normal["terrain_defense_cover"] == 0)
    assert(attack["damage"] <= normal["damage"])
    var public_view: Dictionary = Actions.public_preview_exchange(reply["units"][1], reply["units"][0], map, reply["economy"], reply["units"], reply["camps"])
    assert(public_view["valid"] and public_view["terrain_defense_cover"] == 2)
    # A reconnaissance structure alone reveals a tile outside own unit sight.
    # Fixture uses explicit radius; the actual sniper's unit profile is pending.
    var recon: Dictionary = next.duplicate(true)
    var p := Vector2i(7, 6)
    assert(not Visibility.visible_cells(next, 0).has(p))
    recon["camps"].append({"kind": "reconocimiento", "owner": 0, "pos": p,
        "hp": 4, "max_hp": 4, "vision": 2})
    assert(Camps.valid(recon))
    assert(Visibility.visible_cells(recon, 0).has(Vector2i(8, 6)))
    assert(not Visibility.observed_state(recon, 1)["camps"].has(recon["camps"][1]))
    recon = Visibility.update_exploration(recon)
    assert(Codec.decode(Codec.encode(recon)) == recon)
    print("PASS camps tactical core: specialist action, paid deployment, save, defensive combat, fog")
    quit(0)
