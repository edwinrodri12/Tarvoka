extends RefCounted
class_name TarvokaAPCWeatherFinishV22

# Bastion V22: reversible weather-dependent PBR on actual sculpted meshes.
# Explicitly presentation-only: does NOT alter gameplay weather, HP, fuel,
# physics, pathfinding, unit speed, faction traits or terrain effects.
const V21 = preload("res://scripts/ui/APCMaterialFinishV21.gd")
const FLAG := "tarvoka_apc_weather_v22"
const ROOT := "P06V22_MaterialesClimaticos"
const MODE := "tarvoka_apc_v22_weather"
const SHOW := "tarvoka_apc_v22_visible"
const STAGE := "tarvoka_apc_v22_stage"
const BASE := "tarvoka_p06_v22_base_material"
const OVERLAY := "tarvoka_p06_v22_overlay_material"
const WEATHERS := ["clear","rain","snow"]
const COATING_NAMES := [
    "P06V18_PanelPuente_","P06V19_ChaflanSuperior_",
    "P06V20_RematePintado_","P06V17_CuartonTrasero_",
    "P06V16_BordeTechoCostado_"
]
const RUBBER_NAMES := ["P06V19_LabioCurvo_"]
const STEEL_NAMES := [
    "P06V20_CordonSuperior_","P06V20_CordonTalón_",
    "P06V20_PernoFaldon_","P06V20_PernoArco_",
    "P06V19_CartelaSuspension_"
]
const FRACTURE_NAMES := [
    "P06V20_SoldaduraAbierta","P06V20_AristaMetalExpuesta",
    "P06V20_DesgarroTrasero","P06V20_BordeArcoFrontalPartido",
    "P06V19_CantoneraCizallada","P06V19_ArcoFrontalAplastado",
    "P06V20_CordonSeparadoRuina","P06V19_LaminaColapsada"
]

static func _matches(name: String, patterns: Array) -> bool:
    for item in patterns:
        if name.begins_with(item):
            return true
    return false

static func _kind(name: String) -> String:
    if _matches(name,COATING_NAMES):
        return "paint"
    if _matches(name,RUBBER_NAMES):
        return "rubber"
    if _matches(name,STEEL_NAMES):
        return "steel"
    if name in FRACTURE_NAMES:
        return "fracture"
    return ""

static func _restore(mesh: MeshInstance3D) -> void:
    if not mesh.has_meta(OVERLAY):
        return
    if mesh.material_override == mesh.get_meta(OVERLAY):
        mesh.material_override = mesh.get_meta(BASE) as Material
    mesh.remove_meta(OVERLAY)
    mesh.remove_meta(BASE)

static func _weathered(source: StandardMaterial3D, mode: String,
        kind: String, stage: int) -> StandardMaterial3D:
    var coating: StandardMaterial3D = source.duplicate() as StandardMaterial3D
    # Use the existing V21 triplanar grain/albedo and roughness maps.
    # No layer may erase the source faction color or damage texture.
    if mode == "rain":
        if kind == "paint":
            coating.albedo_color=source.albedo_color.darkened(0.085)
            coating.roughness=maxf(0.30,source.roughness*0.54)
            coating.specular=0.73
        elif kind == "steel":
            coating.roughness=maxf(0.20,source.roughness*0.59)
            coating.specular=0.78
        elif kind == "rubber":
            coating.albedo_color=source.albedo_color.darkened(0.055)
            coating.roughness=maxf(0.69,source.roughness*0.82)
        else:
            coating.roughness=maxf(0.34,source.roughness*0.66)
    elif mode == "snow":
        if kind == "paint":
            var frost: float=0.14 if stage>=3 else 0.26
            coating.albedo_color=source.albedo_color.lerp(
                Color("#d8e3eb"),frost)
            coating.roughness=minf(0.96,source.roughness+0.13)
            coating.specular=0.37
        elif kind == "steel":
            coating.albedo_color=source.albedo_color.lerp(
                Color("#ced9e1"),0.17)
            coating.roughness=minf(0.85,source.roughness+0.14)
        elif kind == "rubber":
            coating.albedo_color=source.albedo_color.lerp(
                Color("#9ca9b3"),0.10)
            coating.roughness=0.96
        else:
            # Exposed burn and rubble still read as damage in snow.
            coating.albedo_color=source.albedo_color.lerp(
                Color("#d6dde1"),0.07)
            coating.roughness=maxf(source.roughness,0.87)
    return coating

static func _refresh(model: Node3D) -> void:
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var mode: String=str(model.get_meta(MODE,"clear"))
    var stage: int=int(model.get_meta(STAGE,0))
    var nodes: Array[Node]=model.find_children(
        "*","MeshInstance3D",true,false)
    for node in nodes:
        var mesh: MeshInstance3D=node as MeshInstance3D
        if mesh==null:
            continue
        var kind: String=_kind(mesh.name)
        if kind.is_empty():
            continue
        if not enabled or mode=="clear":
            _restore(mesh)
            continue
        # On damage changes V21 has already assigned the correct source
        # material. On weather-only changes recover our previously saved
        # source instead of weathering the weathered material a second time.
        var source: Material=mesh.material_override
        if mesh.has_meta(OVERLAY) and source==mesh.get_meta(OVERLAY):
            source=mesh.get_meta(BASE) as Material
        if not source is StandardMaterial3D:
            _restore(mesh)
            continue
        var finish: StandardMaterial3D=_weathered(
            source as StandardMaterial3D,mode,kind,stage)
        mesh.set_meta(BASE,source)
        mesh.set_meta(OVERLAY,finish)
        mesh.material_override=finish

static func apply(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(V21.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var root_node:=Node3D.new()
    root_node.name=ROOT
    model.add_child(root_node)
    model.set_meta(FLAG,true)
    model.set_meta(MODE,"clear")
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return true

static func set_weather(model: Node3D, mode: String) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not mode in WEATHERS:
        return false
    model.set_meta(MODE,mode)
    _refresh(model)
    return true

static func set_stage(model: Node3D, stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(STAGE,clampi(stage,0,4))
    _refresh(model)
    return true

static func set_enabled(model: Node3D, enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    _refresh(model)
    return true
