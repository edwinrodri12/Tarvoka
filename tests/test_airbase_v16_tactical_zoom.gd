extends SceneTree

# Native Godot 4.3 acceptance: actual modern BattleTerrain3D airbase sites.
# V16-inspired close fidelity is ONE mesh (5 or 4 material surfaces), not
# a 300-node Art Studio attached to each production tile.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Airbase=preload("res://scripts/ui/AirbaseBattle3D.gd")
const Driver=preload("res://scripts/ui/AirbaseBattleLOD.gd")
const Proxy=preload("res://scripts/ui/AirbaseMapLODV4.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Probe=preload("res://scripts/ui/City3DPerfProbeV7.gd")
const OUTPUT="res://artifacts/airbase_v16_tactical_zoom"

func _initialize() -> void:
    call_deferred("_run")

func _capture(view:SubViewport,name:String) -> void:
    for _i in range(4):
        await RenderingServer.frame_post_draw
    var shot:Image=view.get_texture().get_image()
    assert(shot!=null and shot.get_size()==view.size)
    assert(shot.save_png(OUTPUT+"/"+name+".png")==OK)

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    assert(Driver.choose_detail(114,Airbase.PROFILE_DISTANT)
        ==Airbase.PROFILE_DISTANT)
    assert(Driver.choose_detail(115,Airbase.PROFILE_DISTANT)
        ==Airbase.PROFILE_CLOSE)
    assert(Driver.choose_detail(86,Airbase.PROFILE_CLOSE)
        ==Airbase.PROFILE_CLOSE)
    assert(Driver.choose_detail(85,Airbase.PROFILE_CLOSE)
        ==Airbase.PROFILE_DISTANT)
    for jitter in [86.0,112.0,94.0,110.0,90.0]:
        assert(Driver.choose_detail(jitter,Airbase.PROFILE_CLOSE)
            ==Airbase.PROFILE_CLOSE)
        assert(Driver.choose_detail(jitter,Airbase.PROFILE_DISTANT)
            ==Airbase.PROFILE_DISTANT)
    assert(Airbase.build(2,-2,0,Airbase.PROFILE_CLOSE)==null)
    assert(Airbase.build(2,9,0,Airbase.PROFILE_CLOSE)==null)

    # Exhaustively exercise 8 factions × 3 tiers × 5 damage stages.
    # Close D3 and D4 MUST NOT regenerate operational tower glazing.
    var checked:int=0
    for tier in [1,2,3]:
        for damage in [0,1,2,3,4]:
            for faction in range(8):
                var far:Node3D=Airbase.build(tier,faction,damage)
                var near:Node3D=Airbase.build(
                    tier,faction,damage,Airbase.PROFILE_CLOSE)
                assert(far!=null and near!=null)
                var far_mesh:MeshInstance3D=far.get_node(Airbase.CHILD_NAME)
                var near_mesh:MeshInstance3D=near.get_node(Airbase.CHILD_NAME)
                assert(far_mesh.mesh.get_surface_count()==4)
                assert(near_mesh.mesh.get_surface_count()==(
                    5 if damage<3 else 4))
                assert(near_mesh.mesh.get_faces().size()>
                    far_mesh.mesh.get_faces().size())
                assert(near.get_meta("airbase_close_fidelity",false))
                assert(not far.get_meta("airbase_close_fidelity",true))
                near.free()
                far.free()
                checked+=1
    assert(checked==120)
    var neutral:Node3D=Airbase.build(3,-1,0,Airbase.PROFILE_CLOSE)
    assert(neutral!=null)
    assert(int(neutral.get_meta("visual_faction",99))==-1)
    neutral.free()

    var state:Dictionary=Session.start(Roles.experimental_armies(),
        Scenarios.terrain(0),0,false,false,true,true)
    assert(bool(state["economy"].get("modern",false)))
    var source:Dictionary=state.duplicate(true)
    var visual:Node3D=Terrain.build(state,"",0)
    assert(visual!=null)
    var air:Node=visual.get_node_or_null("BaseAereaLOD_Camara")
    assert(air!=null and air is TarvokaAirbaseBattleLOD)
    assert(air.registered_count()==2)

    var viewport:=SubViewport.new()
    viewport.name="PruebaBaseAereaGodot43Real"
    viewport.size=Vector2i(960,540)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var sky:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#2c4250")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dbe3e9")
    env.ambient_light_energy=0.55
    sky.environment=env
    viewport.add_child(sky)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-26,0)
    sun.light_energy=1.15
    sun.shadow_enabled=false
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.far=160.0
    camera.near=0.1
    viewport.add_child(camera)
    camera.current=true
    viewport.add_child(visual)
    air.set_process(false)

    var sites:Array=air.get("_sites")
    assert(sites.size()==2)
    var positions:Array[Vector3]=[]
    var ids:Array[int]=[]
    for site in sites:
        assert(str(site.get_meta("site_kind",""))=="airbase")
        positions.append(site.position)
        ids.append(site.get_instance_id())

    var center:Vector3=(sites[0] as Node3D).global_position
    camera.position=center+Vector3(9.0,12.5,10.0)
    camera.look_at(center,Vector3.UP)
    var phases:Array=[]
    for spec in [
        {"name":"far","camera":70.0,"profile":Airbase.PROFILE_DISTANT},
        {"name":"close","camera":7.0,"profile":Airbase.PROFILE_CLOSE},
        {"name":"return_far","camera":70.0,"profile":Airbase.PROFILE_DISTANT}
    ]:
        camera.size=float(spec["camera"])
        var total:int=0
        var steps:int=0
        for _i in range(6):
            var changed:int=air.update_budgeted(camera)
            assert(changed<=1,"More than one site rebuilt in a zoom step")
            total+=changed
            steps+=1
            if not air._pending_transition:
                break
        var expected:int=int(spec["profile"])
        for i in range(sites.size()):
            var site:Node3D=sites[i]
            assert(site.get_instance_id()==ids[i])
            assert(site.position.is_equal_approx(positions[i]))
            assert(int(site.get_meta("airbase_lod_profile",-1))==expected)
            var mesh:MeshInstance3D=site.get_node_or_null(
                Airbase.CHILD_NAME)
            assert(mesh!=null and mesh.mesh!=null)
            assert(mesh.mesh.get_surface_count()==(5 if expected==1 else 4))
        assert(state==source,"Visual camera changed gameplay state")
        phases.append({"phase":str(spec["name"]),"sites_changed":total,
            "steps":steps,"peak_step_cpu_ms":air.peak_step_ms})
        if str(spec["name"]) in ["far","close"]:
            await _capture(viewport,str(spec["name"]))
    assert(int(phases[1]["sites_changed"])==2)
    assert(int(phases[2]["sites_changed"])==2)

    var probe:Control=Probe.new()
    root.add_child(probe)
    probe.call("attach_battle",visual)
    var snap:Dictionary=probe.call("snapshot")
    assert(int(snap["airbases"])==2)
    assert(int(snap["airbase_lod_distant"])==2)
    assert(int(snap["airbase_lod_close"])==0)
    assert(int(snap["airbase_lod_changes"])>=4)
    assert(float(snap["airbase_peak_step_ms"])>0.0)
    assert(state==source)
    var report:Dictionary={"engine":"Godot 4.3 GL Compatibility",
        "hardware":"Linux Mesa software OpenGL, NOT Android hardware",
        "real_modern_airbase_sites":2,
        "art_variant_combinations":checked,
        "zero_impact_on_game_state":state==source,
        "profiles":phases,"fps_overlay":snap}
    var output:=FileAccess.open(OUTPUT+"/report.json",FileAccess.WRITE)
    assert(output!=null)
    output.store_string(JSON.stringify(report,"  "))
    output.close()
    probe.queue_free()
    viewport.queue_free()
    print("PASS AIRBASE V16 TACTICAL ZOOM: 120 native close and distant variants;",
        " 2 playable producers, 1 mesh 4/5 surfaces, budgeted LOD,",
        " FPS probe, fog-safe economy, 2 rendered PNGs")
    quit(0)
