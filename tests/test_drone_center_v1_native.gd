extends SceneTree

# Native Godot 4.3 scene QA for the ACTUAL drone_center producers.
# No unapproved economy, new drone unit or refueling station is created.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Drone=preload("res://scripts/ui/DroneCenterBattle3D.gd")
const Model=preload("res://scripts/ui/DroneCenterModel3D.gd")
const LOD=preload("res://scripts/ui/DroneCenterBattleLOD.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Probe=preload("res://scripts/ui/City3DPerfProbeV7.gd")
const OUTPUT:String="res://artifacts/drone_center_native_v1"

func _initialize() -> void:
    call_deferred("_run")

static func find_drone(scene:Node3D,at:Vector2i) -> Node3D:
    return scene.find_child(
        "Instalacion3D_drone_center_%d_%d" % [at.x,at.y],
        true,false) as Node3D

func capture(view:SubViewport,key:String) -> void:
    for _i in range(4):
        await RenderingServer.frame_post_draw
    var img:Image=view.get_texture().get_image()
    assert(img!=null and img.get_size()==view.size)
    assert(img.save_png(OUTPUT+"/"+key+".png")==OK)

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    assert(Drone.build(0,0,0)==null)
    assert(Drone.build(1,-2,0)==null)
    assert(Drone.build(1,8,0)==null)
    assert(Drone.build(1,0,5)==null)
    assert(Drone.build_site({},{"kind":"factory"},0)==null)
    assert(LOD.choose(118,Drone.DISTANT)==Drone.CLOSE)
    assert(LOD.choose(117,Drone.DISTANT)==Drone.DISTANT)
    assert(LOD.choose(85,Drone.CLOSE)==Drone.DISTANT)
    assert(LOD.choose(86,Drone.CLOSE)==Drone.CLOSE)

    # Eight approved colors, 3 distinct evolution tiers and D0..D4 damage.
    var variants:int=0
    for tier in [1,2,3]:
        for damage in [0,1,2,3,4]:
            for faction in range(8):
                var distant:Node3D=Drone.build(tier,faction,damage)
                var close:Node3D=Drone.build(
                    tier,faction,damage,Drone.CLOSE)
                assert(distant!=null and close!=null)
                var low:MeshInstance3D=distant.get_node(Drone.CHILD_NAME)
                var high:MeshInstance3D=close.get_node(Drone.CHILD_NAME)
                assert(low.mesh.get_surface_count()==4)
                assert(high.mesh.get_surface_count()==(
                    5 if tier>=2 and damage<3 else 4))
                assert(high.mesh.get_faces().size()>
                    low.mesh.get_faces().size())
                assert(bool(high.get_meta("drone_center_native_3d",false)))
                assert(int(distant.get_meta("visual_tier",-1))==tier)
                assert(int(distant.get_meta("visual_damage_stage",-1))
                    ==damage)
                if tier>=2 and damage<3:
                    var glass:Material=high.mesh.surface_get_material(4)
                    assert(glass is StandardMaterial3D)
                    assert((glass as StandardMaterial3D).transparency
                        ==BaseMaterial3D.TRANSPARENCY_ALPHA)
                distant.free()
                close.free()
                variants+=1
    assert(variants==120)
    var neutral:Node3D=Drone.build(3,-1,2,Drone.CLOSE)
    assert(neutral!=null)
    assert(int(neutral.get_meta("visual_faction",99))==-1)
    neutral.free()

    var game:Dictionary=Session.start(Roles.experimental_armies(),
        Scenarios.terrain(0),0,false,false,true,true)
    assert(bool(game["economy"].get("modern",false)))
    var sites:Array=[]
    for item in game["economy"]["sites"]:
        if str(item.get("kind",""))=="drone_center":
            sites.append(item["pos"])
    assert(sites.size()==2)
    var original:Dictionary=game.duplicate(true)
    var battle:Node3D=Terrain.build(game,"",0)
    assert(battle!=null)
    var driver:Node=battle.get_node_or_null("CentroDronesLOD_Camara")
    assert(driver!=null)
    assert(driver.registered_count()==2)
    var instances:Array=driver.get("_sites")
    assert(instances.size()==2)
    for cell in sites:
        var site:Node3D=find_drone(battle,cell)
        assert(site!=null,"Actual game drone producer has no native 3D")
        assert(str(site.get_meta("site_kind",""))=="drone_center")
        assert(str(site.get_meta("kind",""))=="drone_center")
        assert(site.get_meta("battle_cell")==cell)
        assert(str(site.get_meta("production_authority",""))
            =="UrbanEconomy")
        assert(int(site.get_meta("render_surface_count",99))==4)
        assert(site.get_node_or_null(Drone.CHILD_NAME)!=null)
    assert(game==original,"Renderer changed real production state")

    # Test same 3D scene that real Android 3D view instantiates.
    var viewport:=SubViewport.new()
    viewport.name="CentroDrones_Revision3DNativa"
    viewport.size=Vector2i(960,540)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#283b49")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#c5d9e2")
    env.ambient_light_energy=0.72
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-54,-32,0)
    sun.light_energy=1.25
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.1
    camera.far=160.0
    viewport.add_child(camera)
    camera.current=true
    viewport.add_child(battle)
    driver.set_process(false)
    var identities:Array=[]
    var positions:Array[Vector3]=[]
    for item in instances:
        identities.append(item.get_instance_id())
        positions.append(item.position)
    var center:Vector3=(instances[0] as Node3D).global_position
    camera.position=center+Vector3(9.5,13.0,9.0)
    camera.look_at(center,Vector3.UP)
    var results:Array=[]
    for spec in [
        {"name":"distant","zoom":70.0,"expected":Drone.DISTANT},
        {"name":"close","zoom":6.0,"expected":Drone.CLOSE},
        {"name":"back","zoom":70.0,"expected":Drone.DISTANT}
    ]:
        camera.size=float(spec["zoom"])
        var steps:int=0
        var changed_total:int=0
        for _k in range(8):
            var changed:int=driver.update_budgeted(camera)
            assert(changed<=1,"More than one drone center mesh changed")
            changed_total+=changed
            steps+=1
            if not driver._pending:
                break
        for i in range(instances.size()):
            var site:Node3D=instances[i]
            assert(site.get_instance_id()==identities[i])
            assert(site.position.is_equal_approx(positions[i]))
            assert(int(site.get_meta("drone_center_lod",-1))
                ==int(spec["expected"]))
            var mesh:MeshInstance3D=site.get_node(Drone.CHILD_NAME)
            assert(mesh!=null and mesh.mesh!=null)
        assert(game==original,"Camera zoom changed economy or units")
        results.append({"phase":spec["name"],
            "swaps":changed_total,"steps":steps,
            "peak_step_cpu_ms":driver.peak_step_ms})
        if str(spec["name"]) in ["distant","close"]:
            await capture(viewport,str(spec["name"]))
    assert(results[1]["swaps"]==2)
    assert(results[2]["swaps"]==2)

    # Fog-of-war: if position was explored but not visible, show only
    # neutral factory N1/D0; do not reveal owner/upgrades/new damage.
    var fog:Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],Scenarios.terrain(0),0,true,false,true,true)
    var enemy:Vector2i=sites[1]
    var unseen:Node3D=Terrain.build(fog,"",0)
    assert(find_drone(unseen,enemy)==null)
    unseen.free()
    fog["explored"]["0"].append(enemy)
    var rival:Dictionary=Economy.site_at(fog["economy"],enemy)
    rival["visual_level"]=3
    rival["visual_damage_stage"]=4
    var prior:Dictionary=fog.duplicate(true)
    var explored:Node3D=Terrain.build(fog,"",0)
    assert(explored!=null)
    var silhouette:Node3D=find_drone(explored,enemy)
    assert(silhouette!=null)
    assert(int(silhouette.get_meta("visual_faction",99))==-1)
    assert(int(silhouette.get_meta("visual_tier",99))==1)
    assert(int(silhouette.get_meta("visual_damage_stage",99))==0)
    assert(fog==prior)
    explored.free()

    # Existing real device FPS panel must count the centers and their LOD.
    var panel:Control=Probe.new()
    root.add_child(panel)
    panel.call("attach_battle",battle)
    var stats:Dictionary=panel.call("snapshot")
    assert(int(stats["drone_centers"])==2)
    assert(int(stats["drone_lod_far"])==2)
    assert(int(stats["drone_lod_close"])==0)
    assert(int(stats["drone_lod_changes"])>=4)
    var report:Dictionary={
        "model":"Drone Center V1 native Godot, original TARVOKA",
        "real_producers":sites.size(),
        "art_variants":variants,
        "one_mesh_four_or_five_surfaces":true,
        "economy_unchanged":game==original,
        "fog_filtered":fog==prior,
        "captures":["distant.png","close.png"],
        "android_fps_measured":false,
        "test_environment":"Linux Mesa Godot 4.3 GL Compatibility",
        "zoom":results
    }
    var file:=FileAccess.open(OUTPUT+"/report.json",FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    panel.queue_free()
    viewport.queue_free()
    print("PASS DRONE CENTER V1 NATIVE: 2 real producers, 120 variants, ",
        "eight factions, 3 levels, 5 damage stages, close/far mobile LOD,",
        " unmodified economy, filtered fog, two Godot screenshots")
    quit(0)
