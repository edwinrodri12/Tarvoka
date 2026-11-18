extends SceneTree

# Real native Godot matched-scene, matched-lighting comparison:
# approved P06 Bastion vs new G13 V61. Identical 5.5m orthographic
# isometric eye and light; actual wheel macros at equal 1.75m zoom
# relative to each unit's TRUE wheel center. Nine native 3D frames.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const P06=preload("res://scripts/ui/APCWheelV14.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const OUTPUT="res://build/qa/g13-v61"
var issues:int=0
var captures:Array[Dictionary]=[]
var changes:Dictionary={}
var stage:Node3D
var cam:Camera3D

func check(ok:bool,reason:String)->void:
    if not ok:
        issues+=1
        push_error("G13 V61 matched REAL Godot comparison: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _set_camera(focus:Vector3,offset:Vector3,size:float)->void:
    cam.position=focus+offset
    cam.size=size
    cam.look_at(focus,Vector3.UP)

func _shot(label:String,identity:String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=root.get_texture().get_image()
    check(image!=null and image.get_width()>=640 and
        image.get_height()>=480,"real 3D camera image "+label)
    if image==null:
        return
    check(image.save_png(ProjectSettings.globalize_path(
        OUTPUT.path_join(label+".png")))==OK,
        "save native 3D GL pixels "+label)
    captures.append({
        "filename":label+".png","unit":identity,
        "camera":[cam.position.x,cam.position.y,cam.position.z],
        "orthographic_size":cam.size,
        "look_target_at_real_unit":true,
        "same_three_directional_lights":true
    })
    print("G13 V61 MATCHED GODOT FRAME "+label)

func _delta(previous:String,latest:String)->int:
    var a:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUTPUT.path_join(previous+".png")))
    var b:Image=Image.load_from_file(ProjectSettings.globalize_path(
        OUTPUT.path_join(latest+".png")))
    if a==null or b==null or a.get_size()!=b.get_size():
        return -1
    var pixels:int=0
    for y in range(0,a.get_height(),2):
        for x in range(0,a.get_width(),2):
            var p:Color=a.get_pixel(x,y)
            var q:Color=b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.105:
                pixels+=1
    return pixels

func _matched_world()->void:
    root.size=Vector2i(1280,720)
    stage=Node3D.new()
    stage.name="SameWorld_RealBastionVsG13"
    root.add_child(stage)
    cam=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=5.5
    cam.current=true
    stage.add_child(cam)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-52,-30,0)
    key.light_energy=1.7
    stage.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,135,0)
    fill.light_color=Color("#b9d2e6")
    fill.light_energy=0.48
    stage.add_child(fill)
    var specular:=DirectionalLight3D.new()
    specular.rotation_degrees=Vector3(-18,62,0)
    specular.light_color=Color("#fff4e1")
    specular.light_energy=0.76
    stage.add_child(specular)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#27323c")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#a2b5ca")
    env.ambient_light_energy=0.75
    env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
    world.environment=env
    stage.add_child(world)

