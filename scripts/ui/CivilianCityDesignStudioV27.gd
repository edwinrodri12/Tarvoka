extends "res://scripts/ui/CivilianCityDesignStudioV26.gd"
class_name TarvokaCivilianCityDesignStudioV27

# V27 — manual architectural inspection of real native 3D streetscape.
# No separate proxy scene, scripted gameplay or testing of unfinished art.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV27FachadaAceraPlaza"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V27 · FACHADAS Y ESPACIO URBANO"
    if _v19_toolbar!=null:
        for data in [
            ["PORTAL VILLA",Callable(self,"_v27_villa_portal")],
            ["ACCESO CIUDAD",Callable(self,"_v27_town_entry")],
            ["TIENDA METRÓPOLI",Callable(self,"_v27_metro_store")],
            ["PASAJES LATERALES",Callable(self,"_v27_passage")],
            ["PLAZA CÍVICA",Callable(self,"_v27_square")],
            ["D2 ACERA ROTA",Callable(self,"_v27_d2_pavement")],
            ["D4 ACCESOS ROTOS",Callable(self,"_v27_d4_ruins")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(148,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V26","DESARROLLO · V27")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d pavimentos armonizados" % [
                int(_model.get_meta("city_v27_pavement_reconciled",0))]

func _v27_select_level(index: int) -> void:
    if _tier==null or _damage==null:
        return
    _tier.select(index)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,-0.92,-1.88),-30.0,37.0,17.7)

func _v27_villa_portal() -> void:
    _v27_select_level(0)

func _v27_town_entry() -> void:
    _v27_select_level(1)

func _v27_metro_store() -> void:
    _v27_select_level(2)

func _v27_passage() -> void:
    _view_v19(Vector3(2.47,-1.20,1.42),-51.0,46.0,18.2)

func _v27_square() -> void:
    _view_v19(Vector3(0.0,-1.20,2.86),30.0,51.0,19.2)

func _v27_d2_pavement() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,-1.25,1.56),-39.0,44.0,17.7)

func _v27_d4_ruins() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-1.25,-1.48),142.0,40.0,18.0)
