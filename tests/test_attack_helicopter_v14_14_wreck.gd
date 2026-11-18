extends SceneTree

# HAT-29 V14.14: real V14.13 crown breaks into two physically sourced
# rotor-head sectors, driven by the original V13 world-anchored wreck tween.
# Godot 4.3 native geometry/animation checks for all eight factions.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const Crown=preload("res://scripts/ui/AttackHelicopterHubCrownV1413.gd")
const Wreck=preload("res://scripts/ui/AttackHelicopterHubWreckV1414.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("HAT29 V14.14 ROTOR WRECK: "+why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not Wreck.has_model(tactical)
        and not Wreck.apply(tactical),
        "hub fragments never enter Android battle LOD10")
    if tactical!=null:
        tactical.queue_free()
    var checks: int=0
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and Crown.has_model(model)
            and Wreck.has_model(model),
            "all eight hero factions have two rotor cap fragments")
        if model==null:
            continue
        root.add_child(model)
        var rotor: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var wreck: Node3D=model.find_child(V13.WRECK,true,false) as Node3D
        var crown: MeshInstance3D=model.find_child(
            Crown.CROWN,true,false) as MeshInstance3D
        _check(rotor!=null and wreck!=null and crown!=null
            and crown.get_parent()!=wreck and not wreck.visible,
            "intact spinning cap remains separate from hidden V13 debris")
        if rotor==null or wreck==null or crown==null:
            model.queue_free()
            await process_frame
            continue
        var pieces: Array[MeshInstance3D]=[]
        var vertices_total: int=0
        var before_count: int=Models.inspect_meshes(model)
        for index in range(2):
            var part: MeshInstance3D=wreck.find_child(
                Wreck.PREFIX+str(index),false,false) as MeshInstance3D
            _check(part!=null and part.get_parent()==wreck
                and part.mesh is ArrayMesh
                and part.has_meta("a01_v1414_from_original_crown"),
                "V14.14 authentic pieces are attached only to V13 wreck")
            if part==null:
                continue
            pieces.append(part)
            var v: PackedVector3Array=(
                (part.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    as PackedVector3Array)
            vertices_total+=v.size()
            _check(v.size()>120 and v.size()<1848,
                "each jagged sector uses subset of original V14.13 crown triangles")
        _check(pieces.size()==2 and vertices_total<1848,
            "V14.14 makes two incomplete rather than duplicate intact crowns")
        if pieces.size()!=2:
            model.queue_free()
            await process_frame
            continue
        _check(Wreck.set_enabled(model,false)
            and not pieces[0].visible and not pieces[1].visible,
            "old V13-only crash silhouette can be previewed faithfully")
        _check(Wreck.set_enabled(model,true)
            and pieces[0].visible and pieces[1].visible,
            "V14.14 two authentic crown fragments can be restored in situ")
        _check(Wreck.apply(model)
            and Models.inspect_meshes(model)==before_count,
            "reapplying hero damage cap never creates additional mesh nodes")
        _check(V13.set_stage(model,4)
            and wreck.visible and wreck.top_level and not rotor.visible,
            "destroy hides intact hub and world-anchors existing V13 debris")
        _check(V13.pose(model,"destroy",0.0),
            "original V13 destruction animation starts with intact crown gone")
        for piece in pieces:
            _check(piece.position.distance_to(Wreck.LAUNCH)<0.0001,
                "both cap sectors launch from actual V1 rotor-head elevation")
        _check(V13.pose(model,"destroy",0.45),
            "original V13 crash interpolates both new cap sectors")
        for piece in pieces:
            _check(piece.position.y>0.18
                and piece.position.y<Wreck.LAUNCH.y+0.29,
                "fragment is flying, not teleported instantly to ground")
        _check(V13.pose(model,"destroy",1.0),
            "V13 moves authentic hub sectors to their final debris sites")
        for index in range(pieces.size()):
            var piece: MeshInstance3D=pieces[index]
            _check(piece.position.distance_to(Wreck.REST_POINTS[index])<0.0002,
                "each metal sector settles on the real terrain position")
            _check(absf(piece.position.x)>1.30 and piece.position.y<0.17,
                "fractured crown parts remain readable outside the fuselage and close to ground")
        _check(not rotor.visible and crown.get_parent()!=wreck,
            "no intact rotor ghost remains visible at final crash")
        V13.restore(model)
        _check(V13.set_stage(model,0)
            and rotor.visible and not wreck.visible
            and not wreck.top_level and Wreck.has_model(model),
            "repair restores original spinning hub and hides entire debris assembly")
        _check(V13.pose(model,"hover",0.25)
            and rotor.visible and crown.mesh is ArrayMesh
            and Models.inspect_meshes(model)==before_count,
            "repaired rotor turns in place without hidden wreck geometry leaking")
        checks+=1
        model.queue_free()
        await process_frame
    _check(checks==8,"eight full faction-specific wreck/repair cycles executed")
    if failures==0:
        print("PASS HAT29 V14.14 WRECK: eight factions, 2 cut native hub sectors, original V13 airborne-to-ground tween, V13 comparator, no ghost rotor and intact repair")
        quit(0)
    else:
        push_error("HAT29 V14.14 WRECK: %d failures" % failures)
        quit(1)
