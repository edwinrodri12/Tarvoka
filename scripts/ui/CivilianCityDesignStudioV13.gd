extends "res://scripts/ui/CivilianCityDesignStudioV12.gd"
class_name TarvokaCivilianCityDesignStudioV13

# Manual architectural review of in-progress V13 native 3D geometry:
# roof-to-wall connectors, foundation pavement joints and ruined hall.
# No FPS, QA, combat or Android build.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV13EncuentrosYRuinas"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · CIUDADES V13 · CUBIERTAS, CIMIENTOS Y AYUNTAMIENTO"
    var controls: HFlowContainer=layout.get_child(3) as HFlowContainer
    if controls!=null:
        for item in [
            ["TEJADO PARTIDO",Callable(self,"_view_torn_roof")],
            ["CIMIENTOS",Callable(self,"_view_foundation")],
            ["AYUNTAMIENTO D2",Callable(self,"_view_civic_moderate")],
            ["AYUNTAMIENTO D3",Callable(self,"_view_civic_ruined")],
            ["AYUNTAMIENTO D4",Callable(self,"_view_civic_destroyed")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(126,34)
            button.pressed.connect(item[1])
            controls.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V12","DESARROLLO · V13")
        _status.text+=" · cubierta-muro, cimientos, friso cívico"

func _view_torn_roof() -> void:
    _set_damage(2)
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(33.0)
    _elevation=deg_to_rad(48.0)
    _distance=14.2
    _orient_camera()

func _view_foundation() -> void:
    _set_damage(3)
    _model_focus=Vector3(4.63,-0.28,2.29)
    _angle=deg_to_rad(42.0)
    _elevation=deg_to_rad(26.0)
    _distance=11.0
    _orient_camera()

func _civic_camera() -> void:
    # City hall front faces the central avenue from the north.
    _model_focus=Vector3(0.0,-0.15,-2.68)
    _angle=deg_to_rad(-13.0)
    _elevation=deg_to_rad(30.0)
    _distance=14.0
    _orient_camera()

func _view_civic_moderate() -> void:
    _set_damage(2)
    _civic_camera()

func _view_civic_ruined() -> void:
    _set_damage(3)
    _civic_camera()

func _view_civic_destroyed() -> void:
    _set_damage(4)
    _civic_camera()
