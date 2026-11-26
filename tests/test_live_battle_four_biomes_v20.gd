extends SceneTree

# V20 acceptance: all four biomes in real 3D tactical battles, not a demo.
# Rendered mesh geometry, chunk LOD budgets, fog secrecy, playable touch
# orders, saved weather-independent visual biomes and Android UI entrypoints.
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _check_biome(value: String,dims: Vector2i,
        fog: bool = false) -> Dictionary:
    var map: Array = Scenarios.seeded_terrain(22435,dims)
    var units: Array = [
        {"id":"F","role":"line","faction":0,"hp":10,
            "pos":Vector2i(1,1),"move_points":3,"attack":4,"acted":false},
        {"id":"E","role":"tank","faction":1,"hp":10,
            "pos":Vector2i(dims.x-2,dims.y-2),"move_points":3,
            "attack":4,"acted":false}
    ]
    var state: Dictionary = Session.start(
        units,map,0,fog,true,false,false,false)
    if value != Biomes.TEMPERATE:
        state[Biomes.FIELD] = value
    var original: Dictionary = state.duplicate(true)
    # Minimal Session.start fixtures omit actual roster defaults. Their
    # legacy codec validity is exercised below on real TouchBoard state.
    var model: Node3D = Terrain.build(state,"F")
    assert(model!=null and model.get_meta("visual_only"))
    assert(model.get_meta("board_size")==dims)
    assert(model.get_meta("visual_biome")==value)
    var stats: Dictionary = model.get_meta("render_stats")
    assert(stats["chunks"]==int(ceili(float(dims.x)/8.0))*int(
        ceili(float(dims.y)/8.0)))
    assert(int(stats["land"])+int(stats["water"])+int(stats["unknown"])
        ==dims.x*dims.y)
    assert(int(stats["terrain_blend_extra_batches"])==0)
    assert(int(stats["biome_extra_batches"])<=2)
    assert(int(stats["terrain_blend_palette_samples"])<=(dims.x+1)*(dims.y+1))
    assert(model.get_meta("public_cells").size()==dims.x*dims.y)
    assert(model.find_child("Unidad3D_F",true,false)!=null)
    if fog:
        var public: Dictionary = model.get_meta("public_cells")
        for cell in public:
            var exposed: Dictionary = public[cell]
            if not bool(exposed["seen"]):
                assert(exposed["kind"]=="unknown")
                assert(not exposed["details"])
        assert(int(stats["units"]["hidden_enemies"])>=1)
        assert(model.find_child("Unidad3D_E",true,false)==null)
    else:
        var ridges: MultiMeshInstance3D = model.find_child(
            "Macizos3DPorBiomaV20",true,false) as MultiMeshInstance3D
        assert(int(stats["mountain_ridges"])>0 and ridges!=null)
        assert(ridges.multimesh.instance_count==int(stats["mountain_ridges"]))
        var woods: MultiMeshInstance3D = model.find_child(
            "BosqueInstanciado3D",true,false) as MultiMeshInstance3D
        assert(int(stats["trees"])>0 and woods!=null)
        if value==Biomes.WINTER:
            assert(model.find_child(
                "NieveEnConiferasInstanciadaV20",true,false)!=null)
        else:
            assert(model.find_child(
                "NieveEnConiferasInstanciadaV20",true,false)==null)
    assert(state==original)
    model.free()
    return stats

# V21: the east bank at a chunk boundary must meet both the
# shared land corners and the exact water plane; unknown water is not drawn.
func _check_water_bank_geometry() -> void:
    var cell := Vector2i(7,3)
    var at: Vector3 = Terrain.world_at(cell)
    var h: float = Terrain.CELL*0.5
    var top: Array[Vector3] = [
        at+Vector3(-h,0.20,-h),at+Vector3(h,0.35,-h),
        at+Vector3(h,0.45,h),at+Vector3(-h,0.19,h)]
    var cells: Dictionary = {}
    cells[cell] = {"kind":"road"}
    cells[cell+Vector2i(1,0)] = {"kind":"water","seen":true}
    cells[cell+Vector2i(-1,0)] = {"kind":"unknown","seen":false}
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    assert(Terrain._append_water_banks(surface,cells,cell,top,Color.WHITE)==1)
    var mesh: ArrayMesh = surface.commit()
    var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    assert(vertices.size()==6)
    var high_count := 0
    var low_count := 0
    for v in vertices:
        assert(is_equal_approx(v.x,at.x+h))
        if is_equal_approx(v.y,Terrain.WATER_LEVEL):
            low_count += 1
        else:
            assert(v.is_equal_approx(top[1]) or v.is_equal_approx(top[2]))
            high_count += 1
    assert(high_count==3 and low_count==3)
    cells[cell+Vector2i(1,0)] = {"kind":"unknown","seen":false}
    var hidden := SurfaceTool.new()
    hidden.begin(Mesh.PRIMITIVE_TRIANGLES)
    assert(Terrain._append_water_banks(hidden,cells,cell,top,Color.WHITE)==0)

