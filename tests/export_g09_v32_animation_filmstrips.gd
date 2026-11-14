extends SceneTree

# Inspect real engine frames, never generative concept images.
# Five horizontal filmstrips each contain six frames from native Godot
# (move, fire, bullet, explosive, damage recoil); sixth sheet contains five
# actual persistent HP damage states 0..4, from the SAME G09 V31 source.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Hit = preload("res://scripts/ui/TankHitReactionV30.gd")
const WIDTH := 460
const HEIGHT := 305
const FRAMES := [0.0,0.14,0.32,0.46,0.73,1.0]

func _initialize() -> void:
    call_deferred("_run")

func _render(vp: SubViewport) -> Image:
    for i in range(4):
        await process_frame
    var image: Image=vp.get_texture().get_image()
    assert(image!=null and not image.is_empty())
    return image

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var vp:=SubViewport.new()
    vp.size=Vector2i(WIDTH,HEIGHT)
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    vp.own_world_3d=true
    root.add_child(vp)
    var background:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172731")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#C2D0DD")
    env.ambient_light_energy=0.82
    background.environment=env
    vp.add_child(background)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-45,-37,0)
    key.light_energy=1.52
    vp.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-22,125,0)
    fill.light_energy=0.50
    vp.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.68
    camera.position=Vector3(4.3,2.2,-5.0)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.50,0),Vector3.UP)
    camera.current=true
    var model: Node3D=Models.build("tank",2,true,31)
    assert(model!=null and model.get_meta("tarvoka_mbt_tracks_inboard_v31",false))
    assert(model.get_meta("tarvoka_v32_hit_nodes",{}).size()==20)
    vp.add_child(model)
    for kind in ["move","attack",Hit.BULLET,Hit.EXPLOSIVE,"damaged"]:
        assert(Damage.apply_stage(model,0))
        var sheet:=Image.create(FRAMES.size()*WIDTH,HEIGHT,false,Image.FORMAT_RGBA8)
        for i in range(FRAMES.size()):
            assert(Rig.pose(model,kind,float(FRAMES[i]),Vector2i(1,0)))
            var frame: Image=await _render(vp)
            sheet.blit_rect(frame,Rect2i(0,0,WIDTH,HEIGHT),
                Vector2i(i*WIDTH,0))
        Rig.restore(model)
        var filename: String="res://artifacts/tarvoka_g09_v32_anim_%s.png" % kind
        assert(sheet.save_png(filename)==OK)
    var stages:=Image.create(5*WIDTH,HEIGHT,false,Image.FORMAT_RGBA8)
    for stage in range(5):
        assert(Damage.apply_stage(model,stage))
        Rig.restore(model)
        Damage.animate_smoke(model,1.3+float(stage)*0.37)
        var frame: Image=await _render(vp)
        stages.blit_rect(frame,Rect2i(0,0,WIDTH,HEIGHT),Vector2i(stage*WIDTH,0))
    assert(stages.save_png(
        "res://artifacts/tarvoka_g09_v32_five_damage_stages.png")==OK)
    assert(Damage.apply_stage(model,0))
    vp.remove_child(model)
    model.free()
    vp.free()
    await process_frame
    await process_frame
    print("PASS G09 V32 FILMSTRIPS: 6 actual Godot QA strips, 30 native keyframes plus 5 persistent damage states, final V31 inboard geometry unchanged")
    quit(0)
