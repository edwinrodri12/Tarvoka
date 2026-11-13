extends RefCounted
class_name TarvokaSiteOverlayPainter

const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

# Map-first graphic affordances. Small badges indicate ownership and current
# ACTIONABLE status, not progress or made-up income ticks. No hitboxes, no
# textures or repeated labels on zoomed-out maps; touches keep their tiles.

static func owner_tint(owner: int, state: Dictionary = {}) -> Color:
    if owner in [0,1]:
        return Identity.color_for(state,owner)
    if owner == -1:
        return Color("#DECA81") # Confirmed neutral.
    return Color("#778895") # Unconfirmed owner under fog.

static func status_tint(marker: Dictionary) -> Color:
    match str(marker.get("status","unknown")):
        "capture":
            return Color("#FFD45E")
        "ready":
            return Color("#6FE0A2")
        "used":
            return Color("#82909B")
        "funds":
            return Color("#E9A555")
        "blocked":
            return Color("#ED807A")
        "wait":
            return Color("#A2B4BE")
        _:
            return Color("#B8C3CF")

static func status_symbol(marker: Dictionary) -> String:
    match str(marker.get("status","unknown")):
        "capture":
            return "!"
        "ready":
            return "+"
        "used":
            return "-"
        "funds":
            return "$"
        "blocked":
            return "x"
        "wait":
            return "."
        _:
            return ""

static func selected_caption(marker: Dictionary) -> String:
    if str(marker.get("kind","")) == "city":
        if bool(marker.get("capture_pending",false)):
            return "Captura al terminar turno"
        var income: int = int(marker.get("income",0))
        return "+%d / turno" % income
    var caption: String = str(marker.get("caption",""))
    if caption.is_empty():
        return "Instalación"
    return caption

static func draw_classic(canvas: CanvasItem, marker: Dictionary, top_left: Vector2, tile: float, selected: bool, state: Dictionary = {}) -> void:
    if tile < 16.0:
        return
    var tint: Color = owner_tint(int(marker.get("owner",-2)),state)
    # Small owner flag is always in a consistent corner; separate from
    # player unit's ammo badges and from the symbol at tile center.
    var flag := Rect2(top_left+Vector2(tile*0.07,tile*0.07),
        Vector2(maxf(2.0,tile*0.20),maxf(3.0,tile*0.11)))
    canvas.draw_rect(flag,Color("#091521"))
    canvas.draw_rect(flag.grow(-maxf(0.7,tile*0.015)),tint)
    var symbol: String = status_symbol(marker)
    if str(marker.get("kind","")) == "city":
        symbol = "!" if bool(marker.get("capture_pending",false)) else "$"
    if not symbol.is_empty() and tile >= 30.0:
        var box_size: float = clampf(tile*0.24,10.0,22.0)
        var pos := top_left + Vector2(tile-box_size-tile*0.06,tile*0.06)
        canvas.draw_rect(Rect2(pos,Vector2.ONE*box_size),Color("#0A1520"))
        canvas.draw_rect(Rect2(pos,Vector2.ONE*box_size),status_tint(marker),false,maxf(1.0,tile*0.025))
        canvas.draw_string(ThemeDB.fallback_font,pos+Vector2(box_size*0.28,box_size*0.78),
            symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,int(clampf(box_size*0.75,10.0,17.0)),status_tint(marker))
    if selected and tile >= 34.0:
        # Contextual text is shown only for one selected site, never on
        # all cities, so the units and movement hints remain readable.
        var label: String = selected_caption(marker)
        var font_size: int = int(clampf(tile*0.15,10.0,13.0))
        var text_position: Vector2 = top_left+Vector2(tile*0.06,-tile*0.08)
        canvas.draw_string(ThemeDB.fallback_font,text_position,
            label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("#FFE7AB"))

static func draw_iso(canvas: CanvasItem, marker: Dictionary, center: Vector2, hw: float, selected: bool, battery_saver: bool = false, state: Dictionary = {}) -> void:
    if hw < 9.0:
        return
    var tint: Color = owner_tint(int(marker.get("owner",-2)),state)
    var anchor: Vector2 = center+Vector2(-hw*0.32,-hw*0.23)
    var flag_len: float = clampf(hw*0.30,4.0,16.0)
    canvas.draw_line(anchor,anchor+Vector2(flag_len,0),Color("#08131D"),maxf(3.0,hw*0.12))
    canvas.draw_line(anchor,anchor+Vector2(flag_len,0),tint,maxf(2.0,hw*0.075))
    if battery_saver or hw < 18.0:
        return
    var symbol: String = status_symbol(marker)
    if str(marker.get("kind","")) == "city":
        symbol = "!" if bool(marker.get("capture_pending",false)) else "$"
    if not symbol.is_empty():
        var badge: Vector2 = center+Vector2(hw*0.43,-hw*0.26)
        var radius: float = clampf(hw*0.13,4.0,10.0)
        canvas.draw_circle(badge,radius+1.0,Color("#091621"))
        canvas.draw_circle(badge,radius,status_tint(marker))
        canvas.draw_string(ThemeDB.fallback_font,badge+Vector2(-radius*0.42,radius*0.42),
            symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,int(maxf(9.0,radius*1.3)),Color("#081521"))
    if selected and hw >= 24.0:
        var label: String = selected_caption(marker)
        canvas.draw_string(ThemeDB.fallback_font,center+Vector2(-hw*0.25,-hw*0.73),
            label,HORIZONTAL_ALIGNMENT_LEFT,-1,int(clampf(hw*0.25,11.0,15.0)),Color("#FFE7AB"))
