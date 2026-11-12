extends AcceptDialog
class_name TarvokaUnitArtGallery

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Art = preload("res://scripts/ui/UnitArt.gd")
const Icon = preload("res://scripts/ui/UnitArtIcon.gd")

var entries: VBoxContainer

func _ready() -> void:
    title = "TARVOKA | 32 diseños militares (preliminar)"
    ok_button_text = "Cerrar"
    min_size = Vector2i(360,450)
    var scroller := ScrollContainer.new()
    scroller.custom_minimum_size = Vector2(350,400)
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroller)
    entries = VBoxContainer.new()
    entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entries.add_theme_constant_override("separation",6)
    scroller.add_child(entries)
    for role in Roles.ORDER + Arsenal.ORDER:
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 74
        entries.add_child(row)
        var icon := Icon.new()
        icon.custom_minimum_size = Vector2(78,72)
        icon.configure(str(role),Color("#2375F3"))
        row.add_child(icon)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var label := Label.new()
        label.text = Roles.label(str(role))
        label.add_theme_font_size_override("font_size",17)
        info.add_child(label)
        var kind := Label.new()
        var spec: Array = Art.design(str(role))
        kind.text = "%s · %s" % [str(spec[0]).capitalize(),str(role)]
        kind.add_theme_color_override("font_color",Color("#A8BDC6"))
        kind.add_theme_font_size_override("font_size",13)
        info.add_child(kind)
