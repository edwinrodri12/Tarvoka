extends RefCounted
class_name TarvokaWeatherCoating3D

# Model-level, reversible weather finish. Never mutates the source Mesh or
# shared PBR materials, does not affect battle rules, HP, animations or saves.
# Attach small snow sheets to EACH source mesh in local space: turret rotation,
# barrel elevation and animated units carry their own snow with them.
const MODES := ["clear","rain","snow"]
const COAT_TAG := "tarvoka_weather_v1"
const SOURCE_TAG := "tarvoka_weather_source"
const WET_TAG := "tarvoka_weather_wet"
const SNOW_NODE := "ClimaUniversal_CapaNieve"
const MAX_SNOW_NODES := 18
const MAX_SNOW_TRIANGLES := 420
const MAX_ECO_SNOW_NODES := 5
const MAX_ECO_SNOW_TRIANGLES := 65

static func _protected(shape: MeshInstance3D, root: Node3D,
        weather: String) -> bool:
    var node: Node = shape
    while node != null and node != root:
        if node.has_meta("tarvoka_weather_protect") or \
                node.has_meta("tarvoka_weather_v1"):
            return true
        # Wet paint still keeps the original faction albedo, but a white
        # snow polygon must never cover a flag, crest or colored armor plate.
        if weather == "snow" and (node.has_meta("tarvoka_faction_panel") or \
                node.has_meta("tarvoka_paint_zone")):
            return true
        var label: String = node.name.to_lower()
        for word in ["pantalla","vidrio","cristal","ventana","luz_","solar"]:
            if label.contains(word):
                return true
        if weather == "snow":
            for word in ["faccion","insignia","escudo","emblema","logo",
                    "h_raya","h_travesano","letrero","camuflaje"]:
                if label.contains(word):
                    return true
        node = node.get_parent()
    return false

static func _actually_visible(shape: MeshInstance3D,root: Node3D) -> bool:
    var node: Node = shape
    while node != null and node != root:
        if node is Node3D and not (node as Node3D).visible:
            return false
        node = node.get_parent()
    return true

static func _walk(root: Node, out: Array[MeshInstance3D]) -> void:
    for child in root.get_children():
        if child is MeshInstance3D and not child.has_meta(COAT_TAG):
            out.append(child as MeshInstance3D)
        _walk(child,out)

static func _wet(material: StandardMaterial3D, intensity: float) -> StandardMaterial3D:
    # Preserve maps (albedo, normal, roughness, scratches and faction paint).
    # Never replace the underlying shader with a flat colored transparent coat.
    var copy: StandardMaterial3D = material.duplicate(true) as StandardMaterial3D
    copy.roughness = maxf(0.14,lerpf(material.roughness,
        minf(material.roughness,0.19),intensity*0.82))
    copy.metallic = material.metallic
    copy.metallic_specular = maxf(material.metallic_specular,
        0.67*intensity)
    return copy

static func _restore_materials(shape: MeshInstance3D) -> void:
    if not shape.has_meta(SOURCE_TAG):
        return
    var original: Dictionary = shape.get_meta(SOURCE_TAG)
    var applied: Dictionary = shape.get_meta(WET_TAG,{})
    # A faction-repaint operation may have replaced this material while rain
    # was active. Never restore the stale colour over the new faction paint.
    if shape.material_override == applied.get("override",null):
        shape.material_override = original.get("override",null)
    var originals: Array = original.get("surfaces",[])
    var wet_surfaces: Array = applied.get("surfaces",[])
    for i in range(mini(originals.size(),wet_surfaces.size())):
        if shape.get_surface_override_material(i) == wet_surfaces[i]:
            shape.set_surface_override_material(i,originals[i])
    shape.remove_meta(SOURCE_TAG)
    shape.remove_meta(WET_TAG)

static func _wet_shape(shape: MeshInstance3D, intensity: float) -> bool:
    if shape.mesh == null:
        return false
    # Multiple differently painted surfaces keep independent roughness/maps.
    var originals: Array = []
    var painted: Array = []
    var original_override: Material = shape.material_override
    var wet_override: Material = null
    for i in range(shape.mesh.get_surface_count()):
        originals.append(shape.get_surface_override_material(i))
    if original_override is StandardMaterial3D:
        wet_override = _wet(original_override as StandardMaterial3D,intensity)
        shape.material_override = wet_override
    elif original_override == null:
        for i in range(shape.mesh.get_surface_count()):
            var active: Material = shape.get_active_material(i)
            var copy: Material = _wet(active as StandardMaterial3D,intensity) \
                if active is StandardMaterial3D else null
            painted.append(copy)
            if copy != null:
                shape.set_surface_override_material(i,copy)
    if wet_override == null and painted.all(func(item): return item == null):
        return false
    shape.set_meta(SOURCE_TAG,{"override":original_override,"surfaces":originals})
    shape.set_meta(WET_TAG,{"override":wet_override,"surfaces":painted})
    return true

static func _priority(shape: MeshInstance3D) -> int:
    var name: String = shape.name.to_lower()
    for word in ["techo","cubierta","coronamiento","torreta",
            "casco","blindaje","chasis","hull","roof","turret"]:
        if name.contains(word):
            return 0
    for word in ["bloque","aleta","ala","carroceria","pared","plataforma"]:
        if name.contains(word):
            return 1
    return 2

