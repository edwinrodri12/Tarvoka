extends SceneTree

# Repeatable Godot 4.3 software-renderer CPU and geometry profile.
# NOT an Android phone GPU FPS benchmark: never claim these timings are
# mobile frame rates. Compare the SAME 8 factions under LOD8 and LOD13.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/G13TurretFinishV15.gd")
var failures:int=0

func check(value:bool,why:String)->void:
    if not value:
        failures+=1
        push_error("G13 V15 build profile: "+why)

func _count_nodes(node:Node)->int:
    var n:int=1
    for child in node.get_children():
        n+=_count_nodes(child)
    return n

func _draw_calls(node:Node)->int:
    var n:int=1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
    for child in node.get_children():
        n+=_draw_calls(child)
    return n

func _triangles_in_mesh(mesh:Mesh)->int:
    var total:int=0
    if mesh==null:
        return 0
    for surf in range(mesh.get_surface_count()):
        # PrimitiveMesh (BoxMesh, CylinderMesh, SphereMesh) does not expose
        # ArrayMesh.surface_get_primitive_type in Godot 4.3. All meshes
        # authored for this vehicle are triangle surfaces, so count actual
        # indices when present or loose non-indexed vertices otherwise.
        var arrays:Array=mesh.surface_get_arrays(surf)
        if arrays.size()<=Mesh.ARRAY_VERTEX:
            continue
        var indices:Variant=arrays[Mesh.ARRAY_INDEX]
        var verts:Variant=arrays[Mesh.ARRAY_VERTEX]
        if indices is PackedInt32Array and indices.size()>0:
            total+=int(indices.size()/3)
        elif verts is PackedVector3Array:
            total+=int(verts.size()/3)
    return total

func _triangles(node:Node)->int:
    var total:int=0
    if node is MeshInstance3D:
        total+=_triangles_in_mesh((node as MeshInstance3D).mesh)
    elif node is MultiMeshInstance3D:
        var batch:MultiMesh=(node as MultiMeshInstance3D).multimesh
        if batch!=null:
            total+=_triangles_in_mesh(batch.mesh)*batch.instance_count
    for child in node.get_children():
        total+=_triangles(child)
    return total

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var stats:Dictionary={
        "engine":"Godot 4.3",
        "environment":"headless Linux CI compatibility renderer; not Android hardware",
        "role":"aa_mobile",
        "factions":8,
        "profiles":{}
    }
    for level in [8,13]:
        var nodes:int=0
        var calls:int=0
        var triangles:int=0
        var build_us:int=0
        var animation_us:int=0
        var no_nodes_changed:bool=true
        for faction in range(8):
            var before:int=Time.get_ticks_usec()
            var model:=Models.build("aa_mobile",faction,true,level)
            var built:int=Time.get_ticks_usec()
            check(model!=null,"build LOD%d faction %d" % [level,faction])
            if model==null:
                continue
            var old_nodes:int=_count_nodes(model)
            nodes+=old_nodes
            calls+=_draw_calls(model)
            triangles+=_triangles(model)
            build_us+=built-before
            check(bool(model.get_meta(Finish.FLAG,false))==(level==13),
                "V15 only on detail-13 models")
            var start:int=Time.get_ticks_usec()
            for pose_name in ["move","scan","attack_air","attack_ground"]:
                for t in [0.15,0.42,0.75]:
                    check(Models.pose_model("aa_mobile",model,pose_name,t),
                        "no regression during pose "+pose_name)
            Models.restore_model_pose("aa_mobile",model)
            animation_us+=Time.get_ticks_usec()-start
            if _count_nodes(model)!=old_nodes:
                no_nodes_changed=false
            model.free()
        check(no_nodes_changed,"animations allocate no permanent runtime 3D nodes")
        check(nodes>0 and calls>0 and triangles>0,
            "real geometry metrics for LOD %d" % level)
        stats["profiles"]["LOD%d" % level]={
            "average_nodes":int(nodes/8),
            "average_draw_objects":int(calls/8),
            "average_triangles":int(triangles/8),
            "average_build_microseconds":int(build_us/8),
            "average_12_poses_microseconds":int(animation_us/8),
            "node_count_stable_during_animation":no_nodes_changed
        }
    var light:Dictionary=stats["profiles"]["LOD8"]
    var hero:Dictionary=stats["profiles"]["LOD13"]
    check(int(hero["average_triangles"])>int(light["average_triangles"]),
        "hero is more detailed than mobile and does not replace LOD8")
    check(int(hero["average_draw_objects"])>int(light["average_draw_objects"]),
        "LOD8 draw-object count is lower than hero variant")
    var target:String=OS.get_environment("G13_V15_PROFILE_FILE")
    if target.is_empty():
        target="/tmp/g13-v15-profile.json"
    var file:=FileAccess.open(target,FileAccess.WRITE)
    check(file!=null,"can write detailed profiler JSON")
    if file!=null:
        file.store_string(JSON.stringify(stats,"  "))
        file.close()
    print("G13 V15 MEASURED PROFILE: "+JSON.stringify(stats))
    if failures>0:
        quit(1)
        return
    print("PASS G13 V15 PROFILE: eight-faction native geometry and CPU-only build/animation report; NO Android FPS claim")
    quit(0)
