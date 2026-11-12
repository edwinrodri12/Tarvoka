extends RefCounted
class_name TarvokaSupplyStrategy

const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

# A faction-owned, observable-only overview. The enemy treasury, stock and
# undiscovered installations must never drive purchasing decisions.
const REARM_RESERVE := 96

static func assess(knowledge: Dictionary, side: int) -> Dictionary:
    var status := {
        "ground_critical":0, "air_sea_critical":0, "trucks":0,
        "available_trucks":0, "empty_trucks":0,
        "reserve":0, "need_truck":false
    }
    if side not in [0, 1] or not knowledge.get("economy") is Dictionary or not bool(knowledge["economy"].get("modern", false)):
        return status
    for unit in knowledge.get("units", []):
        if not unit is Dictionary or int(unit.get("faction",-1)) != side or int(unit.get("hp",0)) <= 0:
            continue
        if not unit.has("ammo") or not unit.has("fuel"):
            continue
        var role: String = str(unit.get("role", ""))
        if role == "logistics":
            status["trucks"] += 1
            var stock_ammo: int = int(unit.get("supply_ammo", Logistics.TRUCK_AMMO_CAP))
            var stock_fuel: int = int(unit.get("supply_fuel", Logistics.TRUCK_FUEL_CAP))
            if stock_ammo > 0 or stock_fuel > 0:
                if int(unit["fuel"]) > 2:
                    status["available_trucks"] += 1
            else:
                status["empty_trucks"] += 1
            continue
        var domain: String = Domains.domain(unit)
        var ammo_low: bool = Logistics.ammo_capacity(role) > 0 and int(unit["ammo"]) <= 1
        var fuel_low: bool = Logistics.fuel_capacity(role) > 0 and int(unit["fuel"]) <= (3 if domain in ["air", "naval"] else 2)
        if not ammo_low and not fuel_low:
            continue
        if domain == Domains.GROUND:
            status["ground_critical"] += 1
        else:
            status["air_sea_critical"] += 1
    var demand: int = int(status["ground_critical"]) + int(status["air_sea_critical"])
    if demand > 0 or int(status["empty_trucks"]) > 0:
        # The reserve buys a small but meaningful partial refill at a base.
        # It never changes the actual costs defined by Logistics.
        status["reserve"] = REARM_RESERVE
    status["need_truck"] = int(status["ground_critical"]) > 0 and (
        int(status["available_trucks"]) == 0 and int(status["trucks"]) == 0
        or int(status["ground_critical"]) >= 4 and int(status["available_trucks"]) < 2 and int(status["trucks"]) < 2
    )
    return status

static func can_spend_on_recruitment(state: Dictionary, side: int, role: String, price: int, strategy: Dictionary) -> bool:
    if side not in [0, 1] or not state.get("economy") is Dictionary or price < 1:
        return false
    var credits: int = int(state["economy"]["credits"][side])
    if credits < price:
        return false
    # Purchasing the first supply truck during an emergency is a deliberate
    # investment instead of permanently hoarding money for an unreachable base.
    if role == "logistics" and bool(strategy.get("need_truck", false)):
        return true
    return credits - price >= int(strategy.get("reserve", 0))
