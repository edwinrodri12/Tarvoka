extends "res://scripts/ui/CivilianCityDesignStudioV24.gd"
class_name TarvokaCivilianCityDesignStudioV25

# Native Godot 4.3 architecture workshop: material coherence on actual
# Cities.build_tactical(), not proxy screenshots or separate meshes.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV25ContinuidadMaterial"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V25 · CONTINUIDAD DE ACABADOS"
    if _v19_toolbar!=null:
        for data in [
            ["VILLA CERÁMICA",Callable(self,"_v25_villa_seams")],
            ["CIUDAD PIEDRA",Callable(self,"_v25_town_seams")],
            ["METRÓPOLI METAL",Callable(self,"_v25_metro_seams")],
            ["D2 ROTURA",Callable(self,"_v25_roof_break")],
            ["D3 FORJADO",Callable(self,"_v25_floor_cut")],
            ["D4 CIMIENTO",Callable(self,"_v25_foundation_cut")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(140,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V24","DESARROLLO · V25")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d juntas retocadas" % [
                int(_model.get_meta("city_v25_material_reconciled",0))]

func _v25_tier(tier: int) -> void:
    if _tier==null or _damage==null:
        return
    _tier.select(tier)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,1.75,3.62),36.0,49.0,19.0)

func _v25_villa_seams() -> void:
    _v25_tier(0)

func _v25_town_seams() -> void:
    _v25_tier(1)

func _v25_metro_seams() -> void:
    _v25_tier(2)

func _v25_roof_break() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,2.20,3.62),-37.0,56.0,17.5)

func _v25_floor_cut() -> void:
    _set_damage(3)
    _view_v19(Vector3(4.63,-2.75,3.62),138.0,51.0,17.5)

func _v25_foundation_cut() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-3.05,3.62),-53.0,44.0,16.3)
