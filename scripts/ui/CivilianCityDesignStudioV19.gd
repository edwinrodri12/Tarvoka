extends "res://scripts/ui/CivilianCityDesignStudioV18.gd"
class_name TarvokaCivilianCityDesignStudioV19

# V19 native Godot workshop; the same Cities.build_tactical() as the
# unified EDIFICIOS picker, not a separate sprite or 2D mockup.
var _v19_toolbar: HFlowContainer

func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV19ConjuntoUrbano"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · CIUDADES V19 · COHESION DE CONJUNTO 3D"
    # V8 created an HBoxContainer at child #3. Earlier V14-V18 studio
    # extras cast that child to HFlowContainer and therefore never showed.
    # Add a real responsive toolbar without altering the old camera bar.
    _v19_toolbar=HFlowContainer.new()
    _v19_toolbar.name="V19_CamarasInspeccionConjunto"
    _v19_toolbar.add_theme_constant_override("h_separation",5)
    _v19_toolbar.add_theme_constant_override("v_separation",5)
    layout.add_child(_v19_toolbar)
    layout.move_child(_v19_toolbar,4)
    for data in [
        ["CONJUNTO 360",Callable(self,"_show_full_district")],
        ["PASAJES",Callable(self,"_show_passageways")],
        ["CUBIERTAS",Callable(self,"_show_roof_rhythm")],
        ["PLAZA CIVICA",Callable(self,"_show_civic_square")],
        ["RUINAS",Callable(self,"_show_ruined_district")]
    ]:
        var button:=Button.new()
        button.text=str(data[0])
        button.custom_minimum_size=Vector2(117,34)
        button.pressed.connect(data[1])
        _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V18","DESARROLLO · V19")
        _status.text+=" · remates, pasajes y plaza del conjunto 3D"

func _view_v19(focus: Vector3,angle: float,
        elevation: float,distance: float) -> void:
    _model_focus=focus
    _angle=deg_to_rad(angle)
    _elevation=deg_to_rad(elevation)
    _distance=distance
    _orient_camera()

func _show_full_district() -> void:
    _view_v19(Vector3.ZERO,40.0,42.0,33.0)

func _show_passageways() -> void:
    _view_v19(Vector3(2.47,-1.10,-2.90),32.0,46.0,19.0)

func _show_roof_rhythm() -> void:
    _view_v19(Vector3(0.0,2.45,0.0),42.0,67.0,26.0)

func _show_civic_square() -> void:
    _view_v19(Vector3(0.0,-1.15,2.10),18.0,49.0,18.0)

func _show_ruined_district() -> void:
    _set_damage(4)
    _view_v19(Vector3.ZERO,37.0,36.0,30.0)
