extends RefCounted
class_name TarvokaUnitVeterancyV14

# Standalone balance laboratory. These are CANDIDATE changes, never stored XP.
# The actual doctrine has 0 attack and defense bonuses; no live unit is
# promoted. Consumables cannot reasonably gain combat XP after destruction.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const FIELDS := ["hp","attack","defense","vision","move_points"]
const CONSUMABLE := ["fpv","loitering","usv"]
# Each entry supplies ONE independently earned step at xp=15 / 40 / 80.
# Each role has deliberate utility, with offensive stacking limited to +1.
# hp increases preserve a wounded unit's pre-existing damage (in samples).
const STEPS := {
    "line":[{"hp":1},{"vision":1},{"attack":1}],
    "scout":[{"vision":1},{"hp":1},{"move_points":1}],
    "bulwark":[{"hp":1},{"defense":1},{"hp":1}],
    "piercer":[{"vision":1},{"hp":1},{"move_points":1}],
    "artillery":[{"vision":1},{"hp":1},{"attack":1}],
    "assault":[{"hp":1},{"vision":1},{"attack":1}],
    "engineer":[{"hp":1},{"vision":1},{"move_points":1}],
    "apc":[{"vision":1},{"hp":1},{"move_points":1}],
    "ifv":[{"hp":1},{"vision":1},{"defense":1}],
    "tank":[{"vision":1},{"hp":1},{"vision":1}],
    "spg":[{"vision":1},{"hp":1},{"attack":1}],
    "mlrs":[{"vision":1},{"hp":1},{"vision":1}],
    "mobile_aa":[{"vision":1},{"hp":1},{"attack":1}],
    "sam":[{"vision":1},{"hp":1},{"vision":1}],
    "ew":[{"vision":1},{"hp":1},{"move_points":1}],
    "logistics":[{"hp":1},{"vision":1},{"move_points":1}],
    "uav_recon":[{"vision":1},{"move_points":1},{"hp":1}],
    "ucav":[{"vision":1},{"hp":1},{"attack":1}],
    "attack_heli":[{"vision":1},{"hp":1},{"attack":1}],
    "transport_heli":[{"hp":1},{"vision":1},{"move_points":1}],
    "fighter":[{"vision":1},{"hp":1},{"attack":1}],
    "bomber":[{"vision":1},{"hp":1},{"vision":1}],
    "patrol":[{"vision":1},{"hp":1},{"attack":1}],
    "missile_boat":[{"vision":1},{"hp":1},{"attack":1}],
    "corvette":[{"hp":1},{"vision":1},{"defense":1}],
    "frigate":[{"vision":1},{"hp":1},{"vision":1}],
    "destroyer":[{"vision":1},{"hp":1},{"vision":1}],
    "submarine":[{"vision":1},{"hp":1},{"move_points":1}],
    "landing_ship":[{"hp":1},{"vision":1},{"move_points":1}]
}

static func roles() -> Array:
    var collection: Array = []
    collection.append_array(Roles.ORDER)
    collection.append_array(Arsenal.ORDER)
    return collection

static func available(role: String) -> bool:
    return STEPS.has(role) and role not in CONSUMABLE

static func next_xp(level: int) -> int:
    return int(Doctrine.VETERANCY[level]["xp"]) if level >= 0 and level < Doctrine.VETERANCY.size() else -1

static func _base(role: String) -> Dictionary:
    return Roles.PROFILES[role] if Roles.PROFILES.has(role) else Arsenal.profile(role)

static func totals(role: String, level: int) -> Dictionary:
    if not Roles.valid(role) or level < 0 or level > 3:
        return {}
    if role in CONSUMABLE:
        return {} if level != 0 else {"hp":0,"attack":0,"defense":0,"vision":0,"move_points":0}
    if not STEPS.has(role):
        return {}
    var result: Dictionary = {"hp":0,"attack":0,"defense":0,"vision":0,"move_points":0}
    for i in range(level):
        var change: Dictionary = STEPS[role][i]
        for key in change:
            result[key] = int(result[key])+int(change[key])
    return result

static func unit(role: String, side: int, cell: Vector2i, level: int) -> Dictionary:
    var deltas: Dictionary = totals(role,level)
    if deltas.is_empty():
        return {}
    var soldier: Dictionary = Roles.make_unit("LVL",side,cell,role)
    if soldier.is_empty():
        return {}
    Logistics.equip(soldier)
    for stat in FIELDS:
        soldier[stat] = int(soldier[stat])+int(deltas.get(stat,0))
    # No phantom ammo upgrades (Logistics.valid_unit caps real ammo).
    return soldier

static func preview(role: String, enemy_role: String,
        level: int, board: Array) -> Dictionary:
    var attacker: Dictionary = unit(role,0,Vector2i(2,3),level)
    var target: Dictionary = unit(enemy_role,1,Vector2i(3,3),0)
    if attacker.is_empty() or target.is_empty():
        return {"valid":false}
    # Indirect fire at real minimum range if attacker has a blind zone.
    target["pos"] = Vector2i(2+int(attacker["attack_min_range"]),3)
    if target["pos"].x >= board[0].size():
        return {"valid":false}
    return Battle.preview_exchange(attacker,target,true,board,{},[attacker,target])

static func investment_quote(role: String, level: int) -> Dictionary:
    if not Roles.valid(role):
        return {}
    var base: Dictionary = _base(role)
    return {"role":role,"level":level,"xp":next_xp(level),
        "recruit_cost":Economy.cost(role),
        "base_hp":int(base["hp"]),"base_attack":int(base["attack"]),
        "base_defense":int(base["defense"]),
        "changes":totals(role,level),
        "unsupported":role in CONSUMABLE,
        "lab_only":true}
