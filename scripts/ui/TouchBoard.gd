extends Control
class_name TarvokaTouchBoard

# Campaign scene listeners are opt-in; normal skirmishes are unaffected.
signal tactical_action_committed(facts: Dictionary)
signal tactical_phase_completed(completed_side: int)

const Session = preload("res://scripts/core/BattleSession.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const SiteOverlayData = preload("res://scripts/ui/SiteOverlayData.gd")
const SiteOverlayPainter = preload("res://scripts/ui/SiteOverlayPainter.gd")
const IsoProjection = preload("res://scripts/ui/IsoProjection.gd")
const IsoRenderer = preload("res://scripts/ui/IsoRenderer.gd")
const VisualBudget = preload("res://scripts/ui/VisualBudget.gd")
const WIDTH := 10
const HEIGHT := 8
var state: Dictionary = {}
var current_scenario_id := 0
var symmetric_setup := false
var specialized_roster := false
var modern_roster := false
var ai_enabled := true # Faction 1 is computer-controlled; disable for local two-player tests.
var autosave_enabled := false # Enabled by Main after board initializes; tests opt in explicitly.
var autosave_path := "user://tarvoka_autosave_v1.json"
var autosave_warning := ""
var campaign_locked := false
var campaign_markers: Array[Vector2i] = []
var selected_id := ""
var inspected_enemy_id := "" # Only currently visible enemy, never saved.
var require_order_confirmation := false # Main enables safer two-stage taps; legacy test boards remain immediate.
var pending_order: Dictionary = {}
var selected_factory_pos := Vector2i(-1,-1)
var inspected_cell := Vector2i(-1,-1) # UI-only terrain/building inspection; not saved.
var _site_overlay_key := -1
var _site_overlay_snapshot: Array = []
var message := "Selecciona una unidad."
var last_enemy_turn_report := ""
var last_economy_report := ""
var touch_origin := Vector2.ZERO
var touch_active := false
var touch_finger_index := -1
var touch_cancelled := false
# Every physical finger has its own position. Multitouch gestures consume
# all their releases so they never accidentally select or attack.
var _touch_points: Dictionary = {}
var _pinch_distance := 0.0
var _pinch_midpoint := Vector2.ZERO
# Display-only camera, never serialized into BattleSession.
var view_zoom := 1.0
var view_pan := Vector2.ZERO
var iso_enabled := false
var battery_saver := false
var ambient_redraw_count := 0 # Test diagnostics, no save changes.
var iso_zoom := 1.0
var iso_pan := Vector2.ZERO
var motion_effects: Array[Dictionary] = []
var unit_headings: Dictionary = {}
var art_phase := 0.0
var _ambient_accum := 0.0
const TAP_DRAG_LIMIT := 18.0
const COMBAT_EFFECT_SECONDS := 0.55
# Visual-only state. Never exported to save files or read by game rules.
var combat_effects: Array[Dictionary] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    new_game()

func new_game(scenario_id: int = 0, symmetric: bool = false, fog_mode: bool = false, relay_mode: bool = false, specialized: bool = false, economy_mode: bool = false, modern: bool = false, first_faction: int = 0, map_seed: int = 0, map_dimensions: Vector2i = Vector2i(10,8), chosen_factions: Dictionary = {}) -> void:
    campaign_locked = false
    campaign_markers.clear()
    symmetric_setup = symmetric
    specialized_roster = specialized or modern
    modern_roster = modern
    var enemy_hp: int = 10 if symmetric else 8
    var enemy_attack: int = 5 if symmetric else 4
    if not Rules.supported_size(map_dimensions):
        map_dimensions = Vector2i(10,8)
    view_zoom = 1.0
    view_pan = Vector2.ZERO
    iso_zoom = 1.0
    iso_pan = Vector2.ZERO
    _reset_touch_gesture()
    motion_effects.clear()
    unit_headings.clear()
    var is_seeded: bool = scenario_id == Scenarios.RANDOM_SCENARIO_ID and Scenarios.valid_seed(map_seed)
    current_scenario_id = Scenarios.RANDOM_SCENARIO_ID if is_seeded else (scenario_id if scenario_id >= 0 and scenario_id < Scenarios.LABELS.size() else 0)
    var terrain: Array = Scenarios.seeded_terrain(map_seed,map_dimensions) if is_seeded else Scenarios.terrain(current_scenario_id,map_dimensions)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":enemy_hp,"pos":Vector2i(8,2),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":enemy_hp,"pos":Vector2i(8,5),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false}
    ]
    if specialized_roster:
        units = Roles.experimental_armies(symmetric)
    if modern_roster:
        units = Roles.modern_armies(symmetric)
    if fog_mode and not specialized_roster:
        # Classic recon scouts are mirrored: mobility 4, sight 5.
        units.append({"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false})
        units.append({"id":"Z","faction":1,"hp":6,"pos":Vector2i(8,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false})
    if map_dimensions != Vector2i(10,8):
        for unit in units:
            var old: Vector2i = unit["pos"]
            unit["pos"] = Vector2i(Scenarios.scale_x(old.x,map_dimensions),
                Scenarios.scale_y(old.y,map_dimensions))
    var opener: int = first_faction if first_faction in [0,1] else 0
    state = Session.start(units, terrain, opener, fog_mode, relay_mode, economy_mode, modern_roster, true)
    if Identity.is_valid(chosen_factions):
        # Cosmetic team presentation only; no new engine faction values.
        state[Identity.STATE_FIELD] = chosen_factions.duplicate(true)
    inspected_cell = Vector2i(-1,-1)
    if is_seeded:
        state["map_seed"] = map_seed
    selected_factory_pos = Vector2i(-1,-1)
    selected_id = ""
    inspected_enemy_id = ""
    pending_order.clear()
    message = "Apertura equilibrada: %d ordenes disponibles para quien comienza." % Opening.remaining(state)
    last_enemy_turn_report = ""
    last_economy_report = ""
    combat_effects.clear()
    # When the user selects Red to open a single-player battle, complete
    # precisely one real AI turn BEFORE saving the starting human state.
    # Local two-player games leave Red's opening completely manual.
    if ai_enabled and int(state.get("faction",-1)) == 1 and int(state.get("winner",-1)) == -1:
        _play_ai_turn()
    _write_autosave(false)
    queue_redraw()

func set_battery_saver(enabled: bool) -> void:
    battery_saver = enabled
    _ambient_accum = 0.0
    queue_redraw()

func set_isometric(enabled: bool) -> void:
    iso_enabled = enabled
    _ambient_accum = 0.0
    touch_active = false
    touch_finger_index = -1
    touch_cancelled = false
    _touch_points.clear()
    _pinch_distance = 0.0
    _pinch_midpoint = Vector2.ZERO
    queue_redraw()

func change_iso_zoom(direction: int) -> void:
    if not iso_enabled or direction == 0:
        return
    iso_zoom = clampf(iso_zoom * (1.2 if direction > 0 else 1.0/1.2),
        IsoProjection.MIN_ZOOM, IsoProjection.MAX_ZOOM)
    queue_redraw()

func reset_iso_camera() -> void:
    iso_zoom = 1.0
    iso_pan = Vector2.ZERO
    queue_redraw()

func focus_iso_cell(cell: Vector2i) -> bool:
    if not iso_enabled or not Rules.inside(cell,state.get("terrain",[])):
        return false
    iso_pan = size*0.5 - IsoProjection.center(cell,size,iso_zoom,Vector2.ZERO,map_dimensions())
    queue_redraw()
    return true

func screen_cell(point: Vector2) -> Vector2i:
    if iso_enabled:
        return IsoProjection.screen_to_cell(point,size,iso_zoom,iso_pan,map_dimensions())
    var tile: float = _cell_size()
    if tile <= 0.0:
        return Vector2i(-1,-1)
    var relative: Vector2 = point - _board_origin()
    var dimensions: Vector2i = map_dimensions()
    if relative.x < 0.0 or relative.y < 0.0 or relative.x >= dimensions.x*tile or relative.y >= dimensions.y*tile:
        return Vector2i(-1,-1)
    return Vector2i(int(relative.x/tile),int(relative.y/tile))

func map_dimensions() -> Vector2i:
    return Rules.map_size(state.get("terrain",[])) if state.get("terrain") is Array else Vector2i(WIDTH,HEIGHT)

func change_view_zoom(direction: int) -> void:
    if iso_enabled:
        change_iso_zoom(direction)
        return
    if direction == 0:
        return
    view_zoom = clampf(view_zoom * (1.3 if direction > 0 else (1.0/1.3)),1.0,4.0)
    queue_redraw()

func reset_view_camera() -> void:
    if iso_enabled:
        reset_iso_camera()
        return
    view_zoom = 1.0
    view_pan = Vector2.ZERO
    queue_redraw()

func focus_view_cell(cell: Vector2i) -> bool:
    if iso_enabled:
        return focus_iso_cell(cell)
    var dims: Vector2i = map_dimensions()
    if cell.x < 0 or cell.y < 0 or cell.x >= dims.x or cell.y >= dims.y:
        return false
    var tile: float = _cell_size()
    view_pan = size*0.5 - ((size-Vector2(dims)*tile)*0.5 + (Vector2(cell)+Vector2(0.5,0.5))*tile)
    queue_redraw()
    return true

# Fit small tactical maps fully after resizing a device. Keeping the whole
# 10x8 map on screen matters more than centering the player's left-side units.
# Large maps continue using frame_player_force for readable unit zoom.
func frame_small_map() -> bool:
    var dimensions: Vector2i = map_dimensions()
    if size.x < 10.0 or size.y < 10.0 or dimensions.x > 12 or dimensions.y > 10:
        return false
    if iso_enabled:
        iso_zoom = 1.0
        iso_pan = Vector2.ZERO
    else:
        view_zoom = 1.0
        view_pan = Vector2.ZERO
    queue_redraw()
    return true

# Only the camera changes. Frame the player's visible army near the
# middle of the screen instead of opening a 40x30 map as tiny tiles.
# This is called on first layout, loading a match and changing projection,
# not from _process (so user panning/zooming is never overridden).
func frame_player_force() -> bool:
    if size.x < 10.0 or size.y < 10.0 or not state.has("units"):
        return false
    var count := 0
    var location := Vector2.ZERO
    for unit in state["units"]:
        if not unit is Dictionary or int(unit.get("faction",-1)) != 0 or int(unit.get("hp",0)) <= 0:
            continue
        if not unit.get("pos",null) is Vector2i:
            continue
        location += Vector2(unit["pos"])
        count += 1
    if count == 0:
        return false
    var dimensions: Vector2i = map_dimensions()
    if dimensions.x <= 0 or dimensions.y <= 0:
        return false
    location /= float(count)
    var cell := Vector2i(clampi(roundi(location.x),0,dimensions.x-1),
        clampi(roundi(location.y),0,dimensions.y-1))
    if iso_enabled:
        iso_zoom = 2.6 if dimensions.x >= 40 else (2.05 if dimensions.x >= 24 else 1.0)
        iso_zoom = clampf(iso_zoom,IsoProjection.MIN_ZOOM,IsoProjection.MAX_ZOOM)
        iso_pan = size * 0.5 - IsoProjection.center(cell,size,iso_zoom,Vector2.ZERO,dimensions)
    else:
        view_zoom = 2.15 if dimensions.x >= 40 else (1.65 if dimensions.x >= 24 else 1.0)
        var tile: float = _cell_size()
        view_pan = size * 0.5 - ((size - Vector2(dimensions)*tile)*0.5 +
            (Vector2(cell)+Vector2(0.5,0.5))*tile)
    queue_redraw()
    return true

func _cell_size() -> float:
    var dims: Vector2i = map_dimensions()
    if dims.x <= 0 or dims.y <= 0:
        return 0.0
    return minf(size.x / float(dims.x), size.y / float(dims.y)) * view_zoom

func _board_origin() -> Vector2:
    var tile: float = _cell_size()
    return (size - Vector2(map_dimensions()) * tile) * 0.5 + view_pan

# Completely opaque unknown cells prevent even subtle color-based terrain
# leaks; previously explored cells retain a dim, recognizable map surface.
static func fog_cover_color(has_explored: bool) -> Color:
    return Color(0.025, 0.035, 0.05, 0.73) if has_explored else Color(0.015, 0.025, 0.04, 1.0)

func site_overlay_snapshots() -> Array:
    if not state.has("economy"):
        return []
    # Derive only when battle data or sight changes, never on every idle frame.
    # UI-only selection is passed to painters, not stored in the snapshot.
    var key: int = hash([state.get("units",[]),state.get("economy",{}),state.get("faction",-1),
        state.get("winner",-1),state.get("fog_enabled",false),state.get("explored",{})])
    if key != _site_overlay_key:
        _site_overlay_key = key
        _site_overlay_snapshot = SiteOverlayData.snapshots(state,0)
    return _site_overlay_snapshot

func _draw() -> void:
    if iso_enabled:
        IsoRenderer.draw_board(self,state,selected_id,selected_factory_pos,
            pending_order,combat_effects,iso_zoom,iso_pan,motion_effects,art_phase,unit_headings,battery_saver,
            inspected_enemy_id,site_overlay_snapshots(),inspected_cell)
        _draw_campaign_markers()
        return
    var tile := _cell_size()
    var origin := _board_origin()
    var font := ThemeDB.fallback_font
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, 0) if fog else {}
    var explored: Dictionary = Visibility.explored_cells(state, 0) if fog else {}
    var dimensions: Vector2i = map_dimensions()
    for y in range(dimensions.y):
        for x in range(dimensions.x):
            var pos := origin + Vector2(x, y) * tile
            var terrain_type := str(state.get("terrain", [])[y][x])
            var terrain_color: Color = VisualStyle.terrain_color(terrain_type, x, y)
            draw_rect(Rect2(pos, Vector2.ONE * tile), terrain_color)
            # Subtle tile relief reads as depth without changing top-down touch geometry.
            draw_line(pos + Vector2(1, 1), pos + Vector2(tile - 1, 1), terrain_color.lightened(0.25), maxf(1.0, tile * 0.024))
            draw_line(pos + Vector2(1, tile - 1), pos + Vector2(tile - 1, tile - 1), terrain_color.darkened(0.35), maxf(1.0, tile * 0.024))
            draw_rect(Rect2(pos, Vector2.ONE * tile), Color(0.48, 0.55, 0.53, 0.60), false, 1.0)
            # Simple self-contained symbols, no borrowed art or sprite assets.
            if terrain_type == "forest":
                draw_circle(pos + tile * Vector2(0.29, 0.31), tile * 0.09, Color(0.25, 0.53, 0.27))
                draw_circle(pos + tile * Vector2(0.65, 0.27), tile * 0.11, Color(0.20, 0.45, 0.22))
            elif terrain_type == "road":
                draw_line(pos + tile * Vector2(0.12, 0.51), pos + tile * Vector2(0.88, 0.51), Color(0.71, 0.65, 0.47, 0.70), maxf(1.0, tile * 0.035))
            elif terrain_type == "mountain":
                var triangle := PackedVector2Array([
                    pos + tile * Vector2(0.18, 0.77),
                    pos + tile * Vector2(0.52, 0.23),
                    pos + tile * Vector2(0.85, 0.77)
                ])
                draw_colored_polygon(triangle, Color(0.53, 0.58, 0.65, 0.70))
            elif terrain_type == "water":
                draw_line(pos + tile * Vector2(0.19, 0.40), pos + tile * Vector2(0.79, 0.40), Color(0.38, 0.66, 0.86, 0.80), maxf(1.0, tile * 0.025))
                draw_line(pos + tile * Vector2(0.12, 0.62), pos + tile * Vector2(0.72, 0.62), Color(0.38, 0.66, 0.86, 0.65), maxf(1.0, tile * 0.025))
            if fog:
                var spot := Vector2i(x, y)
                if not visible.has(spot):
                    # Previously seen terrain remains dim; unknown areas are dark.
                    var shade: Color = fog_cover_color(explored.has(spot))
                    draw_rect(Rect2(pos, Vector2.ONE * tile), shade)
    # Mission markers are objectives, not selectable enemy units. Under fog,
    # unknown objectives are concealed, while already explored objectives
    # remain marked without revealing their CURRENT owner until visible.
    if state.has("control"):
        for node in state["control"]["nodes"]:
            var objective_cell: Vector2i = node["pos"]
            if fog and not explored.has(objective_cell):
                continue
            var known_owner: int = int(node["owner"]) if not fog or visible.has(objective_cell) else -1
            var signal_color := Color(0.95, 0.76, 0.30)
            if known_owner == 0:
                signal_color = Color(0.30, 0.68, 1.0)
            elif known_owner == 1:
                signal_color = Color(1.0, 0.45, 0.36)
            var signal_center: Vector2 = origin + (Vector2(objective_cell) + Vector2(0.5, 0.5)) * tile
            var marker: PackedVector2Array = PackedVector2Array([
                signal_center + Vector2(0, -tile * 0.30),
                signal_center + Vector2(tile * 0.30, 0),
                signal_center + Vector2(0, tile * 0.30),
                signal_center + Vector2(-tile * 0.30, 0)
            ])
            marker.append(marker[0])
            draw_polyline(marker, signal_color, maxf(2.0, tile * 0.055), true)
    # Decorative overlays reuse one fog-safe snapshot on classic and iso maps.
    # Enemy property changes outside sight remain visually unconfirmed.
    if state.has("economy"):
        for marker in site_overlay_snapshots():
            var city_cell: Vector2i = marker["pos"]
            var city_tint: Color = SiteOverlayPainter.owner_tint(int(marker["owner"]),state)
            var top_left := origin + Vector2(city_cell) * tile
            var center := top_left + Vector2.ONE * (tile * 0.5)
            var is_town: bool = str(marker["kind"]) == "city"
            var half: float = tile * (0.30 if is_town else 0.35)
            draw_rect(Rect2(center-Vector2.ONE*half,Vector2.ONE*(half*2)),Color(0.03,0.07,0.10,0.82))
            draw_rect(Rect2(center-Vector2.ONE*half,Vector2.ONE*(half*2)),city_tint,false,maxf(2.0,tile*0.065))
            if tile >= 20.0:
                var markers := {"city":"C","factory":"F","armor_plant":"B","artillery_depot":"A","drone_center":"D","airbase":"H","shipyard":"P"}
                var symbol: String = str(markers.get(str(marker["kind"]),"?"))
                draw_string(font,center+Vector2(-tile*0.14,tile*0.12),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,int(max(11.0,tile*0.27)),city_tint)
            var selected: bool = city_cell == selected_factory_pos or city_cell == inspected_cell
            SiteOverlayPainter.draw_classic(self,marker,top_left,tile,selected,state)
            if selected:
                draw_rect(Rect2(top_left,Vector2.ONE*tile),Color("#FFE451"),false,maxf(2.0,tile*0.045))
    # Legal destinations in green, adjacent attack targets in red.
    # Reuse the exact movement/combat rules instead of drawing guessed ranges.
    var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
    var inspection: Dictionary = enemy_inspection_hints()
    # Blue and amber footprints show POSSIBLE enemy movement and fire after
    # a legal future move or from its present cell. No actions are created.
    for cell in inspection.get("moves",{}):
        var cell_pos: Vector2 = origin + Vector2(cell) * tile
        draw_rect(Rect2(cell_pos,Vector2.ONE*tile),Color(0.23,0.62,0.98,0.26))
    for cell in inspection.get("attacks",{}):
        var cell_pos: Vector2 = origin + Vector2(cell) * tile
        draw_rect(Rect2(cell_pos,Vector2.ONE*tile),Color(1.0,0.63,0.17,0.19))
        draw_rect(Rect2(cell_pos,Vector2.ONE*tile),Color(1.0,0.67,0.20,0.78),false,maxf(1.0,tile*0.035))
    for destination in hints["moves"]:
        var movement_cell: Vector2i = destination
        var movement_pos: Vector2 = origin + Vector2(movement_cell) * tile
        draw_rect(Rect2(movement_pos, Vector2.ONE * tile), VisualStyle.movement_fill())
        if tile >= 25.0:
            draw_string(font, movement_pos + Vector2(3.0, max(12.0, tile * 0.25)),
                str(hints["moves"][destination]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(max(10.0, tile * 0.20)), Color.WHITE)
    # Combined amber threat reach (legal move endpoint + weapon range).
    # Red targets remain attacks executable NOW from the current position.
    # The player must still move first, then issue a separate attack order.
    var weapon_area: Dictionary = selected_weapon_coverage()
    for covered_cell in weapon_area:
        var covered_pos: Vector2 = origin + Vector2(covered_cell) * tile
        draw_rect(Rect2(covered_pos, Vector2.ONE * tile), VisualStyle.weapon_coverage_fill())
        draw_rect(Rect2(covered_pos, Vector2.ONE * tile), VisualStyle.weapon_coverage_outline(), false, maxf(1.0, tile * 0.027))
    for destination in hints["attacks"]:
        var attack_cell: Vector2i = destination
        var attack_pos: Vector2 = origin + Vector2(attack_cell) * tile
        draw_rect(Rect2(attack_pos, Vector2.ONE * tile), VisualStyle.attack_fill())
        draw_rect(Rect2(attack_pos, Vector2.ONE * tile), Color(1.0, 0.32, 0.24), false, 2.0)
    # Surface units are always painted first, aircraft last. Independent
    # air/surface glyph positions make stacks readable on a small phone.
    var draw_units: Array = state.get("units", []).duplicate()
    draw_units.sort_custom(func(a,b):
        if Domains.layer(a) != Domains.layer(b):
            return Domains.layer(a) == "surface"
        return str(a["id"]) < str(b["id"])
    )
    for unit in draw_units:
        if int(unit.get("hp",0)) <= 0:
            continue
        var cell: Vector2i = unit["pos"]
        if fog and int(unit.get("faction", -1)) != 0 and not visible.has(cell):
            continue
        var airborne: bool = Domains.domain(unit) == Domains.AIR
        var seaborne: bool = Domains.domain(unit) == Domains.NAVAL
        var center := origin + (Vector2(cell) + Vector2(0.5,0.5)) * tile
        if airborne:
            center += Vector2(tile * 0.24, -tile * 0.22)
        var is_player := int(unit["faction"]) == 0
        var color: Color = Identity.color_for(state,0 if is_player else 1)
        var face: Color = color.darkened(0.45) if unit.get("acted", false) else (color.darkened(0.18) if unit.get("moved", false) else color)
        # Circle vs square still indicates faction. Smaller airborne symbols
        # have an independent light ring and wing cross, not a borrowed asset.
        var radius: float = tile * (0.19 if airborne else 0.34)
        if is_player:
            draw_circle(center, radius, face)
        else:
            var half := tile * (0.18 if airborne else 0.32)
            draw_rect(Rect2(center - Vector2.ONE * half, Vector2.ONE * (half * 2.0)), face)
        if airborne:
            draw_arc(center, tile * 0.23, 0, TAU, 24, Color(0.88,0.96,1.0), maxf(1.0,tile*0.028))
            draw_line(center+Vector2(-tile*0.10,0),center+Vector2(tile*0.10,0),Color.WHITE,maxf(1.0,tile*0.023))
        elif seaborne:
            draw_arc(center, tile * 0.40, 0, TAU, 24, Color(0.52,0.94,0.98), maxf(1.0,tile*0.032))
        if (str(unit["id"]) in ["S", "Z"] and not unit.has("role") or str(unit.get("role", "")) == "scout") and not airborne:
            draw_arc(center, tile * 0.40, 0, TAU, 24, Color(0.60, 0.94, 0.88), 2.0)
        if str(unit["id"]) == selected_id:
            draw_arc(center, tile * (0.28 if airborne else 0.44), 0, TAU, 32, Color.YELLOW, 3.0)
        elif str(unit["id"]) == inspected_enemy_id and bool(inspection.get("valid",false)):
            draw_arc(center,tile*(0.30 if airborne else 0.46),0,TAU,32,Color(1.0,0.75,0.27),maxf(2.0,tile*0.055))
        draw_string(font, center + Vector2(-tile * 0.11, tile * 0.10), str(unit["id"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(10.0, tile * (0.20 if airborne else 0.30))), Color.WHITE)
        # A second visual marker identifies the tactical role independently
        # of faction color and unit ID; no borrowed game sprites.
        if Roles.valid(str(unit.get("role", ""))) and tile >= 36.0:
            var role_pos := center + Vector2(tile * 0.19, -tile * 0.14)
            draw_string(font, role_pos, Roles.symbol(str(unit["role"])), HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(11.0, tile * 0.19)), Color(1.0, 0.94, 0.65))
        # Own-unit warnings only: do not reveal hidden enemy supplies through fog.
        # Red means empty and amber means critically low. M=ammo, F=fuel.
        if is_player and unit.has("ammo") and tile >= 36.0:
            var supply_role: String = str(unit.get("role", ""))
            var ammo_max: int = Logistics.ammo_capacity(supply_role)
            var fuel_max: int = Logistics.fuel_capacity(supply_role)
            var warnings: Array = []
            if ammo_max > 0 and int(unit["ammo"]) <= maxi(1, int(ammo_max / 4)):
                warnings.append(["M", int(unit["ammo"]) == 0])
            if fuel_max > 0 and int(unit["fuel"]) <= maxi(2, int(fuel_max / 4)):
                warnings.append(["F", int(unit["fuel"]) == 0])
            for i in range(warnings.size()):
                var empty: bool = bool(warnings[i][1])
                var marker_color := Color(1.0, 0.28, 0.27) if empty else Color(1.0, 0.71, 0.24)
                var tag_pos := origin + Vector2(cell) * tile + Vector2(tile * (0.03 + i * 0.23), tile * 0.03)
                draw_rect(Rect2(tag_pos, Vector2(tile * 0.20, tile * 0.21)), Color(0.06, 0.08, 0.1, 0.92))
                draw_string(font, tag_pos + Vector2(tile * 0.035, tile * 0.16), str(warnings[i][0]),
                    HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(9.0, tile * 0.16)), marker_color)
        # Numeric health avoids a misleading percentage: this prototype has no
        # persistent per-unit maximum-HP field yet. Hide on very small tiles.
        if tile >= 39.0:
            var unit_pos := origin + Vector2(cell) * tile
            var badge_pos := Vector2(tile * 0.50, tile * 0.07) if airborne else Vector2(tile * 0.04, tile * 0.76)
            var badge_rect := Rect2(unit_pos + badge_pos, Vector2(tile * 0.47, tile * 0.22))
            draw_rect(badge_rect, Color(0.03, 0.07, 0.09, 0.89))
            var health_tint := Color(1.0, 0.75, 0.46) if int(unit["hp"]) <= 3 else Color.WHITE
            draw_string(font, badge_rect.position + Vector2(tile * 0.04, tile * 0.17),
                "HP %d" % int(unit["hp"]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(max(10.0, tile * 0.16)), health_tint)
    # Draw transient impact flashes over the battlefield, never as units.
    _draw_combat_effects(tile, origin)
    # A question mark is deliberately NOT a unit: no HP, target preview,
    # hitbox or legal attack is created from historical sightings.
    if fog:
        var stale_contacts: Dictionary = Visibility.last_known_contacts(state, 0)
        for enemy_id in stale_contacts:
            var old_cell: Vector2i = stale_contacts[enemy_id]
            var ghost_center: Vector2 = origin + (Vector2(old_cell) + Vector2(0.5, 0.5)) * tile
            draw_arc(ghost_center, tile * 0.26, 0, TAU, 20, Color(0.95, 0.73, 0.38, 0.80), 2.0)
            draw_string(font, ghost_center + Vector2(-tile * 0.09, tile * 0.11),
                "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(12.0, tile * 0.31)), Color(1.0, 0.86, 0.55))
    if pending_order.has("cell"):
        var preview_cell: Vector2i = pending_order["cell"]
        var preview_pos: Vector2 = origin + Vector2(preview_cell) * tile
        draw_rect(Rect2(preview_pos, Vector2.ONE * tile), Color(1.0, 0.86, 0.20), false, 4.0)
    # Put expected damage above the enemy tile, after units are drawn so it stays readable.
    for destination in hints["attacks"]:
        if tile >= 33.0:
            var target_pos: Vector2 = origin + Vector2(destination) * tile
            var dmg: int = int(hints["attacks"][destination]["damage"])
            draw_string(font, target_pos + Vector2(tile * 0.52, tile * 0.89),
                "-%d" % dmg, HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(max(11.0, tile * 0.22)), Color(1.0, 0.88, 0.60))
    _draw_campaign_markers()

# Overlay objective markers on the existing classic and isometric battlefield.
# Markers are never fake units or attack targets.
func _draw_campaign_markers() -> void:
    if campaign_markers.is_empty() or not state.has("terrain"):
        return
    var fog: bool = Visibility.enabled(state)
    var known: Dictionary = Visibility.explored_cells(state, 0) if fog else {}
    var font: Font = ThemeDB.fallback_font
    for i in range(campaign_markers.size()):
        var cell: Vector2i = campaign_markers[i]
        if not Rules.inside(cell,state["terrain"]) or (fog and not known.has(cell)):
            continue
        var held := false
        for unit in state.get("units",[]):
            if unit is Dictionary and int(unit.get("hp",0)) > 0 and int(unit.get("faction",-1)) == 0 and unit.get("pos") == cell:
                held = true
                break
        var tint := Color("#5BE1A4") if held else Color("#F7C55B")
        if iso_enabled:
            var polygon: PackedVector2Array = IsoProjection.diamond(cell,size,iso_zoom,iso_pan,map_dimensions())
            polygon.append(polygon[0])
            draw_polyline(polygon,tint,3.0,true)
            var center: Vector2 = IsoProjection.center(cell,size,iso_zoom,iso_pan,map_dimensions())
            draw_string(font,center+Vector2(4,-6),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,17,tint)
        else:
            var tile: float = _cell_size()
            var point: Vector2 = _board_origin() + Vector2(cell)*tile
            draw_rect(Rect2(point+Vector2.ONE*2,Vector2.ONE*(tile-4)),tint,false,3.0)
            draw_string(font,point+Vector2(tile*0.60,tile*0.30),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,17,tint)

func _process(delta: float) -> void:
    var dt: float = maxf(0.0, delta)
    var needs_redraw := false
    if iso_enabled:
        art_phase = fmod(art_phase + minf(dt,0.12), TAU*10.0)
        _ambient_accum += dt
        var cadence: float = VisualBudget.ambient_interval(map_dimensions(),battery_saver)
        if _ambient_accum >= cadence:
            _ambient_accum = fmod(_ambient_accum,cadence)
            ambient_redraw_count += 1
            needs_redraw = true
    if not combat_effects.is_empty():
        for effect in combat_effects:
            effect["elapsed"] = float(effect["elapsed"]) + dt
        for i in range(combat_effects.size()-1,-1,-1):
            if float(combat_effects[i]["elapsed"]) >= COMBAT_EFFECT_SECONDS:
                combat_effects.remove_at(i)
        needs_redraw = true
    if not motion_effects.is_empty():
        for effect in motion_effects:
            effect["elapsed"] = float(effect["elapsed"]) + dt
        for i in range(motion_effects.size()-1,-1,-1):
            if float(motion_effects[i]["elapsed"]) >= 0.32:
                motion_effects.remove_at(i)
        needs_redraw = true
    if needs_redraw:
        queue_redraw()

func _record_move_effect(before: Dictionary, after: Dictionary, unit_id: String) -> void:
    if not iso_enabled or unit_id.is_empty():
        return
    var old: Dictionary = {}
    var current: Dictionary = {}
    for u in before.get("units",[]):
        if str(u.get("id","")) == unit_id:
            old = u
            break
    for u in after.get("units",[]):
        if str(u.get("id","")) == unit_id:
            current = u
            break
    if old.is_empty() or current.is_empty() or old["pos"] == current["pos"]:
        return
    if int(old.get("faction",-1)) != 0:
        # Do not animate a hidden enemy path; both endpoints must be known.
        if Visibility.enabled(before) and not Visibility.visible_cells(before,0).has(old["pos"]):
            return
        if Visibility.enabled(after) and not Visibility.visible_cells(after,0).has(current["pos"]):
            return
    for i in range(motion_effects.size()-1,-1,-1):
        if str(motion_effects[i]["id"]) == unit_id:
            motion_effects.remove_at(i)
    unit_headings[unit_id] = current["pos"] - old["pos"]
    motion_effects.append({"id":unit_id,"from":old["pos"],"to":current["pos"],"elapsed":0.0})
    while motion_effects.size() > 16:
        motion_effects.pop_front()
    queue_redraw()

func _record_attack_effect(before: Dictionary, result: Dictionary, attacker_id: String, defender_id: String) -> void:
    if attacker_id.is_empty() or defender_id.is_empty():
        return
    var shot_from := Vector2i(-1,-1)
    var target := Vector2i(-1,-1)
    var target_was_alive := false
    var attacker_role := ""
    var defender_role := ""
    for unit in before.get("units", []):
        if not unit is Dictionary:
            continue
        if str(unit.get("id","")) == attacker_id:
            shot_from = unit["pos"]
            attacker_role = str(unit.get("role",""))
        elif str(unit.get("id","")) == defender_id:
            target = unit["pos"]
            defender_role = str(unit.get("role",""))
            target_was_alive = int(unit.get("hp",0)) > 0
    if target.x < 0 or not target_was_alive:
        return
    # Enemy fire must never expose positions or origins hidden from the human.
    var visible: Dictionary = Visibility.visible_cells(before, 0) if Visibility.enabled(before) else {}
    if Visibility.enabled(before) and not visible.has(target):
        return
    if Visibility.enabled(before) and not visible.has(shot_from):
        shot_from = Vector2i(-1,-1)
    # Destroyed units may be removed entirely from the next state's array.
    var target_survives := false
    for unit in result.get("state", {}).get("units", []):
        if unit is Dictionary and str(unit.get("id","")) == defender_id and int(unit.get("hp",0)) > 0:
            target_survives = true
            break
    var target_destroyed := not target_survives
    if shot_from.x >= 0:
        unit_headings[attacker_id] = target - shot_from
    combat_effects.append({
        "origin":shot_from, "target":target,
        "elapsed":0.0, "destroyed":target_destroyed,
        "attacker_role":attacker_role, "defender_role":defender_role,
        "counter_damage":int(result.get("counter_damage",0)),
        "consumed":not str(result.get("consumed_unit_id", "")).is_empty()
    })
    while combat_effects.size() > 8:
        combat_effects.pop_front()
    queue_redraw()

func _draw_combat_effects(tile: float, board_origin: Vector2) -> void:
    for effect in combat_effects:
        var progress: float = clampf(float(effect["elapsed"]) / COMBAT_EFFECT_SECONDS, 0.0, 1.0)
        var alpha: float = 1.0 - progress
        var target: Vector2i = effect["target"]
        var center: Vector2 = board_origin + (Vector2(target) + Vector2(0.5, 0.5)) * tile
        var radius: float = tile * (0.14 + 0.40 * progress)
        draw_arc(center, radius, 0.0, TAU, 26,
            Color(1.0, 0.72, 0.22, alpha), maxf(2.0, tile * 0.055))
        draw_circle(center, tile * (0.08 + (0.12 if bool(effect["destroyed"]) else 0.04)) * alpha,
            Color(1.0, 0.37, 0.14, alpha * 0.8))
        var from_cell: Vector2i = effect["origin"]
        if from_cell.x >= 0:
            var launch: Vector2 = board_origin + (Vector2(from_cell) + Vector2(0.5, 0.5)) * tile
            draw_line(launch, center, Color(1.0, 0.84, 0.41, alpha * 0.6), maxf(1.0, tile * 0.035))
            if int(effect.get("counter_damage",0)) > 0:
                # Reverse tracer and blue-red pulse signal the defensive shot.
                # The origin is never drawn if fog hides the attacking tile.
                draw_line(center,launch,Color(0.99,0.30,0.23,alpha*0.8),maxf(2.0,tile*0.055))
                draw_arc(launch,tile*(0.11+0.23*progress),0.0,TAU,24,
                    Color(1.0,0.28,0.22,alpha),maxf(2.0,tile*0.04))
            if bool(effect["consumed"]):
                draw_arc(launch, tile * (0.06 + 0.30 * progress), 0.0, TAU, 22,
                    Color(1.0, 0.28, 0.18, alpha), maxf(2.0, tile * 0.04))

func cancel_selection() -> void:
    if selected_id.is_empty() and inspected_enemy_id.is_empty() and pending_order.is_empty() and selected_factory_pos == Vector2i(-1,-1) and inspected_cell == Vector2i(-1,-1):
        return
    selected_id = ""
    inspected_enemy_id = ""
    selected_factory_pos = Vector2i(-1,-1)
    inspected_cell = Vector2i(-1,-1)
    pending_order.clear()
    message = "Seleccion cancelada."
    queue_redraw()

func confirm_pending_order() -> bool:
    if pending_order.is_empty():
        return false
    var order: Dictionary = pending_order.duplicate(true)
    var committed := _commit_order(order)
    queue_redraw()
    return committed

func _request_order(cell: Vector2i, target: Dictionary) -> void:
    var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
    var enemy_id := str(target.get("id", ""))
    var kind := "attack" if not target.is_empty() else "move"
    var legal: bool = bool(hints["attacks"].has(cell)) if kind == "attack" else bool(hints["moves"].has(cell))
    if not legal:
        pending_order.clear()
        message = "Apertura completada. Pulsa Terminar turno." if Opening.remaining(state) == 0 else "Accion no permitida."
        return
    var order: Dictionary = {"unit_id": selected_id, "cell": cell, "kind": kind, "target_id": enemy_id}
    if require_order_confirmation and pending_order != order:
        pending_order = order
        if kind == "attack":
            var damage := int(hints["attacks"][cell]["damage"])
            var response_max: int = int(hints["attacks"][cell].get("counter_damage",0))
            var effects: Dictionary = hints["attacks"][cell]
            var ground_note := " | terreno: ATQ %+d, cobertura rival +%d%s" % [
                int(effects.get("terrain_attack_bonus",0)),int(effects.get("terrain_defense_cover",0)),
                ", flanqueo" if bool(effects.get("flanked",false)) else ""
            ]
            message = "Atacar %s (-%d). Posible respuesta hasta -%d HP%s. Toca otra vez o Confirmar orden." % [enemy_id,damage,response_max,ground_note]
        else:
            message = "Mover a (%d,%d). Toca otra vez o Confirmar orden." % [cell.x + 1, cell.y + 1]
        return
    _commit_order(order)

func _commit_order(order: Dictionary) -> bool:
    if campaign_locked:
        return false
    # State can change between preview and confirmation; never trust a stale hint.
    var unit_id := str(order.get("unit_id", ""))
    var cell = order.get("cell", null)
    var kind := str(order.get("kind", ""))
    var enemy_id := str(order.get("target_id", ""))
    pending_order.clear()
    if unit_id.is_empty() or unit_id != selected_id or not (cell is Vector2i):
        message = "Orden cancelada."
        return false
    if int(state.get("winner", -1)) != -1 or (ai_enabled and int(state.get("faction", -1)) != 0):
        message = "Orden cancelada."
        return false
    var hints: Dictionary = TacticalHints.for_unit(state, unit_id)
    var result: Dictionary = {}
    if kind == "attack":
        if not hints["attacks"].has(cell) or str(hints["attacks"][cell]["id"]) != enemy_id:
            message = "Objetivo ya no disponible."
            return false
        result = Session.attack(state, unit_id, enemy_id)
    elif kind == "move":
        if not hints["moves"].has(cell):
            message = "Destino ya no disponible."
            return false
        result = Session.move(state, unit_id, cell)
    else:
        message = "Orden no valida."
        return false
    if not result.get("valid", false):
        message = "Accion no permitida."
        return false
    var prior_state: Dictionary = state
    state = result["state"]
    if kind == "attack":
        _record_attack_effect(prior_state, result, unit_id, enemy_id)
    elif kind == "move":
        _record_move_effect(prior_state, state, unit_id)
    selected_factory_pos = Vector2i(-1,-1)
    tactical_action_committed.emit({"kind":kind,"unit_id":unit_id,"result":result})
    _write_autosave()
    var winner := int(state.get("winner", -1))
    if winner != -1:
        message = "Victoria de faccion %d." % (winner + 1)
        selected_id = ""
    elif kind == "move":
        # Keep the mover selected if an enemy is now within its attack range.
        # Fog observations were refreshed by Session.move, so the list is fair.
        var follow_up: Dictionary = TacticalHints.for_unit(state, unit_id)
        if not follow_up["attacks"].is_empty():
            selected_id = unit_id
            message = "Movimiento completado. Ahora selecciona un objetivo rojo para atacar."
        else:
            selected_id = ""
            message = "Movimiento completado. Sin objetivos visibles en alcance."
    else:
        selected_id = ""
        var outgoing: int = int(result.get("damage",0))
        var incoming: int = int(result.get("counter_damage",0))
        var exchange_text := "Ataque: Enemigo -%d HP. Respuesta: -%d HP propios." % [outgoing,incoming]
        message = "Impacto confirmado. Municion de un solo uso consumida. " + exchange_text if not str(result.get("consumed_unit_id", "")).is_empty() else exchange_text
    if Opening.remaining(state) == 0 and int(state.get("winner",-1)) == -1:
        message += " Apertura completada: pulsa Terminar turno."
    return true

# A manual supply action spends credits and the selected unit's action.
func can_resupply_selected() -> bool:
    return Opening.can_order(state) and pending_order.is_empty() and not selected_id.is_empty() and (not ai_enabled or int(state.get("faction", -1)) == 0) and Logistics.can_resupply(state, selected_id)

func resupply_selected() -> bool:
    if not can_resupply_selected():
        message = "Reabastecimiento no disponible: requiere base amiga o camion logistico, creditos y suministros gastados."
        return false
    var action: Dictionary = Session.resupply(state, selected_id)
    if not action.get("valid", false):
        message = "Reabastecimiento rechazado."
        return false
    state = action["state"]
    var source_label := "camion logistico" if str(action.get("source_kind", "")) == "truck" else "instalacion aliada"
    var fuel_message: String = ", +%d combustible" % int(action["fuel"]) if int(action["fuel"]) > 0 else ""
    message = "Recarga desde %s: +%d municion%s (%s)." % [
        source_label, int(action["ammo"]), fuel_message,
        "sin costo adicional" if int(action["cost"]) == 0 else "-%d creditos" % int(action["cost"])
    ]
    if int(action["cargo_ammo"]) + int(action["cargo_fuel"]) > 0:
        message += " Camion repuesto: +%d municion, +%d combustible." % [
            int(action["cargo_ammo"]), int(action["cargo_fuel"])
        ]
    selected_id = ""
    selected_factory_pos = Vector2i(-1,-1)
    pending_order.clear()
    _write_autosave()
    queue_redraw()
    return true

# Purchases come from a selected, currently owned and unoccupied workshop.
# The definitive decision is validated again by BattleSession.purchase.
func can_purchase_selected(role: String) -> bool:
    if selected_factory_pos == Vector2i(-1,-1) or not pending_order.is_empty() or not Opening.can_order(state):
        return false
    if ai_enabled and int(state.get("faction",-1)) != 0:
        return false
    return Economy.can_purchase(state, selected_factory_pos, role)

func buy_selected(role: String) -> bool:
    if not can_purchase_selected(role):
        message = "No se puede producir: revisa creditos, propietario y espacio."
        return false
    var action: Dictionary = Session.purchase(state, selected_factory_pos, role)
    if not action.get("valid", false):
        message = "No se pudo producir la unidad."
        return false
    state = action["state"]
    selected_factory_pos = Vector2i(-1,-1)
    selected_id = ""
    pending_order.clear()
    message = "Unidad %s producida (-%d creditos). Actuara el proximo turno." % [Roles.label(role), int(action["cost"])]
    _write_autosave()
    queue_redraw()
    return true

func selected_unit_summary() -> String:
    if not inspected_enemy_id.is_empty():
        var intel: Dictionary = enemy_inspection_hints()
        if bool(intel.get("valid",false)):
            return str(intel["summary"])
    return TacticalHints.unit_summary(state, selected_id)

func enemy_inspection_hints() -> Dictionary:
    return TacticalHints.inspect_enemy(state, inspected_enemy_id, 0)

func _inspect_enemy(enemy: Dictionary) -> void:
    var enemy_id: String = str(enemy.get("id",""))
    if not bool(TacticalHints.inspect_enemy(state,enemy_id,0).get("valid",false)):
        return
    inspected_enemy_id = enemy_id
    selected_id = ""
    selected_factory_pos = Vector2i(-1,-1)
    pending_order.clear()
    message = "Inspeccionando unidad enemiga %s (sin ordenar ataque)." % enemy_id

func legal_action_hints() -> Dictionary:
    return TacticalHints.for_unit(state, selected_id)

func selected_weapon_coverage() -> Dictionary:
    # Just a UI preview. It does not reveal enemies or affect the saved game.
    return TacticalHints.friendly_weapon_coverage(state, selected_id)

# Display-only anchored camera transformation. Classic and isometric
# projections both scale about the board centre and add a pixel pan.
# Pinch zoom preserves the terrain point beneath the moving midpoint.
func zoom_camera_anchored(scale: float, old_anchor: Vector2, new_anchor: Vector2) -> void:
    if scale <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
        return
    var previous: float = iso_zoom if iso_enabled else view_zoom
    var minimum: float = IsoProjection.MIN_ZOOM if iso_enabled else 1.0
    var maximum: float = IsoProjection.MAX_ZOOM if iso_enabled else 4.0
    var next_zoom: float = clampf(previous * scale,minimum,maximum)
    var previous_pan: Vector2 = iso_pan if iso_enabled else view_pan
    var ratio: float = next_zoom / maxf(previous,0.0001)
    var next_pan: Vector2 = new_anchor - size * 0.5 - (old_anchor - size * 0.5 - previous_pan) * ratio
    if iso_enabled:
        iso_zoom = next_zoom
        iso_pan = next_pan
    else:
        view_zoom = next_zoom
        view_pan = next_pan
    queue_redraw()

func _reset_touch_gesture() -> void:
    _touch_points.clear()
    touch_origin = Vector2.ZERO
    touch_active = false
    touch_finger_index = -1
    touch_cancelled = false
    _pinch_distance = 0.0
    _pinch_midpoint = Vector2.ZERO

func _pinch_pair() -> Array:
    var indices: Array = _touch_points.keys()
    indices.sort()
    return [_touch_points[indices[0]],_touch_points[indices[1]]]

func _start_pinch() -> void:
    var pair: Array = _pinch_pair()
    var first: Vector2 = pair[0]
    var second: Vector2 = pair[1]
    _pinch_distance = maxf(1.0,first.distance_to(second))
    _pinch_midpoint = (first+second)*0.5
    touch_cancelled = true

func _update_pinch() -> void:
    var pair: Array = _pinch_pair()
    var first: Vector2 = pair[0]
    var second: Vector2 = pair[1]
    var distance: float = maxf(1.0,first.distance_to(second))
    var midpoint: Vector2 = (first+second)*0.5
    if _pinch_distance > 0.0:
        zoom_camera_anchored(distance/_pinch_distance,_pinch_midpoint,midpoint)
    _pinch_distance = distance
    _pinch_midpoint = midpoint

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_points[event.index] = event.position
            if _touch_points.size() == 1:
                touch_origin = event.position
                touch_cancelled = false
                touch_finger_index = event.index
                touch_active = true
            elif _touch_points.size() == 2:
                _start_pinch()
            else:
                touch_cancelled = true
        elif _touch_points.has(event.index):
            var only_finger: bool = _touch_points.size() == 1
            var should_tap: bool = only_finger and touch_active and event.index == touch_finger_index and not touch_cancelled and touch_origin.distance_to(event.position) <= TAP_DRAG_LIMIT
            _touch_points.erase(event.index)
            if _touch_points.is_empty():
                _reset_touch_gesture()
                if should_tap:
                    _tap(event.position)
            elif _touch_points.size() == 1:
                # Remaining finger can continue panning after a pinch,
                # but its release can never issue a game order.
                var index: int = int(_touch_points.keys()[0])
                touch_finger_index = index
                touch_origin = _touch_points[index]
                touch_active = true
                touch_cancelled = true
                _pinch_distance = 0.0
            else:
                _start_pinch()
        accept_event()
    elif event is InputEventScreenDrag:
        if _touch_points.has(event.index):
            _touch_points[event.index] = event.position
            if _touch_points.size() >= 2:
                _update_pinch()
            elif touch_active and event.index == touch_finger_index:
                if touch_origin.distance_to(event.position) > TAP_DRAG_LIMIT:
                    touch_cancelled = true
                if touch_cancelled:
                    if iso_enabled:
                        iso_pan += event.relative
                    else:
                        view_pan += event.relative
                    queue_redraw()
        accept_event()
    elif event is InputEventMouseButton:
        # Android synthesizes mouse clicks from touches, including pinches.
        # Do not let a synthetic press execute an order.
        if event.device == InputEvent.DEVICE_ID_EMULATION:
            accept_event()
        elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _tap(event.position)
            accept_event()
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
            var factor: float = 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.15
            zoom_camera_anchored(factor,event.position,event.position)
            accept_event()

func _tap(point: Vector2) -> void:
    if campaign_locked:
        return
    if ai_enabled and int(state.get("faction", -1)) != 0:
        return
    if int(state.get("winner",-1)) != -1:
        return
    var cell: Vector2i = screen_cell(point)
    if cell.x < 0 or cell.y < 0:
        return
    inspected_cell = cell # Any revealed tile may show contextual info.
    var target: Dictionary = {}
    var visible: Dictionary = Visibility.visible_cells(state, 0) if Visibility.enabled(state) else {}
    var units_here: Array = []
    for unit in state["units"]:
        if int(unit.get("hp",0)) > 0 and unit["pos"] == cell:
            if Visibility.enabled(state) and int(unit.get("faction", -1)) != 0 and not visible.has(cell):
                continue
            units_here.append(unit)
    # A selected anti-air unit must attack the legally targetable aircraft,
    # even when an enemy soldier or friendly ground unit shares its tile.
    if not selected_id.is_empty():
        var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
        var preferred_id: String = str(hints["attacks"].get(cell, {}).get("id", ""))
        for occupant in units_here:
            if str(occupant.get("id","")) == preferred_id and int(occupant["faction"]) != int(state["faction"]):
                target = occupant
                break
    if target.is_empty():
        var friendlies: Array = []
        for occupant in units_here:
            if int(occupant.get("faction",-1)) == int(state["faction"]):
                friendlies.append(occupant)
        if not friendlies.is_empty():
            # Surface first, aircraft second. Tapping again cycles distinct
            # actionable units; a single-unit tile retains tap-to-deselect.
            friendlies.sort_custom(func(a,b):
                if Domains.layer(a) != Domains.layer(b):
                    return Domains.layer(a) == "surface"
                return str(a["id"]) < str(b["id"])
            )
            var actionable: Array = []
            for friendly in friendlies:
                if not bool(friendly.get("acted",false)):
                    actionable.append(friendly)
            if actionable.is_empty():
                target = friendlies[0]
            elif actionable.size() == 1:
                target = actionable[0]
            else:
                var current_index := -1
                for i in range(actionable.size()):
                    if str(actionable[i]["id"]) == selected_id:
                        current_index = i
                        break
                target = actionable[(current_index + 1) % actionable.size()]
        elif not units_here.is_empty():
            target = units_here[0]
    if not target.is_empty() and int(target["faction"]) == int(state["faction"]):
        selected_factory_pos = Vector2i(-1,-1)
        inspected_enemy_id = ""
        pending_order.clear()
        var tapped_id := str(target["id"])
        if tapped_id == selected_id:
            selected_id = ""
            message = "Seleccion cancelada."
        elif bool(target.get("acted", false)):
            selected_id = ""
            message = "Esta unidad ya termino sus acciones."
        else:
            selected_id = tapped_id
            message = "Unidad " + selected_id + " seleccionada."
    elif not target.is_empty() and int(target.get("faction",-1)) != int(state["faction"]):
        # Keep the existing attack preview and double-tap confirmation for
        # a legally targetable enemy. Otherwise tapping enemy shows intel,
        # never an accidental illegal attack or movement command.
        var legal_attack: bool = false
        if not selected_id.is_empty():
            var attacks: Dictionary = TacticalHints.for_unit(state,selected_id)["attacks"]
            legal_attack = str(attacks.get(cell,{}).get("id","")) == str(target["id"])
        if legal_attack:
            inspected_enemy_id = ""
            _request_order(cell,target)
        else:
            _inspect_enemy(target)
    elif not selected_id.is_empty():
        inspected_enemy_id = ""
        _request_order(cell, target)
    elif target.is_empty() and state.has("economy"):
        var found := false
        var own_side: int = int(state["faction"])
        var fogged: bool = Visibility.enabled(state)
        var discovered: Dictionary = Visibility.explored_cells(state,own_side) if fogged else {}
        for site in state["economy"]["sites"]:
            if site["pos"] != cell:
                continue
            # Unknown installations never expose their existence or owner
            # through tapping a dark cell.
            if fogged and not discovered.has(cell) and int(site["owner"]) != own_side:
                continue
            var owner_known: bool = not fogged or visible.has(cell) or int(site["owner"]) == own_side
            var owner_text := "desconocido"
            if owner_known:
                match int(site["owner"]):
                    0:
                        owner_text = "Azul"
                    1:
                        owner_text = "Rojo"
                    _:
                        owner_text = "neutral"
            if site["kind"] != "city" and int(site["owner"]) == own_side:
                selected_factory_pos = cell if selected_factory_pos != cell else Vector2i(-1,-1)
                message = "Instalacion aliada: produce unidades y repone municion/combustible de su dominio." if selected_factory_pos == cell else "Instalacion cancelada."
            else:
                selected_factory_pos = Vector2i(-1,-1)
                if site["kind"] == "city":
                    message = "Ciudad (%s): genera ingresos al iniciar turno. Infanteria la captura al finalizar turno." % owner_text
                else:
                    message = "Taller (%s): produce unidades para su propietario." % owner_text
            found = true
            break
        if not found:
            selected_factory_pos = Vector2i(-1,-1)
    queue_redraw()

func finish_turn() -> void:
    if campaign_locked:
        return
    # Human cannot manually skip the computer faction.
    if ai_enabled and int(state.get("faction", -1)) != 0:
        return
    var previous: Dictionary = state.duplicate(true)
    var result: Dictionary = Session.end_turn(state)
    if not result.get("valid", false):
        return
    state = result["state"]
    tactical_phase_completed.emit(int(previous["faction"]))
    selected_id = ""
    inspected_enemy_id = ""
    selected_factory_pos = Vector2i(-1,-1)
    pending_order.clear()
    last_enemy_turn_report = ""
    last_economy_report = ""
    if previous.has("economy") and state.has("economy"):
        var captured_cities := 0
        var captured_factories := 0
        for i in range(previous["economy"]["sites"].size()):
            var before_site: Dictionary = previous["economy"]["sites"][i]
            var after_site: Dictionary = state["economy"]["sites"][i]
            if int(before_site["owner"]) != int(previous["faction"]) and int(after_site["owner"]) == int(previous["faction"]):
                if after_site["kind"] == "city":
                    captured_cities += 1
                else:
                    captured_factories += 1
        if captured_cities + captured_factories > 0:
            last_economy_report = "Capturas de faccion %d: %d ciudades, %d talleres." % [int(previous["faction"])+1,captured_cities,captured_factories]
    message = "Turno de faccion " + str(state["faction"] + 1)
    if state.has("control"):
        message = "Reles: " + _relay_turn_report(previous, state, 0)
    if int(state.get("winner", -1)) != -1:
        message = "Victoria de faccion %d." % (int(state["winner"]) + 1)
    if ai_enabled and int(state["faction"]) == 1:
        _play_ai_turn()
        if previous.has("economy") and state.has("economy") and int(state.get("faction",-1)) == 0 and int(state.get("winner",-1)) == -1:
            var received: int = int(state["economy"]["credits"][0])-int(previous["economy"]["credits"][0])
            if received > 0:
                last_economy_report += " +%d creditos al iniciar tu turno." % received
    _write_autosave()
    queue_redraw()

func _play_ai_turn() -> void:
    # Never advance the computer from a human or terminal state.
    if campaign_locked or not ai_enabled or int(state.get("faction", -1)) != 1 or int(state.get("winner", -1)) != -1:
        return
    # A unit may move and attack; each factory may additionally produce at
    # most once this phase. Bound all possibilities even after recruitment.
    var max_actions: int = (state.get("units", []) as Array).size() * 2
    if state.has("economy"):
        max_actions += state["economy"]["sites"].size()
    var movements := 0
    var attacks := 0
    var produced := 0
    var resupplied := 0
    for i in range(max_actions):
        if campaign_locked or int(state.get("winner", -1)) != -1:
            break
        var prior_state: Dictionary = state
        var result: Dictionary = BasicAI.step(state)
        if not result.get("valid", false):
            break
        state = result["state"]
        tactical_action_committed.emit({"kind":str(result.get("action","")),"unit_id":str(result.get("unit_id",result.get("attacker_id",""))),"result":result})
        if str(result.get("action","")) == "attack":
            _record_attack_effect(prior_state, result, str(result.get("attacker_id", "")), str(result.get("defender_id", "")))
        elif str(result.get("action","")) == "move":
            _record_move_effect(prior_state, state, str(result.get("unit_id", "")))
        match str(result.get("action", "")):
            "move":
                movements += 1
            "attack":
                attacks += 1
            "produce":
                produced += 1
            "resupply":
                resupplied += 1
    last_enemy_turn_report = "Turno enemigo: %d movimientos, %d ataques." % [movements, attacks]
    if state.has("economy"):
        last_enemy_turn_report += " %d refuerzos producidos." % produced
    if resupplied > 0:
        last_enemy_turn_report += " %d reabastecimientos." % resupplied
    if movements + attacks + produced + resupplied == 0:
        last_enemy_turn_report = "Turno enemigo: sin acciones disponibles."
    if campaign_locked or int(state.get("winner", -1)) != -1:
        message = "Ejercicio finalizado." if campaign_locked else "Victoria de faccion %d." % (int(state["winner"]) + 1)
        return
    var before_score: Dictionary = state.duplicate(true)
    var next: Dictionary = Session.end_turn(state)
    if next.get("valid", false):
        state = next["state"]
        tactical_phase_completed.emit(1)
        if state.has("control"):
            last_enemy_turn_report += " " + _relay_turn_report(before_score, state, 1)
        message = "Victoria de faccion %d." % (int(state["winner"]) + 1) if int(state.get("winner", -1)) != -1 else "Tu turno: faccion 1."

# Derive reports from actual post-turn state, never inferred intentions.
# Scores are public mission information; no hidden positions are exposed.
static func _relay_turn_report(before: Dictionary, after: Dictionary, faction: int) -> String:
    if faction not in [0, 1] or not before.has("control") or not after.has("control"):
        return ""
    var nodes_before: Array = before["control"]["nodes"]
    var nodes_after: Array = after["control"]["nodes"]
    var captures := 0
    for i in range(mini(nodes_before.size(), nodes_after.size())):
        if int(nodes_before[i]["owner"]) != faction and int(nodes_after[i]["owner"]) == faction:
            captures += 1
    var earned: int = int(after["control"]["scores"][faction]) - int(before["control"]["scores"][faction])
    return "%d reles capturados, +%d senal." % [captures, earned]

func save_game(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var ok := SaveStore.save(state, path)
    message = "Partida guardada." if ok else "No se pudo guardar la partida."
    return ok

func load_game(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var report: Dictionary = SaveStore.load_report(path)
    var restored: Dictionary = report["state"]
    if restored.is_empty():
        message = "No se pudo cargar la partida."
        return false
    state = restored
    view_zoom = 1.0
    view_pan = Vector2.ZERO
    iso_zoom = 1.0
    iso_pan = Vector2.ZERO
    motion_effects.clear()
    unit_headings.clear()
    combat_effects.clear()
    selected_factory_pos = Vector2i(-1,-1)
    inspected_cell = Vector2i(-1,-1)
    current_scenario_id = Scenarios.RANDOM_SCENARIO_ID if state.has("map_seed") else Scenarios.identify(state["terrain"])
    modern_roster = Arsenal.is_modern(state["units"]) or bool(state.get("economy", {}).get("modern", false))
    specialized_roster = Roles.is_specialized(state["units"])
    symmetric_setup = _infer_symmetric_setup()
    selected_id = ""
    inspected_enemy_id = ""
    pending_order.clear()
    last_enemy_turn_report = ""
    last_economy_report = ""
    var loaded_winner := int(state.get("winner", -1))
    message = "Victoria de faccion %d." % (loaded_winner + 1) if loaded_winner != -1 else "Partida cargada."
    if bool(report["recovered"]):
        message = "Se recupero una copia anterior de la partida."
    # A saved computer turn must resume immediately; human input is locked during it.
    if ai_enabled and int(state.get("faction", -1)) == 1 and int(state.get("winner", -1)) == -1:
        _play_ai_turn()
    _write_autosave()
    queue_redraw()
    return true

# Autosave is a separate file; manual "Guardar partida" always remains untouched.
# The main scene chooses when to restore so unit tests can create fresh boards.
func _infer_symmetric_setup() -> bool:
    # Existing v1 saved games contain per-unit attack values but no setup flag.
    # Those values do not decrease when units lose HP, so the mode is recoverable.
    for unit in state.get("units", []):
        if int(unit.get("faction", -1)) == 1:
            return int(unit.get("attack", 0)) == 5
    return false

func resume_autosave() -> bool:
    var report: Dictionary = SaveStore.load_report(autosave_path)
    var restored: Dictionary = report["state"]
    if restored.is_empty():
        return false
    state = restored
    view_zoom = 1.0
    view_pan = Vector2.ZERO
    iso_zoom = 1.0
    iso_pan = Vector2.ZERO
    motion_effects.clear()
    unit_headings.clear()
    combat_effects.clear()
    selected_factory_pos = Vector2i(-1,-1)
    inspected_cell = Vector2i(-1,-1)
    current_scenario_id = Scenarios.RANDOM_SCENARIO_ID if state.has("map_seed") else Scenarios.identify(state["terrain"])
    modern_roster = Arsenal.is_modern(state["units"]) or bool(state.get("economy", {}).get("modern", false))
    specialized_roster = Roles.is_specialized(state["units"])
    symmetric_setup = _infer_symmetric_setup()
    selected_id = ""
    inspected_enemy_id = ""
    pending_order.clear()
    last_enemy_turn_report = ""
    last_economy_report = ""
    message = "Se recupero una copia anterior de la partida." if bool(report["recovered"]) else "Partida recuperada automaticamente."
    if ai_enabled and int(state.get("faction", -1)) == 1 and int(state.get("winner", -1)) == -1:
        _play_ai_turn()
        _write_autosave()
    queue_redraw()
    return true

func _write_autosave(retain_previous: bool = true) -> bool:
    if not autosave_enabled:
        return false
    var ok: bool = SaveStore.save(state, autosave_path, retain_previous)
    # An interrupted or unwritable save must not silently imply progress is safe.
    autosave_warning = "" if ok else "Atencion: no se pudo guardar automaticamente. Guarda la partida manualmente."
    return ok
