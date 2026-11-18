extends SceneTree

# HAT-29 V14.13 real rotor motion + machined crown QA, Godot 4.3.
# All 8 factions x real native poses; no mocked screenshot animation.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const FX=preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
const V1412=preload("res://scripts/ui/AttackHelicopterBladeSeamV1412.gd")
const Hub=preload("res://scripts/ui/AttackHelicopterHubCrownV1413.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("HAT29 V14.13 ROTOR MOTION: "+why)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not Hub.has_model(tactical)
        and not Hub.apply(tactical),
        "V14.13 machined cap must never enter Android battle LOD10")
    if tactical!=null:
        tactical.queue_free()
    var samples: Array[float]=[0.0,0.03125,0.0625,0.125,0.25,0.5,0.75,1.0]
    var modes: Array[String]=[
        "hover","move","attack","hit_bullet","hit_explosive"]
    var tested: int=0
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and Hub.has_model(model)
            and V1412.has_model(model) and V13.has_model(model)
            and FX.has_model(model),
            "eight factions use same original rotor tree and finished cap")
        if model==null:
            continue
        root.add_child(model)
        var main: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var body: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
        var v10: Node3D=model.find_child(V10.ROTOR,true,false) as Node3D
        var cap: MeshInstance3D=model.find_child(Hub.CROWN,true,false) as MeshInstance3D
        var hub: MeshInstance3D=model.find_child(
            "A01_BujePrincipal",true,false) as MeshInstance3D
        if main==null or body==null or v10==null or cap==null or hub==null:
            _check(false,"missing physical V1/V10 hub for faction "+str(faction))
            model.queue_free()
            await process_frame
            continue
        _check(main.get_parent()==body and v10.get_parent()==main
            and cap.get_parent()==v10 and hub.get_parent()==main,
            "machined cap is attached to original spinning rotor, not fuselage")
        _check(cap.mesh is ArrayMesh
            and cap.get_meta(Hub.ORIGINAL_MESH) is TorusMesh,
            "V14.13 physically replaces original V10 open ring in same mesh")
        var shape: ArrayMesh=cap.mesh as ArrayMesh
        if shape!=null:
            var vertices: PackedVector3Array=(
                shape.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    as PackedVector3Array)
            var bounds: AABB=shape.get_aabb()
            _check(vertices.size()==1848
                and bounds.size.x>0.46 and bounds.size.z>0.46
                and bounds.position.y< -0.043
                and bounds.end.y>=0.032,
                "V14.13 616-triangle closed machined ring really covers hub")
        var steel: StandardMaterial3D=cap.material_override as StandardMaterial3D
        _check(steel!=null and steel.roughness>=0.55
            and steel.albedo_color.r<0.50,
            "V14.13 closes blown-out white crown with actual matte metal finish")
        var baseline: Transform3D=(
            main.global_transform.affine_inverse()*cap.global_transform)
        var all_pivots: Array[Node3D]=[]
        var blades: Array[MeshInstance3D]=[]
        var seals: Array[MeshInstance3D]=[]
        var local_roots: Array[Transform3D]=[]
        for i in range(4):
            var pivot: Node3D=model.find_child(
                V3.LEGACY_ROTOR+str(i),true,false) as Node3D
            var blade: MeshInstance3D=model.find_child(
                V3.BLADE+str(i),true,false) as MeshInstance3D
            var root_piece: MeshInstance3D=model.find_child(
                V1412.ROOT+str(i),true,false) as MeshInstance3D
            _check(pivot!=null and pivot.get_parent()==main
                and blade!=null and blade.get_parent()==pivot
                and root_piece!=null and root_piece.get_parent()==pivot,
                "four original airfoils and V14.12 roots remain on V1 pivots")
            if pivot==null or root_piece==null or blade==null:
                continue
            all_pivots.append(pivot)
            blades.append(blade)
            seals.append(root_piece)
            local_roots.append(main.global_transform.affine_inverse()
                *root_piece.global_transform)
        _check(all_pivots.size()==4,"four original spinning pivots required")
        for mode in modes:
            for progress in samples:
                _check(V13.pose(model,mode,progress)
                    and FX.pose(model,mode,progress),
                    "real pose and FX engine support "+mode)
                var local_now: Transform3D=(
                    main.global_transform.affine_inverse()*cap.global_transform)
                _check(local_now.origin.distance_to(baseline.origin)<0.0002
                    and local_now.basis.is_equal_approx(baseline.basis),
                    "no crown or bolts detach when original rotor spins: "+mode)
                for i in range(all_pivots.size()):
                    var piece: MeshInstance3D=seals[i]
                    var current: Transform3D=(
                        main.global_transform.affine_inverse()*piece.global_transform)
                    _check(current.origin.distance_to(local_roots[i].origin)<0.0002
                        and current.basis.is_equal_approx(local_roots[i].basis),
                        "blade transition does not separate in "+mode)
                    _check(piece.get_parent()==all_pivots[i]
                        and blades[i].get_parent()==all_pivots[i]
                        and piece.mesh is ArrayMesh,
                        "animation preserves single shared actual blade pivot")
                tested+=1
        # Missile shot reuses unchanged V13 rotor without inventing V1 action.
        for progress in samples:
            _check(V13.pose(model,"hover",progress)
                and FX.pose(model,"fire_missiles",progress),
                "original missile FX operates with spinning sealed rotor")
            _check((main.global_transform.affine_inverse()
                *cap.global_transform).origin.distance_to(baseline.origin)<0.0002,
                "missile launch cannot detach revolving center cover")
            tested+=1
        _check(Hub.set_enabled(model,false)
            and cap.mesh is TorusMesh,"V14.13 genuinely restores native V10 torus")
        _check(Hub.set_enabled(model,true)
            and cap.mesh is ArrayMesh,
            "V14.13 comparison returns real closed crown on same mesh node")
        var nodes_before: int=Models.inspect_meshes(model)
        _check(Hub.apply(model) and Models.inspect_meshes(model)==nodes_before,
            "V14.13 multiple installs never add draw nodes or new rotor")
        _check(V13.set_stage(model,4) and not main.visible,
            "total destruction hides full original rotor with V14.13 cover")
        _check(V13.pose(model,"destroy",0.85),
            "destroy animation operates on same V1/V13 airframe")
        _check(cap.get_parent()==v10 and cap.mesh is ArrayMesh,
            "destroy never leaves detached ghost hub behind")
        V13.restore(model)
        _check(V13.set_stage(model,0) and main.visible
            and Hub.has_model(model),
            "repair restores rotating finished hub and all original blades")
        model.queue_free()
        await process_frame
    _check(tested==384,"8 factions x 48 authentic V1/V13+V14 motion samples")
    if failures==0:
        print("PASS HAT29 V14.13 MOTION: 8 factions, 384 real frames, original 4-pivot rotor, closed hub, missiles, damage, wreck/repair and zero duplicate draw nodes")
        quit(0)
    else:
        push_error("HAT29 V14.13 MOTION: %d failures" % failures)
        quit(1)
