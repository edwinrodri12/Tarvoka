extends "res://scripts/ui/CivilianCityDesignStudioV41.gd"
class_name TarvokaCivilianCityDesignStudioV42

# V42: inspection-only studio, using the same native city scene tree
# as EDIFICIOS. Read geometric findings and capture via separate CI.
# No gameplay tests or automatic art approval.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV42RevisionVisual"
    if get_child_count()>1:
        var layout: VBoxContainer=get_child(1) as VBoxContainer
        if layout!=null and layout.get_child_count()>0:
            var heading: Label=layout.get_child(0) as Label
            if heading!=null:
                heading.text="TARVOKA · CIUDADES 3D V42 · REVISIÓN VISUAL"
    if _v19_toolbar!=null:
        for item in [
            ["V42 VILLA D0",Callable(self,"_v42_villa")],
            ["V42 CIUDAD D0",Callable(self,"_v42_town")],
            ["V42 METRÓPOLI D0",Callable(self,"_v42_metro")],
            ["V42 D2 TEJADO",Callable(self,"_v42_d2")],
            ["V42 D3 RUINAS",Callable(self,"_v42_d3")],
            ["V42 D4 ESCOMBROS",Callable(self,"_v42_d4")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(146,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status==null or _model==null or not is_instance_valid(_model):
        return
    _status.text=_status.text.replace("DESARROLLO · V41","DESARROLLO · V42")
    var count: int=int(_model.get_meta("city_v42_warning_count",0))
    if count==0:
        _status.text+=" · geometría sin alertas · render pendiente"
    else:
        var warnings: PackedStringArray=_model.get_meta(
            "city_v42_visual_warnings",PackedStringArray())
        _status.text+=" · %d avisos de geometría: %s" % [
            count,"; ".join(warnings)]
    _status.text+=" · SIN APROBACIÓN FINAL"

func _v42_tier(tier: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(0.0,_v40_height()*0.35,0.0),39.0,48.0,38.0)

func _v42_villa() -> void:
    _v42_tier(0)

func _v42_town() -> void:
    _v42_tier(1)

func _v42_metro() -> void:
    _v42_tier(2)

func _v42_damage(stage: int) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(stage)
    _lod.select(0)
    _rebuild()
    var y: float=_v40_height()*0.70 if stage==2 else 0.30
    _view_v19(Vector3(4.63,y,3.62),42.0,49.0,26.0)

func _v42_d2() -> void:
    _v42_damage(2)

func _v42_d3() -> void:
    _v42_damage(3)

func _v42_d4() -> void:
    _v42_damage(4)
