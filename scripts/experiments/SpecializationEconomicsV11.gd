extends RefCounted
class_name TarvokaSpecializationEconomicsV11

# Pure scenario quotes for the balance lab, NOT a shop, tech tree or AI.
# Prices are read from the actual catalog. Hypothetical upgrade prices
# are explicitly supplied by the caller and NEVER charged to a match.
const Lab = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

static func repair_quote(role: String, current_hp: int,
        pack: String, engineer_already_owned: bool) -> Dictionary:
    if role not in Lab.REPAIRABLE_ROLES or not Lab.REPAIR_PACKS.has(pack):
        return {"valid":false}
    var profile: Dictionary = Roles.PROFILES[role] if Roles.PROFILES.has(role) else {}
    if profile.is_empty():
        var Arsenal = preload("res://scripts/core/ModernArsenal.gd")
        profile = Arsenal.profile(role)
    var cap: int = int(profile.get("hp",0))
    if current_hp <= 0 or current_hp >= cap:
        return {"valid":false}
    var treatment: Dictionary = Lab.REPAIR_PACKS[pack]
    var healed: int = mini(int(treatment["hp"]),cap-current_hp)
    var repair_cost: int = int(treatment["credits"])
    var engineer_cost: int = Economy.cost("engineer")
    var investment: int = repair_cost + (0 if engineer_already_owned else engineer_cost)
    var replacement: int = Economy.cost(role)
    if replacement <= 0 or healed <= 0:
        return {"valid":false}
    return {
        "valid":true,"role":role,"hp_before":current_hp,"hp_after":current_hp+healed,
        "max_hp":cap,"hp_restored":healed,"pack":pack,
        "repair_cost":repair_cost,"engineer_capital":0 if engineer_already_owned else engineer_cost,
        "upfront_credits":investment,"replacement_credits":replacement,
        "upfront_below_replacement":investment < replacement,
        "repair_credits_per_hp":float(repair_cost)/float(healed),
        "new_unit_credits_per_hp":float(replacement)/float(cap),
        "requires_adjacent_owned_engineer_now":true,
        "new_unit_requires_owned_empty_producer":true
    }

static func firepower_quote(target_role: String, bonus: int, active_piercers: int,
        hypothetical_tech_cost: int) -> Dictionary:
    if target_role not in Lab.ANTI_ARMOR_ROLES or bonus not in Lab.ARMOR_BONUSES:
        return {"valid":false}
    if active_piercers < 1 or active_piercers > 8 or hypothetical_tech_cost < 0:
        return {"valid":false}
    var a: Dictionary = Roles.make_unit("P",0,Vector2i(3,3),"piercer")
    var b: Dictionary = Roles.make_unit("T",1,Vector2i(4,3),target_role)
    if a.is_empty() or b.is_empty():
        return {"valid":false}
    Logistics.equip(a)
    Logistics.equip(b)
    var flat: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        flat.append(row)
    var base: Dictionary = Lab.preview_antiarmor(a,b,0,flat,{},[a,b])
    var improved: Dictionary = Lab.preview_antiarmor(a,b,bonus,flat,{},[a,b])
    if not bool(base.get("valid",false)) or not bool(improved.get("valid",false)):
        return {"valid":false}
    var damage_base: int = int(base["damage"])
    var damage_upgraded: int = int(improved["damage"])
    var hp: int = int(b["hp"])
    var recruit: int = Economy.cost("piercer")
    return {"valid":true,"target_role":target_role,"target_hp":hp,
        "bonus":bonus,"piercers_in_field":active_piercers,
        "damage_baseline":damage_base,"damage_specialized":damage_upgraded,
        "additional_damage_one_volley":(damage_upgraded-damage_base)*active_piercers,
        "single_piercer_ideal_hits_before":ceili(float(hp)/float(maxi(1,damage_base))),
        "single_piercer_ideal_hits_after":ceili(float(hp)/float(maxi(1,damage_upgraded))),
        "hypothetical_global_tech_credits":hypothetical_tech_cost,
        "new_piercers_at_same_credits":int(hypothetical_tech_cost/recruit),
        "one_piercer_credits":recruit,
        "model_limit":"static strikes with constant HP; ignores counterattacks, range, cover, recruitment locations, ammo and tech access"}
