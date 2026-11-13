extends RefCounted
class_name TarvokaBasicAI

const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const SupplyNavigation = preload("res://scripts/core/SupplyNavigation.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const SupplyStrategy = preload("res://scripts/core/SupplyStrategy.gd")

# Tactical AI v2: bounded, deterministic, scene-independent and rule-compliant.
# Never changes the input state. One legal action at most per call.
# Fog decisions use only currently visible units and previously explored terrain.
static func step(state: Dictionary) -> Dictionary:
    var idle := {"valid": false, "state": state.duplicate(true), "action": "none"}
    if not state.has("units") or not state["units"] is Array or not state.has("terrain"):
        return idle
    if int(state.get("winner", -1)) != -1 or not Opening.can_order(state):
        return idle
    var faction := int(state.get("faction", -1))
    if faction not in [0, 1]:
        return idle
    # Decide from the currently observable units; do not inspect hidden targets.
    var knowledge: Dictionary = Visibility.observed_state(state, faction)
    var friends: Array = []
    var enemies: Array = []
    var occupied: Array[Vector2i] = []
    for unit in knowledge["units"]:
        if not unit is Dictionary or not unit.get("pos") is Vector2i:
            return idle
        if int(unit.get("hp", 0)) <= 0:
            continue
        occupied.append(unit["pos"])
        if int(unit.get("faction", -1)) == faction:
            if not bool(unit.get("acted", true)):
                friends.append(unit)
        else:
            enemies.append(unit)
    if friends.is_empty():
        var only_recruits: Dictionary = _produce_reinforcements(state, knowledge, enemies)
        return only_recruits if only_recruits.get("valid",false) else idle
    # Compare equivalent unit roles and side-normalized positions, not the
    # artificial A..F vs U..Z names assigned to mirrored starting rosters.
    friends.sort_custom(func(a, b): return _unit_before(a, b))
    enemies.sort_custom(func(a, b): return _unit_before(a, b))

    # Focus fire deliberately: a lethal strike is more valuable than simply
    # attacking the lexicographically first enemy. Use the same damage engine.
    var best_hit: Dictionary = {}
    var hit_score := -999999
    for unit in friends:
        for enemy in enemies:
            if not Logistics.can_fire(unit) or not Turns.in_attack_range(unit, enemy):
                continue
            # Use the same exchange model as the combat action, but assume
            # the visible enemy MAY still have ammo/reaction. Never inspect
            # its private stock or readiness to make a planning decision.
            var preview: Dictionary = BattleActions.public_preview_exchange(unit, enemy, knowledge["terrain"],knowledge.get("economy",{}),knowledge["units"])
            if not preview.get("valid", false):
                continue
            var damage := int(preview["damage"])
            var score := damage * 12 - int(preview["counter_damage"]) * 9
            if int(preview["attacker_hp"]) <= 0 and not bool(preview["defeated"]):
                score -= 250
            if preview["defeated"]:
                score += 1000
            # Prefer the more dangerous enemy when damage/kill is otherwise equal.
            score += int(enemy.get("attack", 0)) * 2
            if score > hit_score:
                hit_score = score
                best_hit = {"unit_id": str(unit["id"]), "enemy_id": str(enemy["id"])}
    # Guaranteed eliminations always take precedence. Otherwise preserve a
    # critically wounded soldier if a visible enemy can defeat it next turn
    # and a genuinely safe, currently visible destination exists.
    if not best_hit.is_empty() and hit_score >= 1000:
        var finishing_hit: Dictionary = Session.attack(state, best_hit["unit_id"], best_hit["enemy_id"])
        if finishing_hit.get("valid", false):
            finishing_hit["action"] = "attack"
            return finishing_hit
    # Expendable missiles must not retreat to save their own HP when a legal
    # target is currently visible. They are deliberately spent on impact.
    var expendable_choice: Dictionary = {}
    var expendable_score := -999999
    for ally in friends:
        if str(ally.get("role", "")) not in BattleActions.ONE_WAY_ROLES or not Logistics.can_fire(ally):
            continue
        for enemy in enemies:
            if not Turns.in_attack_range(ally, enemy):
                continue
            var impact: Dictionary = Roles.resolve(ally, enemy)
            if not impact.get("valid", false):
                continue
            var score: int = int(impact["damage"]) * 10 + int(enemy.get("attack", 0))
            if score > expendable_score:
                expendable_score = score
                expendable_choice = {"unit_id":str(ally["id"]), "enemy_id":str(enemy["id"])}
    if not expendable_choice.is_empty():
        var spent: Dictionary = Session.attack(state, expendable_choice["unit_id"], expendable_choice["enemy_id"])
        if spent.get("valid", false):
            spent["action"] = "attack"
            return spent

    var withdrawal: Dictionary = _defensive_retreat(state, knowledge, friends, enemies, occupied)
    if withdrawal.get("valid", false):
        return withdrawal

    # Moving no longer spends an attack. Set up a guaranteed elimination
    # *this turn* before wasting that opportunity on a nonlethal hit or relay
    # race. Use only observed enemies and terrain known to this faction.
    var finish_setup: Dictionary = _advance_finishing_hit(state, knowledge, friends, enemies, occupied)
    if finish_setup.get("valid", false):
        return finish_setup

    if not best_hit.is_empty():
        var hit: Dictionary = Session.attack(state, best_hit["unit_id"], best_hit["enemy_id"])
        if hit.get("valid", false):
            hit["action"] = "attack"
            return hit

    # Compare actual legal recovery orders against replacing those units.
    # Prioritize stranded or disarmed veterans, then affordable efficient
    # partial refills. Field cargo is prepaid; no duplicate charge.
    var rearm: Dictionary = SupplyStrategy.best_resupply(state, knowledge, faction)
    if rearm.get("valid",false):
        var supply: Dictionary = Session.resupply(state, str(rearm["unit_id"]))
        if supply.get("valid",false):
            supply["action"] = "resupply"
            supply["reason"] = str(rearm["reason"])
            return supply

    # A nearby fuel-and-ammunition truck can move toward a stranded ally.
    # Its destination and route are computed on observed terrain only.
    for unit in friends:
        if str(unit.get("role", "")) != "logistics":
            continue
        var truck_plan: Dictionary = SupplyNavigation.plan_truck_delivery(state, knowledge, unit)
        if not truck_plan.get("valid",false):
            continue
        var truck_move: Dictionary = Session.move(state, str(unit["id"]), truck_plan["destination"])
        if truck_move.get("valid", false):
            truck_move["action"] = "move"
            truck_move["reason"] = "field_supply"
            truck_move["unit_id"] = str(unit["id"])
            truck_move["recipient_id"] = str(truck_plan["recipient_id"])
            truck_move["destination"] = truck_plan["destination"]
            return truck_move

    # When resources become critical, preserve the platform instead of
    # marching toward another enemy. Only known, friendly, reachable depots
    # qualify; the authoritative move still rechecks fog and occupancy.
    for unit in friends:
        var return_plan: Dictionary = SupplyNavigation.plan(state, knowledge, unit)
        if not return_plan.get("valid", false):
            continue
        var back: Dictionary = Session.move(state, str(unit["id"]), return_plan["destination"])
        if back.get("valid", false):
            back["action"] = "move"
            back["reason"] = "resupply_return"
            back["unit_id"] = str(unit["id"])
            back["destination"] = return_plan["destination"]
            back["supply_site"] = return_plan["site"]
            return back

    # Safeguard one already-owned, empty relay when an *observed* enemy can
    # legally take that tile on its next turn. This comes after lethal attacks
    # and danger-aware retreat, before chasing further objectives.
    var defense: Dictionary = _defend_relay(state, knowledge, friends, enemies, occupied)
    if defense.get("valid", false):
        return defense

    # Preserve a guard/scout that is ALREADY occupying an unclaimed site:
    # it will capture at phase end. This is a planner-only 'moved' marker
    # in the observed copy; the authoritative state remains unchanged.
    # Lethal attacks, survival retreats and urgent relay defense above
    # retain their normal priority before garrison commitment.
    if knowledge.has("economy"):
        for ally in friends:
            if not Economy.can_capture(ally) or not Turns.can_move(ally, faction):
                continue
            for site in knowledge["economy"]["sites"]:
                if site["pos"] == ally["pos"] and int(site.get("owner",-1)) != faction:
                    ally["moved"] = true
                    break

    # Cities are a longer-term source of reinforcements. Only guards/scouts
    # may occupy and capture an urban site; never infer unseen defenders.
    var urban_action: Dictionary = _capture_urban_site(state, knowledge, friends, occupied)
    if urban_action.get("valid", false):
        return urban_action
    var reinforcement: Dictionary = _produce_reinforcements(state, knowledge, enemies)
    if reinforcement.get("valid", false):
        return reinforcement

    # A signal-relay match offers an alternative strategic objective.
    # Prioritize reaching a neutral or opposing relay after immediate combat.
    var objective_action: Dictionary = _advance_relay(state, knowledge, friends, occupied)
    if objective_action.get("valid", false):
        return objective_action
    if enemies.is_empty():
        return _reconnoiter(state, knowledge, friends, occupied) if Visibility.enabled(state) else idle

    # Pick the destination that meaningfully reduces route cost toward a
    # firing cell within this specific unit's attack range. Reverse Dijkstra
    # accounts for water and terrain
    # costs, unlike Manhattan pursuit that runs into impassable walls.
    var best_score := -99999999
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    for unit in friends:
        if bool(unit.get("moved", false)):
            continue
        var blocked: Array[Vector2i] = _blocked_for(knowledge, unit)
        var reachable: Dictionary = Rules.reachable(
            unit["pos"], Logistics.movement_budget(unit), knowledge["terrain"], blocked, Domains.domain(unit), Logistics.road_fast(unit)
        )
        var route: Dictionary = _approach_costs(knowledge["terrain"], enemies, blocked, unit)
        var from_route := int(route.get(unit["pos"], 999999))
        var from_direct := _closest_enemy_distance(unit["pos"], enemies)
        for y in range(Rules.map_size(knowledge["terrain"]).y):
            for x in range(Rules.map_size(knowledge["terrain"]).x):
                var cell := Vector2i(x, y)
                if cell == unit["pos"] or not reachable.has(cell):
                    continue
                var travel := int(reachable[cell])
                var score := -99999999
                if from_route < 999999 and route.has(cell):
                    var remaining := int(route[cell])
                    if remaining >= from_route:
                        continue
                    score = 100000 - remaining * 100 - travel
                elif from_route >= 999999:
                    # Fallback for disconnected battles. Approach the blockade,
                    # then hold instead of oscillating endlessly behind the wall.
                    var direct := _closest_enemy_distance(cell, enemies)
                    if direct >= from_direct:
                        continue
                    score = 0 - direct * 100 - travel
                if score > best_score or (score == best_score and _prefer_cell(cell,best_cell,faction)):
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = cell
    if not best_id.is_empty():
        var moved: Dictionary = Session.move(state, best_id, best_cell)
        if moved.get("valid", false):
            moved["action"] = "move"
            moved["unit_id"] = best_id
            moved["destination"] = best_cell
            return moved
    return idle

# Deterministic tie decisions must be invariant under horizontal
# reflection. Global 'lowest x' and insertion order previously meant that
# a path toward the center was favored on the left, but not on the right.
static func _side_x(pos: Vector2i, side: int) -> int:
    return pos.x if side == 0 else Rules.WIDTH - 1 - pos.x

static func _prefer_cell(candidate: Vector2i, previous: Vector2i, side: int) -> bool:
    if previous.x < 0:
        return true
    var forward: int = _side_x(candidate,side)
    var prior: int = _side_x(previous,side)
    if forward != prior:
        return forward > prior
    return candidate.y < previous.y

static func _unit_before(a: Dictionary, b: Dictionary) -> bool:
    var ar: String = str(a.get("role",""))
    var br: String = str(b.get("role",""))
    if ar != br:
        return ar < br
    var ax: int = _side_x(a["pos"], int(a["faction"]))
    var bx: int = _side_x(b["pos"], int(b["faction"]))
    if ax != bx:
        return ax < bx
    if a["pos"].y != b["pos"].y:
        return a["pos"].y < b["pos"].y
    return str(a["id"]) < str(b["id"])

# Use ONLY observed positions. Air and surface may overlap without
# blocking each other, while units on the same layer cannot share a cell.
# This keeps AI routes consistent with MoveActions and fog observations.
static func _blocked_for(knowledge: Dictionary, mover: Dictionary) -> Array[Vector2i]:
    var blocked: Array[Vector2i] = []
    for occupant in knowledge.get("units", []):
        if not occupant is Dictionary or int(occupant.get("hp", 0)) <= 0:
            continue
        if str(occupant.get("id", "")) == str(mover.get("id", "")):
            continue
        if Domains.layer(occupant) == Domains.layer(mover):
            blocked.append(occupant["pos"])
    return blocked

static func _ground_occupied(knowledge: Dictionary, cell: Vector2i) -> bool:
    for occupant in knowledge.get("units", []):
        if occupant is Dictionary and int(occupant.get("hp", 0)) > 0 and Domains.domain(occupant) == Domains.GROUND and occupant.get("pos") == cell:
            return true
    return false

# Economic strategy with only side-owned credits, observed enemies and
# explored urban locations. Decisions are deterministic and bounded.
static func _produce_reinforcements(state: Dictionary, knowledge: Dictionary, enemies: Array) -> Dictionary:
    var idle := {"valid":false}
    if not knowledge.has("economy") or not knowledge.get("economy") is Dictionary:
        return idle
    var faction: int = int(state.get("faction",-1))
    var counts: Dictionary = {}
    for unit in knowledge.get("units", []):
        if int(unit.get("faction",-1)) != faction or int(unit.get("hp",0)) <= 0:
            continue
        var role: String = str(unit.get("role",""))
        counts[role] = int(counts.get(role,0)) + 1
    if bool(knowledge["economy"].get("modern", false)):
        return _produce_modern_reinforcements(state, knowledge, enemies, counts)
    var priorities: Array[String] = []
    var seen_enemy_artillery := false
    var seen_enemy_armor := false
    for enemy in enemies:
        seen_enemy_artillery = seen_enemy_artillery or str(enemy.get("role","")) == "artillery"
        seen_enemy_armor = seen_enemy_armor or str(enemy.get("role","")) == "bulwark"
    if seen_enemy_artillery:
        priorities.append("scout")
    if seen_enemy_armor:
        priorities.append("piercer")
    var cities_to_capture := false
    var explored: Dictionary = Visibility.explored_cells(state, faction) if Visibility.enabled(state) else {}
    for site in knowledge["economy"]["sites"]:
        if site["kind"] == "city" and int(site.get("owner",-1)) != faction and (not Visibility.enabled(state) or explored.has(site["pos"])):
            cities_to_capture = true
    if cities_to_capture and int(counts.get("scout",0)) < 2:
        priorities.append("scout")
    for role in ["line","piercer","bulwark","artillery","scout"]:
        if int(counts.get(role,0)) < 2:
            priorities.append(role)
    for role in ["line","scout","piercer","bulwark","artillery"]:
        priorities.append(role)
    for site in knowledge["economy"]["sites"]:
        if site["kind"] != "factory" or int(site.get("owner",-1)) != faction:
            continue
        var factory: Vector2i = site["pos"]
        for role in priorities:
            # Legality and actual funds are independently rechecked in the
            # authoritative state. No enemy treasury or hidden site owner read.
            if Economy.can_purchase(state, factory, role):
                var bought: Dictionary = Session.purchase(state, factory, role)
                if bought.get("valid",false):
                    bought["action"] = "produce"
                    bought["factory"] = factory
                    bought["reason"] = "reinforce"
                    return bought
    return idle

# Modern factions use ALL specialist installations; purchase actions are
# still checked by the identical budget, terrain, layer and ownership rules
# used for touchscreen purchases. Only OBSERVED air/naval threats affect
# counter-unit ordering, never hidden opponents or opponent money.
static func _produce_modern_reinforcements(state: Dictionary, knowledge: Dictionary, enemies: Array, counts: Dictionary) -> Dictionary:
    var none := {"valid":false}
    var faction: int = int(state.get("faction",-1))
    var observed_air := false
    var observed_armor := false
    for enemy in enemies:
        observed_air = observed_air or Domains.domain(enemy) == Domains.AIR
        observed_armor = observed_armor or str(enemy.get("role","")) in ["tank","bulwark","ifv"]
    var strategy: Dictionary = SupplyStrategy.assess(knowledge, faction)
    var priorities := {
        "factory":["scout","assault","engineer","line","logistics"],
        "armor_plant":["piercer","tank","bulwark","ifv","apc"],
        "artillery_depot":["mobile_aa","spg","sam","artillery","mlrs","ew"],
        "drone_center":["uav_recon","fpv","loitering"],
        "airbase":["attack_heli","fighter","ucav","bomber","transport_heli"],
        "shipyard":["patrol","missile_boat","corvette","frigate","submarine","destroyer","usv","landing_ship"]
    }
    # Use known logistical demand, not hidden enemy state, when deciding
    # whether to invest in the first supply truck.
    if bool(strategy.get("need_truck", false)):
        priorities["factory"] = ["logistics","scout","assault","engineer","line"]
    if observed_air:
        priorities["artillery_depot"] = ["mobile_aa","sam","spg","artillery","mlrs","ew"]
        priorities["airbase"] = ["fighter","attack_heli","ucav","bomber","transport_heli"]
    if observed_armor:
        priorities["armor_plant"] = ["piercer","tank","ifv","bulwark","apc"]
        priorities["drone_center"] = ["fpv","loitering","uav_recon"]
    for site in knowledge["economy"]["sites"]:
        if int(site.get("owner",-1)) != faction:
            continue
        var kind: String = str(site["kind"])
        if not priorities.has(kind):
            continue
        var candidates: Array = []
        for role in priorities[kind]:
            if int(counts.get(role,0)) < 1:
                candidates.append(role)
        for role in priorities[kind]:
            candidates.append(role)
        for role in candidates:
            if not SupplyStrategy.can_spend_on_recruitment(state, faction, role, Economy.cost(role), strategy):
                continue
            if not Economy.can_purchase(state, site["pos"], role):
                continue
            var order: Dictionary = Session.purchase(state,site["pos"],role)
            if order.get("valid",false):
                order["action"] = "produce"
                order["factory"] = site["pos"]
                order["reason"] = "modern_reinforce"
                return order
    return none

static func _capture_urban_site(state: Dictionary, knowledge: Dictionary, friends: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid":false}
    if not knowledge.has("economy") or not knowledge.get("economy") is Dictionary:
        return idle
    var faction: int = int(state.get("faction",-1))
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,faction) if fog else {}
    var explored: Dictionary = Visibility.explored_cells(state,faction) if fog else {}
    var best_score := -99999999
    var best_id := ""
    var best_cell := Vector2i(-1,-1)
    var best_kind := ""
    for unit in friends:
        if not Economy.can_capture(unit) or not Turns.can_move(unit,faction):
            continue
        var blockers: Array[Vector2i] = _blocked_for(knowledge, unit)
        # A unit already securing an installation must stay until end-turn
        # rather than abandoning the city immediately before capture.
        var already_holding := false
        for owned_site in knowledge["economy"]["sites"]:
            if owned_site["pos"] == unit["pos"] and int(owned_site.get("owner",-1)) != faction:
                already_holding = true
                break
        if already_holding:
            continue
        var reachable: Dictionary = Rules.reachable(unit["pos"],Logistics.movement_budget(unit),knowledge["terrain"],blockers,Domains.domain(unit),Logistics.road_fast(unit))
        for site in knowledge["economy"]["sites"]:
            if int(site.get("owner",-1)) == faction:
                continue
            var target: Vector2i = site["pos"]
            # Neither the player's board nor the AI knows unexplored
            # installations under fog. Explored but unseen = valid lead.
            if fog and not explored.has(target):
                continue
            if target in blockers:
                continue
            var route: Dictionary = _route_to_relay(knowledge["terrain"],target,blockers)
            var current_cost: int = int(route.get(unit["pos"],999999))
            if current_cost == 0 or current_cost >= 999999:
                continue
            for cell in reachable:
                var destination: Vector2i = cell
                if destination == unit["pos"] or (fog and not visible.has(destination)):
                    continue
                if not route.has(destination) or int(route[destination]) >= current_cost:
                    continue
                var score: int = 100000 - int(route[destination])*100 - int(reachable[destination])*3
                score += 15000 if site["kind"] == "city" else 10000
                if destination == target:
                    score += 50000
                if score > best_score or (score == best_score and _prefer_cell(destination,best_cell,faction)):
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = destination
                    best_kind = str(site["kind"])
    if best_id.is_empty():
        return idle
    var order: Dictionary = Session.move(state,best_id,best_cell)
    if not order.get("valid",false):
        return idle
    order["action"] = "move"
    order["reason"] = "capture_city" if best_kind == "city" else "capture_factory"
    order["unit_id"] = best_id
    order["destination"] = best_cell
    return order

# Tactical one-step lookahead for a guaranteed elimination:
# use the legitimate move action and then check if the already observed
# target remains visible and attackable. Planning never reads a hidden
# opponent's position, attributes or map terrain.
static func _advance_finishing_hit(state: Dictionary, knowledge: Dictionary, friends: Array, enemies: Array, occupied: Array[Vector2i]) -> Dictionary:
    var none := {"valid": false}
    if enemies.is_empty():
        return none
    var faction: int = int(state["faction"])
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, faction) if fog else {}
    var best_score := -999999
    var best_cell := Vector2i(-1,-1)
    var best_order: Dictionary = {}
    for ally in friends:
        if not Turns.can_move(ally, faction):
            continue
        var blockers: Array[Vector2i] = _blocked_for(knowledge, ally)
        var reachable: Dictionary = Rules.reachable(ally["pos"], Logistics.movement_budget(ally), knowledge["terrain"], blockers, Domains.domain(ally), Logistics.road_fast(ally))
        for enemy in enemies:
            if not Logistics.can_fire(ally):
                continue
            for y in range(Rules.map_size(knowledge["terrain"]).y):
                for x in range(Rules.map_size(knowledge["terrain"]).x):
                    var cell := Vector2i(x, y)
                    if cell == ally["pos"] or not reachable.has(cell) or (fog and not visible.has(cell)):
                        continue
                    var attacker: Dictionary = ally.duplicate(true)
                    attacker["pos"] = cell
                    if not Turns.in_attack_range(attacker, enemy):
                        continue
                    var simulated: Dictionary = BattleActions.public_preview_exchange(attacker,enemy,knowledge["terrain"],knowledge.get("economy",{}),knowledge["units"])
                    if not simulated.get("valid",false) or not simulated.get("defeated",false):
                        continue
                    var score: int = 100000 + int(enemy.get("attack", 0)) * 10 - int(reachable[cell])
                    if score < best_score or (score == best_score and not _prefer_cell(cell,best_cell,faction)):
                        continue
                    # State transition is authoritative; no simulated
                    # attack is applied, and no speculative discovery is
                    # returned to the caller or used on other candidates.
                    var proposed: Dictionary = Session.move(state, str(ally["id"]), cell)
                    if not proposed.get("valid", false):
                        continue
                    if fog and not Visibility.is_unit_visible(proposed["state"], faction, str(enemy["id"])):
                        continue
                    best_score = score
                    best_cell = cell
                    best_order = proposed
                    best_order["unit_id"] = str(ally["id"])
                    best_order["target_id"] = str(enemy["id"])
                    best_order["destination"] = cell
    if best_order.is_empty():
        return none
    best_order["action"] = "move"
    best_order["reason"] = "finish_setup"
    return best_order

