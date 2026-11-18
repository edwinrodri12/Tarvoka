extends RefCounted
class_name TarvokaFourthDeploymentPolicyV368

# EXPERIMENT ONLY: no production scripts or gameplay scenes import this.
# The decision reads the AI's *already chosen*, legally executed fourth action.
# Only fixed public objectives + the acting faction's own unit are consulted.
# Never reroutes a unit, alters Session action semantics or peeks at enemies.
static func evaluate(variant: String, prior: Dictionary, proposed: Dictionary) -> Dictionary:
    var action: String = str(proposed.get("action", ""))
    var detail := {
        "allowed": false, "action": action, "destination": Vector2i(-1,-1),
        "origin": Vector2i(-1,-1), "site": false, "relay": false,
        "site_kind": "", "relay_distance_before": -1,
        "relay_distance_after": -1, "relay_delta": 0,
        "own_half": false, "denial": "not_a_movement"
    }
    if variant == "4":
        detail["allowed"] = action in ["move","attack","produce","resupply"]
        detail["denial"] = "none" if bool(detail["allowed"]) else "invalid_action"
    if action != "move" or not proposed.get("destination") is Vector2i:
        return detail
    var destination: Vector2i = proposed["destination"]
    detail["destination"] = destination
    if not prior.get("units") is Array:
        return detail
    var side: int = int(prior.get("faction", -1))
    if side not in [0,1]:
        return detail
    var source := Vector2i(-1,-1)
    var found := false
    for unit in prior["units"]:
        if unit is Dictionary and str(unit.get("id","")) == str(proposed.get("unit_id","")) and \
                int(unit.get("faction",-1)) == side and unit.get("pos") is Vector2i:
            source = unit["pos"]
            found = true
            break
    if not found:
        return detail
    detail["origin"] = source
    var nodes: Array = prior.get("control",{}).get("nodes",[])
    var before := 999999
    var after := 999999
    for node in nodes:
        if not node is Dictionary or not node.get("pos") is Vector2i:
            continue
        var target: Vector2i = node["pos"]
        if destination == target:
            detail["relay"] = true
        before = mini(before, absi(source.x-target.x) + absi(source.y-target.y))
        after = mini(after, absi(destination.x-target.x) + absi(destination.y-target.y))
    if before != 999999:
        detail["relay_distance_before"] = before
        detail["relay_distance_after"] = after
        detail["relay_delta"] = after-before
    var economy: Dictionary = prior.get("economy",{})
    for site in economy.get("sites",[]):
        if site is Dictionary and site.get("pos") == destination:
            detail["site"] = true
            detail["site_kind"] = str(site.get("kind",""))
            break
    var terrain: Array = prior.get("terrain",[])
    var width := 10
    if not terrain.is_empty() and terrain[0] is Array:
        width = terrain[0].size()
    detail["own_half"] = destination.x < int(width/2) if side == 0 else destination.x >= int(width/2)
    var touches_objective: bool = bool(detail["site"]) or bool(detail["relay"])
    if variant == "3plus_no_objective":
        detail["allowed"] = not touches_objective
        detail["denial"] = "objective_tile" if touches_objective else "none"
    elif variant == "3plus_defensive":
        detail["allowed"] = not touches_objective and bool(detail["own_half"]) and \
                int(detail["relay_delta"]) >= 0
        detail["denial"] = "objective_tile" if touches_objective else \
            ("opposing_half" if not bool(detail["own_half"]) else \
            ("approaches_relay" if int(detail["relay_delta"]) < 0 else "none"))
    elif variant == "4":
        detail["allowed"] = true
        detail["denial"] = "none"
    return detail
