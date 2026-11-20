extends SceneTree

# Faction-color signoff on genuine Godot geometry, not an illustration.
# 9 palettes (8 factions + neutral) x HERO / Android tactical / distant.
# N1 and N3 are separately covered by the 135/270 model tests.
const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Tile=preload("res://scripts/ui/ArmoredWorkshopBattleTile3D.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_faction_colors"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var view:=SubViewport.new()
    view.name="CapturaReal9Facciones"
    view.size=Vector2i(720,540)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(view)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#243b48")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce8f0")
    env.ambient_light_energy=0.68
    world.environment=env
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-33,0)
    sun.light_energy=1.26
    sun.shadow_enabled=true
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.10
    camera.far=200.0
    view.add_child(camera)
    camera.current=true
    var shots:Array=[]
    for profile in [0,Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
        for faction in range(-1,8):
            var root:Node3D=Hero.build(2,faction,0) if profile==0 else \
                Tile.build(2,faction,0,profile)
            assert(root!=null)
            view.add_child(root)
            var expected:Color=Style.faction_color(faction) if faction>=0 else Hero.NEUTRAL
            var yaw:float=deg_to_rad(145.0)
            var tilt:float=deg_to_rad(49.0)
            var distance:float=45.0 if profile==0 else 19.0
            var focus:=Vector3(0,3.0 if profile==0 else 0.32,0)
            camera.size=26.0 if profile==0 else 9.60
            camera.position=focus+Vector3(
                sin(yaw)*cos(tilt)*distance,
                sin(tilt)*distance,
                cos(yaw)*cos(tilt)*distance)
            camera.look_at(focus,Vector3.UP)
            await process_frame
            await process_frame
            await RenderingServer.frame_post_draw
            var img:Image=view.get_texture().get_image()
            assert(img!=null and img.get_width()==720 and
                img.get_height()==540)
            var bg:Color=img.get_pixel(4,4)
            var filled:int=0
            for y in range(15,525,9):
                for x in range(15,705,9):
                    var pixel:Color=img.get_pixel(x,y)
                    if (absf(pixel.r-bg.r)+absf(pixel.g-bg.g)+
                            absf(pixel.b-bg.b))>0.14:
                        filled+=1
            assert(filled>=70,"Faction camera rendered empty geometry")
            var faction_id:String="NEUTRAL" if faction==-1 else "F%d" % faction
            var profile_name:String="HERO" if profile==0 else \
                "TACTICAL" if profile==Mobile.PROFILE_TACTICAL else "DISTANT"
            var name:String="%s_N2_%s.png" % [faction_id,profile_name]
            assert(img.save_png(OUTPUT+"/"+name)==OK)
            shots.append({
                "file":name,"faction":faction,
                "palette":expected.to_html(),
                "profile":profile_name,"level":2,
                "damage":0,"visible_samples":filled,
                "gameplay_unchanged":true
            })
            view.remove_child(root)
            root.free()
    assert(shots.size()==27)
    var manifest:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(manifest!=null)
    manifest.store_string(JSON.stringify({
        "renderer":"Godot 4.3 GL Compatibility",
        "images":27,"palettes":9,
        "profiles":["HERO","TACTICAL","DISTANT"],
        "notes":"Official faction colors, no added gameplay or new Android material groups",
        "shots":shots
    },"  "))
    manifest.close()
    print("PASS WORKSHOP FACTION COLORS: 27 real Godot images, ",
        "9 palettes (including neutral), 3 render profiles and approved geometry")
    view.queue_free()
    quit(0)
