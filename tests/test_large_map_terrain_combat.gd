extends SceneTree

const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Rules = preload("res://scripts/core/Rules.gd")

static func _grid(size: Vector2i) -> Array:
    var output: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append("plain")
        output.append(row)
    return output

func _initialize() -> void:
    for size in [Vector2i(24,18),Vector2i(40,30)]:
        var arena: Array = _grid(size)
        var attacker_cell: Vector2i = Vector2i(size.x-4,size.y-4)
        var target_cell: Vector2i = attacker_cell+Vector2i.RIGHT
        arena[attacker_cell.y][attacker_cell.x] = "mountain"
        arena[target_cell.y][target_cell.x] = "forest"
        var friendly: Dictionary = Roles.make_unit("A",0,attacker_cell,"tank")
        var hostile: Dictionary = Roles.make_unit("B",1,target_cell,"tank")
        var initial: Dictionary = Session.start([friendly,hostile],arena,0,false,false,false,false)
        assert(Rules.valid_terrain(arena))
        assert(Terrain.tile_at(arena,attacker_cell) == "mountain")
        assert(Terrain.tile_at(arena,target_cell) == "forest")
        assert(Terrain.tile_at(arena,Vector2i(-1,0)).is_empty())
        assert(Terrain.tile_at(arena,Vector2i(size.x,size.y-1)).is_empty())
        var effects: Dictionary = Terrain.modifiers(friendly,hostile,arena,{},initial["units"])
        assert(int(effects["attack_bonus"]) == 1)
        assert(int(effects["defense_cover"]) == 1)
        assert(int(effects["height_delta"]) == 1)
        var actual: Dictionary = Session.attack(initial,"A","B")
        assert(actual.get("valid",false))
        assert(int(actual["terrain_attack_bonus"]) == 1)
        assert(int(actual["terrain_defense_cover"]) == 1)
        assert(int(actual["damage"]) > 0)
        assert(initial["units"][1]["hp"] == hostile["hp"])
        # Relocate the mountain disadvantage to the defender.
        var reverse: Dictionary = Terrain.modifiers(hostile,friendly,arena,{},initial["units"])
        assert(int(reverse["attack_bonus"]) == -1)
        assert(int(reverse["defense_cover"]) == 2)
    print("PASS full-map terrain tactics: 24x18 and 40x30 mountain, forest, uphill, counter-position and actual combat")
    quit(0)
