extends "res://scripts/ui/CivilianCityDesignStudioV33.gd"
class_name TarvokaCivilianCityDesignStudioV34

# Native V34 art workshop: front stoops, passages, civic square and ruined
# interfaces. Uses the same CivilianCityTacticalLOD4 native 3D meshes.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV34EspaciosPublicos"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V34 · ESPACIOS PÚBLICOS"
    if _v19_toolbar!=null:
        for pair in [
            ["V34 ENTRADAS",Callable(self,"_v34_entries")],
            ["V34 PASAJES",Callable(self,"_v34_passages")],
            ["V34 PLAZA",Callable(self,"_v34_square")],
            ["V34 ACCESO MUNICIPAL",Callable(self,"_v34_civic")],
            ["V34 D2 ESQUINAS",Callable(self,"_v34_d2")],
            ["V34 D4 BORDES ROTOS",Callable(self,"_v34_d4")],
            ["CONJUNTO 360°",Callable(self,"_v34_overview")]
        ]:
            var button:=Button.new()
            button.text=str(pair[0])
            button.custom_minimum_size=Vector2(151,34)
            button.pressed.connect(pair[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V33","DESARROLLO · V34")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d entradas · %d pasajes · %d encuentros plaza" % [
                int(_model.get_meta("city_v34_thresholds",0)),
                int(_model.get_meta("city_v34_passages",0)),
                int(_model.get_meta("city_v34_civic",0))]

func _v34_focus(stage: int,focus: Vector3,
        azimuth: float,elevation: float,distance: float) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(stage)
    _lod.select(0)
    _rebuild()
    _view_v19(focus,azimuth,elevation,distance)

func _v34_entries() -> void:
    _v34_focus(0,Vector3(4.63,0.21,-1.83),0.0,29.0,17.9)

func _v34_passages() -> void:
    _v34_focus(0,Vector3(2.47,0.16,1.39),43.0,44.0,18.5)

func _v34_square() -> void:
    _v34_focus(0,Vector3(0.0,0.19,2.80),-35.0,46.0,18.8)

func _v34_civic() -> void:
    _v34_focus(0,Vector3(0.0,0.18,-1.54),0.0,31.0,16.9)

func _v34_d2() -> void:
    _v34_focus(2,Vector3(4.63,0.19,1.40),-37.0,43.0,18.7)

func _v34_d4() -> void:
    _v34_focus(4,Vector3(2.47,0.18,1.38),137.0,40.0,18.0)

func _v34_overview() -> void:
    _view_v19(Vector3.ZERO,39.0,44.0,33.0)
