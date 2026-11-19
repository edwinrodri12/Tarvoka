extends SceneTree

# Godot 4.3 G13 V65: real articulated turret/hull ring, 8 official factions
# x HERO13/Android8, actual surface triangles, preserved yaw rig and costs.
const Model=preload("res://scripts/ui/UnitModels3D.gd")
const V65=preload("res://scripts/ui/G13TurretRingFinishV65.gd")
const V64=preload("res://scripts/ui/G13ArmorEdgeFinishV64.gd")
const V63=preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const V62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
var errors:int=0
var official_colors:Dictionary={}

func check(ok:bool,msg:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V65 native rotating ring: "+msg)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(V65.SEGMENT_COUNT==12 and
        V65.SEGMENT_TRIANGLES==60 and
        V65.NEW_DRAW_NODES==0,
        "12 beveled bearing segments inside the same GPU batch")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Model.build("aa_mobile",faction,true,lod)
            check(model!=null,
                "real G13 faction %d LOD%d native build" % [faction,lod])
            if model==null:
                continue
            check(bool(model.get_meta(V65.FLAG,false)) and
                bool(model.get_meta(V64.FLAG,false)) and
                bool(model.get_meta(V63.FLAG,false)) and
                bool(model.get_meta(V62.FLAG,false)) and
                bool(model.get_meta(V61.FLAG,false)),
                "new turret sculpt follows approved V61-64 materials")
            var data:Dictionary=model.get_meta(V65.SAVED,{})
            var before_mesh:Mesh=data.get("original_ring_mesh",null)
            var after_mesh:Mesh=data.get("machined_ring_mesh",null)
            var original:Dictionary=data.get("original_coats",{})
            var finished:Dictionary=data.get("machined_coats",{})
            var poses:Array[Transform3D]=data.get(
                "unchanged_rotating_poses",[])
            var hull:=model.find_child("G13_Casco4x4",
                true,false) as Node3D
            var turret:=model.find_child("G13_TorretaAzimut",
                true,false) as Node3D
            var joint:=model.find_child(V65.SEGMENTS,
                true,false) as MultiMeshInstance3D
            check(hull!=null and turret!=null and joint!=null and
                joint.multimesh!=null,"physical original rotating ring")
            if joint==null or turret==null or hull==null or (
                    joint.multimesh==null):
                model.free()
                continue
            check(turret.get_parent()==hull and
                joint.get_parent()==turret,
                "real azimuth parent is unchanged, not a static dummy")
            check(before_mesh is BoxMesh and
                after_mesh is ArrayMesh and
                joint.multimesh.mesh==after_mesh,
                "old cube replaced by true sculpted eight-corner sections")
            if after_mesh is ArrayMesh:
                check(after_mesh.get_faces().size()==
                    V65.SEGMENT_TRIANGLES*3,
                    "each segment is a 60-triangle closed beveled 3D solid")
                var arrays:Array=after_mesh.surface_get_arrays(0)
                var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                check(colors.size()==vertices.size() and
                    vertices.size()==V65.SEGMENT_TRIANGLES*3,
                    "all physical machined faces receive individual shading")
                if colors.size()>0:
                    check(colors[0].r<0.9 and colors[0].r>0.4,
                        "beveled steel edge is neither flat nor chrome")
            check(joint.multimesh.instance_count==12 and
                poses.size()==12 and
                int(model.get_meta(
                    "tarvoka_g13_v65_new_gpu_draw_nodes",-1))==0,
                "same 12 native instances and unchanged render object count")
            if poses.size()==12:
                for i in range(12):
                    check(joint.multimesh.get_instance_transform(i).
                        is_equal_approx(poses[i]),
                        "all original angular instances remain in-place")
            check(original.size()==(3 if hero else 1) and
                finished.size()==original.size(),
                "hero upper pedestal and bearing; Android compact version")
            var m:=joint.material_override as StandardMaterial3D
            check(m!=null and m==finished.get(V65.SEGMENTS) and
                m.vertex_color_use_as_albedo and m.metallic>=0.61 and
                m.roughness>=0.45 and m.clearcoat_enabled,
                "real satin steel upper ring face with bevel highlights")
            if hero:
                var bearing:=model.find_child(V65.BEARING,
                    true,false) as MeshInstance3D
                var pedestal:=model.find_child(V65.PEDESTAL,
                    true,false) as MeshInstance3D
                check(bearing!=null and pedestal!=null,
                    "existing real upper pedestal and rotating bearing")
                if bearing!=null and pedestal!=null:
                    check(bearing.get_parent()==turret and
                        pedestal.get_parent()==hull and
                        bearing.material_override==finished.get(
                        V65.BEARING) and
                        pedestal.material_override==finished.get(
                        V65.PEDESTAL),
                        "actual rotating bearing/upper deck steel contrast")
            check(V65.show_finish(model,false),
                "switch to exact historic V64 turret ring, without proxies")
            check(joint.multimesh.mesh==before_mesh and
                joint.material_override==original.get(V65.SEGMENTS),
                "exact primitive ring geometry and material restored")
            check(V65.show_finish(model,true),
                "reactivate modern chamfered native bearing")
            check(joint.multimesh.mesh==after_mesh and
                joint.material_override==finished.get(V65.SEGMENTS),
                "new native bearing restored on original turret pivot")
            var faction_mark:=model.find_child(
                "G13_TurretFaction_1",true,false
                ) as GeometryInstance3D
            if faction_mark!=null:
                var paint:=faction_mark.material_override as StandardMaterial3D
                if paint!=null:
                    official_colors[paint.albedo_color.to_html()]=true
            for side in [-1,1]:
                check(model.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,"two original autocannons intact")
            check(Model.pose_model("aa_mobile",model,
                "aim_air",0.61,Vector2i(1,1)),
                "azimuth/yaw and dual cannon pitch remain functional")
            Model.restore_model_pose("aa_mobile",model)
            model.free()
    check(official_colors.size()==8,
        "all eight approved faction colors remain distinguishable")
    if errors==0:
        print("PASS G13 V65 TURRET RING: 8 factions x LOD8/13, twelve 60-triangle beveled segments, original yaw and pitch, HERO bearing/pedestal, zero new draw nodes, V61-V64 preserved")
    quit(1 if errors>0 else 0)
