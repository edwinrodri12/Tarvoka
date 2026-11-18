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
var _city_archive_debug: Label

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
        _status.autowrap_mode=TextServer.AUTOWRAP_OFF
        _status.custom_minimum_size=Vector2(0,25)
    _install_visible_canvas_and_archive()
    # Open the genuinely intact Ciudad, not the final damage preset left
    # selected by the long V8-V42 historical camera initialization chain.
    if _tier!=null:
        _tier.select(1)
    if _damage!=null:
        _damage.select(0)
    if _lod!=null:
        # The intact D0 city has >1,700 close-up meshes. Open in the
        # actual mobile-friendly tactical level, keeping full LOD0 selectable.
        _lod.select(1)
    _angle=deg_to_rad(36.0)
    _elevation=deg_to_rad(29.0)
    _distance=29.0
    _initial_city_bootstrap=false
    _rebuild()
    # Parent versions leave their own close-up camera presets behind.
    # Explicitly frame the full block after the final requested city is built.
    _orient_camera()

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
    # V12-V18 added a SECOND overflowing HFlowContainer at layout index 3.
    # Keep the six genuine V8 camera buttons always visible, and archive
    # all later V9-V18 presets with V19-V42 below the 3D preview.
    var early_controls: HFlowContainer=layout.get_child(3) as HFlowContainer
    if early_controls==null or early_controls.get_child_count()<6:
        push_error("Ciudad V43: original camera bar missing")
        return
    var quick: HFlowContainer=HFlowContainer.new()
    quick.name="CiudadesV43_SeisCamarasEsenciales"
    quick.add_theme_constant_override("h_separation",6)
    quick.add_theme_constant_override("v_separation",4)
    quick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    layout.add_child(quick)
    layout.move_child(quick,3)
    for _camera in range(6):
        var original: Control=early_controls.get_child(0) as Control
        original.reparent(quick)
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
    var scroll_contents: VBoxContainer=VBoxContainer.new()
    scroll_contents.name="CiudadesV43_CamarasHistoricasYAuditoria"
    scroll_contents.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _city_advanced_archive.add_child(scroll_contents)
    early_controls.reparent(scroll_contents)
    early_controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _v19_toolbar.reparent(scroll_contents)
    _v19_toolbar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _city_archive_debug=Label.new()
    _city_archive_debug.name="CiudadesV43_AuditoriaDeAcabadosCompleta"
    _city_archive_debug.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    scroll_contents.add_child(_city_archive_debug)
    _city_advanced_archive.visible=false
    _city_advanced_toggle.toggled.connect(_toggle_city_advanced_cameras)

func _toggle_city_advanced_cameras(open: bool) -> void:
    if _city_advanced_archive!=null:
        _city_advanced_archive.visible=open
    if _city_advanced_toggle!=null:
        _city_advanced_toggle.text=(
            "MENOS CÁMARAS · OCULTAR V8–V42" if open else
            "MÁS CÁMARAS 3D · EXPANDIR V8–V42")

func _compact_city_visible_status() -> void:
    if _status==null or _model==null:
        return
    if _city_archive_debug!=null:
        _city_archive_debug.text=_status.text
    var kind: String=(
        "VILLA" if _tier.selected==0 else
        "CIUDAD" if _tier.selected==1 else "METRÓPOLI")
    _status.text=(
        "CIUDADES V43 · %s · D%d · %d mallas 3D · LOD%d · ARTE EN DESARROLLO" %
        [kind,_damage.selected,Cities.drawable_count(_model),_lod.selected])

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
        _compact_city_visible_status()
        return
    if issues==0:
        _status.text+=" · V43: uniones y PBR sin alertas estáticas"
    else:
        var details: PackedStringArray=_model.get_meta(
            "city_v43_art_issues",PackedStringArray())
        _status.text+=" · V43 %d problemas: %s" % [
            issues,"; ".join(details)]
    _status.text+=" · pendiente de inspección de capturas Godot"
    _compact_city_visible_status()
