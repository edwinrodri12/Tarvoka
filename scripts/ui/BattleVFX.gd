extends RefCounted
class_name TarvokaBattleVFX

# Pure, non-authoritative rendering helpers. Grid movement, weapons and death
# are decided by BattleSession; these functions never produce combat effects.
const UnitArt = preload("res://scripts/ui/UnitArt.gd")
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const FLIGHT_SECONDS := 0.24
const EFFECT_SECONDS := 0.55
const STEP_ANGLE := PI / 4.0

static func projected_heading(from_cell: Vector2i, to_cell: Vector2i) -> Vector2:
    var step: Vector2i = to_cell - from_cell
    return Vector2(float(step.x - step.y), float(step.x + step.y) * 0.5)

static func direction_sector(heading: Vector2) -> int:
    if heading.length_squared() < 0.0001:
        return -1
    return posmod(int(round(heading.angle() / STEP_ANGLE)), 8)

static func sprite_rotation(role: String, heading: Vector2) -> float:
    var sector: int = direction_sector(heading)
    if sector < 0:
        return 0.0
    var spec: Array = UnitArt.design(role)
    if spec.is_empty():
        return 0.0
    var family: String = str(spec[0])
    var variant: String = str(spec[1])
    # The base direction must match the actual authored SVG silhouette.
    var base_angle := -PI / 4.0
    if family == "air":
        base_angle = 0.0 if variant in ["attack_heli", "transport_heli"] else -PI / 2.0
    elif family in ["naval", "support"]:
        base_angle = -PI / 8.0
    return float(sector) * STEP_ANGLE - base_angle

static func family_for_role(role: String) -> String:
    var spec: Array = UnitArt.design(role)
    return str(spec[0]) if spec.size() == 2 else "ground"

static func impact_color(role: String) -> Color:
    match family_for_role(role):
        "air":
            return Color("#E6C5A0")
        "naval":
            return Color("#83D6E9")
        "armor", "support":
            return Color("#FF9D58")
        _:
            return Color("#FFCE7C")

static func _impact(canvas: CanvasItem, center: Vector2, radius: float,
        elapsed: float, tint: Color, destroyed: bool, family: String) -> void:
    var t: float = clampf((elapsed - FLIGHT_SECONDS) / (EFFECT_SECONDS - FLIGHT_SECONDS), 0.0, 1.0)
    var alpha: float = 1.0 - t
    var r: float = radius * (0.12 + (0.75 if destroyed else 0.48) * t)
    canvas.draw_arc(center, r, 0.0, TAU, 28,
        Color(tint.r, tint.g, tint.b, alpha * 0.90), maxf(1.0, radius * 0.055), true)
    canvas.draw_circle(center, radius * (0.15 if destroyed else 0.08) * alpha,
        Color(1.0, 0.89, 0.66, alpha * 0.70))
    # Air losses scatter fragments; ship losses produce a water splash;
    # ground losses leave momentary sparks. Nothing persists in game state.
    var fragments: int = 8 if destroyed else 4
    for i in range(fragments):
        var angle: float = TAU * float(i) / float(fragments) + 0.27
        var radial: Vector2 = Vector2(cos(angle), sin(angle))
        var start: Vector2 = center + radial * (r * 0.57)
        var finish: Vector2 = center + radial * (r * (1.13 if destroyed else 0.89))
        if family == "naval":
            finish.y += radius * 0.12
        elif family == "air":
            finish.y += radius * 0.18 * t
        canvas.draw_line(start, finish, Color(tint.r, tint.g, tint.b, alpha),
            maxf(1.0, radius * (0.05 if destroyed else 0.028)), true)

static func draw_effects(canvas: CanvasItem, effects: Array, scale: float,
        view_size: Vector2, zoom: float, pan: Vector2, grid_size: Vector2i = Vector2i(10,8)) -> void:
    for effect in effects:
        var elapsed: float = float(effect.get("elapsed", EFFECT_SECONDS))
        if elapsed >= EFFECT_SECONDS:
            continue
        var target: Vector2i = effect.get("target", Vector2i(-1,-1))
        if target.x < 0:
            continue
        var target_pos: Vector2 = IsoTransform.center(target, view_size, zoom, pan, grid_size)
        var source: Vector2i = effect.get("origin", Vector2i(-1,-1))
        var defender_role: String = str(effect.get("defender_role", ""))
        var attacker_role: String = str(effect.get("attacker_role", ""))
        var destroyed: bool = bool(effect.get("destroyed", false))
        var family: String = family_for_role(defender_role)
        var tint: Color = impact_color(defender_role)
        if source.x >= 0 and elapsed <= FLIGHT_SECONDS:
            var src: Vector2 = IsoTransform.center(source, view_size, zoom, pan, grid_size)
            var t: float = clampf(elapsed / FLIGHT_SECONDS, 0.0, 1.0)
            var point: Vector2 = src.lerp(target_pos, t)
            var back: Vector2 = src.lerp(target_pos, maxf(0.0, t - 0.18))
            var shot_tint: Color = impact_color(attacker_role)
            # Long-range artillery and naval weapons leave a pronounced tracer.
            var beam: float = 0.05 if family_for_role(attacker_role) in ["gun", "naval"] else 0.036
            canvas.draw_line(back, point, Color(shot_tint.r, shot_tint.g, shot_tint.b, 0.84),
                maxf(1.0, scale * beam), true)
            canvas.draw_circle(point, maxf(1.5, scale * 0.065), Color("#FFEAB1"))
        else:
            # A hidden attack origin is never plotted, but an already-visible
            # impact may still be shown without disclosing the attacker.
            _impact(canvas, target_pos, scale, maxf(elapsed, FLIGHT_SECONDS),
                tint, destroyed, family)
        if bool(effect.get("consumed", false)) and source.x >= 0:
            var launch: Vector2 = IsoTransform.center(source, view_size, zoom, pan, grid_size)
            var fade: float = 1.0 - clampf(elapsed / EFFECT_SECONDS, 0.0, 1.0)
            canvas.draw_arc(launch, scale * (0.06 + (1.0-fade)*0.30),
                0.0, TAU, 22, Color(1.0, 0.36, 0.20, fade),
                maxf(1.0, scale*0.04))
