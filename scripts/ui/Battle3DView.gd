extends TextureRect
class_name TarvokaBattle3DView

# Opt-in view of the AUTHORITATIVE battle. Tactical orders still belong to
# TouchBoard._tap(); this control never modifies or serializes battle state.
# Viewport input stays on the parent board (mouse_filter IGNORE), including
# all existing touch, pinch, order-confirmation and Android gesture guards.
const LabScene = preload("res://scenes/Terrain3DLab.tscn")
const Terrain3D = preload("res://scripts/ui/Terrain3DMesh.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const AssetLayer = preload("res://scripts/ui/Battle3DAssetLayer.gd")

var _viewport: SubViewport
var _lab
var _camera: Camera3D
var _asset_layer: Node3D
var _visual_quality := 2
var _telemetry_label: Label
var _telemetry_elapsed := 0.0
var _tactical_highlights: MeshInstance3D
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
    _lab = LabScene.instantiate()
    _viewport.add_child(_lab)
    _camera = _lab.get_node("IsoCamera") as Camera3D
    _asset_layer = AssetLayer.new()
    _asset_layer.name = "ModelosRealesEnPartida"
    _lab.add_child(_asset_layer)
    _tactical_highlights = MeshInstance3D.new()
    _tactical_highlights.name = "LegalTacticalHighlights"
    _lab.add_child(_tactical_highlights)
    texture = _viewport.get_texture()
    resized.connect(_resize_viewport)
    _resize_viewport()
    _telemetry_label = Label.new()
    _telemetry_label.name = "FPSModelos3D"
    _telemetry_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _telemetry_label.position = Vector2(10,10)
    _telemetry_label.add_theme_font_size_override("font_size",15)
    _telemetry_label.add_theme_color_override("font_color",Color("#F8E2A3"))
    _telemetry_label.add_theme_color_override("font_shadow_color",Color("#041726"))
    _telemetry_label.add_theme_constant_override("shadow_offset_x",2)
    _telemetry_label.add_theme_constant_override("shadow_offset_y",2)
    add_child(_telemetry_label)

func _process(delta: float) -> void:
    if not visible or _asset_layer == null:
        return
    _telemetry_elapsed += delta
    if _telemetry_elapsed < 0.7:
        return
    _telemetry_elapsed = 0.0
    var counters: Dictionary = _asset_layer.call("runtime_metrics")
    var profile: String = ["BAJO","EQUILIBRADO","ALTO V23"][_visual_quality]
    _telemetry_label.text = "FPS: %d  |  Unidades: %d  |  G09 V23: %d  |  HQ V13: %d  |  %s" % [
        Engine.get_frames_per_second(),int(counters.get("3d_visible_units",0)),
        int(counters.get("3d_g09_v23",0)),
        int(counters.get("3d_headquarters_v13",0)),profile]

func set_visual_quality(quality: int) -> void:
    _visual_quality = clampi(quality,0,2)
    _unit_signature = -1

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

# Optional live diagnostics for the upcoming physical Android QA.
# FPS is the actual running Godot frame rate, not estimated from triangles.
# No background logging, network traffic or changes to battle state.
func runtime_metrics() -> Dictionary:
    if _lab == null or _viewport == null:
        return {}
    var metrics: Dictionary = _lab.environment_metrics()
    metrics["engine_fps"] = Engine.get_frames_per_second()
    metrics["viewport_resolution"] = _viewport.size
    metrics["live_renderer_active"] = is_visible_in_tree()
    metrics["fps_sample_source"] = "running Godot instance"
    metrics["draw_calls_this_frame"] = Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    if _asset_layer != null:
        metrics.merge(_asset_layer.call("runtime_metrics"),true)
    return metrics

func set_rendering(active: bool) -> void:
    if _viewport != null:
        _viewport.render_target_update_mode = (
            SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED)

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

func _refresh_markers(state: Dictionary, selected: String,
        currently_visible: Dictionary, fog: bool, battery_saver: bool) -> void:
    if _asset_layer == null:
        return
    # Battle3DAssetLayer uses real V23 meshes, HQ V13 and native 3D sites,
    # filtered by *exactly the same fog* as the tactical renderer.
    _asset_layer.call("synchronize",state,selected,currently_visible,fog,
        _lab.terrain,_lab.observed,_lab.restrict_to_observed,
        0 if battery_saver else _visual_quality)

func sync_battle(state: Dictionary, selected: String,
        battery_saver: bool = false) -> void:
    if _lab == null or not state.get("terrain") is Array:
        return
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,0) if fog else {}
    var terrain_key: int = hash([state.get("terrain",[]),visible,fog,battery_saver])
    if terrain_key != _terrain_signature:
        _terrain_signature = terrain_key
        # Batch the visibility/terrain/quality change. Previously a
        # quality toggle rebuilt the entire world twice per turn.
        _lab.set_battle_terrain(state["terrain"],visible,fog,
            2 if battery_saver else 4)
        _unit_signature = -1
    var unit_key: int = hash([state.get("units",[]),selected,visible,fog,
        state.get("faction",-1),state.get("economy",{}),
        state.get("visual_factions",{}),_visual_quality,battery_saver])
    if unit_key != _unit_signature:
        _unit_signature = unit_key
        _refresh_markers(state,selected,visible,fog,battery_saver)
        _refresh_tactical_highlights(state,selected,visible,fog)

