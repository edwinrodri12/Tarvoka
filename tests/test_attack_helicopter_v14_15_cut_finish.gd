extends SceneTree

# HAT-29 V14.15: real V14.14 crown fragments now have closed
# exposed-metal fracture surfaces, checked edge-for-edge in Godot 4.3.
# No new draw nodes, no V13 crash animation edits, no Android LOD changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const V1414=preload("res://scripts/ui/AttackHelicopterHubWreckV1414.gd")
const Finish=preload("res://scripts/ui/AttackHelicopterHubCutFinishV1415.gd")
var failures: int=0

func _check(condition: bool,reason: String) -> void:
    if not condition:
        failures+=1
        push_error("HAT29 V14.15 FINISH: "+reason)

func _initialize() -> void:
    call_deferred("_run")

func _check_watertight(mesh: ArrayMesh) -> bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var vertices: PackedVector3Array=(
        mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array)
    var edges: Dictionary={}
    for triangle in range(vertices.size()/3):
        var i: int=triangle*3
        var a: Vector3=vertices[i]
        var b: Vector3=vertices[i+1]
        var c: Vector3=vertices[i+2]
        # Reject collapsed caps, self-edge degeneracy and unsealed seams.
        if (b-a).cross(c-a).length_squared()<0.0000000001:
            return false
        for pair in [[a,b],[b,c],[c,a]]:
            var key: String=Finish._edge_key(
                pair[0] as Vector3,pair[1] as Vector3)
            edges[key]=int(edges.get(key,0))+1
    if edges.is_empty():
        return false
    for occurrence in edges.values():
        if int(occurrence)!=2:
            return false
    return true

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not Finish.has_model(tactical)
        and not Finish.apply(tactical),
        "V14.15 cannot add microscopic cut surfaces in Android LOD10")
    if tactical!=null:
        tactical.queue_free()
    var checked_factions: int=0
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and V1414.has_model(model)
            and Finish.has_model(model),
            "V14.15 sealed damage finish exists for each of 8 factions")
        if model==null:
            continue
        root.add_child(model)
        var original_rotor: Node3D=model.find_child(
            V1.MAIN_ROTOR,true,false) as Node3D
        var debris: Node3D=model.find_child(
            V13.WRECK,true,false) as Node3D
        var draw_count: int=Models.inspect_meshes(model)
        var parts: Array[MeshInstance3D]=[]
        for index in range(2):
            var piece: MeshInstance3D=model.find_child(
                V1414.PREFIX+str(index),true,false) as MeshInstance3D
            _check(piece!=null and piece.get_parent()==debris,
                "two original V13 fragment nodes retained without duplication")
            if piece==null:
                continue
            parts.append(piece)
            var before: ArrayMesh=piece.get_meta(Finish.BEFORE) as ArrayMesh
            var closed: ArrayMesh=piece.mesh as ArrayMesh
            _check(before!=null and closed!=null and before!=closed,
                "V14.15 replaces exact earlier open V14.14 mesh in-place")
            if before==null or closed==null:
                continue
            var old_vertices: PackedVector3Array=(
                before.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    as PackedVector3Array)
            var final_vertices: PackedVector3Array=(
                closed.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    as PackedVector3Array)
            var final_colors: PackedColorArray=(
                closed.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
                    as PackedColorArray)
            var expected_old: int=792 if index==0 else 831
            var expected_new: int=864 if index==0 else 936
            _check(old_vertices.size()==expected_old
                and final_vertices.size()==expected_new,
                "authentic sector grows by exactly the missing cut-face triangles")
            _check(final_colors.size()==final_vertices.size()
                and final_colors[final_colors.size()-1]!=final_colors[0],
                "exposed bright metal is authored on actual separate cut vertices")
            _check(_check_watertight(closed),
                "full solid 2-manifold: every broken-rotor edge used exactly twice")
            var mat: StandardMaterial3D=piece.material_override as StandardMaterial3D
            _check(mat!=null and mat.vertex_color_use_as_albedo
                and mat.roughness>=0.70
                and mat.cull_mode==BaseMaterial3D.CULL_DISABLED,
                "fracture end caps are visibly metal and double-sided")
        if parts.size()!=2:
            model.queue_free()
            await process_frame
            continue
        _check(Finish.set_enabled(model,false)
            and parts[0].mesh==parts[0].get_meta(Finish.BEFORE)
            and parts[1].mesh==parts[1].get_meta(Finish.BEFORE),
            "V14.15 comparator restores authentic V14.14 cut-open mesh")
        _check(Finish.set_enabled(model,true)
            and _check_watertight(parts[0].mesh as ArrayMesh)
            and _check_watertight(parts[1].mesh as ArrayMesh),
            "V14.15 comparator restores both physically capped fragments")
        _check(Finish.apply(model)
            and Models.inspect_meshes(model)==draw_count,
            "repeated application adds no duplicate mesh or render nodes")
        _check(V13.set_stage(model,4)
            and V13.pose(model,"destroy",0.40)
            and not original_rotor.visible,
            "original V13 detaches finished metal without showing ghost rotor")
        _check(V13.pose(model,"destroy",1.0)
            and parts[0].position.distance_to(V1414.REST_POINTS[0])<0.0002
            and parts[1].position.distance_to(V1414.REST_POINTS[1])<0.0002,
            "V14.15 preserves grounded positions of both approved V14.14 chunks")
        V13.restore(model)
        _check(V13.set_stage(model,0)
            and original_rotor.visible and not debris.visible
            and Models.inspect_meshes(model)==draw_count,
            "repair returns intact HAT-29 with no leftover visible metal")
        checked_factions+=1
        model.queue_free()
        await process_frame
    _check(checked_factions==8,
        "all eight faction rotor damage/repair cycles completed")
    if failures==0:
        print("PASS HAT29 V14.15 CUT FINISH: 8 factions, 2 watertight torn crown shells, exposed metallic end caps, reversible V14.14 preview, intact V13 crash and LOD10")
        quit(0)
    else:
        push_error("HAT29 V14.15 CUT FINISH: %d failures" % failures)
        quit(1)
