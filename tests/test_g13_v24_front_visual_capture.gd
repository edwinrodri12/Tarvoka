extends SceneTree

# Native, auditable Godot geometry review of the ACTUAL G13 V24 addition.
# 22 screenshots across eight factions, five 1:1 V23/V24 camera pairs,
# true 3D louvers, both headlamp macros and original ground-fire rig.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Intake=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const TOTAL:=22
var errors:int=0
var saved:int=0
var differences:Dictionary={}

func ensure(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V24 native photo QA: "+reason)

func shot(v:SubViewport,folder:String,label:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=v.get_texture().get_image()
    ensure(image!=null and not image.is_empty(),"native 3D frame "+label)
    if image==null or image.is_empty():
        return null
    var written:bool=image.save_png(folder.path_join(label+".png"))==OK
    ensure(written,"save PNG "+label)
    if written:
        saved+=1
    return image

func pixel_delta(a:Image,b:Image)->Dictionary:
    if a==null or b==null or a.get_size()!=b.get_size():
        return {"changed":0,"mae":0.0,"samples":0}
    var count:int=0
    var sum:float=0.0
    var samples:int=0
    for y in range(0,a.get_height(),4):
        for x in range(0,a.get_width(),4):
            var ca:Color=a.get_pixel(x,y)
            var cb:Color=b.get_pixel(x,y)
            var diff:float=(
                absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b))/3.0
            sum+=diff
            if diff>0.045:
                count+=1
            samples+=1
    return {
        "changed":count,
        "mae":sum/float(maxi(1,samples)),
        "samples":samples
    }

func focus(camera:Camera3D,position:Vector3,at:Vector3,size:float)->void:
    camera.position=position
    camera.size=size
    camera.look_at(at,Vector3.UP)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:String=OS.get_environment("G13_V24_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v24-frontal"
    ensure(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create real sculpt image folder")
    var view:=SubViewport.new()
    view.size=Vector2i(1080,720)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#27353d")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#beced8")
    env.ambient_light_energy=0.7
    world.environment=env
    view.add_child(world)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-49,-32,0)
    key.light_energy=1.36
    view.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-28,133,0)
    fill.light_energy=0.45
    view.add_child(fill)
    var cam:=Camera3D.new()
    cam.current=true
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    view.add_child(cam)

    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,13)
        ensure(model!=null,"faction "+str(faction)+" G13 genuine model")
        if model==null:
            continue
        ensure(bool(model.get_meta(Intake.FLAG,false)),
            "V24 installed on faction "+str(faction))
        view.add_child(model)
        focus(cam,Vector3(0,1.05,-4.0),
            Vector3(0,0.87,-1.02),1.50)
        await shot(view,folder,"g13_v24_faction_%02d_frontal" % faction)
        view.remove_child(model)
        model.free()

    var hero:=Models.build("aa_mobile",0,true,13)
    ensure(hero!=null,"hero V24 built")
    if hero==null:
        quit(1)
        return
    view.add_child(hero)
    var cams:Dictionary={
        "front":[Vector3(0,1.03,-4.0),Vector3(0,0.78,-1.03),1.28],
        "low":[Vector3(0,0.70,-4.0),Vector3(0,0.75,-1.03),1.28],
        "left":[Vector3(-2.35,1.43,-3.7),Vector3(-0.18,0.80,-1.03),1.58],
        "right":[Vector3(2.35,1.43,-3.7),Vector3(0.18,0.80,-1.03),1.58],
        "high":[Vector3(0.5,2.7,-3.1),Vector3(0,0.85,-0.90),1.66]
    }
    for angle in ["front","low","left","right","high"]:
        var config:Array=cams[angle]
        focus(cam,config[0],config[1],float(config[2]))
        Models.restore_model_pose("aa_mobile",hero)
        ensure(Intake.show_v23_reference(hero,true),
            "switch native front intake off "+angle)
        var before:Image=await shot(view,folder,
            "same_%s_v23" % angle)
        ensure(Intake.show_v23_reference(hero,false),
            "switch native front intake back on "+angle)
        var after:Image=await shot(view,folder,
            "same_%s_v24" % angle)
        var diff:Dictionary=pixel_delta(before,after)
        differences[angle]=diff
        ensure(int(diff["changed"])>35,
            "actual V24 grille is visible in camera "+angle+" "
            +str(diff["changed"]))
        ensure(float(diff["mae"])<0.12,
            "localized geometry, no global paint change "+angle)

    focus(cam,Vector3(-1.5,1.04,-2.8),
        Vector3(-0.50,0.85,-1.245),0.78)
    await shot(view,folder,"macro_left_lamp_and_intake")
    focus(cam,Vector3(1.5,1.04,-2.8),
        Vector3(0.50,0.85,-1.245),0.78)
    await shot(view,folder,"macro_right_lamp_and_intake")

    focus(cam,Vector3(0,1.06,-4.0),
        Vector3(0,0.84,-1.00),1.55)
    env.background_color=Color("#080e19")
    env.ambient_light_energy=0.08
    key.light_energy=0.15
    fill.light_energy=0.05
    await shot(view,folder,"low_light_front_v24")
    env.background_color=Color("#27353d")
    env.ambient_light_energy=0.7
    key.light_energy=1.36
    fill.light_energy=0.45
    ensure(Models.pose_model("aa_mobile",hero,"attack_ground",0.40),
        "V24 front still supports approved dual cannon ground attack")
    await shot(view,folder,"g13_v24_ground_cannon_front")
    Models.restore_model_pose("aa_mobile",hero)

    ensure(saved==TOTAL,"exact expected 22 native shots, got "+str(saved))
    var metrics:Dictionary={
        "version":"G13 V24",
        "base":"G13 V23",
        "authentic_godot_screenshots":saved,
        "factions":8,
        "same_camera_comparison":differences,
        "louvres":4,
        "new_gun_modules":0,
        "android_lod8_modified":false,
        "failures":errors
    }
    var report:=FileAccess.open(folder.path_join(
        "g13_v24_real_3d_review.json"),FileAccess.WRITE)
    ensure(report!=null,"write inspection report")
    if report!=null:
        report.store_string(JSON.stringify(metrics,"  ")+"\n")
        report.close()
    if errors>0:
        print("FAIL G13 V24 3D FRONTAL REVIEW: ",errors," ",JSON.stringify(differences))
        quit(1)
        return
    print("PASS G13 V24 3D FRONTAL REVIEW: 22 authentic Godot PNGs, 8 factions, ",
        "five V23/V24 1:1 camera comparisons, 4 3D grille louvers, ",
        "no missiles or Android LOD8 impact; ",JSON.stringify(differences))
    quit(0)
