extends RefCounted
class_name TarvokaTankClayV19

# Non-destructive geometry review in the native Godot / WebGL studio.
# One flat neutral PBR material exposes topology, faceting and silhouettes
# instead of allowing PBR textures/faction stripes to mask modeling faults.
# There is no shader compilation or per-pixel wireframe pass at run time.
const CLAY := Color("#667078")  # Medium-value gray; avoids blown highlights under studio lights.
const RESTORE := "tarvoka_v19_clay_restore"
const EFFECT_NAMES := [
    "HumoGrisMotor","VahoMotor","HumoNegroCritico",
    "HumoElevado","ColumnaHumo","HumoSuperior",
    "FuegoBase","FuegoNucleo",
    "LenguaFuegoIzquierda","LenguaFuegoCentro","LenguaFuegoAlta"
]
static var _shared_clay: StandardMaterial3D

static func _material() -> StandardMaterial3D:
    if _shared_clay == null:
        _shared_clay = StandardMaterial3D.new()
        _shared_clay.albedo_color = CLAY
        _shared_clay.roughness = 0.94
        _shared_clay.metallic = 0.0
        _shared_clay.normal_enabled = false
        _shared_clay.cull_mode = BaseMaterial3D.CULL_DISABLED
        _shared_clay.emission_enabled = false
    return _shared_clay

static func is_enabled(model: Node3D) -> bool:
    return model != null and bool(model.get_meta("tarvoka_v19_clay_enabled",false))

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_resculpt_v18",false):
        return false
    if is_enabled(model)==enabled:
        return true
    if enabled:
        var restored: Array = []
        var count: int = 0
        for node in model.find_children("*","GeometryInstance3D",true,false):
            var geometry: GeometryInstance3D = node as GeometryInstance3D
            if geometry == null:
                continue
            var fx_name: String = str(geometry.name)
            var is_fx: bool = fx_name in EFFECT_NAMES or (
                fx_name.begins_with("G09V17Humo_") or
                fx_name.begins_with("G09V16FuegoLamina_"))
            restored.append([geometry,geometry.material_override,
                geometry.visible])
            if is_fx:
                geometry.visible = false
            else:
                geometry.material_override = _material()
            count+=1
        model.set_meta(RESTORE,restored)
        model.set_meta("tarvoka_v19_clay_count",count)
        model.set_meta("tarvoka_v19_clay_enabled",true)
    else:
        var restored: Array = model.get_meta(RESTORE,[])
        for entry in restored:
            var node: GeometryInstance3D = entry[0] as GeometryInstance3D
            if node == null or not is_instance_valid(node):
                continue
            node.material_override = entry[1] as Material
            # FX alpha cards remain hidden in clay but are restored exactly
            # on return to the original eight-faction artwork.
            node.visible = entry[2]
        model.remove_meta(RESTORE)
        model.set_meta("tarvoka_v19_clay_enabled",false)
    return true
