extends RefCounted
class_name TarvokaTacticalHints

const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")

# UI-only advisory information. All calculations use the same movement and
# combat rules as actual actions; this module never mutates the battle state.
static func for_unit(state: Dictionary, unit_id: String) -> Dictionary:
    var empty := {"moves": {}, "attacks": {}}
    if unit_id.is_empty() or int(state.get("winner", -1)) != -1:
        return empty
    if not (state.get("units") is Array) or not (state.get("terrain") is Array):
        return empty
    var units: Array = state["units"]
    var faction := int(state.get("faction", -1))
    if faction not in [0, 1]:
        return empty
    var visible: Dictionary = Visibility.visible_cells(state, faction) if Visibility.enabled(state) else {}
    var unit: Dictionary = {}
    var occupied_by_layer: Dictionary = {}
    var ids := {}
    for candidate in units:
        if not (candidate is Dictionary):
            return empty
        var candidate_id = candidate.get("id", null)
        if not (candidate_id is String) or candidate_id.is_empty() or ids.has(candidate_id):
            return empty
        ids[candidate_id] = true
        if int(candidate.get("hp", 0)) <= 0:
            continue
        var location = candidate.get("pos", null)
        if not (location is Vector2i) or not Rules.inside(location):
            return empty
        if Domains.domain(candidate).is_empty():
            return empty
        if not Visibility.enabled(state) or int(candidate.get("faction", -1)) == faction or visible.has(location):
            var layer: String = Domains.layer(candidate)
            if not occupied_by_layer.has(layer):
                occupied_by_layer[layer] = []
            if location in occupied_by_layer[layer]:
                return empty
            occupied_by_layer[layer].append(location)
        if candidate_id == unit_id:
            unit = candidate
    if unit.is_empty() or not Turns.can_act(unit, faction):
        return empty
    var origin: Vector2i = unit["pos"]
    var blockers: Array[Vector2i] = []
    for cell in occupied_by_layer.get(Domains.layer(unit), []):
        blockers.append(cell)
    blockers.erase(origin)
    var moves: Dictionary = {}
    if Turns.can_move(unit, faction):
        moves = Rules.reachable(origin, Logistics.movement_budget(unit), state["terrain"], blockers, Domains.domain(unit))
        moves.erase(origin)
    if Visibility.enabled(state):
        for cell in moves.keys():
            if not visible.has(cell):
                moves.erase(cell)
    var attacks: Dictionary = {}
    if not Logistics.can_fire(unit):
        return {"moves": moves, "attacks": attacks}
    for enemy in units:
        if int(enemy.get("hp", 0)) <= 0 or int(enemy.get("faction", -1)) == faction:
            continue
        var enemy_pos: Vector2i = enemy["pos"]
        if Visibility.enabled(state) and not visible.has(enemy_pos):
            continue
        if not Turns.in_attack_range(unit, enemy):
            continue
        var result: Dictionary = BattleActions.preview_exchange(unit, enemy)
        if result.get("valid", false):
            attacks[enemy_pos] = {
                "id": str(enemy["id"]), "damage": int(result["damage"]),
                "counter_damage": int(result["counter_damage"]),
                "defeated": bool(result["defeated"])
            }
    return {"moves": moves, "attacks": attacks}

# Separate from for_unit()["attacks"], which contains ONLY currently legal
# enemy targets. This is the WEAPON FOOTPRINT from the selected unit's
# existing position (no move-then-fire prediction and no new action).
# Only currently visible cells are highlighted in fog mode. A cell must
# support at least one of the weapon's target domains: land, water or air.
static func friendly_weapon_coverage(state: Dictionary, unit_id: String) -> Dictionary:
    var coverage: Dictionary = {}
    if unit_id.is_empty() or int(state.get("winner",-1)) != -1 or not state.get("units") is Array or not state.get("terrain") is Array:
        return coverage
    var faction: int = int(state.get("faction",-1))
    if faction not in [0,1]:
        return coverage
    var firing: Dictionary = {}
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == unit_id:
            firing = unit
            break
    if firing.is_empty() or not Turns.can_act(firing,faction) or not Logistics.can_fire(firing):
        return coverage
    if int(firing.get("attack",0)) <= 0 or Domains.targets(firing).is_empty():
        return coverage
    var low: int = int(firing.get("attack_min_range",1))
    var high: int = int(firing.get("attack_range",1))
    if low < 1 or high < low or high > 8:
        return coverage
    var origin: Vector2i = firing.get("pos", Vector2i(-1,-1))
    if not Rules.inside(origin):
        return coverage
    var visible: Dictionary = Visibility.visible_cells(state,faction) if Visibility.enabled(state) else {}
    var targets: Array = Domains.targets(firing)
    var terrain: Array = state["terrain"]
    if terrain.size() != Rules.HEIGHT:
        return coverage
    for y in range(Rules.HEIGHT):
        if not terrain[y] is Array or terrain[y].size() != Rules.WIDTH:
            return {}
        for x in range(Rules.WIDTH):
            var cell := Vector2i(x,y)
            var distance: int = absi(x-origin.x) + absi(y-origin.y)
            if distance < low or distance > high or (Visibility.enabled(state) and not visible.has(cell)):
                continue
            var tile: String = str(terrain[y][x])
            var valid_target_domain: bool = Domains.AIR in targets
            valid_target_domain = valid_target_domain or (Domains.NAVAL in targets and tile == "water")
            valid_target_domain = valid_target_domain or (Domains.GROUND in targets and tile != "water")
            if valid_target_domain:
                coverage[cell] = true
    return coverage

