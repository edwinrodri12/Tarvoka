extends PanelContainer
class_name TarvokaBuildingInfoPanel

# One reusable native Godot panel for friendly, hostile and neutral sites.
# All information comes from fog-filtered SiteInteractionData; only the real
# command-center production flow may create a unit or spend resources.
signal production_requested(site_pos: Vector2i)
signal close_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")

const FUNCTIONS := {
    "city":"Centro urbano. Su control proporciona ingresos a cada nuevo turno del propietario.",
    "factory":"Produce infantería y unidades básicas, según el catálogo de la partida.",
    "armor_plant":"Instalación especializada en vehículos blindados y tanques.",
    "artillery_depot":"Produce artillería, lanzacohetes y defensa antiaérea.",
    "drone_center":"Produce drones y plataformas aéreas ligeras.",
    "airbase":"Permite producir unidades aéreas y helicópteros.",
    "shipyard":"Instalación naval: produce barcos y unidades marítimas."
}
const STATUS := {
    "ready":"Lista para producir",
    "used":"Producción utilizada este turno",
    "wait":"Esperando turno disponible",
    "funds":"Créditos insuficientes",
    "blocked":"Producción bloqueada",
    "capture":"Captura pendiente al finalizar turno",
    "unknown":"Sin información de producción",
    "city":"Genera recursos, no unidades"
}

var site_pos: Vector2i = Vector2i(-1,-1)
var title_label: Label
var owner_label: Label
var function_label: Label
var status_label: Label
var production_button: Button
var close_button: Button
var emblem: TextureRect
var category_label: Label
var income_label: Label
var capture_label: Label
var corner_label: Label
var _info_scroll: ScrollContainer

func _make_text(parent: Node, value: String, size: int, tint: Color) -> Label:
    var item := Label.new()
    item.text = value
    item.add_theme_font_size_override("font_size",size)
    item.add_theme_color_override("font_color",tint)
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(item)
    return item

func _ready() -> void:
    name = "FichaEdificioSeleccionado"
    mouse_filter = Control.MOUSE_FILTER_STOP
    add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091B2AF4"),Chrome.EDGE_BRIGHT,12,10))
    var shell := VBoxContainer.new()
    shell.name = "PantallaDeEdificio"
    shell.add_theme_constant_override("separation",7)
    add_child(shell)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation",7)
    shell.add_child(top)
    var emblem_frame := PanelContainer.new()
    emblem_frame.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#10283A"),Chrome.EDGE,8,5))
    top.add_child(emblem_frame)
    emblem = TextureRect.new()
    emblem.custom_minimum_size = Vector2(45,45)
    emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
    emblem_frame.add_child(emblem)
    var identity := VBoxContainer.new()
    identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity.add_theme_constant_override("separation",2)
    top.add_child(identity)
    _make_text(identity,"TARVOKA  /  INSTALACIÓN",10,Chrome.MUTED)
    title_label = _make_text(identity,"EDIFICIO",18,Chrome.TEXT)
    title_label.clip_text = true
    close_button = Button.new()
    close_button.name = "CerrarFichaEdificio"
    close_button.text = "✕"
    close_button.custom_minimum_size = Vector2(42,44)
    close_button.tooltip_text = "Cerrar ficha"
    close_button.pressed.connect(func(): close_requested.emit())
    top.add_child(close_button)

    var separator := HSeparator.new()
    shell.add_child(separator)

    var allegiance := PanelContainer.new()
    allegiance.name = "IdentidadDeInstalacion"
    allegiance.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#132C3C"),Chrome.EDGE,6,7))
    shell.add_child(allegiance)
    owner_label = _make_text(allegiance,"PROPIETARIO",13,Chrome.TEXT)
    owner_label.clip_text = true

    _info_scroll = ScrollContainer.new()
    _info_scroll.name = "DatosDesplazablesDeEdificio"
    _info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _info_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    shell.add_child(_info_scroll)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation",6)
    _info_scroll.add_child(info)

    category_label = _make_text(info,"TIPO DE EDIFICIO",12,Chrome.GOLD)
    function_label = _make_text(info,"",13,Chrome.TEXT)

    var vital := PanelContainer.new()
    vital.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#102637"),Chrome.EDGE,7,7))
    info.add_child(vital)
    var columns := VBoxContainer.new()
    columns.add_theme_constant_override("separation",5)
    vital.add_child(columns)
    income_label = _make_text(columns,"",13,Chrome.GOLD)
    status_label = _make_text(columns,"",13,Chrome.TEXT)
    corner_label = _make_text(columns,"",12,Chrome.MUTED)
    capture_label = _make_text(info,"",12,Chrome.MUTED)

    production_button = Button.new()
    production_button.name = "AbrirCompraDeUnidades"
    production_button.text = "VER UNIDADES Y PRECIOS  ›"
    production_button.tooltip_text = "Abre el catálogo original, sin comprar automáticamente"
    production_button.custom_minimum_size.y = 48
    production_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    production_button.pressed.connect(_request_production)
    Chrome.emphasize(production_button,"primary")
    shell.add_child(production_button)
    hide()

