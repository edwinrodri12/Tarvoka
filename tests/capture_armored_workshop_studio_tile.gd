extends SceneTree

# Native Godot OpenGL evidence from the SAME selectable nine-tile Studio
# scene. Neither screenshots nor this fixture change an actual game board.
const Tiles=preload("res://scripts/ui/ArmoredWorkshopBattleTile3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_studio_tile"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var view:=SubViewport.new()
    view.size=Vector2i(960,720)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(view)
    var background:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#243b48")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#dce8f0")
    environment.ambient_light_energy=0.66
    background.environment=environment
    view.add_child(background)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-33,0)
    sun.light_energy=1.3
    sun.shadow_enabled=true
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.1
    camera.far=200.0
    view.add_child(camera)
    camera.current=true
    var captures:Array=[]
    for level in [1,2,3]:
        for lod in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
            var root:Node3D=Tiles.build(level,3,0,lod)
            assert(root!=null)
            view.add_child(root)
            for angle in [["isometrica",145.0,49.0],["techo",48.0,78.0]]:
                var label:String="N%d_LOD%d_%s.png" % [level,lod,str(angle[0])]
                captures.append(await _capture(view,camera,angle,label))
            view.remove_child(root)
            root.free()
    for damage in [3,4]:
        var root:Node3D=Tiles.build(3,-1,damage,
            Mobile.PROFILE_TACTICAL)
        assert(root!=null)
        view.add_child(root)
        captures.append(await _capture(view,camera,
            ["escombros",145.0,49.0],
            "N3_D%d_escombros.png" % damage))
        view.remove_child(root)
        root.free()
    assert(captures.size()==14)
    var output:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(output!=null)
    output.store_string(JSON.stringify({
        "engine":"Godot 4.3 OpenGL",
        "scene":"TARVOKA studio native 3D nine 2.4m tiles",
        "num_images":captures.size(),
        "captures":captures
    },"  "))
    output.close()
    print("PASS WORKSHOP STUDIO TILE VISUAL: ",
        captures.size()," actual Godot screenshots in nine-tile context, ",
        "3 levels, 2 mobile LODs and D3/D4 wreckage")
    view.queue_free()
    quit(0)

func _capture(view:SubViewport,camera:Camera3D,
        angle:Array,filename:String) -> Dictionary:
    var focus:=Vector3(0,0.29,0)
    var yaw:float=deg_to_rad(float(angle[1]))
    var elevation:float=deg_to_rad(float(angle[2]))
    camera.size=11.0
    camera.position=focus+Vector3(
        sin(yaw)*cos(elevation)*18.0,
        sin(elevation)*18.0,
        cos(yaw)*cos(elevation)*18.0)
    camera.look_at(focus,Vector3.UP)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture:Image=view.get_texture().get_image()
    assert(picture!=null and picture.get_width()==960 and
        picture.get_height()==720)
    var cleared:Color=picture.get_pixel(1,1)
    var filled:int=0
    for y in range(20,700,10):
        for x in range(20,940,10):
            var point:Color=picture.get_pixel(x,y)
            if absf(point.r-cleared.r)+absf(point.g-cleared.g)+\
                    absf(point.b-cleared.b)>0.13:
                filled+=1
    assert(filled>=180,"Empty or out-of-frame map-view geometry "+filename)
    assert(picture.save_png(OUTPUT+"/"+filename)==OK)
    return {"filename":filename,"foreground_samples":filled}
