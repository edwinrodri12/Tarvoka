extends VBoxContainer
class_name TarvokaTileContextCard

# Reusable, non-interactive fact ribbon. Actual purchases and capture
# navigation remain exclusively inside SiteActionBar.
var compact := false
var title_label: Label
var mobility_label: Label
var defense_label: Label
var status_label: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_constant_override("separation",3 if compact else 6)
    title_label = Label.new()
    title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_label.clip_text = true
    title_label.add_theme_font_size_override("font_size",14 if compact else 17)
    title_label.add_theme_color_override("font_color",Color("#F4D58C"))
    add_child(title_label)

    mobility_label = Label.new()
    mobility_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mobility_label.clip_text = true
    mobility_label.add_theme_font_size_override("font_size",11 if compact else 14)
    mobility_label.add_theme_color_override("font_color",Color("#DCECF3"))
    add_child(mobility_label)

    defense_label = Label.new()
    defense_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    defense_label.clip_text = true
    defense_label.add_theme_font_size_override("font_size",11 if compact else 14)
    defense_label.add_theme_color_override("font_color",Color("#86D6CB"))
    add_child(defense_label)

    status_label = Label.new()
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size",11 if compact else 13)
    status_label.add_theme_color_override("font_color",Color("#B9CED9"))
    add_child(status_label)
    hide()

func bind_context(data: Dictionary) -> void:
    var category: String = str(data.get("kind","none"))
    if category not in ["terrain","building","unknown"]:
        hide()
        return
    var owner: String = str(data.get("owner",""))
    title_label.text = "%s  ·  %s%s" % [str(data.get("title","")),
        str(data.get("location","")),("  ·  "+owner) if category == "building" else ""]
    mobility_label.text = str(data.get("movement",""))
    defense_label.text = str(data.get("defense",""))
    status_label.text = str(data.get("status",""))
    status_label.visible = not status_label.text.is_empty()
    if category == "unknown":
        mobility_label.hide()
        defense_label.hide()
    else:
        mobility_label.show()
        defense_label.show()
    show()
