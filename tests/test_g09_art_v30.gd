extends SceneTree

const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Rig=preload("res://scripts/ui/TankVisualRig3D.gd")
const Damage=preload("res://scripts/ui/TankDamage3D.gd")
const Tracks=preload("res://scripts/ui/TankFinalTracksV29.gd")
const Hit=preload("res://scripts/ui/TankHitReactionV30.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var model: Node3D=Models.build("tank",2,true,30)
    assert(model!=null)
    assert(model.get_meta("tarvoka_mbt_track_wide_v30",false))
    assert(model.get_meta("tarvoka_damage_polished_v30",false))
    assert(model.get_meta("tarvoka_hit_v30",false))
    assert(Models.paintable_count(model)==14)
    var left: MultiMeshInstance3D=model.find_child(
        "OrugaArticuladaG09V7_-1",true,false) as MultiMeshInstance3D
    var right: MultiMeshInstance3D=model.find_child(
        "OrugaArticuladaG09V7_1",true,false) as MultiMeshInstance3D
    assert(left!=null and right!=null)
    assert(left.multimesh.instance_count==84)
    assert(right.multimesh.instance_count==84)
    assert(left.multimesh.mesh==right.multimesh.mesh)
    var bb: AABB=left.multimesh.mesh.get_aabb()
    assert(bb.size.x>0.40 and bb.size.x<0.46)
    assert(left.multimesh.mesh.get_surface_count()==2)
    for side in [-1,1]:
        var belt: MultiMeshInstance3D=model.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(absf(belt.multimesh.get_instance_transform(0).origin.x-
            float(side)*Tracks.CENTER_X)<0.001)
        var old: Node3D=model.find_child("BandaOruga%s" % side,true,false) as Node3D
        assert(old!=null and not old.visible)
    var damage_root: Node3D=model.find_child("EtapasDestruccion3D",true,false)
    assert(damage_root!=null)
    for stage in range(5):
        assert(Damage.apply_stage(model,stage))
        assert(Models.paintable_count(model)==14)
        for n in range(1,5):
            var layer: Node3D=damage_root.find_child(
                "DesgasteEtapa%d" % n,false,false)
            assert(layer!=null)
            for node in layer.get_children():
                if node is MeshInstance3D:
                    var part: MeshInstance3D=node as MeshInstance3D
                    if part.mesh is BoxMesh or part.mesh is CylinderMesh:
                        assert(not part.visible)
        assert(model.get_meta("tarvoka_mbt_track_wide_v30"))
    assert(Damage.apply_stage(model,0))
    for faction in range(8):
        assert(Models.apply_faction_palette(model,faction)==14)
        assert(left.multimesh.mesh.get_aabb().size.x>0.40)
    assert(Hit.classify_weapon("line")==Hit.BULLET)
    assert(Hit.classify_weapon("scout")==Hit.BULLET)
    assert(Hit.classify_weapon("tank")==Hit.EXPLOSIVE)
    assert(Hit.classify_weapon("fighter")==Hit.EXPLOSIVE)
    assert(Hit.classify_weapon("mlrs")==Hit.EXPLOSIVE)
    assert(Hit.classify_weapon("apc","rocket launcher")==Hit.EXPLOSIVE)
    var bullet: Dictionary={}
    var explosive: Dictionary={}
    for kind in [Hit.BULLET,Hit.EXPLOSIVE]:
        for frame in range(16):
            assert(Rig.pose(model,kind,float(frame)/15.0,Vector2i(0,-1)))
            if frame==2:
                var spark: MeshInstance3D=model.find_child(
                    "DestelloRicochet",true,false) as MeshInstance3D
                var blast: MeshInstance3D=model.find_child(
                    "ExplosionCentral",true,false) as MeshInstance3D
                if kind==Hit.BULLET:
                    assert(spark.visible and not blast.visible)
                    bullet={"jolt":model.rotation_degrees.z}
                else:
                    assert(not spark.visible and blast.visible)
                    explosive={"jolt":model.rotation_degrees.z}
        Rig.restore(model)
        var spark_off: MeshInstance3D=model.find_child(
            "DestelloRicochet",true,false) as MeshInstance3D
        assert(not spark_off.visible)
    assert(absf(float(explosive["jolt"]))>absf(float(bullet["jolt"])))
    var before: int=Models.inspect_meshes(model)
    assert(before>0)
    assert(Models.paintable_count(model)==14)
    model.free()
    print("PASS G09 V30: 0.422m width textured tracks, 168 links, same 2 GPU batches, five sculpted damage stages, bullet/explosion responses and eight palettes")
    quit(0)
