extends RefCounted
class_name TarvokaIsoRenderer

# Prototype renderer only. All military calculations use the untouched board
# coordinates, not projected screen pixels or rendered silhouettes.
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const UnitArt = preload("res://scripts/ui/UnitArt.gd")
const UnitSprites = preload("res://scripts/ui/UnitSpriteAtlas.gd")
const WorldArt = preload("res://scripts/ui/WorldArt.gd")
const SurfaceMaterials = preload("res://scripts/ui/TerrainSurfaceMaterials.gd")
const TextureAtlas = preload("res://scripts/ui/TerrainTextureAtlas.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const BattleVFX = preload("res://scripts/ui/BattleVFX.gd")
const VisualBudget = preload("res://scripts/ui/VisualBudget.gd")
const SiteOverlayData = preload("res://scripts/ui/SiteOverlayData.gd")
const SiteOverlayPainter = preload("res://scripts/ui/SiteOverlayPainter.gd")
static var last_frame_stats: Dictionary = {}

static func _projected_center(cell: Vector2i, base: Vector2, hw: float) -> Vector2:
    return base + Vector2(float(cell.x-cell.y)*hw,float(cell.x+cell.y)*hw*0.5)

static func _diamond_at(center: Vector2, hw: float) -> PackedVector2Array:
    return PackedVector2Array([
        center + Vector2(0,-hw*0.5),
        center + Vector2(hw,0),
        center + Vector2(0,hw*0.5),
        center + Vector2(-hw,0)
    ])

static func _ring(vertices: PackedVector2Array) -> PackedVector2Array:
    var outline: PackedVector2Array = vertices.duplicate()
    outline.append(vertices[0])
    return outline

static func _tile(canvas: Control, vertices: PackedVector2Array, tint: Color) -> void:
    canvas.draw_colored_polygon(vertices, tint)
    # The invisible tactical cells remain selectable, but the normal map
    # should not resemble a dark, separated checkerboard of tiles.
    canvas.draw_polyline(_ring(vertices),
        Color(0.05,0.09,0.12,0.24),0.85,true)

static func _center(cell: Vector2i, canvas: Control, zoom: float, pan: Vector2, dims: Vector2i = Vector2i(10,8)) -> Vector2:
    return IsoTransform.center(cell, canvas.size, zoom, pan, dims)

static func _poly(cell: Vector2i, canvas: Control, zoom: float, pan: Vector2, dims: Vector2i = Vector2i(10,8)) -> PackedVector2Array:
    return IsoTransform.diamond(cell, canvas.size, zoom, pan, dims)

static func draw_board(canvas: Control, state: Dictionary, selected_id: String,
        selected_factory_pos: Vector2i, pending_order: Dictionary,
        combat_effects: Array, zoom: float, pan: Vector2, motion_effects: Array = [], phase: float = 0.0,
        unit_headings: Dictionary = {}, battery_saver: bool = false, inspected_enemy_id: String = "",
        site_markers: Array = [], inspected_cell: Vector2i = Vector2i(-1,-1)) -> void:
    if not state.has("terrain") or not Rules.valid_terrain(state["terrain"]):
        return
    var dims: Vector2i = Rules.map_size(state["terrain"])
    var hw: float = IsoTransform.half_width(canvas.size, zoom, dims)
    if hw <= 0.0:
        return
    var hh: float = hw * 0.5
    var font: Font = ThemeDB.fallback_font
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, 0) if fog else {}
    var explored: Dictionary = Visibility.explored_cells(state, 0) if fog else {}
    var detail: int = VisualBudget.detail_level(hw,battery_saver)
    var bounds: Rect2i = VisualBudget.visible_grid_bounds(canvas.size,zoom,pan,dims)
    var base_origin: Vector2 = IsoTransform.origin(canvas.size,zoom,pan,dims)
    var drawn := 0
    var decorated := 0
    var unknown := 0
    # Painter order is retained. Iterate only the conservative screen-facing
    # rectangle, not every grid cell during zoomed/panned 40x30 battles.
    if bounds.size.x > 0 and bounds.size.y > 0:
        for depth in range(bounds.position.x+bounds.position.y,
                bounds.end.x+bounds.end.y-1):
            var y_min: int = maxi(bounds.position.y,depth-bounds.end.x+1)
            var y_max: int = mini(bounds.end.y-1,depth-bounds.position.x)
            for y in range(y_min,y_max+1):
                var x: int = depth-y
                var cell := Vector2i(x,y)
                var c: Vector2 = _projected_center(cell,base_origin,hw)
                if not VisualBudget.in_view(c,hw,canvas.size):
                    continue
                var vertices: PackedVector2Array = _diamond_at(c,hw)
                drawn += 1
                if fog and not explored.has(cell):
                    # Never render unknown terrain beneath its opaque cover.
                    _tile(canvas,vertices,Color(0.015,0.025,0.04,1.0))
                    unknown += 1
                    continue
                var terrain: String = str(state["terrain"][y][x])
                var tint: Color = VisualStyle.terrain_color(terrain,x,y)
                _tile(canvas,vertices,tint)
                if detail == VisualBudget.DETAIL_FULL and (
                        not fog or visible.has(cell)):
                    # No decorative tile seams inside a continuous biome.
                    # The tactical grid still exists for all touches and
                    # highlights. Draw only low-contrast material boundaries,
                    # never inspecting unobserved terrain behind fog.
                    var same_kind: int = Topology.neighbor_mask(
                        state["terrain"],cell,terrain,true,visible,fog)
                    if (same_kind & Topology.NORTH) == 0:
                        var northern_edge: Color = tint.lightened(0.13)
                        northern_edge.a = 0.17
                        canvas.draw_line(vertices[0],vertices[1],northern_edge,
                            maxf(1.0,hw*0.012),true)
                    if (same_kind & Topology.SOUTH) == 0:
                        var southern_edge: Color = tint.darkened(0.21)
                        southern_edge.a = 0.14
                        canvas.draw_line(vertices[2],vertices[3],southern_edge,
                            maxf(1.0,hw*0.012),true)
                if (not fog or visible.has(cell)) and VisualBudget.should_draw_terrain(detail,terrain):
                    # Determine continuity only from observable neighbors:
                    # no shoreline or road shape may reveal an unseen tile.
                    var road_links: int = Topology.road_mask(
                        state["terrain"],cell,visible,fog) if terrain == "road" else 0
                    var shoreline: int = Topology.shore_mask(
                        state["terrain"],cell,visible,fog) if terrain == "water" else 0
                    var terrain_links: int = Topology.neighbor_mask(
                        state["terrain"],cell,terrain,true,visible,fog
                        ) if terrain == "mountain" or terrain == "forest" else 0
                    var crossing: int = Topology.bridge_axis(
                        state["terrain"],cell,visible,fog) if terrain == "road" else 0
                    # All environmental transition masks use the SAME
                    # visibility rules as roads and shorelines. This is
                    # render data only; nothing is written into the battle.
                    var environment: Dictionary = {"cell":cell}
                    if terrain in ["plain","forest","mountain"]:
                        var biome_colors: Dictionary = {}
                        for side in range(4):
                            var neighbor: Vector2i = cell+Topology.DIRECTIONS[side]
                            if neighbor.x < 0 or neighbor.y < 0 or (
                                    neighbor.x >= dims.x or neighbor.y >= dims.y):
                                continue
                            if fog and not visible.has(neighbor):
                                continue
                            var neighbor_kind: String = str(
                                state["terrain"][neighbor.y][neighbor.x])
                            if neighbor_kind == terrain or (
                                    neighbor_kind in ["road","water"]):
                                continue
                            biome_colors[side] = VisualStyle.terrain_color(
                                neighbor_kind,neighbor.x,neighbor.y)
                        environment["biome_colors"] = biome_colors
                    if terrain == "water":
                        environment["water_connections"] = Topology.neighbor_mask(
                            state["terrain"],cell,"water",true,visible,fog)
                        var bank_colors: Dictionary = {}
                        for side in range(4):
                            if (shoreline & (1 << side)) == 0:
                                continue
                            var land_cell: Vector2i = cell+Topology.DIRECTIONS[side]
                            if land_cell.x < 0 or land_cell.y < 0 or (
                                    land_cell.x >= dims.x or land_cell.y >= dims.y):
                                continue
                            if fog and not visible.has(land_cell):
                                continue
                            var land_kind: String = str(
                                state["terrain"][land_cell.y][land_cell.x])
                            bank_colors[side] = VisualStyle.terrain_color(
                                land_kind,land_cell.x,land_cell.y)
                        environment["shore_colors"] = bank_colors
                    else:
                        environment["water_edges"] = Topology.neighbor_mask(
                            state["terrain"],cell,"water",true,visible,fog)
                        if terrain == "mountain":
                            environment["exposed_edges"] = Topology.neighbor_mask(
                                state["terrain"],cell,"mountain",false,visible,fog)
                        elif detail == VisualBudget.DETAIL_FULL:
                            environment["mountain_edges"] = Topology.neighbor_mask(
                                state["terrain"],cell,"mountain",true,visible,fog)
                    TextureAtlas.draw_ground(canvas,terrain,c,hw,cell,detail)
                    SurfaceMaterials.draw_surface(canvas,terrain,c,hw,cell,detail)
                    WorldArt.draw_terrain(canvas,terrain,c,hw,phase,depth*17+x,
                        road_links,shoreline,terrain_links,crossing,detail,environment)
                    if terrain == "road":
                        SurfaceMaterials.draw_road_wear(canvas,c,hw,cell,detail,
                            crossing != 0)
                    decorated += 1
                if fog and not visible.has(cell):
                    _tile(canvas,vertices,Color(0.025,0.035,0.05,0.73))
    last_frame_stats = {
        "size":dims,"candidate_tiles":bounds.size.x*bounds.size.y,
        "tiles_drawn":drawn,"unknown_tiles":unknown,
        "terrain_detail_cells":decorated,"detail_level":detail
    }

    # Objective and installation overlays must never expose an unseen owner.
    if state.has("control"):
        for objective in state["control"]["nodes"]:
            var cell: Vector2i = objective["pos"]
            if (fog and not explored.has(cell)) or not bounds.has_point(cell):
                continue
            var owner: int = int(objective["owner"]) if not fog or visible.has(cell) else -1
            var tint := Color("#F2C04C")
            if owner == 0:
                tint = VisualStyle.faction_color(0)
            elif owner == 1:
                tint = VisualStyle.faction_color(1)
            var c: Vector2 = _center(cell, canvas, zoom, pan, dims)
            var badge: PackedVector2Array = PackedVector2Array([
                c + Vector2(0, -hh * 0.64), c + Vector2(hw * 0.26, 0),
                c + Vector2(0, hh * 0.64), c + Vector2(-hw * 0.26, 0)
            ])
            WorldArt.draw_relay(canvas, c, hw*0.38, tint, phase)
            canvas.draw_polyline(_ring(badge), tint.darkened(0.15), maxf(1.0, hw * 0.025), true)

    if state.has("economy"):
        # Direct painter callers may omit the board's cached snapshot.
        var draw_markers: Array = site_markers if not site_markers.is_empty() else SiteOverlayData.snapshots(state,0)
        for marker in draw_markers:
            var cell: Vector2i = marker["pos"]
            if not bounds.has_point(cell):
                continue
            var tint: Color = SiteOverlayPainter.owner_tint(int(marker["owner"]))
            var c: Vector2 = _center(cell,canvas,zoom,pan,dims)
            WorldArt.draw_site(canvas,str(marker["kind"]),c,hw*0.46,tint,phase)
            var selected: bool = cell == selected_factory_pos or cell == inspected_cell
            SiteOverlayPainter.draw_iso(canvas,marker,c,hw,selected,battery_saver)
            if selected:
                canvas.draw_polyline(_ring(_poly(cell,canvas,zoom,pan,dims)),
                    Color("#FFE451"),maxf(2.0,hw*0.055),true)

    # Read-only enemy inspection and friendly move+weapon envelopes. Orange
    # marks a possible shot AFTER a separate legal move, never an instant shot.
    var inspection: Dictionary = TacticalHints.inspect_enemy(state,inspected_enemy_id,0)
    for cell in inspection.get("moves",{}):
        if not bounds.has_point(cell):
            continue
        var poly: PackedVector2Array = _poly(cell,canvas,zoom,pan,dims)
        canvas.draw_colored_polygon(poly,Color(0.23,0.62,0.98,0.26))
    for cell in inspection.get("attacks",{}):
        if not bounds.has_point(cell):
            continue
        var poly: PackedVector2Array = _poly(cell,canvas,zoom,pan,dims)
        canvas.draw_colored_polygon(poly,VisualStyle.weapon_coverage_fill())
        canvas.draw_polyline(_ring(poly),VisualStyle.weapon_coverage_outline(),maxf(1.0,hw*0.025),true)
    var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
    for destination in hints["moves"]:
        var cell: Vector2i = destination
        if not bounds.has_point(cell):
            continue
        var poly: PackedVector2Array = _poly(cell, canvas, zoom, pan, dims)
        canvas.draw_colored_polygon(poly, VisualStyle.movement_fill())
        canvas.draw_polyline(_ring(poly), Color("#62BDFF"), maxf(1.0, hw * 0.025), true)
        if hw >= 23.0:
            canvas.draw_string(font, _center(cell, canvas, zoom, pan, dims) + Vector2(-hw * 0.06, hh * 0.16),
                str(hints["moves"][destination]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(maxf(10.0, hw * 0.20)), Color.WHITE)
    var weapon_area: Dictionary = TacticalHints.friendly_weapon_coverage(state,selected_id)
    for cell in weapon_area:
        if not bounds.has_point(cell):
            continue
        var poly: PackedVector2Array = _poly(cell,canvas,zoom,pan,dims)
        canvas.draw_colored_polygon(poly,VisualStyle.weapon_coverage_fill())
        canvas.draw_polyline(_ring(poly),VisualStyle.weapon_coverage_outline(),maxf(1.0,hw*0.025),true)
    for destination in hints["attacks"]:
        var cell: Vector2i = destination
        if not bounds.has_point(cell):
            continue
        var poly: PackedVector2Array = _poly(cell, canvas, zoom, pan, dims)
        canvas.draw_colored_polygon(poly, VisualStyle.attack_fill())
        canvas.draw_polyline(_ring(poly), Color("#FF6655"), maxf(2.0, hw * 0.035), true)

    # Units are depth-sorted; aircraft have a separate offset and outline.
    var draw_units: Array = state.get("units", []).duplicate()
    draw_units.sort_custom(func(a, b):
        var pos_a: Vector2i = a["pos"]
        var pos_b: Vector2i = b["pos"]
        if pos_a.x + pos_a.y != pos_b.x + pos_b.y:
            return pos_a.x + pos_a.y < pos_b.x + pos_b.y
        if Domains.layer(a) != Domains.layer(b):
            return Domains.layer(a) == "surface"
        return str(a["id"]) < str(b["id"])
    )
    var units_drawn := 0
    for unit in draw_units:
        if int(unit.get("hp", 0)) <= 0:
            continue
        var cell: Vector2i = unit["pos"]
        if not bounds.has_point(cell):
            continue
        var own: bool = int(unit["faction"]) == 0
        if fog and not own and not visible.has(cell):
            continue
        units_drawn += 1
        var is_air: bool = Domains.domain(unit) == Domains.AIR
        var is_naval: bool = Domains.domain(unit) == Domains.NAVAL
        var c: Vector2 = _center(cell, canvas, zoom, pan, dims)
        var is_moving := false
        for movement in motion_effects:
            if str(movement.get("id", "")) == str(unit["id"]):
                is_moving = true
                var t: float = clampf(float(movement["elapsed"]) / 0.32, 0.0, 1.0)
                var smooth: float = t*t*(3.0-2.0*t)
                var previous: Vector2i = movement["from"]
                c = _center(previous, canvas, zoom, pan, dims).lerp(c, smooth)
                break
        if is_air:
            c += Vector2(hw * 0.23, -hh * 0.48 + sin(phase*2.5) * hh*0.08)
        var tint: Color = VisualStyle.faction_color(int(unit["faction"]))
        var face: Color = tint.darkened(0.46) if bool(unit.get("acted", false)) else (tint.darkened(0.18) if bool(unit.get("moved", false)) else tint)
        var role: String = str(unit.get("role",""))
        var radius: float = hw * (0.29 if is_air else 0.33)
        var pose := "damaged" if int(unit.get("hp",10)) <= 3 else "idle"
        if is_moving:
            pose = "move"
        var visual_heading: Vector2i = unit_headings.get(str(unit["id"]), Vector2i.ZERO)
        for effect in combat_effects:
            if effect["origin"] == cell and float(effect["elapsed"]) <= BattleVFX.FLIGHT_SECONDS:
                pose = "attack"
                visual_heading = effect["target"] - cell
                break
        var sprite: Texture2D = null if detail == VisualBudget.DETAIL_COMPACT else UnitSprites.frame_texture(role,pose)
        if detail == VisualBudget.DETAIL_COMPACT:
            # Screen-space, high-contrast military markers stay legible where
            # a full 96px original sprite would become an indistinct 8px blur.
            var marker_radius: float = maxf(2.4,hw*0.31)
            canvas.draw_circle(c,marker_radius,Color("#102534"))
            canvas.draw_circle(c,maxf(1.9,marker_radius*0.73),face)
            if is_air:
                canvas.draw_line(c+Vector2(-marker_radius,0),c+Vector2(marker_radius,0),
                    Color.WHITE,maxf(1.0,hw*0.09),true)
            elif is_naval:
                canvas.draw_line(c+Vector2(0,-marker_radius),c+Vector2(0,marker_radius),
                    Color("#BDF2F3"),maxf(1.0,hw*0.09),true)
        elif sprite != null:
            var sprite_size := hw * (0.94 if is_air else 0.88)
            var rotation: float = BattleVFX.sprite_rotation(role,
                BattleVFX.projected_heading(Vector2i.ZERO,visual_heading))
            canvas.draw_set_transform(c,rotation)
            canvas.draw_texture_rect(sprite,
                Rect2(Vector2(-sprite_size*0.5,-sprite_size*0.56),Vector2.ONE*sprite_size),
                false,face)
            canvas.draw_set_transform(Vector2.ZERO)
        elif UnitArt.has_role(role):
            # Existing procedural silhouette is retained as a safe fallback.
            UnitArt.draw_unit(canvas, role, c, radius, face, phase)
        else:
            # Compatibility fallback ONLY for pre-role tutorial soldiers.
            if own:
                canvas.draw_circle(c, radius, face)
            else:
                canvas.draw_rect(Rect2(c-Vector2.ONE*radius,Vector2.ONE*(radius*2.0)),face)
            canvas.draw_string(font,c+Vector2(-radius*0.25,radius*0.35),
                str(unit["id"]),HORIZONTAL_ALIGNMENT_LEFT,-1,int(maxf(11.0,hw*0.27)),Color.WHITE)
        if is_air or is_naval:
            canvas.draw_arc(c, radius*1.34, 0, TAU, 24,
                Color("#B7F4FF") if is_air else Color("#70E6E2"), maxf(1.0, hw * 0.032))
        if str(unit["id"]) == selected_id:
            canvas.draw_arc(c, radius * 1.53, 0, TAU, 30,
                Color("#FFE451"), maxf(2.0, hw * 0.055))
        if hw >= 23.0:
            canvas.draw_string(font,c+Vector2(-radius*0.16,radius+hh*0.42),
                str(int(unit["hp"])),HORIZONTAL_ALIGNMENT_LEFT,-1,
                int(maxf(10.0,hw*0.22)),Color("#FFCE87") if int(unit["hp"]) <= 3 else Color.WHITE)
        # Ammunition and fuel warnings are never drawn on enemy troops.
        if own and unit.has("ammo") and hw >= 26.0:
            var ammo_max: int = Logistics.ammo_capacity(role)
            var fuel_max: int = Logistics.fuel_capacity(role)
            var warnings: Array[String] = []
            if ammo_max > 0 and int(unit["ammo"]) <= maxi(1,int(ammo_max/4)):
                warnings.append("M")
            if fuel_max > 0 and int(unit["fuel"]) <= maxi(2,int(fuel_max/4)):
                warnings.append("F")
            if not warnings.is_empty():
                canvas.draw_string(font,c+Vector2(-radius*0.8,-radius-hh*0.36),
                    "/".join(warnings),HORIZONTAL_ALIGNMENT_LEFT,-1,
                    int(maxf(10.0,hw*0.19)),Color("#FFD15A"))

    last_frame_stats["units_drawn"] = units_drawn
    if fog:
        var stale_contacts: Dictionary = Visibility.last_known_contacts(state, 0)
        for enemy_id in stale_contacts:
            var old_cell: Vector2i = stale_contacts[enemy_id]
            if not bounds.has_point(old_cell):
                continue
            var c: Vector2 = _center(old_cell, canvas, zoom, pan, dims)
            canvas.draw_arc(c, hw * 0.23, 0, TAU, 24, Color("#F0C86D"), maxf(1.0, hw * 0.035))
            canvas.draw_string(font, c + Vector2(-hw * 0.10, hh * 0.19), "?",
                HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(13.0, hw * 0.34)), Color("#F2DF90"))
    if pending_order.has("cell"):
        var pending_cell: Vector2i = pending_order["cell"]
        canvas.draw_polyline(_ring(_poly(pending_cell, canvas, zoom, pan, dims)),
            Color("#FFE451"), maxf(2.0, hw * 0.06), true)

    for destination in hints["attacks"]:
        if bounds.has_point(destination) and VisualBudget.should_draw_label(detail,hw):
            var damage: int = int(hints["attacks"][destination]["damage"])
            canvas.draw_string(font, _center(destination, canvas, zoom, pan, dims) + Vector2(hw * 0.12, hh * 0.52),
                "-%d" % damage, HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(maxf(11.0, hw * 0.21)), Color("#FFDE9F"))

    # Effects belong to rendering only, and their stored origins already
    # passed the fog-safety check in the core TouchBoard code.
    BattleVFX.draw_effects(canvas,combat_effects,hw,canvas.size,zoom,pan,dims)
