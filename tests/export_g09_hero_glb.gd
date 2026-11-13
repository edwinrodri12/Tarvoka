extends SceneTree

# Export the exact current in-game G09 geometry into a truly editable glTF 2.0
# asset for Blender, Godot and independent 3D validation. Copies only VISIBLE
# model meshes. MultiMesh/track instances are baked to individual glTF nodes
# in this authoring export, while the runtime game keeps mobile batching.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const TARGET := "res://artifacts/TARVOKA_G09_V10_Escultura_Editable.glb"

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

func _run() -> void:
    var source: Node3D = Models.build("tank",0)
    assert(source != null and source.get_meta("tarvoka_mbt_sculpted_v10",false))
    root.add_child(source)
    var artist := Node3D.new()
    artist.name = "TARVOKA_G09_ESCULTURA_V10_EDITABLE"
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
    for node in source.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D = node as MeshInstance3D
        if not part.is_visible_in_tree() or part.mesh == null:
            continue
        var target: Node3D = collections[_group_for(part)]
        var clone := MeshInstance3D.new()
        clone.name = str(part.name)
        clone.mesh = part.mesh
        clone.material_override = part.material_override
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
            instance.material_override = batch.material_override
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
        push_error("GLB: cannot serialize actual V10 G09 geometry; code=%d" % read_result)
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
    print("PASS G09 V10 GLB export: %d true meshes, %d baked running-gear parts, %d bytes, 3 editable mechanical groups" % [count,baked,length])
    artist.queue_free()
    source.queue_free()
    quit(0)
