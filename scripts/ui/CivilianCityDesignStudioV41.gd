extends "res://scripts/ui/CivilianCityDesignStudioV40.gd"
class_name TarvokaCivilianCityDesignStudioV41

# Native V41 focused art view. The real city builder is shared with
# EDIFICIOS; keep all five damage stages and LOD choices available.
# These are visual inspection cameras, not gameplay simulations.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV41EncuentrosDeCubierta"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null and layout.get_child_count()>0:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V41 · UNIONES DE CUBIERTA"
    if _v19_toolbar!=null:
        for item in [
            ["V41 VILLA · CUMBRERA",Callable(self,"_v41_villa")],
            ["V41 CIUDAD · CORNISA",Callable(self,"_v41_town")],
            ["V41 METRÓPOLI · CORONA",Callable(self,"_v41_metro")],
            ["V41 D2 · TEJADO ABIERTO",Callable(self,"_v41_d2")],
            ["V41 D4 · RUINAS",Callable(self,"_v41_d4")],
            ["V41 VISTA CONJUNTO",Callable(self,"_v41_overview")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(162,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V40","DESARROLLO · V41")
        if _model!=null and is_instance_valid(_model):
            var total: int=(
                int(_model.get_meta("city_v41_villa_ridge_joins",0))
                +int(_model.get_meta("city_v41_town_parapet_joins",0))
                +int(_model.get_meta("city_v41_metropolis_crown_joins",0)))
            _status.text+=" · %d encuentros 3D ajustados · pendiente render" % total

func _v41_closeup(tier: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    var roof_height: float=2.31 if tier==0 else 6.51 if tier==1 else 10.71
    _view_v19(Vector3(4.63,roof_height+0.46,3.62),
        -34.0,39.0,18.0)

func _v41_villa() -> void:
    _v41_closeup(0)

func _v41_town() -> void:
    _v41_closeup(1)

func _v41_metro() -> void:
    _v41_closeup(2)

func _v41_d2() -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(2)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,_v40_height()*0.94,3.62),
        -34.0,54.0,20.0)

func _v41_d4() -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(4)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,0.17,3.62),
        133.0,40.0,18.0)

func _v41_overview() -> void:
    _view_v19(Vector3.ZERO,39.0,44.0,33.0)
