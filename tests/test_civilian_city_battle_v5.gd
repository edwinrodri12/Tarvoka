extends SceneTree

# V5: approved civilian-city V1-V4 geometry in the ACTUAL read-only
# 3D battle map; this is not a replacement preview nor a balance patch.
const City=preload("res://scripts/ui/CivilianCityBattle3D.gd")
const V4=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const CityDistance=preload("res://scripts/ui/CivilianCityDistanceLODV6.gd")
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _site(root: Node3D,cell: Vector2i) -> Node3D:
    return root.find_child("Instalacion3D_city_%d_%d" % [
        cell.x,cell.y],true,false) as Node3D

static func _max_horizontal_radius(model: Node3D) -> Vector2:
    # Inspect all eight transformed AABB vertices of every ACTUAL 3D mesh,
    # including child transforms and native city model scaling.
    var furthest:=Vector2.ZERO
    var pending: Array[Dictionary]=[{
        "node":model,"frame":Transform3D.IDENTITY}]
    while not pending.is_empty():
        var visit: Dictionary=pending.pop_back()
        var current: Node=visit["node"]
        var frame: Transform3D=visit["frame"]
        if current is Node3D:
            var local: Transform3D=(current as Node3D).transform
            if current==model:
                # The root may be positioned at x=17 or z=10 on the
                # battlefield. Its placement is NOT part of its footprint.
                local.origin=Vector3.ZERO
            frame=frame*local
        if current is MeshInstance3D:
            var mesh:=current as MeshInstance3D
            if mesh.mesh!=null:
                var bb: AABB=mesh.mesh.get_aabb()
                for index in range(8):
                    var corner: Vector3=frame*bb.get_endpoint(index)
                    furthest.x=maxf(furthest.x,absf(corner.x))
                    furthest.y=maxf(furthest.y,absf(corner.z))
        for child in current.get_children():
            if child is Node3D:
                pending.append({"node":child,"frame":frame})
    return furthest

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _capture_live_city_map(state: Dictionary,close_up: bool=false) -> void:
    # Real playable terrain scene, never the art viewer or a mock render.
    var frame:=SubViewportContainer.new()
    frame.name="TarvokaV5CiudadCapturaReal"
    frame.size=Vector2(1024,640)
    root.add_child(frame)
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1024,640)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg=false
    frame.add_child(viewport)
    var battlefield: Node3D=Terrain.build(state,"",0)
    assert(battlefield!=null)
    viewport.add_child(battlefield)
    assert(_site(battlefield,Vector2i(3,4))!=null)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=6.2 if close_up else 29.0
    viewport.add_child(camera)
    if close_up:
        camera.position=Vector3(11.7,10.2,17.5)
        camera.look_at(Vector3(7.2,0.8,9.6),Vector3.UP)
    else:
        camera.position=Vector3(22.0,27.0,32.0)
        camera.look_at(Vector3(10.8,0.0,8.4),Vector3.UP)
    camera.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-55.0,24.0,0.0)
    sun.light_energy=1.7
    viewport.add_child(sun)
    await _frames(23)
    var result: Image=viewport.get_texture().get_image()
    assert(result!=null and not result.is_empty())
    var palette: Dictionary={}
    for py in range(0,result.get_height(),maxi(1,int(result.get_height()/19))):
        for px in range(0,result.get_width(),maxi(1,int(result.get_width()/24))):
            palette[result.get_pixel(px,py).to_html()]=true
    assert(palette.size()>8)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    var destination: String=(
        "res://artifacts/tarvoka_city_v5_live_closeup.png" if close_up
        else "res://artifacts/tarvoka_city_v5_live_battle.png")
    assert(result.save_png(destination)==OK)
    frame.queue_free()
    await _frames(3)

