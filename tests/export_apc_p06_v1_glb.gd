extends SceneTree

# Exports ACTUAL Godot P06 V1 geometry, paint and moving assemblies.
# Wheel bolts are baked into editable meshes ONLY for the artist's GLB;
# the Android/Godot runtime retains six efficient 8-instance MultiMeshes.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const TARGET := "res://artifacts/TARVOKA_APC_P06_V1_Editable.glb"

func _initialize() -> void:
    call_deferred("_run")

static func _group_name(part: Node) -> String:
    var parent: Node=part
    while parent!=null:
        if str(parent.name).begins_with("RuedaMotorizadaP06_"):
            return str(parent.name)
        if str(parent.name)=="ArmaEstabilizadaP06":
            return "Remote_Turret_Weapon"
        if str(parent.name)=="EstacionRemotaP06":
            return "Remote_Turret_Weapon"
        if str(parent.name)=="BisagraRampaP06":
            return "Troop_Ramp_Animated"
        parent=parent.get_parent()
    return "V_Hull_Armor_Seats"

func _run() -> void:
    var source: Node3D=Models.build("apc",2,true,11)
    assert(source!=null and source.get_meta("tarvoka_apc_sculpt_v1",false))
    root.add_child(source)
    var artist:=Node3D.new()
    artist.name="TARVOKA_APC_P06_V1_EDITABLE"
    root.add_child(artist)
    var groups: Dictionary={}
    for label in ["V_Hull_Armor_Seats","Remote_Turret_Weapon","Troop_Ramp_Animated"]:
        var group:=Node3D.new()
        group.name=label
        artist.add_child(group)
        groups[label]=group
    for side in [-1,1]:
        for axle in range(3):
            var label: String="RuedaMotorizadaP06_%d_%d" % [side,axle]
            var wheel:=Node3D.new()
            wheel.name=label
            artist.add_child(wheel)
            groups[label]=wheel
    var count:=0
    var baked:=0
    var materials: Dictionary={}
    for node in source.find_children("*","MeshInstance3D",true,false):
        var original: MeshInstance3D=node as MeshInstance3D
        if not original.is_visible_in_tree() or original.mesh==null:
            continue
        var part:=MeshInstance3D.new()
        part.name=str(original.name)
        part.mesh=original.mesh
        var mat: Material=original.material_override
        if mat!=null:
            var key: int=mat.get_instance_id()
            if not materials.has(key):
                materials[key]=mat
            part.material_override=materials[key]
        var target: Node3D=groups[_group_name(original)] as Node3D
        part.transform=target.global_transform.affine_inverse()*original.global_transform
        target.add_child(part)
        count+=1
    for node in source.find_children("*","MultiMeshInstance3D",true,false):
        var batch: MultiMeshInstance3D=node as MultiMeshInstance3D
        if not batch.is_visible_in_tree() or batch.multimesh==null:
            continue
        var group: Node3D=groups[_group_name(batch)] as Node3D
        var mm: MultiMesh=batch.multimesh
        for index in range(mm.instance_count):
            var piece:=MeshInstance3D.new()
            piece.name="%s_%02d" % [batch.name,index]
            piece.mesh=mm.mesh
            piece.material_override=batch.material_override
            piece.transform=(group.global_transform.affine_inverse()
                *batch.global_transform*mm.get_instance_transform(index))
            group.add_child(piece)
            baked+=1
    assert(count>60)
    assert(baked==48)
    var document:=GLTFDocument.new()
    var state:=GLTFState.new()
    var append_error: Error=document.append_from_scene(artist,state,0)
    if append_error!=OK:
        push_error("APC P06 glTF serialize failed: %d" % append_error)
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var write_error: Error=document.write_to_filesystem(
        state,ProjectSettings.globalize_path(TARGET))
    if write_error!=OK:
        push_error("APC P06 GLB write failed: %d" % write_error)
        quit(3)
        return
    var output: FileAccess=FileAccess.open(TARGET,FileAccess.READ)
    assert(output!=null and output.get_length()>9000)
    var bytes: int=output.get_length()
    output.close()
    artist.free()
    source.free()
    print("PASS APC P06 V1 GLB: %d native visible meshes, %d baked bolt instances, %d bytes, original Godot PBR with separately editable wheels, turret and ramp" % [count,baked,bytes])
    quit(0)
