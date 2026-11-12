extends RefCounted
class_name TarvokaSupplyStrategy

const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

# A faction-owned, observable-only overview. The enemy treasury, stock and
# undiscovered installations must never drive purchasing decisions.
const REARM_RESERVE := 96

static func assess(knowledge: Dictionary, side: int) -> Dictionary:
    var status := {
        "ground_critical":0, "air_sea_critical":0, "trucks":0,
        "available_trucks":0, "empty_trucks":0,
        "reserve":0, "need_truck":false,
        "ready_combat":0, "visible_enemies":0, "friendly_combat":0, "income":0
    }
    if side not in [0, 1] or not knowledge.get("economy") is Dictionary or not bool(knowledge["economy"].get("modern", false)):
        return status
    for unit in knowledge.get("units", []):
        if not unit is Dictionary or int(unit.get("faction",-1)) != side or int(unit.get("hp",0)) <= 0:
            continue
        if not unit.has("ammo") or not unit.has("fuel"):
            continue
        var role: String = str(unit.get("role", ""))
        if int(unit.get("attack", 0)) > 0:
            status["friendly_combat"] += 1
            if int(unit.get("ammo",0)) > 1 and (Logistics.fuel_capacity(role) == 0 or int(unit.get("fuel",0)) > 3):
                status["ready_combat"] += 1
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
    for unit in knowledge.get("units", []):
        if unit is Dictionary and int(unit.get("faction",-1)) == 1 - side and int(unit.get("hp",0)) > 0:
            status["visible_enemies"] += 1
    status["income"] = Economy.income_for(knowledge["economy"], side)
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

# AI-only per-faction production cadence. The human player still keeps
# every legal factory action; the game economy and unit prices stay identical.
# Existing own factory produced_turn markers provide a deterministic counter
# without inventing save fields or hiding any extra state in the AI.
static func recruitment_limit(strategy: Dictionary) -> int:
    var ready: int = int(strategy.get("ready_combat", 0))
    var observed_enemies: int = int(strategy.get("visible_enemies", 0))
    if ready < 2 or observed_enemies > ready + 2:
        return 3 # Genuine emergency: reinforce several arms.
    if ready >= 6 and ready >= observed_enemies:
        return 1 # Established force: invest in supply and objectives.
    return 2

static func produced_this_phase(state: Dictionary, side: int) -> int:
    if side not in [0, 1] or not state.get("economy") is Dictionary:
        return 0
    var economy: Dictionary = state["economy"]
    var current: int = int(economy.get("turn", -1))
    var count := 0
    for site in economy.get("sites", []):
        if site is Dictionary and int(site.get("owner", -1)) == side and str(site.get("kind","")) != "city" and int(site.get("produced_turn",-2)) == current:
            count += 1
    return count

static func can_spend_on_recruitment(state: Dictionary, side: int, role: String, price: int, strategy: Dictionary) -> bool:
    if side not in [0, 1] or not state.get("economy") is Dictionary or price < 1:
        return false
    var credits: int = int(state["economy"]["credits"][side])
    if credits < price:
        return false
    if bool(state["economy"].get("modern", false)):
        var count: int = produced_this_phase(state, side)
        if count >= recruitment_limit(strategy) and not (role == "logistics" and bool(strategy.get("need_truck", false))):
            return false
    # Purchasing the first supply truck during an emergency is a deliberate
    # investment instead of permanently hoarding money for an unreachable base.
    if role == "logistics" and bool(strategy.get("need_truck", false)):
        return true
    var reserve: int = int(strategy.get("reserve", 0))
    if credits - price < reserve:
        return false
    # Do not repeatedly buy until the bank is dry while a healthy force
    # already exists. Reinvest when the visible threat is overwhelming.
    var ready: int = int(strategy.get("ready_combat", 0))
    var enemies: int = int(strategy.get("visible_enemies", 0))
    if ready >= 4 and ready >= enemies:
        var buffer: int = maxi(price, 2 * int(strategy.get("income", 0)))
        return credits - price >= reserve + buffer
    return true

# A legal recovery action is evaluated against replacing the same platform.
# It is deliberately conservative: a partly depleted high-value tank is worth
# saving, but topping off a nearly full cheap scout wastes a tactical action.
# All quotes use authoritative same-side stock and credits, never enemy data.
static func best_resupply(state: Dictionary, knowledge: Dictionary, side: int) -> Dictionary:
    var none := {"valid":false}
    if side not in [0, 1] or not state.get("economy") is Dictionary or not bool(state["economy"].get("modern", false)):
        return none
    var best: Dictionary = none
    var best_score := -9999999
    for unit in knowledge.get("units", []):
        if not unit is Dictionary or int(unit.get("faction",-1)) != side or int(unit.get("hp",0)) <= 0:
            continue
        if bool(unit.get("acted", true)) or not unit.has("ammo") or not unit.has("fuel"):
            continue
        var role: String = str(unit.get("role", ""))
        if role in ["fpv", "loitering", "usv"]:
            continue # Disposable drones should not return to rearm.
        var quote: Dictionary = Logistics.quote(state, str(unit["id"]))
        if not quote.get("valid", false):
            continue
        var ammo_max: int = Logistics.ammo_capacity(role)
        var fuel_max: int = Logistics.fuel_capacity(role)
        var ammo: int = int(unit["ammo"])
        var fuel: int = int(unit["fuel"])
        var missing_ammo: int = maxi(0, ammo_max - ammo)
        var missing_fuel: int = maxi(0, fuel_max - fuel)
        var load_needed: bool = role == "logistics" and (
            int(unit.get("supply_ammo", Logistics.TRUCK_AMMO_CAP)) <= 3
            or int(unit.get("supply_fuel", Logistics.TRUCK_FUEL_CAP)) <= 5
        )
        var immobilized: bool = fuel_max > 0 and fuel == 0
        var disarmed: bool = ammo_max > 0 and ammo == 0
        var depleted: bool = immobilized or disarmed or load_needed
        var ammo_priority: bool = ammo_max > 0 and ammo <= maxi(1, ammo_max / 2)
        var fuel_priority: bool = fuel_max > 0 and fuel <= maxi(3, fuel_max / 3)
        if not depleted and not ammo_priority and not fuel_priority:
            continue
        var value_recovered: int = int(quote.get("ammo",0)) * Logistics.AMMO_PRICE + int(quote.get("fuel",0)) * Logistics.FUEL_PRICE
        value_recovered += int(quote.get("cargo_ammo",0)) * Logistics.AMMO_PRICE + int(quote.get("cargo_fuel",0)) * Logistics.FUEL_PRICE
        if value_recovered <= 0:
            continue
        var price: int = Economy.cost(role)
        var paid: int = int(quote.get("cost",0))
        if not depleted and paid >= maxi(24, price / 2):
            continue
        var score: int = value_recovered * 2 - paid
        if immobilized:
            score += 2000
        if disarmed:
            score += 1500
        if load_needed:
            score += 1100
        if not depleted:
            score += 120
        if str(quote.get("source_kind","")) == "truck":
            score += 200
        if score > best_score:
            best_score = score
            best = {"valid":true, "unit_id":str(unit["id"]), "score":score, "cost":paid,
                "source_kind":str(quote.get("source_kind","")), "reason":"critical" if depleted else "efficient"}
    return best