func _run() -> void:
    var terrain: Array=Scenarios.terrain(0)
    var state: Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true)
    assert(not state.is_empty())
    var untouched: Dictionary=state.duplicate(true)
    var original_credits: Array=state["economy"]["credits"].duplicate(true)
    assert(Economy.income_for(state["economy"],0)==100)
    assert(Economy.income_for(state["economy"],1)==100)
    assert(City.build_site(state,{"kind":"factory"},0)==null)
    assert(City.build(0,0,0)==null)
    assert(City.build(1,8,0)==null)
    assert(City.build(1,0,0,3)==null)

    # All four pre-placed cities become REAL approved V4 mesh models.
    var board: Node3D=Terrain.build(state,"",0)
    assert(board!=null)
    for cell in [Vector2i(2,1),Vector2i(7,1),
                 Vector2i(3,4),Vector2i(6,4)]:
        var model: Node3D=_site(board,cell)
        assert(model!=null)
        assert(model.get_meta("kind")=="city")
        assert(model.get_meta("battle_cell")==cell)
        assert(int(model.get_meta("approved_art_version",-1))==4)
        assert(bool(model.get_meta("game_visual_only",false)))
        assert(bool(model.get_meta("city_economy_untouched",false)))
        assert(model.has_node(V4.STAGE_NAME))
        assert(int(model.get_meta("actual_3d_meshes",0))>15)
        assert(model.scale.is_equal_approx(Vector3.ONE*City.CELL_MODEL_SCALE))
        var footprint: Vector2=_max_horizontal_radius(model)
        assert(footprint.x < Terrain.CELL*0.5)
        assert(footprint.y < Terrain.CELL*0.5)
    assert(int(_site(board,Vector2i(2,1)).get_meta("visual_tier",0))==1)
    assert(int(_site(board,Vector2i(3,4)).get_meta("visual_tier",0))==2)
    assert(_site(board,Vector2i(2,1)).get_meta("owner_public")==0)
    assert(_site(board,Vector2i(7,1)).get_meta("owner_public")==1)
    assert(_site(board,Vector2i(3,4)).get_meta("visual_faction")==-1)
    assert(int(board.get_meta("render_stats")["sites"])>=6)
    board.free()
    assert(state==untouched)
    assert(state["economy"]["credits"]==original_credits)

    # Optional sculpt tiers 1/2/3 and all 5 visual damage states fit a
    # single tile without influencing the engine's site ownership.
    for level in [1,2,3]:
        for damage in [0,1,2,3,4]:
            var sculpt: Node3D=City.build(level,-1,damage,2)
            assert(sculpt!=null)
            assert(sculpt.has_node(V4.STAGE_NAME))
            assert(int(sculpt.get_meta("visual_tier",0))==level)
            assert(int(sculpt.get_meta("visual_damage",-1))==damage)
            var radius: Vector2=_max_horizontal_radius(sculpt)
            assert(radius.x<Terrain.CELL*0.5)
            assert(radius.y<Terrain.CELL*0.5)
            sculpt.free()

    # Every official eight-faction identity is resolved from PUBLIC owner
    # only; an unseen ownership update will not leak the real paint color.
    for faction in range(8):
        var colored: Dictionary=state.duplicate(true)
        var ids: Dictionary=Identity.resolved(
            colored.get(Identity.STATE_FIELD,{}))
        ids["0"]=str(Style.FACTIONS[faction]["key"])
        # Every army uses a DIFFERENT faction identity; otherwise
        # FactionIdentity.resolved rightfully rejects the test fixture.
        ids["1"]=str(Style.FACTIONS[(faction+1)%8]["key"])
        colored[Identity.STATE_FIELD]=ids
        var city_site: Dictionary=Economy.site_at(
            colored["economy"],Vector2i(2,1))
        var painted: Node3D=City.build_site(colored,city_site,0)
        assert(painted!=null)
        assert(int(painted.get_meta("visual_faction",-1))==faction)
        painted.free()
        var masked: Node3D=City.build_site(colored,city_site,-1)
        assert(masked!=null)
        assert(int(masked.get_meta("visual_faction",-2))==-1)
        assert(int(masked.get_meta("public_owner",-2))==-1)
        masked.free()
    assert(state==untouched)

    # An unexplored enemy city is entirely absent; an explored-but-
    # unobserved enemy city remains geometry with neutral palette.
    var fog: Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true)
    var unseen: Node3D=Terrain.build(fog,"",0)
    assert(unseen!=null)
    assert(_site(unseen,Vector2i(7,1))==null)
    unseen.free()
    fog["explored"]["0"].append(Vector2i(7,1))
    var stale: Node3D=Terrain.build(fog,"",0)
    assert(stale!=null)
    var neutral: Node3D=_site(stale,Vector2i(7,1))
    assert(neutral!=null)
    assert(int(neutral.get_meta("owner_public",-9))==-1)
    assert(int(neutral.get_meta("visual_faction",-9))==-1)
    stale.free()

    # An explicitly annotated metropolis remains decorative. The city
    # is not a factory even if it has an elaborate civic center.
    var tiered: Dictionary=untouched.duplicate(true)
    Economy.site_at(tiered["economy"],Vector2i(2,1))["visual_level"]=3
    var tiered_before: Dictionary=tiered.duplicate(true)
    var stage: Node3D=Terrain.build(tiered,"",0)
    assert(int(_site(stage,Vector2i(2,1)).get_meta("visual_tier",0))==3)
    assert(tiered==tiered_before)
    assert(not Session.purchase(tiered,Vector2i(2,1),"scout")["valid"])
    stage.free()
    # V6 adaptive native LOD: preserve the SAME city root, cell, owner
    # and save state while rebuilding only the mesh stages on camera zoom.
    assert(CityDistance.preferred_detail(70.0,2)==0)
    assert(CityDistance.preferred_detail(40.0,0)==0)
    assert(CityDistance.preferred_detail(32.0,0)==1)
    assert(CityDistance.preferred_detail(17.0,1)==1)
    assert(CityDistance.preferred_detail(11.0,1)==2)
    var runtime: Node3D=Terrain.build(state,"",0)
    assert(runtime!=null)
    var dynamic_driver=runtime.get_node_or_null("CiudadesCivilesV6_LOD_Camara")
    assert(dynamic_driver!=null)
    assert(int(runtime.get_meta("render_stats")["city_lod_models"])==4)
    assert(dynamic_driver.cities.size()==4)
    var target_cell:=Vector2i(3,4)
    var same_root: Node3D=_site(runtime,target_cell)
    var before_pos: Vector3=same_root.position
    var before_owner: int=int(same_root.get_meta("owner_public",-5))
    var far_count: int=V4.drawable_count(same_root)
    assert(int(same_root.get_meta("city_lod",-1))==2)
    var zoom_camera:=Camera3D.new()
    zoom_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    zoom_camera.size=3.0
    assert(dynamic_driver.update_now(zoom_camera,540.0)>0)
    assert(_site(runtime,target_cell)==same_root)
    assert(int(same_root.get_meta("city_lod",-1))==0)
    var full_count: int=V4.drawable_count(same_root)
    assert(full_count>far_count*2)
    assert(same_root.position==before_pos)
    assert(int(same_root.get_meta("owner_public",-5))==before_owner)
    assert(same_root.has_node(V4.STAGE_NAME))
    # Reset to a far/mobile camera. The mesh instances themselves vanish,
    # not just their visible flag: important for modest Android hardware.
    zoom_camera.size=90.0
    assert(dynamic_driver.update_now(zoom_camera,540.0)>0)
    assert(int(same_root.get_meta("city_lod",-1))==2)
    assert(V4.drawable_count(same_root)==far_count)
    assert(_site(runtime,target_cell)==same_root)
    assert(state==untouched)
    zoom_camera.free()
    runtime.free()
    if DisplayServer.get_name()!="headless":
        await _capture_live_city_map(state,false)
        await _capture_live_city_map(state,true)
    print("PASS TARVOKA CITY V5 LIVE BATTLE: real V4 art, tiles, variants, 8 factions, fog, immutable economy")
    quit(0)