# Explain movement costs without implying combat bonuses from terrain:
# terrain currently affects path cost; combat cover belongs to the unit.
static func terrain_name(kind: String) -> String:
    match kind:
        "plain":
            return "Llanura"
        "forest":
            return "Bosque"
        "road":
            return "Camino"
        "mountain":
            return "Montana"
        "water":
            return "Agua"
        _:
            return "Desconocido"

static func unit_summary(state: Dictionary, unit_id: String) -> String:
    if unit_id.is_empty() or not (state.get("units") is Array):
        return "Toca una unidad azul para ver su alcance."
    for unit in state["units"]:
        if not (unit is Dictionary) or str(unit.get("id", "")) != unit_id:
            continue
        if Visibility.enabled(state) and not Visibility.is_unit_visible(state, int(state.get("faction", -1)), unit_id):
            return "Unidad no disponible."
        var hints: Dictionary = for_unit(state, unit_id)
        var availability: String = "Actuo" if bool(unit.get("acted", false)) else ("Movio; puede atacar" if bool(unit.get("moved", false)) else "Disponible")
        var text: String = "%s | Vida %d | Ataque %d | Defensa %d | Movimiento %d | %s | %d destinos / %d objetivos" % [
            unit_id, int(unit.get("hp", 0)), int(unit.get("attack", 0)),
            int(unit.get("defense", 0)), int(unit.get("move_points", 0)),
            availability, hints["moves"].size(), hints["attacks"].size()
        ]
        text += " | Alcance ataque %d-%d" % [int(unit.get("attack_min_range", 1)), int(unit.get("attack_range", 1))]
        var weapon_area: Dictionary = friendly_weapon_coverage(state,unit_id)
        if not weapon_area.is_empty():
            text += "\nAzul: movimiento legal | Naranja: cobertura del arma desde esta casilla | Rojo: objetivo atacable ahora."
        elif int(unit.get("attack",0)) <= 0 or Domains.targets(unit).is_empty():
            text += "\nSin armamento ofensivo."
        elif not Logistics.can_fire(unit):
            text += "\nArma sin municion: no puede disparar."
        elif bool(unit.get("acted",false)):
            text += "\nYa actuo: no puede volver a disparar este turno."
        if unit.has("ammo"):
            var role_key: String = str(unit.get("role", ""))
            text += " | Municion %d/%d" % [int(unit["ammo"]), Logistics.ammo_capacity(role_key)]
            if Logistics.fuel_capacity(role_key) > 0:
                text += " | Combustible %d/%d" % [int(unit["fuel"]), Logistics.fuel_capacity(role_key)]
            else:
                text += " | A pie (sin combustible)"
            if role_key == "logistics":
                text += " | Carga del camion: municion %d/%d, combustible %d/%d" % [
                    int(unit.get("supply_ammo", Logistics.TRUCK_AMMO_CAP)), Logistics.TRUCK_AMMO_CAP,
                    int(unit.get("supply_fuel", Logistics.TRUCK_FUEL_CAP)), Logistics.TRUCK_FUEL_CAP
                ]
            var warning: String = Logistics.alert(unit)
            if not warning.is_empty():
                text += "\nATENCION: " + warning
            var supply_order: Dictionary = Logistics.quote(state, unit_id)
            if supply_order.get("valid", false):
                text += "\nRecarga desde %s: +%d municion, +%d combustible (%s)" % [
                    "camion" if str(supply_order["source_kind"]) == "truck" else "base",
                    int(supply_order["ammo"]), int(supply_order["fuel"]),
                    "sin costo" if int(supply_order["cost"]) == 0 else "-%d creditos" % int(supply_order["cost"])
                ]
                if int(supply_order["cargo_ammo"]) + int(supply_order["cargo_fuel"]) > 0:
                    text += " | Carga camion: +%d municion, +%d combustible" % [
                        int(supply_order["cargo_ammo"]), int(supply_order["cargo_fuel"])
                    ]
        if unit.has("domain") or unit.has("target_domains"):
            text += " | Dominio: %s | Objetivos: %s" % [Domains.domain(unit), ", ".join(Domains.targets(unit))]
        if Visibility.enabled(state):
            text += " | Vision %d" % int(unit.get("vision", Visibility.DEFAULT_VISION))
        # The selected own unit is necessarily in the player's sight.
        # In fog we never reveal terrain from another unrevealed coordinate.
        var location = unit.get("pos", null)
        if location is Vector2i and Rules.inside(location) and state.get("terrain") is Array:
            var own_faction: int = int(state.get("faction", -1))
            var is_friendly: bool = int(unit.get("faction", -1)) == own_faction
            var visible: bool = not Visibility.enabled(state) or Visibility.visible_cells(state, own_faction).has(location)
            if is_friendly or visible:
                var terrain: Array = state["terrain"]
                if terrain.size() == Rules.HEIGHT and terrain[location.y] is Array and terrain[location.y].size() == Rules.WIDTH:
                    var kind: String = str(terrain[location.y][location.x])
                    var move_cost: int = Rules.movement_cost_for(kind, Domains.domain(unit))
                    if move_cost >= 0:
                        var role: String = Roles.label(str(unit.get("role", ""))) if unit.has("role") else ("Explorador" if int(unit.get("vision", Visibility.DEFAULT_VISION)) >= 5 else "Soldado")
                        text += "\nRol: %s | Terreno: %s (entrar cuesta %d) | Cobertura unidad: %d" % [
                            role, terrain_name(kind), move_cost, int(unit.get("cover", 0))
                        ]
        if Roles.valid(str(unit.get("role", ""))):
            text += "\n" + Roles.counter_description(str(unit["role"]))
        if not hints["attacks"].is_empty():
            var damages: PackedStringArray = []
            for target in hints["attacks"].values():
                var retaliates: int = int(target.get("counter_damage",0))
                damages.append("%s: -%d%s" % [str(target["id"]), int(target["damage"]),
                    " (respuesta -%d propia)" % retaliates if retaliates > 0 else " (sin respuesta)"])
            text += " | Danio estimado " + ", ".join(damages)
        return text
    return "Unidad no disponible."