# Legal movement and attack previews are READ ONLY and come from the
# same TacticalHints used by the isometric board. Every quadrilateral
# is projected onto the actual 3D heightfield to avoid z-fighting.
func _highlight_cell(surface: SurfaceTool, cell: Vector2i,
        tint: Color) -> void:
    var grid: Array = _lab.terrain
    if not Terrain3D.observed_cell(grid,cell,
            _lab.observed,_lab.restrict_to_observed):
        return
    const SEGMENTS := 3
    for iy in range(SEGMENTS):
        for ix in range(SEGMENTS):
            var u0: float = float(ix)/float(SEGMENTS)
            var u1: float = float(ix+1)/float(SEGMENTS)
            var v0: float = float(iy)/float(SEGMENTS)
            var v1: float = float(iy+1)/float(SEGMENTS)
            var p00 := Vector3(float(cell.x)+u0,Terrain3D.height_at(
                grid,cell,u0,v0,_lab.observed,_lab.restrict_to_observed)+0.09,
                float(cell.y)+v0)
            var p01 := Vector3(float(cell.x)+u0,Terrain3D.height_at(
                grid,cell,u0,v1,_lab.observed,_lab.restrict_to_observed)+0.09,
                float(cell.y)+v1)
            var p10 := Vector3(float(cell.x)+u1,Terrain3D.height_at(
                grid,cell,u1,v0,_lab.observed,_lab.restrict_to_observed)+0.09,
                float(cell.y)+v0)
            var p11 := Vector3(float(cell.x)+u1,Terrain3D.height_at(
                grid,cell,u1,v1,_lab.observed,_lab.restrict_to_observed)+0.09,
                float(cell.y)+v1)
            for p in [p00,p01,p10,p10,p01,p11]:
                surface.set_color(tint)
                surface.add_vertex(p)

func _refresh_tactical_highlights(state: Dictionary,
        selected: String, visible: Dictionary, fog: bool) -> void:
    if _tactical_highlights == null:
        return
    if selected.is_empty():
        _tactical_highlights.visible = false
        return
    var hints: Dictionary = TacticalHints.for_unit(state,selected)
    var moves: Dictionary = hints.get("moves",{})
    var attacks: Dictionary = hints.get("attacks",{})
    var total := 0
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for cell in moves:
        if not cell is Vector2i or (
                fog and not visible.has(cell)) or total >= 130:
            continue
        _highlight_cell(st,cell,Color(0.19,0.78,0.94,0.24))
        total += 1
    for cell in attacks:
        if not cell is Vector2i or (
                fog and not visible.has(cell)) or total >= 160:
            continue
        _highlight_cell(st,cell,Color(1.0,0.31,0.28,0.35))
        total += 1
    if total == 0:
        _tactical_highlights.visible = false
        return
    st.generate_normals()
    var mesh := st.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.surface_set_material(0,material)
    _tactical_highlights.mesh = mesh
    _tactical_highlights.visible = true
