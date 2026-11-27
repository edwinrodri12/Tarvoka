extends SceneTree

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Art = preload("res://scripts/ui/LayeredBridgeArtV48.gd")
const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Playback = preload("res://scripts/ui/LayeredBridgePlaybackV48.gd")
const View = preload("res://scripts/ui/Battle3DMapView.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fixture(id: String,role: String,domain: String,cell: Vector2i,side: int) -> Dictionary:
    return {"id":id,"role":role,"domain":domain,"pos":cell,"faction":side,
        "hp":10,"move_points":3,"attack":4,"defense":1,"cover":0,
        "acted":false,"target_domains":[domain]}

func _run() -> void:
    assert(DisplayServer.get_name()!="headless")
    for axis in ["ew","ns"]:
        var cell := Vector2i(4,3)
        var map: Array = []
        for y in range(8):
            var row: Array = []
            for x in range(10):
                var water: bool = x==cell.x if axis=="ew" else y==cell.y
                row.append("water" if water else "plain")
            map.append(row)
        map[cell.y][cell.x] = "road"
        var units: Array = [_fixture("G","tank","ground",cell,0),
            _fixture("N","destroyer","naval",cell,1),
            _fixture("A","attack_heli","air",cell,0)]
        var state: Dictionary = Session.start_layered(units,map,[{"x":cell.x,"y":cell.y,"axis":axis}])
        assert(not state.is_empty())
        var original: Dictionary = state.duplicate(true)
        var model: Node3D = Terrain.build(state,"G",0)
        assert(model!=null and state==original)
        var stats: Dictionary = model.get_meta("render_stats")
        assert(stats["bridge_spans_v48"]==1 and stats["bridge_ramps_v48"]==2)
        assert(stats["bridge_skipped_ramps_v48"]==0)
        assert(stats["bridge_steep_ramps_v48"]==0)
        var public: Dictionary = model.get_meta("public_cells")
        assert(public[cell]["kind"]=="water" and public[cell]["bridge_axis_v48"]==axis)
        assert(state["terrain"][cell.y][cell.x]=="road")
        var ground: Node3D = model.get_node("Unidad3D_G")
        var ship: Node3D = model.get_node("Unidad3D_N")
        var air: Node3D = model.get_node("Unidad3D_A")
        assert(ground.get_meta("bridge_domain_v48")=="ground")
        assert(ship.get_meta("bridge_domain_v48")=="naval")
        assert(air.get_meta("bridge_domain_v48")=="air")
        var ground_report: Dictionary = ground.get_meta("bridge_clearance_v48")
        var ship_report: Dictionary = ship.get_meta("bridge_clearance_v48")
        assert(not ground_report.get("unmeasured",false))
        assert(not ship_report.get("unmeasured",false))
        assert(absf(float(ground_report["bottom"])-Art.ROAD_TOP)<0.002)
        assert(absf(float(ship_report["bottom"])-Terrain.WATER_LEVEL)<0.002)
        print("V48_CLEARANCE axis=",axis," ground=",ground_report," destroyer=",ship_report)
        # A failed fit is diagnostic evidence, not hidden by scaling the ship.
        assert(ship_report.has("fits_channel_width"))
        assert(ship_report["fits_vertical"] and ship_report["fits_channel_width"])
        assert(stats["bridge_clearance_failures_v48"]==int(not bool(ship_report["fits_vertical"]) or not bool(ship_report["fits_channel_width"])))
        assert(is_equal_approx(ship.rotation.y,PI*0.5 if axis=="ns" else 0.0))
        for side in [-1,1]:
            var ramp: Node3D = model.get_node("Rampa_%d_%d_%d" % [cell.x,cell.y,side])
            var mesh: ArrayMesh = ramp.get_child(0).mesh
            assert(mesh.surface_get_array_len(0)==36)
            assert(is_equal_approx(float(ramp.get_meta("deck_y")),Art.ROAD_TOP))
        var direction := Vector2i.RIGHT if axis=="ew" else Vector2i.DOWN
        var destination: Vector2i = cell+direction*2
        var plan: Dictionary = Playback.quote(state,"G",destination)
        assert(plan["route"]==[cell,cell+direction,destination])
        var offset: float = ground.get_meta("bridge_anchor_offset_v48")
        var start_pose: Dictionary = Playback.sample(model,plan,0.0,offset)
        var middle_pose: Dictionary = Playback.sample(model,plan,0.5,offset)
        var end_pose: Dictionary = Playback.sample(model,plan,1.0,offset)
        assert(start_pose["position"].is_equal_approx(ground.position))
        assert(start_pose["position"].y>middle_pose["position"].y and middle_pose["position"].y>end_pose["position"].y)
        assert(Playback.quote(state,"G",cell+(Vector2i.DOWN if axis=="ew" else Vector2i.RIGHT)).is_empty())
        var naval_state: Dictionary = state.duplicate(true)
        naval_state["faction"] = 1
        var channel: Vector2i = Vector2i.DOWN if axis=="ew" else Vector2i.RIGHT
        var naval_plan: Dictionary = Playback.quote(naval_state,"N",cell+channel*2)
        assert(naval_plan["route"]==[cell,cell+channel,cell+channel*2])
        var ship_offset: float = ship.get_meta("bridge_anchor_offset_v48")
        for progress in [0.0,0.25,0.5,0.75,1.0]:
            var pose: Dictionary = Playback.sample(model,naval_plan,progress,ship_offset)
            assert(is_equal_approx(pose["position"].y,Terrain.WATER_LEVEL+ship_offset))
        assert(state==original)
        root.add_child(model)
        var light := DirectionalLight3D.new()
        light.rotation_degrees = Vector3(-55,-35,0)
        light.light_energy = 1.1
        root.add_child(light)
        var camera := Camera3D.new()
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = 9.0
        root.add_child(camera)
        var focus: Vector3 = Terrain.world_at(cell)+Vector3.UP*0.85
        camera.position = focus+Vector3(7,4,8) if axis=="ew" else focus+Vector3(8,4,-7)
        camera.look_at(focus)
        camera.make_current()
        for frame in range(12):
            await process_frame
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        assert(image!=null and not image.is_empty())
        DirAccess.make_dir_recursive_absolute("res://artifacts")
        assert(image.save_png("res://artifacts/tarvoka_bridge_v48_4_%s.png" % axis)==OK)
        model.free()
        light.free()
        camera.free()
        var viewer: Control = View.new()
        root.add_child(viewer)
        assert(viewer.open_from_state(state,"G",0))
        assert(viewer.inspect_cell(cell))
        assert(viewer._choose_unit_button.visible)
        viewer._choose_unit_here()
        assert(viewer._selected_hint_unit_id=="G")
        viewer._choose_unit_here()
        assert(viewer._selected_hint_unit_id=="N")
        viewer._choose_unit_here()
        assert(viewer._selected_hint_unit_id=="A")
        viewer._choose_unit_here()
        assert(viewer._selected_hint_unit_id=="G")
        var moving: Node3D = viewer._scene.get_node("Unidad3D_G")
        var original_pose: Transform3D = moving.transform
        assert(viewer.tap_battle_cell(destination))
        viewer._advance_bridge_playback(0.48)
        assert(moving.position.y<original_pose.origin.y)
        viewer._advance_bridge_playback(2.0)
        assert(moving.transform.is_equal_approx(original_pose))
        assert(viewer._state_snapshot==state and state==original)
        viewer.close_view()
        viewer.free()
    _check_mixed_and_fog()
    await _capture_mixed_regions()
    await _stress_large_regions()
    print("PASS V48_4_NATIVE_BRIDGE: real unit bounds, two axes, ramps and read-only water surface")
    quit(0)

func _check_mixed_and_fog() -> void:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("water" if x==4 else "plain")
        map.append(row)
    var bridge := Vector2i(4,3)
    map[3][4] = "road"
    var unit: Dictionary = _fixture("F","tank","ground",Vector2i(0,0),0)
    unit["vision"] = 1
    var enemy: Dictionary = _fixture("E","destroyer","naval",bridge,1)
    var state: Dictionary = Session.start_layered([unit,enemy],map,[{"x":4,"y":3,"axis":"ew"}],0,"clear",true)
    assert(not state.is_empty())
    state[Regions.FIELD] = {"version":1,"primary":"temperate","secondary":"winter"}
    state[Regions.SEED_FIELD] = 1729
    var model: Node3D = Terrain.build(state,"F",0)
    assert(model!=null)
    var cells: Dictionary = model.get_meta("public_cells")
    assert(cells[bridge]["kind"]=="unknown" and not cells[bridge].has("mixed_region_v49"))
    assert(not cells[bridge].has("bridge_axis_v48"))
    assert(not model.has_node("Unidad3D_E"))
    assert(model.get_meta("render_stats")["bridge_spans_v48"]==0)
    assert(cells[Vector2i.ZERO].has("mixed_region_v49"))
    model.free()
    var plain: Dictionary = Session.start([],map)
    plain[Regions.FIELD] = state[Regions.FIELD].duplicate(true)
    plain[Regions.SEED_FIELD] = 1729
    var before: Dictionary = plain.duplicate(true)
    var mixed: Node3D = Terrain.build(plain)
    assert(mixed!=null and mixed.get_meta("mixed_pigments_v49"))
    var public: Dictionary = mixed.get_meta("public_cells")
    var north: Dictionary = public[Vector2i(2,0)]
    var south: Dictionary = public[Vector2i(2,7)]
    assert(north["mixed_region_v49"]["secondary_weight"]==0)
    assert(south["mixed_region_v49"]["secondary_weight"]==1000)
    assert(Terrain._tint(north)!=Terrain._tint(south))
    assert(Codec.decode(Codec.encode(plain))==plain and plain==before)
    mixed.free()
    # Force visible examples of both forests and mountains, and verify
    # region instancing uses the full surrounding height map.
    for cell in [Vector2i(2,1),Vector2i(7,1),Vector2i(2,6),Vector2i(7,6)]:
        map[cell.y][cell.x] = "forest"
    for cell in [Vector2i(3,1),Vector2i(6,1),Vector2i(3,6),Vector2i(6,6)]:
        map[cell.y][cell.x] = "mountain"
    var art_state: Dictionary = Session.start([],map)
    art_state[Regions.FIELD] = {"version":1,"primary":"tropical","secondary":"winter"}
    art_state[Regions.SEED_FIELD] = 1729
    var art_before: Dictionary = art_state.duplicate(true)
    var art: Node3D = Terrain.build(art_state)
    assert(art!=null)
    assert(art.has_node("VegetacionRegional_tropical/BosqueInstanciado3D"))
    assert(art.has_node("VegetacionRegional_winter/NieveEnConiferasInstanciadaV20"))
    assert(art.has_node("RelieveRegional_tropical/Macizos3DPorBiomaV20"))
    assert(art.has_node("RelieveRegional_winter/Macizos3DPorBiomaV20"))
    var stats: Dictionary = art.get_meta("render_stats")
    assert(stats["regional_tree_groups_v49"]==2 and stats["regional_ridge_groups_v49"]==2)
    assert(stats["trees"]==8 and stats["mountain_ridges"]==4)
    assert(stats["biome_extra_batches"]<=4 and stats["shared_chunk_materials_v27"]<=3)
    assert(art_state==art_before)
    art.free()

func _capture_mixed_regions() -> void:
    for pair in [["temperate","winter"],["desert","tropical"],["wetland","urban"],["coastal","archipelago"]]:
        var dims := Vector2i(24,18)
        var config: Dictionary = {"version":1,"primary":pair[0],"secondary":pair[1]}
        var map: Array = Regions.geographic_candidate(1729,dims,config)
        var state: Dictionary = Session.start([],map)
        state[Regions.FIELD] = config
        state[Regions.SEED_FIELD] = 1729
        var snapshot: Dictionary = state.duplicate(true)
        var model: Node3D = Terrain.build(state)
        assert(model!=null and state==snapshot)
        root.add_child(model)
        var light := DirectionalLight3D.new()
        light.rotation_degrees = Vector3(-55,-35,0)
        light.light_energy = 1.15
        root.add_child(light)
        var camera := Camera3D.new()
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = 49.0
        root.add_child(camera)
        var focus: Vector3 = Terrain.world_at(Vector2i(11,8))
        camera.position = focus+Vector3(18,45,42)
        camera.look_at(focus)
        camera.make_current()
        for frame in range(12):
            await process_frame
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        assert(image!=null and not image.is_empty())
        assert(image.save_png("res://artifacts/tarvoka_mixed_v49_6_%s_%s.png" % pair)==OK)
        print("V49_MIXED_STATS pair=",pair," stats=",model.get_meta("render_stats"))
        model.free()
        light.free()
        camera.free()

# V50.2: bounded CPU/GPU stress fixture, not a physical Android benchmark.
# No unstable machine-dependent timing threshold; hard bounds cover resource
# counts, state invariance and actual viewport output.
func _stress_large_regions() -> void:
    var dims := Vector2i(40,30)
    for pair in [["desert","tropical"],["wetland","archipelago"]]:
        var config: Dictionary = {"version":1,"primary":pair[0],"secondary":pair[1]}
        var map: Array = Regions.geographic_candidate(1729,dims,config)
        var state: Dictionary = Session.start([],map)
        state[Regions.FIELD] = config
        state[Regions.SEED_FIELD] = 1729
        var before: Dictionary = state.duplicate(true)
        var model: Node3D = Terrain.build(state)
        assert(model!=null and state==before)
        var stats: Dictionary = model.get_meta("render_stats")
        var max_corners: int = (dims.x+1)*(dims.y+1)
        assert(stats["chunks"]==20)
        assert(stats["land"]+stats["water"]+stats["unknown"]==1200)
        assert(stats["height_samples_v42"]<=max_corners)
        assert(stats["terrain_blend_palette_samples"]<=max_corners)
        assert(stats["water_palette_samples_v27"]<=max_corners)
        assert(stats["shared_chunk_materials_v27"]<=3)
        assert(stats["regional_tree_groups_v49"]<=2 and stats["regional_ridge_groups_v49"]<=2)
        assert(stats["biome_extra_batches"]<=4)
        assert(stats["scene_build_ms_v50"]>=stats["chunk_build_ms_v42"])
        assert(stats["scene_build_ms_v50"]>=stats["landscape_build_ms_v50"])
        root.add_child(model)
        var light := DirectionalLight3D.new()
        light.rotation_degrees = Vector3(-55,-35,0)
        light.light_energy = 1.15
        root.add_child(light)
        var camera := Camera3D.new()
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = 83.0
        root.add_child(camera)
        var focus: Vector3 = Terrain.world_at(Vector2i(19,14))
        camera.position = focus+Vector3(35,75,65)
        camera.look_at(focus)
        camera.make_current()
        for frame in range(12):
            await process_frame
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        assert(image!=null and not image.is_empty())
        assert(image.save_png("res://artifacts/tarvoka_mixed_v50_2_large_%s_%s.png" % pair)==OK)
        print("V50_LARGE_MAP pair=",pair," scene_ms=",stats["scene_build_ms_v50"],
            " chunk_ms=",stats["chunk_build_ms_v42"]," landscape_ms=",stats["landscape_build_ms_v50"],
            " stats=",stats)
        assert(state==before)
        model.free()
        light.free()
        camera.free()