# Enemy intelligence is a READ-ONLY UI preview, not an order or a promise
# that an opponent can move/attack this turn. Use the player's legal sight:
# never reveal an enemy in fog, remembered contacts or unexplored terrain.
# Static movement points intentionally avoid disclosing current fuel, ammo,
# hidden orders or whether the enemy already moved this phase.
static func inspect_enemy(state: Dictionary, enemy_id: String, viewer: int = 0) -> Dictionary:
    var empty: Dictionary = {"valid":false, "moves":{}, "attacks":{}, "summary":""}
    if enemy_id.is_empty() or viewer not in [0,1] or not state.get("units") is Array or not state.get("terrain") is Array:
        return empty
    var fogged: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, viewer) if fogged else {}
    var observed: Dictionary = Visibility.observed_state(state, viewer)
    var enemy: Dictionary = {}
    for candidate in observed.get("units",[]):
        if not candidate is Dictionary:
            continue
        if str(candidate.get("id","")) == enemy_id and int(candidate.get("faction",-1)) != viewer and int(candidate.get("hp",0)) > 0:
            enemy = candidate
            break
    if enemy.is_empty():
        return empty
    var origin: Vector2i = enemy["pos"]
    if not Rules.inside(origin) or (fogged and not visible.has(origin)):
        return empty
    var same_layer: Array[Vector2i] = []
    for unit in observed.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0 or unit["pos"] == origin:
            continue
        if Domains.layer(unit) == Domains.layer(enemy):
            same_layer.append(unit["pos"])
    var base_move: int = maxi(0,int(enemy.get("move_points",0)))
    var moves: Dictionary = Rules.reachable(origin, base_move, observed["terrain"], same_layer, Domains.domain(enemy))
    moves.erase(origin)
    if fogged:
        for cell in moves.keys():
            if not visible.has(cell):
                moves.erase(cell)
    var attacks: Dictionary = {}
    var targets: Array = Domains.targets(enemy)
    var armed: bool = int(enemy.get("attack",0)) > 0 and not targets.is_empty()
    var minimum: int = int(enemy.get("attack_min_range",1))
    var maximum: int = int(enemy.get("attack_range",1))
    if armed and minimum >= 1 and maximum >= minimum and maximum <= 8:
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                var cell := Vector2i(x,y)
                var distance: int = absi(cell.x-origin.x) + absi(cell.y-origin.y)
                if distance >= minimum and distance <= maximum and (not fogged or visible.has(cell)):
                    attacks[cell] = true
    var role: String = str(enemy.get("role",""))
    var label: String = Roles.label(role) if Roles.valid(role) else "Soldado"
    var description: String = "%s | Enemigo %s | Vida %d | Ataque %d | Defensa %d" % [
        label, enemy_id, int(enemy.get("hp",0)), int(enemy.get("attack",0)), int(enemy.get("defense",0))
    ]
    description += "\nMovimiento: %d puntos | Vision: %d | Dominio: %s" % [
        base_move, int(enemy.get("vision",Visibility.DEFAULT_VISION)), Domains.domain(enemy)
    ]
    if armed:
        description += "\nAlcance de ataque: %d-%d casillas | Ataca: %s" % [minimum,maximum,", ".join(targets)]
    else:
        description += "\nSin ataque convencional"
    description += "\nAzul: movimiento posible | Naranja: alcance desde posicion actual."
    if fogged:
        description += " Solo area visible."
    description += "\nEstimaciones teoricas: no revelan combustible, municion ni acciones restantes."
    return {"valid":true, "moves":moves, "attacks":attacks, "summary":description, "id":enemy_id}
