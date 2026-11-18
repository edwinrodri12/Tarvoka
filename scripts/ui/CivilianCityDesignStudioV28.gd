extends "res://scripts/ui/CivilianCityDesignStudioV27.gd"
class_name TarvokaCivilianCityDesignStudioV28

# V28 manual inspection of the same native city assembly in EDIFICIOS.
# Review four elevations, roof corners and D4 remains; no mock-up meshes.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV28Coherencia360"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V28 · COHERENCIA 360°"
    if _v19_toolbar!=null:
        for data in [
            ["ALZADO NORTE",Callable(self,"_v28_north")],
            ["ALZADO SUR",Callable(self,"_v28_south")],
            ["ALZADO ESTE",Callable(self,"_v28_east")],
            ["ALZADO OESTE",Callable(self,"_v28_west")],
            ["D2 ESQUINA TECHO",Callable(self,"_v28_broken_corner")],
            ["D4 ARRANQUE MURO",Callable(self,"_v28_ruin_contacts")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(145,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V27","DESARROLLO · V28")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d acabados 360° armonizados" % [
                int(_model.get_meta("city_v28_harmonized_meshes",0))]

func _v28_north() -> void:
    _view_v19(Vector3(4.63,1.45,-3.80),180.0,31.0,17.8)

func _v28_south() -> void:
    _view_v19(Vector3(4.63,1.45,3.62),0.0,31.0,17.8)

func _v28_east() -> void:
    _view_v19(Vector3(4.63,1.45,3.62),90.0,32.0,17.8)

func _v28_west() -> void:
    _view_v19(Vector3(-4.63,1.45,-3.80),-90.0,32.0,17.8)

func _v28_broken_corner() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,2.15,3.62),-43.0,54.0,17.7)

func _v28_ruin_contacts() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,0.18,-3.80),133.0,36.0,17.7)
