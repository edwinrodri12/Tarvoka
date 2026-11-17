extends SceneTree

# G13 V16 GPU instancing acceptance: ensure actual rendered draw objects
# fall by 27, not merely renaming nodes or deleting important art pieces.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Batches=preload("res://scripts/ui/G13StaticBatchV16.gd")
var failures:int=0

func check(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V16: "+reason)

func _visible_draws(node:Node,parent_visible:bool=true)->int:
    var visible_here:bool=parent_visible
    if node is Node3D:
        visible_here=visible_here and (node as Node3D).visible
    if not visible_here:
        return 0
    var draws:int=1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
    for child in node.get_children():
        draws+=_visible_draws(child,visible_here)
    return draws

func _triangles(mesh:Mesh)->int:
    if mesh==null:
        return 0
    var value:int=0
    for i in range(mesh.get_surface_count()):
        var a:Array=mesh.surface_get_arrays(i)
        var ix:Variant=a[Mesh.ARRAY_INDEX]
        var vs:Variant=a[Mesh.ARRAY_VERTEX]
        if ix is PackedInt32Array and ix.size()>0:
            value+=int(ix.size()/3)
        elif vs is PackedVector3Array:
            value+=int(vs.size()/3)
    return value

func _visible_triangles(node:Node,parent_visible:bool=true)->int:
    var visible_here:bool=parent_visible
    if node is Node3D:
        visible_here=visible_here and (node as Node3D).visible
    if not visible_here:
        return 0
    var count:int=0
    if node is MeshInstance3D:
        count+=_triangles((node as MeshInstance3D).mesh)
    elif node is MultiMeshInstance3D:
        var mm:MultiMesh=(node as MultiMeshInstance3D).multimesh
        if mm!=null:
            count+=_triangles(mm.mesh)*mm.instance_count
    for child in node.get_children():
        count+=_visible_triangles(child,visible_here)
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var expected_reduction:int=27
    var first_faction:Color=Color.WHITE
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,13)
        check(model!=null,"hero construction faction "+str(faction))
        if model==null:
            continue
        check(bool(model.get_meta(Batches.FLAG,false)),
            "real V16 batch is installed for faction "+str(faction))
        var source_names:Array=model.get_meta(Batches.META_SOURCES,[])
        var batches:Array=model.get_meta(Batches.META_GROUPS,[])
        check(source_names.size()==44 and batches.size()==17,
            "V16 covers exactly 44 repeated parts in 17 GPU MultiMeshes")
        check(int(model.get_meta(Batches.META_SAVED,0))==expected_reduction,
            "GPU draw-object savings should be exactly 27")
        var rendered:int=_visible_draws(model)
        var triangles:int=_visible_triangles(model)
        for spec in Batches._specs():
            var name:String=str(spec["name"])
            var mm_node:=model.find_child(name,true,false) as MultiMeshInstance3D
            check(mm_node!=null and mm_node.visible and mm_node.multimesh!=null,
                "all 17 batches are real visible GPU MultiMeshes")
            if mm_node==null or mm_node.multimesh==null:
                continue
            var mm:MultiMesh=mm_node.multimesh
            var entries:Array=spec["parts"]
            check(mm.instance_count==entries.size(),
                "instance count matches every original GPU source")
            for i in range(entries.size()):
                var original:=model.find_child(str(entries[i]),true,false) as MeshInstance3D
                check(original!=null and not original.visible,
                    "original named part retained but hidden after batching")
                if original!=null:
                    check(original.get_parent()==mm_node.get_parent(),
                        "batch remains on exact same local animated pivot")
                    check(original.transform.is_equal_approx(mm.get_instance_transform(i)),
                        "batching retains full original 3D transform")
                    var shared:=mm.mesh as PrimitiveMesh
                    check(shared!=null and Batches._same_primitive(
                            original.mesh as PrimitiveMesh,shared),
                        "GPU instance still draws identical source geometry")
                    if shared!=null:
                        check(Batches._same_material(
                            original.material_override as StandardMaterial3D,
                            shared.material as StandardMaterial3D),
                            "materials, emission, faction enamel and roughness survive batching")
        check(Batches.set_legacy_comparison(model,true),
            "can reproduce exact legacy V15 source meshes for visual QA")
        var legacy:int=_visible_draws(model)
        var old_triangles:int=_visible_triangles(model)
        check(legacy-rendered==expected_reduction,
            "actual visible render-object reduction is 27 vs legacy V15")
        check(old_triangles==triangles,
            "same original triangle count, no geometry lost or invented")
        check(Batches.set_legacy_comparison(model,false),
            "return to optimized V16 without destroying named meshes")
        check(_visible_draws(model)==rendered,
            "enable/disable reference is reversible")
        check(not Batches.apply(model),"batching is idempotent")
        var color_node:=model.find_child("G13_V2_TurretInsignia_1",
            true,false) as MeshInstance3D
        if color_node!=null:
            var enamel:Color=(color_node.material_override as StandardMaterial3D).albedo_color
            if faction==0:
                first_faction=enamel
            else:
                check(not enamel.is_equal_approx(first_faction),
                    "unique faction paint is not replaced by fixed V16 color")
        var radar:=model.find_child(G13.RADAR,true,false) as Node3D
        var turret:=model.find_child(G13.TURRET,true,false) as Node3D
        var pitch:=model.find_child(G13.GUNS,true,false) as Node3D
        check(radar!=null and turret!=null and pitch!=null,
            "original independent aim and radar pivots present")
        for kind in ["move","scan","attack_air","attack_ground"]:
            check(Models.pose_model("aa_mobile",model,kind,0.43,Vector2i(1,0)),
                "V16 batching does not alter animation "+kind)
            check(_visible_draws(model)==rendered,
                "no added/removed draw objects during "+kind)
        check(Batches.set_legacy_comparison(model,true),
            "reference mode works after turret and radar animation")
        check(_visible_draws(model)==legacy,
            "original V15 equivalent still displays after animation")
        check(Batches.set_legacy_comparison(model,false),
            "reoptimized V16 restores after animation")
        Models.restore_model_pose("aa_mobile",model)
        model.free()
        var light:=Models.build("aa_mobile",faction,true,8)
        check(light!=null,"G13 lightweight Android profile survives")
        if light!=null:
            check(not bool(light.get_meta(Batches.FLAG,false)) and
                light.find_child("G13_V16_Fenders",true,false)==null,
                "lightweight Android LOD8 stays unchanged")
            light.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V16: 8 factions x 44 originals batched into 17 GPU groups, -27 visible draw objects, unchanged visible triangles, same faction materials, moving pivots, air/ground fire and mobile LOD8")
    quit(0)
