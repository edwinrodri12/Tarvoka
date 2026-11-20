extends SceneTree

# G11 mobile visual correctness: batched launchers and wheels across
# 8 faction palettes, LOD8/LOD10 and unaffected high-detail Studio.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
var errors: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 MOBILE QA " + label)

func _find(model: Node3D, title: String) -> Node:
    return model.find_child(title,true,false)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Mobile.recommended_level(18.0,12) == 8,
        "far camera selects lower detail")
    _check(Mobile.recommended_level(4.0,64) == 8,
        "dense 8-player viewport selects lower detail")
    _check(Mobile.recommended_level(4.0,8) == 10,
        "near camera retains visible detail")
    var baseline_tube_triangles: int = 0
    var optimized_tube_triangles: int = 0
    for faction in range(8):
        for level in [8,10]:
            var model: Node3D = Models.build("mlrs",faction,true,level)
            _check(model != null,"build LOD %d faction %d" % [level,faction])
            if model == null:
                continue
            root.add_child(model)
            _check(Mobile.has_model(model),"LOD resource tagged")
            _check(not Art.has_model(model),"hero material not loaded on Android")
            _check(int(model.get_meta(Mobile.FLAG,-1)) == level,"correct LOD")
            _check(_find(model,Mobile.POD) != null,"legacy-compatible launcher name")
            _check(_find(model,"ChasisLanzacohetes") != null,
                "combat silhouette remains stable")
            var tube: MultiMeshInstance3D = _find(model,
                "G11Mobile_Lote12Tubos") as MultiMeshInstance3D
            _check(tube != null and tube.multimesh != null,
                "all 12 tubes grouped in one GPU batch")
            if tube != null and tube.multimesh != null:
                _check(tube.multimesh.instance_count == Mobile.TUBES,
                    "full twelve-tube count")
                var tube_mesh := tube.multimesh.mesh as CylinderMesh
                _check(tube_mesh != null and tube_mesh.radial_segments == Mobile.TUBE_RADIAL_SEGMENTS,
                    "rocket tube radial budget")
                if tube_mesh != null:
                    var reference := CylinderMesh.new()
                    reference.top_radius = tube_mesh.top_radius
                    reference.bottom_radius = tube_mesh.bottom_radius
                    reference.height = tube_mesh.height
                    reference.radial_segments = 10
                    var old_count: int = reference.get_faces().size() / 3
                    var new_count: int = tube_mesh.get_faces().size() / 3
                    _check(new_count < old_count, "tube optimization reduces actual mesh triangles")
                    baseline_tube_triangles += old_count * tube.multimesh.instance_count
                    optimized_tube_triangles += new_count * tube.multimesh.instance_count
            var wheel: MultiMeshInstance3D = _find(model,
                "G11Mobile_Lote12Ruedas") as MultiMeshInstance3D
            var rims: MultiMeshInstance3D = _find(model,
                "G11Mobile_Lote12Bordes") as MultiMeshInstance3D
            _check((wheel != null) == (level == 10),
                "wheel geometry only drawn near camera")
            _check((rims != null) == (level == 10),
                "tube rim geometry culled at distance")
            if rims != null and rims.multimesh != null:
                _check(rims.multimesh.instance_count == Mobile.TUBES,
                    "all twelve near-camera rims preserved")
                var rim_mesh := rims.multimesh.mesh as CylinderMesh
                _check(rim_mesh != null and rim_mesh.radial_segments == Mobile.TUBE_RADIAL_SEGMENTS,
                    "near-camera rims match reduced radial budget")
            if wheel != null and wheel.multimesh != null:
                _check(wheel.multimesh.instance_count == Mobile.WHEELS,
                    "12 wheels in one MultiMesh")
            _check(Models.inspect_meshes(model) <= 18,
                "less than 19 MeshInstances per vehicle")
            var stripe: MeshInstance3D = _find(model,
                "G11Mobile_InsigniaFrontal") as MeshInstance3D
            _check(stripe != null and stripe.material_override != null,
                "faction paint on actual native mesh")
            _check(Models.pose_model("mlrs",model,"attack",0.5,Vector2i(1,0)),
                "launcher still rotates when attacking")
            _check(_find(model,Mobile.ROTATOR).rotation_degrees.y < -40.0,
                "attacker facing motion")
            _check(Models.pose_model("mlrs",model,"move",0.4),
                "mobile rig supports movement")
            Models.restore_model_pose("mlrs",model)
            _check(_find(model,Mobile.POD).rotation_degrees.x == -25.0,
                "restore launch angle")
            model.queue_free()
            await process_frame
    var hero := Models.build("mlrs",0,true,13)
    _check(hero != null and Art.has_model(hero),
        "studio retains complete V3 sculpt with independent launcher")
    _check(hero != null and not Mobile.has_model(hero),
        "no mobile proxy allocated under studio sculpt")
    if hero != null:
        hero.free()
    _check(optimized_tube_triangles < baseline_tube_triangles,
        "aggregate tube triangle budget reduced across all faction LODs")
    print("G11 tube census (16 models, tubes only): baseline=", baseline_tube_triangles,
        " optimized=", optimized_tube_triangles,
        " saved=", baseline_tube_triangles - optimized_tube_triangles)
    if errors > 0:
        push_error("G11 mobile QA %d failed" % errors)
        quit(1)
        return
    print("PASS G11 MOBILE LOD: eight factions, 12 tubes, 12 batched wheels, LOD8/LOD10, hero V3, aim and restore")
    quit(0)
