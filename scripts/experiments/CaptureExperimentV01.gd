extends RefCounted
class_name TarvokaCaptureExperimentV01

# DIAGNOSTIC ONLY — never called from BattleSession or the shipping UI.
# This wraps genuine Session.end_turn and changes only the resulting
# trial-state city/facility ownership, income, and an OUT-OF-BAND meter.
# The meter is NOT serialized by SaveCodec v1 and is not production-ready.
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")

const CITY_THRESHOLD := 4
const FACILITY_THRESHOLD := 3
const MIN_OWN_TURNS := 2
const MAX_ADJACENT_SUPPORT := 2
const ELIGIBLE := ["line","scout","assault","piercer","engineer"]
const FAST_CAPTURERS := ["line","assault"]
const SECONDARY_ELIGIBLE := "piercer"

static func _key(pos: Vector2i) -> String:
    return "%d:%d" % [pos.x,pos.y]

static func _unit_maxhp(role: String) -> int:
    if Roles.PROFILES.has(role):
        return int(Roles.PROFILES[role]["hp"])
    if Arsenal.valid(role):
        return int(Arsenal.profile(role)["hp"])
    return 1

static func eligible(unit: Dictionary, allow_piercer: bool = true) -> bool:
    if int(unit.get("hp",0)) <= 0 or Domains.domain(unit) != Domains.GROUND:
        return false
    var role: String = str(unit.get("role",""))
    return role in ELIGIBLE and (allow_piercer or role != SECONDARY_ELIGIBLE)

static func _occupant(units: Array, pos: Vector2i, side: int,
        allow_piercer: bool) -> Dictionary:
    for unit in units:
        if unit is Dictionary and int(unit.get("faction",-1)) == side and unit.get("pos") == pos and eligible(unit,allow_piercer):
            return unit
    return {}

static func _effort(units: Array, holder: Dictionary, side: int,
        allow_piercer: bool) -> Dictionary:
    var role: String = str(holder["role"])
    var base: int = 2 if role in FAST_CAPTURERS else 1
    if int(holder["hp"])*2 < _unit_maxhp(role):
        base = 1
    var helpers: Dictionary = {}
    var cell: Vector2i = holder["pos"]
    for ally in units:
        if not ally is Dictionary or int(ally.get("faction",-1)) != side or str(ally.get("id","")) == str(holder["id"]):
            continue
        if not eligible(ally,allow_piercer):
            continue
        var pos: Vector2i = ally.get("pos",Vector2i(-1,-1))
        if absi(pos.x-cell.x)+absi(pos.y-cell.y) != 1:
            continue
        helpers[_key(pos)] = true
    return {"base":base,"support":mini(MAX_ADJACENT_SUPPORT,helpers.size()),
        "total":base+mini(MAX_ADJACENT_SUPPORT,helpers.size())}

static func finish_and_advance(state: Dictionary, tracking: Dictionary,
        allow_piercer: bool = true) -> Dictionary:
    var before: Dictionary = state.duplicate(true)
    var unchanged: Dictionary = tracking.duplicate(true)
    var denied := {"valid":false,"state":before,"tracking":unchanged}
    if not state.has("economy") or not Economy.valid(state["economy"],state.get("terrain",[])):
        return denied
    if int(state.get("winner",-1)) != -1 or int(state.get("faction",-1)) not in [0,1]:
        return denied
    var side: int = int(state["faction"])
    var settled: Dictionary = Session.end_turn(state)
    if not bool(settled.get("valid",false)):
        return denied
    var next: Dictionary = settled["state"]
    var meter: Dictionary = tracking.duplicate(true)
    var completed := 0
    var advanced := 0
    var interrupted := 0
    var contested := 0
    var paid_withheld := 0
    for previous_site in state["economy"]["sites"]:
        var pos: Vector2i = previous_site["pos"]
        var key: String = _key(pos)
        var now_site: Dictionary = Economy.site_at(next["economy"],pos)
        var old_owner: int = int(previous_site["owner"])
        var kind: String = str(previous_site["kind"])
        if not meter.has(key):
            meter[key] = {}
        var record: Dictionary = meter[key]
        var holder: Dictionary = _occupant(next["units"],pos,side,allow_piercer)
        # The defender's turn must not erase continuing capture while the
        # attacker still occupies the cell. Leaving/dying ALWAYS resets.
        if not record.is_empty():
            var former_side: int = int(record["side"])
            var still_present: Dictionary = _occupant(next["units"],pos,former_side,allow_piercer)
            if still_present.is_empty() or old_owner == former_side:
                meter.erase(key)
                record = {}
                interrupted += 1
        if old_owner == side:
            # A site owned by its occupant needs no progress meter.
            if meter.has(key):
                meter.erase(key)
            continue
        if holder.is_empty():
            if meter.has(key) and meter[key].is_empty():
                meter.erase(key)
            continue
        if not record.is_empty() and int(record["side"]) != side:
            meter.erase(key)
            record = {}
            interrupted += 1
        var effort: Dictionary = _effort(next["units"],holder,side,allow_piercer)
        var threshold: int = CITY_THRESHOLD if kind == "city" else FACILITY_THRESHOLD
        var value: int = int(record.get("points",0))+int(effort["total"])
        var turns: int = int(record.get("turns",0))+1
        var ready: bool = value >= threshold and turns >= MIN_OWN_TURNS
        if ready:
            now_site["owner"] = side
            meter.erase(key)
            completed += 1
        else:
            # The original economy module already flipped ownership as soon
            # as the occupant stood on this tile. Undo only this transition
            # so later income and production are based on actual completion.
            now_site["owner"] = old_owner
            meter[key] = {"side":side,"points":mini(value,threshold),
                "turns":turns,"kind":kind}
            advanced += 1
    # Reconcile automatic income that Session.end_turn already paid to the
    # next faction before our experimental ownership/progress adjustment.
    # A city under active occupation cannot bankroll its defender.
    var next_side: int = int(next.get("faction",-1))
    if next_side in [0,1] and next.has("economy"):
        var baseline_income: int = Economy.income_for(settled["state"]["economy"],next_side)
        var income_new: int = Economy.income_for(next["economy"],next_side)
        var withheld: int = 0
        var one_city: int = Economy.MODERN_CITY_INCOME if bool(next["economy"].get("modern",false)) else Economy.CITY_INCOME
        for site in next["economy"]["sites"]:
            if str(site["kind"]) != "city" or int(site["owner"]) != next_side:
                continue
            var key: String = _key(site["pos"])
            if meter.has(key) and not meter[key].is_empty() and int(meter[key]["side"]) != next_side:
                withheld += one_city
                contested += 1
        var adjust: int = income_new-baseline_income-withheld
        if adjust != 0:
            next["economy"]["credits"][next_side] = maxi(0,mini(Economy.MAX_CREDITS,
                int(next["economy"]["credits"][next_side])+adjust))
        paid_withheld = withheld
    assert(Economy.valid(next["economy"],next["terrain"]))
    return {"valid":true,"state":next,"tracking":meter,
        "completed":completed,"advanced":advanced,
        "interrupted":interrupted,"contested":contested,
        "withheld":paid_withheld}