static func _snow_geometry(shape: MeshInstance3D, max_triangles: int,
        salt: int) -> Dictionary:
    if shape.mesh == null or max_triangles <= 0:
        return {"mesh":null,"triangles":0}
    # Mesh.get_faces() handles authored ArrayMeshes AND primitive BoxMesh/
    # CylinderMesh. The vertex normals are measured in mesh-local space.
    var faces: PackedVector3Array = shape.mesh.get_faces()
    if faces.size() < 3:
        return {"mesh":null,"triangles":0}
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count := 0
    var total_faces: int = int(faces.size()/3)
    var stride: int = maxi(1,ceili(float(total_faces)/float(max_triangles)))
    for index in range(0,total_faces,stride):
        if count >= max_triangles:
            break
        var a: Vector3 = faces[index*3]
        var b: Vector3 = faces[index*3+1]
        var c: Vector3 = faces[index*3+2]
        var n: Vector3 = (b-a).cross(c-a)
        if n.length_squared() < 0.002:
            continue
        n = n.normalized()
        if n.y < 0.70:
            continue
        # Deterministic patchy cover, not a pristine white reskin.
        var seed: int = posmod(index*97+salt*31,23)
        if seed in [1,7,16,21]:
            continue
        var center: Vector3 = (a+b+c)/3.0
        var size: float = 0.77 + 0.10*float(seed%3)
        var lift: Vector3 = n*0.013
        var tint: Color = Color("#DFE9ED") if seed%4!=0 else Color("#F4F8FA")
        for pos in [a,b,c]:
            tool.set_color(tint)
            tool.add_vertex(center+(pos-center)*size+lift)
        count += 1
    if count == 0:
        return {"mesh":null,"triangles":0}
    tool.generate_normals()
    return {"mesh":tool.commit(),"triangles":count}

static func _snow(shape: MeshInstance3D, triangle_limit: int,
        salt: int) -> int:
    var result: Dictionary = _snow_geometry(shape,triangle_limit,salt)
    if int(result["triangles"]) <= 0:
        return 0
    var cover := MeshInstance3D.new()
    cover.name = SNOW_NODE
    cover.mesh = result["mesh"]
    var finish := StandardMaterial3D.new()
    finish.vertex_color_use_as_albedo = true
    finish.roughness = 0.92
    finish.metallic = 0.0
    finish.cull_mode = BaseMaterial3D.CULL_DISABLED
    cover.material_override = finish
    cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    cover.set_meta(COAT_TAG,true)
    cover.set_meta("visual_only",true)
    # The patch follows the mesh's LOCAL coordinates even under articulated
    # parents. No world-space offsets that would freeze the G09 turret.
    shape.add_child(cover)
    return int(result["triangles"])

static func clear(model: Node3D) -> void:
    if model == null:
        return
    var shapes: Array[MeshInstance3D] = []
    _walk(model,shapes)
    for shape in shapes:
        _restore_materials(shape)
        for child in shape.get_children():
            if child.has_meta(COAT_TAG):
                shape.remove_child(child)
                child.free()
    model.set_meta("weather_coating",{"mode":"clear","wet":0,
        "snow_nodes":0,"snow_triangles":0,"protected":0,"economy":false})

static func apply(model: Node3D, weather: String, economy: bool = false,
        intensity: float = 1.0) -> Dictionary:
    if model == null or weather not in MODES:
        return {"valid":false}
    clear(model)
    var result := {"valid":true,"mode":weather,"wet":0,
        "snow_nodes":0,"snow_triangles":0,"protected":0,"economy":economy}
    if weather == "clear":
        model.set_meta("weather_coating",result)
        return result
    var shapes: Array[MeshInstance3D] = []
    _walk(model,shapes)
    var candidates: Array[MeshInstance3D] = []
    for shape in shapes:
        if not _actually_visible(shape,model) or _protected(shape,model,weather):
            result["protected"] += 1
            continue
        if weather == "rain":
            if _wet_shape(shape,clampf(intensity,0.0,1.0)):
                result["wet"] += 1
        elif shape.mesh != null:
            candidates.append(shape)
    if weather == "snow":
        # Process visually important exposed armor/roof volumes first.
        # Deterministic ordering, cap both draw calls and triangle count.
        candidates.sort_custom(func(a,b): return _priority(a) < _priority(b))
        var node_limit: int = MAX_ECO_SNOW_NODES if economy else MAX_SNOW_NODES
        var total_limit: int = MAX_ECO_SNOW_TRIANGLES if economy else MAX_SNOW_TRIANGLES
        for shape in candidates:
            if int(result["snow_nodes"]) >= node_limit or \
                    int(result["snow_triangles"]) >= total_limit:
                break
            var triangles: int = _snow(shape,mini(32,
                total_limit-int(result["snow_triangles"])),shape.name.hash())
            if triangles > 0:
                result["snow_nodes"] += 1
                result["snow_triangles"] += triangles
    model.set_meta("weather_coating",result)
    return result
