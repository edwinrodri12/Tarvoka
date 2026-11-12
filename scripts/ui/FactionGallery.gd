extends AcceptDialog
class_name TarvokaFactionGallery

const Style = preload("res://scripts/ui/VisualStyle.gd")
var cards: VBoxContainer

func _ready() -> void:
    title = "TARVOKA | Identidades de facción"
    ok_button_text = "Cerrar"
    min_size = Vector2i(360, 410)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(340, 355)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    cards = VBoxContainer.new()
    cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards.add_theme_constant_override("separation", 8)
    scroll.add_child(cards)
    for i in range(Style.FACTIONS.size()):
        var data: Dictionary = Style.faction_info(i)
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 64
        row.add_theme_constant_override("separation", 10)
        cards.add_child(row)
        var texture: Texture2D = Style.emblem_texture(i)
        if texture != null:
            var picture := TextureRect.new()
            picture.texture = texture
            picture.custom_minimum_size = Vector2(62, 62)
            picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            row.add_child(picture)
        else:
            # Explicit placeholder, never an invented replacement for official art.
            var swatch := ColorRect.new()
            swatch.color = Style.faction_color(i)
            swatch.custom_minimum_size = Vector2(62, 62)
            swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
            row.add_child(swatch)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var name := Label.new()
        name.text = str(data["name"])
        name.add_theme_color_override("font_color", Style.faction_color(i))
        name.add_theme_font_size_override("font_size", 17)
        info.add_child(name)
        var motif := Label.new()
        motif.text = str(data["motif"])
        motif.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        motif.add_theme_font_size_override("font_size", 13)
        info.add_child(motif)
