extends "res://scripts/ui/CivilianCityDesignStudioV38.gd"
class_name TarvokaCivilianCityDesignStudioV39

# V39: native corrective inspection. Uses the shared real V1–V39
# building mesh tree, not a substitute render. Three focused cameras
# verify actual sub-roof PBR and grounding of existing structural parts.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV39AuditoriaAcabados"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null and layout.get_child_count()>0:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V39 · AUDITORÍA ARTÍSTICA"
    if _v19_toolbar!=null:
        for item in [
            ["V39 CUBIERTA / MATERIAL",Callable(self,"_v39_roof")],
            ["V39 CIMIENTOS / TERRENO",Callable(self,"_v39_foundation")],
            ["V39 RUINAS D4 / APOYOS",Callable(self,"_v39_rubble")],
            ["V39 CONJUNTO 360°",Callable(self,"_v39_overview")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(162,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V38","DESARROLLO · V39")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d cubiertas · %d contactos asentados" % [
                int(_model.get_meta("city_v39_roof_materials_corrected",0)),
                int(_model.get_meta("city_v39_ground_gaps_corrected",0))]

func _v39_focus(damage: int,at: Vector3,
        angle: float,elevation: float,distance: float) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(damage)
    _lod.select(0)
    _rebuild()
    _view_v19(at,angle,elevation,distance)

func _v39_roof() -> void:
    var tier: int=0 if _tier==null else _tier.selected
    var height: float=2.31 if tier==0 else 6.51 if tier==1 else 10.71
    _v39_focus(0,Vector3(4.63,height+0.05,3.62),
        -36.0,54.0,18.1)

func _v39_foundation() -> void:
    _v39_focus(0,Vector3(4.63,0.12,3.62),
        22.0,22.0,16.6)

func _v39_rubble() -> void:
    _v39_focus(4,Vector3(4.63,0.14,3.62),
        133.0,34.0,17.7)

func _v39_overview() -> void:
    _view_v19(Vector3.ZERO,39.0,44.0,33.0)
