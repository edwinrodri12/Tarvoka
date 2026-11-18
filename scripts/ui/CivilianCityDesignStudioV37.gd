extends "res://scripts/ui/CivilianCityDesignStudioV36.gd"
class_name TarvokaCivilianCityDesignStudioV37

# V37 native tactical visual workshop: inherited city builder,
# real reversible/compact LOD 0/1/2 and D2/D4 architectural details.
# These buttons modify the actual Godot model and camera, not an image.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV37LecturaTactica"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V37 · DETALLES Y SILUETAS TÁCTICAS"
    if _v19_toolbar!=null:
        for option in [
            ["V37 CERCA · LOD0",Callable(self,"_v37_close")],
            ["V37 TÁCTICA · LOD1",Callable(self,"_v37_tactical")],
            ["V37 LEJANA · LOD2",Callable(self,"_v37_far")],
            ["V37 D2 · TECHO",Callable(self,"_v37_open_roof")],
            ["V37 D3 · ESTRUCTURA",Callable(self,"_v37_open_structure")],
            ["V37 D4 · RUINAS",Callable(self,"_v37_rubble")],
            ["V37 VISTA 360°",Callable(self,"_v37_overview")]
        ]:
            var button:=Button.new()
            button.text=str(option[0])
            button.custom_minimum_size=Vector2(155,34)
            button.pressed.connect(option[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V36","DESARROLLO · V37")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d remates afinados" % [
                int(_model.get_meta("city_v37_profiles_refined",0))]

func _v37_lod(value: int) -> void:
    if _lod==null or _damage==null:
        return
    _lod.select(value)
    _rebuild()
    var focal_y: float=0.6 if _damage.selected>=3 else 2.6
    _view_v19(Vector3(0.0,focal_y,0.0),38.0,50.0,
        31.0 if value==0 else 34.0 if value==1 else 38.0)

func _v37_close() -> void:
    _v37_lod(0)

func _v37_tactical() -> void:
    _v37_lod(1)

func _v37_far() -> void:
    _v37_lod(2)

func _v37_damage(value: int,height: float,
        elevation: float,distance: float) -> void:
    if _lod==null or _damage==null:
        return
    _lod.select(0)
    _damage.select(value)
    _rebuild()
    _view_v19(Vector3(4.63,height,3.62),
        -38.0,elevation,distance)

func _v37_open_roof() -> void:
    var tier: int=0 if _tier==null else _tier.selected
    var y: float=2.3 if tier==0 else 6.5 if tier==1 else 10.7
    _v37_damage(2,y,58.0,17.8)

func _v37_open_structure() -> void:
    _v37_damage(3,0.70,48.0,17.5)

func _v37_rubble() -> void:
    _v37_damage(4,0.18,39.0,17.1)

func _v37_overview() -> void:
    _view_v19(Vector3.ZERO,39.0,43.0,33.0)