# Defensive AI is intentionally limited: only a unit that a *visible*
# enemy can immediately kill is eligible, and only if it can retreat beyond
# all visible adjacent attack threats. This never reads hidden enemy data.
static func _defensive_retreat(state: Dictionary, knowledge: Dictionary, friends: Array, enemies: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false}
    var faction: int = int(state.get("faction", -1))
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, faction) if fog else {}
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    var best_score := -999999
    for ally in friends:
        if bool(ally.get("moved", false)):
            continue
        var hp: int = int(ally.get("hp", 0))
        if hp <= 0 or hp > 3:
            continue
        var threatened := false
        for enemy in enemies:
            if not Turns.in_attack_range(enemy, ally):
                continue
            var incoming: Dictionary = BattleActions.public_preview_exchange(enemy,ally,knowledge["terrain"],knowledge.get("economy",{}),knowledge["units"])
            if incoming.get("valid", false) and incoming.get("defeated", false):
                threatened = true
                break
        if not threatened:
            continue
        # Withdraw only towards friendly support, never flee endlessly
        # across an empty battlefield.
        var support: Array = []
        for candidate in knowledge["units"]:
            if candidate is Dictionary and int(candidate.get("hp", 0)) > 0 and int(candidate.get("faction", -1)) == int(ally["faction"]) and str(candidate.get("id", "")) != str(ally["id"]):
                support.append(candidate)
        if support.is_empty():
            continue
        var support_before: int = _closest_enemy_distance(ally["pos"], support)
        var blocked: Array[Vector2i] = _blocked_for(knowledge, ally)
        var reachable: Dictionary = Rules.reachable(ally["pos"], Logistics.movement_budget(ally), knowledge["terrain"], blocked, Domains.domain(ally), Logistics.road_fast(ally))
        for destination in reachable:
            var cell: Vector2i = destination
            if cell == ally["pos"] or (fog and not visible.has(cell)):
                continue
            var hypothetical: Dictionary = ally.duplicate(true)
            hypothetical["pos"] = cell
            var in_enemy_range := false
            for enemy in enemies:
                if Turns.in_attack_range(enemy, hypothetical):
                    in_enemy_range = true
                    break
            if in_enemy_range:
                continue
            var nearest: int = _closest_enemy_distance(cell, enemies)
            var support_after: int = _closest_enemy_distance(cell, support)
            # Strict improvement prevents indefinite retreat oscillation.
            if support_after >= support_before or support_after > 3:
                continue
            var score: int = nearest * 100 - support_after * 15 - int(reachable[cell]) * 3
            if score > best_score or (score == best_score and _prefer_cell(cell,best_cell,faction)):
                best_score = score
                best_id = str(ally["id"])
                best_cell = cell
    if best_id.is_empty():
        return idle
    var moved: Dictionary = Session.move(state, best_id, best_cell)
    if not moved.get("valid", false):
        return idle
    moved["action"] = "move"
    moved["reason"] = "retreat"
    moved["unit_id"] = best_id
    moved["destination"] = best_cell
    return moved

