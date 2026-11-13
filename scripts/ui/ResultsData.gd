extends RefCounted
class_name TarvokaResultsData

const Roles = preload("res://scripts/core/UnitRoles.gd")

# Read-only end-of-battle facts. No fabricated accuracy, damage dealt or
# "units produced": older saved matches have no historical action ledger.
# Do not mutate battle state or the SaveCodec format to make a prettier card.
static func report(state: Dictionary) -> Dictionary:
    var winner: int = int(state.get("winner",-1))
    if winner not in [0,1] or not state.get("units") is Array:
        return {"valid":false}
    var survivors := [0,0]
    var remaining_hp := [0,0]
    var recorded_losses := [0,0]
    var surviving_roles: Array = [{},{}]
    for unit in state["units"]:
        if not unit is Dictionary:
            continue
        var side: int = int(unit.get("faction",-1))
        if side not in [0,1]:
            continue
        var hp: int = int(unit.get("hp",0))
        if hp <= 0:
            recorded_losses[side] += 1
            continue
        survivors[side] += 1
        remaining_hp[side] += hp
        var role: String = str(unit.get("role",""))
        if not role.is_empty():
            surviving_roles[side][role] = int(surviving_roles[side].get(role,0))+1
    var control: Dictionary = state.get("control",{})
    var win_by_relay := false
    var signal_scores := [0,0]
    var signal_target := 0
    if not control.is_empty():
        var scores: Array = control.get("scores",[])
        if scores.size() == 2:
            signal_scores = [int(scores[0]),int(scores[1])]
            signal_target = int(control.get("target",0))
            win_by_relay = signal_target > 0 and signal_scores[winner] >= signal_target
    var city_counts := [0,0]
    var base_counts := [0,0]
    var credits := [0,0]
    var income := [0,0]
    var economy: Dictionary = state.get("economy",{})
    if not economy.is_empty():
        var raw_credits: Array = economy.get("credits",[])
        if raw_credits.size() == 2:
            credits = [int(raw_credits[0]),int(raw_credits[1])]
        var city_income: int = 250 if bool(economy.get("modern",false)) else 100
        for site in economy.get("sites",[]):
            if not site is Dictionary:
                continue
            var owner: int = int(site.get("owner",-1))
            if owner not in [0,1]:
                continue
            if str(site.get("kind","")) == "city":
                city_counts[owner] += 1
                income[owner] += city_income
            else:
                base_counts[owner] += 1
    var title := "VICTORIA" if winner == 0 else "DERROTA"
    var cause := ("Victoria por control de relés" if win_by_relay else "Victoria por eliminación")
    if not win_by_relay and survivors[1-winner] > 0:
        # A legacy terminal save may have a different victory source;
        # never claim a total rout while the loser still has active units.
        cause = "Victoria registrada por el motor de batalla"
    return {
        "valid":true, "winner":winner,"title":title,"cause":cause,
        "survivors":survivors,"hp":remaining_hp,
        "recorded_losses":recorded_losses,
        "surviving_roles":surviving_roles,
        "signal":signal_scores,"signal_target":signal_target,"relay_victory":win_by_relay,
        "has_relay":not control.is_empty(),"has_economy":not economy.is_empty(),
        "cities":city_counts,"bases":base_counts,"credits":credits,"income":income
    }
