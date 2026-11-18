extends "res://scripts/ui/CivilianCityDesignStudioV29.gd"
class_name TarvokaCivilianCityDesignStudioV30

# Native Godot silhouette comparison. Uses the same city build_tactical()
# mesh hierarchy as the unified EDIFICIOS tab, not proxy screenshots.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV30TresPerfiles"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V30 · SILUETAS POR NIVEL"
    if _v19_toolbar!=null:
        for data in [
            ["VILLA · TEJAS",Callable(self,"_v30_villa")],
            ["CIUDAD · PARAPETO",Callable(self,"_v30_town")],
            ["METRÓPOLI · CORONA",Callable(self,"_v30_metro")],
            ["D2 IDENTIDAD ROTA",Callable(self,"_v30_d2")],
            ["D3 ESTRUCTURAS",Callable(self,"_v30_d3")],
            ["D4 RESTOS",Callable(self,"_v30_d4")],
            ["VER CONJUNTO",Callable(self,"_v30_overview")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(149,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V29","DESARROLLO · V30")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d siluetas recalibradas" % [
                int(_model.get_meta("city_v30_tuned_silhouette_meshes",0))]

func _v30_level(tier: int) -> void:
    if _tier==null or _damage==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,1.90,3.62),36.0,54.0,18.7)

func _v30_villa() -> void:
    _v30_level(0)

func _v30_town() -> void:
    _v30_level(1)

func _v30_metro() -> void:
    _v30_level(2)

func _v30_d2() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,2.19,3.62),-40.0,58.0,18.5)

func _v30_d3() -> void:
    _set_damage(3)
    _view_v19(Vector3(4.63,-2.80,3.62),124.0,45.0,17.2)

func _v30_d4() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-3.08,3.62),-113.0,39.0,17.6)

func _v30_overview() -> void:
    _view_v19(Vector3.ZERO,38.0,47.0,32.0)
