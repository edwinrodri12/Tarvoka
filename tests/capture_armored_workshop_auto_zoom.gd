extends SceneTree

# Native Godot 4.3 OpenGL screenshot QA at eight zoom distances. We render
# the SAME BattleTile + LODPolicy used by both studios, but in a dedicated
# fixed-resolution SubViewport. The studio's responsive UI otherwise resizes
# its SubViewport during screenshot capture on headless CI, making width/
# height assertions unreliable and leaving Godot open on a failed assert.
# The separate test_armored_workshop_studio_ui.gd exercises real controls.
const Tiles=preload("res://scripts/ui/ArmoredWorkshopBattleTile3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_auto_zoom"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var view:=SubViewport.new()
    view.name="FixedResolutionZoomEvidence"
    view.size=Vector2i(960,720)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(view)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#243b48")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dde8ee")
    env.ambient_light_energy=0.66
    world.environment=env
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-33,0)
    sun.light_energy=1.30
    sun.shadow_enabled=true
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.10
    camera.far=200.0
    view.add_child(camera)
    camera.current=true
    var scene:Node3D=Tiles.build(3,3,0,Mobile.PROFILE_TACTICAL)
    assert(scene!=null)
    view.add_child(scene)
    var land:Node3D=scene.get_node(
        "Terreno3DRealNueveCasillas") as Node3D
    assert(land!=null and land.get_child_count()==12)
    var land_id:int=land.get_instance_id()
    var workshop_id:int=scene.get_node(
        "TallerEnCasillaCentral").get_instance_id()
    var rows:Array=[]
    var tactical:int=0
    var distant:int=0
    for n in range(8):
        var zoom:float=[0.60,0.85,1.12,1.42,1.95,1.25,0.90,0.60][n]
        var focus:=Vector3(0,0.32,0)
        var yaw:float=deg_to_rad(145.0)
        var tilt:float=deg_to_rad(49.0)
        camera.size=9.60*zoom
        camera.position=focus+Vector3(
            sin(yaw)*cos(tilt)*19.0,
            sin(tilt)*19.0,
            cos(yaw)*cos(tilt)*19.0)
        camera.look_at(focus,Vector3.UP)
        var px:float=Policy.projected_width(
            camera,Vector3(0,0.3,0),2.17)
        var previous:int=int(scene.get_meta("workshop_lod_profile",0))
        var selected:int=Policy.choose_mobile(px,previous)
        assert(Tiles.set_preview_detail(scene,selected))
        assert(int(scene.get_meta("workshop_lod_profile",0))==selected)
        assert(land.get_instance_id()==land_id and land.get_child_count()==12)
        assert(scene.get_node(
            "TallerEnCasillaCentral").get_instance_id()==workshop_id)
        if selected==Mobile.PROFILE_TACTICAL:
            tactical+=1
        else:
            distant+=1
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var png:Image=view.get_texture().get_image()
        assert(png!=null and png.get_width()==960
            and png.get_height()==720,
            "Fixed-size viewport unexpectedly changed resolution")
        var cleared:Color=png.get_pixel(1,1)
        var visible:int=0
        for y in range(20,700,10):
            for x in range(20,940,10):
                var pixel:Color=png.get_pixel(x,y)
                if absf(pixel.r-cleared.r)+absf(pixel.g-cleared.g)+\
                    absf(pixel.b-cleared.b)>0.14:
                    visible+=1
        assert(visible>=180,"Empty Godot 3D zoom frame")
        var filename:String="zoom_%02d_%03d_LOD%d.png" % [
            n,int(roundf(zoom*100.0)),selected]
        assert(png.save_png(OUTPUT+"/"+filename)==OK)
        rows.append({
            "file":filename,"zoom":zoom,
            "lod":selected,"projected_width_px":snappedf(px,0.1),
            "workshop_batches":int(scene.get_meta("workshop_batches",0)),
            "sampled_visible_pixels":visible,"terrain_reused":true
        })
    assert(rows.size()==8 and tactical>=2 and distant>=2)
    var manifest:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(manifest!=null)
    manifest.store_string(JSON.stringify({
        "engine":"Godot 4.3 OpenGL",
        "mode":"BattleTile 3D native render + studio UI verified separately",
        "tile_m":2.4,"hysteresis":[112,152],
        "frames":rows.size(),"tactical_frames":tactical,
        "distant_frames":distant,"images":rows
    },"  "))
    manifest.close()
    view.queue_free()
    print("PASS WORKSHOP AUTO ZOOM VISUAL: 8 real native Godot PNGs, ",
        tactical," tactical, ",distant,
        " distant; terrain and workshop root preserved at every zoom")
    quit(0)
