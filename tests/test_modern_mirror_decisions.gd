extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

# Only diagnostic until all decision types are mirror-equivalent. No faction
# bonuses are modified to force a desired 50/50 tournament score.
func _initialize() -> void:
    var mismatches := 0
    var compared := 0
    for map_id in [0,3]:
        for fog in [false,true]:
            var terrain: Array = Scenarios.terrain(map_id)
            var left: Dictionary = Session.start(Roles.modern_armies(true),terrain,0,fog,true,true,true)
            var right: Dictionary = Session.start(Roles.modern_armies(true),terrain,1,fog,true,true,true)
            var divergent := false
            for phase in range(12):
                for i in range(50):
                    var old_l: Dictionary = left.duplicate(true)
                    var old_r: Dictionary = right.duplicate(true)
                    var l: Dictionary = AI.step(left)
                    var r: Dictionary = AI.step(right)
                    assert(left == old_l and right == old_r)
                    var a: String = _action_signature(old_l,l)
                    var b: String = _action_signature(old_r,r)
                    compared += 1
                    if a != b:
                        mismatches += 1
                        divergent = true
                        print("MIRROR_DIAGNOSTIC map=%d fog=%s phase=%d step=%d LEFT=%s RIGHT=%s" % [map_id,str(fog),phase,i,a,b])
                        break
                    if not l.get("valid",false):
                        break
                    left = l["state"]
                    right = r["state"]
                    if int(left["winner"]) != -1 or int(right["winner"]) != -1:
                        break
                if divergent:
                    break
                if int(left["winner"]) != -1 or int(right["winner"]) != -1:
                    if int(left["winner"]) != 1-int(right["winner"]):
                        mismatches += 1
                        print("MIRROR_TERMINAL_DIFFERENCE map=%d fog=%s phase=%d left=%d right=%d" % [
                            map_id,str(fog),phase,int(left["winner"]),int(right["winner"])
                        ])
                    break
                var ended_l: Dictionary = Session.end_turn(left)
                var ended_r: Dictionary = Session.end_turn(right)
                assert(ended_l["valid"] and ended_r["valid"])
                left = ended_l["state"]
                right = ended_r["state"]
                if int(left["winner"]) != -1 or int(right["winner"]) != -1:
                    if int(left["winner"]) != 1-int(right["winner"]):
                        mismatches += 1
                        print("MIRROR_TERMINAL_DIFFERENCE map=%d fog=%s phase=%d left=%d right=%d" % [
                            map_id,str(fog),phase,int(left["winner"]),int(right["winner"])
                        ])
                    break
                assert(int(left["faction"]) == 1-int(right["faction"]))
    print("MIRROR_SUMMARY compared=%d divergent_openings=%d" % [compared,mismatches])
    print("PASS mirror multi-round diagnostic: compare role, destination and resources over twelve paired phases")
    quit(0)

static func _role(state: Dictionary, id: String) -> String:
    for unit in state["units"]:
        if str(unit.get("id","")) == id:
            return str(unit.get("role",""))
    return "unknown"

static func _action_signature(before: Dictionary, result: Dictionary) -> String:
    if not result.get("valid",false):
        return "idle"
    var reason: String = str(result.get("reason",""))
    match str(result.get("action","")):
        "move":
            var dest: Vector2i = result["destination"]
            # Normalize x for the currently acting faction.
            var relative_x: int = dest.x if int(before["faction"]) == 0 else 9-dest.x
            return "move %s %s (%d,%d)" % [_role(before,str(result["unit_id"])),reason,relative_x,dest.y]
        "attack":
            return "attack %s %s" % [_role(before,str(result.get("attacker_id",""))),_role(before,str(result.get("defender_id","")))]
        "produce":
            var factory: Vector2i = result["factory"]
            var relative_x: int = factory.x if int(before["faction"]) == 0 else 9-factory.x
            return "produce %s (%d,%d)" % [str(result["role"]),relative_x,factory.y]
        "resupply":
            return "resupply %s %s" % [_role(before,str(result.get("unit_id",""))),str(result.get("source_kind",""))]
        _:
            return "unsupported"
