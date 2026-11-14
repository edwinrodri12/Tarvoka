extends SceneTree

# The +2 role counter must work in ordinary AI choices and keep the same
# purchased credits, facility limits and income cycle. Does not prove PvP win
# balance or that this AI chooses the perfect competitive unit mix.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var production_cases := 0
    for side in [0,1]:
        var ours: Vector2i = Vector2i(1,2) if side == 0 else Vector2i(8,2)
        var theirs: Vector2i = Vector2i(8,5) if side == 0 else Vector2i(1,5)
        var state: Dictionary = Session.start([
            Roles.make_unit("A",side,ours,"line"),
            Roles.make_unit("X",1-side,theirs,"tank")
        ],Scenarios.terrain(0),side,false,false,true,true)
        assert(Economy.valid(state["economy"],state["terrain"]))
        state["units"][0]["acted"] = true
        # All OUR installations except the armor plant already produced
        # this turn; isolate the investment choice without fabricated income.
        var plant := Vector2i(-1,-1)
        for site in state["economy"]["sites"]:
            if int(site["owner"]) != side:
                continue
            if str(site["kind"]) == "armor_plant":
                plant = site["pos"]
            elif site.has("produced_turn"):
                # Neutralize unrelated plants in this isolated test; marking
                # them already-produced would exhaust the AI's real per-turn
                # recruiting limit and invalidate the very purchase we test.
                site["owner"] = -1
        assert(plant.x >= 0)
        var unchanged: Dictionary = state.duplicate(true)
        var choice: Dictionary = AI.step(state)
        assert(choice["valid"] and choice["action"] == "produce")
        assert(choice["role"] == "piercer")
        assert(choice["cost"] == 300 and choice["factory"] == plant)
        assert(choice["state"]["units"].size() == state["units"].size()+1)
        assert(choice["state"]["units"].back()["role"] == "piercer")
        assert(choice["state"]["units"].back()["faction"] == side)
        assert(choice["state"]["units"].back()["acted"])
        assert(choice["state"]["economy"]["credits"][side] == 2500-300)
        assert(choice["state"]["economy"]["credits"][1-side] == 2500)
        assert(Economy.valid(choice["state"]["economy"],choice["state"]["terrain"]))
        assert(Codec.decode(Codec.encode(choice["state"])) == choice["state"])
        assert(state == unchanged)
        production_cases += 1

        # The AI's damage preview uses exactly the specialized role bonus
        # on BOTH sides; no extra force is secretly assigned by AI.
        var ppos := Vector2i(2,2) if side == 0 else Vector2i(7,2)
        var tpos := Vector2i(3,2) if side == 0 else Vector2i(6,2)
        var front: Dictionary = Session.start([
            Roles.make_unit("P",side,ppos,"piercer"),
            Roles.make_unit("T",1-side,tpos,"tank")
        ],Scenarios.terrain(0),side,false,false,true,true)
        var before: Dictionary = front.duplicate(true)
        var hit: Dictionary = AI.step(front)
        assert(hit["valid"] and hit["action"] == "attack")
        assert(hit["attacker_id"] == "P" and hit["defender_id"] == "T")
        assert(hit["damage"] == 4 and hit["counter_damage"] == 4)
        assert(hit["state"]["units"][0]["hp"] == 4)
        assert(hit["state"]["units"][1]["hp"] == 10)
        assert(front == before)
        assert(Codec.decode(Codec.encode(hit["state"])) == hit["state"])
    assert(production_cases == 2)
    print("PASS piercer G09 AI economy: mirrored armor-plant purchases at 300 credits, real AI attack +2, exact counterfire and save")
    quit(0)