func bind_site(data: Dictionary, can_open_catalog: bool) -> void:
    if not bool(data.get("valid",false)):
        site_pos = Vector2i(-1,-1)
        hide()
        return
    site_pos = data.get("pos",Vector2i(-1,-1))
    var kind: String = str(data.get("kind",""))
    var owner: int = int(data.get("owner",-2))
    var known: bool = bool(data.get("owner_known",false))
    var friendly: bool = bool(data.get("friendly",false))
    var owner_text := "SIN CONFIRMAR"
    if known:
        match owner:
            -1: owner_text = "NEUTRAL"
            0,1: owner_text = "ALIADO" if friendly else "ENEMIGO"
    var accent: Color = (
        Chrome.GREEN if friendly else
        Chrome.RED if known and owner in [0,1] else Chrome.GOLD)
    var emblem_id: int = int(data.get("owner_emblem",-1))
    emblem.texture = Factions.emblem_texture(emblem_id) if known and emblem_id>=0 else null
    emblem.visible = emblem.texture != null
    title_label.text = str(data.get("title","Instalación")).to_upper()
    var owner_name: String = str(data.get("owner_name",""))
    owner_label.text = "PROPIETARIO: %s%s" % [
        owner_text,("  ·  "+owner_name) if known and not owner_name.is_empty() else ""]
    owner_label.add_theme_color_override("font_color",accent)
    category_label.text = "TIPO  ·  "+kind.replace("_"," ").to_upper()
    function_label.text = str(FUNCTIONS.get(kind,"Instalación estratégica del mapa."))
    income_label.visible = kind=="city"
    income_label.text = "INGRESOS: +%d créditos/turno" % int(data.get("income",0))
    status_label.text = "ESTADO: "+str(STATUS.get(str(data.get("status","unknown")),"No disponible"))
    if bool(data.get("capture_pending",false)):
        status_label.text = "ESTADO: Captura pendiente al finalizar turno"
    if not friendly and kind!="city" and not bool(data.get("capture_pending",false)):
        status_label.text = "ESTADO: No puedes producir sin conquistar esta instalación"
    corner_label.text = "UBICACIÓN  ·  CASILLA %d, %d" % [site_pos.x+1,site_pos.y+1]
    capture_label.text = (
        "La infantería puede conquistar esta instalación al finalizar el turno."
        if not friendly else
        "Controlada por tu facción. Mantén su posición para conservarla.")
    production_button.visible = kind!="city" and friendly
    production_button.disabled = not can_open_catalog
    show()

func _request_production() -> void:
    if site_pos == Vector2i(-1,-1) or not production_button.visible or production_button.disabled:
        return
    production_requested.emit(site_pos)
