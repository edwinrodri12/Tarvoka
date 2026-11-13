extends RefCounted
class_name TarvokaTacticalUITheme

# Source: approved TARVOKA concept language, not Godot's default controls:
# deep navy tactical glass, electric-blue edging, ivory labels and gold
# decisive actions. One resource stylesheet is inherited by ALL scene panels.
# Intentional visual-only code; no new factions, resources or game mechanics.
const BG := Color("#07121F")
const SURFACE := Color("#0A1E31")
const PANEL := Color("#0C2438")
const INSET := Color("#091727")
const CYAN := Color("#37C8FF")
const CYAN_SOFT := Color("#12659C")
const GOLD := Color("#FFD54C")
const GOLD_DARK := Color("#664A0A")
const WHITE := Color("#F2F7FD")
const MUTED := Color("#B4D0E0")
const DANGER := Color("#F36A71")

static func frame(kind: String = "panel") -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    var highlight: Color = CYAN
    match kind:
        "screen":
            style.bg_color = Color("#061321")
            highlight = Color("#2FB8FF")
        "side":
            style.bg_color = SURFACE
        "hero":
            style.bg_color = Color("#082A42")
        "subtle":
            style.bg_color = Color("#0B1D2E")
            highlight = CYAN_SOFT
        "inset":
            style.bg_color = INSET
            highlight = Color("#175782")
        "gold":
            style.bg_color = Color("#28200A")
            highlight = GOLD
        "danger":
            style.bg_color = Color("#2C1623")
            highlight = DANGER
        _:
            style.bg_color = PANEL
    style.border_color = highlight
    style.set_border_width_all(2 if kind in ["side","hero","gold","danger"] else 1)
    style.set_corner_radius_all(7)
    style.content_margin_left = 13
    style.content_margin_right = 13
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    # Electric-blue / amber halo matches the original concept art while
    # remaining a cheap 2D StyleBox (no full-screen shaders or particle VFX).
    style.shadow_color = Color(highlight.r,highlight.g,highlight.b,
        0.24 if kind in ["hero","gold"] else 0.12)
    style.shadow_size = 4 if kind in ["hero","gold","side"] else 2
    return style

static func _button_box(state: String = "normal",gold: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    var line: Color = GOLD if gold else CYAN
    match state:
        "hover":
            style.bg_color = Color("#5A410E") if gold else Color("#163C59")
        "pressed":
            style.bg_color = Color("#8A650F") if gold else Color("#175E87")
        "disabled":
            style.bg_color = Color("#16212C")
            line = Color("#3C5361")
        "focus":
            style.bg_color = Color.TRANSPARENT
            line = GOLD if gold else Color("#C6F1FF")
        _:
            style.bg_color = Color("#392B0D") if gold else Color("#0D2942")
    style.border_color = line
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    if state not in ["disabled","focus"]:
        style.shadow_color = Color(line.r,line.g,line.b,0.26 if gold else 0.16)
        style.shadow_size = 3
    return style

static func _make_buttons(theme: Theme, type_name: String) -> void:
    for state in ["normal","hover","pressed","disabled","focus"]:
        theme.set_stylebox(state,type_name,_button_box(state))
    theme.set_color("font_color",type_name,WHITE)
    theme.set_color("font_hover_color",type_name,WHITE)
    theme.set_color("font_pressed_color",type_name,Color("#FFFFFF"))
    theme.set_color("font_disabled_color",type_name,Color("#8197A5"))
    theme.set_color("font_focus_color",type_name,GOLD)
    theme.set_font_size("font_size",type_name,17)

static func make_theme() -> Theme:
    var theme := Theme.new()
    theme.set_color("font_color","Label",WHITE)
    theme.set_color("font_shadow_color","Label",Color(0,0,0,0.54))
    theme.set_constant("shadow_offset_x","Label",1)
    theme.set_constant("shadow_offset_y","Label",1)
    theme.set_font_size("font_size","Label",16)
    theme.set_stylebox("panel","PanelContainer",frame())
    _make_buttons(theme,"Button")
    _make_buttons(theme,"OptionButton")
    _make_buttons(theme,"MenuButton")
    theme.set_color("font_color","PopupMenu",WHITE)
    theme.set_stylebox("panel","PopupMenu",frame("inset"))
    theme.set_stylebox("hover","PopupMenu",frame("hero"))
    theme.set_font_size("font_size","PopupMenu",16)
    for name in ["normal","read_only","focus"]:
        theme.set_stylebox(name,"LineEdit",frame("inset"))
    theme.set_color("font_color","LineEdit",WHITE)
    theme.set_color("font_placeholder_color","LineEdit",MUTED)
    theme.set_font_size("font_size","LineEdit",16)
    theme.set_stylebox("panel","TabContainer",frame("side"))
    theme.set_stylebox("tab_selected","TabContainer",_button_box("pressed",true))
    theme.set_stylebox("tab_unselected","TabContainer",_button_box())
    theme.set_stylebox("tab_hovered","TabContainer",_button_box("hover"))
    theme.set_stylebox("tab_disabled","TabContainer",_button_box("disabled"))
    theme.set_color("font_selected_color","TabContainer",GOLD)
    theme.set_color("font_unselected_color","TabContainer",MUTED)
    theme.set_color("font_hovered_color","TabContainer",WHITE)
    theme.set_font_size("font_size","TabContainer",16)
    var separator := StyleBoxFlat.new()
    separator.bg_color = Color("#2775A7")
    separator.content_margin_top = 1
    separator.content_margin_bottom = 1
    theme.set_stylebox("separator","HSeparator",separator)
    theme.set_constant("separation","VBoxContainer",9)
    theme.set_constant("separation","HBoxContainer",7)
    return theme

static func accent(button: Button, gold: bool = true) -> void:
    for state in ["normal","hover","pressed","disabled","focus"]:
        button.add_theme_stylebox_override(state,_button_box(state,gold))
    button.add_theme_color_override("font_color",WHITE if not gold else GOLD)
    button.add_theme_color_override("font_hover_color",WHITE)
    button.add_theme_color_override("font_pressed_color",WHITE)
    button.add_theme_color_override("font_disabled_color",Color("#8395A2"))

static func section(label: Label,gold: bool = false) -> void:
    label.add_theme_color_override("font_color",GOLD if gold else Color("#8ADBFF"))
    label.add_theme_font_size_override("font_size",19 if gold else 17)
