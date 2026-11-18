extends "res://scripts/ui/CivilianCityDesignStudioV32.gd"
class_name TarvokaCivilianCityDesignStudioV33

# V33: native roof, stone and metal finish review, not a substitute render.
# All controls reuse the same real city GDScript builder as EDIFICIOS.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV33ContinuidadMaterial"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V33 · MATERIALES Y UNIONES"
    if _v19_toolbar!=null:
        for config in [
            ["VILLA · TEJA/MADERA",Callable(self,"_v33_villa")],
            ["CIUDAD · PIEDRA",Callable(self,"_v33_city")],
            ["METRÓPOLI · METAL",Callable(self,"_v33_metro")],
            ["D2 · TECHO FRACTURADO",Callable(self,"_v33_roof_damage")],
            ["D3 · MURO INTERIOR",Callable(self,"_v33_wall_damage")],
            ["D4 · RESTOS BAJOS",Callable(self,"_v33_low_ruins")],
            ["CONJUNTO 360°",Callable(self,"_v33_overview")]
        ]:
            var button:=Button.new()
            button.text=str(config[0])
            button.custom_minimum_size=Vector2(148,34)
            button.pressed.connect(config[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V32","DESARROLLO · V33")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d materiales armonizados" % [
                int(_model.get_meta("city_v33_materials_refinished",0))]

func _v33_tier(tier: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    var roof: float=2.75 if tier==0 else 6.7 if tier==1 else 10.9
    _view_v19(Vector3(4.63,roof,3.62),-38.0,51.0,17.5)

func _v33_villa() -> void:
    _v33_tier(0)

func _v33_city() -> void:
    _v33_tier(1)

func _v33_metro() -> void:
    _v33_tier(2)

func _v33_damaged(stage: int,height: float,elevation: float) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(stage)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,height,3.62),-42.0,elevation,18.0)

func _v33_roof_damage() -> void:
    var tier: int=0 if _tier==null else _tier.selected
    var height: float=2.47 if tier==0 else 6.6 if tier==1 else 10.8
    _v33_damaged(2,height,59.0)

func _v33_wall_damage() -> void:
    _v33_damaged(3,0.67,45.0)

func _v33_low_ruins() -> void:
    _v33_damaged(4,0.16,37.0)

func _v33_overview() -> void:
    _view_v19(Vector3.ZERO,38.0,46.0,32.0)
