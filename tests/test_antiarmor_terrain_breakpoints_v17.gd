extends SceneTree

# Counterplay study: exact forward hits under existing integer damage and
# candidate +2 antiarmor, NOT simulated continuous duels. Counterattacks,
# fuel, positioning, reload and survival can prevent theoretical followups.
const Lab = preload("res://scripts/experiments/FactionPowerBalanceV17.gd")
const Tech = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

static func _shots(hp: int, damage: int) -> int:
    return ceili(float(hp)/float(maxi(1,damage)))

func _initialize() -> void:
    var counts := {"situations":0,"tech_changes_hit":0,"tech_reduces_shots":0,
        "tech_changes_ammo_reach":0,"tech_opening_kills":0,
        "unchanged_by_cover":0}
    var ammo: int = Logistics.ammo_capacity("piercer")
    assert(ammo == 4)
    var army_class: Array = Tech.ANTI_ARMOR_ROLES
    assert(army_class.size() == 9)
    for role in army_class:
        for terrain_kind in Lab.TERRAIN_TYPES:
            var sample: Dictionary = Lab.exchange("piercer",role,0,0,terrain_kind)
            assert(bool(sample.get("valid",false)))
            assert(Tech.armor_bonus(sample["attacker"],sample["defender"],2) == 2)
            var upgraded: Dictionary = Lab.project_duel(sample,"alianza_norte",false,"nearest","replace",true)
            var actual_tech: Dictionary = Tech.preview_antiarmor(sample["attacker"],sample["defender"],2,
                Lab.terrain_at(terrain_kind,sample["defender"]["pos"]),{},[sample["attacker"],sample["defender"]])
            assert(bool(actual_tech.get("valid",false)))
            assert(int(upgraded["offense"]) == int(actual_tech["damage"]))
            var base_damage: int = int(sample["actual_damage"])
            var tech_damage: int = int(upgraded["offense"])
            var hp: int = int(sample["target_hp"])
            var base_shots: int = _shots(hp,base_damage)
            var tech_shots: int = _shots(hp,tech_damage)
            assert(tech_shots <= base_shots)
            counts["situations"] += 1
            if tech_damage > base_damage:
                counts["tech_changes_hit"] += 1
            else:
                counts["unchanged_by_cover"] += 1
            if tech_shots < base_shots:
                counts["tech_reduces_shots"] += 1
            if base_shots > ammo and tech_shots <= ammo:
                counts["tech_changes_ammo_reach"] += 1
            if base_damage < hp and tech_damage >= hp:
                counts["tech_opening_kills"] += 1
            print("ARMOR_CASE_V17 target=%s terrain=%s hp=%d raw_damage=%d tech_damage=%d base_shots=%d tech_shots=%d ammo=%d baseline_first_counter=%d tech_first_counter=%d" % [
                role,terrain_kind,hp,base_damage,tech_damage,base_shots,tech_shots,ammo,
                int(sample["counter_damage"]),int(actual_tech["counter_damage"])
            ])

    var open: Dictionary = Lab.exchange("piercer","tank",0,0,"plain")
    var forest: Dictionary = Lab.exchange("piercer","tank",0,0,"forest")
    var mountain: Dictionary = Lab.exchange("piercer","tank",0,0,"mountain")
    assert(open["actual_damage"] == 2 and forest["actual_damage"] == 1 and mountain["actual_damage"] == 1)
    var a: Dictionary = Lab.project_duel(open,"alianza_norte",false,"nearest","replace",true)
    var b: Dictionary = Lab.project_duel(forest,"alianza_norte",false,"nearest","replace",true)
    var c: Dictionary = Lab.project_duel(mountain,"alianza_norte",false,"nearest","replace",true)
    assert(a["offense"] == 4 and b["offense"] == 3 and c["offense"] == 1)
    assert(_shots(14,int(a["offense"])) == ammo)
    assert(_shots(14,int(b["offense"])) > ammo)
    assert(_shots(14,int(c["offense"])) > ammo)
    print("TANK_TERRAIN_V17 plain=2_to_4_7_to_4_shots forest=1_to_3_14_to_5_shots mountain=1_to_1_14_to_14_shots")
    assert(counts["situations"] == 27)
    assert(counts["tech_changes_hit"] > 0)
    assert(counts["unchanged_by_cover"] > 0)
    assert(counts["tech_reduces_shots"] > 0)
    assert(counts["tech_opening_kills"] == 0)
    print("ANTIARMOR_SUMMARY_V17 %s" % str(counts))
    print("PASS antiarmor terrain breakpoints v17: nine supported armored targets, three terrains, exact previews, capped ammo and truthful hypothetical follow-up hits")
    quit(0)
