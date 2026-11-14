extends RefCounted
class_name TarvokaThreatAwarenessData

# Advisor, NOT a predicted enemy order. Each danger is computed from a
# CURRENTLY OBSERVED enemy and its theoretical move+weapon footprint. Never
# inspect private fuel, ammo, previous actions, invisible contacts or allies
# on behalf of the player. Targets must match the inspected unit's domain.
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")

static func preview(state: Dictionary, selected_id: String, viewer: int = 0,
        vs_ai: bool = false) -> Dictionary:
    var empty := {"valid":false,"unit_id":"","cells":{},"danger":0,
        "cover":0,"destinations":0,"contacts":0,"fog":false}
    if selected_id.is_empty() or viewer not in [0,1] or not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]) or not state.get("units") is Array:
        return empty
    if int(state.get("winner",-1)) != -1 or int(state.get("faction",-1)) != viewer:
        return empty
    if vs_ai and viewer != 0:
        return empty
    var friend: Dictionary = {}
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == selected_id and int(unit.get("faction",-1)) == viewer and int(unit.get("hp",0)) > 0:
            friend = unit
            break
    if friend.is_empty() or not Turns.can_act(friend,viewer):
        return empty
    var terrain: Array = state["terrain"]
    var origin = friend.get("pos",null)
    if not origin is Vector2i or not Rules.inside(origin,terrain):
        return empty
    var hints: Dictionary = Hints.for_unit(state,selected_id)
    var destinations: Dictionary = hints.get("moves",{})
    var positions: Array[Vector2i] = [origin]
    for destination in destinations:
        if destination is Vector2i and Rules.inside(destination,terrain):
            positions.append(destination)
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if fog else {}
    var dangerous: Dictionary = {}
    var contacts := 0
    var selected_domain: String = Domains.domain(friend)
    # Prioritize information the player can actually observe. The enemy
    # inspector deliberately ignores unknown enemy ammo/fuel and actions.
    for enemy in state["units"]:
        if not enemy is Dictionary or int(enemy.get("faction",-1)) == viewer or int(enemy.get("hp",0)) <= 0:
            continue
        var enemy_pos = enemy.get("pos",null)
        if not enemy_pos is Vector2i or (fog and not visible.has(enemy_pos)):
            continue
        if selected_domain not in Domains.targets(enemy):
            continue
        var intel: Dictionary = Hints.inspect_enemy(state,str(enemy.get("id","")),viewer)
        if not bool(intel.get("valid",false)) or intel.get("attacks",{}).is_empty():
            continue
        contacts += 1
        var reach: Dictionary = intel["attacks"]
        for destination in positions:
            if reach.has(destination):
                dangerous[destination] = int(dangerous.get(destination,0))+1
    var cells: Dictionary = {}
    var threatened := 0
    var protected := 0
    for position in positions:
        if fog and not visible.has(position):
            continue
        var type: String = Terrain.tile_at(terrain,position)
        var cover := 0
        # Air and naval units do not benefit from LAND terrain coverage.
        if selected_domain == Domains.GROUND:
            cover = int(Terrain.COVER.get(type,0))
            if Terrain.city_at(state.get("economy",{}),position):
                cover += Terrain.CITY_COVER
        var threats: int = int(dangerous.get(position,0))
        if threats > 0:
            threatened += 1
        if cover > 0:
            protected += 1
        cells[position] = {
            "threats":threats,"cover":cover,
            "current":position == origin
        }
    return {
        "valid":true,"unit_id":selected_id,
        "cells":cells,"danger":threatened,"cover":protected,
        "destinations":maxi(0,cells.size()-1),
        "contacts":contacts,"fog":fog
    }
