extends "res://scripts/ui/CivilianCityDesignStudioV34.gd"
class_name TarvokaCivilianCityDesignStudioV35

# Manual V35 360-degree architectural inspection of real native Godot
# models. Never alters camera-independent building geometry or gameplay.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV35CuatroFachadas"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V35 · CUATRO FACHADAS"
    if _v19_toolbar!=null:
        for item in [
            ["V35 NORTE",Callable(self,"_v35_north")],
            ["V35 SUR",Callable(self,"_v35_south")],
            ["V35 ESTE",Callable(self,"_v35_east")],
            ["V35 OESTE",Callable(self,"_v35_west")],
            ["V35 D2 ESQUINA",Callable(self,"_v35_d2_corner")],
            ["V35 D4 BASE",Callable(self,"_v35_d4_base")],
            ["CONJUNTO 360°",Callable(self,"_v35_overview")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(148,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V34","DESARROLLO · V35")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d contactos de fachadas armonizados" % [
                int(_model.get_meta("city_v35_refinished_meshes",0))]

func _v35_cardinal(angle: float) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(0.0,2.7,0.0),angle,34.0,35.0)

func _v35_north() -> void:
    _v35_cardinal(180.0)

func _v35_south() -> void:
    _v35_cardinal(0.0)

func _v35_east() -> void:
    _v35_cardinal(90.0)

func _v35_west() -> void:
    _v35_cardinal(-90.0)

func _v35_d2_corner() -> void:
    _v34_focus(2,Vector3(4.63,2.20,3.62),47.0,57.0,17.6)

func _v35_d4_base() -> void:
    _v34_focus(4,Vector3(4.63,0.17,3.62),-115.0,37.0,17.4)

func _v35_overview() -> void:
    _view_v19(Vector3.ZERO,40.0,44.0,33.0)
