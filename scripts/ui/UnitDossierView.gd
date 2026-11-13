extends VBoxContainer
class_name TarvokaUnitDossierView

const UnitIcon = preload("res://scripts/ui/UnitArtIcon.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const TacticalUI = preload("res://scripts/ui/TacticalUITheme.gd")

var compact := false
var _header: HBoxContainer
var _icon: Control
var _name: Label
var _status: Label
var _health: ProgressBar
var _stats: Label
var _details: Label

# One responsive graphical card for unit/building inspection. Never owns a
# battle action or persistent data; accepts already-authorized view model only.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_constant_override("separation",3)
    _header = HBoxContainer.new()
    _header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header.add_theme_constant_override("separation",8)
    add_child(_header)
    _icon = UnitIcon.new()
    _icon.custom_minimum_size = Vector2(47,47) if compact else Vector2(70,70)
    _header.add_child(_icon)
    var info := VBoxContainer.new()
    info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _header.add_child(info)
    _name = Label.new()
    _name.add_theme_font_size_override("font_size",14 if compact else 17)
    _name.add_theme_color_override("font_color",Color("#F5D982"))
    _name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_child(_name)
    _status = Label.new()
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _status.add_theme_font_size_override("font_size",12 if compact else 14)
    _status.add_theme_color_override("font_color",Color("#AAC7DB"))
    info.add_child(_status)
    _health = ProgressBar.new()
    _health.show_percentage = false
    _health.custom_minimum_size.y = 12 if compact else 16
    _health.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var gauge_bg := StyleBoxFlat.new()
    gauge_bg.bg_color = Color("#051522")
    gauge_bg.border_color = TacticalUI.CYAN_SOFT
    gauge_bg.set_border_width_all(1)
    gauge_bg.set_corner_radius_all(4)
    _health.add_theme_stylebox_override("background",gauge_bg)
    _set_health_tint(1.0)
    info.add_child(_health)
    _stats = Label.new()
    _stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _stats.add_theme_font_size_override("font_size",13 if compact else 15)
    _stats.add_theme_color_override("font_color",Color("#E6EDF3"))
    add_child(_stats)
    _details = Label.new()
    _details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _details.add_theme_font_size_override("font_size",12 if compact else 14)
    _details.add_theme_color_override("font_color",Color("#B5CED8"))
    add_child(_details)
    hide()

func _set_health_tint(ratio: float) -> void:
    if _health == null:
        return
    var gauge := StyleBoxFlat.new()
    gauge.bg_color = Color("#2DD793") if ratio > 0.55 else (Color("#F4C33C") if ratio > 0.28 else Color("#ED5963"))
    gauge.set_corner_radius_all(4)
    _health.add_theme_stylebox_override("fill",gauge)

func bind_dossier(data: Dictionary) -> void:
    if data.is_empty() or str(data.get("kind","none")) not in ["friendly","enemy","building"]:
        hide()
        return
    var kind: String = str(data["kind"])
    var is_unit: bool = kind in ["friendly","enemy"]
    _icon.visible = is_unit
    _health.visible = is_unit
    _name.text = str(data.get("name",""))
    _status.text = str(data.get("status",data.get("owner","")))
    if is_unit:
        _icon.call("configure",str(data.get("role","line")),VisualStyle.faction_color(0 if kind == "friendly" else 1))
        var current: int = maxi(0,int(data.get("hp",0)))
        var full: int = maxi(1,int(data.get("max_hp",current)))
        _health.max_value = full
        _health.value = mini(current,full)
        _set_health_tint(float(current)/float(full))
        _name.text += " · HP %d/%d" % [current,full]
    var values: Array = data.get("stats",[])
    var portions: PackedStringArray = []
    for entry in values:
        if not entry is Dictionary:
            continue
        portions.append("%s %s" % [str(entry.get("name","")),str(entry.get("value",""))])
    if compact and portions.size() > 4:
        _stats.text = "  ·  ".join(portions.slice(0,4))
    else:
        _stats.text = "  ·  ".join(portions)
    var extras: PackedStringArray = []
    if data.has("ammo"):
        extras.append("Munición %d/%d" % [int(data["ammo"]),int(data.get("ammo_max",0))])
    if data.has("fuel"):
        extras.append("Combustible %d/%d" % [int(data["fuel"]),int(data.get("fuel_max",0))])
    if not compact:
        extras.append(str(data.get("note","")))
    _details.text = "  ·  ".join(extras)
    _details.visible = not _details.text.is_empty()
    show()
