extends Node3D
class_name TarvokaBattle3DAssetLayer

# Visual-only layer for the *real* tactical state. The authoritative board
# owns selection, movement, capture, combat, fog and saved games.
# No visual model is allowed to modify economy or unit dictionaries.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Headquarters = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const Terrain = preload("res://scripts/ui/Terrain3DMesh.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Domains = preload("res://scripts/core/Domains.gd")

const MAX_V23_TANKS := 6
const QUALITY_LOW := 0
const QUALITY_BALANCED := 1
const QUALITY_HIGH := 2
const NAVAL_MODELS := ["patrol","missile_boat","corvette","frigate",
    "submarine","landing_ship","usv"]

var _models: Dictionary = {}
var _model_specs: Dictionary = {}
var _building_models: Dictionary = {}
var _building_signature := -1
var _metrics: Dictionary = {}

static func model_for_role(role: String) -> String:
    if Models.supports(role):
        return role
    match role:
        "assault", "engineer":
            return "line"
        "bulwark", "piercer":
            return "tank"
        "ifv", "logistics", "ew", "mobile_aa":
            return "apc"
        "artillery", "spg", "sam":
            return "mlrs"
        "uav_recon", "fpv", "loitering", "ucav", "transport_heli":
            return "attack_heli"
        "bomber":
            return "fighter"
        "patrol", "missile_boat", "corvette", "frigate", "submarine", "landing_ship", "usv":
            return "destroyer"
    return "scout"

static func faction_index(state: Dictionary, side: int) -> int:
    if side < 0:
        return 0
    var choices: Dictionary = Identity.from_state(state)
    var id: int = Identity.index_for(str(choices.get(str(side),"")))
    return clampi(id if id >= 0 else side,0,7)

static func _visible_cell(grid: Array, cell: Vector2i, observed: Dictionary,
        restricted: bool, visible: Dictionary, fog: bool) -> bool:
    if fog and not visible.has(cell):
        return false
    return Terrain.observed_cell(grid,cell,observed,restricted)

static func _model_detail(role: String, is_selected: bool, quality: int,
        v23_used: int) -> int:
    if role != "tank":
        return 10
    if quality == QUALITY_LOW:
        return 10
    if quality == QUALITY_BALANCED:
        return 23 if is_selected else 15
    return 23 if is_selected or v23_used < MAX_V23_TANKS else 15

static func _marker_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.77
    mat.metallic = 0.14
    return mat

static func _box(parent: Node3D, id: String, pos: Vector3,
        dims: Vector3, color: Color) -> MeshInstance3D:
    var shape := MeshInstance3D.new()
    shape.name = id
    var box := BoxMesh.new()
    box.size = dims
    shape.mesh = box
    shape.position = pos
    shape.material_override = _marker_material(color)
    parent.add_child(shape)
    return shape

static func _proxy_site(kind: String, color: Color) -> Node3D:
    # The real HQ V13 is used only on an occupied capital city; all other
    # economic site categories get honest, inexpensive 3D stand-ins.
    var root := Node3D.new()
    root.name = "EdificioPrototipo_" + kind
    var concrete := Color("#9CA8AC")
    var dark := Color("#344B58")
    _box(root,"Base",Vector3(0,0.035,0),Vector3(0.82,0.07,0.82),concrete)
    match kind:
        "city":
            _box(root,"Centro",Vector3(-0.12,0.24,0),Vector3(0.39,0.39,0.49),color)
            _box(root,"Torre",Vector3(0.22,0.32,-0.08),Vector3(0.22,0.55,0.27),dark)
            _box(root,"Techos",Vector3(-0.12,0.45,0),Vector3(0.43,0.06,0.52),dark)
        "airbase":
            _box(root,"Pista",Vector3(0,0.085,0.02),Vector3(0.76,0.035,0.33),dark)
            _box(root,"Hangar",Vector3(-0.14,0.26,-0.24),Vector3(0.42,0.35,0.27),color)
            _box(root,"TorreControl",Vector3(0.26,0.38,-0.25),Vector3(0.12,0.57,0.12),concrete)
        "shipyard":
            _box(root,"Muelle",Vector3(0,0.115,0.07),Vector3(0.75,0.06,0.27),color)
            _box(root,"Almacen",Vector3(-0.17,0.25,-0.22),Vector3(0.36,0.29,0.30),dark)
            _box(root,"Grua",Vector3(0.26,0.43,-0.20),Vector3(0.05,0.62,0.05),concrete)
            _box(root,"BrazoGrua",Vector3(0.11,0.73,-0.20),Vector3(0.37,0.04,0.05),color)
        _:
            _box(root,"NaveIndustrial",Vector3(0,0.27,0),Vector3(0.66,0.42,0.53),color)
            _box(root,"Techo",Vector3(0,0.51,0),Vector3(0.71,0.07,0.57),dark)
            if kind in ["factory","armor_plant","artillery_depot"]:
                _box(root,"Chimenea",Vector3(0.20,0.69,-0.16),Vector3(0.11,0.40,0.11),concrete)
            elif kind == "drone_center":
                _box(root,"TorreRadar",Vector3(0.21,0.68,-0.16),Vector3(0.09,0.30,0.09),concrete)
    root.set_meta("tarvoka_visual_prototype_only",true)
    return root

