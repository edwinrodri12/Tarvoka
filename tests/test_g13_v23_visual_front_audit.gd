extends SceneTree

# G13 V23 real Godot 3D optical-inspection dossier, NOT 2D concept art.
# The same mesh is captured with its V23 parts ON/OFF, with identical
# camera pose, faction paint, light source, and renderer. No gameplay edits.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Front=preload("res://scripts/ui/G13FrontLightingV23.gd")
const Intake=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")

const CAPTURES:=27
var failures:int=0
var saved:int=0
var comparisons:Dictionary={}

func require(value:bool,message:String)->void:
    if not value:
        failures+=1
        push_error("G13 V23 front visual audit: "+message)

func picture(view:SubViewport,folder:String,name:String)->Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=view.get_texture().get_image()
    require(img!=null and not img.is_empty(),"native Godot image "+name)
    if img==null or img.is_empty():
        return null
    var ok:bool=img.save_png(folder.path_join(name+".png"))==OK
    require(ok,"PNG written "+name)
    if ok:
        saved+=1
    return img

func image_delta(before:Image,after:Image)->Dictionary:
    if before==null or after==null or before.get_size()!=after.get_size():
        return {"changed":0,"mae":0.0,"sampled":0}
    var changed:int=0
    var sampled:int=0
    var difference:float=0.0
    for y in range(0,before.get_height(),4):
        for x in range(0,before.get_width(),4):
            var a:Color=before.get_pixel(x,y)
            var b:Color=after.get_pixel(x,y)
            var d:float=(
                absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
            difference+=d
            sampled+=1
            if d>0.045:
                changed+=1
    return {
        "changed":changed,
        "mae":difference/float(maxi(sampled,1)),
        "sampled":sampled
    }

func frame_camera(cam:Camera3D,origin:Vector3,target:Vector3,height:float)->void:
    cam.position=origin
    cam.size=height
    cam.look_at(target,Vector3.UP)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:String=OS.get_environment("G13_V23_VISUAL_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v23-front-review"
    require(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create authentic 3D capture output")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1080,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#283641")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#bdcdd5")
    env.ambient_light_energy=0.7
    environment.environment=env
    viewport.add_child(environment)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-50,-35,0)
    key.light_energy=1.36
    viewport.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-29,132,0)
    fill.light_energy=0.46
    viewport.add_child(fill)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.current=true
    viewport.add_child(cam)
    var configurations:Dictionary={
        "front":[Vector3(0,1.07,-4.2),Vector3(0,0.90,-1.0),1.40],
        "front_low":[Vector3(0,0.66,-4.3),Vector3(0,0.86,-1.0),1.44],
        "front_left":[Vector3(-2.3,1.47,-3.8),Vector3(-0.25,0.91,-1.0),1.63],
        "front_right":[Vector3(2.3,1.47,-3.8),Vector3(0.25,0.91,-1.0),1.63],
        "front_high":[Vector3(0.7,2.8,-3.3),Vector3(0,0.95,-0.9),1.67],
        "full_iso":[Vector3(3.8,3.0,4.2),Vector3(0,1.03,0),4.65]
    }
    # Every faction uses precisely the approved V23 model; same optical
    # family, original emblem/paint and no new unit category or weapons.
    for faction in range(8):
        var unit:=Models.build("aa_mobile",faction,true,13)
        require(unit!=null,"faction %d native high-detail G13" % faction)
        if unit==null:
            continue
        require(bool(unit.get_meta(Front.FLAG,false)) and
            str(unit.get_meta("tarvoka_g13_v23_weapon_identity",""))==
                "twin_autocannon_no_missiles",
            "faction %d preserves weapons and genuine V23" % faction)
        viewport.add_child(unit)
        Intake.show_v23_reference(unit,true)
        frame_camera(cam,Vector3(0,1.07,-4.2),
            Vector3(0,0.90,-1.0),1.40)
        await picture(viewport,folder,"faction_%02d_front" % faction)
        viewport.remove_child(unit)
        unit.free()

    var hero:=Models.build("aa_mobile",0,true,13)
    require(hero!=null,"primary G13 sculpt exists")
    if hero==null:
        quit(1)
        return
    viewport.add_child(hero)
    # This historical V22/V23 test must disable V24 across both images.
    require(Intake.show_v23_reference(hero,true),
        "historical V23 reference excludes later sculpt V24")
    for side in [-1,1]:
        var frame:=hero.find_child(Front.RIM % side,true,false) as MeshInstance3D
        var lens:=hero.find_child(Front.LENS % side,true,false) as MeshInstance3D
        var old:=hero.find_child("G13_Lamp_%d" % side,true,false) as MeshInstance3D
        require(frame!=null and lens!=null and old!=null,
            "pair of 3D lamps anchored on original front face")
        if frame!=null and lens!=null and old!=null:
            require(frame.position.is_equal_approx(old.position) and (
                lens.position.is_equal_approx(old.position)),
                "bezel and lens fitted on inherited exact lamp center")
            require(frame.get_parent()==old.get_parent() and (
                lens.get_parent()==old.get_parent()),
                "optics linked to real chasis hull")
            var frame_aabb:AABB=frame.mesh.get_aabb()
            var lens_aabb:AABB=lens.mesh.get_aabb()
            # The lens face is 8mm behind the front of the protective metal;
            # the metal's backside overlaps the source body footprint.
            require(lens_aabb.position.z>frame_aabb.position.z+0.006,
                "optics sit INSIDE armor, not in front of metal flange")
            require(frame_aabb.end.z>old.mesh.get_aabb().position.z-0.05,
                "back of headlight bezel extends into original lamp footprint")
            require(lens_aabb.size.x<frame_aabb.size.x and (
                lens_aabb.size.y<frame_aabb.size.y),
                "optical glass fully housed within protective rim")
    var directions:Array[String]=[
        "front","front_low","front_left","front_right",
        "front_high","full_iso"
    ]
    for direction in directions:
        var config:Array=configurations[direction]
        frame_camera(cam,config[0],config[1],float(config[2]))
        Models.restore_model_pose("aa_mobile",hero)
        require(Front.compare_v22(hero,true),
            "V22 authentic before for "+direction)
        var original:Image=await picture(viewport,folder,
            "compare_%s_v22" % direction)
        require(Front.compare_v22(hero,false),
            "V23 authentic after for "+direction)
        var finished:Image=await picture(viewport,folder,
            "compare_%s_v23" % direction)
        var diff:Dictionary=image_delta(original,finished)
        comparisons[direction]=diff
        # The full-isometric model is intentionally farther away and the
        # lighting elements occupy only a few pixels; test close-up views.
        if direction in ["front","front_low","front_left","front_right"]:
            require(int(diff["changed"])>=20,
                "same-camera front V23 is visibly different from V22 "
                +direction+" changed="+str(diff["changed"]))
        require(float(diff["mae"])<0.12,
            "V23 is a local headlight improvement, not a global color swap")

    frame_camera(cam,Vector3(0,1.1,-4),Vector3(0,0.9,-1),1.65)
    require(Models.pose_model("aa_mobile",hero,"attack_ground",0.42,
        Vector2i(0,-1)),"ground-fire pose untouched")
    await picture(viewport,folder,"attack_ground_front")
    require(Models.pose_model("aa_mobile",hero,"attack_air",0.42,
        Vector2i(0,-1)),"air-fire pose untouched")
    await picture(viewport,folder,"attack_air_front")
    Models.restore_model_pose("aa_mobile",hero)

    frame_camera(cam,Vector3(-1.6,1.04,-2.8),
        Vector3(-0.50,0.85,-1.245),0.78)
    await picture(viewport,folder,"macro_left_headlight")
    frame_camera(cam,Vector3(1.6,1.04,-2.8),
        Vector3(0.50,0.85,-1.245),0.78)
    await picture(viewport,folder,"macro_right_headlight")

    env.background_color=Color("#090f19")
    env.ambient_light_energy=0.07
    key.light_energy=0.13
    fill.light_energy=0.03
    frame_camera(cam,Vector3(0,1.07,-4.2),
        Vector3(0,0.90,-1.0),1.40)
    await picture(viewport,folder,"night_front_optics")
    frame_camera(cam,Vector3(2.3,1.47,-3.8),
        Vector3(0.25,0.91,-1.0),1.63)
    await picture(viewport,folder,"night_front_right")
    env.ambient_light_energy=0.7
    key.light_energy=1.36
    fill.light_energy=0.46

    viewport.remove_child(hero)
    hero.free()
    var mobile:=Models.build("aa_mobile",0,true,8)
    require(mobile!=null,"LOD8 Android geometry remains available")
    if mobile!=null:
        require(not bool(mobile.get_meta(Front.FLAG,false)),
            "no V23 extra meshes on Android LOD8")
        viewport.add_child(mobile)
        frame_camera(cam,Vector3(3.8,3.0,4.2),
            Vector3(0,1.03,0),4.65)
        await picture(viewport,folder,"android_lod8_baseline")
        viewport.remove_child(mobile)
        mobile.free()

    require(saved==CAPTURES,"exactly 27 real 3D captures, got "+str(saved))
    var report:Dictionary={
        "art_revision":"G13 V23",
        "reference":"G13 V22",
        "captured":saved,
        "factions":8,
        "approved_weapon_identity":"twin_autocannon_no_missiles",
        "front_view_differences":comparisons,
        "android_lod8_modified":false,
        "gameplay_modified":false,
        "failed_checks":failures
    }
    var out:=FileAccess.open(folder.path_join(
        "g13-v23-front-visual-report.json"),FileAccess.WRITE)
    require(out!=null,"write reproducible 3D review metrics")
    if out!=null:
        out.store_string(JSON.stringify(report,"  ")+"\n")
        out.close()
    if failures>0:
        print("FAIL G13 V23 FRONT VISUAL AUDIT: ",failures,
            " failures; ",saved," PNGs; ",JSON.stringify(comparisons))
        quit(1)
        return
    print("PASS G13 V23 FRONT VISUAL AUDIT: ",saved,
        " real Godot PNGs; 8 factions; 6 matching camera pairs; ",
        "ground/air attacks; low light; independent true 3D light housings; ",
        "unchanged LOD8; delta=",JSON.stringify(comparisons))
    quit(0)
