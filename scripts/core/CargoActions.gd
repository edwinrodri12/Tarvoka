extends RefCounted
class_name TarvokaCargoActions

const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

# Initial ground-only transport. Two infantry slots on the APC G07; IFV
# cargo needs its own independent balance decision and later release.
const CAPACITY := 2
const CARRIER_ROLE := "apc"
const PASSENGER_ROLES := ["line","scout","assault","engineer","piercer"]

static func passengers(unit: Dictionary) -> Array:
    var stored = unit.get("cargo",[])
    return stored if stored is Array and str(unit.get("role","")) == CARRIER_ROLE else []

static func _adjacent(a: Vector2i, b: Vector2i) -> bool:
    return absi(a.x-b.x)+absi(a.y-b.y) == 1

static func _preflight(units: Array, side: int, terrain: Array) -> bool:
    if side not in [0,1] or not Rules.valid_terrain(terrain):
        return false
    var ids: Dictionary = {}
    for unit in units:
        if not unit is Dictionary:
            return false
        var id = unit.get("id",null)
        if not id is String or str(id).is_empty() or ids.has(id):
            return false
        ids[id] = true
        if int(unit.get("hp",0)) <= 0:
            continue
        if not unit.get("pos") is Vector2i or not Rules.inside(unit["pos"],terrain):
            return false
        if not (unit.get("cargo",[]) is Array):
            return false
        if unit.has("cargo") and (str(unit.get("role","")) != CARRIER_ROLE or (unit["cargo"] as Array).size() > CAPACITY):
            return false
        for passenger in passengers(unit):
            if not passenger is Dictionary or not passenger.get("id") is String:
                return false
            if ids.has(passenger["id"]) or passenger.has("pos") or passenger.has("cargo"):
                return false
            ids[passenger["id"]] = true
            if str(passenger.get("role","")) not in PASSENGER_ROLES or int(passenger.get("faction",-1)) != int(unit["faction"]) or int(passenger.get("hp",0)) <= 0:
                return false
    return true

# Embark is a separate deliberate order. BOTH infantry and APC must be
# ready, stationary this turn and orthogonally adjacent on dry land.
# It consumes both actions, so loading never grants a free APC ride.
static func embark(units: Array, passenger_id: String, carrier_id: String,
        side: int, terrain: Array) -> Dictionary:
    var reject := {"valid":false,"units":units.duplicate(true)}
    if passenger_id.is_empty() or carrier_id.is_empty() or passenger_id == carrier_id or not _preflight(units,side,terrain):
        return reject
    var next: Array = units.duplicate(true)
    var passenger_index := -1
    var carrier_index := -1
    for i in range(next.size()):
        if str(next[i]["id"]) == passenger_id:
            passenger_index = i
        if str(next[i]["id"]) == carrier_id:
            carrier_index = i
    if passenger_index < 0 or carrier_index < 0:
        return reject
    var troop: Dictionary = next[passenger_index]
    var vehicle: Dictionary = next[carrier_index]
    if not Turns.can_move(troop,side) or not Turns.can_move(vehicle,side):
        return reject
    if str(troop.get("role","")) not in PASSENGER_ROLES or str(vehicle.get("role","")) != CARRIER_ROLE:
        return reject
    if Domains.domain(troop) != Domains.GROUND or Domains.domain(vehicle) != Domains.GROUND:
        return reject
    if not _adjacent(troop["pos"],vehicle["pos"]):
        return reject
    if passengers(vehicle).size() >= CAPACITY or not (vehicle.get("cargo",[]) is Array):
        return reject
    # The passenger keeps its own HP, ammunition, custom stats and identity,
    # but cannot occupy a tile, capture, fire or provide independent sight.
    var stowed: Dictionary = troop.duplicate(true)
    stowed.erase("pos")
    stowed["acted"] = true
    stowed["moved"] = true
    if not vehicle.has("cargo"):
        vehicle["cargo"] = []
    vehicle["cargo"].append(stowed)
    vehicle["acted"] = true
    vehicle["moved"] = true
    next.remove_at(passenger_index)
    return {"valid":true,"units":next,"carrier_id":carrier_id,
        "passenger_id":passenger_id,"cargo_count":passengers(vehicle).size()}

# Unload ONE passenger into a visible, unoccupied orthogonal ground tile.
# The APC may have moved earlier this turn, but cannot have attacked or
# unloaded another soldier. The deployed infantry cannot act until next turn.
static func disembark(units: Array, carrier_id: String, passenger_id: String,
        destination: Vector2i, side: int, terrain: Array) -> Dictionary:
    var reject := {"valid":false,"units":units.duplicate(true)}
    if carrier_id.is_empty() or passenger_id.is_empty() or not _preflight(units,side,terrain):
        return reject
    var next: Array = units.duplicate(true)
    var vehicle: Dictionary = {}
    for unit in next:
        if str(unit["id"]) == carrier_id:
            vehicle = unit
            break
    if vehicle.is_empty() or not Turns.can_act(vehicle,side) or str(vehicle.get("role","")) != CARRIER_ROLE:
        return reject
    if not Rules.inside(destination,terrain) or not _adjacent(vehicle["pos"],destination):
        return reject
    if Rules.movement_cost_for(str(terrain[destination.y][destination.x]),Domains.GROUND) < 0:
        return reject
    for other in next:
        if int(other.get("hp",0)) > 0 and Domains.layer(other) == "surface" and other["pos"] == destination:
            return reject
    var manifest: Array = passengers(vehicle)
    var which := -1
    for i in range(manifest.size()):
        if str(manifest[i].get("id","")) == passenger_id:
            which = i
            break
    if which < 0:
        return reject
    var infantry: Dictionary = manifest[which].duplicate(true)
    infantry["pos"] = destination
    infantry["acted"] = true
    infantry["moved"] = true
    manifest.remove_at(which)
    vehicle["acted"] = true
    vehicle["moved"] = true
    next.append(infantry)
    return {"valid":true,"units":next,"carrier_id":carrier_id,
        "passenger_id":passenger_id,"destination":destination,
        "cargo_count":manifest.size()}

# No free evacuation when a carrier is destroyed by combat or counterfire.
# Passengers disappear from the active roster; the dropped manifest cannot
# provide independent vision or resurrect after save/load.
static func eliminate_destroyed_cargo(units: Array) -> Array:
    var next: Array = units.duplicate(true)
    for unit in next:
        if unit is Dictionary and str(unit.get("role","")) == CARRIER_ROLE and int(unit.get("hp",0)) <= 0 and unit.has("cargo"):
            unit["cargo"] = []
    return next
