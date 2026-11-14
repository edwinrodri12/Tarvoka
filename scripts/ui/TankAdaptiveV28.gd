extends RefCounted
class_name TarvokaTankAdaptiveV28

# The EXACT G09 V25 from TankWearV25 is the only battle tank identity.
# LOD controls expendable GPU work on that SAME geometry instead of swapping
# to old V10/V6 silhouettes. Nothing moves, resizes or changes materials'
# faction ALBEDO; no FPS promise without real Android profiling.
const Wear = preload("res://scripts/ui/TankWearV25.gd")
const CLOSE := 0
const MEDIUM := 1
const DISTANT := 2
const MEDIUM_ZOOM := 17.5
const DISTANT_ZOOM := 36.0
const MICRO_MEDIUM := 0.065
const MICRO_DISTANT := 0.18
# Reuse simplified shader resources for the full session, preserving the
# actual V25 albedo/edge-wear image and paint textures.
static var _medium_material: Dictionary = {}
static var _far_material: Dictionary = {}

static func tier(camera_size: float, quality_enabled: bool = true) -> int:
    var out := CLOSE
    if camera_size > DISTANT_ZOOM:
        out = DISTANT
    elif camera_size > MEDIUM_ZOOM:
        out = MEDIUM
    # ECO only removes fine rendering work; never selects an older tank.
    return maxi(out,MEDIUM) if not quality_enabled else out

static func _read_meshes(node: Node,into: Array) -> void:
    if node is MeshInstance3D and (node as MeshInstance3D).mesh!=null:
        into.append(node)
    for child in node.get_children():
        _read_meshes(child,into)

static func _critical(part: MeshInstance3D) -> bool:
    # Every original named faction plate and 17 V23+V24 roof/side
    # camouflage plates ALWAYS survives every quality tier.
    return part.name.begins_with("Faccion") or (
        part.has_meta("tarvoka_paint_zone")) or (
        Wear._targets().has(String(part.name)))

static func _cheap_material(source: StandardMaterial3D, far: bool) -> StandardMaterial3D:
    var key: int = source.get_instance_id()
    var pool: Dictionary = _far_material if far else _medium_material
    if pool.has(key):
        return pool[key] as StandardMaterial3D
    var material: StandardMaterial3D = source.duplicate(false) as StandardMaterial3D
    # Preserve authored pigmentation and chip textures exactly. Only expensive
    # micro-normal fetches and, at the greatest distances, roughness fetches
    # are dropped; tiny specular changes cannot replace hull geometry.
    material.normal_enabled = false
    if far:
        material.roughness_texture = null
        material.roughness = 0.89
    pool[key] = material
    return material

static func configure(model: Node3D,camera_size: float,
        selected: bool,quality_enabled: bool) -> Dictionary:
    if model == null or not model.get_meta("tarvoka_mbt_wear_v25",false):
        return {}
    var band: int = tier(camera_size,quality_enabled)
    var tiny_threshold: float = (
        0.0 if band==CLOSE
        else MICRO_MEDIUM if band==MEDIUM
        else MICRO_DISTANT)
    var meshes: Array = []
    _read_meshes(model,meshes)
    var hidden := 0
    var shadow_off := 0
    var simplified := 0
    var persistent := 0
    for entry in meshes:
        var part: MeshInstance3D = entry as MeshInstance3D
        if not part.has_meta("v28_original_visible"):
            part.set_meta("v28_original_visible",part.visible)
            part.set_meta("v28_original_shadow",part.cast_shadow)
            part.set_meta("v28_original_material",part.material_override)
        var bounds: Vector3 = part.mesh.get_aabb().size
        var max_axis: float = maxf(bounds.x,maxf(bounds.y,bounds.z))
        var micro: bool = not _critical(part) and max_axis<=tiny_threshold
        var originally_visible: bool = bool(
            part.get_meta("v28_original_visible",true))
        part.visible = originally_visible and not micro
        if micro and originally_visible:
            hidden += 1
        elif part.visible:
            persistent += 1
        var original_shadow: int = int(part.get_meta("v28_original_shadow"))
        if band==CLOSE and selected:
            part.cast_shadow = original_shadow
        elif band==DISTANT or (
                max_axis<0.45 and not _critical(part)):
            part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        else:
            part.cast_shadow = original_shadow
        if part.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
            shadow_off += 1
        var original_material: Material = part.get_meta(
            "v28_original_material",null) as Material
        # A handful of parts obtain their material through a PrimitiveMesh;
        # never override those so that their colors remain untouched.
        if original_material is StandardMaterial3D:
            if band==CLOSE and selected:
                part.material_override = original_material
            else:
                part.material_override = _cheap_material(
                    original_material as StandardMaterial3D,band==DISTANT)
                simplified += 1
    model.set_meta("v28_visual_tier",band)
    model.set_meta("v28_quality_enabled",quality_enabled)
    model.set_meta("v28_active_micro_hidden",hidden)
    return {
        "tier":band,
        "hidden_micro":hidden,
        "shadow_off":shadow_off,
        "simplified_materials":simplified,
        "remaining_meshes":persistent,
        "source_art_level":25
    }
