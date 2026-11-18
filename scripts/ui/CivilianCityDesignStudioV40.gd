extends "res://scripts/ui/CivilianCityDesignStudioV39.gd"
class_name TarvokaCivilianCityDesignStudioV40

# V40: final-art inspection, not final approval. Native Godot geometry
# from the shared builder, identical ground-level camera angle for
# all three civilization tiers, plus roof-wall seam and D4 ruin views.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV40RevisionArtistica"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null and layout.get_child_count()>0:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V40 · REVISIÓN ARTÍSTICA"
    if _v19_toolbar!=null:
        for item in [
            ["V40 VILLA COMPLETA",Callable(self,"_v40_villa")],
            ["V40 CIUDAD COMPLETA",Callable(self,"_v40_town")],
            ["V40 METRÓPOLI COMPLETA",Callable(self,"_v40_metro")],
            ["V40 CONTACTO TECHO-MURO",Callable(self,"_v40_roof_wall")],
            ["V40 RUINAS D4",Callable(self,"_v40_d4")],
            ["V40 VISTA DEL DISTRITO",Callable(self,"_v40_overview")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(165,34)
            button.pressed.connect(item[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V39","DESARROLLO · V40")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d/%d tejados asentados · %d juntas pendientes" % [
                int(_model.get_meta("city_v40_roofs_seated",0)),
                int(_model.get_meta("city_v40_roofs_audited",0)),
                int(_model.get_meta("city_v40_unresolved_roof_gaps",0))]

func _v40_height() -> float:
    var tier: int=0 if _tier==null else _tier.selected
    return 2.31 if tier==0 else 6.51 if tier==1 else 10.71

func _v40_compare(tier: int) -> void:
    if _tier==null or _damage==null or _lod==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    # Match angle/elevation and scale across all three urban styles.
    _view_v19(Vector3(0.0,_v40_height()*0.36,0.0),
        38.0,45.0,38.0)

func _v40_villa() -> void:
    _v40_compare(0)

func _v40_town() -> void:
    _v40_compare(1)

func _v40_metro() -> void:
    _v40_compare(2)

func _v40_roof_wall() -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(0)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,_v40_height()+0.05,3.62),
        -35.0,34.0,16.4)

func _v40_d4() -> void:
    if _damage==null or _lod==null:
        return
    _damage.select(4)
    _lod.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,0.16,3.62),
        132.0,40.0,18.2)

func _v40_overview() -> void:
    _view_v19(Vector3.ZERO,39.0,44.0,33.0)
