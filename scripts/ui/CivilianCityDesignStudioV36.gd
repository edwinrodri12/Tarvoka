extends "res://scripts/ui/CivilianCityDesignStudioV35.gd"
class_name TarvokaCivilianCityDesignStudioV36

# V36: manual equal-camera architectural damage comparison on the exact
# same native city mesh generator as the unified EDIFICIOS category.
# Not a separate illustration, screenshot, animation or gameplay test.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV36TransicionesDano"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V36 · ACABADOS D0–D4"
    if _v19_toolbar!=null:
        for item in [
            ["V36 D0 · INTACTA",Callable(self,"_v36_d0")],
            ["V36 D1 · DESGASTE",Callable(self,"_v36_d1")],
            ["V36 D2 · TECHO ABIERTO",Callable(self,"_v36_d2")],
            ["V36 D3 · ESTRUCTURA",Callable(self,"_v36_d3")],
            ["V36 D4 · ESCOMBROS",Callable(self,"_v36_d4")],
            ["V36 VER DISTRITO",Callable(self,"_v36_overview")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(149,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V35","DESARROLLO · V36")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d superficies · %d perfiles revisados" % [
                int(_model.get_meta("city_v36_materials_harmonized",0)),
                int(_model.get_meta("city_v36_profiles_checked",0))]

func _v36_damage(stage: int) -> void:
    if _damage==null or _tier==null or _lod==null:
        return
    _damage.select(stage)
    _lod.select(0)
    _rebuild()
    var level: int=_tier.selected+1
    var reference_roof: float=(
        2.31 if level==1 else 6.51 if level==2 else 10.71)
    # Same focus, angle, elevation, distance for all five damage stages.
    # Damage does not move the inspection camera between comparisons.
    _view_v19(
        Vector3(4.63,reference_roof*0.38,3.62),35.0,45.0,24.0)

func _v36_d0() -> void:
    _v36_damage(0)

func _v36_d1() -> void:
    _v36_damage(1)

func _v36_d2() -> void:
    _v36_damage(2)

func _v36_d3() -> void:
    _v36_damage(3)

func _v36_d4() -> void:
    _v36_damage(4)

func _v36_overview() -> void:
    _view_v19(Vector3.ZERO,39.0,44.0,33.0)