# Multi-goal reversed shortest path: from an arbitrary cell to any free
# orthogonal cell adjacent to a living enemy. Never step through units or water.
# Edges are charged for the *destination* terrain in forward motion, hence
# expanding backwards charges the cell from which we are expanding.
# Reconnaissance without omniscience: rank legal *currently visible* cells by
# how much never-explored terrain a unit would reveal from there. We use the
# same movement validation as the player and never inspect hidden opponents.
static func _reconnoiter(state: Dictionary, knowledge: Dictionary, friends: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false, "state": state.duplicate(true), "action": "none"}
    var faction := int(state.get("faction", -1))
    var visible: Dictionary = Visibility.visible_cells(state, faction)
    var explored: Dictionary = Visibility.explored_cells(state, faction)
    var best_score := 0
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    var best_reason := "scout"
    # A remembered sighting is a search lead, NOT a live target or location
    # feed. Never consult the current hidden enemy position or HP.
    var sightings: Dictionary = Visibility.last_known_contacts(state, faction)
    for unit in friends:
        if bool(unit.get("moved", false)):
            continue
        var blocked: Array[Vector2i] = _blocked_for(knowledge, unit)
        var reachable: Dictionary = Rules.reachable(unit["pos"], Logistics.movement_budget(unit), knowledge["terrain"], blocked, Domains.domain(unit), Logistics.road_fast(unit))
        var radius: int = clampi(int(unit.get("vision", Visibility.DEFAULT_VISION)), 1, Visibility.MAX_VISION)
        for y in range(Rules.map_size(knowledge["terrain"]).y):
            for x in range(Rules.map_size(knowledge["terrain"]).x):
                var cell := Vector2i(x, y)
                if cell == unit["pos"] or not reachable.has(cell) or not visible.has(cell):
                    continue
                var discovery := 0
                var sweep := 0
                for dy in range(maxi(0, cell.y - radius), mini(Rules.map_size(knowledge["terrain"]).y - 1, cell.y + radius) + 1):
                    for dx in range(maxi(0, cell.x - radius), mini(Rules.map_size(knowledge["terrain"]).x - 1, cell.x + radius) + 1):
                        var unveiled := Vector2i(dx, dy)
                        if absi(unveiled.x - cell.x) + absi(unveiled.y - cell.y) <= radius:
                            if not explored.has(unveiled):
                                discovery += 1
                            elif not visible.has(unveiled):
                                # No enemies, discovery or remembered lead?
                                # Sweep previously explored but currently unseen
                                # ground, rather than idle after scouts die.
                                sweep += 1
                var investigation := 0
                for enemy_id in sightings:
                    var last_seen: Vector2i = sightings[enemy_id]
                    var improvement: int = _distance(unit["pos"], last_seen) - _distance(cell, last_seen)
                    investigation = maxi(investigation, improvement)
                var score: int = discovery * 100 + investigation * 130 - int(reachable[cell])
                var reason := "investigate" if investigation * 130 >= discovery * 100 and investigation > 0 else "scout"
                if discovery > 0 or investigation > 0:
                    score += 100000 # True exploration/leads outrank patrol.
                elif sweep > 0:
                    score = sweep * 10 - int(reachable[cell])
                    reason = "sweep"
                else:
                    continue
                if score > best_score or (score == best_score and _prefer_cell(cell,best_cell,faction)):
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = cell
                    best_reason = reason
    if best_id.is_empty():
        return idle
    var moved: Dictionary = Session.move(state, best_id, best_cell)
    if not moved.get("valid", false):
        return idle
    moved["action"] = "move"
    moved["reason"] = best_reason
    moved["unit_id"] = best_id
    moved["destination"] = best_cell
    return moved

