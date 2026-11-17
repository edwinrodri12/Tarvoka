extends PanelContainer
class_name TarvokaBuildingInfoPanel

# Native battlefield card. It only displays fog-safe SiteInteractionData
# and forwards the request to the existing, authoritative production menu.
# No credit, ownership, unit or turn mutation happens in this component.
signal production_requested(site_pos: Vector2i)
signal close_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")

var title_label: Label
var owner_label: Label
var function_label: Label
var status_label: Label
var production_button: Button
var close_button: Button
var site_pos: Vector2i = Vector2i(-1,-1)

const FUNCTIONS := {
    "city":"Genera créditos al inicio del turno del propietario. Capturable por infantería.",
    "factory":"Produce infantería y unidades ligeras.",
    "armor_plant":"Produce vehículos blindados y tanques.",
    "artillery_depot":"Produce artillería y sistemas antiaéreos.",
    "drone_center":"Produce drones y plataformas aéreas ligeras.",
    "airbase":"Produce helicópteros, cazas y bombarderos.",
    "shipyard":"Produce embarcaciones y unidades navales."
}

const STATUS := {
    "ready":"Producción disponible.",
    "used":"Esta instalación ya produjo durante el turno.",
    "wait":"Espera al turno de su propietario.",
    "funds":"Créditos insuficientes para producir.",
    "blocked":"Producción bloqueada: revisa el espacio y las condiciones.",
    "capture":"Captura pendiente al terminar el turno.",
    "unknown":"Estado de producción no disponible.",
    "city":"Captura por infantería; no produce unidades."
}

func _ready() -> void:
    name = "FichaEdificioSeleccionado"
    mouse_filter = Control.MOUSE_FILTER_STOP
    add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#101E2EF2"),Chrome.GOLD,10,10))
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation",5)
    add_child(body)

    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation",7)
    body.add_child(heading)
    title_label = Label.new()
    title_label.text = "EDIFICIO"
    title_label.clip_text = true
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.add_theme_font_size_override("font_size",17)
    title_label.add_theme_color_override("font_color",Chrome.GOLD)
    heading.add_child(title_label)

    close_button = Button.new()
    close_button.name = "CerrarFichaEdificio"
    close_button.text = "✕"
    close_button.tooltip_text = "Cerrar ficha del edificio"
    close_button.custom_minimum_size = Vector2(40,40)
    close_button.pressed.connect(func(): close_requested.emit())
    heading.add_child(close_button)

    owner_label = Label.new()
    owner_label.add_theme_font_size_override("font_size",13)
    owner_label.add_theme_color_override("font_color",Chrome.TEXT)
    body.add_child(owner_label)

    function_label = Label.new()
    function_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    function_label.add_theme_font_size_override("font_size",12)
    function_label.add_theme_color_override("font_color",Chrome.TEXT)
    body.add_child(function_label)

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size",12)
    status_label.add_theme_color_override("font_color",Chrome.GOLD)
    body.add_child(status_label)

    production_button = Button.new()
    production_button.name = "AbrirCompraDeUnidades"
    production_button.text = "VER UNIDADES Y PRECIOS"
    production_button.custom_minimum_size.y = 46
    production_button.pressed.connect(_request_production)
    Chrome.emphasize(production_button,"primary")
    body.add_child(production_button)
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
    var owner_text: String = "SIN CONFIRMAR"
    if known:
        match owner:
            -1: owner_text = "NEUTRAL"
            0, 1: owner_text = "ALIADO" if bool(data.get("production",false)) or (
                str(data.get("detail","")).contains("Propietario aliado")) else "ENEMIGO"
    title_label.text = str(data.get("title","Instalación")).to_upper()
    owner_label.text = "PROPIETARIO: %s    ·    CASILLA %d,%d" % [
        owner_text,site_pos.x+1,site_pos.y+1]
    function_label.text = str(FUNCTIONS.get(kind,"Instalación estratégica."))
    if kind == "city":
        function_label.text = "Ingreso: +%d créditos/turno. %s" % [
            int(data.get("income",0)),str(FUNCTIONS["city"])]
    var state_text: String = str(STATUS.get(str(data.get("status","unknown")),
        "Información de la instalación."))
    if bool(data.get("capture_pending",false)):
        state_text = str(STATUS["capture"])
    # Never surface the private production state of an unknown or enemy base.
    if kind != "city" and not bool(data.get("production",false)) and (
            not bool(data.get("capture_pending",false))):
        state_text = "No puedes producir aquí sin controlar esta instalación."
    status_label.text = state_text
    production_button.visible = kind != "city" and bool(data.get("production",false))
    production_button.disabled = not can_open_catalog
    production_button.tooltip_text = (
        "Abre el catálogo real de esta instalación; comprar requiere confirmación."
        if can_open_catalog else "Disponible en tu turno, sin órdenes pendientes.")
    show()

func _request_production() -> void:
    if site_pos == Vector2i(-1,-1) or not production_button.visible or (
            production_button.disabled):
        return
    production_requested.emit(site_pos)
