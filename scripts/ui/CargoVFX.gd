extends RefCounted
class_name TarvokaCargoVFX

# Pure short-lived battlefield animation. THIS IS NOT a saved unit, a free
# action or a real-time modification of the authoritative turn state.
# The chassis stays where Session placed it; a silhouette moves between
# visible tile centers while the IFV/APC side hatch opens and closes.
const Iso = preload("res://scripts/ui/IsoProjection.gd")
const Cargo = preload("res://scripts/core/CargoActions.gd")
const DURATION := 0.72
const MAX_EVENTS := 6

static func _unit(units: Array, id: String) -> Dictionary:
    for candidate in units:
        if candidate is Dictionary and str(candidate.get("id","")) == id:
            return candidate
    return {}

static func _contains(manifest: Array, passenger_id: String) -> bool:
    for soldier in manifest:
        if soldier is Dictionary and str(soldier.get("id","")) == passenger_id:
            return true
    return false

# Observe actual before/after combat states; never trust staged tap hints.
# Side 1 (AI/red) manifest is private, even in non-fog matches; drawing
# an enemy soldier moving into/out of its APC would leak that manifest.
static func event_for(before: Dictionary, after: Dictionary, action: String,
        carrier_id: String, passenger_id: String, viewer: int = 0) -> Dictionary:
    if action not in ["embark","disembark"] or viewer not in [0,1] or carrier_id.is_empty() or passenger_id.is_empty():
        return {}
    var carrier_before: Dictionary = _unit(before.get("units",[]),carrier_id)
    var carrier_after: Dictionary = _unit(after.get("units",[]),carrier_id)
    if carrier_before.is_empty() or carrier_after.is_empty():
        return {}
    if int(carrier_before.get("faction",-1)) != viewer or int(carrier_after.get("faction",-1)) != viewer:
        return {}
    var role: String = str(carrier_after.get("role",""))
    if Cargo.capacity(role) <= 0 or not carrier_after.get("pos") is Vector2i or not carrier_before.get("pos") is Vector2i:
        return {}
    var source: Vector2i
    var target: Vector2i
    var soldier: Dictionary = {}
    var from_cargo: Array = Cargo.passengers(carrier_before)
    var to_cargo: Array = Cargo.passengers(carrier_after)
    if action == "embark":
        soldier = _unit(before["units"],passenger_id)
        if soldier.is_empty() or not soldier.get("pos") is Vector2i:
            return {}
        if not _unit(after["units"],passenger_id).is_empty() or _contains(from_cargo,passenger_id) or not _contains(to_cargo,passenger_id):
            return {}
        if to_cargo.size() != from_cargo.size()+1:
            return {}
        source = soldier["pos"]
        target = carrier_after["pos"]
    else:
        soldier = _unit(after["units"],passenger_id)
        if soldier.is_empty() or not soldier.get("pos") is Vector2i:
            return {}
        if not _unit(before["units"],passenger_id).is_empty() or not _contains(from_cargo,passenger_id) or _contains(to_cargo,passenger_id):
            return {}
        if from_cargo.size() != to_cargo.size()+1:
            return {}
        source = carrier_before["pos"]
        target = soldier["pos"]
    if int(soldier.get("faction",-1)) != viewer:
        return {}
    if absi(source.x-target.x)+absi(source.y-target.y) != 1:
        return {}
    return {"kind":action,"from":source,"to":target,
        "carrier":carrier_after["pos"],"carrier_role":role,
        "passenger_role":str(soldier.get("role","")),
        "elapsed":0.0,"viewer":viewer}

static func phase(effect: Dictionary) -> Dictionary:
    var t: float = clampf(float(effect.get("elapsed",DURATION))/DURATION,0.0,1.0)
    # Opening: 0.00-0.24, boarding: 0.22-0.78, closing: 0.78-1.00.
    var open: float = clampf(t/0.24,0.0,1.0) if t < 0.24 else (clampf((1.0-t)/0.22,0.0,1.0) if t > 0.78 else 1.0)
    var unit_t: float = clampf((t-0.20)/0.60,0.0,1.0)
    # Smoothstep without unbounded overshoot in either direction.
    unit_t = unit_t*unit_t*(3.0-2.0*unit_t)
    var size: float = maxf(0.0,1.0-unit_t) if str(effect.get("kind","")) == "embark" else unit_t
    return {"progress":t,"hatch":open,"soldier_t":unit_t,
        "soldier_scale":size,"dust":maxf(0.0,1.0-absf(t-0.52)*2.1)}

static func advance(effects: Array[Dictionary], dt: float) -> void:
    for effect in effects:
        effect["elapsed"] = float(effect.get("elapsed",0.0))+maxf(0.0,dt)
    for i in range(effects.size()-1,-1,-1):
        if float(effects[i].get("elapsed",0.0)) >= DURATION:
            effects.remove_at(i)

