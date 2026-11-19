extends SceneTree

# TARVOKA actual OpenGL camera inspection of the same native V2 mesh used
# by the Web 3D studio. No proxy images and no fake preview geometry.
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_v2"

func _initialize() -> void:
    call_deferred("_capture_all")

func _capture_all() -> void:
    var output_abs:String=ProjectSettings.globalize_path(OUTPUT)
    var dir_error:Error=DirAccess.make_dir_recursive_absolute(output_abs)
    assert(dir_error==OK,"Cannot create visual QA artifact directory")
    var viewport:=SubViewport.new()
    viewport.name="WorkshopRealCameraQA"
    viewport.size=Vector2i(960,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg=false
    get_root().add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#2b3e48")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e2ecf0")
    env.ambient_light_energy=0.70
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-29,0)
    sun.light_energy=1.28
    sun.shadow_enabled=true
    viewport.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,142,0)
    fill.light_energy=0.36
    viewport.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.10
    camera.far=200.0
    viewport.add_child(camera)
    camera.current=true
    var views:Array=[
        ["isometrica",145.0,39.0],
        ["frente",180.0,19.0],
        ["posterior",0.0,19.0],
        ["lateral_derecha",90.0,22.0],
        ["lateral_izquierda",270.0,22.0],
        ["techo",37.0,78.0]
    ]
    var manifest:Array=[]
    var image_count:int=0
    for level in [1,2,3]:
        # Neutral, official faction 0 and official faction 3.
        var faction:int=-1 if level==1 else 0 if level==2 else 3
        var model:Node3D=Workshop.build(level,faction,0)
        assert(model!=null)
        viewport.add_child(model)
        for shot in views:
            var filename:String="N%d_F%d_D0_%s.png" % [
                level,faction,str(shot[0])]
            var result:Dictionary=await _capture_view(
                viewport,camera,level,shot,filename)
            manifest.append(result)
            image_count+=1
        viewport.remove_child(model)
        model.free()
    # Inspect roof collapses, front rubble and intact-to-damaged sequence.
    for damage in [2,3,4]:
        var model:Node3D=Workshop.build(3,-1,damage)
        assert(model!=null)
        viewport.add_child(model)
        for shot in [["isometrica",145.0,39.0],
                ["frente",180.0,19.0]]:
            var filename:String="N3_F-1_D%d_%s.png" % [damage,str(shot[0])]
            var result:Dictionary=await _capture_view(
                viewport,camera,3,shot,filename)
            manifest.append(result)
            image_count+=1
        viewport.remove_child(model)
        model.free()
    # Direct visual comparison against identical six-angle HERO N3 views.
    for profile in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        var model:Node3D=Mobile.build(3,3,0,profile)
        assert(model!=null)
        viewport.add_child(model)
        for shot in views:
            var filename:String="N3_F3_D0_M%d_%s.png" % [
                profile,str(shot[0])]
            var result:Dictionary=await _capture_view(
                viewport,camera,3,shot,filename)
            result["mobile_lod"]=profile
            manifest.append(result)
            image_count+=1
        viewport.remove_child(model)
        model.free()
    assert(image_count==36,
        "Not all six-view HERO / Android camera profiles rendered")
    var file:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(file!=null,"No manifest")
    file.store_string(JSON.stringify({
        "artifact":"TARVOKA Taller de Blindados V2",
        "real_engine":"Godot 4.3 OpenGL",
        "cameras":6,"hero_images":24,"mobile_images":12,
        "rendered_images":image_count,"captures":manifest
    }, "\t"))
    file.close()
    print("PASS WORKSHOP V2 VISUAL: ",image_count,
        " real OpenGL images, six cameras, three sizes, D2-D4, ",
        "tactical and distant mobile LOD")
    viewport.queue_free()
    quit(0)

func _capture_view(viewport:SubViewport,camera:Camera3D,
        level:int,shot:Array,filename:String) -> Dictionary:
    var distance:float=38.0 if level==1 else 48.0 if level==2 else 59.0
    var focus_y:float=2.3 if level==1 else 2.8 if level==2 else 3.7
    var focus:=Vector3(0,focus_y,0)
    var yaw:float=deg_to_rad(float(shot[1]))
    var tilt:float=deg_to_rad(float(shot[2]))
    camera.size=22.0 if level==1 else 30.0 if level==2 else 39.0
    camera.position=focus+Vector3(
        sin(yaw)*cos(tilt)*distance,
        sin(tilt)*distance,
        cos(yaw)*cos(tilt)*distance)
    camera.look_at(focus,Vector3.UP)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var captured:Image=viewport.get_texture().get_image()
    assert(captured!=null and captured.get_width()==960 and
        captured.get_height()==720,"Invalid GPU camera image")
    var output:String=OUTPUT+"/"+filename
    var saved:Error=captured.save_png(output)
    assert(saved==OK,"Could not save "+filename)
    return {"file":filename,"view":str(shot[0]),"level":level}
