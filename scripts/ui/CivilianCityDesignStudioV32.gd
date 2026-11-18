extends "res://scripts/ui/CivilianCityDesignStudioV31.gd"
class_name TarvokaCivilianCityDesignStudioV32

# V32 manual art inspection of EXISTING roof/facade/jagged ruin meshes.
# The same native build_tactical() city mesh tree as EDIFICIOS.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV32AcabadosYRuinas"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V32 · ACABADOS Y RUINAS"
    if _v19_toolbar!=null:
        for data in [
            ["VILLA · TEJADO",Callable(self,"_v32_villa_roof")],
            ["CIUDAD · CORNISA",Callable(self,"_v32_town_eave")],
            ["METRÓPOLI · CORONA",Callable(self,"_v32_metro_crown")],
            ["V32 D2 BORDE",Callable(self,"_v32_d2_roof")],
            ["V32 D3 FORJADO",Callable(self,"_v32_d3_floor")],
            ["V32 D4 CIMIENTOS",Callable(self,"_v32_d4_ground")],
            ["V32 CONJUNTO 360",Callable(self,"_v32_overview")]
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
        _status.text=_status.text.replace("DESARROLLO · V31","DESARROLLO · V32")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d acabados · %d restos a ras de suelo" % [
                int(_model.get_meta("city_v32_refinished_pieces",0)),
                int(_model.get_meta("city_v32_grounded_fragments",0))]

func _v32_roof(tier: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    var roof_y: float=2.75 if tier==0 else 6.7 if tier==1 else 10.9
    _view_v19(Vector3(4.63,roof_y,3.62),-39.0,55.0,17.8)

func _v32_villa_roof() -> void:
    _v32_roof(0)

func _v32_town_eave() -> void:
    _v32_roof(1)

func _v32_metro_crown() -> void:
    _v32_roof(2)

func _v32_damage(stage: int,focus_y: float,
        elevation: float,distance: float) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(stage)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,focus_y,3.62),
        -39.0,elevation,distance)

func _v32_d2_roof() -> void:
    var tier: int=0 if _tier==null else _tier.selected
    var h: float=2.45 if tier==0 else 6.55 if tier==1 else 10.75
    _v32_damage(2,h,61.0,18.2)

func _v32_d3_floor() -> void:
    _v32_damage(3,0.70,47.0,17.8)

func _v32_d4_ground() -> void:
    _v32_damage(4,0.18,37.0,16.9)

func _v32_overview() -> void:
    _view_v19(Vector3.ZERO,38.0,45.0,32.0)
