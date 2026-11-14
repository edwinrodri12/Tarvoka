extends RefCounted
class_name TarvokaTankTacticalV24

# G09 V24: faction ID on six ORIGINAL top-facing armor panels.
# The V23 side markings work at low camera elevations; these subtle roof
# panels stay in view at the higher tactical camera and at smaller zoom.
# Existing Godot meshes are only repainted: ZERO new geometry/draw calls.
# The V10 default Android tank is unaffected (opt-in art_level >= 24).
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V24IdentificacionVistaTactica"
const BASE := Color("#526670")
const TOP_PAINT_COUNT := 6

static func _targets() -> Array:
    var targets: Array = []
    for side in [-1,1]:
        # Turret upper cheek, chassis upper shoulder and rear service deck.
        # Deliberately keep the main center roof, hatches and engine grilles
        # as neutral steel, so this does not become a toy-colored tank.
        targets.append(["CubiertaCompuestaFrontalG09_%s" % side,0.72])
        targets.append(["G09V14LomoBlindadoCentral_%s" % side,0.62])
        targets.append(["G09V14HombroMotorPosterior_%s" % side,0.40])
    return targets

static func _paint(tint: Color,blend: float) -> StandardMaterial3D:
    var pigment: Color = BASE.lerp(tint,blend)
    var enamel: StandardMaterial3D = Hero._army_material(pigment,true)
    enamel.roughness = 0.86
    enamel.metallic = 0.12
    enamel.normal_scale = 0.21
    enamel.emission_enabled = false
    return enamel

static func apply(model: Node3D,tint: Color) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_faction_v23",false):
        return false
    if model.get_meta("tarvoka_mbt_tactical_v24",false):
        return false
    var list: Array = _targets()
    if list.size()!=TOP_PAINT_COUNT:
        return false
    for row in list:
        var panel: MeshInstance3D = model.find_child(
            str(row[0]),true,false) as MeshInstance3D
        if panel==null or panel.mesh==null:
            return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_tactical_v24",true)
    var painted: int = recolor(model,tint)
    model.set_meta("tarvoka_mbt_tactical_v24_roof_count",painted)
    return painted==TOP_PAINT_COUNT

static func recolor(model: Node3D,tint: Color) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_tactical_v24",false):
        return 0
    var changed := 0
    # Recompute from fixed neutral steel after each faction change to avoid
    # compounding the palette; each vehicle owns its own material.
    for row in _targets():
        var panel: MeshInstance3D = model.find_child(
            str(row[0]),true,false) as MeshInstance3D
        if panel==null:
            continue
        panel.material_override = _paint(tint,float(row[1]))
        changed += 1
    return changed
