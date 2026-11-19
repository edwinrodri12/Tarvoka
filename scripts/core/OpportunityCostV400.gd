extends RefCounted
class_name TarvokaOpportunityCostV400

# Opt-in experimental arbiter. Decides between THREE already legal,
# independently generated one-step actions: a race to a visible contested
# relay, an urban capture, and normal reinforcement. No future state or
# unseen enemy/unit/credits are read. Never grants free orders/resources.
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const THREE_INCOME_CYCLES := 3
const URGENT_ENEMY_ETA := 1

static func _immediate_known_city(knowledge: Dictionary, side: int,
        urban: Dictionary) -> Dictionary:
    if not bool(urban.get("valid",false)) or \
            str(urban.get("action","")) != "move" or \
            str(urban.get("reason","")) != "capture_city" or \
            not urban.get("destination") is Vector2i:
        return {}
    var destination: Vector2i = urban["destination"]
    var found := false
    for site in knowledge.get("economy",{}).get("sites",[]):
        if not site is Dictionary or site.get("pos") != destination:
            continue
        if str(site.get("kind","")) == "city" and \
                int(site.get("owner",-2)) in [-1,1-side]:
            found = true
            break
    if not found:
        return {}
    var who: String = str(urban.get("unit_id",""))
    for unit in knowledge.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == who and \
                int(unit.get("faction",-1)) == side and \
                Economy.can_capture(unit):
            var credit_value: int = Economy.MODERN_CITY_INCOME if \
                bool(knowledge.get("economy",{}).get("modern",false)) \
                else Economy.CITY_INCOME
            return {
                "known_city":true,
                "next_round_income":credit_value,
                "three_round_income_opportunity":credit_value*THREE_INCOME_CYCLES
            }
    return {}

static func decide(knowledge: Dictionary, side: int,
        race: Dictionary, urban: Dictionary,
        recruit: Dictionary) -> Dictionary:
    # Flags are evaluated by BasicAI; this helper is intentionally pure,
    # deterministic and limited to a VISIBLE race candidate and normal
    # legal urban/recruit alternatives already checked by Session.
    if side not in [0,1] or \
            not bool(race.get("valid",false)) or \
            str(race.get("action","")) != "move" or \
            not race.get("destination") is Vector2i or \
            not race.get("target_relay") is Vector2i:
        return {"choice":"none","reason":"no_legal_relay_race"}
    var rival_eta: int = int(race.get("visible_enemy_eta",999999))
    var own_eta: int = int(race.get("own_eta",999999))
    var same_turn_capture: bool = \
        race["destination"] == race["target_relay"]
    var city: Dictionary = _immediate_known_city(knowledge,side,urban)
    var can_recruit: bool = bool(recruit.get("valid",false)) and \
        str(recruit.get("action","")) == "produce"
    var emergency: bool = rival_eta <= URGENT_ENEMY_ETA and \
        own_eta <= URGENT_ENEMY_ETA and same_turn_capture
    var choice := "race"
    var explanation := "contested_relay_before_nonurgent_alternatives"
    # A city taken NOW earns real income from each subsequent turn;
    # giving that up for a relay approached but NOT captured in this
    # action was harmful in the v398 holdout.
    if not city.is_empty() and not emergency:
        choice = "city"
        explanation = "immediate_city_income_outranks_delayed_relay"
    elif can_recruit and not emergency and \
            (rival_eta > 1 or own_eta > rival_eta):
        choice = "recruit"
        explanation = "affordable_force_now_outranks_nonurgent_race"
    elif bool(urban.get("valid",false)) and \
            not emergency and \
            not same_turn_capture:
        # Preserve the original AI's planned movement toward income.
        # This is NOT a claim that a remote city is already captured.
        choice = "city"
        explanation = "preserve_existing_urban_development"
    elif can_recruit and not emergency and \
            not same_turn_capture:
        choice = "recruit"
        explanation = "preserve_reinforcement_before_delayed_relay"
    elif emergency:
        explanation = "immediate_relay_capture_before_visible_enemy"
    return {
        "choice":choice,
        "reason":explanation,
        "rival_eta":rival_eta,
        "own_eta":own_eta,
        "relay_captured_by_move":same_turn_capture,
        "known_city_capture_this_action":not city.is_empty(),
        "known_city_three_round_income":int(
            city.get("three_round_income_opportunity",0)),
        "legal_recruit_available":can_recruit,
        "recruit_cost":int(recruit.get("cost",0)) if can_recruit else 0
    }
