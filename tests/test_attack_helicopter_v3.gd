extends SceneTree

# A01 V3 physical rotor and wing proportions; 8 faction/pivot/regression QA.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
var failures: int=0

func _check(condition: bool,label: String) -> void:
    if not condition:
        failures+=1
        push_error("A01 V3: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var battle: Node3D=Models.build("attack_heli",0,true,10)
    _check(battle!=null and not V3.has_model(battle),
        "original mobile battle LOD is not modified")
    if battle!=null:
        battle.free()
    var colors: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"V3 builds for faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(V1.has_model(model) and V2.has_model(model) and V3.has_model(model),
            "V1 V2 and V3 present in original compatible pivots")
        _check(Models.inspect_meshes(model)>100,
            "V3 uses actual added native meshes")
        var main: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var tail: Node3D=model.find_child(V1.TAIL_ROTOR,true,false) as Node3D
        var guard: Node3D=model.find_child(V3.GUARD,true,false) as Node3D
        _check(main!=null and tail!=null and guard!=null,
            "main + tail rotor and fixed guard")
        if guard!=null:
            _check(guard.get_child_count()>=27,
                "24 continuous guard segments and 3 metal supports")
        for i in range(4):
            var pivot: Node3D=model.find_child("A01_AspaPortante_%d" % i,
                true,false) as Node3D
            var main_old: MeshInstance3D=model.find_child(
                "A01_Pala_%d" % i,true,false) as MeshInstance3D
            var new_blade: MeshInstance3D=model.find_child(
                V3.BLADE+str(i),true,false) as MeshInstance3D
            var tail_old: MeshInstance3D=model.find_child(
                "A01_PalaCola_%d" % i,true,false) as MeshInstance3D
            var tail_new: MeshInstance3D=model.find_child(
                V3.TAIL_BLADE+str(i),true,false) as MeshInstance3D
            _check(pivot!=null and main_old!=null and new_blade!=null,
                "four original main blade pivots with new 3D airfoils")
            _check(tail_old!=null and tail_new!=null,
                "four old tail blade pivots with new sealed airfoils")
            if main_old!=null and new_blade!=null:
                _check(not main_old.visible and new_blade.visible,
                    "old main rotor slab hidden, new blade visible")
                _check(new_blade.mesh is ArrayMesh,
                    "airfoil is custom closed mesh, not a BoxMesh")
                var bounds: AABB=new_blade.mesh.get_aabb()
                _check(bounds.size.z>1.7 and bounds.size.y<0.08,
                    "main blade is long, tapered and thin")
            if tail_old!=null and tail_new!=null:
                _check(not tail_old.visible and tail_new.visible,
                    "old tail slab correctly replaced")
        for side in [-1,1]:
            var former: MeshInstance3D=model.find_child(
                "A01_AlaRefuerzo_%d" % side,true,false) as MeshInstance3D
            var finished: MeshInstance3D=model.find_child(
                V3.WING+str(side),true,false) as MeshInstance3D
            _check(former!=null and finished!=null,
                "original side wing replaced with closed tapered wing")
            if former!=null:
                _check(not former.visible,"old rectangular faction wing hidden")
            if finished!=null:
                _check(finished.mesh is ArrayMesh,
                    "new wing is shaped 3D array mesh, not colored box")
            var trim: MeshInstance3D=model.find_child(
                "A01V3_FranjaFaccion_%d" % side,true,false) as MeshInstance3D
            _check(trim!=null,"narrow faction marking retained")
            if trim!=null and side==1:
                var paint: StandardMaterial3D=trim.material_override as StandardMaterial3D
                if paint!=null:
                    colors[paint.albedo_color.to_html()]=true
        _check(V3.set_enabled(model,false),"V3 can revert without duplicate geom")
        _check(not guard.is_visible_in_tree(),"fixed tail guard disappears in V1 compare")
        var slab: MeshInstance3D=model.find_child("A01_Pala_0",
            true,false) as MeshInstance3D
        var blade: MeshInstance3D=model.find_child(V3.BLADE+"0",
            true,false) as MeshInstance3D
        _check(slab.visible and not blade.visible,"V1 blade comparison truthful")
        _check(V3.set_enabled(model,true),"V3 can be restored")
        _check(guard.visible and not slab.visible and blade.visible,
            "new rotor returns without overlaps")
        var before: Vector3=model.position
        _check(Models.pose_model("attack_heli",model,"move",0.36),
            "main rotor animation still runs on the original pivot")
        _check(main.rotation_degrees.y!=0.0,"main rotor moves")
        _check(tail.rotation_degrees.x!=0.0,"tail rotor moves")
        _check(Models.pose_model("attack_heli",model,"attack",0.34),
            "gun firing animation remains connected")
        Models.restore_model_pose("attack_heli",model)
        _check(model.position==before and guard.visible and blade.visible,
            "original pose restored with V3 meshes intact")
        model.queue_free()
        await process_frame
    _check(colors.size()==8,"eight faction paint trims keep unique identities")
    if failures>0:
        push_error("A01 V3 geometry failures: %d" % failures)
        quit(1)
        return
    print("PASS A01 V3: 8 factions, four tapered main and tail rotor blades, fixed 24-segment guard, tapered wings, exact reversible V1 comparison and preserved original battle LOD")
    quit(0)
