extends SceneTree

# Godot 4.3 REAL geometry QA for G15 V5, including five native damage
# states. ALL damage is art-only, no combat or game-state mutations.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const V5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const OUT="res://build/qa/g15-v5"
var failures:int=0
var images:int=0

func check(condition:bool,label:String)->void:
    if not condition:
        failures+=1
        push_error("G15 V5 DAMAGE ART: "+label)

func _initialize()->void:
    call_deferred("_run")

func _capture(file_name:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var pic:Image=root.get_texture().get_image()
    check(pic!=null and pic.get_width()>=800 and pic.get_height()>=600,
        "native Godot V5 screenshot "+file_name)
    if pic!=null:
        var output=ProjectSettings.globalize_path(
            OUT.path_join(file_name+".png"))
        check(pic.save_png(output)==OK,"saved actual frame "+file_name)
        images+=1

func _pixel_difference(a_name:String,b_name:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a_name+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b_name+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var differences:int=0
    for y in range(0,a.get_height(),3):
        for x in range(0,a.get_width(),3):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.13:
                differences+=1
    return differences

func _run()->void:
    root.size=Vector2i(1024,768)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "native capture folder")
    var world:=Node3D.new()
    root.add_child(world)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=5.5
    world.add_child(cam)
    cam.current=true
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-47,-35,0)
    light.light_energy=2.05
    world.add_child(light)
    var light2:=DirectionalLight3D.new()
    light2.rotation_degrees=Vector3(-28,127,0)
    light2.light_energy=0.72
    world.add_child(light2)
    var atmosphere:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#263642")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#a9bbc8")
    env.ambient_light_energy=0.70
    atmosphere.environment=env
    world.add_child(atmosphere)
    var paints:Dictionary={}
    for faction in range(8):
        for art_level in [8,13]:
            var high:bool=art_level==13
            var model:Node3D=Models.build("ew_mobile",faction,true,art_level)
            check(model!=null,"G15 native 3D faction %d LOD%d" % [
                faction,art_level])
            if model==null:
                continue
            check(bool(model.get_meta(V4.FLAG,false)) and
                bool(model.get_meta(V5.FLAG,false)),
                "real antenna V4 and damage V5 built together")
            check(bool(model.get_meta("tarvoka_g15_v5_art_only",false)),
                "no added gameplay logic")
            var finishing:=model.find_child(V5.SHELL,true,false) as Node3D
            var hinge:=model.find_child(V5.HINGE,true,false) as Node3D
            var damaged:=model.find_child(V5.DAMAGE,true,false) as Node3D
            var antenna:=model.find_child(V4.ARRAY,true,false) as Node3D
            check(finishing!=null and finishing.get_parent()==antenna,
                "finished steel surface tracks rotated EW antenna")
            check(hinge!=null and hinge.get_parent()==
                model.find_child(V1.MAST,true,false),
                "mechanical hinge follows actual folding mast")
            check(damaged!=null and damaged.get_parent()==antenna,
                "damage fragments ride the REAL antenna pivot")
            var enamel:=model.find_child("G15_V5_FactionEdge_-1",
                true,false) as MeshInstance3D
            check(enamel!=null and
                enamel.material_override is StandardMaterial3D,
                "native metallic faction enamel integrated into antenna")
            if enamel!=null:
                paints[(enamel.material_override as StandardMaterial3D).
                    albedo_color.to_html()]=true
            var marks:int=0
            var shards:int=0
            for child in damaged.get_children():
                if str(child.name).begins_with(V5.IMPACT):
                    marks+=1
                if str(child.name).begins_with(V5.FRAGMENT):
                    shards+=1
            check(marks==(4 if high else 2) and shards==3,
                "damage geometry preserved in hero and Android LOD")
            for stage in range(5):
                check(V5.set_damage(model,stage),
                    "art-only persistent damage stage %d" % stage)
                check(int(model.get_meta("tarvoka_g15_v5_visual_damage",-1))
                    ==stage,"damage stage saved in preview metadata")
                var n:int=0
                for child in damaged.get_children():
                    if str(child.name).begins_with(V5.FRAGMENT) and child.visible:
                        n+=1
                check(n==(3 if stage>=3 else 0),
                    "fracture fragments appear only on high visual damage")
                if stage==4:
                    check(absf(antenna.rotation_degrees.z)>=30.0 and
                        antenna.position.y<-0.1,
                        "heavy destruction deforms 3D array rather than a label")
            check(V5.reset_damage(model) and
                antenna.position==Vector3.ZERO and
                antenna.rotation==Vector3.ZERO,
                "art-only repair fully restores physical antenna")
            check(Models.pose_model("ew_mobile",model,"damage",0.71),
                "existing impact animation now blends into V5 damage stages")
            check(int(model.get_meta("tarvoka_g15_v5_visual_damage",0))>=2,
                "V1 impact animation drives new physical damage")
            Models.restore_model_pose("ew_mobile",model)
            check(int(model.get_meta("tarvoka_g15_v5_visual_damage",9))==0,
                "old restore resets new V5 damage and previous V1-V4 rig")
            check(Models.pose_model("ew_mobile",model,"scan",0.35),
                "antenna scan still works with new physical armor and damage")
            Models.restore_model_pose("ew_mobile",model)
            check(V5.show_finish(model,false) and not finishing.visible,
                "V4 historical view hides V5 mechanical surface finish")
            check(V5.show_finish(model,true) and finishing.visible,
                "V5 finish restored without reconstruction")
            if high and faction in [0,3]:
                world.add_child(model)
                for view in range(2):
                    cam.position=(
                        Vector3(4.7,4.0,-5.6) if view==0 else
                        Vector3(-5.3,3.85,5.2))
                    cam.look_at(Vector3(0,1.98,0))
                    for stage in [0,2,4]:
                        check(V5.set_damage(model,stage),
                            "native destruction stage before capture")
                        await _capture("g15-f%02d-a%d-damage%d" % [
                            faction,view,stage])
                    var stamp:String="g15-f%02d-a%d-damage" % [faction,view]
                    check(_pixel_difference(stamp+"0",stamp+"2")>40,
                        "moderate damage MUST be visible in real Godot pixels")
                    check(_pixel_difference(stamp+"0",stamp+"4")>150,
                        "catastrophic antenna failure MUST differ visibly")
                world.remove_child(model)
                model.free()
            else:
                model.free()
    check(paints.size()==8,"all eight approved faction colors unchanged")
    check(images==12,
        "12 real Godot images: two factions x two angles x three damages")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v5-manifest.json")),FileAccess.WRITE)
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "unit":"G15 war electronic original native 3D",
            "version":"V5 physical antenna panel detailing + five visual damage stages",
            "factions":8,"mobile_lod":8,"hero_lod":13,
            "damage_visual_only":true,
            "ready_for_final_approval":false,
            "images":images,"failures":failures
        },"  "))
        manifest.close()
    world.queue_free()
    await process_frame
    print(("PASS G15 V5 NATIVE 3D:" if failures==0
        else "FAIL G15 V5 NATIVE 3D:")+
        " 5 art-only damage stages, metallic finish, mast hinges, 8 factions, 2 LODs, 12 real Godot renders, failures=%d" % failures)
    quit(1 if failures>0 else 0)