static func enqueue(effects: Array[Dictionary], event: Dictionary) -> void:
    if event.is_empty():
        return
    effects.append(event.duplicate(true))
    while effects.size() > MAX_EVENTS:
        effects.pop_front()

static func _render(canvas: CanvasItem, source: Vector2, destination: Vector2,
        carrier: Vector2, scale: float, effect: Dictionary,
        battery_saver: bool) -> void:
    if scale < 9.0:
        return
    var state: Dictionary = phase(effect)
    var p: float = float(state["progress"])
    if p >= 1.0:
        return
    var openness: float = float(state["hatch"])
    var unit_t: float = float(state["soldier_t"])
    var troop_scale: float = float(state["soldier_scale"])
    var role: String = str(effect["carrier_role"])
    var armor_tint := Color("#5C9EBC") if role == "ifv" else Color("#74B09B")
    # Hatch frame sits on top of the actual chassis sprite. The IFV's
    # smaller rear hatch deliberately reads differently from APC double doors.
    var w: float = scale * (0.29 if role == "ifv" else 0.37)
    var h: float = scale * (0.12 if role == "ifv" else 0.17)
    var edge := carrier+Vector2(-w*0.5,-h*0.7)
    canvas.draw_rect(Rect2(edge,Vector2(w,h)),Color(0.035,0.065,0.082,0.88))
    canvas.draw_rect(Rect2(edge,Vector2(w,h)),armor_tint,false,maxf(1.0,scale*0.021))
    var door_gap: float = w*(0.09+0.42*openness)
    var offset_x: float = w*0.5
    canvas.draw_line(carrier+Vector2(-offset_x,-h*0.8),
        carrier+Vector2(-door_gap,-h*0.8-openness*h*0.65),
        Color("#BDE3EE"),maxf(1.2,scale*0.035),true)
    canvas.draw_line(carrier+Vector2(offset_x,-h*0.8),
        carrier+Vector2(door_gap,-h*0.8-openness*h*0.65),
        Color("#BDE3EE"),maxf(1.2,scale*0.035),true)
    # One recognizable troop marker travels toward the carrier when loading
    # and away from it when unloading. Nothing can be clicked at its position.
    var eased_pos := source.lerp(destination,unit_t)
    var r: float = maxf(0.0,scale*0.17*troop_scale)
    if r >= 1.2:
        var alpha: float = clampf(troop_scale*1.7,0.0,1.0)
        canvas.draw_circle(eased_pos+Vector2(0.0,-r*0.38),r*0.38,
            Color(0.94,0.96,0.87,alpha))
        canvas.draw_line(eased_pos+Vector2(0.0,-r*0.06),
            eased_pos+Vector2(0.0,r*0.71),
            Color(0.84,0.91,0.87,alpha),maxf(1.1,r*0.40),true)
        canvas.draw_line(eased_pos+Vector2(-r*0.40,r*0.10),
            eased_pos+Vector2(r*0.40,r*0.10),
            Color(0.85,0.94,0.97,alpha),maxf(1.0,r*0.23),true)
    if not battery_saver:
        # Dust / tread vibration: deterministic, lightweight and no RNG.
        var dust: float = float(state["dust"])
        if dust > 0.0:
            canvas.draw_arc(carrier,scale*(0.17+p*0.20),0.0,TAU,15,
                Color(0.80,0.89,0.79,dust*0.45),maxf(1.0,scale*0.020),true)
            for i in range(3):
                var angle: float = PI*0.15+float(i)*PI*0.80
                var point := carrier+Vector2(cos(angle),sin(angle))*scale*(0.19+p*0.11)
                canvas.draw_circle(point,maxf(0.7,scale*0.026*dust),
                    Color(0.89,0.84,0.66,dust*0.50))

static func draw_classic(canvas: CanvasItem, effects: Array[Dictionary],
        origin: Vector2, tile: float, battery_saver: bool = false) -> void:
    for effect in effects:
        var source: Vector2 = origin+(Vector2(effect["from"])+Vector2.ONE*0.5)*tile
        var dest: Vector2 = origin+(Vector2(effect["to"])+Vector2.ONE*0.5)*tile
        var carrier: Vector2 = origin+(Vector2(effect["carrier"])+Vector2.ONE*0.5)*tile
        _render(canvas,source,dest,carrier,tile,effect,battery_saver)

static func draw_iso(canvas: CanvasItem, effects: Array[Dictionary],
        view_size: Vector2, zoom: float, pan: Vector2,
        dimensions: Vector2i, half_width: float, battery_saver: bool = false) -> void:
    for effect in effects:
        var source: Vector2 = Iso.center(effect["from"],view_size,zoom,pan,dimensions)
        var dest: Vector2 = Iso.center(effect["to"],view_size,zoom,pan,dimensions)
        var carrier: Vector2 = Iso.center(effect["carrier"],view_size,zoom,pan,dimensions)
        _render(canvas,source,dest,carrier,half_width,effect,battery_saver)
