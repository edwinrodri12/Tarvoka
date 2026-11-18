extends SceneTree

# Genuine Godot 4.3 3D QA for G15 V8, including original six
# wheel pivots, swept closed transition armor and helix mesh springs.
# 8 faction paints; Android LOD8 and hero LOD13. No gameplay changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const V7=preload("res://scripts/ui/G15MechanicalExteriorV7.gd")
const V8=preload("res://scripts/ui/G15ContinuitySuspensionV8.gd")
const OUT="res://build/qa/g15-v8"
var findings:int=0
var screenshots:int=0
var colors:Dictionary={}

func check(ok:bool,claim:String)->void:
    if not ok:
        findings+=1
        push_error("G15 V8 NATIVE ART: "+claim)

func _initialize()->void:
    call_deferred("_run")

func _capture(name:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var shot:Image=root.get_texture().get_image()
    check(shot!=null and shot.get_width()>=800 and shot.get_height()>=600,
        "real Godot screenshot "+name)
    if shot!=null:
        check(shot.save_png(ProjectSettings.globalize_path(
            OUT.path_join(name+".png")))==OK,
            "capture persisted "+name)
        screenshots+=1

func _difference(a_name:String,b_name:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a_name+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b_name+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var diffs:int=0
    for y in range(0,a.get_height(),3):
        for x in range(0,a.get_width(),3):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.145:
                diffs+=1
    return diffs

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "screenshot directory created")
    var scene:=Node3D.new()
    root.add_child(scene)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.5
    scene.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-46,-31,0)
    sun.light_energy=2.20
    scene.add_child(sun)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-25,135,0)
    light.light_energy=0.87
    scene.add_child(light)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#27343f")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#aabdc5")
    env.ambient_light_energy=0.71
    world.environment=env
    scene.add_child(world)

    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:Node3D=Models.build("ew_mobile",faction,true,lod)
            check(model!=null,"G15 faction%d LOD%d spawned" % [
                faction,lod])
            if model==null:
                continue
            check(V1.has_model(model) and
                bool(model.get_meta(V7.FLAG,false)) and
                bool(model.get_meta(V8.FLAG,false)),
                "V1-V7 geometry preserved and V8 applied")
            check(bool(model.get_meta("tarvoka_g15_v8_all_visual_only",false)),
                "no new weapons, battle logic or EW abilities")
            check(bool(model.get_meta(
                "tarvoka_g15_v8_suspension_pivots_untouched",false)),
                "wheel pivots remain original")
            var chassis:=model.find_child(V1.CHASSIS,true,false) as Node3D
            var pivots:=model.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            var finish:=model.find_child(V8.ASSEMBLY,true,false) as Node3D
            check(chassis!=null and finish!=null and
                finish.get_parent()==chassis,
                "V8 integrated in actual chassis hierarchy")
            check(pivots!=null and pivots.get_child_count()==6,
                "all 6 authentic movable wheels remain")
            var original:Array[Vector3]=[]
            for wheel in pivots.get_children():
                original.append((wheel as Node3D).position)
            for group in [V8.ARMOR,V8.METAL,V8.SUSPENSION]:
                check(model.find_child(group,true,false) is Node3D,
                    "separable physical group "+group)
            for side in [-1,1]:
                var id:String=str(side)
                var transition:=model.find_child(
                    "G15_V8_ClosedCabShelterBridge_"+id,
                    true,false) as MeshInstance3D
                check(transition!=null and
                    transition.mesh is ArrayMesh,
                    "true non-planar cab-to-shelter armor transition")
                if transition!=null and transition.mesh is ArrayMesh:
                    check(transition.mesh.get_faces().size()==36,
                        "fully capped closed transition with 12 triangles")
                    var range3:Vector3=transition.mesh.get_aabb().size
                    check(range3.y>0.43 and range3.z>0.47 and range3.x>0.2,
                        "the new transition spans genuine volume in 3 axes")
                var belt:=model.find_child(
                    "G15_V8_ContinuousSideBelt_"+id,
                    true,false) as MeshInstance3D
                check(belt!=null and belt.mesh is BoxMesh and
                    belt.position.y<1.13,
                    "continuous solid lower belt doesn't hide faction")
                var enamel:=model.find_child(
                    "G15_V8_FactionServicePip_"+id,
                    true,false) as MeshInstance3D
                check(enamel!=null and
                    enamel.material_override is StandardMaterial3D,
                    "new structural metal carries original faction enamel")
                if enamel!=null:
                    var mat:=enamel.material_override as StandardMaterial3D
                    colors[mat.albedo_color.to_html()]=true
                    check(absf(enamel.position.x)>0.87,
                        "faction paint physically above side steel")
                for axle in range(3):
                    var suffix:String="%s_%d" % [id,axle]
                    var core:=model.find_child(
                        "G15_V8_ShockChromedCore_"+suffix,
                        true,false) as MeshInstance3D
                    var spring:=model.find_child(
                        "G15_V8_RealCoilSpring_"+suffix,
                        true,false) as MeshInstance3D
                    var mobile:=model.find_child(
                        "G15_V8_MobileSpringSleeve_"+suffix,
                        true,false) as MeshInstance3D
                    check(core!=null and core.mesh is CylinderMesh,
                        "real metallic shock absorbers for each wheel")
                    check((spring!=null)==hero and (mobile!=null)!=hero,
                        "hero has 6 physical 5-turn coils; mobile has sleeves")
                    if spring!=null:
                        check(spring.mesh is ArrayMesh and
                            spring.mesh.get_faces().size()==45*7*6,
                            "3D helical tube has 1890 vertices per spring")
                        var old_wheel:=pivots.find_child(
                            "G15_Wheel_"+suffix,false,false) as Node3D
                        check(old_wheel!=null and old_wheel.get_parent()==pivots,
                            "original rotating tire remains independent")
            check(Models.pose_model("ew_mobile",model,"move",0.65),
                "V1 wheel turning animation still valid")
            check(Models.pose_model("ew_mobile",model,"deploy",0.55),
                "V4 hydraulic fold and deployment preserved")
            check(Models.pose_model("ew_mobile",model,"scan",0.40),
                "V4 antenna search unchanged by V8")
            check(Models.pose_model("ew_mobile",model,"damage",0.76),
                "V5 damaged antenna still animates")
            Models.restore_model_pose("ew_mobile",model)
            check(int(model.get_meta("tarvoka_g15_v5_visual_damage",-1))==0,
                "damage state restores with V8 present")
            for i in range(pivots.get_child_count()):
                check((pivots.get_child(i) as Node3D).position==original[i],
                    "no wheel pivot displaced by new suspension")
            check(V8.show_finish(model,false) and not finish.visible,
                "historical V7 model reversible")
            check(V8.show_finish(model,true) and finish.visible,
                "native V8 model restored intact")
            if hero and faction in [0,3]:
                scene.add_child(model)
                for angle in range(3):
                    camera.position=(
                        Vector3(5.35,3.18,-5.16) if angle==0 else
                        (Vector3(-5.28,2.90,4.8) if angle==1 else
                         Vector3(5.15,2.0,1.0)))
                    camera.look_at(Vector3(0,1.38,-0.18))
                    var stem:String="g15-f%02d-view%d" % [faction,angle]
                    check(V8.show_finish(model,false),"V7 photo without V8")
                    await _capture(stem+"-v7")
                    check(V8.show_finish(model,true),"V8 photo with new surfaces")
                    await _capture(stem+"-v8")
                    check(_difference(stem+"-v7",stem+"-v8")>35,
                        "visible before/after 3D difference in rendered pixels")
                scene.remove_child(model)
                model.free()
            else:
                model.free()
    check(colors.size()==8,"all eight faction paint colors preserved")
    check(screenshots==12,"12 real Godot V7-V8 comparison screenshots")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v8-manifest.json")),FileAccess.WRITE)
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "model":"G15 EW 6x6 native 3D","version":"V8",
            "closed_armor_transition_per_side":true,
            "hero_springs":6,"spring_turns":5,"mobile_sleeves":6,
            "factions":8,"lods":[8,13],
            "images":screenshots,
            "gameplay_changes":false,
            "final_approved":false,
            "errors":findings
        },"  "))
        manifest.close()
    scene.queue_free()
    await process_frame
    if findings==0:
        print("PASS G15 V8 NATIVE 3D: closed cab-shelter transitional armor, satin metal, 6 visible 3D coils, 8 factions, 2 Android LODs, 12 authentic Godot renders")
    else:
        print("FAIL G15 V8 NATIVE 3D: %d conditions" % findings)
    quit(1 if findings>0 else 0)
