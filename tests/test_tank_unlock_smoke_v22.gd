extends SceneTree

const Lab = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const V21 = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Tier = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    assert(Lab.MODES.size() == 2)
    assert(int(Tier.UPGRADE_COSTS["armor_plant"][2]) == 650)
    assert(Tier.required_level("tank") == 2)
    assert(Tier.required_level("ifv") == 2)
    var start: Dictionary = Lab.begin(0,Vector2i(10,8),0)
    assert(start.get("valid",false))
    assert(start["original"] == start["session"])
    var old_cash: int = int(start["session"]["world"]["state"]["economy"]["credits"][0])
    var upgrade: Dictionary = Lab._upgrade(start,0)
    assert(bool(upgrade.get("valid",false)))
    var raised: Dictionary = upgrade["battle"]
    assert(int(raised["session"]["world"]["state"]["economy"]["credits"][0]) == old_cash-650)
    assert(int(raised["unlock_lab"]["upgrades"][0]) == 1)
    assert(int(raised["unlock_lab"]["upgrade_spent"][0]) == 650)
    assert(Lab._has_upgraded_plant(raised,0))
    assert(not bool(Lab._upgrade(raised,0).get("valid",false)))
    assert(Economy.valid(raised["session"]["world"]["state"]["economy"],
        raised["session"]["world"]["state"]["terrain"]))
    # No sudden upgrade on the other army.
    assert(not Lab._has_upgraded_plant(raised,1))
    var instant: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],"instant",8)
    var gated: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],"level2",8)
    assert(instant.get("valid",false))
    assert(gated.get("valid",false))
    for run in [instant,gated]:
        assert(run["halfturns"] > 0 and run["halfturns"] <= 8)
        assert(run["sides"]["0"]["policy"] == "armor")
        assert(run["sides"]["1"]["policy"] == "pressure")
        for side in ["0","1"]:
            var data: Dictionary = run["sides"][side]
            assert(int(data["cash"]) == Economy.MODERN_START_CREDITS+
                int(data["income"])-int(data["total_spent"]))
            assert(int(data["upgrade_spent"]) == 650*int(data["upgrade_count"]))
    assert(int(instant["sides"]["0"]["upgrade_count"]) == 0)
    assert(int(gated["sides"]["0"]["upgrade_count"]) == 1)
    assert(int(gated["sides"]["0"]["upgrade_halfturn"]) == 1)
    assert(int(gated["sides"]["0"]["first_tank_halfturn"]) == -1 or
        int(gated["sides"]["0"]["first_tank_halfturn"]) > 1)
    assert(int(gated["sides"]["1"]["upgrade_count"]) == 0)
    print("GATE_SMOKE_V22 instant=%s gated=%s" % [str(instant),str(gated)])
    # Controls keep original A/B simulation completely backwards compatible.
    var control: Dictionary = V21.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],8)
    assert(control.get("valid",false))
    for side in ["0","1"]:
        for field in ["attacks","moves","damage","purchases","spent","cash",
                "income","city_captures","base_captures"]:
            assert(control["sides"][side][field] == instant["sides"][side][field])
    assert(control["winner"] == instant["winner"])
    print("PASS tank unlock smoke v22: paid upgrade, no cross-side upgrade, no same-turn tank, exact cash, original v21 instant parity")
    quit(0)
