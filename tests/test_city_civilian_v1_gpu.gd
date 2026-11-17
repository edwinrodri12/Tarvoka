extends SceneTree

const City=preload("res://scripts/ui/CivilianCity3DV1.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const DAMAGE_SAMPLES=[0,1,2,3,4]

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for i in range(n):
        await process_frame

func _capture(view: SubViewport,base: Node3D,
        cam: Camera3D,level: int,faction: int,
        damage: int,label: String,yaw: float=0.0) -> void:
    var model: Node3D=City.build(level,faction,damage)
    assert(model!=null)
    base.add_child(model)
    cam.position=Vector3(
        18.0*cos(yaw)+20.0*sin(yaw),18.5,
        23.5*cos(yaw)-18.0*sin(yaw))
    cam.look_at(Vector3(0.0,2.0,0.0),Vector3.UP)
    await _frames(9)
    var image: Image=view.get_texture().get_image()
    assert(image!=null and not image.is_empty())
    var palette: Dictionary={}
    for y in range(0,image.get_height(),maxi(1,int(image.get_height()/16))):
        for x in range(0,image.get_width(),maxi(1,int(image.get_width()/22))):
            palette[image.get_pixel(x,y).to_html()]=true
    assert(palette.size()>8)
    assert(image.save_png(
        "res://artifacts/tarvoka_city_v1_%s.png" % label)==OK)
    base.remove_child(model)
    model.free()
    await _frames(2)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(City.valid_spec(1,-1,0))
    assert(City.valid_spec(3,7,4))
    assert(not City.valid_spec(0,0,0))
    assert(not City.valid_spec(1,8,0))
    assert(not City.valid_spec(1,0,5))
    assert(City.build(0,0,0)==null)
    var tiers: Dictionary={}
    var configurations: int=0
    for level in [1,2,3]:
        for faction in range(-1,8):
            for damage in DAMAGE_SAMPLES:
                var node: Node3D=City.build(level,faction,damage)
                assert(node!=null)
                assert(node.has_node(City.STAGE_NAME))
                assert(bool(node.get_meta("visual_only",false)))
                assert(bool(node.get_meta("not_headquarters",false)))
                assert(bool(node.get_meta("not_buildable",false)))
                assert(int(node.get_meta("visual_level",-1))==level)
                assert(int(node.get_meta("visual_faction",-2))==faction)
                assert(int(node.get_meta("visual_damage_stage",-1))==damage)
                var count: int=City.count_meshes(node)
                assert(count>=20)
                if faction==0 and damage==0:
                    tiers[level]=count
                if damage==4:
                    assert(node.find_child("TorreRelojMunicipal",true,false)==null)
                if damage==0:
                    assert(node.find_child("PlazaCivica",true,false)!=null)
                    assert(node.find_child("Ayuntamiento",true,false)==null)
                    assert(node.find_child("EdificioCivil_Ayuntamiento",true,false)!=null)
                node.free()
                configurations+=1
    assert(configurations==135)
    assert(int(tiers[1])<int(tiers[2]) and int(tiers[2])<int(tiers[3]))
    # Game economy remains the existing fixed-city capture/revenue system.
    for size in [Vector2i(10,8),Vector2i(24,18)]:
        var terrain: Array=Scenarios.terrain(0,size)
        var state: Dictionary=Economy.create(terrain)
        assert(not state.is_empty())
        var cities: int=0
        for site in state["sites"]:
            if str(site["kind"])=="city":
                cities+=1
                assert(not site.has("visual_level"))
        assert(cities==4)

    if DisplayServer.get_name()!="headless":
        assert(DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))==OK)
        var frame:=SubViewportContainer.new()
        frame.size=Vector2(1100,720)
        frame.stretch=false
        root.add_child(frame)
        var view:=SubViewport.new()
        view.size=Vector2i(1100,720)
        view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
        view.transparent_bg=false
        frame.add_child(view)
        var scene:=Node3D.new()
        view.add_child(scene)
        var camera:=Camera3D.new()
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=25.5
        view.add_child(camera)
        camera.current=true
        var sun:=DirectionalLight3D.new()
        sun.rotation_degrees=Vector3(-46.0,30.0,0.0)
        sun.light_energy=1.75
        scene.add_child(sun)
        var fill:=DirectionalLight3D.new()
        fill.rotation_degrees=Vector3(-60.0,-125.0,0.0)
        fill.light_energy=0.54
        scene.add_child(fill)
        # Color/geometry contrast is assessed in native Godot, not with
        # an image generator, so exported meshes remain inspectable.
        for level in [1,2,3]:
            await _capture(view,scene,camera,level,0,0,
                "level_%d_overview" % level)
            await _capture(view,scene,camera,level,0,0,
                "level_%d_street" % level,1.0)
        await _capture(view,scene,camera,2,-1,0,"neutral_city")
        await _capture(view,scene,camera,3,7,0,"onyx_city")
        for damage in [1,2,3,4]:
            await _capture(view,scene,camera,3,0,damage,
                "damage_%d" % damage)
        frame.queue_free()
        await _frames(2)
    print("PASS TARVOKA CITY V1: 135 civilian city 3D variants, 3 architectural tiers, eight factions plus neutral, five damages, game economy/capture unchanged, 12 native Godot previews")
    quit(0)
