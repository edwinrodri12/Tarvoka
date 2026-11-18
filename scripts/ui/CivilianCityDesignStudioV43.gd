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
    _initial_city_bootstrap=false
    _rebuild()

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