# One-action emergency relay garrison. Only ACTUALLY observed enemy units
# can trigger it, and threat must be demonstrated by a legal terrain path.
# Occupied friendly relays already have a garrison; occupied hostile relays
# cannot be entered. Restrict to a reachable defensive move this turn to avoid
# wandering back and forth or creating an endless defensive march.
static func _defend_relay(state: Dictionary, knowledge: Dictionary, friends: Array, enemies: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false}
    if not knowledge.get("control") is Dictionary or enemies.is_empty():
        return idle
    var faction: int = int(state["faction"])
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, faction) if fog else {}
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    var best_score := -999999
    for relay in knowledge["control"]["nodes"]:
        if int(relay.get("owner", -1)) != faction:
            continue
        var cell: Vector2i = relay["pos"]
        if _ground_occupied(knowledge, cell) or (fog and not visible.has(cell)):
            continue
        var threatened := false
        for enemy in enemies:
            if Domains.domain(enemy) != Domains.GROUND:
                continue
            var blockers: Array[Vector2i] = _blocked_for(knowledge, enemy)
            var approach: Dictionary = Rules.reachable(enemy["pos"], Logistics.movement_budget(enemy), knowledge["terrain"], blockers, Domains.GROUND, Logistics.road_fast(enemy))
            if approach.has(cell):
                threatened = true
                break
        if not threatened:
            continue
        for ally in friends:
            if bool(ally.get("moved", false)) or Domains.domain(ally) != Domains.GROUND:
                continue
            # Do not desert a different relay to protect this one.
            var guard_needed_elsewhere := false
            for other in knowledge["control"]["nodes"]:
                if other["pos"] == ally["pos"] and int(other.get("owner", -1)) == faction:
                    guard_needed_elsewhere = true
                    break
            if guard_needed_elsewhere:
                continue
            var own_blockers: Array[Vector2i] = _blocked_for(knowledge, ally)
            var reachable: Dictionary = Rules.reachable(ally["pos"], Logistics.movement_budget(ally), knowledge["terrain"], own_blockers, Domains.GROUND, Logistics.road_fast(ally))
            if not reachable.has(cell) or cell == ally["pos"]:
                continue
            var score: int = 10000 - int(reachable[cell]) * 100 + int(ally.get("hp", 0))
            if score > best_score or (score == best_score and _prefer_cell(cell,best_cell,faction)):
                best_score = score
                best_id = str(ally["id"])
                best_cell = cell
    if best_id.is_empty():
        return idle
    var moved: Dictionary = Session.move(state, best_id, best_cell)
    if not moved.get("valid", false):
        return idle
    moved["action"] = "move"
    moved["reason"] = "defend_relay"
    moved["unit_id"] = best_id
    moved["destination"] = best_cell
    return moved

