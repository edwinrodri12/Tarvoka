extends "res://scripts/ui/CivilianCityDesignStudioV14.gd"
class_name TarvokaCivilianCityDesignStudioV15

# Native 3D ART preview: tier recognition, not game balance or benchmark.
# Switch among the SAME real city model in 3 tiers and 5 damage stages.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesIdentidadV15"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · CIUDADES V15 · VILLA / CIUDAD / METRÓPOLI"
    var controls: HFlowContainer=layout.get_child(3) as HFlowContainer
    if controls!=null:
        for item in [
            ["VILLA",Callable(self,"_show_villa")],
            ["CIUDAD",Callable(self,"_show_town")],
            ["METRÓPOLI",Callable(self,"_show_metropolis")],
            ["SILUETA TÁCTICA",Callable(self,"_compare_tactical")],
            ["DETALLE 3D",Callable(self,"_compare_close")],
            ["D4 IDENTIDAD",Callable(self,"_compare_ruins")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(113,34)
            button.pressed.connect(item[1])
            controls.add_child(button)
    # An architectural identity pass deserves an initial wide view;
    # preserve the user's available tier, faction and damage selectors.
    _reset_focus()
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _model!=null and is_instance_valid(_model):
        _model.name="CiudadCivilV15_Arte3DReal"
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V14","DESARROLLO · V15")
        var identity: String="Teja terracota · estructura de madera"
        if _tier!=null and _tier.selected==1:
            identity="Cornisa de piedra · ladrillo · mampostería"
        elif _tier!=null and _tier.selected==2:
            identity="Corona escalonada · vidrio · aluminio"
        _status.text+=" · "+identity

func _choose_tier(index: int) -> void:
    if _tier==null:
        return
    # Keep current faction, damage level and camera while switching
    # architecture. The model is rebuilt, not a swapped billboard.
    _tier.select(index)
    _rebuild()

func _show_villa() -> void:
    _choose_tier(0)

func _show_town() -> void:
    _choose_tier(1)

func _show_metropolis() -> void:
    _choose_tier(2)

func _compare_tactical() -> void:
    if _lod!=null:
        _lod.select(2)
    _model_focus=Vector3.ZERO
    _angle=deg_to_rad(38.0)
    _elevation=deg_to_rad(43.0)
    _distance=38.0
    _rebuild()

func _compare_close() -> void:
    if _lod!=null:
        _lod.select(0)
    _model_focus=Vector3.ZERO
    _angle=deg_to_rad(34.0)
    _elevation=deg_to_rad(34.0)
    _distance=24.0
    _rebuild()

func _compare_ruins() -> void:
    if _damage!=null:
        _damage.select(4)
    _compare_tactical()
