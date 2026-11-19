extends SceneTree

# G15 V9: regression guard on actual Godot 4.3 G15 build and rendered pixels.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const V8=preload("res://scripts/ui/G15ContinuitySuspensionV8.gd")
const V9=preload("res://scripts/ui/G15ProductionSurfaceV9.gd")
const OUT="res://build/qa/g15-v9"
var fails:int=0
var frames:int=0
var colors:Dictionary={}
func ck(ok:bool,label:String)->void:
    if not ok:
        fails+=1
        push_error("G15 V9 CHECK: "+label)
func _initialize()->void:
    call_deferred("_run")
func _capture(name:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=root.get_texture().get_image()
    ck(img!=null and img.get_width()>=800,"real render "+name)
    if img!=null:
        ck(img.save_png(ProjectSettings.globalize_path(
            OUT.path_join(name+".png")))==OK,"image stored "+name)
        frames+=1
func _difference(a_name:String,b_name:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(a_name+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUT.path_join(b_name+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var result:int=0
    for y in range(0,a.get_height(),3):
        for x in range(0,a.get_width(),3):
            var c:Color=a.get_pixel(x,y)
            var d:Color=b.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.16:
                result+=1
    return result
func _run()->void:
    root.size=Vector2i(1024,768)
    ck(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"render folder")
    var stage:=Node3D.new()
    root.add_child(stage)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.65
    stage.add_child(camera)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-28,0)
    sun.light_energy=2.0
    stage.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,130,0)
    fill.light_energy=0.91
    stage.add_child(fill)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#293641")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#acc1ca")
    env.ambient_light_energy=0.77
    world.environment=env
    stage.add_child(world)
    for faction in range(8):
        for quality in [8,13]:
            var hero:bool=quality==13
            var model:Node3D=Models.build("ew_mobile",faction,true,quality)
            ck(model!=null,"all faction and LOD vehicles build")
            if model==null:
                continue
            ck(V1.has_model(model) and
                bool(model.get_meta(V8.FLAG,false)) and
                bool(model.get_meta(V9.FLAG,false)),"G15 all revisions through V9")
            ck(bool(model.get_meta("tarvoka_g15_v9_no_gameplay_changes",false)),
                "no gameplay hooks")
            ck(int(model.get_meta(
                "tarvoka_g15_v9_original_materials",0))==16,
                "16 original armored and rubber materials are reversible")
            var wheels:=model.find_child(V1.WHEEL_GROUP,true,false) as Node3D
            ck(wheels!=null and wheels.get_child_count()==6,
                "six original wheel pivots retained")
            for node in wheels.get_children():
                var pivot:=node as Node3D
                var token:String=str(pivot.name).trim_prefix("G15_Wheel_")
                var tread:=pivot.find_child(V9.WHEEL_PREFIX+token,
                    false,false) as MultiMeshInstance3D
                var ring:=pivot.find_child(V9.RIM_PREFIX+token,
                    false,false) as MeshInstance3D
                ck(tread!=null and ring!=null,
                    "real molded tread with metallic rim for six wheels")
                if tread!=null:
                    ck(tread.multimesh.instance_count==(40 if hero else 16),
                        "batched hero/Android instancing correct")
                    var mat:=tread.material_override as StandardMaterial3D
                    ck(mat!=null and mat.metallic==0.0 and
                        mat.roughness>0.90,"tire is rubber, never metal")
            var steel:=model.find_child(
                "G15_V6_SculptedSideArmor_-1",
                true,false) as MeshInstance3D
            ck(steel!=null and
                steel.material_override is StandardMaterial3D,
                "solid steel now uses real PBR material")
            if steel!=null:
                var coating:=steel.material_override as StandardMaterial3D
                ck(coating.albedo_texture!=null and coating.uv1_triplanar,
                    "physically mapped PBR grain is present")
            var enamel:=model.find_child(
                "G15_V9_FactionElectronicsBar_-1",
                true,false) as MeshInstance3D
            if enamel!=null:
                var color:=enamel.material_override as StandardMaterial3D
                colors[color.albedo_color.to_html()]=true
            ck(Models.pose_model("ew_mobile",model,"move",0.46),
                "wheels and spring motion remains")
            ck(Models.pose_model("ew_mobile",model,"deploy",0.42),
                "original EW hydraulics remain")
            ck(Models.pose_model("ew_mobile",model,"damage",0.74),
                "V5 visual destruction not broken")
            Models.restore_model_pose("ew_mobile",model)
            ck(int(model.get_meta("tarvoka_g15_v5_visual_damage",-1))==0,
                "damage resets properly")
            if hero and faction in [0,3]:
                stage.add_child(model)
                for view in range(3):
                    camera.position=(
                        Vector3(5.4,3.4,-5.25) if view==0 else
                        Vector3(-5.55,3.25,4.65) if view==1 else
                        Vector3(5.2,2.3,1.2))
                    camera.look_at(Vector3(0,1.40,0))
                    var stem:String="g15-f%02d-view%d" % [faction,view]
                    ck(V9.show_finish(model,false),"V8 reversible")
                    await _capture(stem+"-v8")
                    ck(V9.show_finish(model,true),"V9 reversible")
                    await _capture(stem+"-v9")
                    ck(_difference(stem+"-v8",stem+"-v9")>40,
                        "real Godot camera sees changed PBR or wheel finish")
                stage.remove_child(model)
                model.free()
            else:
                ck(V9.show_finish(model,false),"V8 reversible LOD")
                ck(V9.show_finish(model,true),"V9 reversible LOD")
                model.free()
    ck(colors.size()==8,"faction original enamel all eight colors")
    ck(frames==12,"12 comparative Godot PNGs")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUT.path_join("g15-v9-manifest.json")),FileAccess.WRITE)
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "revision":"G15 V9","factions":8,"lods":[8,13],
            "real_pngs":frames,
            "hero_real_tread_blocks":240,
            "mobile_real_tread_blocks":96,
            "gameplay_changes":false,"errors":fails
        },"  "))
        manifest.close()
    stage.queue_free()
    await process_frame
    if fails==0:
        print("PASS G15 V9 NATIVE 3D: satin armor grain, six sculpted tires, original EW animation, eight factions, Android LOD, 12 Godot renders")
    else:
        print("FAIL G15 V9 NATIVE 3D: %d findings" % fails)
    quit(1 if fails>0 else 0)
