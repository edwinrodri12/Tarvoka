extends PanelContainer
class_name TarvokaCommanderIdentityStrip

const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")

# Read-only portraits and badges for the two engine sides. Never displays
# hidden troop data or invents active commander powers.
var compact := false
var portraits: Array[TextureRect] = []
var crests: Array[TextureRect] = []
var names: Array[Label] = []
var turns: Array[Label] = []
var bars: Array[ColorRect] = []
var _last_key := -1

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var bg: Color = Color("#102436") if not compact else Color("#0B1D2B")
    add_theme_stylebox_override("panel",Chrome.box_style(bg,Chrome.EDGE,8,5 if compact else 9))
    var column := VBoxContainer.new()
    column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_theme_constant_override("separation",4 if compact else 8)
    add_child(column)
    if not compact:
        var kicker := Label.new()
        kicker.text = "COMANDANTES  /  BANDOS"
        kicker.add_theme_color_override("font_color",Chrome.GOLD)
        kicker.add_theme_font_size_override("font_size",14)
        kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
        column.add_child(kicker)
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation",5 if compact else 8)
    column.add_child(row)
    for side in range(2):
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_theme_stylebox_override("panel",Chrome.box_style(Color("#132C3B"),Chrome.EDGE,5,3 if compact else 6))
        row.add_child(card)
        var inside := VBoxContainer.new()
        inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
        inside.add_theme_constant_override("separation",3)
        card.add_child(inside)
        var line := HBoxContainer.new()
        line.mouse_filter = Control.MOUSE_FILTER_IGNORE
        line.add_theme_constant_override("separation",3 if compact else 6)
        inside.add_child(line)
        var picture := TextureRect.new()
        picture.name = "CommanderPortrait%d" % side
        picture.custom_minimum_size = Vector2(28,28) if compact else Vector2(48,45)
        picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
        line.add_child(picture)
        portraits.append(picture)
        var details := VBoxContainer.new()
        details.mouse_filter = Control.MOUSE_FILTER_IGNORE
        details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(details)
        var name := Label.new()
        name.name = "FactionName%d" % side
        name.clip_text = true
        name.mouse_filter = Control.MOUSE_FILTER_IGNORE
        name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name.add_theme_font_size_override("font_size",12 if compact else 15)
        details.add_child(name)
        names.append(name)
        var role := Label.new()
        role.name = "TurnBadge%d" % side
        role.clip_text = true
        role.mouse_filter = Control.MOUSE_FILTER_IGNORE
        role.add_theme_font_size_override("font_size",10 if compact else 12)
        details.add_child(role)
        turns.append(role)
        var stripe := ColorRect.new()
        stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
        stripe.custom_minimum_size = Vector2(0,3 if compact else 5)
        inside.add_child(stripe)
        bars.append(stripe)
        # Large identity comes from the same approved artwork as the small
        # selection cards, no separately invented battle image.
        var crest: TextureRect = TextureRect.new()
        crest.visible = false
        crests.append(crest)

func bind_state(state: Dictionary, vs_ai: bool) -> void:
    if names.size() != 2:
        return
    var key: int = hash([state.get(Identity.STATE_FIELD,{}),
        state.get("faction",-1),state.get("winner",-1),vs_ai,compact])
    if _last_key == key:
        return
    _last_key = key
    var active: int = int(state.get("faction",0))
    var winner: int = int(state.get("winner",-1))
    for side in range(2):
        var faction_key: String = Identity.key_for(state,side)
        var idx: int = Identity.index_for(faction_key)
        var title: String = Identity.name_for(state,side)
        var tint: Color = Identity.color_for(state,side)
        portraits[side].texture = Style.commander_texture(idx)
        portraits[side].visible = portraits[side].texture != null
        names[side].text = title
        names[side].tooltip_text = title
        names[side].add_theme_color_override("font_color",tint.lightened(0.22))
        bars[side].color = tint if (winner == -1 and active == side) or winner == side else tint.darkened(0.50)
        var role := "JUGADOR" if side == 0 else ("IA" if vs_ai else "JUGADOR 2")
        if winner != -1:
            role = "VICTORIA" if winner == side else "DERROTA"
        elif active == side:
            role = "EN TURNO" if side == 0 or not vs_ai else "TURNO IA"
        turns[side].text = role
        turns[side].add_theme_color_override("font_color",Chrome.GOLD if role in ["EN TURNO","TURNO IA","VICTORIA"] else Chrome.MUTED)
