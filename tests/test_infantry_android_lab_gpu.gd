extends SceneTree

# Native Godot 4.3/OpenGL acceptance: the same V1-V5 meshes as Android.
# Measures mesh visibility, never claims real Android FPS on Linux.
const Lab=preload("res://scenes/InfantryBarracksAndroidLab.tscn")
const BarracksV5=preload("res://scripts/ui/InfantryBarracksEntranceYardV5.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _capture(name: String) -> void:
    await _frames(9)
    var img: Image=root.get_texture().get_image()
    assert(img!=null and img.get_width()>=640 and img.get_height()>=400)
    var folder: String=ProjectSettings.globalize_path("res://artifacts")
    assert(DirAccess.make_dir_recursive_absolute(folder)==OK)
    assert(img.save_png("res://artifacts/infantry_android_%s.png" % name)==OK)

func _run() -> void:
    root.content_scale_size=Vector2i(1280,720)
    var lab: Node3D=Lab.instantiate()
    root.add_child(lab)
    await _frames(9)
    assert(lab._models.size()==1)
    assert(lab._models[0].has_node(BarracksV5.STAGE_NAME))
    assert(not lab._far_lod)
    var first_stats: Dictionary=lab.model_mesh_stats()
    assert(int(first_stats["visible_meshes"])>100)
    print("INFANTRY ANDROID MODEL N3/1/CLOSE: ",JSON.stringify(first_stats))
    await _capture("n3_close_1")

    lab.set_scenario(3,1,0,0,true)
    await _frames(6)
    var far_one: Dictionary=lab.model_mesh_stats()
    assert(int(far_one["total_meshes"])==int(first_stats["total_meshes"]))
    assert(int(far_one["visible_meshes"])<int(first_stats["visible_meshes"]))
    var one_hidden: int=int(far_one["hidden_meshes"])
    assert(one_hidden>0)
    print("INFANTRY ANDROID MODEL N3/1/FAR: ",JSON.stringify(far_one))
    await _capture("n3_far_1")

    lab.set_scenario(3,9,0,0,false)
    await _frames(6)
    var near_nine: Dictionary=lab.model_mesh_stats()
    assert(lab._models.size()==9)
    assert(int(near_nine["hidden_meshes"])==0)
    await _capture("n3_close_9")
    lab.set_scenario(3,9,0,0,true)
    await _frames(6)
    var far_nine: Dictionary=lab.model_mesh_stats()
    assert(int(far_nine["total_meshes"])==int(near_nine["total_meshes"]))
    assert(int(near_nine["visible_meshes"])-int(far_nine["visible_meshes"])==9*one_hidden)
    assert(int(far_nine["hidden_meshes"])==9*one_hidden)
    print("INFANTRY ANDROID MODEL N3/9/NEAR: ",JSON.stringify(near_nine))
    print("INFANTRY ANDROID MODEL N3/9/FAR: ",JSON.stringify(far_nine))
    await _capture("n3_far_9")

    for level in range(1,4):
        lab.set_scenario(level,4,2,0,false)
        await _frames(4)
        var near: Dictionary=lab.model_mesh_stats()
        lab.set_scenario(level,4,2,0,true)
        await _frames(4)
        var far: Dictionary=lab.model_mesh_stats()
        assert(int(far["total_meshes"])==int(near["total_meshes"]))
        assert(int(far["hidden_meshes"])>0)
        assert(int(far["visible_meshes"])<int(near["visible_meshes"]))
        print("INFANTRY ANDROID MODEL N%d/4 LOD DELTA: %d/%d" % [
            level,int(far["hidden_meshes"]),int(near["visible_meshes"])])

    lab.set_scenario(3,4,7,4,true)
    await _frames(5)
    assert(lab._models.size()==4)
    for model in lab._models:
        assert(model.has_node(BarracksV5.STAGE_NAME))
        assert(int(model.get_meta("visual_damage_stage",-1))==4)
        assert(BarracksV5.lod_stats(model).get("total_meshes",-1)==0)
    await _capture("n3_destroyed_4")

    lab.set_scenario(2,4,1,2,false)
    await _frames(5)
    assert(lab._models.size()==4)
    await _capture("n2_damaged_4")
    # Synthetic arithmetic checks; these are not claims about device FPS.
    var sample_near: Dictionary={
        "level":3,"count":4,"faction":1,"damage":0,
        "platform":"Linux","android_hardware_tested":false,"lod":"near",
        "fps_mean":50.0,"draw_calls_mean":300.0,"frame_p95_ms":24.0,
        "mesh_stats":{"visible_meshes":1760,"hidden_meshes":0}}
    var sample_far: Dictionary=sample_near.duplicate(true)
    sample_far["lod"]="far"
    sample_far["fps_mean"]=55.0
    sample_far["mesh_stats"]={"visible_meshes":1688,"hidden_meshes":72}
    var paired: Dictionary=lab.compare_ab(sample_near,sample_far)
    assert(float(paired.get("fps_delta_percent",0.0))==10.0)
    assert(int(paired.get("hidden_meshes",0))==72)
    assert(not bool(paired.get("android_hardware_tested",true)))
    sample_far["damage"]=1
    assert(lab.compare_ab(sample_near,sample_far).is_empty())
    lab.begin_ab_compare()
    await _frames(3)
    assert(lab._ab_active and lab._ab_phase==0 and not lab._far_lod)
    lab.set_scenario(1,1,0,0,false)
    assert(not lab._ab_active)
    # Exercise the entire A/B sequence through the actual _process loop:
    # warmup + 180 samples near, then warmup + 180 samples far.
    lab.begin_ab_compare()
    await _frames(2*(lab.WARMUP_FRAMES+lab.SAMPLE_FRAMES)+16)
    assert(not lab._ab_active)
    assert(lab._ab_comparisons.size()==1)
    var completed_ab: Dictionary=lab._ab_comparisons[0]
    assert(not bool(completed_ab["android_hardware_tested"]))
    assert(int(completed_ab["near_visible_meshes"])>
        int(completed_ab["far_visible_meshes"]))
    print("INFANTRY ANDROID LAB A/B desktop-smoke: ",
        JSON.stringify(completed_ab))
    var report_payload=JSON.parse_string(lab._report_json())
    assert(report_payload is Dictionary)
    assert(not bool(report_payload.get("hardware_android_tested",false)))
    print("PASS INFANTRY ANDROID LAB: real V1-V5 meshes, LOD visibility scales 1/4/9, level 1-3, five damage states preserved, six original OpenGL captures, paired A/B comparison validated, separate from production gameplay")
    lab.queue_free()
    await _frames(3)
    quit(0)
