extends RefCounted
class_name TarvokaG11CameraIdentityV28

# V28: camera-dependent, low-energy faction enamel for the EXISTING G11
# tactical paint surfaces. No new nodes, meshes, icons or enemy reveals.
# A distinct material copy per G11 keeps the shared official paint safe.
const FLAG := "tarvoka_g11_v28_camera_identity"
const SOURCE := "tarvoka_g11_v27_tactical_paint_readability"
const NORMAL_KEY := "tarvoka_g11_v28_normal_enamel"
const FAR_KEY := "tarvoka_g11_v28_far_enamel"
const CURRENT_KEY := "tarvoka_g11_v28_active_finish"
const EMISSION_STRENGTH: float = 0.22
const FAR_LEVEL := 8
const NEAR_LEVEL := 10
const PARTS := [
    "G11Mobile_InsigniaFrontal",
    "G11Mobile_PinturaCostado_-1",
    "G11Mobile_PinturaCostado_1",
    "G11Mobile_MarcaModulo"
]

static func _part(model: Node3D,name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func base_material(model: Node3D) -> StandardMaterial3D:
    # The V26 gallery repaints these pieces AFTER the battle is built.
    # Return the unmodified original, not an emission-enhanced finish.
    if model==null:
        return null
    if not model.has_meta(NORMAL_KEY):
        return null
    return model.get_meta(NORMAL_KEY) as StandardMaterial3D

static func _paint_parts(model: Node3D) -> Array[MeshInstance3D]:
    var out: Array[MeshInstance3D]=[]
    if model==null or not bool(model.get_meta(SOURCE,false)):
        return out
    for part_name in PARTS:
        var part := _part(model,str(part_name))
        if part==null or not part.material_override is StandardMaterial3D:
            out.clear()
            return out
        out.append(part)
    return out

static func bind(model: Node3D,level: int = FAR_LEVEL) -> bool:
    if level!=FAR_LEVEL and level!=NEAR_LEVEL:
        return false
    var parts := _paint_parts(model)
    if parts.size()!=PARTS.size():
        return false
    var current := parts[0].material_override as StandardMaterial3D
    var normal := base_material(model)
    var far: StandardMaterial3D=null
    if model!=null and model.has_meta(FAR_KEY):
        far=model.get_meta(FAR_KEY) as StandardMaterial3D
    # On first bind take the factory paint; on rebind take the V26 gallery
    # paint. Neither is ever mutated, which avoids repainting other units.
    if normal==null or far==null or (
            current!=normal and current!=far):
        for part in parts:
            if part.material_override!=current:
                return false
        normal=current
        far=current.duplicate(true) as StandardMaterial3D
        far.emission_enabled=true
        far.emission=current.albedo_color
        far.emission_energy_multiplier=EMISSION_STRENGTH
        model.set_meta(NORMAL_KEY,normal)
        model.set_meta(FAR_KEY,far)
    return set_detail(model,level)

static func set_detail(model: Node3D,level: int) -> bool:
    if level!=FAR_LEVEL and level!=NEAR_LEVEL:
        return false
    var parts := _paint_parts(model)
    if parts.size()!=PARTS.size():
        return false
    var normal := base_material(model)
    var far: StandardMaterial3D=null
    if model!=null and model.has_meta(FAR_KEY):
        far=model.get_meta(FAR_KEY) as StandardMaterial3D
    if normal==null or far==null:
        return false
    var finish: StandardMaterial3D=far if level==FAR_LEVEL else normal
    # Only the existing four approved enamel shapes change material
    # references. No overlays, halos, selection marker or hidden unit.
    for part in parts:
        part.material_override=finish
    model.set_meta(FLAG,true)
    model.set_meta(CURRENT_KEY,level)
    return true
