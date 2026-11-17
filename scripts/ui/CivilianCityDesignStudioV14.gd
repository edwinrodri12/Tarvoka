extends "res://scripts/ui/CivilianCityDesignStudioV13.gd"
class_name TarvokaCivilianCityDesignStudioV14

# Real V1-V4/V8-V14 model in an ART review viewport.
# Cardinal cameras help examine the silhouette of each damaged building.
# No automated QA, simulation, gameplay tests or release approval.

func _ready() -> void:
    super._ready()
    name="TARVOKA_CiudadesV14Vista360"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · CIUDADES 3D V14 · SILUETA 360° Y RUINAS"
    var controls: HFlowContainer=layout.get_child(3) as HFlowContainer
    if controls!=null:
        for item in [
            ["NORTE",Callable(self,"_view_north")],
            ["SUR",Callable(self,"_view_south")],
            ["ESTE",Callable(self,"_view_east")],
            ["OESTE",Callable(self,"_view_west")],
            ["D2 TEJADOS",Callable(self,"_view_damaged_roofs")],
            ["D3 MUROS",Callable(self,"_view_severe_walls")],
            ["D4 RUINAS",Callable(self,"_view_total_ruins")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(102,34)
            button.pressed.connect(item[1])
            controls.add_child(button)
    _reset_focus()
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V13","DESARROLLO · V14")
        _status.text+=" · silueta 360°, tejados fracturados, ayuntamiento"

func _set_cardinal(angle_degrees: float) -> void:
    _model_focus=Vector3.ZERO
    _angle=deg_to_rad(angle_degrees)
    _elevation=deg_to_rad(25.0)
    _distance=25.5
    _orient_camera()

func _view_north() -> void:
    _set_cardinal(180.0)

func _view_south() -> void:
    _set_cardinal(0.0)

func _view_east() -> void:
    _set_cardinal(90.0)

func _view_west() -> void:
    _set_cardinal(-90.0)

func _view_damaged_roofs() -> void:
    _set_damage(2)
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(45.0)
    _elevation=deg_to_rad(43.0)
    _distance=14.6
    _orient_camera()

func _view_severe_walls() -> void:
    _set_damage(3)
    _model_focus=Vector3(4.63,-0.19,-3.80)
    _angle=deg_to_rad(-36.0)
    _elevation=deg_to_rad(47.0)
    _distance=14.7
    _orient_camera()

func _view_total_ruins() -> void:
    _set_damage(4)
    _model_focus=Vector3.ZERO
    _angle=deg_to_rad(47.0)
    _elevation=deg_to_rad(42.0)
    _distance=23.0
    _orient_camera()
