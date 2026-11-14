extends RefCounted
class_name TarvokaBattleRanges3D

# Advisory highlights only. Uses the actual TacticalHints API; never builds
# alternate pathfinding, fire ranges, damage estimates or game orders.
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const ROAD_CLEARANCE := 0.13
const MOVEMENT := Color(0.19,0.62,0.99,0.39)
const COVERAGE := Color(1.0,0.63,0.17,0.31)
const TARGET := Color(0.98,0.21,0.21,0.65)

static func legal_snapshot(state: Dictionary, unit_id: String,
        public_cells: Dictionary) -> Dictionary:
    var result: Dictionary = {"moves":{},"coverage":{},"attacks":{}}
    var selected: Dictionary = {}
    if unit_id.is_empty() or int(state.get("faction",-1)) != 0:
        return result
    for unit in state.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == unit_id:
            selected = unit
            break
    if selected.is_empty() or int(selected.get("hp",0)) <= 0 or int(selected.get("faction",-1)) != 0:
        return result
    var authoritative: Dictionary = Hints.for_unit(state,unit_id)
    var footprint: Dictionary = Hints.friendly_weapon_coverage(state,unit_id)
    for pos in authoritative.get("moves",{}):
        if public_cells.has(pos) and bool(public_cells[pos].get("visible",false)):
            result["moves"][pos] = authoritative["moves"][pos]
    for pos in footprint:
        if public_cells.has(pos) and bool(public_cells[pos].get("visible",false)):
            result["coverage"][pos] = true
    for pos in authoritative.get("attacks",{}):
        if public_cells.has(pos) and bool(public_cells[pos].get("visible",false)):
            result["attacks"][pos] = authoritative["attacks"][pos]
    return result

static func _surface(parent: Node3D, tool: SurfaceTool,
        size: int, label: String) -> void:
    if size == 0:
        return
    tool.generate_normals()
    var colored := MeshInstance3D.new()
    colored.name = label
    colored.mesh = tool.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.render_priority = 2
    colored.material_override = mat
    parent.add_child(colored)

static func _quad(tool: SurfaceTool, cells: Dictionary,
        cell: Vector2i, tint: Color) -> void:
    var at: Vector3 = Terrain.world_at(cell)
    var half: float = Terrain.CELL*0.49
    # Follow the same four triangles as the rendered terrain, avoiding the
    # false flat-plane highlights that clip mountains or road cutouts.
    var center: Vector3 = at+Vector3(0,
        Terrain.height_at(cells,cell)+ROAD_CLEARANCE,0)
    var nw: Vector3 = at+Vector3(-half,
        Terrain.height_at(cells,cell,-half,-half)+ROAD_CLEARANCE,-half)
    var ne: Vector3 = at+Vector3(half,
        Terrain.height_at(cells,cell,half,-half)+ROAD_CLEARANCE,-half)
    var se: Vector3 = at+Vector3(half,
        Terrain.height_at(cells,cell,half,half)+ROAD_CLEARANCE,half)
    var sw: Vector3 = at+Vector3(-half,
        Terrain.height_at(cells,cell,-half,half)+ROAD_CLEARANCE,half)
    Terrain._tri(tool,nw,center,ne,tint)
    Terrain._tri(tool,ne,center,se,tint)
    Terrain._tri(tool,se,center,sw,tint)
    Terrain._tri(tool,sw,center,nw,tint)

static func build(parent: Node3D, state: Dictionary, unit_id: String,
        public_cells: Dictionary) -> Node3D:
    var node := Node3D.new()
    node.name = "GuiasAlcance3D"
    parent.add_child(node)
    var hints: Dictionary = legal_snapshot(state,unit_id,public_cells)
    var move_mesh := SurfaceTool.new()
    var coverage_mesh := SurfaceTool.new()
    var attack_mesh := SurfaceTool.new()
    for tool in [move_mesh,coverage_mesh,attack_mesh]:
        tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var move_count: int = 0
    var coverage_count: int = 0
    var attack_count: int = 0
    # Mutually exclusive paint priority: red attack > blue destination >
    # orange weapon footprint. A highlight NEVER authorizes an order.
    for cell in hints["coverage"]:
        if hints["attacks"].has(cell) or hints["moves"].has(cell):
            continue
        _quad(coverage_mesh,public_cells,cell,COVERAGE)
        coverage_count += 1
    for cell in hints["moves"]:
        if hints["attacks"].has(cell):
            continue
        _quad(move_mesh,public_cells,cell,MOVEMENT)
        move_count += 1
    for cell in hints["attacks"]:
        _quad(attack_mesh,public_cells,cell,TARGET)
        attack_count += 1
    _surface(node,move_mesh,move_count,"DestinosLegalesAzules")
    _surface(node,coverage_mesh,coverage_count,"CoberturaPotencialNaranja")
    _surface(node,attack_mesh,attack_count,"ObjetivosAtacablesRojos")
    node.set_meta("unit_id",unit_id)
    node.set_meta("hints",hints)
    node.set_meta("counts",{"moves":move_count,
        "coverage":coverage_count,"attacks":attack_count})
    node.set_meta("visual_only",true)
    return node
