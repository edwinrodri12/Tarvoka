extends SceneTree

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Art = preload("res://scripts/ui/LayeredBridgeArtV48.gd")

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
        assert(stats["bridge_clearance_failures_v48"]==int(not bool(ship_report["fits_vertical"]) or not bool(ship_report["fits_channel_width"])))
        assert(is_equal_approx(ship.rotation.y,PI*0.5 if axis=="ns" else 0.0))
        for side in [-1,1]:
            var ramp: Node3D = model.get_node("Rampa_%d_%d_%d" % [cell.x,cell.y,side])
            var mesh: ArrayMesh = ramp.get_child(0).mesh
            assert(mesh.surface_get_array_len(0)==36)
            assert(is_equal_approx(float(ramp.get_meta("deck_y")),Art.ROAD_TOP))
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
    print("PASS V48_4_NATIVE_BRIDGE: real unit bounds, two axes, ramps and read-only water surface")
    quit(0)
