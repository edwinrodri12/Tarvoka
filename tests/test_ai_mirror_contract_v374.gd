extends SceneTree

# 48 actual reflected BattleSession states (4 terrains × 2 first factions
# × 2 fog settings × 3 relay layouts). Geometric involution is mandatory;
# visible-cell asymmetry is OBSERVED, not concealed or used by AI.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")

static func _check(map_id: int, first: int, fog: bool, layout: String) -> void:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),first,
        fog,true,true,false,true,"clear",false,true)
    var columns: Array = [4,5] if layout == "center" else [3,6]
    var rows: Array = [1,6] if layout == "flanks" else [2,5]
    var sites: Array = []
    for y in rows:
        for x in columns:
            var pos := Vector2i(x,y)
            assert(Economy.site_at(state["economy"],pos).is_empty())
            sites.append({"pos":pos,"owner":-1})
    state["control"]["nodes"] = sites
    state["control"]["target"] = 8
    state["control"]["fair_round"] = true
    state["control"]["round_scoring"] = true
    state["control"]["first_faction"] = first
    state["ai_config"] = {"level":12,"style":"balanced"}
    assert(Relays.valid(state["control"],state["terrain"]))
    assert(not Codec.encode(state).is_empty())
    var baseline: Dictionary = state.duplicate(true)
    var swap: Dictionary = Mirror.reflect(state)
    assert(state == baseline) # source is immutable
    assert(Mirror.reflect(swap) == state) # double reflection = identity
    assert(swap["faction"] == 1-first)
    assert(swap["economy"]["credits"] == state["economy"]["credits"])
    assert(swap["control"]["scores"] == [0,0])
    assert(Opening.remaining(swap) == 3)
    assert(Relays.valid(swap["control"],swap["terrain"]))
    var mismatch: int = Mirror.visibility_mismatch(state,swap)
    var repair: bool = Codec.encode(swap).is_empty()
    if repair:
        swap = Visibility.update_exploration(swap)
    assert(not Codec.encode(swap).is_empty())
    assert(Codec.decode(Codec.encode(swap)) == swap)
    assert(Codec.decode(Codec.encode(state)) == state)
    assert(Mirror.mapped_id(Mirror.mapped_id("A")) == "A")
    assert(Mirror.mapped_id(Mirror.mapped_id("V")) == "V")
    for i in range(state["units"].size()):
        var a: Dictionary = state["units"][i]
        var b: Dictionary = swap["units"][i]
        assert(Mirror.mapped_id(str(a["id"])) == str(b["id"]))
        assert(a["pos"] == Mirror.position(b["pos"],10))
        assert(int(a["faction"]) == 1-int(b["faction"]))
    var reordered: Dictionary = Mirror.stable_reorder(state)
    assert(Mirror.stable_reorder(reordered) == state)
    assert(Codec.decode(Codec.encode(reordered)) == reordered)
    print("MIRROR374_CONTRACT map=%d fog=%s first=%d layout=%s los_mismatch=%d fog_repair=%s" % [
        map_id,str(fog),first,layout,mismatch,str(repair)])

func _initialize() -> void:
    for map_id in [0,1,2,3]:
        for fog in [false,true]:
            for first in [0,1]:
                for layout in ["center","approach","flanks"]:
                    _check(map_id,first,fog,layout)
    print("PASS AI mirror v374 contract: 48 mirrored states, unit IDs, fog, relay owners, credits, opening, save parity")
    quit(0)
