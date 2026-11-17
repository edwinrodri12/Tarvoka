extends SceneTree

const City=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const V3=preload("res://scripts/ui/CivilianCityPublicSpaceV3.gd")
const V4=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
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
        damage: int,label: String,yaw: float=0.0,
        use_v2: bool=true,use_v3: bool=true,
        lod: int=0,compact: bool=false) -> void:
    var model: Node3D
    if compact:
        model=V4.build_tactical(level,faction,damage,lod)
    else:
        model=City.build(level,faction,damage)
    assert(model!=null)
    if use_v2 and not compact:
        assert(V2.apply(model,level,faction,damage))
        if use_v3:
            assert(V3.apply(model,level,faction,damage))
            assert(V4.apply(model,level,faction,damage))
            assert(V4.set_detail(model,lod))
    base.add_child(model)
    cam.position=Vector3(
        18.0*cos(yaw)+20.0*sin(yaw),18.5,
        23.5*cos(yaw)-18.0*sin(yaw))
    if label.begins_with("tactical_"):
        cam.size=28.0 if lod==0 else 36.0 if lod==1 else 46.0
        cam.position=Vector3(19.0,21.0,28.0)
        cam.look_at(Vector3(0.0,2.0,0.0),Vector3.UP)
    elif label.begins_with("plaza") or label.begins_with("compare_v2_plaza") or label.begins_with("compare_v3_plaza"):
        cam.size=12.5
        cam.position=Vector3(7.8,9.8,13.5)
        cam.look_at(Vector3(0.0,0.55,1.85),Vector3.UP)
    elif label.begins_with("entry"):
        cam.size=13.5
        cam.position=Vector3(10.0,10.5,12.0)
        cam.look_at(Vector3(0.0,2.1,-2.38),Vector3.UP)
    elif label.begins_with("civic") or label.begins_with("compare"):
        cam.size=14.0
        cam.position=Vector3(11.0,10.5,-18.0)
        cam.look_at(Vector3(0,3.5,-3.75),Vector3.UP)
    else:
        cam.size=25.5
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
        "res://artifacts/tarvoka_city_v4_%s.png" % label)==OK)
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
    var raw_city: Node3D=City.build(1,0,0)
    assert(not V4.apply(raw_city,1,0,0))
    raw_city.free()
    assert(not V2.apply(null,1,0,0))
    assert(not V3.apply(null,1,0,0))
    assert(not V4.apply(null,1,0,0))
    assert(V4.build_tactical(0,0,0)==null)
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
                var original_meshes: int=City.count_meshes(node)
                assert(V2.apply(node,level,faction,damage))
                assert(not V2.apply(node,level,faction,damage))
                assert(node.has_node(V2.STAGE_NAME))
                var finish: Node3D=node.get_node(V2.STAGE_NAME) as Node3D
                assert(bool(finish.get_meta("visual_only",false)))
                assert(bool(finish.get_meta("no_gameplay_changes",false)))
                assert(int(finish.get_meta("detail_version",0))==2)
                assert(int(finish.get_meta("level",-1))==level)
                assert(int(finish.get_meta("damage",-1))==damage)
                assert(int(finish.get_meta("faction",-2))==faction)
                var v2_meshes: int=City.count_meshes(node)
                var raw_v1: Node3D=City.build(level,faction,damage)
                assert(not V3.apply(raw_v1,level,faction,damage))
                raw_v1.free()
                assert(V3.apply(node,level,faction,damage))
                assert(not V3.apply(node,level,faction,damage))
                assert(node.has_node(V3.STAGE_NAME))
                var public_space: Node3D=node.get_node(V3.STAGE_NAME) as Node3D
                assert(bool(public_space.get_meta("visual_only",false)))
                assert(bool(public_space.get_meta("no_gameplay_changes",false)))
                assert(int(public_space.get_meta("detail_version",0))==3)
                assert(int(public_space.get_meta("level",-1))==level)
                assert(int(public_space.get_meta("faction",-2))==faction)
                assert(int(public_space.get_meta("damage",-1))==damage)
                assert(str(public_space.get_meta("tactical_silhouette",""))=="plaza-and-townhall-entrance")

                assert(V4.apply(node,level,faction,damage))
                assert(not V4.apply(node,level,faction,damage))
                assert(node.has_node(V4.STAGE_NAME))
                var lod_stage: Node3D=node.get_node(V4.STAGE_NAME) as Node3D
                assert(bool(lod_stage.get_meta("visual_only",false)))
                assert(bool(lod_stage.get_meta("no_gameplay_changes",false)))
                assert(int(lod_stage.get_meta("detail_version",0))==4)
                assert(str(lod_stage.get_meta("tactical_landmark",""))=="municipal-roof-and-plaza")
                var count: int=City.count_meshes(node)
                assert(count>v2_meshes)
                assert(V4.drawable_count(node)==count)
                var full_count: int=V4.drawable_count(node)
                assert(V4.set_detail(node,1))
                var medium_count: int=V4.drawable_count(node)
                assert(V4.set_detail(node,2))
                var far_count: int=V4.drawable_count(node)
                assert(V4.set_detail(node,0))
                assert(V4.drawable_count(node)==full_count)
                assert(far_count<=medium_count and medium_count<=full_count)
                if damage<=2:
                    assert(far_count<full_count)
                if damage==0 and faction==0:
                    assert(far_count*2<full_count)
                    assert(node.find_child("FranjaMunicipalVisibleV4",true,false)!=null)
                    if level==1:
                        assert(node.find_child("RemateVillaV4",true,false)!=null)
                    elif level==2:
                        assert(node.find_child("MarcoMunicipalCiudadV4",true,false)!=null)
                    else:
                        assert(node.find_child("AletaCoronaMetropoliV4_1",true,false)!=null)
                    var compact: Node3D=V4.build_tactical(level,faction,damage,2)
                    assert(compact!=null)
                    assert(bool(compact.get_meta("tactical_compact",false)))
                    assert(int(compact.get_meta("removed_render_meshes",0))>0)
                    assert(V4.drawable_count(compact)==far_count)
                    assert(City.count_meshes(compact)==far_count)
                    compact.free()
                assert(count>=original_meshes)
                if damage==0:
                    assert(node.find_child("PortonSurAyuntamientoV3",true,false)!=null)
                    assert(node.find_child("FranjaPasoCebraV3_0",true,false)!=null)
                    assert(node.find_child("BordeFuenteLateralV3_1",true,false)!=null)
                    if level==1:
                        assert(node.find_child("MacizoFloresVillaV3_-1",true,false)!=null)
                        assert(node.find_child("AparcabicicletasVillaV3_0",true,false)!=null)
                        assert(node.find_child("MarquesinaParadaV3_1",true,false)==null)
                    else:
                        assert(node.find_child("MarquesinaParadaV3_1",true,false)!=null)
                        assert(node.find_child("CubiertaPorticoCiudadanoV3",true,false)!=null)
                        if level==3:
                            assert(node.find_child("SenalDireccionV3_-1",true,false)!=null)
                if damage>=3:
                    assert(node.find_child("PortonSurAyuntamientoV3",true,false)==null)
                    assert(node.find_child("FranjaPasoCebraV3_0",true,false)==null)
                    assert(node.find_child("GrietaAvenidaV3",true,false)!=null)
                    assert(node.find_child("EscaleraMunicipalRotaV3",true,false)!=null)
                if damage==2:
                    assert(node.find_child("PuertaDesencajadaV3",true,false)!=null)
                if damage>=3:
                    assert(City.count_meshes(finish)==0)
                if damage==0:
                    assert(City.count_meshes(finish)>20)
                    assert(node.find_child("FrontonTriangularV2_Ayuntamiento",true,false)!=null)
                    if level==1:
                        assert(node.find_child("TejaInclinadaV2_-1",true,false)!=null)
                        assert(node.find_child("BalconesV2_ResidencialSur_1",true,false)==null)
                    elif level==2:
                        assert(node.find_child("MarquesinaComercioV2",true,false)!=null)
                        assert(node.find_child("BarandillaFrenteV2_1",true,false)!=null)
                    elif level==3:
                        assert(node.find_child("AntenaUrbanaV2",true,false)!=null)
                        assert(node.find_child("VentanalPanoramicoV2",true,false)!=null)
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
        for level in [1,2,3]:
            await _capture(view,scene,camera,level,0,0,
                "civic_level_%d" % level)
            await _capture(view,scene,camera,level,0,0,
                "plaza_level_%d" % level)
            await _capture(view,scene,camera,level,0,0,
                "entry_level_%d" % level)
        await _capture(view,scene,camera,2,0,0,"compare_v1_civic",0.0,false,false)
        await _capture(view,scene,camera,2,0,0,"compare_v2_civic",0.0,true,false)
        await _capture(view,scene,camera,2,0,0,"compare_v2_plaza",0.0,true,false)
        await _capture(view,scene,camera,2,0,0,"compare_v3_plaza")
        await _capture(view,scene,camera,2,-1,0,"neutral_city")
        await _capture(view,scene,camera,3,7,0,"onyx_city")
        for level in [1,2,3]:
            for lod in [0,1,2]:
                await _capture(view,scene,camera,level,0,0,
                    "tactical_level_%d_lod_%d" % [level,lod],
                    0.0,true,true,lod,lod==2)
        for damage in [1,2,3,4]:
            await _capture(view,scene,camera,3,0,damage,
                "damage_%d" % damage)
        frame.queue_free()
        await _frames(2)
    print("PASS TARVOKA CITY V4: 135 city variants, tactical mesh reductions and 3 levels of LOD, native compact mobile builds, 34 Godot GPU screenshots, economy unchanged")
    quit(0)
