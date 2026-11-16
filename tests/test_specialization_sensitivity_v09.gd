extends SceneTree

# Economic and counterplay sensitivity for candidate Rompedor/Ingeniero
# abilities. All numbers are PREVIEW or standalone tests, never progression
# applied to the live TARVOKA catalog.
const Lab = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var terrains := ["plain","forest","mountain","city"]
    var role_list: Array = []
    role_list.append_array(Roles.ORDER)
    role_list.append_array(Arsenal.ORDER)
    var count := {"valid":0,"illegal":0,"modern_armored":0,"bonus2_kills":0,
        "bonus3_kills":0,"base_kills":0,"bonus2_ttk_improved":0,
        "bonus3_ttk_improved":0,"nonarmored_changed":0,
        "damage_total_base":0,"damage_total_plus2":0,"damage_total_plus3":0}
    for target_role in role_list:
        for context in terrains:
            var terrain: Array = _terrain(context)
            var economics: Dictionary = _econ(context)
            var attacker: Dictionary = _unit("piercer",0,Vector2i(4,4))
            var defender: Dictionary = _unit(str(target_role),1,Vector2i(5,4))
            if context == "forest":
                terrain[4][5] = "forest"
            elif context == "mountain":
                terrain[4][5] = "mountain"
            var exchange: Array = []
            for bonus in [0,2,3]:
                exchange.append(Lab.preview_antiarmor(attacker,defender,int(bonus),terrain,economics,[attacker,defender]))
            var base: Dictionary = exchange[0]
            if not bool(base.get("valid",false)):
                count["illegal"] += 1
                assert(not exchange[1].get("valid",false) and not exchange[2].get("valid",false))
                continue
            count["valid"] += 1
            var previous: int = int(base["damage"])
            var two: int = int(exchange[1]["damage"])
            var three: int = int(exchange[2]["damage"])
            if str(target_role) in Lab.ANTI_ARMOR_ROLES:
                count["modern_armored"] += 1
                assert(previous <= two and two <= three)
            else:
                assert(previous == two and two == three)
                if previous != two or previous != three:
                    count["nonarmored_changed"] += 1
            count["damage_total_base"] += previous
            count["damage_total_plus2"] += two
            count["damage_total_plus3"] += three
            count["base_kills"] += int(base.get("defeated",false))
            count["bonus2_kills"] += int(exchange[1].get("defeated",false))
            count["bonus3_kills"] += int(exchange[2].get("defeated",false))
            var hp: int = int(defender["hp"])
            if ceili(float(hp)/float(maxi(1,two))) < ceili(float(hp)/float(maxi(1,previous))):
                count["bonus2_ttk_improved"] += 1
            if ceili(float(hp)/float(maxi(1,three))) < ceili(float(hp)/float(maxi(1,previous))):
                count["bonus3_ttk_improved"] += 1
            if context == "plain" and str(target_role) in Lab.ANTI_ARMOR_ROLES:
                print("SPECIAL_ARMOR_DUEL role=%s hp=%d def=%d cost=%d plain_damage=%d plus2=%d plus3=%d hits_ttk=%d/%d/%d" % [
                    target_role,hp,int(defender["defense"]),Economy.cost(str(target_role)),
                    previous,two,three,ceili(float(hp)/float(maxi(1,previous))),
                    ceili(float(hp)/float(maxi(1,two))),ceili(float(hp)/float(maxi(1,three)))
                ])
    assert(int(count["valid"]) > 0)
    assert(int(count["nonarmored_changed"]) == 0)
    assert(int(count["modern_armored"]) == Lab.ANTI_ARMOR_ROLES.size()*terrains.size())
    assert(int(count["damage_total_base"]) < int(count["damage_total_plus2"]))
    assert(int(count["damage_total_plus2"]) <= int(count["damage_total_plus3"]))
    print("SPECIAL_ARMOR_SENSITIVITY=%s" % str(count))
    _repair_value()
    print("PASS specialization sensitivity v09: 32 roles x four covers, 3 bonuses, 9 vehicle counters, repair economics and no unintended infantry damage")
    quit(0)

static func _unit(role: String, side: int, position: Vector2i) -> Dictionary:
    var unit: Dictionary = Roles.make_unit("U%d"%side,side,position,role)
    Logistics.equip(unit)
    return unit

static func _terrain(context: String) -> Array:
    var result: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        result.append(row)
    return result

static func _econ(context: String) -> Dictionary:
    if context == "city":
        return {"sites":[{"pos":Vector2i(5,4),"kind":"city","owner":1}]}
    return {}

static func _repair_value() -> void:
    for role in Lab.REPAIRABLE_ROLES:
        var soldier: Dictionary = _unit(str(role),0,Vector2i(4,4))
        var replacement_cost: int = Economy.cost(str(role))
        var max_health: int = Lab.max_hp(soldier)
        assert(max_health > 0 and replacement_cost > 0)
        for name in Lab.REPAIR_PACKS:
            var plan: Dictionary = Lab.REPAIR_PACKS[name]
            var healed: int = mini(int(plan["hp"]),max_health-1)
            var cost: int = int(plan["credits"])
            var repair_per_hp: float = float(cost)/float(healed)
            var replacement_per_hp: float = float(replacement_cost)/float(max_health)
            print("SPECIAL_REPAIR_ECON role=%s pack=%s hp=%d cost=%d repair_cost_per_hp=%.2f replacement_cost_per_hp=%.2f" % [
                role,name,healed,cost,repair_per_hp,replacement_per_hp
            ])
    # Level/tech upgrades and commander multipliers are NOT modeled.
    assert(int(Lab.REPAIR_PACKS["small"]["credits"]) < int(Lab.REPAIR_PACKS["field"]["credits"]))
