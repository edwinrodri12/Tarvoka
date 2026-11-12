extends AcceptDialog
class_name TarvokaUnitArtGallery

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Art = preload("res://scripts/ui/UnitArt.gd")
const Icon = preload("res://scripts/ui/UnitArtIcon.gd")
const SpriteAtlas = preload("res://scripts/ui/UnitSpriteAtlas.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")

var entries: VBoxContainer
var pose_picker: OptionButton
var faction_picker: OptionButton

func _ready() -> void:
    title = "TARVOKA | 32 diseños militares (preliminar)"
    ok_button_text = "Cerrar"
    min_size = Vector2i(290,280)
    var controls := VBoxContainer.new()
    controls.add_theme_constant_override("separation", 4)
    add_child(controls)
    pose_picker = OptionButton.new()
    pose_picker.custom_minimum_size.y = 40
    for text in ["Reposo","Movimiento","Ataque","Dañado"]:
        pose_picker.add_item(text)
    pose_picker.select(0)
    pose_picker.item_selected.connect(_select_pose)
    controls.add_child(pose_picker)
    faction_picker = OptionButton.new()
    faction_picker.custom_minimum_size.y = 40
    for i in range(8):
        faction_picker.add_item(str(VisualStyle.faction_info(i)["name"]))
    faction_picker.select(0)
    faction_picker.item_selected.connect(_select_faction)
    controls.add_child(faction_picker)
    var scroller := ScrollContainer.new()
    scroller.custom_minimum_size = Vector2(280,180)
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
        icon.configure(str(role),VisualStyle.faction_color(0))
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

func _select_pose(index: int) -> void:
    if entries == null or index < 0 or index >= SpriteAtlas.POSES.size():
        return
    var pose_name: String = str(SpriteAtlas.POSES[index])
    for row in entries.get_children():
        var icon = row.get_child(0)
        icon.set_pose(pose_name)

func _select_faction(index: int) -> void:
    if entries == null or index < 0 or index >= 8:
        return
    var tint: Color = VisualStyle.faction_color(index)
    for row in entries.get_children():
        var icon = row.get_child(0)
        icon.configure(str(icon.role),tint)