func _create_unit(unit: Dictionary, model_kind: String, faction: int,
        detail: int, is_selected: bool) -> Node3D:
    var holder := Node3D.new()
    holder.name = "UnidadReal_" + str(unit.get("id",""))
    var model: Node3D = Models.build(model_kind,faction,true,detail)
    if model == null:
        holder.free()
        return null
    model.name = "MallaUnidad_" + str(unit.get("role",""))
    holder.add_child(model)
    # Authoring-space characters and vehicles occupy one 1x1 tactical tile.
    holder.scale = Vector3.ONE*0.24
    var ring := MeshInstance3D.new()
    ring.name = "IndicadorSeleccion"
    var disc := CylinderMesh.new()
    disc.top_radius = 1.52
    disc.bottom_radius = 1.52
    disc.height = 0.065
    disc.radial_segments = 24
    ring.mesh = disc
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color("#F7D35E")
    paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = paint
    ring.position.y = -0.30
    ring.visible = is_selected
    holder.add_child(ring)
    holder.set_meta("tarvoka_role",str(unit.get("role","")))
    holder.set_meta("tarvoka_model_kind",model_kind)
    holder.set_meta("tarvoka_detail_level",detail)
    holder.set_meta("tarvoka_mesh_count",Models.inspect_meshes(model)+1)
    holder.set_meta("tarvoka_role_prototype",model_kind != str(unit.get("role","")))
    return holder

func _release_instance(node: Node3D) -> void:
    if node == null:
        return
    node.visible = false
    if node.get_parent() == self:
        remove_child(node)
    node.queue_free()

