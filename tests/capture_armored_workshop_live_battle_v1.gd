extends SceneTree

# Real Godot render of actual playable BattleTerrain3D modern armor_plant.
# No studio demo, synthetic site markers, or gameplay parameter changes.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Workshop=preload("res://scripts/ui/ArmoredWorkshopBattle3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_real_battle"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var board:Array=Scenarios.terrain(0)
    var state:Dictionary=Session.start(
        Roles.experimental_armies(),board,0,false,false,true)
    assert(state.get("economy",{}).get("modern",false))
    var view:=SubViewport.new()
    view.size=Vector2i(960,720)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(view)
    var bg:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#263746")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce7ed")
    env.ambient_light_energy=0.62
    bg.environment=env
    view.add_child(bg)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-33,0)
    sun.light_energy=1.28
    sun.shadow_enabled=true
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.1
    camera.far=180.0
    view.add_child(camera)
    camera.current=true
    var point:Vector2i=Vector2i(0,1)
    var rows:Array=[]
    for variant in [
            {"level":1,"damage":0,"profile":Mobile.PROFILE_TACTICAL},
            {"level":2,"damage":0,"profile":Mobile.PROFILE_TACTICAL},
            {"level":3,"damage":0,"profile":Mobile.PROFILE_TACTICAL},
            {"level":3,"damage":2,"profile":Mobile.PROFILE_TACTICAL},
            {"level":3,"damage":3,"profile":Mobile.PROFILE_TACTICAL},
            {"level":3,"damage":4,"profile":Mobile.PROFILE_TACTICAL},
            {"level":3,"damage":0,"profile":Mobile.PROFILE_DISTANT}
        ]:
        var edit:Dictionary=state.duplicate(true)
        var site:Dictionary=Economy.site_at(edit["economy"],point)
        site["visual_level"]=int(variant["level"])
        site["visual_damage_stage"]=int(variant["damage"])
        var prior:Dictionary=edit.duplicate(true)
        var scene:Node3D=Terrain.build(edit,"",0)
        assert(scene!=null)
        view.add_child(scene)
        var model:Node3D=scene.find_child(
            "Instalacion3D_armor_plant_0_1",true,false) as Node3D
        assert(model!=null)
        if int(variant["profile"])==Mobile.PROFILE_DISTANT:
            assert(Workshop.set_runtime_detail(model,Mobile.PROFILE_DISTANT))
        var camera_center:Vector3=model.global_position+Vector3(0,0.48,0)
        var yaw:float=deg_to_rad(145.0)
        var tilt:float=deg_to_rad(55.0)
        camera.size=9.4 if int(variant["profile"])==1 else 17.0
        camera.position=camera_center+Vector3(
            sin(yaw)*cos(tilt)*19.0,
            sin(tilt)*19.0,cos(yaw)*cos(tilt)*19.0)
        camera.look_at(camera_center,Vector3.UP)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var png:Image=view.get_texture().get_image()
        assert(png!=null and png.get_width()==960 and
            png.get_height()==720)
        var bg_color:Color=png.get_pixel(3,3)
        var filled:int=0
        for y in range(16,700,10):
            for x in range(16,940,10):
                var px:Color=png.get_pixel(x,y)
                if absf(px.r-bg_color.r)+absf(px.g-bg_color.g)+
                        absf(px.b-bg_color.b)>0.14:
                    filled+=1
        assert(filled>100,"Actual battle frame blank")
        var label:String="N%d_D%d_LOD%d" % [
            int(variant["level"]),int(variant["damage"]),
            int(variant["profile"])]
        assert(png.save_png(OUTPUT+"/"+label+".png")==OK)
        rows.append({"image":label+".png",
            "level":int(variant["level"]),
            "damage":int(variant["damage"]),
            "profile":int(variant["profile"]),
            "visible_samples":filled,
            "actual_armor_plant_site":true})
        assert(edit==prior,"Render mutated playable state")
        view.remove_child(scene)
        scene.free()
    var manifest:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(manifest!=null)
    manifest.store_string(JSON.stringify({
        "source":"Actual modern BattleTerrain3D.build, existing armor_plant",
        "renderer":"Godot 4.3 GL Compatibility",
        "frames":rows.size(),"gameplay_unchanged":true,
        "scenes":rows
    },"  "))
    manifest.close()
    assert(rows.size()==7)
    print("PASS WORKSHOP LIVE BATTLE SCREENSHOTS: 7 real modern ",
        "gameplay-scene screenshots N1-N3 D0-D4 and both Android profiles")
    view.queue_free()
    quit(0)
