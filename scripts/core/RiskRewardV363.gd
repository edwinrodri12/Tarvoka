extends RefCounted
class_name TarvokaRiskRewardV363

# Pure bounded risk/reward gate. ALL facts come from the observed side's
# state; no real-authority move probes, omniscient enemy stocks or RNG.
# Values are heuristic opportunity costs, not changes to game economics.
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

static func _distance(a: Vector2i,b: Vector2i) -> int:
    return abs(a.x-b.x)+abs(a.y-b.y)

static func _objective_cost(known: Dictionary,side: int,
        unit: Dictionary,destination: Vector2i) -> int:
    if not Economy.can_capture(unit):
        return 0
    var current: Vector2i = unit["pos"]
    var sites: Array = known.get("economy",{}).get("sites",[])
    for site in sites:
        if not site is Dictionary or site.get("pos") != current or \
                destination == current or int(site.get("owner",-2)) in [side,-2]:
            continue
        # At phase end, a living infantry unit already here wins this site.
        # City cost approximates a few future income collections; a producer
        # has strategic recruitment value, but NO fictitious income.
        if str(site.get("kind","")) == "city":
            var city_income: int = Economy.MODERN_CITY_INCOME if \
                bool(known.get("economy",{}).get("modern",false)) else \
                Economy.CITY_INCOME
            return city_income*3+220
        return 550
    return 0

static func _lost_progress(known: Dictionary,side: int,
        unit: Dictionary,destination: Vector2i) -> int:
    var before: int = 9999
    var after: int = 9999
    if Economy.can_capture(unit):
        for site in known.get("economy",{}).get("sites",[]):
            if not site is Dictionary or \
                    int(site.get("owner",-2)) in [side,-2]:
                continue
            before = mini(before,_distance(unit["pos"],site["pos"]))
            after = mini(after,_distance(destination,site["pos"]))
    if before < 9999 and after > before:
        return mini(4,after-before)*45
    return 0

static func _exposed_pressure(known: Dictionary,side: int,
        unit: Dictionary,destination: Vector2i) -> int:
    var old_distance: int = 9999
    var new_distance: int = 9999
    for foe in known.get("units",[]):
        if not foe is Dictionary or int(foe.get("hp",0)) <= 0 or \
                int(foe.get("faction",-1)) == side:
            continue
        old_distance = mini(old_distance,_distance(unit["pos"],foe["pos"]))
        new_distance = mini(new_distance,_distance(destination,foe["pos"]))
    if old_distance < 9999 and new_distance > old_distance:
        return mini(4,new_distance-old_distance)*35
    return 0

static func evaluate(known: Dictionary,side: int,unit: Dictionary,
        destination: Vector2i,danger_before: int,
        danger_after: int) -> Dictionary:
    var hp: int = int(unit.get("hp",0))
    if hp <= 0 or danger_before < hp or \
            danger_after >= hp or danger_after >= danger_before:
        return {"permit":false,"reason":"no_confirmed_survival_improvement"}
    var role: String = str(unit.get("role",""))
    var price: int = maxi(150,Economy.cost(role))
    var preservation: int = price*17/10+160
    if int(unit.get("attack_min_range",1)) >= 2 or \
            role in ["logistics","uav_recon","ew","sam","mlrs"]:
        preservation += 260
    if hp <= 3:
        # A critically wounded infantry survivor may be worth extracting
        # even from a classical income city (three-turn approximation).
        preservation += 300
    preservation += mini(4,danger_before-danger_after)*10

    var capture_loss: int = _objective_cost(known,side,unit,destination)
    var progression_loss: int = _lost_progress(known,side,unit,destination)
    var pressure_loss: int = _exposed_pressure(known,side,unit,destination)
    var penalty: int = capture_loss+progression_loss+pressure_loss
    return {
        "permit":preservation > penalty,
        "reason":"save_unit" if preservation > penalty else "hold_objective",
        "preservation":preservation,
        "objective_cost":capture_loss,
        "lost_progress":progression_loss,
        "lost_pressure":pressure_loss,
        "margin":preservation-penalty,
        "risk_before":danger_before,
        "risk_after":danger_after
    }
