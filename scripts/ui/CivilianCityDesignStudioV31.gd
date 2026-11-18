extends "res://scripts/ui/CivilianCityDesignStudioV30.gd"
class_name TarvokaCivilianCityDesignStudioV31

# Same native three-tier city builder, with actual reversible LOD1/LOD2
# options for art review. No simulated sprites, geometry proxies or tests.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV31LecturaTactica"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V31 · LECTURA TÁCTICA"
    if _v19_toolbar!=null:
        for data in [
            ["VILLA TÁCTICA",Callable(self,"_v31_villa")],
            ["CIUDAD TÁCTICA",Callable(self,"_v31_town")],
            ["METRÓPOLI TÁCTICA",Callable(self,"_v31_metro")],
            ["DETALLE COMPLETO",Callable(self,"_v31_close")],
            ["VISTA TÁCTICA",Callable(self,"_v31_medium")],
            ["SILUETA LEJANA",Callable(self,"_v31_far")],
            ["D2 TÁCTICA",Callable(self,"_v31_d2")],
            ["D4 LEJANA",Callable(self,"_v31_d4")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(147,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V30","DESARROLLO · V31")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d perfiles · %d remates LOD" % [
                int(_model.get_meta("city_v31_rebalanced_pieces",0)),
                int(_model.get_meta("city_v31_far_lod_curated",0))]

func _v31_tier(tier: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _lod.select(1)
    _rebuild()
    _view_v19(Vector3.ZERO,38.0,55.0,31.0)

func _v31_villa() -> void:
    _v31_tier(0)

func _v31_town() -> void:
    _v31_tier(1)

func _v31_metro() -> void:
    _v31_tier(2)

func _v31_set_lod(level: int) -> void:
    if _lod==null:
        return
    _lod.select(level)
    _rebuild()
    _view_v19(Vector3.ZERO,38.0,53.0,31.0)

func _v31_close() -> void:
    _v31_set_lod(0)

func _v31_medium() -> void:
    _v31_set_lod(1)

func _v31_far() -> void:
    _v31_set_lod(2)

func _v31_d2() -> void:
    if _damage==null:
        return
    _damage.select(2)
    _v31_set_lod(1)

func _v31_d4() -> void:
    if _damage==null:
        return
    _damage.select(4)
    _v31_set_lod(2)