func synchronize(state: Dictionary, selected: String, visible: Dictionary,
        fog: bool, grid: Array, observed: Dictionary, restricted: bool,
        quality: int) -> void:
    var requested: Dictionary = {}
    var v23_count := 0
    # The selected true G09 gets priority even if >MAX_V23_TANKS are visible.
    var units: Array = state.get("units",[])
    var ordered: Array = []
    for u in units:
        if u is Dictionary and str(u.get("id","")) == selected:
            ordered.push_front(u)
        else:
            ordered.append(u)
    for unit in ordered:
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        var cell: Variant = unit.get("pos",null)
        if not cell is Vector2i or not _visible_cell(grid,cell,observed,
                restricted,visible,fog):
            continue
        var id: String = str(unit.get("id",""))
        if id.is_empty():
            continue
        var original: String = str(unit.get("role","line"))
        var resolved: String = model_for_role(original)
        var is_selected: bool = id == selected
        var side: int = int(unit.get("faction",0))
        var faction: int = faction_index(state,side)
        var detail: int = _model_detail(original,is_selected,quality,v23_count)
        if original == "tank" and detail == 23:
            v23_count += 1
        var spec: String = "%s/%s/%d/%d" % [original,resolved,faction,detail]
        if not _models.has(id) or str(_model_specs.get(id,"")) != spec:
            if _models.has(id):
                _release_instance(_models[id])
            var instance: Node3D = _create_unit(unit,resolved,faction,detail,is_selected)
            if instance == null:
                _models.erase(id)
                _model_specs.erase(id)
                continue
            add_child(instance)
            _models[id] = instance
            _model_specs[id] = spec
        requested[id] = true
        var object: Node3D = _models[id]
        var center: Vector3 = Terrain.tactical_cell_center(
            grid,cell,observed,restricted)
        var domain: String = str(Domains.domain(unit))
        var elevation: float = 0.52 if domain == "air" else (
            0.09 if domain == "naval" else 0.06)
        object.position = center+Vector3(0,elevation,0)
        var select_disc: MeshInstance3D = object.get_node_or_null(
            "IndicadorSeleccion") as MeshInstance3D
        if select_disc != null:
            select_disc.visible = is_selected
    for id in _models.keys():
        if not requested.has(id):
            _release_instance(_models[id])
            _models.erase(id)
            _model_specs.erase(id)
    _synchronize_sites(state,visible,fog,grid,observed,restricted)
    var count_meshes := 0
    var prototypes := 0
    for id in _models:
        var entry: Node3D = _models[id]
        count_meshes += int(entry.get_meta("tarvoka_mesh_count",0))
        if bool(entry.get_meta("tarvoka_role_prototype",false)):
            prototypes += 1
    var hq_count := 0
    for id in _building_models:
        var entry: Node3D = _building_models[id]
        if bool(entry.get_meta("tarvoka_hq_production_v13",false)):
            hq_count += 1
    _metrics = {
        "3d_visible_units":_models.size(),
        "3d_unit_meshes":count_meshes,
        "3d_g09_v23":v23_count,
        "3d_role_prototypes":prototypes,
        "3d_site_models":_building_models.size(),
        "3d_headquarters_v13":hq_count,
        "3d_quality":quality,
        "3d_v23_limit":MAX_V23_TANKS
    }

func _synchronize_sites(state: Dictionary, visible: Dictionary, fog: bool,
        grid: Array, observed: Dictionary, restricted: bool) -> void:
    var economy: Dictionary = state.get("economy",{})
    var sites: Array = economy.get("sites",[])
    var stamp: int = hash([sites,visible,fog,grid,state.get("visual_factions",{})])
    if stamp == _building_signature:
        return
    _building_signature = stamp
    for id in _building_models:
        _release_instance(_building_models[id])
    _building_models.clear()
    var capital_sides: Dictionary = {}
    for i in range(sites.size()):
        var site: Dictionary = sites[i]
        var cell: Variant = site.get("pos",null)
        if not cell is Vector2i or not _visible_cell(grid,cell,
                observed,restricted,visible,fog):
            continue
        var owner: int = int(site.get("owner",-1))
        var kind: String = str(site.get("kind","city"))
        var render_as_hq: bool = kind == "city" and owner in [0,1] and (
            not capital_sides.has(owner))
        var tint: Color = Identity.color_for(state,owner) if owner in [0,1] else Color("#88949C")
        var model: Node3D
        if render_as_hq:
            capital_sides[owner] = true
            model = Headquarters.build(1,faction_index(state,owner),
                "operativo",Headquarters.QUALITY_TACTICAL,false)
        else:
            model = _proxy_site(kind,tint)
        if model == null:
            continue
        var pos: Vector3 = Terrain.tactical_cell_center(grid,cell,
            observed,restricted)
        var holder := Node3D.new()
        holder.name = "InstalacionEnBatalla_%d_%s" % [i,kind]
        holder.position = pos+Vector3(0,0.02,0)
        if render_as_hq:
            holder.scale = Vector3.ONE*0.073
            model.name = "HQ_V13_SobreCiudad"
            holder.set_meta("tarvoka_hq_production_v13",true)
        else:
            model.name = "Prototipo_" + kind
        holder.add_child(model)
        add_child(holder)
        _building_models[str(i)] = holder

func runtime_metrics() -> Dictionary:
    return _metrics.duplicate()
