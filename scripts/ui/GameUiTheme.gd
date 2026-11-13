extends RefCounted
class_name TarvokaGameUiTheme

# Original, lightweight UI chrome inspired by TARVOKA's archived concept
# panels: layered navy steel, warm command highlights, faction-blue tactical
# focus, restrained borders and readable typography. No copyrighted assets or
# texture imports; works in Godot 4.3 and on low-memory Android devices.
const BACKGROUND := Color("#08131F")
const SURFACE := Color("#102332")
const SURFACE_RAISED := Color("#193447")
const EDGE := Color("#36596D")
const EDGE_BRIGHT := Color("#608497")
const TEXT := Color("#F1F5F2")
const MUTED := Color("#B3CEDD")
const GOLD := Color("#EBD08F")
const BLUE := Color("#448DD2")
const BLUE_HOVER := Color("#2469A2")
const RED := Color("#C96361")
const GREEN := Color("#398C72")

static func box_style(bg: Color, border: Color, radius: int = 9, inset: int = 10) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = inset
    style.content_margin_right = inset
    style.content_margin_top = inset
    style.content_margin_bottom = inset
    return style

static func _button_style(bg: Color,border: Color,radius: int = 7) -> StyleBoxFlat:
    var style: StyleBoxFlat = box_style(bg,border,radius,8)
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style

static func create_theme() -> Theme:
    var style := Theme.new()
    style.default_font_size = 16
    for kind in ["Button","OptionButton","MenuButton"]:
        style.set_stylebox("normal",kind,_button_style(SURFACE_RAISED,EDGE))
        style.set_stylebox("hover",kind,_button_style(Color("#28516B"),EDGE_BRIGHT))
        style.set_stylebox("pressed",kind,_button_style(Color("#163B56"),BLUE))
        style.set_stylebox("disabled",kind,_button_style(Color("#111D28"),Color("#253949")))
        var focus_style := _button_style(Color.TRANSPARENT,GOLD)
        focus_style.bg_color = Color.TRANSPARENT
        focus_style.set_border_width_all(2)
        style.set_stylebox("focus",kind,focus_style)
        style.set_color("font_color",kind,TEXT)
        style.set_color("font_hover_color",kind,Color.WHITE)
        style.set_color("font_pressed_color",kind,GOLD)
        style.set_color("font_disabled_color",kind,Color("#7D95A4"))
        style.set_font_size("font_size",kind,16)
        style.set_constant("h_separation",kind,8)
    style.set_stylebox("panel","PanelContainer",box_style(SURFACE,EDGE))
    style.set_stylebox("panel","TabContainer",box_style(BACKGROUND,EDGE,8,8))
    style.set_stylebox("tab_selected","TabContainer",_button_style(SURFACE_RAISED,GOLD,7))
    style.set_stylebox("tab_unselected","TabContainer",_button_style(Color("#0E1C2A"),EDGE,7))
    style.set_stylebox("tab_hovered","TabContainer",_button_style(Color("#27475D"),EDGE_BRIGHT,7))
    style.set_stylebox("tab_disabled","TabContainer",_button_style(BACKGROUND,EDGE,7))
    style.set_color("font_selected_color","TabContainer",GOLD)
    style.set_color("font_unselected_color","TabContainer",MUTED)
    style.set_color("font_hovered_color","TabContainer",TEXT)
    style.set_font_size("font_size","TabContainer",16)
    style.set_color("font_color","Label",TEXT)
    style.set_font_size("font_size","Label",16)
    style.set_color("font_color","RichTextLabel",TEXT)
    style.set_stylebox("normal","LineEdit",box_style(Color("#0C1C2A"),EDGE,6,8))
    style.set_stylebox("focus","LineEdit",box_style(Color.TRANSPARENT,BLUE,6,8))
    style.set_color("font_color","LineEdit",TEXT)
    style.set_color("font_placeholder_color","LineEdit",MUTED)
    style.set_color("caret_color","LineEdit",GOLD)
    style.set_color("font_color","SpinBox",TEXT)
    style.set_stylebox("panel","PopupPanel",box_style(SURFACE,EDGE_BRIGHT,8,9))
    style.set_stylebox("panel","PopupMenu",box_style(SURFACE,EDGE_BRIGHT,7,7))
    style.set_color("font_color","PopupMenu",TEXT)
    style.set_color("font_hover_color","PopupMenu",GOLD)
    style.set_stylebox("hover","PopupMenu",_button_style(SURFACE_RAISED,BLUE))
    style.set_stylebox("separator","PopupMenu",box_style(EDGE,EDGE,0,0))
    style.set_stylebox("separator","HSeparator",box_style(EDGE,EDGE,0,0))
    style.set_stylebox("separator","VSeparator",box_style(EDGE,EDGE,0,0))
    return style

static func emphasize(button: Button, variant: String = "primary") -> void:
    var fill: Color = BLUE if variant == "primary" else (GREEN if variant == "success" else (RED if variant == "danger" else SURFACE_RAISED))
    var edge: Color = GOLD if variant == "primary" else (Color("#72CAB0") if variant == "success" else (Color("#EA9690") if variant == "danger" else EDGE_BRIGHT))
    button.add_theme_stylebox_override("normal",_button_style(fill,edge))
    button.add_theme_stylebox_override("hover",_button_style(fill.lightened(0.16),GOLD))
    button.add_theme_stylebox_override("pressed",_button_style(fill.darkened(0.20),edge))
    button.add_theme_stylebox_override("disabled",_button_style(Color("#162634"),Color("#34495B")))
    button.add_theme_color_override("font_color",TEXT)
    button.add_theme_color_override("font_hover_color",Color.WHITE)
    button.add_theme_color_override("font_pressed_color",Color.WHITE)
    button.add_theme_color_override("font_disabled_color",Color("#74899A"))
    button.add_theme_font_size_override("font_size",17)

static func section(label: Label) -> void:
    label.add_theme_color_override("font_color",GOLD)
    label.add_theme_font_size_override("font_size",17)