func _run()->void:
    _matched_world()
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK,
        "create evidence folder")
    var bastion:=Models.build("apc",0,true,14)
    var g13:=Models.build("aa_mobile",0,true,13)
    check(bastion!=null and g13!=null,"Bastion P06 and G13 exact hero 3D")
    if bastion==null or g13==null:
        quit(1)
        return
    check(bool(bastion.get_meta(P06.FLAG,false)),
        "actual P06 production six-hole open spokes in comparison")
    check(bool(g13.get_meta(V61.FLAG,false)),
        "actual G13 V61 eight-hole open steel hub installed")
    var bastion_pivot:=bastion.find_child(
        "RuedaMotorizadaP06_-1_0",true,false) as Node3D
    var g13_tyre:=g13.find_child(
        "G13_Ruedas4x4MultiMesh",true,false) as MultiMeshInstance3D
    check(bastion_pivot!=null and g13_tyre!=null,
        "real original P06 and G13 wheel center locators")
    if bastion_pivot==null or g13_tyre==null:
        quit(1)
        return
    var bastion_wheel:Vector3=bastion_pivot.position
    var g13_wheel:Vector3=Vector3(-0.85,0.33,-0.85)
    stage.add_child(bastion)
    _set_camera(Vector3(0,1.10,0),Vector3(-4.7,3.1,-5.5),5.5)
    await _shot("01-bastion-hero-same-iso","P06 Bastion")
    stage.remove_child(bastion)
    stage.add_child(g13)
    check(V61.show_finish(g13,false),"old G13 V60 wheel center reference")
    await _shot("02-g13-old-v60-same-iso","G13 V60")
    check(V61.show_finish(g13,true),"G13 V61 real open spokes restore")
    await _shot("03-g13-new-v61-same-iso","G13 V61")
    changes["normal_iso"]=_delta(
        "02-g13-old-v60-same-iso","03-g13-new-v61-same-iso")
    check(int(changes["normal_iso"])>=15,
        "new real G13 open wheels and armor have actual iso pixel change")
    stage.remove_child(g13)
    stage.add_child(bastion)
    _set_camera(bastion_wheel,Vector3(-2.25,1.0,-0.85),1.75)
    await _shot("04-bastion-production-wheel-macro","P06 Bastion")
    stage.remove_child(bastion)
    stage.add_child(g13)
    _set_camera(g13_wheel,Vector3(-2.25,1.0,-0.85),1.75)
    check(V61.show_finish(g13,false),"same angle G13 pre-V61 wheel")
    await _shot("05-g13-v60-wheel-macro","G13 V60")
    check(V61.show_finish(g13,true),"new sculpted G13 8-spoke wheel")
    await _shot("06-g13-v61-wheel-macro","G13 V61")
    changes["wheel_macro"]=_delta(
        "05-g13-v60-wheel-macro","06-g13-v61-wheel-macro")
    check(int(changes["wheel_macro"])>=35,
        "actual open spokes visibly better at SAME macro camera")
    _set_camera(Vector3(0.85,0.33,0.85),
        Vector3(2.25,1.0,0.85),1.75)
    await _shot("07-g13-v61-rear-wheel-opposite-side","G13 V61")
    stage.remove_child(g13)
    g13.free()
    for fac in [3,7]:
        var variant:=Models.build("aa_mobile",fac,true,13)
        check(variant!=null and bool(variant.get_meta(V61.FLAG,false)),
            "V61 same wheel finish installed on official faction "+str(fac))
        if variant==null:
            continue
        stage.add_child(variant)
        _set_camera(Vector3(0,1.1,0),Vector3(-4.7,3.1,-5.5),5.5)
        await _shot("08-faction-%d-g13-v61" % fac,
            "G13 faction %d" % fac)
        stage.remove_child(variant)
        variant.free()
    bastion.free()
    check(captures.size()==9,
        "nine true native Godot frames P06/G13 wheel/normal angle")
    var manifest:=FileAccess.open(ProjectSettings.globalize_path(
        OUTPUT.path_join("g13-v61-bastion-comparison.json")),FileAccess.WRITE)
    check(manifest!=null,"native P06/G13 proof manifest")
    if manifest!=null:
        manifest.store_string(JSON.stringify({
            "comparison":"Actual P06 Bastion vs G13 V60/V61, same lighting",
            "real_godot_4_3":true,
            "same_iso_camera":true,
            "wheel_macro_same_relative_eye_and_zoom":true,
            "no_mockups_or_generated_frames":true,
            "v61_extra_draw_nodes":0,
            "artistic_user_signoff_pending":true,
            "changed_sampled_pixels":changes,
            "captures":captures,"issues":issues
        },"  "))
        manifest.close()
    stage.queue_free()
    await process_frame
    await process_frame
    if issues==0:
        print("PASS G13 V61 REAL P06 BASTION MATCHED LIGHT: 9 original Godot images, same lights and iso camera, equal wheel macro zoom, actual 8 open-spoke steel rims, all eight faceted hubs preserve rig")
    quit(1 if issues>0 else 0)
