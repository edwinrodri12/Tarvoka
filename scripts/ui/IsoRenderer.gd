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
const BattleVFX = preload("res://scripts/ui/BattleVFX.gd")

static func _ring(vertices: PackedVector2Array) -> PackedVector2Array:
    var outline: PackedVector2Array = vertices.duplicate()
    outline.append(vertices[0])
    return outline

static func _tile(canvas: Control, vertices: PackedVector2Array, tint: Color) -> void:
    canvas.draw_colored_polygon(vertices, tint)
    canvas.draw_polyline(_ring(vertices), Color(0.05, 0.09, 0.12, 0.72), 1.2, true)

static func _center(cell: Vector2i, canvas: Control, zoom: float, pan: Vector2, dims: Vector2i = Vector2i(10,8)) -> Vector2:
    return IsoTransform.center(cell, canvas.size, zoom, pan, dims)

static func _poly(cell: Vector2i, canvas: Control, zoom: float, pan: Vector2, dims: Vector2i = Vector2i(10,8)) -> PackedVector2Array:
    return IsoTransform.diamond(cell, canvas.size, zoom, pan, dims)

static func draw_board(canvas: Control, state: Dictionary, selected_id: String,
        selected_factory_pos: Vector2i, pending_order: Dictionary,
        combat_effects: Array, zoom: float, pan: Vector2, motion_effects: Array = [], phase: float = 0.0,
        unit_headings: Dictionary = {}) -> void:
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
    # Painter order avoids reversed elevation occluding neighboring ground.
    for depth in range(dims.x + dims.y - 1):
        for y in range(dims.y):
            var x: int = depth - y
            if x < 0 or x >= dims.x:
                continue
            var cell := Vector2i(x, y)
            var vertices: PackedVector2Array = _poly(cell, canvas, zoom, pan, dims)
            var c: Vector2 = _center(cell, canvas, zoom, pan, dims)
            # Omit entirely offscreen tiles when the camera is panned or zoomed.
            if c.x < -hw*1.4 or c.x > canvas.size.x+hw*1.4 or c.y < -hw*1.5 or c.y > canvas.size.y+hw*1.5:
                continue
            var terrain: String = str(state["terrain"][y][x])
            var base: Color = VisualStyle.terrain_color(terrain, x, y)
            _tile(canvas, vertices, base)
            canvas.draw_line(vertices[0], vertices[1], base.lightened(0.20), maxf(1.0, hw * 0.025), true)
            canvas.draw_line(vertices[2], vertices[3], base.darkened(0.32), maxf(1.0, hw * 0.025), true)
            WorldArt.draw_terrain(canvas, terrain, c, hw, phase, depth * 17 + x)
            if fog and not visible.has(cell):
                # Unknown cells stay 100% opaque; explored cells are fogged.
                _tile(canvas, vertices, Color(0.015, 0.025, 0.04, 1.0) if not explored.has(cell)
                    else Color(0.025, 0.035, 0.05, 0.73))

    # Objective and installation overlays must never expose an unseen owner.
    if state.has("control"):
        for objective in state["control"]["nodes"]:
            var cell: Vector2i = objective["pos"]
            if fog and not explored.has(cell):
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
        for site in state["economy"]["sites"]:
            var cell: Vector2i = site["pos"]
            if fog and not explored.has(cell):
                continue
            var owner: int = int(site["owner"]) if not fog or visible.has(cell) or int(site["owner"]) == 0 else -1
            var tint := Color("#E5C57D")
            if owner in [0,1]:
                tint = VisualStyle.faction_color(owner)
            var c: Vector2 = _center(cell, canvas, zoom, pan, dims)
            WorldArt.draw_site(canvas, str(site["kind"]), c, hw*0.46, tint, phase)
            if cell == selected_factory_pos:
                canvas.draw_polyline(_ring(_poly(cell, canvas, zoom, pan, dims)),
                    Color("#FFE451"), maxf(2.0, hw * 0.055), true)

    # Blue movement/Red attacks come exclusively from authoritative hints.
    var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
    for destination in hints["moves"]:
        var cell: Vector2i = destination
        var poly: PackedVector2Array = _poly(cell, canvas, zoom, pan, dims)
        canvas.draw_colored_polygon(poly, VisualStyle.movement_fill())
        canvas.draw_polyline(_ring(poly), Color("#62BDFF"), maxf(1.0, hw * 0.025), true)
        if hw >= 23.0:
            canvas.draw_string(font, _center(cell, canvas, zoom, pan, dims) + Vector2(-hw * 0.06, hh * 0.16),
                str(hints["moves"][destination]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(maxf(10.0, hw * 0.20)), Color.WHITE)
    for destination in hints["attacks"]:
        var cell: Vector2i = destination
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
    for unit in draw_units:
        if int(unit.get("hp", 0)) <= 0:
            continue
        var cell: Vector2i = unit["pos"]
        var own: bool = int(unit["faction"]) == 0
        if fog and not own and not visible.has(cell):
            continue
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
        var sprite: Texture2D = UnitSprites.frame_texture(role,pose)
        if sprite != null:
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

    if fog:
        for enemy_id in Visibility.last_known_contacts(state, 0):
            var old_cell: Vector2i = Visibility.last_known_contacts(state, 0)[enemy_id]
            var c: Vector2 = _center(old_cell, canvas, zoom, pan, dims)
            canvas.draw_arc(c, hw * 0.23, 0, TAU, 24, Color("#F0C86D"), maxf(1.0, hw * 0.035))
            canvas.draw_string(font, c + Vector2(-hw * 0.10, hh * 0.19), "?",
                HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(13.0, hw * 0.34)), Color("#F2DF90"))
    if pending_order.has("cell"):
        var pending_cell: Vector2i = pending_order["cell"]
        canvas.draw_polyline(_ring(_poly(pending_cell, canvas, zoom, pan, dims)),
            Color("#FFE451"), maxf(2.0, hw * 0.06), true)

    for destination in hints["attacks"]:
        if hw >= 24.0:
            var damage: int = int(hints["attacks"][destination]["damage"])
            canvas.draw_string(font, _center(destination, canvas, zoom, pan, dims) + Vector2(hw * 0.12, hh * 0.52),
                "-%d" % damage, HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(maxf(11.0, hw * 0.21)), Color("#FFDE9F"))

    # Effects belong to rendering only, and their stored origins already
    # passed the fog-safety check in the core TouchBoard code.
    BattleVFX.draw_effects(canvas,combat_effects,hw,canvas.size,zoom,pan,dims)
