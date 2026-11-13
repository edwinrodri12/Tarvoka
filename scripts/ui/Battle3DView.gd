extends TextureRect
class_name TarvokaBattle3DView

# Opt-in view of the AUTHORITATIVE battle. Tactical orders still belong to
# TouchBoard._tap(); this control never modifies or serializes battle state.
# Viewport input stays on the parent board (mouse_filter IGNORE), including
# all existing touch, pinch, order-confirmation and Android gesture guards.
const LabScene = preload("res://scenes/Terrain3DLab.tscn")
const Terrain3D = preload("res://scripts/ui/Terrain3DMesh.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

var _viewport: SubViewport
var _lab: Node3D
var _camera: Camera3D
var _markers: Node3D
var _terrain_signature := -1
var _unit_signature := -1
var _last_size := Vector2i.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_SCALE
    _viewport = SubViewport.new()
    _viewport.name = "TacticalTerrainViewport"
    _viewport.disable_3d = false
    _viewport.transparent_bg = false
    _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _viewport.size = Vector2i(960,600)
    add_child(_viewport)
    _lab = LabScene.instantiate() as Node3D
    _viewport.add_child(_lab)
    _camera = _lab.get_node("IsoCamera") as Camera3D
    _markers = Node3D.new()
    _markers.name = "VisibleTacticalMarkers"
    _lab.add_child(_markers)
    texture = _viewport.get_texture()
    resized.connect(_resize_viewport)
    _resize_viewport()

func _resize_viewport() -> void:
    if _viewport == null or size.x < 16 or size.y < 16:
        return
    # Limit offscreen memory/GPU load on Android without changing touch math.
    var ratio: float = minf(1.0,1200.0/maxf(size.x,size.y))
    var dimensions := Vector2i(maxi(160,roundi(size.x*ratio)),
        maxi(128,roundi(size.y*ratio)))
    if dimensions != _last_size:
        _last_size = dimensions
        _viewport.size = dimensions

func _local_to_viewport(point: Vector2) -> Vector2:
    if _viewport == null or size.x < 1.0 or size.y < 1.0:
        return point
    return Vector2(point.x*float(_viewport.size.x)/size.x,
        point.y*float(_viewport.size.y)/size.y)

func _surface_intersection(point: Vector2) -> Vector3:
    if _camera == null or _lab == null or _lab.terrain.is_empty():
        return Vector3(INF,INF,INF)
    var origin: Vector3 = _camera.project_ray_origin(_local_to_viewport(point))
    var direction: Vector3 = _camera.project_ray_normal(
        _local_to_viewport(point)).normalized()
    if direction.y >= -0.01:
        return Vector3(INF,INF,INF)
    # Raycast directly against the continuous height function, not the y=0
    # plane: otherwise mountains can select a tile BEHIND the visible peak.
    var t0: float = maxf(0.0,(4.8-origin.y)/direction.y)
    var t1: float = maxf(t0+0.001,(-1.5-origin.y)/direction.y)
    var was_above := false
    var last_t := t0
    var samples := 160
    for j in range(samples+1):
        var t: float = lerpf(t0,t1,float(j)/float(samples))
        var world: Vector3 = origin+direction*t
        var cell: Vector2i = Terrain3D.tactical_cell_from_world(
            _lab.terrain,world)
        if cell.x < 0:
            was_above = false
            last_t = t
            continue
        if _lab.restrict_to_observed and not _lab.observed.has(cell):
            was_above = false
            last_t = t
            continue
        var local_u: float = clampf(world.x-float(cell.x),0.0,1.0)
        var local_v: float = clampf(world.z-float(cell.y),0.0,1.0)
        var height: float = Terrain3D.height_at(_lab.terrain,cell,
            local_u,local_v,_lab.observed,_lab.restrict_to_observed)
        if str(_lab.terrain[cell.y][cell.x]) == "water":
            height = maxf(height,Terrain3D.WATER_LEVEL)
        var above: bool = world.y >= height
        if not above:
            if not was_above:
                # A ray can enter through the side of a raised mountain.
                # The point is still a valid visible terrain cell.
                return world
            var left: float = last_t
            var right: float = t
            for _step in range(16):
                var mid: float = (left+right)*0.5
                var p: Vector3 = origin+direction*mid
                var c: Vector2i = Terrain3D.tactical_cell_from_world(
                    _lab.terrain,p)
                if c.x < 0 or (_lab.restrict_to_observed and (
                        not _lab.observed.has(c))):
                    left = mid
                    continue
                var h: float = Terrain3D.height_at(_lab.terrain,c,
                    p.x-float(c.x),p.z-float(c.y),
                    _lab.observed,_lab.restrict_to_observed)
                if str(_lab.terrain[c.y][c.x]) == "water":
                    h = maxf(h,Terrain3D.WATER_LEVEL)
                if p.y >= h:
                    left = mid
                else:
                    right = mid
            return origin+direction*((left+right)*0.5)
        was_above = true
        last_t = t
    return Vector3(INF,INF,INF)

func cell_at_screen(point: Vector2) -> Vector2i:
    var world: Vector3 = _surface_intersection(point)
    if is_inf(world.x):
        return Vector2i(-1,-1)
    return Terrain3D.tactical_cell_from_world(_lab.terrain,world)

func _world_at(point: Vector2) -> Vector3:
    var hit: Vector3 = _surface_intersection(point)
    if not is_inf(hit.x):
        return hit
    if _camera == null:
        return Vector3(INF,INF,INF)
    var o: Vector3 = _camera.project_ray_origin(_local_to_viewport(point))
    var ray: Vector3 = _camera.project_ray_normal(
        _local_to_viewport(point))
    if ray.y >= -0.01:
        return Vector3(INF,INF,INF)
    return o+ray*((0.0-o.y)/ray.y)

func zoom_anchored(scale: float, old_anchor: Vector2,
        new_anchor: Vector2) -> void:
    if _camera == null or scale <= 0.0:
        return
    var before: Vector3 = _world_at(old_anchor)
    _camera.size = clampf(_camera.size/scale,5.0,130.0)
    var after: Vector3 = _world_at(new_anchor)
    if not is_inf(before.x) and not is_inf(after.x):
        _camera.position += Vector3(
            before.x-after.x,0,before.z-after.z)

func pan_pixels(delta: Vector2) -> void:
    if _camera == null or _viewport == null:
        return
    var scale: float = _camera.size/maxf(1.0,float(_viewport.size.y))
    var amount: Vector3 = (_camera.global_transform.basis.x*
        (delta.x*scale)+_camera.global_transform.basis.y*
        (delta.y*scale))
    _camera.position -= Vector3(amount.x,0,amount.z)

func focus_cell(cell: Vector2i, zoom_level: float = -1.0) -> bool:
    if _camera == null or _lab == null or not Terrain3D.observed_cell(
            _lab.terrain,cell,_lab.observed,_lab.restrict_to_observed):
        return false
    var point: Vector3 = Terrain3D.tactical_cell_center(
        _lab.terrain,cell,_lab.observed,_lab.restrict_to_observed)
    var span: float = 10.0
    for line in _lab.terrain:
        if line is Array:
            span = maxf(span,float((line as Array).size()))
    span = maxf(span,float(_lab.terrain.size()))
    var next_size: float = _camera.size if zoom_level < 0.0 else (
        clampf(span/zoom_level,6.0,110.0))
    var distance: float = maxf(12.0,span*2.5)
    var forward: Vector3 = -_camera.global_transform.basis.z
    _camera.position = point-forward*distance
    _camera.size = next_size
    return true

func reset_camera() -> void:
    if _lab != null:
        _lab._fit_camera()

func _marker_box(name: String, position: Vector3, color: Color,
        scale: Vector3) -> void:
    var visual := MeshInstance3D.new()
    visual.name = name
    var shape := CapsuleMesh.new()
    shape.radius = 0.19
    shape.height = 0.57
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.72
    material.metallic = 0.16
    shape.material = material
    visual.mesh = shape
    visual.position = position
    visual.scale = scale
    _markers.add_child(visual)

func _refresh_markers(state: Dictionary, selected: String,
        currently_visible: Dictionary, fog: bool) -> void:
    for node in _markers.get_children():
        node.queue_free()
    var observed: Dictionary = _lab.observed
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        var cell = unit.get("pos",null)
        if not cell is Vector2i:
            continue
        if fog and not currently_visible.has(cell):
            continue
        if not Terrain3D.observed_cell(_lab.terrain,cell,
                observed,_lab.restrict_to_observed):
            continue
        var side: int = int(unit.get("faction",-1))
        var color := Color("#398BE2") if side == 0 else Color("#CF5559")
        var center: Vector3 = Terrain3D.tactical_cell_center(
            _lab.terrain,cell,observed,_lab.restrict_to_observed)
        var selected_unit: bool = str(unit.get("id","")) == selected
        if selected_unit:
            color = Color("#F5E39A")
        _marker_box("Unit_"+str(unit.get("id","")),center+Vector3(
            0,0.37,0),color,Vector3.ONE if not selected_unit else (
            Vector3(1.25,1.25,1.25)))
    if not selected.is_empty():
        # Units remain basic colored placeholders until the approved
        # 3D unit-model branch supplies its real art.
        pass

func sync_battle(state: Dictionary, selected: String,
        battery_saver: bool = false) -> void:
    if _lab == null or not state.get("terrain") is Array:
        return
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,0) if fog else {}
    var terrain_key: int = hash([state.get("terrain",[]),visible,fog,battery_saver])
    if terrain_key != _terrain_signature:
        _terrain_signature = terrain_key
        _lab.set_quality(2 if battery_saver else 4)
        _lab.set_terrain(state["terrain"],visible,fog)
        _unit_signature = -1
    var unit_key: int = hash([state.get("units",[]),selected,visible,fog])
    if unit_key != _unit_signature:
        _unit_signature = unit_key
        _refresh_markers(state,selected,visible,fog)
