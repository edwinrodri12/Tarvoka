extends RefCounted
class_name TarvokaAttackHelicopterFactionV14

# Hero-only HAT-29 identity coat. Preserve V13 destruction geometry, rotors,
# glass, weapons, and the Android battle LOD <= 10.
const FLAG := "tarvoka_a01_hat29_faction_v14"
const V13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const PAINTED := [
    ["A01_V2_Casco12CarasCerrado",0.79],
    ["A01V4_BlindajeLateral_-1",0.84],
    ["A01V4_BlindajeLateral_1",0.84],
    ["A01V12_MejillaBlindada_-1",0.79],
    ["A01V12_MejillaBlindada_1",0.79],
    ["A01_V2_PuertaCabina_-1",0.87],
    ["A01_V2_PuertaCabina_1",0.87],
    ["A01_VigaColaSellada",0.87],
    ["A01_AletaVertical",0.83],
    ["A01_EstabilizadorCola",0.63],
    ["A01_V2_BandaIdentificacionSuperior",0.98],
]

# The secondary aircraft finish deliberately follows the dual-tone colors
# from the official HAT-29 reference: the faction hue remains dominant.
const SECONDARY := [
    "#ffc83e", # Alianza Norte: blue + military gold
    "#eae0d9", # Pacto Escarlata: red + warm ceramic
    "#bcdf64", # Unión Verde: green + lime
    "#f6e1a6", # Confederación Solar: gold + light champagne
    "#e9c3ff", # Sindicato Violeta: violet + pale lilac
    "#ffd097", # Legión Ámbar: amber + pale bronze
    "#b4eef2", # Dominio Turquesa: teal + ice
    "#d7e1e9", # Orden Ónix: black + steel
]
const TWO_TONE := [
    ["A01V4_MotorCarenado_-1",0.91],
    ["A01V4_MotorCarenado_1",0.91],
    ["A01_AlaRefuerzo_-1",0.80],
    ["A01_AlaRefuerzo_1",0.80],
    ["A01_AletaVertical",0.68],
]

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func _enamel(mesh: MeshInstance3D,color: Color) -> void:
    var old: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    var coat: StandardMaterial3D=(old.duplicate(true) as StandardMaterial3D
        if old!=null else StandardMaterial3D.new())
    coat.albedo_color=color
    coat.metallic=0.24
    coat.roughness=0.55
    mesh.material_override=coat

static func apply(model: Node3D,faction: Color,faction_index: int=-1) -> bool:
    if not V13.has_model(model):
        return false
    if has_model(model):
        return true
    var count: int=0
    for entry in PAINTED:
        var shape: MeshInstance3D=model.find_child(str(entry[0]),true,false) as MeshInstance3D
        if shape==null:
            continue
        var strength: float=float(entry[1])
        # Faction is vivid, while some grey alloy and amber details remain
        # exposed for readability; the HAT-29 is not a monochrome toy.
        var color: Color=Color("#32444e").lerp(faction,strength)
        _enamel(shape,color)
        count+=1
    # Preserve the primary faction hull plus a very visible contrast
    # across motor pods, wings and tail: not the all-monochrome V14 test coat.
    var second: Color=Color(SECONDARY[faction_index]) if (
        faction_index>=0 and faction_index<SECONDARY.size()) else Color("#e3c77d")
    for entry in TWO_TONE:
        var shape: MeshInstance3D=model.find_child(str(entry[0]),true,false) as MeshInstance3D
        if shape==null:
            continue
        _enamel(shape,Color("#43515d").lerp(second,float(entry[1])))
        count+=1
    if count<11:
        return false
    model.set_meta(FLAG,true)
    model.set_meta("a01_v14_faction_painted_count",count)
    model.set_meta("a01_v14_faction_color",faction)
    model.set_meta("a01_v14_secondary_color",second)
    return true
