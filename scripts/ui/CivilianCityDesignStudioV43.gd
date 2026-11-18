extends "res://scripts/ui/CivilianCityDesignStudioV42.gd"
class_name TarvokaCivilianCityDesignStudioV43

# No more decorative buttons: inherit V42's 15 native tier/damage
# inspection selections, and show the real PBR/joint inspection results.
# A clear static check is not a substituted visual/render approval.
# Every V8–V42 parent _ready() calls _rebuild(). On V43, virtual
# dispatch previously rebuilt the full 43-stage city dozens of times
# while opening one browser scene. Defer those inherited startup calls,
# then assemble the identical final V43 model exactly ONCE.
var _initial_city_bootstrap: bool=true
var _city_advanced_archive: ScrollContainer
var _city_advanced_toggle: Button

func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV43Evidencia"
    if get_child_count()>1:
        var layout: VBoxContainer=get_child(1) as VBoxContainer
        if layout!=null and layout.get_child_count()>0:
            var heading: Label=layout.get_child(0) as Label
            if heading!=null:
                heading.text="TARVOKA · CIUDADES 3D V43 · EVIDENCIA ARTÍSTICA"
    if _status!=null:
        _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        _status.custom_minimum_size=Vector2(0,48)
    _install_visible_canvas_and_archive()
    _initial_city_bootstrap=false
    _rebuild()

func _install_visible_canvas_and_archive() -> void:
    # V19-V42 added hundreds of camera buttons to ONE HFlowContainer.
    # In a 720px browser window that container grows beyond the screen,
    # steals the SubViewportContainer's height, and creates a zero-size
    # WebGL framebuffer (INVALID_VALUE texImage2D / status 36054).
    # Keep every approved camera callable, but move it into a closed,
    # bounded, scrollable archive below the actual 3D canvas.
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null or _v19_toolbar==null:
        push_error("Ciudad V43: missing original 3D layout or camera toolbar")
        return
    var canvas: SubViewportContainer=layout.get_child(2) as SubViewportContainer
    if canvas==null:
        push_error("Ciudad V43: real SubViewportContainer unavailable")
        return
    canvas.custom_minimum_size=Vector2(0,240)
    canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
    canvas.stretch=true
    if viewport!=null:
        viewport.size=Vector2i(960,540)
        viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    _city_advanced_toggle=Button.new()
    _city_advanced_toggle.name="CiudadesV43_MostrarCamarasHistoricas"
    _city_advanced_toggle.text="MÁS CÁMARAS 3D · EXPANDIR V8–V42"
    _city_advanced_toggle.toggle_mode=true
    _city_advanced_toggle.button_pressed=false
    _city_advanced_toggle.custom_minimum_size=Vector2(0,32)
    layout.add_child(_city_advanced_toggle)
    layout.move_child(_city_advanced_toggle,4)
    _city_advanced_archive=ScrollContainer.new()
    _city_advanced_archive.name="CiudadesV43_ArchivoDeCamarasDesplazable"
    _city_advanced_archive.custom_minimum_size=Vector2(0,125)
    _city_advanced_archive.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _city_advanced_archive.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
    _city_advanced_archive.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    _city_advanced_archive.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
    layout.add_child(_city_advanced_archive)
    layout.move_child(_city_advanced_archive,5)
    _v19_toolbar.reparent(_city_advanced_archive)
    _v19_toolbar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _city_advanced_archive.visible=false
    _city_advanced_toggle.toggled.connect(_toggle_city_advanced_cameras)

func _toggle_city_advanced_cameras(open: bool) -> void:
    if _city_advanced_archive!=null:
        _city_advanced_archive.visible=open
    if _city_advanced_toggle!=null:
        _city_advanced_toggle.text=(
            "MENOS CÁMARAS · OCULTAR V8–V42" if open else
            "MÁS CÁMARAS 3D · EXPANDIR V8–V42")

func _rebuild() -> void:
    if _initial_city_bootstrap:
        return
    super._rebuild()
    if _status==null or _model==null or not is_instance_valid(_model):
        return
    _status.text=_status.text.replace("DESARROLLO · V42","DESARROLLO · V43")
    var issues: int=int(_model.get_meta("city_v43_issue_count",-1))
    if issues<0:
        _status.text+=" · V43 SIN DATOS · RENDER PENDIENTE"
        return
    if issues==0:
        _status.text+=" · V43: uniones y PBR sin alertas estáticas"
    else:
        var details: PackedStringArray=_model.get_meta(
            "city_v43_art_issues",PackedStringArray())
        _status.text+=" · V43 %d problemas: %s" % [
            issues,"; ".join(details)]
    _status.text+=" · pendiente de inspección de capturas Godot"