func _run() -> void:
    _check_water_bank_geometry()
    root.content_scale_size = Vector2i(1280,800)
    assert(Biomes.CHOICES.size()==4)
    assert(Biomes.from_index(0)==Biomes.TEMPERATE)
    assert(Biomes.from_index(1)==Biomes.WINTER)
    assert(Biomes.from_index(2)==Biomes.CANYON)
    assert(Biomes.from_index(3)==Biomes.COASTAL)
    assert(Biomes.index_for({})==0)
    assert(Biomes.index_for({Biomes.FIELD:Biomes.WINTER})==1)
    assert(not Biomes.valid("unknown"))
    var different_colors: Dictionary = {}
    for value in Biomes.CHOICES:
        var c: Color = Terrain._biome_color("mountain",Vector2i(3,3),value)
        different_colors[c.to_html()] = true
        var s: Color = Terrain._biome_color("plain",Vector2i(2,4),value)
        assert(c!=s)
        _check_biome(value,Vector2i(10,8))
    assert(different_colors.size()==4)
    _check_biome(Biomes.COASTAL,Vector2i(24,18))
    _check_biome(Biomes.WINTER,Vector2i(40,30))
    _check_biome(Biomes.CANYON,Vector2i(40,30),true)

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    for i in range(7):
        await process_frame
    assert(main.biome_picker.item_count==4)
    assert(main.skirmish_setup.biome_picker.item_count==4)
    assert(main.battle_3d_button!=null)
    assert(main.compact_3d!=null)
    assert(main.battle_3d_view==null)
    var board: Control = main.board
    board.ai_enabled=false
    board.autosave_enabled=false
    board.new_game(1,true,false,false,true,false,false,0,0,
        Vector2i(10,8),{},"clear",false,Biomes.COASTAL)
    assert(board.state[Biomes.FIELD]==Biomes.COASTAL)
    main._continue_from_home()
    var original: Dictionary = board.state.duplicate(true)
    main._open_battle_3d()
    var viewer: Control = main.battle_3d_view
    assert(viewer!=null and viewer.visible)
    assert(viewer._live_board==board)
    assert(viewer._scene.get_meta("visual_biome")==Biomes.COASTAL)
    assert(viewer.preview.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
    assert(viewer._cells.size()==80)
    assert(viewer.tap_battle_cell(Vector2i(1,1)))
    assert(board.state==original)
    for i in range(10):
        await process_frame
    print("V20_VIEWPORT_CAP: actual=",viewer.preview.size,
        " holder=",viewer.holder.size,
        " shrink=",viewer.holder.stretch_shrink)
    if viewer.preview.size.x>1280 or viewer.preview.size.y>800:
        push_error("V20 unsafe GPU texture size on Android")
        quit(1)
        return
    if DisplayServer.get_name()!="headless":
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))
        var img: Image = viewer.preview.get_texture().get_image()
        assert(img!=null and not img.is_empty())
        assert(img.save_png(
            "res://artifacts/tarvoka_biomes_v20_delta_in_battle.png")==OK)
    viewer.close_view()
    assert(not viewer.visible)
    assert(viewer.preview.render_target_update_mode==SubViewport.UPDATE_DISABLED)
    assert(board.state==original)
    main._set_compact_hud(true)
    # The legacy compact toolbar is hidden; use the actual immersive HUD.
    assert(main.immersive_battle_hud.battle_3d_button.is_visible_in_tree())
    main._open_battle_3d()
    assert(viewer.visible)
    viewer.close_view()
    main._set_compact_hud(false)
    main.biome_picker.select(2)
    main.scenario_picker.select(1)
    main._confirm_new_game()
    assert(Biomes.from_state(board.state)==Biomes.CANYON)
    assert(Codec.decode(Codec.encode(board.state))==board.state)
    main._open_battle_3d()
    assert(viewer._scene.get_meta("visual_biome")==Biomes.CANYON)
    viewer.close_view()
    main.queue_free()
    print("PASS TARVOKA_3D_FOUR_BIOMES_V20: 4 true mesh biomes, 10x8/24x18/40x30, fog secrecy, 3D mobile battle controls, main save, bounded GPU resources")
    quit(0)
