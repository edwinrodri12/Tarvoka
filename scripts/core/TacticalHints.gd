extends RefCounted
class_name TarvokaTacticalHints

const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const TerrainTactics = preload("res://scripts/core/TerrainTactics.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")

# UI-only advisory information. All calculations use the same movement and
# combat rules as actual actions; this module never mutates the battle state.
static func for_unit(state: Dictionary, unit_id: String) -> Dictionary:
    var empty := {"moves": {}, "attacks": {}}
    if unit_id.is_empty() or int(state.get("winner", -1)) != -1 or not Opening.can_order(state):
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
        if not (location is Vector2i) or not Rules.inside(location,state.get("terrain",[])):
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
    var transit_only: Array[Vector2i] = []
    for candidate in units:
        if int(candidate.get("hp", 0)) <= 0 or str(candidate.get("id", "")) == unit_id or Domains.layer(candidate) != Domains.layer(unit):
            continue
        if Visibility.enabled(state) and int(candidate.get("faction", -1)) != faction and not visible.has(candidate["pos"]):
            continue
        if int(candidate.get("faction", -1)) == faction:
            transit_only.append(candidate["pos"])
        else:
            blockers.append(candidate["pos"])
    var moves: Dictionary = {}
    if Turns.can_move(unit, faction):
        moves = Rules.reachable(origin, Logistics.movement_budget(unit), state["terrain"], blockers, Domains.domain(unit), Logistics.road_fast(unit), transit_only)
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
        var result: Dictionary = BattleActions.public_preview_exchange(unit, enemy, state["terrain"],state.get("economy",{}),Visibility.observed_state(state,faction)["units"])
        if result.get("valid", false):
            attacks[enemy_pos] = {
                "id": str(enemy["id"]), "damage": int(result["damage"]),
                "counter_damage": int(result["counter_damage"]),
                "terrain_attack_bonus":int(result["terrain_attack_bonus"]),
                "terrain_defense_cover":int(result["terrain_defense_cover"]),
                "flanked":bool(result["flanked"]),
                "defeated": bool(result["defeated"])
            }
    return {"moves": moves, "attacks": attacks}

# Display-only union of the weapon footprint from every available legal
# movement endpoint plus the current cell. Attack remains a SEPARATE action:
# highlighting a tile never authorizes a remote shot or a move+shot in one tap.
# Respect actual map boundaries, weapon minimum range, target domain and fog.
static func _weapon_footprint(terrain: Array, origins: Array[Vector2i], low: int, high: int, targets: Array, fogged: bool, visible: Dictionary) -> Dictionary:
    var coverage: Dictionary = {}
    var dimensions: Vector2i = Rules.map_size(terrain)
    for origin in origins:
        for dx in range(-high,high+1):
            var vertical: int = high - absi(dx)
            for dy in range(-vertical,vertical+1):
                var distance: int = absi(dx) + absi(dy)
                if distance < low:
                    continue
                var cell: Vector2i = origin + Vector2i(dx,dy)
                if cell.x < 0 or cell.x >= dimensions.x or cell.y < 0 or cell.y >= dimensions.y:
                    continue
                if fogged and not visible.has(cell):
                    continue
                var tile: String = str(terrain[cell.y][cell.x])
                var valid_domain: bool = Domains.AIR in targets
                valid_domain = valid_domain or (Domains.NAVAL in targets and tile == "water")
                valid_domain = valid_domain or (Domains.GROUND in targets and tile != "water")
                if valid_domain:
                    coverage[cell] = true
    return coverage

