extends RefCounted
class_name TarvokaBattleVFX

# Pure, non-authoritative rendering helpers. Grid movement, weapons and death
# are decided by BattleSession; these functions never produce combat effects.
const UnitArt = preload("res://scripts/ui/UnitArt.gd")
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const FLIGHT_SECONDS := 0.36
const COUNTER_START_SECONDS := 0.48
const COUNTER_FLIGHT_SECONDS := 0.22
const EFFECT_SECONDS := 0.88
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

static func _damage_number(canvas: CanvasItem, position: Vector2,
        amount: int, opacity: float, scale: float) -> void:
    if amount <= 0 or opacity <= 0.0 or scale < 8.0:
        return
    var font: Font = ThemeDB.fallback_font
    var font_size: int = int(clampf(scale*0.27,14.0,28.0))
    var label: String = "-%d" % amount
    canvas.draw_string(font,position+Vector2(1,1),
        label,HORIZONTAL_ALIGNMENT_CENTER,-1,font_size,
        Color(0.07,0.09,0.11,opacity*0.9))
    canvas.draw_string(font,position,
        label,HORIZONTAL_ALIGNMENT_CENTER,-1,font_size,
        Color(1.0,0.91,0.73,opacity))

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
        var src: Vector2 = IsoTransform.center(source, view_size, zoom, pan, grid_size) if source.x >= 0 else target_pos
        var is_tank_shot: bool = attacker_role == "tank"
        if source.x >= 0 and elapsed <= FLIGHT_SECONDS:
            var t: float = clampf(elapsed / FLIGHT_SECONDS, 0.0, 1.0)
            var direction: Vector2 = (target_pos-src).normalized()
            var muzzle: Vector2 = src + direction*minf(scale*0.26,src.distance_to(target_pos)*0.20)
            var point: Vector2 = muzzle.lerp(target_pos, t)
            var back: Vector2 = muzzle.lerp(target_pos, maxf(0.0, t - 0.25))
            var shot_tint: Color = impact_color(attacker_role)
            var beam: float = 0.085 if is_tank_shot else (0.05 if family_for_role(attacker_role) in ["gun","naval"] else 0.036)
            canvas.draw_line(back,point,Color(0.10,0.10,0.10,0.45),
                maxf(2.0,scale*beam*1.8),true)
            canvas.draw_line(back,point,Color(shot_tint.r,shot_tint.g,shot_tint.b,0.97),
                maxf(1.3,scale*beam),true)
            canvas.draw_circle(point,maxf(2.4,scale*(0.11 if is_tank_shot else 0.065)),Color("#FFF2C3"))
            if is_tank_shot and elapsed < 0.20:
                var flash: float = 1.0-clampf(elapsed/0.20,0.0,1.0)
                canvas.draw_circle(muzzle,maxf(2.0,scale*0.22*flash),
                    Color(1.0,0.69,0.16,0.82*flash))
        else:
            # A hidden attack origin is never plotted, but a visible impact
            # may still be shown without revealing its attacker.
            _impact(canvas,target_pos,scale,maxf(elapsed,FLIGHT_SECONDS),
                tint,destroyed,family)
        var inflicted: int = int(effect.get("damage",0))
        if inflicted > 0 and elapsed >= FLIGHT_SECONDS and elapsed < EFFECT_SECONDS:
            var rise: float = clampf((elapsed-FLIGHT_SECONDS)/(EFFECT_SECONDS-FLIGHT_SECONDS),0.0,1.0)
            _damage_number(canvas,target_pos+Vector2(0,-scale*(0.26+0.18*rise)),
                inflicted,1.0-rise,scale)
        var returned: int = int(effect.get("counter_damage",0))
        if returned > 0 and source.x >= 0 and elapsed >= COUNTER_START_SECONDS:
            # Response is a distinct visible shot, not a silent HP change.
            var response_time: float = elapsed-COUNTER_START_SECONDS
            if response_time <= COUNTER_FLIGHT_SECONDS:
                var response_t: float = clampf(response_time/COUNTER_FLIGHT_SECONDS,0.0,1.0)
                var counter_point: Vector2 = target_pos.lerp(src,response_t)
                var counter_back: Vector2 = target_pos.lerp(src,maxf(0.0,response_t-0.22))
                canvas.draw_line(counter_back,counter_point,
                    Color(0.89,0.76,0.65,0.96),maxf(1.7,scale*0.08),true)
                canvas.draw_circle(counter_point,maxf(2.2,scale*0.09),Color("#FFDFB9"))
            else:
                var response_elapsed: float = response_time-COUNTER_FLIGHT_SECONDS
                var response_opacity: float = 1.0-clampf(response_elapsed/0.18,0.0,1.0)
                canvas.draw_arc(src,scale*(0.13+response_elapsed*0.70),0.0,TAU,20,
                    Color(1.0,0.56,0.35,response_opacity),maxf(1.5,scale*0.065),true)
                _damage_number(canvas,src+Vector2(0,-scale*0.30),returned,
                    response_opacity,scale)
        if bool(effect.get("consumed", false)) and source.x >= 0:
            var launch: Vector2 = IsoTransform.center(source, view_size, zoom, pan, grid_size)
            var fade: float = 1.0 - clampf(elapsed / EFFECT_SECONDS, 0.0, 1.0)
            canvas.draw_arc(launch, scale * (0.06 + (1.0-fade)*0.30),
                0.0, TAU, 22, Color(1.0, 0.36, 0.20, fade),
                maxf(1.0, scale*0.04))