# Objective AI: non-omniscient weighted path to the exact relay tile.
# The world map outside explored vision is masked in `knowledge`, and
# enemy-held nodes outside line-of-sight carry owner=-2 (unknown).
static func _advance_relay(state: Dictionary, knowledge: Dictionary, friends: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false}
    if not knowledge.get("control") is Dictionary:
        return idle
    var faction: int = int(state["faction"])
    var visible: Dictionary = Visibility.visible_cells(state, faction) if Visibility.enabled(state) else {}
    var best_score := -999999
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    for unit in friends:
        if bool(unit.get("moved", false)) or Domains.domain(unit) != Domains.GROUND:
            continue
        var blocked: Array[Vector2i] = _blocked_for(knowledge, unit)
        var reachable: Dictionary = Rules.reachable(unit["pos"], Logistics.movement_budget(unit), knowledge["terrain"], blocked, Domains.GROUND, Logistics.road_fast(unit))
        for relay in knowledge["control"]["nodes"]:
            if int(relay["owner"]) == faction:
                continue
            var target: Vector2i = relay["pos"]
            if target in blocked:
                continue # No teleporting onto an occupied relay.
            var route: Dictionary = _route_to_relay(knowledge["terrain"], target, blocked)
            var current_cost: int = int(route.get(unit["pos"], 999999))
            if current_cost >= 999999 or current_cost == 0:
                continue
            for destination in reachable:
                var cell: Vector2i = destination
                if cell == unit["pos"] or (Visibility.enabled(state) and not visible.has(cell)):
                    continue
                if not route.has(cell) or int(route[cell]) >= current_cost:
                    continue
                var score: int = 100000 - int(route[cell]) * 110 - int(reachable[cell]) * 3
                if cell == target:
                    score += 50000
                if score > best_score or (score == best_score and _prefer_cell(cell,best_cell,faction)):
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = cell
    if best_id.is_empty():
        return idle
    var order: Dictionary = Session.move(state, best_id, best_cell)
    if not order.get("valid", false):
        return idle
    order["action"] = "move"
    order["reason"] = "relay"
    order["unit_id"] = best_id
    order["destination"] = best_cell
    return order