# Weapon THREAT from anywhere this friendly unit can legally end movement
# this turn. A unit that already moved can only shoot from its actual cell.
# Only visible destinations are offered as movement endpoints in fog.
static func friendly_weapon_coverage(state: Dictionary, unit_id: String) -> Dictionary:
    var coverage: Dictionary = {}
    if unit_id.is_empty() or int(state.get("winner",-1)) != -1 or not Opening.can_order(state) or not state.get("units") is Array or not state.get("terrain") is Array:
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
    var targets: Array = Domains.targets(firing)
    if int(firing.get("attack",0)) <= 0 or targets.is_empty():
        return coverage
    var low: int = int(firing.get("attack_min_range",1))
    var high: int = int(firing.get("attack_range",1))
    if low < 1 or high < low or high > 8:
        return coverage
    var terrain: Array = state["terrain"]
    if not Rules.valid_terrain(terrain):
        return coverage
    var origin: Vector2i = firing.get("pos", Vector2i(-1,-1))
    if not Rules.inside(origin,terrain):
        return coverage
    var positions: Array[Vector2i] = [origin]
    if Turns.can_move(firing,faction):
        var movement: Dictionary = for_unit(state,unit_id)["moves"]
        for endpoint in movement:
            positions.append(endpoint)
    var fogged: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,faction) if fogged else {}
    return _weapon_footprint(terrain,positions,low,high,targets,fogged,visible)

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
            text += "\nAzul: movimiento legal | Naranja: cobertura del arma tras mover o desde esta casilla | Rojo: objetivo atacable ahora."
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
            if not supply_order.get("valid", false) and (Logistics.ammo_capacity(role_key) > 0 or Logistics.fuel_capacity(role_key) > 0):
                text += "\nRecarga: instalacion aliada compatible o camion logistico adyacente (terrestres)."
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
        if location is Vector2i and Rules.inside(location,state.get("terrain",[])) and state.get("terrain") is Array:
            var own_faction: int = int(state.get("faction", -1))
            var is_friendly: bool = int(unit.get("faction", -1)) == own_faction
            var visible: bool = not Visibility.enabled(state) or Visibility.visible_cells(state, own_faction).has(location)
            if is_friendly or visible:
                var terrain: Array = state["terrain"]
                if Rules.valid_terrain(terrain):
                    var kind: String = str(terrain[location.y][location.x])
                    var move_cost: int = Rules.movement_cost_for(kind, Domains.domain(unit))
                    if move_cost >= 0:
                        var role: String = Roles.label(str(unit.get("role", ""))) if unit.has("role") else ("Explorador" if int(unit.get("vision", Visibility.DEFAULT_VISION)) >= 5 else "Soldado")
                        var cost_label: String = "0.5" if kind == "road" and Logistics.road_fast(unit) else str(move_cost)
                        text += "\nRol: %s | Terreno: %s (entrar cuesta %s) | Cobertura unidad: %d" % [
                            role, terrain_name(kind), cost_label, int(unit.get("cover", 0))
                        ]
                        if kind == "road" and Logistics.road_fast(unit):
                            text += " | Vehiculo motorizado: 2 casillas por punto en carretera"
                        text += "\n" + TerrainTactics.defensive_description(unit,terrain,state.get("economy",{}))
        if Roles.valid(str(unit.get("role", ""))):
            text += "\n" + Roles.counter_description(str(unit["role"]))
        if not hints["attacks"].is_empty():
            var damages: PackedStringArray = []
            for target in hints["attacks"].values():
                var retaliates: int = int(target.get("counter_damage",0))
                damages.append("%s: -%d%s" % [str(target["id"]), int(target["damage"]),
                    " (posible respuesta hasta -%d propia)" % retaliates if retaliates > 0 else " (sin respuesta prevista)"])
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
    if not Rules.inside(origin,state.get("terrain",[])) or (fogged and not visible.has(origin)):
        return empty
    var blockers: Array[Vector2i] = []
    var transit_only: Array[Vector2i] = []
    for unit in observed.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0 or unit["pos"] == origin:
            continue
        if Domains.layer(unit) != Domains.layer(enemy):
            continue
        if int(unit.get("faction", -1)) == int(enemy.get("faction", -1)):
            transit_only.append(unit["pos"])
        else:
            blockers.append(unit["pos"])
    var base_move: int = maxi(0,int(enemy.get("move_points",0)))
    var moves: Dictionary = Rules.reachable(origin, base_move, observed["terrain"], blockers, Domains.domain(enemy), Logistics.road_fast(enemy), transit_only)
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
        var positions: Array[Vector2i] = [origin]
        # Enemy movement is theoretical: never inspect its real fuel, ammo,
        # already-used actions or hidden blockers. Only observed endpoints.
        for endpoint in moves:
            positions.append(endpoint)
        attacks = _weapon_footprint(observed["terrain"],positions,minimum,maximum,targets,fogged,visible)
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
    if Logistics.road_fast(enemy):
        description += "\nMovilidad de carretera: 2 casillas por punto (vehiculo motorizado)"
    description += "\nAzul: movimiento posible | Naranja: amenaza teorica tras mover y atacar."
    if fogged:
        description += " Solo area visible."
    description += "\n" + TerrainTactics.defensive_description(enemy,observed["terrain"],observed.get("economy",{}))
    description += "\nEstimaciones teoricas: no revelan combustible, municion ni acciones restantes."
    return {"valid":true, "moves":moves, "attacks":attacks, "summary":description, "id":enemy_id}
