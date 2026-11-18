extends "res://scripts/ui/CivilianCityDesignStudioV37.gd"
class_name TarvokaCivilianCityDesignStudioV38

# V38 volume & proportion art workshop on the same actual model as EDIFICIOS.
# All tier views use the native builder; no proxy artwork or gameplay tests.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV38ProporcionesVolumetricas"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null and layout.get_child_count()>0:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V38 · MASAS Y PROPORCIONES"
    if _v19_toolbar!=null:
        for item in [
            ["V38 VILLA · TEJADO",Callable(self,"_v38_villa")],
            ["V38 CIUDAD · CORNISAS",Callable(self,"_v38_town")],
            ["V38 METRÓPOLI · CORONA",Callable(self,"_v38_metro")],
            ["V38 D2 · PERFIL ROTO",Callable(self,"_v38_d2")],
            ["V38 D3 · ESTRUCTURA BAJA",Callable(self,"_v38_d3")],
            ["V38 D4 · CIMIENTOS",Callable(self,"_v38_d4")],
            ["V38 CONJUNTO 360°",Callable(self,"_v38_overview")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(155,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V37","DESARROLLO · V38")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d bases cubierta · %d remates · %d perfiles dañados" % [
                int(_model.get_meta("city_v38_roof_mass_balanced",0)),
                int(_model.get_meta("city_v38_tier_profiles_balanced",0)),
                int(_model.get_meta("city_v38_damaged_profiles_balanced",0))]

func _v38_tier(value: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(value)
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    var roof_height: float=2.31 if value==0 else 6.51 if value==1 else 10.71
    _view_v19(Vector3(4.63,roof_height+0.30,3.62),-36.0,57.0,19.2)

func _v38_villa() -> void:
    _v38_tier(0)

func _v38_town() -> void:
    _v38_tier(1)

func _v38_metro() -> void:
    _v38_tier(2)

func _v38_damage(value: int,height: float,elevation: float) -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(value)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,height,3.62),-38.0,elevation,18.3)

func _v38_d2() -> void:
    var tier: int=0 if _tier==null else _tier.selected
    var roof_height: float=2.31 if tier==0 else 6.51 if tier==1 else 10.71
    _v38_damage(2,roof_height,59.0)

func _v38_d3() -> void:
    _v38_damage(3,0.69,47.0)

func _v38_d4() -> void:
    _v38_damage(4,0.17,38.0)

func _v38_overview() -> void:
    _view_v19(Vector3.ZERO,38.0,44.0,33.0)
