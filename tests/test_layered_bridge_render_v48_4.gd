extends SceneTree

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Art = preload("res://scripts/ui/LayeredBridgeArtV48.gd")
const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Playback = preload("res://scripts/ui/LayeredBridgePlaybackV48.gd")
const View = preload("res://scripts/ui/Battle3DMapView.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Orders = preload("res://scripts/ui/Battle3DOrders.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

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
        assert(ground_report.has("fits_deck_width"))
        assert(is_equal_approx(float(ground_report["deck_width"]),Art.ROAD_WIDTH))
        assert(is_equal_approx(ground.rotation.y,PI*0.5 if axis=="ew" else 0.0))
        # Measured native tank is 2.2244 units wide. Require an actual fit
        # with 0.03 margin on each side, not just successful diagnostics.
        assert(ground_report["fits_vertical"] and ground_report["fits_deck_width"])
        assert(stats["bridge_clearance_failures_v48"]==0)
        var span: Node3D = model.get_node("PuenteElevado_%d_%d" % [cell.x,cell.y])
        assert(float(span.get_meta("rail_inner_width_v50"))>=Art.ROAD_WIDTH-0.001)
        assert(Art.DECK_WIDTH<=Art.CELL)
        var air_bounds: Dictionary = Art.model_bounds(air)
        var ground_bounds: Dictionary = Art.model_bounds(ground)
        assert(air_bounds["valid"] and ground_bounds["valid"])
        var air_box: AABB = air_bounds["bounds"]
        var ground_box: AABB = ground_bounds["bounds"]
        assert(air_box.position.y>=ground_box.end.y+0.05)
        assert(is_equal_approx(ship.rotation.y,PI*0.5 if axis=="ns" else 0.0))
        for side in [-1,1]:
            var ramp: Node3D = model.get_node("Rampa_%d_%d_%d" % [cell.x,cell.y,side])
            var mesh: ArrayMesh = ramp.get_child(0).mesh
            assert(mesh.surface_get_array_len(0)==36)
            assert(is_equal_approx(float(ramp.get_meta("deck_y")),Art.ROAD_TOP))
            assert(is_equal_approx(float(ramp.get_meta("road_width_v50")),Art.ROAD_WIDTH))
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
        camera.size = 11.5
        root.add_child(camera)
        var focus: Vector3 = Terrain.world_at(cell)+Vector3.UP*2.1
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
    _check_live_layered_orders()
    _check_mixed_and_fog()
    await _capture_mixed_regions()
    await _stress_large_regions()
    await _capture_urban_finish()
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

# V50.6 explicit opt-in native view uses actual TouchBoard confirmations.
func _check_live_layered_orders() -> void:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("water" if x==4 else "plain")
        map.append(row)
    var cell := Vector2i(4,3)
    map[3][4] = "road"
    var attacker: Dictionary = _fixture("P","attack_heli","air",Vector2i(3,3),0)
    attacker["target_domains"] = ["ground","naval","air"]
    var units: Array = [attacker,_fixture("G","tank","ground",cell,1),_fixture("N","destroyer","naval",cell,1),_fixture("A","attack_heli","air",cell,1)]
    var state: Dictionary = Session.start_layered(units,map,[{"x":4,"y":3,"axis":"ew"}])
    assert(not state.is_empty())
    var hints: Dictionary = Hints.for_unit(state,"P")
    assert(hints["attacks_by_id"].size()==3)
    var board: Control = Board.new()
    root.add_child(board)
    board.set("state",state.duplicate(true))
    board.set("ai_enabled",false)
    board.set("require_order_confirmation",true)
    board.set("autosave_enabled",false)
    var viewer: Control = View.new()
    root.add_child(viewer)
    assert(not viewer.open_from_board(board))
    board.set("allow_layered_3d",true)
    assert(viewer.open_from_board(board))
    assert(viewer._select_3d_unit("P"))
    assert(viewer._ranges_node.get_meta("counts")["attacks"]==3)
    assert(viewer.tap_battle_cell(cell))
    assert(viewer._order_quote["order"]["target_id"]=="A")
    assert(viewer.tap_battle_cell(cell) and board.get("state")==state)
    assert(viewer._choose_order_button.visible)
    viewer._cycle_layered_order()
    assert(viewer._order_quote["order"]["target_id"]=="G")
    viewer._cycle_layered_order()
    assert(viewer._order_quote["order"]["target_id"]=="N")
    assert(board.get("state")==state)
    viewer._cancel_3d_order()
    assert(board.get("pending_order").is_empty() and board.get("state")==state)
    assert(viewer.tap_battle_cell(cell))
    viewer._cycle_layered_order()
    viewer._cycle_layered_order()
    var expected: Dictionary = Session.attack(state,"P","N")
    assert(expected["valid"])
    viewer._confirm_3d_order()
    assert(board.get("state")==expected["state"])
    assert(board.get("state")["units"][1]["hp"]==state["units"][1]["hp"])
    assert(board.get("state")["units"][3]["hp"]==state["units"][3]["hp"])
    viewer.close_view()
    # The same destination can contain a hostile naval unit without blocking
    # a ground order. Test stale preview rejection and exact real commit.
    var mover: Dictionary = Roles.make_unit("M",0,Vector2i(3,3),"tank")
    var movement: Dictionary = Session.start_layered([mover,Roles.make_unit("N",1,cell,"destroyer"),
        Roles.make_unit("A",0,cell,"attack_heli")],map,[{"x":4,"y":3,"axis":"ew"}])
    board.set("state",movement.duplicate(true))
    board.set("selected_id","")
    assert(viewer.open_from_board(board) and viewer._select_3d_unit("M"))
    assert(viewer.tap_battle_cell(cell))
    assert(viewer._order_quote["order"]["kind"]=="move")
    assert(board.get("state")==movement)
    var stale: Dictionary = movement.duplicate(true)
    stale["units"][0]["hp"] -= 1
    board.set("state",stale)
    viewer._confirm_3d_order()
    assert(board.get("state")==stale and board.get("pending_order").is_empty())
    board.set("state",movement.duplicate(true))
    assert(viewer.open_from_board(board) and viewer._select_3d_unit("M"))
    assert(viewer.tap_battle_cell(cell))
    var moved: Dictionary = Session.move(movement,"M",cell)
    assert(moved["valid"])
    viewer._confirm_3d_order()
    assert(board.get("state")==moved["state"])
    assert(viewer._bridge_playback.get("committed",false))
    var moving_model: Node3D = viewer._scene.get_node("Unidad3D_M")
    var destination_pose: Transform3D = viewer._bridge_original_pose
    assert(not moving_model.transform.is_equal_approx(destination_pose))
    viewer._advance_bridge_playback(0.24)
    assert(board.get("state")==moved["state"])
    viewer._advance_bridge_playback(2.0)
    assert(viewer._bridge_playback.is_empty() and moving_model.transform.is_equal_approx(destination_pose))
    assert(Codec.decode(Codec.encode(board.get("state")))==board.get("state"))
    var ended: Dictionary = Session.end_turn(moved["state"])
    assert(ended["valid"])
    viewer._finish_layered_turn()
    assert(board.get("state")==ended["state"])
    # A fog-hidden stacked target cannot be offered even by a forged ID.
    var scout: Dictionary = _fixture("F","tank","ground",Vector2i(1,3),0)
    scout["vision"] = 1
    scout["attack_range"] = 5
    scout["target_domains"] = ["ground","naval","air"]
    var fog: Dictionary = Session.start_layered([scout,_fixture("N","destroyer","naval",cell,1)],map,[{"x":4,"y":3,"axis":"ew"}],0,"clear",true)
    assert(not fog.is_empty())
    assert(Orders.layered_intents(fog,"F",cell).is_empty())
    assert(Orders.legal_intent(fog,"F",cell,"attack","N").is_empty())
    viewer.close_view()
    viewer.free()
    board.free()
    print("PASS V50_6_LIVE_LAYERED: exact target cycling, cancel, explicit commit and opt-in guard")

func _capture_urban_finish() -> void:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var surface: Dictionary = {"x":0,"z":0,"top":0.2,"half":1.2,"corners":PackedFloat32Array([0.2,0.2,0.2,0.2])}
    Terrain._append_urban_plaza(tool,Vector3.ZERO,surface,Vector2i(0,0))
    var mesh: ArrayMesh = tool.commit()
    # 15 subdivided quads (8 triangles each) and 8 utility-cover triangles.
    assert(mesh.surface_get_array_len(0)==384)
    var bounds: AABB = mesh.get_aabb()
    assert(bounds.position.x>=-1.2 and bounds.end.x<=1.2)
    assert(bounds.position.z>=-1.2 and bounds.end.z<=1.2)
    assert(bounds.end.y<=0.25)
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("road" if y==3 else ("forest" if x==2 and y in [1,5] else "plain"))
        map.append(row)
    var state: Dictionary = Session.start([],map)
    state["visual_biome"] = "urban"
    var original: Dictionary = state.duplicate(true)
    var model: Node3D = Terrain.build(state)
    assert(model!=null and state==original)
    assert(model.get_meta("render_stats")["shared_chunk_materials_v27"]<=3)
    root.add_child(model)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55,-35,0)
    light.light_energy = 1.1
    root.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 12.0
    root.add_child(camera)
    var focus: Vector3 = Terrain.world_at(Vector2i(4,3))
    for angle in [0,1]:
        camera.position = focus+(Vector3(9,13,10) if angle==0 else Vector3(-10,9,8))
        camera.look_at(focus)
        camera.make_current()
        for frame in range(12):
            await process_frame
        await RenderingServer.frame_post_draw
        var capture: Image = root.get_texture().get_image()
        assert(capture!=null and not capture.is_empty())
        assert(capture.save_png("res://artifacts/tarvoka_urban_v51_3_%d.png" % angle)==OK)
    assert(state==original)
    model.free()
    light.free()
    camera.free()
    print("PASS V51_3_URBAN: bounded plaza mesh, shared materials and two native captures")