# Reverse Dijkstra: forward movement pays the cost of the entered tile.
# Bounded by board dimensions; no heuristic path through impassable unknowns.
static func _route_to_relay(terrain: Array, target: Vector2i, blocked: Array[Vector2i]) -> Dictionary:
    var distances: Dictionary = {}
    if not Rules.valid_terrain(terrain) or not Rules.inside(target,terrain) or target in blocked:
        return distances
    if Rules.movement_cost(str(terrain[target.y][target.x])) < 0:
        return distances
    distances[target] = 0
    var queue: Array[Vector2i] = [target]
    var cursor := 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        var enter_cost: int = Rules.movement_cost(str(terrain[current.y][current.x]))
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = current + direction
            if not Rules.inside(previous,terrain) or previous in blocked:
                continue
            if Rules.movement_cost(str(terrain[previous.y][previous.x])) < 0:
                continue
            var proposed: int = int(distances[current]) + enter_cost
            if not distances.has(previous) or proposed < int(distances[previous]):
                distances[previous] = proposed
                queue.append(previous)
    return distances

static func _approach_costs(terrain: Array, enemies: Array, blocked: Array[Vector2i], attacker: Dictionary) -> Dictionary:
    var distances: Dictionary = {}
    if not Rules.valid_terrain(terrain):
        return distances
    var queue: Array[Vector2i] = []
    var melee: bool = int(attacker.get("attack_min_range", 1)) == 1 and int(attacker.get("attack_range", 1)) == 1
    var domain: String = Domains.domain(attacker)
    if domain.is_empty():
        return distances
    for enemy in enemies:
        if not Domains.can_attack(attacker, enemy):
            continue
        var candidates: Array[Vector2i] = []
        if melee:
            # Preserve established melee tie-breaking and existing AI tests.
            var center: Vector2i = enemy["pos"]
            for direction in Rules.DIRECTIONS:
                candidates.append(center + direction)
        else:
            # Build actual ranged firing cells instead of trying to approach
            # an enemy until adjacent (illegal for min-range 2 artillery).
            var shooter: Dictionary = attacker.duplicate(true)
            for y in range(Rules.map_size(terrain).y):
                for x in range(Rules.map_size(terrain).x):
                    var cell := Vector2i(x, y)
                    shooter["pos"] = cell
                    if Turns.in_attack_range(shooter, enemy):
                        candidates.append(cell)
        for goal in candidates:
            if not Rules.inside(goal,terrain) or goal in blocked:
                continue
            if Rules.movement_cost_for(str(terrain[goal.y][goal.x]), domain) < 0:
                continue
            if not distances.has(goal):
                distances[goal] = 0
                queue.append(goal)
    var cursor := 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        var enter_cost := Rules.movement_cost_for(str(terrain[current.y][current.x]), domain)
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = current + direction
            if not Rules.inside(previous,terrain) or previous in blocked:
                continue
            if Rules.movement_cost_for(str(terrain[previous.y][previous.x]), domain) < 0:
                continue
            var proposed: int = int(distances[current]) + enter_cost
            if not distances.has(previous) or proposed < int(distances[previous]):
                distances[previous] = proposed
                queue.append(previous)
    return distances

static func _closest_enemy_distance(cell: Vector2i, enemies: Array) -> int:
    var distance := 999999
    for enemy in enemies:
        distance = mini(distance, _distance(cell, enemy["pos"]))
    return distance

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)
