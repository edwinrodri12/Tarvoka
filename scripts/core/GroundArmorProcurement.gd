extends RefCounted
class_name TarvokaGroundArmorProcurement

# Specialized ARMORED FACTORY preference, not a new combat advantage or
# unit/stat modifier. The caller provides Visibility.observed_state, so this
# planner can only react to enemies the AI is actually allowed to see.
# Purchases are still 100% authorized by Economy.can_purchase,
# SupplyStrategy.can_spend_on_recruitment and BattleSession.purchase.
#
# Roles after the first choice are tactical fallbacks for lower budgets and
# already-owned chassis. Every role has a useful field niche even while
# future APC/IFV infantry loading remains explicitly unimplemented.
const GROUND_ROLES := ["piercer","apc","ifv","tank","bulwark"]

static func ranking(knowledge: Dictionary, faction: int,
        counts: Dictionary) -> Array:
    var fallback := ["apc","ifv","piercer","tank","bulwark"]
    if faction not in [0,1] or not knowledge.get("units") is Array:
        return fallback
    var enemy_heavy := 0
    var enemy_mechanized := 0
    var enemy_infantry := 0
    var enemy_indirect := 0
    for unit in knowledge["units"]:
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        if int(unit.get("faction",-1)) != 1-faction:
            continue
        var role: String = str(unit.get("role",""))
        if role in ["tank","bulwark"]:
            enemy_heavy += 1
        elif role in ["ifv","apc"]:
            enemy_mechanized += 1
        elif role in ["artillery","spg","mlrs"]:
            enemy_indirect += 1
        elif role in ["line","scout","assault","engineer","piercer"]:
            enemy_infantry += 1
    var our_piercers: int = int(counts.get("piercer",0))
    var our_tanks: int = int(counts.get("tank",0))
    var our_ifvs: int = int(counts.get("ifv",0))
    var our_apcs: int = int(counts.get("apc",0))
    if enemy_heavy > 0:
        # A 300-credit Rompedor has +2 against G09 and +4 vs Baluarte.
        # Once supported by at least one specialist, diversify into G09 or
        # IFV instead of buying infinite copies of the same cheap counter.
        if our_piercers < mini(2,enemy_heavy):
            return ["piercer","tank","ifv","apc","bulwark"]
        if our_tanks < 1:
            return ["tank","ifv","piercer","apc","bulwark"]
        return ["ifv","piercer","apc","tank","bulwark"]
    if enemy_mechanized > 0:
        # Main G09 wins head-on vs IFV/APC at higher cost; IFV supports it.
        if our_tanks < 1:
            return ["tank","ifv","piercer","apc","bulwark"]
        return ["ifv","apc","piercer","tank","bulwark"]
    if enemy_indirect > 0:
        # APC's reach and cheap 11HP chassis helps close on gun platforms;
        # IFV's 5 ATK then clears vulnerable ranged units.
        if our_apcs < 1:
            return ["apc","ifv","tank","piercer","bulwark"]
        return ["ifv","tank","piercer","apc","bulwark"]
    if enemy_infantry > 0:
        # IFV uses its 5 ATK, six rounds and better sight to screen foot
        # infantry without paying full G09 price. APC adds cheap endurance.
        if our_ifvs < 1:
            return ["ifv","apc","tank","piercer","bulwark"]
        if our_apcs < 1:
            return ["apc","tank","ifv","piercer","bulwark"]
        return ["tank","ifv","piercer","apc","bulwark"]
    # With no ground contact, cheaper faster APC is a scouting/road-screen
    # investment, NOT a claim that it can load or capture infantry.
    # Once one exists, purchase a more capable IFV for the next role.
    if our_apcs < 1:
        return fallback
    if our_ifvs < 1:
        return ["ifv","tank","piercer","apc","bulwark"]
    return ["tank","piercer","ifv","apc","bulwark"]
