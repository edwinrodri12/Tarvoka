extends SceneTree

# Real native Godot 4.3 coastal gameplay: 2 existing shipyard producers,
# not separate buildings, with visually correct NAVAL BASE models.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Naval=preload("res://scripts/ui/NavalBaseBattle3D.gd")
const Model=preload("res://scripts/ui/NavalBaseTactical3D.gd")
const LOD=preload("res://scripts/ui/NavalBaseBattleLOD.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const OUTPUT:String="res://artifacts/naval_base_battle_v1"

func _initialize() -> void:
    call_deferred("_run")

static func find_naval(scene:Node3D,cell:Vector2i) -> Node3D:
    return scene.find_child(
        "Instalacion3D_shipyard_%d_%d" % [cell.x,cell.y],
        true,false) as Node3D

func capture(view:SubViewport,key:String) -> void:
    for _i in range(4):
        await RenderingServer.frame_post_draw
    var image:Image=view.get_texture().get_image()
    assert(image!=null and image.get_size()==view.size)
    assert(image.save_png(OUTPUT+"/"+key+".png")==OK)

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    assert(Naval.build(1,-2,0)==null)
    assert(Naval.build(1,8,0)==null)
    assert(Naval.build(1,1,5)==null)
    assert(Naval.build_site({},{"kind":"factory"},0)==null)
    assert(LOD.choose(116,0)==1)
    assert(LOD.choose(115,0)==0)
    assert(LOD.choose(85,1)==0)
    assert(LOD.choose(86,1)==1)

    var combos:int=0
    for tier in [1,2,3]:
        for damage in [0,1,2,3,4]:
            for faction in range(8):
                var distant:Node3D=Naval.build(tier,faction,damage)
                var close:Node3D=Naval.build(
                    tier,faction,damage,Naval.PROFILE_CLOSE)
                assert(distant!=null and close!=null)
                var dm:MeshInstance3D=distant.get_node(Naval.CHILD_NAME)
                var cm:MeshInstance3D=close.get_node(Naval.CHILD_NAME)
                assert(dm.mesh.get_surface_count()==4)
                assert(cm.mesh.get_surface_count()==(
                    5 if damage<=2 else 4))
                assert(cm.mesh.get_faces().size()>dm.mesh.get_faces().size())
                assert(bool(close.get_meta("game_visual_only",false)))
                distant.free()
                close.free()
                combos+=1
    assert(combos==120)
    var neutral:Node3D=Naval.build(3,-1,4,Naval.PROFILE_CLOSE)
    assert(neutral!=null and int(neutral.get_meta(
        "visual_faction",99))==-1)
    neutral.free()

    # The same game terrain without a sea MUST have zero naval facilities.
    var land:Dictionary=Session.start(Roles.experimental_armies(),
        Scenarios.terrain(0),0,false,false,true,true)
    assert(Economy.site_at(land["economy"],Vector2i(0,0)).is_empty())
    var land3d:Node3D=Terrain.build(land,"",0)
    assert(land3d!=null)
    assert(land3d.get_node_or_null("BaseNavalLOD_Camara")==null)
    land3d.free()

    var sea:Array=Scenarios.terrain(3)
    var game:Dictionary=Session.start(Roles.experimental_armies(),
        sea,0,false,false,true,true)
    assert(bool(game["economy"].get("modern",false)))
    var shipyards:Array=[]
    for site in game["economy"]["sites"]:
        if str(site.get("kind",""))=="shipyard":
            shipyards.append(site["pos"])
            assert(str(sea[site["pos"].y][site["pos"].x])=="water")
    assert(shipyards.size()==2)
    var original:Dictionary=game.duplicate(true)
    var board:Node3D=Terrain.build(game,"",0)
    assert(board!=null)
    var driver:Node=board.get_node_or_null("BaseNavalLOD_Camara")
    assert(driver!=null)
    assert(driver.registered_count()==2)
    var roots:Array=driver.get("_sites")
    assert(roots.size()==2)
    for cell in shipyards:
        var built:Node3D=find_naval(board,cell)
        assert(built!=null,"Real coastal shipyard missing 3D Naval Base")
        assert(built.get_meta("kind")=="shipyard")
        assert(str(built.get_meta("production_authority",""))
            =="UrbanEconomy")
        assert(built.get_meta("battle_cell")==cell)
        assert(int(built.get_meta("mesh_surface_count",99))==4)
        assert(built.get_node_or_null(Naval.CHILD_NAME)!=null)
    assert(original==game,"Sea visuals mutated production state")
    
    # Zoom changes ONLY render mesh, not map position, turn, owner or money.
    var viewport:=SubViewport.new()
    viewport.name="PuertoRealMapaTARVOKA"
    viewport.size=Vector2i(960,540)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#2b4258")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#c3d5dd")
    env.ambient_light_energy=0.61
    environment.environment=env
    viewport.add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-28,0)
    sun.light_energy=1.12
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.far=170
    camera.near=0.1
    viewport.add_child(camera)
    camera.current=true
    viewport.add_child(board)
    driver.set_process(false)
    var poses:Array=[]
    var identities:Array=[]
    for site in roots:
        poses.append(site.position)
        identities.append(site.get_instance_id())
    var center:Vector3=(roots[0] as Node3D).global_position
    camera.position=center+Vector3(9,13,10)
    camera.look_at(center,Vector3.UP)
    var outcomes:Array=[]
    for spec in [
        {"label":"far","zoom":70.0,"profile":Naval.PROFILE_DISTANT},
        {"label":"close","zoom":6.0,"profile":Naval.PROFILE_CLOSE},
        {"label":"return_far","zoom":70.0,"profile":Naval.PROFILE_DISTANT}
    ]:
        camera.size=spec["zoom"]
        var switches:int=0
        for _k in range(8):
            var changed:int=driver.update_budgeted(camera)
            assert(changed<=1,"Android LOD exceeded rebuild budget")
            switches+=changed
            if not driver._pending:
                break
        for i in range(roots.size()):
            var site:Node3D=roots[i]
            assert(site.get_instance_id()==identities[i])
            assert(site.position.is_equal_approx(poses[i]))
            assert(int(site.get_meta("naval_mobile_profile",-1))
                ==int(spec["profile"]))
            assert(int(site.get_meta("mesh_surface_count",99))==(
                5 if int(spec["profile"])==1 else 4))
        assert(game==original,"Zoom touched canonical battle state")
        outcomes.append({"phase":spec["label"],"changes":switches,
            "peak_cpu_step_ms":driver.peak_step_ms})
        if spec["label"] in ["far","close"]:
            await capture(viewport,spec["label"])
    assert(outcomes[1]["changes"]==2)
    assert(outcomes[2]["changes"]==2)
    # Fog: no unobserved enemy naval ownership, upgrades or damage leak.
    var fog:Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],sea,0,true,false,true,true)
    var enemy:Vector2i=shipyards[1]
    var hidden:Node3D=Terrain.build(fog,"",0)
    assert(find_naval(hidden,enemy)==null)
    hidden.free()
    fog["explored"]["0"].append(enemy)
    var rival:Dictionary=Economy.site_at(fog["economy"],enemy)
    rival["visual_level"]=3
    rival["visual_damage_stage"]=4
    var prior:Dictionary=fog.duplicate(true)
    var explored:Node3D=Terrain.build(fog,"",0)
    var grey:Node3D=find_naval(explored,enemy)
    assert(grey!=null)
    assert(int(grey.get_meta("visual_faction",99))==-1)
    assert(int(grey.get_meta("visual_level",99))==1)
    assert(int(grey.get_meta("visual_damage_stage",99))==0)
    assert(fog==prior)
    explored.free()

    var report:Dictionary={
        "engine":"Godot 4.3 native Mesa GL Compat",
        "android_hardware_fps_measured":false,
        "real_coastal_producers":shipyards.size(),
        "land_producers":0,
        "variants":combos,
        "battle_state_unchanged":game==original,
        "naval_camera_lod":outcomes
    }
    var file:=FileAccess.open(OUTPUT+"/report.json",FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    viewport.queue_free()
    print("PASS NAVAL BASE PLAYABLE 3D: two real water-based producers, ",
        combos," variants, 4/5 surfaces, camera LOD with <=1 swap,",
        " fog privacy, unchanged economy, 2 native PNGs")
    quit(0)
