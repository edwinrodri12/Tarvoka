extends SceneTree

# Blender-ready glTF of real V10 material-junction HQ geometry. This is editable artwork,
# not a screenshot or a replacement for the in-game WebGL model.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const TARGET := "res://artifacts/TARVOKA_CuartelGeneral_V10_Nivel3_Editable.glb"

func _initialize() -> void:
    call_deferred("_run")

static func _category(n: Node) -> String:
    var node: Node = n
    while node != null:
        var label: String = str(node.name)
        if label in ["Helipuerto","AproximacionHelipuertoV4",
                "PatioMilitar","PatioOperativoV3",
                "BalizamientoHelipuertoV7"]:
            return "Helipad_Logistics"
        if label in ["RadarPremium3D","ArmazonDeRadarV4",
                "TorreDeRedesTrianguladaV4","BanderaPrincipalV4",
                "TorreDeComunicaciones","CoronaDeComandoV3",
                "MecanismoDeRadarArticuladoV7"]:
            return "Radar_Communications"
        if label.begins_with("Restos") or label.begins_with("Impactos") or label.begins_with("Danos") or label.begins_with("Fractura"):
            return "Damage_Props"
        if node.has_meta("tarvoka_faction_panel"):
            return "Faction_Panels"
        node = node.get_parent()
    return "Building_Architecture"

static func _shared(mat: Material,cache: Dictionary) -> Material:
    if not (mat is StandardMaterial3D):
        return mat
    var m: StandardMaterial3D = mat as StandardMaterial3D
    var id: String = str([
        m.albedo_color,m.metallic,m.roughness,m.emission_enabled,
        m.emission,m.emission_energy_multiplier,m.cull_mode,
        m.albedo_texture.get_instance_id() if m.albedo_texture != null else -1
    ])
    if not cache.has(id):
        cache[id] = mat
    return cache[id]

func _run() -> void:
    var source: Node3D = HQ.build(3,0,"operativo",true,true,true,true,true,true,true)
    assert(source != null and source.get_meta("tarvoka_hq_visual_v10",false))
    root.add_child(source)
    HQ.set_render_detail(source,true)
    var artist := Node3D.new()
    artist.name = "TARVOKA_CUARTEL_GENERAL_V10_NIVEL3_EDITABLE"
    root.add_child(artist)
    var groups: Dictionary = {}
    for label in ["Building_Architecture","Faction_Panels",
            "Radar_Communications","Helipad_Logistics","Damage_Props"]:
        var node := Node3D.new()
        node.name = label
        artist.add_child(node)
        groups[label] = node
    var mats: Dictionary = {}
    var meshes: int = 0
    var batches: int = 0
    for node in source.find_children("*","MeshInstance3D",true,false):
        var mesh: MeshInstance3D = node as MeshInstance3D
        if not mesh.is_visible_in_tree() or mesh.mesh == null:
            continue
        var label: String = "Faction_Panels" if mesh.has_meta(
            "tarvoka_faction_panel") else _category(mesh)
        var target: Node3D = groups[label] as Node3D
        var clone := MeshInstance3D.new()
        clone.name = str(mesh.name)
        clone.mesh = mesh.mesh
        clone.material_override = _shared(mesh.material_override,mats)
        clone.transform = target.global_transform.affine_inverse()*mesh.global_transform
        target.add_child(clone)
        meshes += 1
    for node in source.find_children("*","MultiMeshInstance3D",true,false):
        var batch: MultiMeshInstance3D = node as MultiMeshInstance3D
        if not batch.is_visible_in_tree() or batch.multimesh == null:
            continue
        var target: Node3D = groups[_category(batch)] as Node3D
        for i in range(batch.multimesh.instance_count):
            var clone := MeshInstance3D.new()
            clone.name = "%s_%03d" % [batch.name,i]
            clone.mesh = batch.multimesh.mesh
            clone.material_override = _shared(batch.material_override,mats)
            clone.transform = target.global_transform.affine_inverse()*(
                batch.global_transform*batch.multimesh.get_instance_transform(i))
            target.add_child(clone)
            batches += 1
    assert(meshes > 300)
    assert(batches >= 40)
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var status: Error = document.append_from_scene(artist,state,0)
    if status != OK:
        push_error("V9 HQ geometry cannot serialize to glTF: %d" % status)
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    status = document.write_to_filesystem(state,ProjectSettings.globalize_path(TARGET))
    if status != OK:
        push_error("V10 HQ GLB failed to write: %d" % status)
        quit(3)
        return
    var file := FileAccess.open(TARGET,FileAccess.READ)
    assert(file != null and file.get_length() > 35000)
    var bytes: int = file.get_length()
    file.close()
    print("PASS HQ V10 GLB export: %d visible real 3D meshes, %d editable bolt instances, %d shared materials, %d bytes" % [
        meshes,batches,mats.size(),bytes])
    artist.queue_free()
    source.queue_free()
    quit(0)
