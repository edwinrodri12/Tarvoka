extends SceneTree

# Export the exact current in-game G09 geometry into a truly editable glTF 2.0
# asset for Blender, Godot and independent 3D validation. Copies only VISIBLE
# model meshes. MultiMesh/track instances are baked to individual glTF nodes
# in this authoring export, while the runtime game keeps mobile batching.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const TARGET := "res://artifacts/TARVOKA_G09_V18_Escultura_Editable.glb"

func _initialize() -> void:
    call_deferred("_run")

static func _group_for(node: Node) -> String:
    var current: Node = node
    while current != null:
        if str(current.name) == "ElevacionCanon":
            return "Cannon_Animated"
        if str(current.name) == "TorretaGiratoria":
            return "Turret_Rotating"
        if str(current.name) == "ChasisBlindado":
            return "Chassis_Tracks"
        current = current.get_parent()
    return "Chassis_Tracks"

static func _texture_id(tex: Texture2D) -> int:
    return tex.get_instance_id() if tex != null else -1

static func _shared_export_material(mat: Material, cache: Dictionary) -> Material:
    # GLTF duplicates a unique texture set for every otherwise-identical
    # StandardMaterial. Consolidating instances ONLY in the source export
    # makes the editable 3D file much easier to work with in Blender; the
    # live Android/HTML5 material and its node hierarchy remain unchanged.
    if not mat is StandardMaterial3D:
        return mat
    var m: StandardMaterial3D = mat as StandardMaterial3D
    var key: String = str([
        m.albedo_color,m.metallic,m.roughness,
        m.normal_enabled,m.normal_scale,m.emission_enabled,
        m.emission,m.emission_energy_multiplier,
        m.uv1_scale,m.uv1_offset,m.cull_mode,m.transparency,
        m.texture_filter,_texture_id(m.albedo_texture),
        _texture_id(m.normal_texture),
        _texture_id(m.roughness_texture),
        _texture_id(m.metallic_texture),
        _texture_id(m.emission_texture)
    ])
    if not cache.has(key):
        cache[key] = mat
    return cache[key]

func _run() -> void:
    var source: Node3D = Models.build("tank",0,true,18)
    assert(source != null and source.get_meta("tarvoka_mbt_resculpt_v18",false))
    root.add_child(source)
    var artist := Node3D.new()
    artist.name = "TARVOKA_G09_ESCULTURA_V18_EDITABLE"
    root.add_child(artist)
    var chassis := Node3D.new()
    chassis.name = "Chassis_Tracks"
    artist.add_child(chassis)
    var turret := Node3D.new()
    turret.name = "Turret_Rotating"
    artist.add_child(turret)
    var cannon := Node3D.new()
    cannon.name = "Cannon_Animated"
    artist.add_child(cannon)
    var collections := {
        "Chassis_Tracks": chassis,"Turret_Rotating":turret,
        "Cannon_Animated":cannon
    }
    var count: int = 0
    var baked: int = 0
    var material_cache: Dictionary = {}
    for node in source.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D = node as MeshInstance3D
        if not part.is_visible_in_tree() or part.mesh == null:
            continue
        var target: Node3D = collections[_group_for(part)]
        var clone := MeshInstance3D.new()
        clone.name = str(part.name)
        clone.mesh = part.mesh
        clone.material_override = _shared_export_material(part.material_override,material_cache)
        clone.transform = target.global_transform.affine_inverse()*part.global_transform
        target.add_child(clone)
        count += 1
    for node in source.find_children("*","MultiMeshInstance3D",true,false):
        var batch: MultiMeshInstance3D = node as MultiMeshInstance3D
        if not batch.is_visible_in_tree() or batch.multimesh == null:
            continue
        var group: Node3D = collections[_group_for(batch)]
        for i in range(batch.multimesh.visible_instance_count if batch.multimesh.visible_instance_count >= 0 else batch.multimesh.instance_count):
            var instance := MeshInstance3D.new()
            instance.name = "%s_%03d" % [batch.name,i]
            instance.mesh = batch.multimesh.mesh
            instance.material_override = _shared_export_material(batch.material_override,material_cache)
            var local: Transform3D = batch.multimesh.get_instance_transform(i)
            instance.transform = group.global_transform.affine_inverse()*batch.global_transform*local
            group.add_child(instance)
            baked += 1
    assert(count > 120)
    assert(baked >= 168)
    var doc := GLTFDocument.new()
    var state := GLTFState.new()
    var read_result: Error = doc.append_from_scene(artist,state,0)
    if read_result != OK:
        push_error("GLB: cannot serialize actual V18 G09 geometry; code=%d" % read_result)
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var write_result: Error = doc.write_to_filesystem(state,ProjectSettings.globalize_path(TARGET))
    if write_result != OK:
        push_error("GLB: write failed; code=%d" % write_result)
        quit(3)
        return
    var source_glb := FileAccess.open(TARGET,FileAccess.READ)
    assert(source_glb != null and source_glb.get_length() > 10000)
    var length: int = source_glb.get_length()
    source_glb.close()
    print("PASS G09 V18 GLB export: %d true meshes, %d baked running-gear parts, %d bytes, %d shared authored materials, 3 editable mechanical groups" % [count,baked,length,material_cache.size()])
    artist.queue_free()
    source.queue_free()
    quit(0)
